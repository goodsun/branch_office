# labo-portal システム設計

*by メフィ（bon-soleil CCO）— 2026-03-07*

---

## 概要

bon-soleil奥様（大学教授）向けのAIアシスタント＋文書管理システム。  
**みぃちゃん**（亡くなった飼い猫の名前）が中心エージェント。

---

## 設計思想

- **親しみやすさ最優先**（みぃちゃんというキャラクター）
- シンプルに始めて、必要になったら拡張する
- 研究者が技術知識なしで使えること
- bon-soleilシステムとは完全分離

---

## 構成要素

### エージェント
| 名前 | 役割 | 稼働場所 |
|------|------|---------|
| みぃちゃん（mie） | メインアシスタント | MBP 2024 Docker |
| りんちゃん（rin）| 奥様専用サブアシスタント（予定） | 未定 |

### スタック
- **LLM**: Gemini（初期）、Anthropic追加は必要を感じてから
- **RAG**: ChromaDB（単一ユーザー・数千文書規模で十分）
- **UI**: labo-portal（Flask or FastAPI、staff_portalから派生）
- **ランタイム**: OpenClaw（labo edition）

---

## RAG設計

### academic_rag コレクション
- bon-soleilのnote記事RAGとは**完全分離**（混ぜるな危険）
- 対象: 論文PDF、Word文書、テキストファイル
- 自動取り込み: フォルダ監視（watcher.py）
- チャンク設計: 512トークン、オーバーラップ64

### データフロー
```
[論文PDF/Word] → [watcher.py] → [ingest.py] → [ChromaDB]
                                                      ↓
[みぃちゃんUI] ← [RAG検索] ←─────────────────────────┘
```

---

## labo-portal UI 要件

- ファイルアップロード → RAG自動取り込み
- みぃちゃんとのチャット（RAG参照）
- 生成文書のダウンロード（inbox/outbox）
- シンプル認証（パスワード1つ）

---

## フェーズ計画

| フェーズ | 内容 | 状態 |
|---------|------|------|
| Phase 0 | みぃちゃん起動・Telegram接続確認 | ✅ 完了 |
| Phase 1 | academic_rag ingest スクリプト | 🔄 PR #3 マージ待ち |
| Phase 2 | labo-portal UI 基本実装 | 📋 未着手 |
| Phase 3 | ファイルinbox/outbox | 📋 未着手 |
| Phase 4 | labo edition Docker設定 | 📋 Issue #1 |
| Phase 5 | りんちゃん追加 | 📋 未定 |

---

## 関連リポジトリ

- `goodsun/rag` — RAGシステム（PR #3: academic-rag）
- `goodsun/openclaw-docker` — Docker設定（Issue #1: labo edition）
- `goodsun/staff_portal` — UI参考元

---

*「親しみやすさは、設計の最初から組み込むもの。後から足すものじゃない。」 — メフィ 😈*
