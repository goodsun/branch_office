# branch_office

**bon-soleil Holdings 事業部テンプレート**

> **社是: Rooted Cosmopolitanism（ルーテッドコスモポリタニズム）**
>
> 根を張り、壁を溶かす。

各事業部（支社）が同じ構造で自律運用するためのスケルトンリポジトリ。
Clone して中身を入れるだけで、新しい事業部が立ち上がる。

## コンセプト

```
bon-soleil Holdings
│
├── HQ（本社 / ~/）          ← 統括AI
│
├── PostgreSQL（全社共有DB）
│   ├── shared.knowledge     ← RAG（pgvector）
│   ├── shared.secrets       ← 機密情報（pgcrypto）
│   └── {division}.*         ← 事業部専用スキーマ
│
└── /opt/divisions/          ← 支社群
    ├── web3/                ← web3事業部
    ├── publishing/          ← 出版事業部
    └── services/            ← Webサービス事業部
```

- **HQも支社も同じディレクトリ構造**を持つ（このテンプレート）
- 各事業部は独自の **OpenClawインスタンス + 専任AI** で自律運用
- 知識（RAG）と機密情報はPostgreSQLで全社共有、スキーマで論理分離
- 事業部間連携は OpenClaw の `sessions_send` / `sessions_spawn`

## ディレクトリ構成

```
branch_office/                      # リポジトリ（種）
│
├── template_workspace/             # -> ~/.openclaw/workspace/ (初回コピー)
│   ├── SOUL.md.template            # AIの人格テンプレート
│   ├── AGENTS.md                   # 運用ルール
│   ├── BOOTSTRAP.md                # 初回セットアップガイド
│   └── memory/                     # 日次メモ
│
├── template_config/                # -> ~/config/ (初回コピー)
│   └── division.json               # 事業部設定
│
├── HR/                             # 人事部（社員IP管理）— workspace内にsync
│   ├── profiles/                   # キャラプリセットJSON（履歴書）
│   └── charsheets/                 # 社員の公式設定画（証明写真）
│
├── assets/                         # アセット管理 — workspace内にsync
│   ├── tmp/                        # 生成直後・試行錯誤（使い捨てゾーン）
│   ├── charsheets/                 # 登場人物の設定画（作品のIP）
│   └── images/                     # 採用済み公開画像
│
├── documents/                      # ドキュメント管理
│   ├── company_rules/              # 社則 — sync対象
│   ├── drafts/                     # ブレスト・下書き・WIP
│   ├── discussions/                # 採択済み議事録
│   ├── notes/                      # 記事原稿
│   └── papers/                     # 論文・ホワイトペーパー
│
├── projects/                       # プロジェクト群
├── scripts/                        # 運用スクリプト
│   └── common/                     # 共通スクリプト — sync対象
│       └── sync.sh                 # 本社→支社 同期
│
└── setup.sh                        # 初回セットアップ
```

### デプロイ後のホームディレクトリ

```
~/
├── workspace/              <- AI の作業場所（branch_office 構成に準拠）
│   ├── AGENTS.md, SOUL.md, MEMORY.md...
│   ├── HR/                 <- sync.sh で本社から強制上書き
│   ├── assets/             <- charsheets/ のみ sync
│   ├── documents/          <- company_rules/ のみ sync + 議事録等
│   ├── projects/           <- gitリポジトリをcloneして作業する場所
│   ├── scripts/            <- common/ のみ sync、他はローカル固有
│   ├── config/             <- 設定ファイル（certbot 等も含む）
│   └── logs/               <- ログ
└── branch_office/          <- リポジトリ（git pull で更新）
                               ※ workspace 外に置く（理由: contribution_guide.md 参照）
```

> **`workspace/projects/` について**: gitリポジトリをcloneしてここで作業し、
> 成果を GitHub に push するのが基本ワークフロー。
> `~/workspace/projects/` は workspace 内なので image ツールからも参照可能。

### v3.3からv3.4へのマイグレーション

v3.3以前では `~/documents/`、`~/config/`、`~/logs/` がホーム直下にありました。
v3.4からは `~/workspace/` 配下に統合されています。

