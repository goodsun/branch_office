# Hetzner マルチエージェント設計

**作成**: 2026-03-14  
**ステータス**: 検討中

## 背景

- ボトルネックはLLMのAPI（外部）であり、VMのCPU/RAMではない
- openclawはnode.js常駐プロセスで1エージェントあたり数百MB程度
- 複数エージェントを1台のVMに載せることで費用対効果が高い

## 推奨VM構成

```
Hetzner CX21（2vCPU, 4GB RAM）月額〜€7程度
```

- エージェント2〜4人なら余裕で動く
- labo_portal（Node.js）も同居可能

## ディレクトリ構成

```
/home/
  alice/              ← アリス専用ユーザー
    .openclaw/        ← openclaw設定・認証
    workspace/        ← アリスのワークスペース
  bizeny/             ← 彰子専用ユーザー
    .openclaw/
    workspace/
  shared/             ← 共有リソース（任意）
    data/
      casts/
      docs/

/usr/local/bin/openclaw → /home/alice/.nvm/.../openclaw  ← シムリンク
```

## サービス管理（systemd）

各エージェントをsystemdサービスとして登録：

```ini
# /etc/systemd/system/openclaw-alice.service
[Unit]
Description=OpenClaw Gateway - Alice
After=network.target

[Service]
User=alice
WorkingDirectory=/home/alice
ExecStart=/usr/local/bin/openclaw gateway
Restart=on-failure
RestartSec=5s
Environment=HOME=/home/alice

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable openclaw-alice openclaw-bizeny
systemctl start openclaw-alice openclaw-bizeny
```

## ポート設計

| エージェント | gatewayポート | 備考 |
|---|---|---|
| alice | 18790 | Telegramボット |
| bizeny（彰子） | 18791 | Telegramボット |
| labo_portal | 8800 | nginxでリバースプロキシ |

## nginxリバースプロキシ

```nginx
server {
  listen 443 ssl;
  server_name bon-soleil.com;

  location /alice/ {
    proxy_pass http://localhost:18790/;
  }
  location /bizeny/ {
    proxy_pass http://localhost:18791/;
  }
  location /labo/ {
    proxy_pass http://localhost:8800/;
  }
}
```

## openclaw インストール方針

- alice ユーザーのnvmでopenclaw globalインストール
- `/usr/local/bin/openclaw` にシムリンクを貼る（全ユーザーから使用可能）
- 各ユーザーの `~/.openclaw/` は完全に独立

```bash
# aliceユーザーでインストール後
sudo ln -s $(which openclaw) /usr/local/bin/openclaw
```

## Mac（HQ）との違い

| | Mac HQ（現在） | Hetzner（予定） |
|---|---|---|
| 実行環境 | Docker（Rancher Desktop） | Linux直接 |
| オーバーヘッド | Docker+VM分のオーバーヘッドあり | なし（軽量） |
| 管理 | docker compose | systemd |
| 費用 | Mac本体コスト | 月額€7〜 |
| 可用性 | Macが落ちると全滅 | 常時稼働 |

## 移行計画

1. Hetzner VPSを作成（CX21）
2. aliceユーザー作成、nvmでnodeインストール
3. `openclaw@latest` グローバルインストール
4. `/usr/local/bin/openclaw` シムリンク
5. bizenyユーザー作成、シムリンク経由でsetup
6. systemdサービス登録
7. labo_portalをclone&build
8. nginxセットアップ、SSL証明書（Let's Encrypt）
9. Telegramトークン設定
10. 動作確認後、Mac HQの該当コンテナを停止
