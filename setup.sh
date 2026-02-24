#!/bin/bash
# 🏢 bon-soleil Holdings — Branch Office Bootstrap
#
# このスクリプトはAIエージェントが動ける最低限の環境だけを整えます。
# セットアップの続きはAIが documents/company_rules/onboarding.md を読んで
# 対話式に進めます。
#
# Usage: ./setup.sh

set -e

echo ""
echo "🏢 bon-soleil Holdings — Branch Office Bootstrap"
echo "================================================="
echo ""

# ----- 1. 前提チェック -----
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "❌ $1 が見つかりません。インストールしてください。"
    exit 1
  fi
}

echo "📋 前提条件をチェックしています..."

# Node.js が無ければ nvm 経由で自動インストール
if ! command -v node &> /dev/null; then
  echo ""
  echo "📦 Node.js が見つかりません。自動インストールします..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install --lts
  echo "  ✅ Node.js $(node -v) をインストールしました"
else
  echo "  ✅ Node.js $(node -v)"
fi

# ----- 2. OpenClaw インストール -----
if command -v openclaw &> /dev/null; then
  echo "  ✅ OpenClaw $(openclaw --version 2>/dev/null || echo '(installed)')"
else
  echo ""
  echo "📦 OpenClawをインストールしています..."
  npm install -g openclaw
  echo "  ✅ OpenClaw インストール完了"
fi

# ----- 3. AI エージェント選択 -----
echo ""
echo "🤖 AIエージェントを選択してください:"
echo "  1) Claude Code (Anthropic)"
echo "  2) OpenCode"
echo "  3) その他 (手動設定)"
echo ""
read -p "選択 [1]: " AI_CHOICE
AI_CHOICE=${AI_CHOICE:-1}

case $AI_CHOICE in
  1)
    AI_AGENT="claude-code"
    if ! command -v claude &> /dev/null; then
      echo "📦 Claude Codeをインストールしています..."
      npm install -g @anthropic-ai/claude-code
    fi
    echo "  ✅ Claude Code"
    ;;
  2)
    AI_AGENT="opencode"
    echo "  ✅ OpenCode (手動でインストールしてください)"
    ;;
  3)
    AI_AGENT="custom"
    echo "  ✅ カスタムエージェント (手動設定)"
    ;;
esac

# ----- 4. OpenClaw Gateway 起動 -----
WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "🚀 OpenClaw Gatewayを設定しています..."
echo "  Workspace: $WORKSPACE_DIR/.openclaw/workspace"

# API キー確認
if [ -z "$ANTHROPIC_API_KEY" ] && [ "$AI_AGENT" = "claude-code" ]; then
  echo ""
  read -sp "🔑 Anthropic API Key を入力してください: " ANTHROPIC_API_KEY
  echo ""
  
  # ~/.config/ に保存（リポジトリ外 = git追跡されない）
  mkdir -p "$HOME/.config/branch_office"
  echo "$ANTHROPIC_API_KEY" > "$HOME/.config/branch_office/anthropic_key"
  chmod 600 "$HOME/.config/branch_office/anthropic_key"
  export ANTHROPIC_API_KEY
  echo "  ✅ APIキーを ~/.config/branch_office/anthropic_key に保存しました"
fi

# ----- 5. 完了 -----
echo ""
echo "================================================="
echo "✅ ブートストラップ完了！"
echo ""
echo "次のステップ:"
echo "  1. OpenClaw Gatewayを起動してください"
echo "     $ cd $WORKSPACE_DIR && openclaw gateway start"
echo ""
echo "  2. AIが起動したら、AIが自動的にセットアップを続けます。"
echo "     onboarding.md を読んで、対話式に設定を進めます。"
echo ""
echo "  初回起動時、AIは以下を行います:"
echo "    - config/division.json の設定（事業部名、タイムゾーン等）"
echo "    - .openclaw/workspace/SOUL.md の人格設定"
echo "    - HR/ のキャラクター登録"
echo ""
echo "🏢 Welcome to bon-soleil Holdings!"
echo ""
