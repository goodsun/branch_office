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
WORKSPACE="$HOME/workspace"

echo ""
echo "bon-soleil Holdings — Branch Office Setup"
echo "================================================="
echo ""

# ----- 1. ディレクトリ展開 -----
echo "Deploying branch office directories..."

# workspace初期化 (template_workspace -> ~/.openclaw/workspace)
if [ -d "$WORKSPACE" ]; then
  echo "  [skip] ~/workspace (already exists)"
elif [ -d "$REPO_DIR/template_workspace" ]; then
  cp -r "$REPO_DIR/template_workspace" "$WORKSPACE"
  echo "  [copy] template_workspace -> ~/workspace"
fi

# workspace内に配置するディレクトリ (エージェントがアクセスする全データ)
WS_DIRS="HR assets"
for dir in $WS_DIRS; do
  if [ -d "$WORKSPACE/$dir" ]; then
    echo "  [skip] workspace/$dir (already exists)"
  elif [ -d "$REPO_DIR/$dir" ]; then
    cp -r "$REPO_DIR/$dir" "$WORKSPACE/$dir"
    echo "  [copy] workspace/$dir"
  fi
done

# workspace内に配置するディレクトリ (ドキュメント・プロジェクト・スクリプト)
WS_EXTRA_DIRS="documents projects scripts"
for dir in $WS_EXTRA_DIRS; do
  if [ -d "$WORKSPACE/$dir" ]; then
    echo "  [skip] workspace/$dir (already exists)"
  elif [ -d "$REPO_DIR/$dir" ]; then
    cp -r "$REPO_DIR/$dir" "$WORKSPACE/$dir"
    echo "  [copy] workspace/$dir"
  fi
done

# template_config -> ~/workspace/config (初回コピーのみ)
if [ -d "$WORKSPACE/config" ]; then
  echo "  [skip] workspace/config (already exists)"
elif [ -d "$REPO_DIR/template_config" ]; then
  cp -r "$REPO_DIR/template_config" "$WORKSPACE/config"
  echo "  [copy] template_config -> workspace/config"
fi

echo "  Done."

# ----- 2. 前提チェック -----
echo ""
echo "Checking prerequisites..."

# Node.js
if ! command -v node &> /dev/null; then
  echo ""
  echo "  Node.js not found."
  echo "  Please install Node.js (v18+) first:"
  echo "    - nvm:      https://github.com/nvm-sh/nvm"
  echo "    - Homebrew:  brew install node"
  echo "    - dnf:       sudo dnf install nodejs"
  echo "    - apt:       sudo apt install nodejs"
  echo ""
  exit 1
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
