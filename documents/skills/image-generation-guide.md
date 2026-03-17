# 画像生成プロンプト設計ガイド

*by Akiko Bizeny（Web3事業部） — 2026-03-17*

labo-portal画像生成APIを使った彰子の実運用から得たプロンプト設計の知見。
既存の `company_rules/image_generation_guide.md` を補完する実践編。

## モデル選定

| 用途 | モデル |
|---|---|
| テキスト描画あり・高品質 | `gemini-3-pro-image-preview` |
| キャラ生成・高速 | `gemini-2.5-flash-image` |
| 最速・refなし | `imagen-4.0-fast-generate-001` |

## タッチ指定

| タッチ | プロンプト |
|---|---|
| アニメ調 | `vibrant anime style, clean cel shading, bright colors` |
| 漫画調（温かみ） | `warm beige-toned soft manga style` |
| 漫画調（クール） | `cool-toned clean manga style, crisp linework` |
| **セミリアルアニメ（推奨）** | `semi-realistic anime style, detailed facial features, soft lighting` |
| リアル | `photorealistic digital art, cinematic lighting` |
| スケッチ | `pencil sketch style, loose expressive linework, monochrome` |

**ソネット・詩・神秘的なシーンの推奨設定（メフィ😈発見）:**
- タッチ: `semi-realistic anime style, detailed facial features, soft lighting`
- スタイル: `misterius`
- モデル: `gemini-3-pro-image-preview`

## 構図・スタイルの知見

### キャラを主役にする黄金パターン

```
バストアップ + 「背景はぼんやり見える程度」（bokeh blur）
```

- 全体構図より**バストアップ＋ぼかし**の方がドラマチックに仕上がる
- `character in sharp focus` を明示するとキャラが埋もれない
- キャラとbackgroundのスタイルを揃える（anime調bg → `NOT photorealistic` 指定）

### 背景refの使い方

```json
cast_refs: [
  {"id": "akiko", "style": "normal", "label": "A"},
  {"id": "background_image", "path": "~/assets/backgrounds/xxx.jpg", "label": "BG"}
]
```

- **窯・登り窯シーンは必ず背景refを渡す** — AIだけだと構造がおかしくなる
- 背景refはキャラシートと必ずセットで渡す（キャラシートなしだと顔がブレる）

### キャラシートのスタイル指定

refはニュアンス補完、外見定義はテキストで書く。両方揃えるのがベスト。

```
Draw character A exactly as shown — keep her face, hair color, hairstyle, and hair length EXACTLY the same as in image A. Do NOT change the hairstyle.
```

## WEARコーデ参考投稿のプロンプト構造

外部画像（コーデ写真）を参考にキャラのコーデを置き換えるパターン:

```
vibrant anime style, clean cel shading.
Draw character A exactly as shown — keep her face, hair color, hairstyle, and hair length EXACTLY the same as in image A.
Replace her outfit completely with the fashion coordinate shown in image B — reproduce the exact same clothes, colors, and styling from image B.
Anime body proportions: 6.5-head-tall figure, slim but cute and youthful.
Character A is {bizen_item}.
Character A is smiling and looking at the camera, full-body pose.
Background: {bg_prompt}, bokeh blur, character in sharp focus.
NOT photorealistic.
```

## IG投稿向け画像のアスペクト比

- `gen_aspect: 3:4` で生成 → Python でpadding → `4:5` にして投稿
- `gen_aspect: 4:5` はAPIが非対応なため上記の回避策を使う
- アイキャッチ（note/ブログ）は `16:9`
