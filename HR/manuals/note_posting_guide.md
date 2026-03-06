# note.com 投稿手順書

*by メフィ（bon-soleil CCO）— 2026-03-07*

---

## 概要

bon-soleilのnoteアカウント（`teddy_on_web`）への記事投稿をAPIで自動化する手順。  
ブラウザのセッションCookieを使用する。

---

## 必要なもの

- `_note_session_v5` Cookie（ログイン済みブラウザから取得）
- Node.js（`marked`、`sharp` npm パッケージ）
- 記事本文（Markdownファイル）
- アイキャッチ画像（PNG、後でJPEG変換）

---

## Cookie の取得方法

1. ブラウザで https://note.com にログイン
2. DevTools → Network タブで任意のリクエストをコピー（`Copy as cURL`）
3. `_note_session_v5=xxxx` の値を取得
4. **有効期限：約3ヶ月。切れたら再取得。**

---

## API エンドポイント（実証済み）

| 操作 | メソッド | エンドポイント |
|------|---------|--------------|
| 新規記事作成 | POST | `/api/v1/text_notes` |
| 本文保存（下書き） | POST | `/api/v1/text_notes/draft_save` |
| アイキャッチ画像アップロード | POST | `/api/v1/image_upload/note_eyecatch` |

- ベースURL: `https://note.com`
- 必須ヘッダー: `Origin: https://editor.note.com`、`X-Requested-With: XMLHttpRequest`

---

## 手順

### STEP 1: 新規記事作成

```json
POST /api/v1/text_notes
{ "name": "記事タイトル", "status": "draft" }
```

レスポンスの `id` と `key` を保存する。

### STEP 2: 本文を保存

Markdownを `marked` でHTMLに変換してから送る。**plain textのまま送ると改行が崩れる。**

```javascript
const { marked } = require('marked');
const html = marked.parse(markdownText);

// POST /api/v1/text_notes/draft_save
{
  "id": 123456789,
  "name": "記事タイトル",
  "body": "<p>HTML本文...</p>",
  "body_length": 1234,
  "status": "draft"
}
```

### STEP 3: アイキャッチ画像をアップロード

**JPEGのみ対応（PNG不可）**。`sharp` でリサイズ変換してから送る。

```javascript
const jpegBuf = await sharp('eyecatch.png')
  .resize(1920, 1005, { fit: 'cover' })
  .jpeg({ quality: 90 })
  .toBuffer();

// multipart/form-data で送信
// フィールド順: note_id → file → width → height
POST /api/v1/image_upload/note_eyecatch
```

### STEP 4: 公開

APIでの公開は未検証。**現状はブラウザのnote.com下書き画面から手動で公開。**

---

## アイキャッチ生成（Gemini）

```javascript
const { GoogleGenAI } = require('@google/genai');
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const response = await ai.models.generateContent({
  model: 'gemini-2.0-flash-exp-image-generation',
  contents: '英語プロンプト',
  config: { responseModalities: ['TEXT', 'IMAGE'] },
});
// response.candidates[0].content.parts から inlineData を取り出す
```

---

## ハマりポイント（実証済み）

| 問題 | 原因 | 解決策 |
|------|------|--------|
| POST 422 | フォーマット誤り | `body`、`id`、`name`、`status` を含める |
| PUT 422 | 古いエンドポイント | `draft_save` を使う（PUT ではない） |
| アイキャッチ `file_type_not_allowed` | PNG を送っていた | `sharp` で JPEG に変換する |
| 本文の改行崩れ | Markdown をそのまま送った | `marked.parse()` でHTML変換後に送る |
| Cookie 認証失敗 | セッション期限切れ | ブラウザで再ログインしてCookieを再取得 |

---

*「試行錯誤した分だけ、手順書は正確になる。」 — メフィ 😈*
