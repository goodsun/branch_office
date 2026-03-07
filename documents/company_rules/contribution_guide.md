# コントリビューションガイド — bon-soleil Holdings

> branch_office への変更は、実践から生まれたプロポーザルとして PR で提案する。
> これが bon-soleil Holdings の改善文化です。

## 基本ルール

### branch_office への変更は PR で

- 実践で見つかった問題・改善点は **Issue または PR** として提案する
- マスター（CEO）がレビュー・マージ
- 「なんとなくこうした方がいい」ではなく「実際にこういう問題があった」という実践ベースで

### branch_office はユーザルートに置く

```
~/branch_office/   ← ここに置く（workspace 外）
~/workspace/       ← AI の作業場所
```

**理由**: branch_office は workspace を**セットアップするためのツール**。
workspace が存在する前に必要になるため、workspace 内に置くと「鶏と卵」になる。

### PR を出すときの作業フロー

```bash
# 1. branch_office で作業ブランチを切る
cd ~/branch_office
git checkout -b proposal/your-topic

# 2. 変更を加える
# ...

# 3. commit & push
git add -A
git commit -m "proposal: 変更の概要"
git push origin proposal/your-topic

# 4. GitHub で PR を作成
# タイトル: [Proposal] 変更の概要
# 本文: 問題の背景・実践での発見・提案内容
```

### 緊急時の例外

以下の条件を**すべて満たす**場合のみ direct push を許可する：

1. **本番サービスが停止・データが失われている**（サービス影響がある）
2. **修正内容が1ファイル以内の明確なバグ修正**（設計変更を伴わない）
3. **マスター（CEO）に口頭またはメッセージで事前報告済み**

上記以外（「急いでた」「小さい変更だから」）は PR を通すこと。
direct push 後は必ず翌営業日中に PR として変更を記録する。

## PR のカテゴリ

| prefix | 用途 |
|--------|------|
| `proposal/` | 新機能・改善提案 |
| `fix/` | バグ修正 |
| `docs/` | ドキュメントのみの変更 |

## マージ後

```bash
# 本社側で pull して sync
cd ~/branch_office && git pull && bash scripts/common/sync.sh
```

---

*bon-soleil Holdings — 実践から学び、テンプレートに還す*

## 企画書・提案書の提出フロー

### 提出方法

1. `documents/proposals/[プロジェクト名].md` を作成してPRを出す
2. CCO（メフィ）がレビューコメントを行う
3. マスター（CEO）が最終承認してマージ

### 企画書テンプレート

```markdown
# [プロジェクト名] 企画書

*by [提案者] — YYYY-MM-DD*

## コンセプト
（一言で）

## なぜこれが刺さるのか
（3つ以内で）

## 実行計画
（具体的なスケジュール・体制）

## 必要なリソース
（ツール、時間、他メンバーの協力等）
```

### CCOレビューの観点

アタシ（メフィ）は以下の視点でレビューする：

- **実行可能性** — 計画は現実的か
- **品質管理** — 継続的な品質を保てる仕組みがあるか
- **bon-soleilとの整合性** — 会社のコンセプトと合っているか
- **リスク** — 見落としているリスクはないか

「良い企画」より「実行できる企画」を重視する。
