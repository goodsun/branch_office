#!/bin/bash
# bon-soleil Holdings — Branch Office Sync
#
# 本社(branch_officeリポジトリ)から共通ファイルを同期します。
# ローカル固有のファイルには触れません。
#
# Usage: cd ~/branch_office && git pull && bash scripts/common/sync.sh
#    or: bash ~/branch_office/scripts/common/sync.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOME_DIR="$HOME"

echo ""
echo "bon-soleil Holdings — Sync"
echo "================================"
echo "Source: $REPO_DIR"
echo ""

# ----- 1. 社則 (company_rules) -----
echo "[sync] documents/company_rules/"
mkdir -p "$HOME_DIR/documents/company_rules"
rsync -av --delete "$REPO_DIR/documents/company_rules/" "$HOME_DIR/documents/company_rules/"

# ----- 2. 共通スクリプト (scripts/common) -----
echo "[sync] scripts/common/"
mkdir -p "$HOME_DIR/scripts/common"
rsync -av --delete "$REPO_DIR/scripts/common/" "$HOME_DIR/scripts/common/"

# ----- 3. HR (profiles, charsheets) -----
echo "[sync] HR/"
mkdir -p "$HOME_DIR/HR"
rsync -av "$REPO_DIR/HR/" "$HOME_DIR/HR/"

# ----- 4. AGENTS.md (ワークスペース共通設定) -----
if [ -f "$REPO_DIR/.openclaw/workspace/AGENTS.md" ]; then
  echo "[sync] .openclaw/workspace/AGENTS.md"
  cp "$REPO_DIR/.openclaw/workspace/AGENTS.md" "$HOME_DIR/.openclaw/workspace/AGENTS.md"
fi

# ----- 5. SOUL.md.template (参考用、上書きはしない) -----
if [ -f "$REPO_DIR/.openclaw/workspace/SOUL.md.template" ]; then
  echo "[sync] .openclaw/workspace/SOUL.md.template"
  cp "$REPO_DIR/.openclaw/workspace/SOUL.md.template" "$HOME_DIR/.openclaw/workspace/SOUL.md.template"
fi

# ----- 6. assets/charsheets (共通キャラシート) -----
if [ -d "$REPO_DIR/assets/charsheets" ]; then
  echo "[sync] assets/charsheets/"
  mkdir -p "$HOME_DIR/assets/charsheets"
  rsync -av "$REPO_DIR/assets/charsheets/" "$HOME_DIR/assets/charsheets/"
fi

echo ""
echo "================================"
echo "Sync complete!"
echo ""
