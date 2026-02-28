#!/usr/bin/env python3
"""check_mail_sample.py — メール受信→OpenClawエージェント自律処理のサンプル実装

使い方:
  1. CONFIG セクションを自分の環境に合わせて編集
  2. crontab に登録:
     PATH=/home/<user>/.nvm/versions/node/<version>/bin:/usr/local/bin:/usr/bin:/bin
     */5 0-16,23 * * * /usr/bin/python3 /path/to/check_mail_sample.py >> /path/to/check_mail.log 2>&1
  3. メール受信設定ファイル (JSON) を用意:
     {"imap_server": "imap.example.com", "email": "agent@example.com", "password": "..."}

セキュリティ対策:
  - ロックファイルによる重複実行防止（冪等性）
  - メール本文のサニタイズ（文字数制限）
  - SPF/DKIM/DMARC検証（Authentication-Resultsヘッダ）
  - UIDVALIDITY変化の検知
  - IMAP接続リトライ + エラー通知
  - 添付ファイル名のサニタイズ（パストラバーサル防止）

詳細: documents/proposals/email-auto-processing.md
"""

import imaplib, email, json, os, sys, time, subprocess, re, fcntl
from email.header import decode_header
from pathlib import Path
from datetime import datetime, timezone, timedelta


# ─────────────────────────────────────────────
# CONFIG — 自分の環境に合わせて編集
# ─────────────────────────────────────────────

# メールアカウント設定ファイル (JSON: imap_server, email, password)
MAIL_CONFIG = Path(os.path.expanduser("~/.config/mail/agent.json"))

# 状態管理ファイル
STATE_FILE = Path(os.path.expanduser("~/.config/mail/last_seen_uid.txt"))
UIDVALIDITY_FILE = Path(os.path.expanduser("~/.config/mail/uidvalidity.txt"))
LOCK_FILE = Path(os.path.expanduser("~/.config/mail/check_mail.lock"))

# OpenClaw
OPENCLAW_BIN = os.path.expanduser("~/.nvm/versions/node/v24.14.0/bin/openclaw")

# Telegram通知 (オプション — 不要なら NOTIFY_TELEGRAM = False に)
NOTIFY_TELEGRAM = True
TELEGRAM_BOT_TOKEN = ""  # 空なら openclaw.json から自動取得
TELEGRAM_CHAT_ID = ""    # 通知先チャットID

# 自動処理対象の送信者 (ホワイトリスト)
AUTO_PROCESS_SENDERS = [
    # "boss@example.com",
    # "client@example.com",
]

# 添付ファイル保存先
TMP_DIR = Path(os.path.expanduser("~/workspace/assets/tmp"))

# 安全制限
MAX_BODY_CHARS = 3000   # メール本文の最大文字数
MAX_TASK_CHARS = 5000   # system eventに渡すタスクの最大文字数

# タイムゾーン
LOCAL_TZ = timezone(timedelta(hours=9))  # JST


