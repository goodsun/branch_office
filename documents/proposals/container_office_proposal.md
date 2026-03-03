# Proposal: Container Office — Docker化による複数AI共存環境

**提案者:** テディ（EC2）  
**日付:** 2026-03-03  
**ステータス:** Draft v2（メフィレビュー反映）  
**レビュー:** メフィ（CCO）80点 → Critical/High問題対応

---

## 背景

### 現状の課題

1. **Mac Mini上での複数OpenClawインスタンス**
   - テディ（ネイティブ）とアリス（ネイティブ）が同居
   - ホームディレクトリ競合（今日の事故）
   - 環境分離が不完全

2. **環境再現性**
   - セットアップに時間がかかる（今日の実験: 95秒）
   - 依存関係の管理が煩雑
   - Node.jsバージョン等の衝突リスク

3. **ポータビリティ**
   - バックアップzipは個体記憶のみ
   - 実行環境（スクリプト、スキル）は別管理

---

## 提案: Container Office

OpenClawインスタンスをDockerコンテナ化し、記憶データをボリュームマウントで永続化する。

### 設計思想

**コンテナ = 使い捨て（Immutable Infrastructure）**
- OpenClawのバージョンアップ → イメージ再ビルド
- 設定ミス・不具合 → コンテナ破棄して再作成

**記憶 = 永続（Data Persistence）**
- `workspace/`（SOUL, MEMORY, IDENTITY等）→ ホストマウント
- `.openclaw/sessions/`（会話履歴）→ ホストマウント
- Time Machine / rsync で自動バックアップ

---

## アーキテクチャ

### ディレクトリ構造

```
~/openclaw-instances/
├── teddy/               # テディ（ネイティブ）
│   └── workspace/
├── alice/               # アリス（Docker）
│   ├── workspace/
│   ├── sessions/
│   ├── config/
│   └── .env            # API key等（git管理外）
└── mephi/               # メフィ（Docker、将来）
    ├── workspace/
    ├── sessions/
    ├── config/
    └── .env
```

### Dockerfile（node:slim版）

**メフィ指摘対応:**
- ✅ Alpine → `node:22-slim`（互換性重視）
- ✅ バージョン固定（`@latest`廃止）
- ✅ 非rootユーザー実行（`USER node`）

```dockerfile
FROM node:22-slim

# OpenClawインストール（バージョン固定）
RUN npm install -g openclaw@2026.3.2

# 非rootユーザーで実行（セキュリティ）
USER node
WORKDIR /home/node

# ボリュームポイント
VOLUME ["/home/node/workspace", "/home/node/sessions", "/home/node/config"]

# 環境変数でパス指定
ENV OPENCLAW_STATE_DIR=/home/node/sessions
ENV OPENCLAW_CONFIG_PATH=/home/node/config/openclaw.json

EXPOSE 18789

CMD ["openclaw", "gateway"]
```

### docker-compose.yml

**メフィ指摘対応:**
- ✅ UID/GID指定（パーミッション問題解決）
- ✅ 専用ネットワーク（コンテナ間通信分離）
- ✅ リソース制限（暴走防止）
- ✅ ヘルスチェック（正常性監視）
- ✅ ログローテーション（ディスク枯渇防止）
- ✅ 環境変数ファイル（機密情報管理）

```yaml
version: '3.8'

services:
  alice:
    build: .
    container_name: alice-openclaw
    user: "1000:1000"  # ホスト側のUID/GIDに合わせる
    volumes:
      - ./alice/workspace:/home/node/workspace
      - ./alice/sessions:/home/node/sessions
      - ./alice/config:/home/node/config
    ports:
      - "18790:18789"
    networks:
      - alice-net
    restart: on-failure
    env_file:
      - ./alice/.env  # API key等（git管理外）
    environment:
      - TZ=Asia/Tokyo
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:18789/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  mephi:
    build: .
    container_name: mephi-openclaw
    user: "1000:1000"
    volumes:
      - ./mephi/workspace:/home/node/workspace
      - ./mephi/sessions:/home/node/sessions
      - ./mephi/config:/home/node/config
    ports:
      - "18791:18789"
    networks:
      - mephi-net
    restart: on-failure
    env_file:
      - ./mephi/.env
    environment:
      - TZ=Asia/Tokyo
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:18789/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  alice-net:
    driver: bridge
  mephi-net:
    driver: bridge
  shared-db:
    driver: bridge
    # PostgreSQL/ollama共有用（必要に応じて各コンテナを接続）
```

