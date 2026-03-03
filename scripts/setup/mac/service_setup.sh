#!/bin/bash
# bon-soleil HQ セットアップスクリプト
# 使い方: bash setup.sh
# 前提: macOS (Apple Silicon), Homebrew未インストールでもOK

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

USERNAME=$(whoami)
HOME_DIR="/Users/$USERNAME"
WORKSPACE="$HOME_DIR/workspace"

echo ""
echo "=========================================="
echo "  bon-soleil HQ セットアップ"
echo "  ユーザー: $USERNAME"
echo "  ホーム:   $HOME_DIR"
echo "=========================================="
echo ""

# --- 1. Homebrew ---
info "Homebrew確認..."
if ! command -v brew &>/dev/null; then
  info "Homebrewをインストールします..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  success "Homebrew インストール済み"
fi

# --- 2. 必要パッケージ ---
info "パッケージインストール..."
PACKAGES=(git python3 postgresql@17 httpd openssl certbot pandoc)
for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    success "$pkg インストール済み"
  else
    info "$pkg をインストール..."
    brew install "$pkg"
  fi
done

# --- 3. Node.js (nvm) ---
info "nvm / Node.js確認..."
if [ ! -d "$HOME_DIR/.nvm" ]; then
  info "nvmをインストールします..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME_DIR/.nvm"
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
else
  success "nvm インストール済み"
fi

# --- 4. OpenClaw ---
info "OpenClaw確認..."
if ! command -v openclaw &>/dev/null; then
  info "OpenClawをインストールします..."
  npm install -g openclaw
else
  success "OpenClaw インストール済み"
fi

# --- 5. Python パッケージ ---
info "Pythonパッケージインストール..."
PY_PACKAGES=(flask flask-session flask-wtf uvicorn fastapi psycopg2-binary bcrypt werkzeug chromadb)
for pkg in "${PY_PACKAGES[@]}"; do
  pip3 install --break-system-packages "$pkg" -q && success "$pkg" || warn "$pkg インストール失敗（スキップ）"
done

# --- 6. ディレクトリ構成 ---
info "ディレクトリ構成..."
mkdir -p "$WORKSPACE"/{projects,documents,assets/tmp,config/ssl,logs}
mkdir -p "$WORKSPACE/documents/infra"
mkdir -p "$HOME_DIR/.config/bonsoleil"
mkdir -p "$HOME_DIR/www/images"
success "ディレクトリ作成済み"

# --- 7. オレオレ証明書 ---
info "SSL証明書確認..."
if [ ! -f "$WORKSPACE/config/ssl/fullchain.pem" ]; then
  info "オレオレ証明書を生成します（10年有効）..."
  read -p "ドメイン名 (例: local.bon-soleil.com): " DOMAIN
  LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "192.168.1.1")
  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -keyout "$WORKSPACE/config/ssl/privkey.pem" \
    -out "$WORKSPACE/config/ssl/fullchain.pem" \
    -subj "/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,IP:$LOCAL_IP"
  success "SSL証明書生成済み（$DOMAIN）"
else
  success "SSL証明書 既存"
fi

# --- 8. ~/.config/bonsoleil/gw_token ---
info "GWトークン確認..."
if [ ! -f "$HOME_DIR/.config/bonsoleil/gw_token" ]; then
  warn "GWトークンが未設定です"
  read -p "OpenClaw GWトークンを入力 (空でスキップ): " GW_TOKEN
  if [ -n "$GW_TOKEN" ]; then
    echo -n "$GW_TOKEN" > "$HOME_DIR/.config/bonsoleil/gw_token"
    chmod 600 "$HOME_DIR/.config/bonsoleil/gw_token"
    success "GWトークン保存済み"
  fi
else
  success "GWトークン 既存"
fi

# --- 9. plist インストール ---
info "LaunchAgents設定..."
PLIST_DIR="$HOME_DIR/Library/LaunchAgents"
mkdir -p "$PLIST_DIR"

install_plist() {
  local name="$1"
  local script_path="$2"
  local plist_file="$PLIST_DIR/com.bonsoleil.$name.plist"

  if [ ! -f "$script_path" ]; then
    warn "start.shが見つかりません: $script_path（スキップ）"
    return
  fi

  cat > "$plist_file" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.bonsoleil.$name</string>
    <key>ProgramArguments</key>
    <array>
        <string>$script_path</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>/tmp/$name.log</string>
    <key>StandardErrorPath</key><string>/tmp/$name.log</string>
</dict>
</plist>
PLIST

  launchctl unload "$plist_file" 2>/dev/null || true
  launchctl load "$plist_file"
  success "plist登録: com.bonsoleil.$name"
}

install_plist "chat-api"       "$WORKSPACE/projects/chat-api/start.sh"
install_plist "ragmyadmin"     "$WORKSPACE/projects/rag/admin/start.sh"
install_plist "staff-portal"   "$WORKSPACE/projects/staff_portal/start.sh"
install_plist "campfire-chat"  "$WORKSPACE/projects/campfire-chat/start.sh"
install_plist "plurality-chat" "$WORKSPACE/projects/plurality-chat/start.sh"
install_plist "voice-assistant" "$WORKSPACE/projects/voice-assistant/start.sh"

# --- 10. gitconfig ---
info "gitconfig設定..."
git config --global core.hooksPath ~/.config/git/hooks
mkdir -p ~/.config/git/hooks
success "gitconfig OK"

# --- 11. PostgreSQL ---
info "PostgreSQL確認..."
brew services start postgresql@17 2>/dev/null || true
success "PostgreSQL起動"

# --- 12. Apache ---
info "Apache確認..."
brew services start httpd 2>/dev/null || true
success "Apache起動"

# --- 13. OpenClaw Gateway ---
info "OpenClaw Gateway確認..."
if ! launchctl list | grep -q "ai.openclaw.gateway"; then
  warn "OpenClaw Gatewayが未起動です。手動で設定してください:"
  echo "  openclaw gateway install"
  echo "  openclaw configure"
else
  success "OpenClaw Gateway 起動中"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  セットアップ完了！${NC}"
echo "=========================================="
echo ""
echo "⚠️  手動で必要な作業:"
echo "  1. ~/.openclaw/openclaw.json のworkspaceパス確認"
echo "  2. Apache vhost設定 (/opt/homebrew/etc/httpd/extra/teddy-vhost.conf)"
echo "     → SSLパス・DocumentRootを環境に合わせて修正"
echo "  3. openclaw configure でAPIキー設定"
echo "  4. openclaw gateway install でGateway登録"
echo ""
