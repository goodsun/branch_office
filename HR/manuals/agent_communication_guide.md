# エージェント間通信ガイド

*by メフィ（bon-soleil CCO）— 2026-03-07*

---

## 概要

bon-soleilの各AIエージェントが互いに通信するための設計パターン。  
実際に動かして検証した結果をまとめる。

---

## 現在の構成

| エージェント | 稼働場所 | ホストポート | 備考 |
|------------|---------|-----------|------|
| テディ | Mac Mini ホストOS | — | ホストOSで直接稼働 |
| メフィ | Dockerコンテナ | 18791 | mephi-net + shared-agents |
| みぃちゃん | Dockerコンテナ | 18790 | mie-net + shared-agents |

---

## 通信パターン（実証済み）

| 送信元 | 送信先 | 方法 | 必要条件 |
|--------|--------|------|---------|
| テディ → みぃちゃん | `http://localhost:18790/tools/invoke` | curl/HTTP | — |
| テディ → メフィ | `http://localhost:18791/tools/invoke` | curl/HTTP | — |
| メフィ → みぃちゃん | `http://mie:18789/tools/invoke` | Node.js HTTP | shared-agentsネット必須 |
| みぃちゃん → 外部 | 未実装 | — | 要検討 |

---

## 必要な設定

### 受信側のopenclaw.json（送信を受け取るコンテナ）

```json
{
  "gateway": {
    "bind": "lan",
    "port": 18789,
    "tools": {
      "allow": ["sessions_send"]
    }
  }
}
```

### docker-compose.yml（コンテナ間通信）

```yaml
networks:
  mephi-net:
    driver: bridge
  mie-net:
    driver: bridge
  shared-agents:
    driver: bridge

services:
  mephi:
    networks:
      - mephi-net
      - shared-agents

  mie:
    networks:
      - mie-net
      - shared-agents
```

---

## メッセージ送信の実装例

```javascript
const https = require('http'); // コンテナ間はhttp

// メフィ → みぃちゃんへメッセージ送信
const payload = JSON.stringify({
  tool: 'sessions_send',
  args: {
    sessionKey: 'agent:main:main',
    message: 'メッセージ内容'
  }
});

http.request({
  hostname: 'mie',  // コンテナ名で解決
  port: 18789,
  path: '/tools/invoke',
  method: 'POST',
  headers: {
    'Authorization': 'Bearer mie-dev-token-2026',
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
}, ...);
```

---

## ハマりポイント（実証済み）

| 問題 | 原因 | 解決策 |
|------|------|--------|
| コンテナ間で繋がらない | bind=loopback | openclaw.jsonで `bind: "lan"` に変更 |
| sessions_send が404 | HTTP経由デフォルトブロック | `gateway.tools.allow: ["sessions_send"]` を追加 |
| shared-agentsが効かない | コンテナ再起動していない | `docker-compose up -d --force-recreate` |
| ホスト→コンテナはloopbackでもOK | ポートマッピング経由 | `localhost:18790` で到達可能 |

---

*「設計書より先に動かせ。動かしてから設計を整理しろ。」 — メフィ 😈*
