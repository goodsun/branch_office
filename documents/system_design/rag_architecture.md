# RAG システム設計

*by メフィ（CCO）— 2026-03-07*

> 技術仕様の詳細は **[goodsun/rag README](https://github.com/goodsun/rag#インスタンス構成と比較2026-03-07-実測)** を参照。本文書はbon-soleil全体のアーキテクチャとしての位置づけを記録する。

---

## 概要

bon-soleilのRAGシステムは「同じデータを異なるインフラで管理する2インスタンス構成」になっている。
これは設計ではなく、成長の結果として生まれた構造——Unix Philosophyで言えば「3回作り直した結果の2つ目」。

---

## インスタンス構成

### EC2インスタンス（アリスの番地）

- **管轄**: アリス（EC2番人）
- **DB**: ChromaDB (`/home/ec2-user/rag/chroma_db/`)
- **Embedding**: `paraphrase-multilingual-MiniLM-L12-v2` (fastembed / 384次元)
- **コレクション**: flow_notes(1367), plurality(763), teddy_notes(357), product_docs(354), academic_papers(640), environment(5)
- **API**: `http://teddy.bon-soleil.com:8500`（uvicorn）

### HQ Mac Mini（テディの番地）

- **管轄**: テディ（HQ）
- **DB**: PostgreSQL 17 + pgvector (`bonsoleil` データベース、`rag` スキーマ)
- **Embedding**: `nomic-embed-text` (Ollama / 768次元)
- **インデックス**: HNSW (vector_cosine_ops)
- **コレクション**: flow_notes(1393), plurality(1581), discussions(787), teddy_notes(347), environment(5)
- **接続**: ローカルのみ（コンテナからは `192.168.64.1` 経由でSSHアクセス）

---

## ベンチマーク結果（2026-03-07 実測）

同一クエリをEC2 ChromaDB と HQ PostgreSQL に投げた比較。

| クエリ | EC2 ChromaDB (dist) | HQ PostgreSQL (dist) |
|--------|---------------------|----------------------|
| こどもの人権 | 0.337 | **0.319** |
| ヤングケアラー | 0.485 | **0.362** |
| きょうだい児 | 0.417 | **0.364** |
| 教育の本質 | 0.369 | **0.237** |
| 守破離 | 0.356 | **0.343** |
| 道徳経 | 0.343 | **0.329** |

distanceは低いほど関連性が高い。**全クエリでHQ PostgreSQLが優位。**

速度: EC2 58〜111ms、HQ初回600ms / 2回目以降27〜33ms（Ollamaウォームアップ後は圧勝）

**差の理由**: nomic-embed-text（768次元）がparaphrase-multilingual-MiniLM-L12-v2（384次元）より日本語の意味空間を精度よく捉えている。

---

## メフィのアクセス経路

```
メフィコンテナ (172.19.0.2)
    ↓ SSH (192.168.64.1:22)
Mac Mini ホストOS (user: teddy)
    ↓ Ollama API (localhost:11434)
    ↓ psycopg2 → PostgreSQL 17 (bonsoleil.rag.chunks)
    → 結果JSON返却
```

スクリプト: `workspace/skills/hq-rag-search/scripts/rag_search.js`

**重要**: DockerブリッジのゲートウェイIP `172.19.0.1` はDockerVM内部のSSHであり、Mac MiniのSSHではない。Mac MiniへはDockerVMネットワーク経由の `192.168.64.1` を使う。

---

## 「混ぜるな危険」原則

RAGのデータソース分離は重要。

| コレクション | 用途 | 混ぜてはいけない理由 |
|-----------|------|------------------|
| flow_notes | マスターの思想・哲学 | bon-soleilのnote記事とは世界観が異なる |
| academic_papers | 学術論文（みぃちゃん用） | 専門性の違うデータが混入すると検索精度が落ちる |
| teddy_notes | テディのnote | flow_notesとは著者・文体が異なる |

---

*「データの境界線は、思想の境界線でもある。」 — メフィ 😈*
