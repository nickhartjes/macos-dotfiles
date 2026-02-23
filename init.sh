#!/bin/sh
# Populate local config files from Bitwarden
# Requires: bw (bitwarden-cli), jq, gpg
# Run: just init
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$1"; }

# ─── Check dependencies ────────────────────────────────────
for cmd in bw jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    warn "$cmd not found — run 'just install' first to install dependencies"
    exit 1
  fi
done

# ─── Bitwarden session ─────────────────────────────────────
if [ -z "$BW_SESSION" ]; then
  info "No BW_SESSION found. Log in and unlock Bitwarden:"
  echo ""
  echo "  bw login"
  echo "  export BW_SESSION=\$(bw unlock --raw)"
  echo "  just init"
  echo ""
  exit 1
fi

# ─── Fetch dotfiles item from Bitwarden ────────────────────
info "Fetching 'dotfiles' item from Bitwarden..."
BW_ITEM=$(bw get item "dotfiles" 2>/dev/null) || {
  warn "Bitwarden item 'dotfiles' not found. Create it with these custom fields:"
  echo ""
  echo "  GIT_USER_NAME     Your Name"
  echo "  GIT_USER_EMAIL    you@example.com"
  echo "  GIT_SIGNING_KEY   YOUR_GPG_KEY_ID"
  echo ""
  echo "  Optionally add a secure note named 'dotfiles/gpg' with your armored private key."
  echo ""
  exit 1
}

# ─── .gitconfig.local ──────────────────────────────────────
if [ -f "$HOME/.gitconfig.local" ]; then
  ok "~/.gitconfig.local already exists, skipping"
else
  GIT_USER_NAME=$(echo "$BW_ITEM" | jq -r '.fields[] | select(.name=="GIT_USER_NAME") | .value')
  GIT_USER_EMAIL=$(echo "$BW_ITEM" | jq -r '.fields[] | select(.name=="GIT_USER_EMAIL") | .value')
  GIT_SIGNING_KEY=$(echo "$BW_ITEM" | jq -r '.fields[] | select(.name=="GIT_SIGNING_KEY") | .value')

  sed \
    -e "s|\${GIT_USER_NAME}|$GIT_USER_NAME|" \
    -e "s|\${GIT_USER_EMAIL}|$GIT_USER_EMAIL|" \
    -e "s|\${GIT_SIGNING_KEY}|$GIT_SIGNING_KEY|" \
    "$DOTFILES_DIR/dotfiles/git/.gitconfig.local.tpl" > "$HOME/.gitconfig.local"

  ok "Created ~/.gitconfig.local"
fi

# ─── GPG private key ───────────────────────────────────────
GPG_KEY=$(bw get notes "dotfiles/gpg" 2>/dev/null) || true

if [ -n "$GPG_KEY" ]; then
  if command -v gpg >/dev/null 2>&1; then
    echo "$GPG_KEY" | gpg --import 2>/dev/null && ok "GPG key imported" || warn "GPG key import failed (may already exist)"
  else
    warn "gpg not found, skipping GPG key import"
  fi
else
  warn "No 'dotfiles/gpg' note found in Bitwarden, skipping GPG key import"
fi

ok "Init complete"
