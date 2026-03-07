# labo-portal

bon-soleil奥様（大学教授）向けAIアシスタント＋研究文書管理システム。

## みぃちゃんについて

みぃちゃんは、マスターが昔飼っていた猫の名前を持つAIエージェント。  
「元気で、よく話しかけてくれる子だった」——その元気さを受け継いで、研究室に寄り添う存在として設計されている。

## 詳細設計

→ [/documents/system_design/labo_portal.md](/documents/system_design/labo_portal.md)

## 関連Issue/PR

- [openclaw-docker Issue #1](https://github.com/goodsun/openclaw-docker/issues/1) — labo edition Docker設定
- [rag PR #3](https://github.com/goodsun/rag/pull/3) — academic-rag実装

## 担当

- 設計・監査: メフィ（CCO）
- 実装: テディ / メフィ
- 運用: みぃちゃん


---

## 将来のユースケース（Vision）

### 教育機関向け展開

マスター（goodsun）にとって「教育」は人生の大きなテーマのひとつ。

奥様（栄養学博士）が取り組む「デジタル推進」活動——学生にAI・web3をエクスプロールさせたい——という方向性と、labo-portalの設計は自然に接続する。

#### 想定ユースケース

- **研究者向け**（現在設計中）: 論文管理・RAG・みぃちゃんとの対話
- **学生向けサンドボックス**（将来）: 安全に隔離された環境でAIを体験する

#### サンドボックス設計の要件

- ホストのファイルシステムと完全分離（volumeマウントなし）
- bon-soleilの他コンテナと分離（専用ネットワーク）
- クリーンなワークスペース（個人情報を持たない）
- モデルは差し替え可能（DeepSeek, Claude, Gemini等）
- 高性能マシン不要（クラウドAPIベース）

#### 技術的実現性

OpenClawはOpenAI互換APIをサポートしているため、
DeepSeekのような外部モデルへの切り替えは .env の変更のみで可能。
1学生1コンテナ、または共有コンテナの両方で対応できる。

> 「今後の世界をエクスプロールするのに必要」——これが出発点。
> 技術は手段。目的は、学生が自分の頭で考えられるようになること。

*記録日: 2026-03-07 by メフィ（CCO）😈*
