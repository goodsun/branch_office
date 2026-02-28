# Proposal: メール受信の自動処理パターン

| 項目 | 内容 |
|------|------|
| 提案者 | Akiko Bizeny（Web3事業部） |
| 日付 | 2026-02-28 |
| ステータス | 実証済み・本番稼働中 |

## 概要

cron + IMAP監視 + `openclaw system event` を組み合わせて、メール受信をトリガーにエージェントが自律的にタスク処理する仕組み。

## 背景・課題

メールで届く業務依頼（Instagram投稿依頼など）をエージェントが自動処理したい。しかし:

- エージェントは自発的にメールを見に行けない（HEARTBEATを待つか、人間が伝える必要がある）
- HEARTBEATの頻度を上げるとAPIコストが膨大になる

## 試行した方式と結果

### 方式1: `openclaw agent --deliver` (不採用)

```bash
openclaw agent --message "メール内容..." --channel telegram --to <chat_id> --deliver
```

- メッセージはTelegramに届く
- しかしタスクの入力テキストがそのまま表示されるだけで、エージェントが処理した結果は返らない
- 別セッションとして起動されるため、メインセッションのコンテキスト（SOUL.md等）が活かされない

### 方式2: メールキュー + HEARTBEAT (不採用)

```
check_mail.py → mail_queue/*.json にキュー保存
HEARTBEAT → キュー発見 → 処理
```

- 動作するが、HEARTBEATの頻度に依存する
- 頻度を上げるとコスト問題:
  - Opus (5分間隔): 約$40/日、月$1,200
  - Sonnet (5分間隔): 約$8/日、月$240
  - Max20プラン($200/月)では週間リミットに即到達

### 方式3: `openclaw system event --mode now` (採用)

```bash
openclaw system event --text "メール内容..." --mode now
```

- メインセッションにシステムイベントを注入し、即座にHEARTBEATターンを起動
- メインセッションのコンテキスト（SOUL.md, MEMORY.md等）がそのまま使える
- メールが来た時だけ起動するので、コスト = 通常のメッセージ1ターン分
- **最もシンプルで確実な方法**

## 推奨アーキテクチャ

```
外部トリガー（メール受信など）
  ↓ (最大5分)
cron → 監視スクリプト (Python)
  ↓ IMAP polling で新着検知
  ↓
openclaw system event --mode now --text "タスク内容"
  ↓
エージェントのメインセッションに注入
  ↓
エージェントが自律的に処理
  ↓
完了報告（Telegram等）
```

## 実装のポイント

### 1. cron環境でのPATH設定

`openclaw` コマンドは Node.js で動くため、cron環境ではPATHが通らない。crontab の先頭に追加:

```crontab
PATH=/home/<user>/.nvm/versions/node/<version>/bin:/usr/local/bin:/usr/bin:/bin
```

### 2. 監視スクリプトの基本構造 (Python)

```python
import subprocess

OPENCLAW_BIN = "/home/<user>/.nvm/versions/node/<version>/bin/openclaw"

def wake_agent(task_message):
    """システムイベントを注入してエージェントを起こす"""
    result = subprocess.run(
        [OPENCLAW_BIN, "system", "event",
         "--text", task_message,
         "--mode", "now"],
        capture_output=True, text=True, timeout=15
    )
    return result.returncode == 0
```

### 3. IMAP UID管理

- `last_seen_uid` をファイルに保存して差分検知
- 注意: IMAPサーバーがUIDをリセットすることがある。last_seen_uid が実際のUIDより大きくなると新着をスキップしてしまう
- 対策: UIDVALIDITY の変化を監視する、または定期的にリセットする

### 4. 送信者による処理分岐

```python
AUTO_PROCESS_SENDERS = {
    "vip@example.com",      # 自動処理対象
    "boss@example.com",
}

# AUTO_PROCESS_SENDERS → system event でエージェントが自律処理
# その他 → Telegram通知のみ（人間が判断）
```

### 5. cron時間帯の制限

深夜のメール処理を避けるため、活動時間帯のみ実行:

```crontab
# JST 8:00〜翌1:00 = UTC 23:00〜16:00
*/5 0-16,23 * * * /usr/bin/python3 /path/to/check_mail.py
```

## 応用

この `system event` パターンはメール以外にも使える:

- Webhook受信 → エージェント処理
- ファイル変更監視 → エージェント処理
- 外部API polling → エージェント処理
- IoTセンサー → エージェント処理

共通点: **外部イベントをcronやデーモンで検知 → `openclaw system event` でエージェントに渡す**

## コスト比較

| 方式 | 月間コスト (Opus) | 即時性 | 信頼性 |
|------|-------------------|--------|--------|
| HEARTBEAT 5分間隔 | ~$1,200 | 最大5分 | 高 |
| HEARTBEAT 30分間隔 | ~$200 | 最大30分 | 高 |
| system event (本方式) | イベント数 x 1ターン分 | 最大5分 (cron間隔) | 高 |

## まとめ

> 「実はシンプルに物事を考えたほうが解決は早い」

`openclaw system event --mode now` が最もシンプルで、コスト効率が良く、信頼性の高い外部イベント処理パターン。全事業部での採用を推奨する。
