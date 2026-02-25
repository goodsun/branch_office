#!/bin/bash
# bon-soleil Holdings — Branch Office Setup
#
# 初回セットアップ: ディレクトリ展開 + Node.js + OpenClaw インストール
# このスクリプトは branch_office/ リポジトリ内から実行してください。
#
# Usage: ./setup.sh

set -e
trap 'echo "ERROR at line $LINENO"; exit 1' ERR

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

echo ""
echo "bon-soleil Holdings — Branch Office Setup"
echo "================================================="
echo ""

# ----- 1. ディレクトリ展開 -----
echo "Deploying branch office directories..."

DIRS="HR assets documents projects scripts"
for dir in $DIRS; do
  if [ -d "$HOME_DIR/$dir" ]; then
    echo "  [skip] ~/$dir (already exists)"
  else
    cp -r "$REPO_DIR/$dir" "$HOME_DIR/$dir"
    echo "  [copy] ~/$dir"
  fi
done

# template_config -> ~/config (初回コピーのみ)
if [ -d "$HOME_DIR/config" ]; then
  echo "  [skip] ~/config (already exists)"
elif [ -d "$REPO_DIR/template_config" ]; then
  cp -r "$REPO_DIR/template_config" "$HOME_DIR/config"
  echo "  [copy] template_config -> ~/config"
fi

# template_workspace -> ~/.openclaw/workspace (初回コピーのみ)
if [ -d "$HOME_DIR/.openclaw/workspace" ]; then
  echo "  [skip] ~/.openclaw/workspace (already exists)"
elif [ -d "$REPO_DIR/template_workspace" ]; then
  mkdir -p "$HOME_DIR/.openclaw"
  cp -r "$REPO_DIR/template_workspace" "$HOME_DIR/.openclaw/workspace"
  echo "  [copy] template_workspace -> ~/.openclaw/workspace"
fi

echo "  Done."

# ----- 2. 前提チェック -----
echo ""
echo "Checking prerequisites..."

# Node.js
if ! command -v node &> /dev/null; then
  echo ""
  echo "  Node.js not found. Installing via nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install --lts
  echo "  Node.js $(node -v) installed."
else
  echo "  Node.js $(node -v)"
fi

# ----- 3. OpenClaw インストール -----
if command -v openclaw &> /dev/null; then
  echo "  OpenClaw $(openclaw --version 2>/dev/null || echo '(installed)')"
else
  echo ""
  echo "  Installing OpenClaw..."
  npm install -g openclaw
  echo "  OpenClaw installed."
fi

# ----- 4. 完了 -----
echo ""
echo "================================================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Configure your API keys manually"
echo "     (e.g. openclaw agents add main)"
echo ""
echo "  2. Start OpenClaw Gateway:"
echo "     $ openclaw gateway start"
echo ""
echo "  3. The AI will read BOOTSTRAP.md and guide you"
echo "     through the interactive onboarding."
echo ""
echo "To sync updates later:"
echo "  $ cd $REPO_DIR && git pull && bash scripts/common/sync.sh"
echo ""
echo "Welcome to bon-soleil Holdings!"
echo ""
