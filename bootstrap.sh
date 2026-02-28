#!/bin/sh
# Bootstrap macOS development environment
# Installs Homebrew and all packages (including just)
# After this, use 'just' for everything: just install
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }

# ─── 1. Homebrew ─────────────────────────────────────────
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed"
fi

# ─── 2. Install packages (includes just) ─────────────────
info "Running brew bundle..."
brew bundle --file="$REPO_DIR/apps/Brewfile"
ok "Brew bundle complete"

# ─── Done ─────────────────────────────────────────────────
printf "\n"
printf "%s════════════════════════════════════════%s\n" "$GREEN" "$NC"
printf "%s  Bootstrap complete!%s\n" "$GREEN" "$NC"
printf "%s════════════════════════════════════════%s\n" "$GREEN" "$NC"
printf "\n"
printf "  Next steps:\n"
printf "    %sjust install%s    Complete setup (dotfiles + macOS defaults)\n" "$YELLOW" "$NC"
printf "    %sjust init%s       Set up secrets from Bitwarden\n" "$YELLOW" "$NC"
printf "    %sjust doctor%s     Verify environment health\n" "$YELLOW" "$NC"
printf "\n"