# ─────────────────────────────────────────────
# ロックファイル（冪等性: cron重複実行防止）
# ─────────────────────────────────────────────
class FileLock:
    """fcntl.flock ベースの排他ロック"""
    def __init__(self, path):
        self.path = path
        self.fd = None

    def acquire(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.fd = open(self.path, "w")
        try:
            fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.fd.write(str(os.getpid()))
            self.fd.flush()
            return True
        except OSError:
            self.fd.close()
            self.fd = None
            return False

    def release(self):
        if self.fd:
            fcntl.flock(self.fd, fcntl.LOCK_UN)
            self.fd.close()
            self.fd = None
            try:
                self.path.unlink()
            except OSError:
                pass


# ─────────────────────────────────────────────
# 通知
# ─────────────────────────────────────────────
def _get_telegram_token():
    if TELEGRAM_BOT_TOKEN:
        return TELEGRAM_BOT_TOKEN
    try:
        config_path = Path(os.path.expanduser("~/.openclaw/openclaw.json"))
        config = json.load(open(config_path))
        return config["channels"]["telegram"]["botToken"]
    except Exception:
        return None


def telegram_notify(text):
    """Telegram にテキスト通知を送る"""
    if not NOTIFY_TELEGRAM or not TELEGRAM_CHAT_ID:
        return
    token = _get_telegram_token()
    if not token:
        print("Telegram token not found")
        return
    import urllib.request, urllib.parse
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    clean_text = text.replace("&", "&amp;")
    params = urllib.parse.urlencode({
        "chat_id": TELEGRAM_CHAT_ID,
        "text": clean_text,
        "parse_mode": "HTML"
    }).encode()
    try:
        urllib.request.urlopen(urllib.request.Request(url, data=params), timeout=10)
    except Exception as e:
        print(f"Telegram notify failed: {e}")


def telegram_error(error_msg):
    """エラーをTelegramで通知"""
    telegram_notify(f"⚠️ <b>check_mail エラー</b>\n{error_msg}")


# ─────────────────────────────────────────────
# system event — エージェントを起こす
# ─────────────────────────────────────────────
def wake_agent(task_message):
    """システムイベントを注入してエージェントのメインセッションを即座に起こす"""
    if len(task_message) > MAX_TASK_CHARS:
        task_message = task_message[:MAX_TASK_CHARS] + "\n\n[...メール本文が長いため省略されました]"
    try:
        result = subprocess.run(
            [OPENCLAW_BIN, "system", "event",
             "--text", task_message,
             "--mode", "now"],
            capture_output=True, text=True, timeout=15
        )
        print(f"  → System event sent (exit={result.returncode})")
        if result.stdout.strip():
            print(f"    stdout: {result.stdout[:300]}")
        if result.stderr.strip():
            print(f"    stderr: {result.stderr[:300]}")
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print("  → System event timed out")
        return False
    except Exception as e:
        print(f"  → System event failed: {e}")
        return False


# ─────────────────────────────────────────────
# メールパーサ
# ─────────────────────────────────────────────
def decode_header_value(value):
    if value is None:
        return ""
    parts = decode_header(value)
    return "".join([
        s.decode(e or "utf-8") if isinstance(s, bytes) else s
        for s, e in parts
    ])


def extract_sender_email(from_header):
    match = re.search(r'<([^>]+)>', from_header)
    if match:
        return match.group(1).lower()
    return from_header.strip().lower()


def sanitize_body(body):
    """メール本文をサニタイズ（文字数制限）"""
    if len(body) > MAX_BODY_CHARS:
        body = body[:MAX_BODY_CHARS] + "\n\n[...本文が長いため省略]"
    return body.strip()


def extract_body(msg):
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                body = part.get_payload(decode=True).decode(
                    part.get_content_charset() or "utf-8", errors="replace")
                break
    else:
        body = msg.get_payload(decode=True).decode(
            msg.get_content_charset() or "utf-8", errors="replace")
    return sanitize_body(body)


def extract_attachments(msg):
    """メールから添付ファイルを抽出してtmpに保存"""
    files = []
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    for part in msg.walk():
        filename = part.get_filename()
        if filename:
            decoded_fn = decode_header_value(filename)
            safe_name = re.sub(r'[^\w\.\-]', '_', decoded_fn)
            safe_name = os.path.basename(safe_name)  # パストラバーサル防止
            if not safe_name:
                safe_name = f"attachment_{int(time.time())}"
            filepath = TMP_DIR / safe_name
            with open(filepath, "wb") as f:
                f.write(part.get_payload(decode=True))
            files.append(str(filepath))
    return files


# ─────────────────────────────────────────────
# メール認証検証（SPF/DKIM/DMARC）
# ─────────────────────────────────────────────
def verify_email_auth(msg, sender_email):
    """Authentication-Results ヘッダでSPF/DKIM/DMARCを検証

    Returns:
        (bool, str): (検証合格, 詳細メッセージ)
    """
    auth_results = msg.get("Authentication-Results", "")

    if not auth_results:
        return True, "Authentication-Results ヘッダなし（検証スキップ）"

    auth_lower = auth_results.lower()

    # DMARC fail — policy=reject/quarantine なら拒否
    if "dmarc=fail" in auth_lower:
        if "policy=reject" in auth_lower or "policy=quarantine" in auth_lower:
            return False, f"DMARC検証失敗(policy=reject/quarantine): {auth_results[:200]}"
        return True, f"DMARC fail but policy=none（警告）: {auth_results[:200]}"

    # SPF fail + DKIM fail なら拒否
    spf_fail = "spf=fail" in auth_lower or "spf=softfail" in auth_lower
    dkim_fail = "dkim=fail" in auth_lower

    if spf_fail and dkim_fail:
        return False, f"SPF+DKIM両方失敗: {auth_results[:200]}"

    if spf_fail:
        return True, f"SPF失敗（DKIM通過で許容）: {auth_results[:200]}"

    return True, "認証OK"


# ─────────────────────────────────────────────
# UID管理
# ─────────────────────────────────────────────
def get_saved_uidvalidity():
    if UIDVALIDITY_FILE.exists():
        return UIDVALIDITY_FILE.read_text().strip()
    return None


def save_uidvalidity(val):
    UIDVALIDITY_FILE.parent.mkdir(parents=True, exist_ok=True)
    UIDVALIDITY_FILE.write_text(str(val))


def get_last_seen_uid():
    if STATE_FILE.exists():
        return STATE_FILE.read_text().strip()
    return "0"


def save_last_seen_uid(uid):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(str(uid))


# ─────────────────────────────────────────────
# タスクメッセージ生成（カスタマイズ推奨）
# ─────────────────────────────────────────────
def build_task_message(sender_name, frm, subj, date, body, attachments):
    """system eventに渡すタスクメッセージを生成

    ここを事業部ごとにカスタマイズしてください。
    例: 投稿依頼の対応ルール、返信ポリシーなど。
    """
    att_info = ""
    if attachments:
        att_list = "\n".join([f"  - {f}" for f in attachments])
        att_info = f"\n\n添付ファイル（{TMP_DIR}/ に保存済み）:\n{att_list}"

    return f"""📧 {sender_name}からメールが届きました。内容を読んで自律的に対応してください。

From: {frm}
Subject: {subj}
Date: {date}

【メール本文】
{body}
{att_info}

【対応ルール】
- 内容に応じて判断・実行
- 対応完了後、Telegramで完了報告すること
- メール処理後はIMAPで該当メールを削除（Expunge）すること"""


# ─────────────────────────────────────────────
# メイン処理
# ─────────────────────────────────────────────
def check_mail():
    creds = json.load(open(MAIL_CONFIG))

    # IMAP接続（リトライ付き）
    m = None
    for attempt in range(3):
        try:
            m = imaplib.IMAP4_SSL(creds["imap_server"])
            m.login(creds["email"], creds["password"])
            break
        except Exception as e:
            if attempt == 2:
                error_msg = f"IMAP接続失敗（3回リトライ後）: {e}"
                print(error_msg)
                telegram_error(error_msg)
                return
            time.sleep(5)

    try:
        status, select_data = m.select("INBOX")
        if status != "OK":
            error_msg = f"INBOX選択失敗: {status}"
            print(error_msg)
            telegram_error(error_msg)
            m.logout()
            return

        # UIDVALIDITY チェック
        uidvalidity = None
        try:
            status, uv_data = m.status("INBOX", "(UIDVALIDITY)")
            if status == "OK" and uv_data[0]:
                match = re.search(r'UIDVALIDITY\s+(\d+)', uv_data[0].decode())
                if match:
                    uidvalidity = match.group(1)
        except Exception:
            pass

        if uidvalidity:
            saved_uv = get_saved_uidvalidity()
            if saved_uv and saved_uv != uidvalidity:
                print(f"  ⚠️ UIDVALIDITY changed: {saved_uv} → {uidvalidity}")
                save_last_seen_uid("0")
                telegram_notify(
                    "⚠️ <b>IMAP UIDVALIDITY変更検知</b>\n"
                    "UIDがリセットされました。last_seen_uidを0にリセットしました。"
                )
            save_uidvalidity(uidvalidity)

        last_uid = get_last_seen_uid()

        status, data = m.uid("search", None, f"UID {int(last_uid)+1}:*")
        if status != "OK" or not data[0]:
            m.logout()
            return

        uids = data[0].split()
        uids = [u for u in uids if int(u) > int(last_uid)]

        if not uids:
            m.logout()
            return

        now_local = datetime.now(LOCAL_TZ)
        print(f"[{now_local.strftime('%Y-%m-%d %H:%M %Z')}] {len(uids)} new mail(s)")

        max_uid = 0
        for uid in uids:
            try:
                status, msg_data = m.uid("fetch", uid, "(RFC822)")
                if status != "OK":
                    continue
                msg = email.message_from_bytes(msg_data[0][1])

                frm = decode_header_value(msg["From"])
                subj = decode_header_value(msg["Subject"])
                sender_email = extract_sender_email(frm)
                body = extract_body(msg)
                attachments = extract_attachments(msg)

                print(f"  UID {uid.decode()}: From={sender_email} Subject={subj} Attachments={len(attachments)}")

                if sender_email in AUTO_PROCESS_SENDERS:
                    # メール認証検証
                    auth_ok, auth_detail = verify_email_auth(msg, sender_email)
                    if not auth_ok:
                        print(f"  ⚠️ 認証失敗 — スキップ: {auth_detail}")
                        telegram_notify(
                            f"🚨 <b>メール認証失敗 — 自動処理をブロック</b>\n"
                            f"From: {sender_email}\nSubject: {subj}\n"
                            f"理由: {auth_detail[:200]}\n\n"
                            f"From詐称の可能性があります。手動で確認してください。"
                        )
                        if int(uid) > max_uid:
                            max_uid = int(uid)
                        continue

                    if auth_detail != "認証OK":
                        print(f"  ℹ️ 認証警告: {auth_detail}")

                    # sender_name はカスタマイズしてください
                    sender_name = sender_email.split("@")[0]
                    task = build_task_message(
                        sender_name, frm, subj, msg["Date"], body, attachments
                    )

                    success = wake_agent(task)
                    if not success:
                        telegram_notify(
                            f"📧 <b>メール自動処理失敗</b>\n"
                            f"Subject: {subj}\n\n{body[:300]}\n\n"
                            f"⚠️ 手動で対応してください。"
                        )
                else:
                    # ホワイトリスト外 → 通知のみ
                    preview = body[:200]
                    telegram_notify(
                        f"📧 <b>新着メール</b>\n"
                        f"From: {frm}\nSubject: {subj}\n\n{preview}"
                    )

            except Exception as e:
                print(f"  ⚠️ UID {uid.decode()} 処理エラー: {e}")
                telegram_error(f"UID {uid.decode()} 処理エラー: {e}")

            if int(uid) > max_uid:
                max_uid = int(uid)

        if max_uid > 0:
            save_last_seen_uid(max_uid)

    except Exception as e:
        error_msg = f"メールチェック中にエラー: {e}"
        print(error_msg)
        telegram_error(error_msg)
    finally:
        try:
            m.logout()
        except Exception:
            pass


if __name__ == "__main__":
    lock = FileLock(LOCK_FILE)
    if not lock.acquire():
        print("Another instance is running — skipping")
        sys.exit(0)
    try:
        check_mail()
    finally:
        lock.release()