```bash
# 1. 各ディレクトリを workspace 配下に移動
#    ※ macOS は ~/documents/ が ~/Documents/ と同一のため rsync を使う
rsync -a ~/documents/discussions/ ~/workspace/documents/discussions/
rm -rf ~/documents/discussions

mv ~/logs ~/workspace/logs
mv ~/config ~/workspace/config

# 2. certbot を使っている場合
mv ~/certbot ~/workspace/config/certbot
# Apache/nginx の証明書パスを更新することを忘れずに

# 3. scripts を使っている場合
rsync -a ~/scripts/ ~/workspace/scripts/
rm -rf ~/scripts

# 4. branch_office を更新
cd ~/branch_office && git pull && bash scripts/common/sync.sh

# 5. Gateway 再起動
openclaw gateway restart
```

> HR, assets は workspace 内に配置。
> OpenClaw の image ツールは workspace 内のファイルのみ読み取り可能なため、
> エージェントがアクセスする画像・データは全て workspace 内に集約する。
> workspace を `~/workspace/` にすることで、隠しディレクトリに実データを埋めず、
> Finder や `ls` で直接見える場所に配置する。
>
> OpenClaw設定: `openclaw config set agents.defaults.workspace ~/workspace`

## ワークフロー: draft → review → adopt

全事業部で共通のライフサイクル:

```
生成・起案           レビュー           採用・配置
assets/tmp/      →   確認    →   assets/charsheets/ or images/
documents/drafts/→   確認    →   documents/discussions/ or notes/
```

- `assets/tmp/` `documents/drafts/` は使い捨てゾーン（定期クリーンアップ対象）
- 採用されたものだけ正式ディレクトリに移動
- 未採用は一定期間後に削除

> **`assets/tmp/` は揮発データ。** 画像生成の試行錯誤（v1, v2...）を一時保管する場所であり、
> 永続的なデータを置いてはいけない。7日以上経過したファイルはクリーンアップ対象。
> `.gitignore` でgit管理外、sync対象外。
>
> クリーンアップ（手動 or cron）:
> ```bash
> bash ~/branch_office/scripts/common/cleanup_tmp.sh
> ```
> Cron例（毎週日曜3時）: `0 3 * * 0 cd ~/branch_office && bash scripts/common/cleanup_tmp.sh`

## HR: 社員 vs 登場人物

| | HR/ (社員) | assets/charsheets/ (登場人物) |
|---|---|---|
| 例 | テディ、メフィ、彰子 | セゾン、尹喜 |
| 性質 | 自律AIキャラ、繰り返し生成 | 作品に登場するIP |
| 管理 | プリセットJSON + 公式設定画 | 素材として保管 |
| 雇用関係 | あり| なし |

## 準備するもの

セットアップを始める前に、以下を用意してください:

| 必須 | 項目 | 入手先 |
|:---:|------|--------|
| * | **AIエージェントのAPIキー** | Anthropic / OpenAI / Google 等 |
| * | Node.js (v18+) | nvm / Homebrew / apt / dnf 等で事前インストール |
| | OpenClaw | setup.shが自動インストール |
| | git | OS標準 or `apt install git` / `dnf install git` |

> **Node.js (v18+) は事前にインストールしてください。** setup.sh は Node.js の自動インストールを行いません。
> nvm / Homebrew / apt / dnf など、お好みの方法でインストールしてから setup.sh を実行してください。

### 推奨環境

| 項目 | 最低 | 推奨 |
|------|------|------|
| RAM | 2GB | 4GB+ |
| ディスク | 5GB | 10GB+ |
| OS | macOS / Linux | - |

> t2.micro（1GB RAM）では OpenClaw のインストール時にメモリ不足で失敗します。最低 2GB 以上の環境をご利用ください。

### おすすめ（Googleアカウントがあれば大体揃います）

| 項目 | 用途 | 入手先 |
|------|------|--------|
| Google Calendar | スケジュール管理 | Googleアカウント |
| Google Sheets | データ管理 | Googleアカウント |
| Gemini API Key | 画像生成・サブAI処理 | https://aistudio.google.com/ |
| Gmail App Password | メール送受信 | Google Account Settings |

### 通知先（いずれか1つ）

| 項目 | 入手先 |
|------|--------|
| Telegram Bot Token | @BotFather |
| Discord Bot Token | Discord Developer Portal |
| WhatsApp Business API | Meta Developer Portal |

### その他（必要に応じて）

| 項目 | 用途 |
|------|------|
| GitHub SSH Key | リポジトリ管理 |
| Instagram Graph API Token | SNS投稿 |

