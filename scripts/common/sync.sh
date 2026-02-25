#!/bin/bash
# bon-soleil Holdings — Branch Office Sync
#
# 本社(branch_officeリポジトリ)から共通ファイルを同期します。
# 共通ファイルは強制上書き（本社が正）。ローカル固有ファイルには触れません。
#
# Usage: cd ~/branch_office && git pull && bash scripts/common/sync.sh

set -e
trap 'echo "ERROR at line $LINENO"; exit 1' ERR

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOME_DIR="$HOME"

echo ""
echo "bon-soleil Holdings — Sync"
echo "================================"
echo "Source: $REPO_DIR"
echo ""

# ----- 1. 社則 (company_rules) — 強制上書き -----
echo "[sync] documents/company_rules/"
mkdir -p "$HOME_DIR/documents/company_rules"
cp -r "$REPO_DIR/documents/company_rules/"* "$HOME_DIR/documents/company_rules/"

# ----- 2. 共通スクリプト (scripts/common) — 強制上書き -----
echo "[sync] scripts/common/"
mkdir -p "$HOME_DIR/scripts/common"
cp -r "$REPO_DIR/scripts/common/"* "$HOME_DIR/scripts/common/"

# ----- 3. HR (profiles, charsheets) — 強制上書き -----
echo "[sync] HR/"
mkdir -p "$HOME_DIR/HR"
cp -r "$REPO_DIR/HR/"* "$HOME_DIR/HR/"

# ----- 4. assets/charsheets — 強制上書き -----
if [ -d "$REPO_DIR/assets/charsheets" ] && ls "$REPO_DIR/assets/charsheets/"* &>/dev/null; then
  echo "[sync] assets/charsheets/"
  mkdir -p "$HOME_DIR/assets/charsheets"
  cp -r "$REPO_DIR/assets/charsheets/"* "$HOME_DIR/assets/charsheets/"
fi

echo ""
echo "================================"
echo "Sync complete!"
echo ""
