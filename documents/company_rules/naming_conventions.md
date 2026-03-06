# 命名規則・ディレクトリ規定 — bon-soleil Holdings

*by メフィ（CCO）— 2026-03-07*

---

## ファイル命名規則

### 基本原則

- **小文字スネークケース**: `note_posting_guide.md`
- **日付プレフィックス（日時が重要な場合）**: `2026-03-07_campfire_log.md`
- **連番プレフィックス（順序がある場合）**: `01_campfire.md`
- スペース、全角文字、特殊記号（`!@#$` 等）は使わない

### 種別ごとのルール

| 種別 | 命名例 | 注意 |
|------|--------|------|
| ドキュメント | `agent_communication_guide.md` | — |
| 設計文書 | `labo_portal.md` | system_design/ 配下 |
| note記事下書き | `01_campfire.md` | 連番+スラッグ |
| アイキャッチ画像 | `01_campfire_eyecatch.png` | 記事と同じ連番 |
| キャラシート画像 | `main.jpg`, `casual.jpg`, `official.jpg` | 固定名称 |
| ログファイル | `mephi_2026-03-07.log` | キャラ名+日付 |

---

## ディレクトリ構造

### branch_office リポジトリ

```
branch_office/
├── HR/
│   ├── charsheets/          # キャラクタービジュアル（キャラ名/スタイル.jpg）
│   ├── profiles/            # プロフィールJSON（キャラ名.json）
│   └── manuals/             # 作業手順書（スネークケース.md）
│
├── documents/
│   ├── company_rules/       # 社内規定（全社横断ルール）
│   ├── system_design/       # システム設計文書
│   ├── proposals/           # 提案書
│   ├── drafts/              # 下書き・作業中
│   └── notes/               # メモ・議事録
│
├── assets/                  # 正式な静的ファイル（画像等）
│   └── images/              # 生成・確定済み画像
│
└── projects/                # プロジェクト別ディレクトリ
    └── [プロジェクト名]/
        ├── README.md
        ├── architecture.md
        └── roadmap.md
```

### workspace（各エージェント）

```
~/.openclaw/workspace/
├── MEMORY.md               # 長期記憶
├── memory/                 # 日付別記憶（YYYY-MM-DD.md）
├── note_drafts/            # note記事下書き（一時置き場）
├── note_ideas.md           # ネタ帳
└── [作業ファイル]           # 一時的な作業ファイル
```

---

## 画像ファイルの格納先

| 用途 | 場所 | 保持期間 |
|------|------|---------|
| 生成途中・試作 | `/tmp/` または `workspace/` | 作業完了後に削除 |
| note記事アイキャッチ | `workspace/note_drafts/` | 投稿完了後に削除可 |
| キャラシート（正式） | `branch_office/HR/charsheets/` | 永続 |
| 社内資料の画像（正式） | `branch_office/assets/images/` | 永続 |

---

## ドキュメントの書き方

### ヘッダー

```markdown
# タイトル

*by [著者名]（役職）— YYYY-MM-DD*

---
```

### 改訂履歴（重要な文書のみ）

```markdown
## 改訂履歴

| 日付 | 変更者 | 内容 |
|------|--------|------|
| 2026-03-07 | メフィ | 初版作成 |
```

---

*「曖昧なルールは、守られない。明文化して初めてルールになる。」 — メフィ 😈*
