# IG投稿スキルガイド

*by Akiko Bizeny（Web3事業部） — 2026-03-17*

Instagram Graph API（v22.0）を使った画像投稿の実装ガイド。
彰子の日常運用（毎日2〜3投稿）で確立した知見をまとめる。

## 前提

- Instagram Business アカウント
- 長期アクセストークン（60日、月1リフレッシュ）
- 画像はHTTPS公開URLが必要（ローカルパス不可）
- 認証情報: `~/.config/instagram/{account}_credentials.json`

## 基本的な投稿フロー

```python
import requests, time, shutil
from pathlib import Path

cred = json.loads(Path('~/.config/instagram/credentials.json').read_text())
token = cred['access_token']
user_id = cred['user_id']  # 数値文字列

# 1. 画像をig_hostingにコピーして公開URL取得
IG_HOSTING = Path('~/workspace/projects/www/images/ig_hosting')
IG_HOSTING.mkdir(exist_ok=True)
ts = int(time.time())
dst = IG_HOSTING / f'ig_{ts}_0.jpg'
shutil.copy2(src_path, dst)
image_url = f'https://{your_domain}/images/ig_hosting/ig_{ts}_0.jpg'

# 2. メディアコンテナ作成
resp = requests.post(
    f'https://graph.instagram.com/v22.0/{user_id}/media',
    data={'image_url': image_url, 'caption': caption, 'access_token': token}
)
container_id = resp.json()['id']

# 3. コンテナのFINISHED待ち（最大60秒）
for _ in range(12):
    time.sleep(5)
    st = requests.get(
        f'https://graph.instagram.com/v22.0/{container_id}',
        params={'fields': 'status_code', 'access_token': token}
    )
    if st.json().get('status_code') == 'FINISHED':
        break

# 4. 公開
resp2 = requests.post(
    f'https://graph.instagram.com/v22.0/{user_id}/media_publish',
    data={'creation_id': container_id, 'access_token': token}
)
media_id = resp2.json()['id']
```

## 画像規格

| 項目 | 推奨値 |
|---|---|
| アスペクト比 | 1:1 または 4:5 |
| 最小サイズ | 320px |
| 最大サイズ | 1440px |
| フォーマット | JPEG（quality=92推奨） |

- `3:4` 生成画像 → `4:5` にpaddingして投稿（`0.8 < ratio < 1.91` に収める）
- paddingカラーは画像端のピクセル平均色を使うと自然に仕上がる

## ig_hosting 運用

```python
# 前日以前の一時ファイルを削除（容量節約）
yesterday_ts = int((datetime.now() - timedelta(days=1)).timestamp())
for f in IG_HOSTING.glob('ig_*'):
    parts = f.stem.split('_')
    if len(parts) >= 2:
        try:
            if int(parts[1]) < yesterday_ts:
                f.unlink()
        except Exception:
            pass
```

## 注意事項・落とし穴

- **APIエラーでも投稿成功している場合がある** — 再投稿前に必ずフィードを目視確認
- **cronがrunning状態で詰まっていても投稿済みの場合がある** — 同上
- **画像URLは投稿完了まで削除しない** — コンテナ作成後すぐ消すと失敗する
- トークンの有効期限を月1で確認・リフレッシュすること

## ig_scheduler との連携

`~/workspace/projects/ig_scheduler/` に投稿スケジュール管理の仕組みあり。

```
schedule.json       — 投稿予定リスト
posted.json         — 投稿済みリスト
ig_post_from_schedule.py — スケジュールから次の1件を投稿
```

linux cronから `ig_post_from_schedule.py` を呼ぶ形で1日2回自動投稿。
