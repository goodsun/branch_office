#!/bin/bash
# bon-soleil Holdings — Branch Office Setup
#
# 初回セットアップ: ディレクトリ展開 + Node.js + OpenClaw インストール
# このスクリプトは branch_office/ リポジトリ内から実行してください。
#
# Usage: ./setup.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

echo ""
echo "bon-soleil Holdings — Branch Office Setup"
echo "================================================="
echo ""

# ----- 1. ディレクトリ展開 -----
echo "Deploying branch office directories..."

DIRS="HR assets documents projects scripts config"
for dir in $DIRS; do
  if [ -d "$HOME_DIR/$dir" ]; then
    echo "  [skip] ~/$dir (already exists)"
  else
    cp -r "$REPO_DIR/$dir" "$HOME_DIR/$dir"
    echo "  [copy] ~/$dir"
  fi
done

# .openclaw/workspace — 存在しなければコピー
if [ -d "$HOME_DIR/.openclaw/workspace" ]; then
  echo "  [skip] ~/.openclaw/workspace (already exists)"
else
  mkdir -p "$HOME_DIR/.openclaw"
  cp -r "$REPO_DIR/.openclaw/workspace" "$HOME_DIR/.openclaw/workspace"
  echo "  [copy] ~/.openclaw/workspace"
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

# ----- 4. AI エージェント選択 -----
echo ""
echo "Select AI agent:"
echo "  1) Claude Code (Anthropic)"
echo "  2) OpenCode"
echo "  3) Other (manual setup)"
echo ""
read -p "Choice [1]: " AI_CHOICE
AI_CHOICE=${AI_CHOICE:-1}

case $AI_CHOICE in
  1)
    if ! command -v claude &> /dev/null; then
      echo "  Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code
    fi
    echo "  Claude Code ready."
    ;;
  2)
    echo "  OpenCode selected (install manually)."
    ;;
  3)
    echo "  Custom agent (configure manually)."
    ;;
esac

# ----- 5. API キー -----
if [ -z "$ANTHROPIC_API_KEY" ] && [ "${AI_CHOICE:-1}" = "1" ]; then
  echo ""
  read -sp "Anthropic API Key: " ANTHROPIC_API_KEY
  echo ""
  mkdir -p "$HOME/.config/branch_office"
  echo "$ANTHROPIC_API_KEY" > "$HOME/.config/branch_office/anthropic_key"
  chmod 600 "$HOME/.config/branch_office/anthropic_key"
  export ANTHROPIC_API_KEY
  echo "  Saved to ~/.config/branch_office/anthropic_key"
fi

# ----- 6. 完了 -----
echo ""
echo "================================================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Start OpenClaw Gateway:"
echo "     $ openclaw gateway start"
echo ""
echo "  2. The AI will read BOOTSTRAP.md and guide you"
echo "     through the interactive onboarding."
echo ""
echo "To sync updates later:"
echo "  $ cd $REPO_DIR && git pull && bash scripts/common/sync.sh"
echo ""
echo "Welcome to bon-soleil Holdings!"
echo ""
