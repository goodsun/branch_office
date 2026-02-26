# 画像生成ガイドライン — bon-soleil Holdings

実践から得られた知見をまとめたガイドライン。
generate.py（nanobanana skill）を使った画像生成の運用ルール。

## ref とプロンプトテキストの役割分担

### 大原則: テキストが ref より優先される

Gemini はプロンプトテキストを ref 画像より強く優先する。
**キャラクターの外見はテキスト（prompt_features）で書く。ref はニュアンスの補完。**

| 要素 | 役割 | 例 |
|------|------|-----|
| `prompt_features` | キャラの外見定義（最優先） | 髪色・服装・角・耳など |
| `charsheet`（ref） | タッチ・色味・雰囲気の補完 | ベージュ暖色系のマンガ調など |

### よくある失敗

- ref だけ変えて prompt_features を変えない → 同じキャラが出続ける
- ref を渡さず prompt_features だけ → 外見は正確だがタッチが安定しない
- **両方揃えるのがベスト**

## スタイル切替は必ず両方セットで

```json
"corp": {
  "charsheet_override": "~/workspace/HR/charsheets/xxx/corp.jpg",
  "prompt_features_override": "具体的な外見テキスト..."
}
```

**`charsheet_override` と `prompt_features_override` は必ずセットで定義する。**
片方だけでは切り替わらない。

## モデル選定

| モデル | 向いている用途 | 特記 |
|--------|-------------|------|
| `gemini-3-pro-image-preview` | 写真合成・テキスト描画・最高品質 | ref 反映精度◎、フィルタやや厳しい |
| `gemini-2.5-flash-image` | キャラ生成・スタイル参照・高速 | フィルタ緩め、テキスト描画は不得意 |

### 使い分けの目安

- **日本語テキストを画像内に描画したい** → `gemini-3-pro-image-preview` 一択
- **写真にキャラを合成したい** → `gemini-3-pro-image-preview`
- **キャライラストを生成したい** → `gemini-2.5-flash-image`（フィルタが緩い）
- **3キャラ以上を同時に生成したい** → `gemini-2.5-flash-image`（3キャラ揃うとディズニーIP判定されやすい）

## 生成物の管理

```
workspace/generates/    ← 生成直後はここに出力（ステージング）
↓ 確認・採用
workspace/assets/images/   ← 公開用
workspace/HR/charsheets/   ← 社員のキャラシート
```

- **試行錯誤（v1, v2...）は generates/ に溜める**
- 採用後に正しい場所にコピー、generates/ から削除
- SNS 投稿成功後も generates/ から削除

## 生成前の確認事項

- **生成前にマスターに確認を取ること**（自動生成が許可されているタスクを除く）
- 画像サイズ確認（100KB 超はリサイズしてから image ツールで確認）
- 生成後は即 Telegram でマスターに送る

---

*bon-soleil Holdings — 実践から学んだ画像生成ルール*
