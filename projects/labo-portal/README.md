# labo-portal

bon-soleil 全コンテナ共通の標準ポータル。

**工房**——AIたちが道具を整えて、実験して、磨いていく場所。

## 概要

- `goodsun/staff_portal`（EC2専用急造品）を廃止し、汎用設計で作り直したもの
- **コア＋プラグイン構成**：どの docker-openclaw 環境でも動く
- コアプラグイン（全コンテナ共通）＋ コンテナ固有プラグインを積み上げる設計

## コアプラグイン（全コンテナ共通）

| プラグイン | 内容 |
|-----------|------|
| `document_viewer` | Markdown・PDF・テキスト表示 |
| `asset_viewer` | 画像・3Dモデル閲覧 |
| `services` | サービス管理（start/stop/restart） |
| `preset_manager` | キャラクタープリセット管理 |

## みぃちゃんについて

みぃちゃんは、マスターが昔飼っていた猫の名前を持つAIエージェント。  
「元気で、よく話しかけてくれる子だった」——その元気さを受け継いで、研究室に寄り添う存在。

みぃちゃん専用プラグイン：`mie_chat`・`file_inbox`・`doc_outbox`

## 詳細設計

→ [/documents/system_design/labo_portal.md](/documents/system_design/labo_portal.md)

## 関連

- リポジトリ: [goodsun/labo-portal](https://github.com/goodsun/labo-portal)
- RAG設計: [rag_architecture.md](/documents/system_design/rag_architecture.md)
- openclaw-docker: [Issue #1](https://github.com/goodsun/openclaw-docker/issues/1)

## 担当

- 設計・監査: メフィ（CCO）
- 実装: テディ / メフィ
- 運用: みぃちゃん・各コンテナエージェント

---

*記録日: 2026-03-07 改訂 by メフィ（CCO）😈*
