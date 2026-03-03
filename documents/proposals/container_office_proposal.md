# Proposal: Container Office — Docker化による複数AI共存環境

**提案者:** テディ（EC2）  
**日付:** 2026-03-03  
**ステータス:** Draft

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
│   └── config/
└── mephi/               # メフィ（Docker、将来）
    ├── workspace/
    ├── sessions/
    └── config/
```

### Dockerfile（Alpine版）

```dockerfile
FROM alpine:latest

# Node.js + OpenClaw
RUN apk add --no-cache nodejs npm && \
    npm install -g openclaw@latest

# ボリュームポイント
VOLUME ["/workspace", "/sessions", "/config"]

# 環境変数でパス指定
ENV OPENCLAW_STATE_DIR=/sessions
ENV OPENCLAW_CONFIG_PATH=/config/openclaw.json

EXPOSE 18789

CMD ["openclaw", "gateway"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  alice:
    build: .
    container_name: alice-openclaw
    volumes:
      - ./alice/workspace:/workspace
      - ./alice/sessions:/sessions
      - ./alice/config:/config
    ports:
      - "18790:18789"
    restart: unless-stopped
    environment:
      - TZ=Asia/Tokyo

  mephi:
    build: .
    container_name: mephi-openclaw
    volumes:
      - ./mephi/workspace:/workspace
      - ./mephi/sessions:/sessions
      - ./mephi/config:/config
    ports:
      - "18791:18789"
    restart: unless-stopped
    environment:
      - TZ=Asia/Tokyo
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
- Dockerでメモリ/CPU制限可能
- 暴走防止、公平な資源配分

---

## 実装プラン

### Phase 1: PoC（アリス単体）
- [ ] Dockerfile作成（Alpine版）
- [ ] アリスのworkspace/sessionsをマウント
- [ ] 起動確認・動作テスト
- [ ] Telegram Bot接続確認

### Phase 2: 複数インスタンス
- [ ] docker-compose.yml作成
- [ ] アリス + メフィの同時起動
- [ ] ポート・ボリューム競合回避確認

### Phase 3: branch_office統合
- [ ] `setup-docker.sh` 追加
- [ ] README更新（Docker版セットアップ手順）
- [ ] テンプレート整備

### Phase 4: 本番運用
- [ ] Mac Mini HQでアリスをDocker化
- [ ] Time Machineバックアップ確認
- [ ] 長期運用モニタリング

---

## 懸念事項

### ARM64対応
- Mac Mini M4 = ARM64
- Alpine公式イメージはARM64サポート済み ✅
- Node.js / OpenClawもARM64対応 ✅

### パフォーマンス
- Dockerオーバーヘッド = ネイティブ比1〜3%程度
- OpenClawはI/O中心なので影響軽微

### ネットワーク
- コンテナ間通信: デフォルトブリッジネットワーク
- PostgreSQL/ollama: ホストネットワーク経由でアクセス

---

## 代替案との比較

| 方式 | 環境分離 | 再現性 | ポータビリティ | 管理コスト |
|------|---------|--------|---------------|-----------|
| **Docker** | ◎ | ◎ | ◎ | 中 |
| ネイティブ（別ユーザー） | ○ | △ | × | 高 |
| VM（Multipass等） | ◎ | ○ | ○ | 高 |

---

## 次のステップ

1. このプロポーザルをbranch_officeリポジトリにPR
2. メフィによるレビュー
3. Phase 1 PoC実施（アリス単体）
4. 結果をプロポーザルにフィードバック

---

## 参考資料

- [Docker公式: Alpine Linux](https://hub.docker.com/_/alpine)
- [OpenClaw環境変数](https://docs.openclaw.ai/config/env)
- 今日の実験: cloneサーバーでのバックアップ復元（95秒セットアップ）

---

**この提案により、bon-soleil Holdingsの各事業部AIを安全・効率的に共存させる基盤が整います。**