> 全部最初に揃える必要はありません。AIが対話の中で「〇〇が必要です」と案内します。

## クイックスタート

```bash
# 1. リポジトリをクローン
cd ~
git clone https://github.com/goodsun/branch_office.git
cd branch_office


# 2. ブートストラップ実行（Node.js + OpenClaw + AIエージェントを自動インストール）
./setup.sh

# 3. OpenClaw設定（"Local" を選択）
openclaw config
# ⚠️ 間違えて Remote を選んだ場合: openclaw config set gateway.mode local

# 4. 通知チャンネル設定（例: Telegram）
#    事前に @BotFather で /newbot してBot Tokenを取得しておく
openclaw channels add    # 対話式でBot Tokenを入力

# 5. Gateway起動
openclaw gateway install
openclaw gateway start

# 6. Botにメッセージを送ってペアリング
#    Telegramで作ったBotにDMを送る → ペアリングコードが返る
openclaw pairing approve telegram <code>

# 7. AIが起動！BOOTSTRAP.mdを読んで対話式にセットアップを続けます

# --- 以降、本社から社則・共通スクリプトの更新を受け取るには ---
cd ~/branch_office && git pull && bash scripts/common/sync.sh
```

### APIキーについて

- **Anthropic (Claude)**: https://console.anthropic.com/settings/keys で「Create Key」
  - 古いキーが401エラーになる場合は新規作成を推奨
  - `openclaw agents add main` でキーを登録後、`openclaw gateway restart` で反映
- **OpenAI / Google**: 各プロバイダーのConsoleでキーを発行

### トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| npm installでOOM/SIGKILL | メモリ不足（1GB以下） | 2GB以上の環境を使用 |
| Gateway start blocked: set gateway.mode=local | configでRemoteを選んだ | `openclaw config set gateway.mode local` |
| 401 authentication_error | APIキー無効 | 新しいキーを作成して `openclaw agents add main` |
| Agent failed: No API key found | キー未登録 | `openclaw agents add main` でキー登録 |
| Botから返答なし | Gateway未起動 or ペアリング未完了 | `openclaw gateway status` で確認 |

## v2からのマイグレーション

v2（`~/.openclaw/workspace/` + ホーム直下配置）からv3（`~/workspace/` 統合）への移行:

```bash
# 1. workspaceを移動
mv ~/.openclaw/workspace ~/workspace

# 2. HR, assetsをworkspace内に移動
mv ~/HR ~/workspace/
mv ~/assets ~/workspace/

# 3. OpenClawのworkspaceパスを変更
openclaw config set agents.defaults.workspace ~/workspace

# 4. branch_officeを更新してsync
cd ~/branch_office && git pull && bash scripts/common/sync.sh

# 5. Gateway再起動
openclaw gateway restart
```

## v3からv2へのロールバック

万一v3で問題が発生した場合の戻し手順:

```bash
# 1. workspace内のデータをホーム直下に戻す
mv ~/workspace/HR ~/
mv ~/workspace/assets ~/

# 2. workspaceを元の場所に戻す
mv ~/workspace ~/.openclaw/workspace

# 3. OpenClawのworkspaceパスを元に戻す
openclaw config set agents.defaults.workspace ~/.openclaw/workspace

# 4. Gateway再起動
openclaw gateway restart
```

## カスタマイズ箇所

このテンプレートを自社用にフォークする場合、以下を書き換えてください:

| ファイル | 項目 | 説明 |
|---------|------|------|
| `README.md` | `bon-soleil Holdings` | 組織名 |
| `README.md` | `git:goodsun/branch_office.git` | リポジトリURL |
| `template_workspace/SOUL.md.template` | `マスター（goodsun）` | オーナー名 |
| `template_workspace/SOUL.md.template` | `HQ（テディ🧸）` | 本社AI名 |
| `documents/company_rules/*.md` | `マスター（CEO）` | オーナー名・役職 |
| `documents/company_rules/*.md` | `bon-soleil Holdings` | 組織名 |
| `documents/company_rules/*.md` | `テディ🧸` `メフィ😈` | HQのAI名 |

## ライセンス

MIT License — 詳細は [LICENSE](LICENSE) を参照

---

*Maintained by テディ🧸 — bon-soleil HQ*
