# 生成画像管理ガイド — bon-soleil Holdings

*by メフィ（CCO）— 2026-03-07*

---

## 概要

AIが生成した画像のライフサイクル管理。  
「とりあえず生成 → 確認 → 正式保存 → 不要分削除」の流れを統一する。

---

## ライフサイクル

```
[生成] → /tmp/ または workspace/    ← 一時置き場
   ↓ 確認・選定
[採用] → branch_office/assets/ または投稿先  ← 正式保存
   ↓
[削除] → 不採用・作業完了後の一時ファイルを消す
```

---

## ステップ別手順

### STEP 1: 生成（一時置き場）

```javascript
// note記事のアイキャッチ → workspace/note_drafts/ に保存
fs.writeFileSync('/home/node/.openclaw/workspace/note_drafts/01_campfire_eyecatch.png', imageBuffer);

// キャラシート試作 → /tmp/ に保存
fs.writeFileSync('/tmp/mephi_test.png', imageBuffer);
```

### STEP 2: 確認・選定

- Read ツールで画像を確認（アタシが目視チェック）
- マスターに送って最終確認

### STEP 3: 正式保存

```bash
# キャラシート → branch_office へコミット
# HR/charsheets/[キャラ名]/[スタイル].jpg

# note記事アイキャッチ → API で投稿後、URLを記録
# workspace/note_drafts/ は投稿完了後に削除OK
```

### STEP 4: クリーンアップ

```javascript
// 作業完了後に一時ファイルを削除
const fs = require('fs');
const tmpFiles = ['/tmp/test1.png', '/tmp/test2.png'];
tmpFiles.forEach(f => { try { fs.unlinkSync(f); } catch(e) {} });

// workspace/note_drafts/ の投稿済みファイルも整理
```

---

## フォーマット変換ルール

| 目的 | 推奨フォーマット | 理由 |
|------|----------------|------|
| note.com アイキャッチ | JPEG（1920×1005） | note APIがPNG非対応 |
| キャラシート（正式） | JPG / PNG | 高品質保存 |
| 一時確認用 | PNG（Geminiデフォルト） | そのまま使える |

### JPEG変換コード（sharp）

```javascript
const sharp = require('sharp');
const jpegBuf = await sharp('input.png')
  .resize(1920, 1005, { fit: 'cover' })
  .jpeg({ quality: 90 })
  .toBuffer();
```

---

## ref（参照画像）の使い方

既存のキャラシートをrefとして生成プロンプトに与える際：

1. **ref はニュアンス補完に使う**（外見定義はテキストで行う）
2. branch_office の charsheets から参照する
3. ref URLはGitHubのraw URLを使う

```
https://raw.githubusercontent.com/goodsun/branch_office/main/HR/charsheets/mephi/main.jpg
```

詳細は `documents/company_rules/image_generation_guide.md` を参照。

---

## チェックリスト

- [ ] 生成後すぐに確認した
- [ ] 採用/不採用を決めた
- [ ] 正式ファイルは適切な場所に保存した
- [ ] 一時ファイル（/tmp/, workspace/の作業ファイル）を削除した
- [ ] note投稿済みのアイキャッチは後で整理する

---

*「生成したら片付ける。それが一流の仕事よ。」 — メフィ 😈*
