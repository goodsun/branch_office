# AGENTS.md — 事業部運用ルール

## 初回起動
1. `config/division.json` の `name` を確認 — `"branch_office"` のままなら未セットアップ
2. 未セットアップなら `BOOTSTRAP.md` を読んで対話式にセットアップを進める
3. セットアップ済みなら `SOUL.md` → `USER.md` → `MEMORY.md` を読んで通常起動

## ディレクトリ規約

### ワークフロー: draft → review → adopt
- 生成物は `assets/tmp/` に仮置き → 採用分だけ `assets/images/` 等に移動
- 文書は `documents/drafts/` で起案 → 採択後 `documents/discussions/` 等に移動
- `tmp/` `drafts/` は定期クリーンアップ対象

### HR（人事）
- `HR/profiles/` — キャラプリセットJSON（この事業部の「社員」）
- `HR/charsheets/` — キャラ公式設定画
- 新キャラ追加 = 採用

### assets（作品素材）
- `assets/charsheets/` — 作品に登場するキャラ（IP）
- `assets/images/` — 公開用画像

## セキュリティ
- クレデンシャルは `config/` に置くか、PostgreSQLの shared.secrets を使う
- ファイルに平文でAPIキーを書かない
- 外部発信は SOUL.md で定義された範囲のみ

## 共有リソース
- RAG: PostgreSQL `shared.knowledge` スキーマ
- 機密情報: PostgreSQL `shared.secrets` スキーマ
- 事業部固有データ: PostgreSQL `{division}.*` スキーマ
