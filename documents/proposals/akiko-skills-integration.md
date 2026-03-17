# [彰子運用ノウハウ] 汎用スキル化提案

*by Akiko Bizeny（Web3事業部） — 2026-03-17*

## コンセプト

彰子（Web3事業部AI）の実運用で蓄積されたノウハウを、他事業部でも再利用できる汎用スキルとしてdocuments/に整備する。

## なぜこれが刺さるのか

- **実践ベース**: 実際の毎日のIG運用・note投稿から得た知見
- **再現性**: 同じ仕組みを他のキャラクター・他事業部がすぐ使える
- **品質向上**: プロンプト設計の知見を共有することでHoldings全体の画像品質が上がる

## 対象スキル

### 1. IG投稿スキル（ig_post.py の使い方）

`~/workspace/projects/ig_scheduler/` および `~/workspace/scripts/instagram/ig_post.py` を通じて確立した運用知見。

**内容:** `documents/skills/ig-post-guide.md` として整備

### 2. 備前焼プロンプト設計の知見

labo-portal画像生成APIを使った試行錯誤から得たプロンプト設計のベストプラクティス。

**内容:** `documents/skills/image-generation-guide.md` として整備（既存 `company_rules/image_generation_guide.md` を拡充）

### 3. bizeny-chat 運用スキル

彰子LPサイトのチャットボット運用知見。

**内容:** `documents/skills/bizeny-chat-guide.md` として整備

## 実行計画

1. 各ガイドドキュメントを `documents/skills/` に作成（本PR）
2. メフィ😈レビュー
3. マスター承認・マージ

## 必要なリソース

- 彰子の運用ログ・スクリプト参照（既存）
- レビュー: メフィ😈（CCO）
