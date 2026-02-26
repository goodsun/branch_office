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

- セキュリティ上の問題など緊急のバグ修正は direct push も可
- ただし後から PR として変更を記録する

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