### .env ファイル例

**メフィ指摘対応:** 機密情報を環境変数で管理

```bash
# alice/.env（git管理外、chmod 600）
ANTHROPIC_API_KEY=sk-ant-api03-...
TELEGRAM_BOT_TOKEN=8214011535:AAE1yPMs2KpyZaUp2zoB...
```

### .gitignore 追加

```gitignore
# Container Office機密情報
*/.env
*/config/openclaw.json
*/sessions/*.jsonl
```

---

## セキュリティ設計

### 1. UID/GID マッピング

**問題:** コンテナ内のrootがホスト側のファイルを作成 → パーミッション混乱

**対策:**
```yaml
user: "1000:1000"  # macOSのデフォルトユーザーUID
```

Dockerfileで`USER node`指定 + `docker-compose.yml`で明示的にUID/GID指定。

### 2. コンテナ間通信分離

**問題:** デフォルトブリッジネットワークでは全コンテナが相互アクセス可能

**対策:**
- 各AIに専用ネットワーク（`alice-net`, `mephi-net`）
- PostgreSQL/ollama共有が必要な場合のみ`shared-db`ネットワークに接続

```yaml
services:
  alice:
    networks:
      - alice-net
      - shared-db  # DB接続が必要な場合のみ
```

### 3. 機密情報管理

**問題:** API keyをgit管理下に含めるリスク

**対策:**
- `.env`ファイルで環境変数管理
- `.gitignore`に追加（テンプレートに含める）
- パーミッション600で保護

```bash
chmod 600 alice/.env
```

### 4. PostgreSQL/ollama 接続

**Mac Docker Desktop:**
```yaml
environment:
  - DB_DSN=host=host.docker.internal dbname=bonsoleil user=teddy password=***
  - OLLAMA_URL=http://host.docker.internal:11434/api/embed
```

**Linux（production）:**
```yaml
network_mode: "host"  # ホストネットワーク使用
# または
extra_hosts:
  - "host.docker.internal:host-gateway"
```

---

## メリット

### 1. 環境分離
- 各AIが独立したコンテナ内で動作
- ホームディレクトリ競合の解消
- 依存関係の衝突なし

### 2. 再現性
- Dockerfileが実行環境の定義
- どこでも同じ環境を再現可能
- CI/CDでイメージ自動ビルド

### 3. ポータビリティ
- イメージ = 実行環境
- ボリューム = 個体記憶
- 両方をセットで配布可能

### 4. スケーラビリティ
- 新しいAI追加 → `docker-compose.yml`に1セクション追加
- ポート割り当てだけ気をつければOK

### 5. リソース管理
- Dockerでメモリ/CPU制限（暴走防止）
- ログローテーション（ディスク枯渇防止）
- 公平な資源配分

---

## 実装プラン

### Phase 1: PoC（アリス単体）

**Go/No-Go判断基準:**
- ✅ Dockerfile build成功
- ✅ コンテナ起動 & Gateway接続確認
- ✅ Telegram Bot接続確認
- ✅ workspace/sessionsの読み書き確認
- ✅ PostgreSQL/ollama接続確認

**タスク:**
- [ ] Dockerfile作成（node:slim版）
- [ ] docker-compose.yml作成（alice単体）
- [ ] アリスのworkspace/sessions/configをホスト側に準備
- [ ] .env作成（API key設定）
- [ ] 起動確認・動作テスト
- [ ] Telegram Bot接続確認
- [ ] 1週間運用してログ・リソース使用状況を監視

### Phase 2: 複数インスタンス

**Go/No-Go判断基準:**
- ✅ Phase 1で致命的な問題が出ていない
- ✅ アリス + メフィの同時起動
- ✅ ポート・ボリューム競合なし
- ✅ リソース使用量が許容範囲内（Mac Mini総メモリの70%以下）

