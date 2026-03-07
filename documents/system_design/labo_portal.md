# labo-portal システム設計

*by メフィ（bon-soleil CCO）— 2026-03-07 改訂*

---

## コンセプト：工房（ラボ）

labo-portal は bon-soleil 全コンテナ共通の標準ポータル。

「工房」——AIたちが道具を整えて、実験して、磨いていく場所。  
staff_portal（EC2専用急造品）を廃止し、最初から汎用設計で作り直したもの。

> `goodsun/staff_portal` は歴史保存のため `goodsun/labo_portal` にリネーム済み。  
> 新実装はこのリポジトリで行う。

---

## 設計思想

- **どのdocker-openclaw環境でも動く**（EC2・Mac Mini・MBP・VPS、問わない）
- **3層プラグイン構成**（必要な機能だけ積む、設定で有効化）
- **急造品の反省を生かす**（継ぎ足しではなく、最初から構造を持つ）

---

## プラグイン3層構造

### Layer 1: コア（設定不要・即動く）

どのコンテナでも外部依存なしで動く。インストールしたら使える。

| プラグイン | 内容 | staff_portalからの継承 |
|-----------|------|-------------------|
| `document_viewer` | Markdown・PDF・テキスト表示 | Markdownビューア流用 |
| `asset_viewer` | 画像・3Dモデル閲覧 | charsheets/3Dビューア流用 |
| `services` | サービス管理（start/stop/restart） | services機能流用・改善 |
| `preset_manager` | キャラクタープリセット管理 | characters機能流用 |

### Layer 2: 標準プラグイン（コードは同梱・設定で有効化）

ほぼすべてのコンテナが使うが、外部サービスの設定が必要。  
`.env` または `openclaw.json` に設定を書くだけで有効化。

| プラグイン | 必要な設定 | 内容 |
|-----------|----------|------|
| `rag_search` | DB接続情報 or ChromaDB path | RAG検索UI・コレクション管理 |
| `image_gen` | Gemini / Stability APIキー | 画像生成・管理 |

### Layer 3: 固有プラグイン（コンテナ専用・自作）

コンテナの役割に特化した機能。自分たちで作る。

| プラグイン | 対象 | 内容 |
|-----------|------|------|
| `mie_chat` | みぃちゃん | RAG参照チャット |
| `file_inbox` | みぃちゃん | ファイルアップロード→RAG自動取り込み |
| `doc_outbox` | みぃちゃん | 生成文書ダウンロード |
| `cco_dashboard` | メフィ | CCO監査ダッシュボード（将来） |

---

## アーキテクチャ

```
labo-portal/
├── app.py              ← コア（認証・プラグインローダー・共通レイアウト）
├── core/
│   ├── auth.py         ← 認証（staff_auth依存なし、自前実装）
│   └── plugin.py       ← プラグインレジストリ（Blueprint自動登録）
├── plugins/
│   ├── document_viewer/   ← [Layer 1]
│   ├── asset_viewer/      ← [Layer 1]
│   ├── services/          ← [Layer 1]
│   ├── preset_manager/    ← [Layer 1]
│   ├── rag_search/        ← [Layer 2]
│   ├── image_gen/         ← [Layer 2]
│   └── (固有プラグイン)/  ← [Layer 3] コンテナごとに追加
└── static/ / templates/
```

---

## フェーズ計画

| フェーズ | 内容 | 状態 |
|---------|------|------|
| Phase 0 | リポジトリ整理（staff_portal → labo_portal リネーム） | ✅ 完了 |
| Phase 1 | コア設計・app.py・plugin.py・auth.py | 📋 未着手 |
| Phase 2 | Layer 1プラグイン4本 | 📋 未着手 |
| Phase 3 | Layer 2プラグイン（rag_search・image_gen） | 📋 未着手 |
| Phase 4 | みぃちゃん向けLayer 3プラグイン | 📋 未着手 |
| Phase 5 | 全コンテナへのデプロイ | 📋 未着手 |

---

## 認証設計

staff_authへの依存を断ち切り、自前実装。

- シンプルなセッション認証（パスワード1つ）
- ロールベース（admin / viewer）
- 環境変数で設定（`.env`）

---

## 関連

- リポジトリ: [goodsun/labo_portal](https://github.com/goodsun/labo_portal)（旧: staff_portal）
- RAG設計: [rag_architecture.md](./rag_architecture.md)

---

*「3層に分けるのは、混ぜるな危険の精神よ。」 — メフィ 😈*
