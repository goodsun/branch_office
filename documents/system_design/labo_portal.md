# labo-portal システム設計

*by メフィ（bon-soleil CCO）— 2026-03-07 改訂*

---

## コンセプト：工房（ラボ）

labo-portal は bon-soleil 全コンテナ共通の標準ポータル。

「工房」——AIたちが道具を整えて、実験して、磨いていく場所。  
staff_portal（EC2専用急造品）を廃止し、最初から汎用設計で作り直したもの。

> `goodsun/staff_portal` は歴史保存のため `goodsun/labo-portal` にリネーム済み。  
> 新実装はこのリポジトリで行う。

---

## 設計思想

- **どのdocker-openclaw環境でも動く**（EC2・Mac Mini・MBP・VPS、問わない）
- **コア＋プラグイン構成**（必要な機能だけ積む）
- **急造品の反省を生かす**（継ぎ足しではなく、最初から構造を持つ）

---

## アーキテクチャ

```
labo-portal/
├── app.py              ← コア（認証・プラグインローダー・共通レイアウト）
├── core/
│   ├── auth.py         ← 認証（staff_auth依存なし、自前実装）
│   └── plugin.py       ← プラグインレジストリ（Blueprint自動登録）
├── plugins/            ← 機能プラグイン（独立したBlueprintモジュール）
│   ├── document_viewer/   ← Markdown・PDF・テキスト表示
│   ├── asset_viewer/      ← 画像・3Dモデル閲覧
│   ├── services/          ← サービス管理（start/stop/restart）
│   ├── preset_manager/    ← キャラクタープリセット管理
│   ├── mie_chat/          ← みぃちゃんチャット（RAG参照）★みぃちゃん専用
│   ├── file_inbox/        ← ファイルアップロード→RAG取り込み ★研究者向け
│   ├── doc_outbox/        ← 生成文書ダウンロード ★研究者向け
│   └── rag_admin/         ← ChromaDB/pgvectorコレクション管理
└── static/ / templates/
```

---

## コアプラグイン（全コンテナ共通）

| プラグイン | 内容 | staff_portalからの継承 |
|-----------|------|-------------------|
| `document_viewer` | MD・PDF・テキスト表示 | Markdownビューア流用 |
| `asset_viewer` | 画像・3Dモデル閲覧 | charsheets/3Dビューア流用 |
| `services` | サービス管理（start/stop） | services機能流用・改善 |
| `preset_manager` | キャラクタープリセット管理 | characters機能流用 |

## コンテナ固有プラグイン

| プラグイン | 対象コンテナ | 内容 |
|-----------|------------|------|
| `mie_chat` | みぃちゃん | RAG参照チャット |
| `file_inbox` | みぃちゃん・研究者向け | ファイルアップロード→RAG自動取り込み |
| `doc_outbox` | みぃちゃん | 生成文書ダウンロード |
| `rag_admin` | 全コンテナ（RAG持ちのみ） | コレクション管理 |
| `cco_dashboard` | メフィ | CCO監査ダッシュボード（将来） |

---

## フェーズ計画

| フェーズ | 内容 | 状態 |
|---------|------|------|
| Phase 0 | リポジトリ整理（staff_portal → labo-portal リネーム） | ✅ 完了 |
| Phase 1 | コア設計・app.py・plugin.py・auth.py | 📋 未着手 |
| Phase 2 | コアプラグイン4本（document/asset/services/preset） | 📋 未着手 |
| Phase 3 | みぃちゃん向けプラグイン（mie_chat・file_inbox・doc_outbox） | 📋 未着手 |
| Phase 4 | 全コンテナへのデプロイ | 📋 未着手 |
| Phase 5 | コンテナ固有プラグイン拡張 | 📋 未着手 |

---

## 認証設計

staff_authへの依存を断ち切り、自前実装。

- シンプルなセッション認証（パスワード1つ）
- ロールベース（admin / viewer）
- 環境変数で設定（`.env`）

---

## 関連

- リポジトリ: [goodsun/labo-portal](https://github.com/goodsun/labo-portal)（旧: staff_portal）
- 前身: `goodsun/staff_portal`（履歴参照）
- RAG設計: [rag_architecture.md](./rag_architecture.md)

---

*「工房は道具を揃えるところ。道具が揃ってはじめて、本当の仕事が始まる。」 — メフィ 😈*