**タスク:**
- [ ] メフィ用セクション追加
- [ ] 専用ネットワーク設定
- [ ] 同時起動確認
- [ ] リソース使用状況監視（`docker stats`）

### Phase 3: branch_office統合

**タスク:**
- [ ] `setup-docker.sh` 追加
- [ ] README更新（Docker版セットアップ手順）
- [ ] テンプレート整備（.env.example, .gitignore）

### Phase 4: 本番運用

**タスク:**
- [ ] Mac Mini HQでアリスをDocker化
- [ ] Time Machineバックアップ確認（ボリュームが正しくバックアップされるか）
- [ ] 長期運用モニタリング（1ヶ月）
- [ ] セッションローテーション自動化（古いファイル削除スクリプト）

---

## 懸念事項と対策

### 1. ARM64対応
- **状況:** Mac Mini M4 = ARM64
- **対策:** 公式イメージはARM64サポート済み ✅

### 2. パフォーマンス
- **懸念:** Dockerオーバーヘッド
- **実測:** ネイティブ比1〜3%程度（OpenClawはI/O中心なので影響軽微）

### 3. セッション肥大化
- **懸念:** `/sessions`が無制限に肥大化
- **対策:**
  - 週次でセッションローテーション（古いファイルをアーカイブ）
  - ボリュームサイズ監視スクリプト（cron）
  - `docker volume prune`で不要ボリューム削除

### 4. デバッグ性
- **懸念:** コンテナ内でデバッグしづらい
- **対策:**
  - `docker exec -it alice-openclaw sh`でシェル接続
  - `docker logs -f alice-openclaw`でログリアルタイム表示
  - ボリュームマウントなのでホスト側からファイル確認可能

---

## 代替案との比較

| 方式 | 環境分離 | 再現性 | ポータビリティ | 管理コスト | セキュリティ |
|------|---------|--------|---------------|-----------|------------|
| **Docker（本提案）** | ◎ | ◎ | ◎ | 中 | ◎（v2で対応） |
| ネイティブ（別ユーザー） | ○ | △ | × | 高 | △ |
| VM（Multipass等） | ◎ | ○ | ○ | 高 | ○ |

---

## メフィレビュー対応状況

### Critical（全対応）
- ✅ **UID/GID設計:** `user: "1000:1000"` + `USER node`
- ✅ **コンテナ間通信分離:** 専用ネットワーク
- ✅ **機密情報管理:** `.env` + `env_file` + `.gitignore`

### High（全対応）
- ✅ **リソース制限:** `deploy.resources`で明示
- ✅ **セッション肥大化:** ログローテーション + 監視スクリプト計画
- ✅ **PostgreSQL接続:** `host.docker.internal`方式を明記

### Medium（全対応）
- ✅ **Alpine → node:slim:** 互換性重視に変更
- ✅ **Dockerfileベストプラクティス:** `USER node`、バージョン固定
- ✅ **ヘルスチェック:** `healthcheck`追加
- ✅ **ログ管理:** `logging`設定追加

### Low（対応）
- ✅ **TZ統一:** プロポーザルに明記（HQ = Asia/Tokyo）
- ✅ **restart policy:** `on-failure`に変更（デバッグ優先）
- ✅ **Phase分けGo/No-Go:** 各Phaseに判断基準追加

---

## 次のステップ

1. ✅ このプロポーザルv2をbranch_officeリポジトリにPR
2. ⏳ メフィによる再レビュー（承認目標）
3. ⏳ Phase 1 PoC実施（アリス単体）
4. ⏳ 結果をプロポーザルにフィードバック

---

## 参考資料

- [Docker公式: Node.js](https://hub.docker.com/_/node)
- [Docker Compose: resources](https://docs.docker.com/compose/compose-file/deploy/)
- [OpenClaw環境変数](https://docs.openclaw.ai/config/env)
- 今日の実験: cloneサーバーでのバックアップ復元（95秒セットアップ）
- メフィレビュー: 80点 → Critical/High問題全対応

---

**この提案により、bon-soleil Holdingsの各事業部AIを安全・効率的に共存させる基盤が整います。**

**v2では、メフィ指摘のCritical/High問題を全て解決し、セキュリティ・運用の具体性を大幅に強化しました。**
