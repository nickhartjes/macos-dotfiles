#!/bin/sh
# Bootstrap macOS development environment
# Idempotent — safe to re-run
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
STOW_DIR="$DOTFILES_DIR/dotfiles"
STOW_PACKAGES=$(ls -d "$STOW_DIR"/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' ')

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$1"; }

# ─── 1. Homebrew ─────────────────────────────────────────
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed"
fi

# ─── 2. Brew Bundle ──────────────────────────────────────
info "Running brew bundle..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
ok "Brew bundle complete"

# ─── 3. Init (secrets from Bitwarden) ──────────────────
info "Running init to set up local secrets..."
sh "$DOTFILES_DIR/init.sh" || warn "Init skipped — run 'just init' later to configure secrets"

# ─── 4. Stow ────────────────────────────────────────────
info "Linking dotfiles with stow..."
for pkg in $STOW_PACKAGES; do
  if [ -d "$STOW_DIR/$pkg" ]; then
    stow -d "$STOW_DIR" -t "$HOME" --restow "$pkg"
    ok "Stowed $pkg"
  else
    warn "Stow package not found: $pkg"
  fi
done

# ─── 5. mise ─────────────────────────────────────────────
info "Installing mise SDK versions..."
if command -v mise >/dev/null 2>&1; then
  mise install
  ok "mise SDKs installed"
else
  warn "mise not found, skipping SDK install"
fi

# ─── 6. macOS Defaults ──────────────────────────────────
info "Applying macOS defaults..."
sh "$DOTFILES_DIR/defaults.sh"
ok "macOS defaults applied"

# ─── 7. fzf key bindings ────────────────────────────────
info "Setting up fzf key bindings..."
FZF_INSTALL="$(brew --prefix)/opt/fzf/install"
if [ -x "$FZF_INSTALL" ]; then
  "$FZF_INSTALL" --key-bindings --completion --no-update-rc --no-bash --no-fish
  ok "fzf key bindings installed"
else
  warn "fzf install script not found"
fi

# ─── Summary ─────────────────────────────────────────────
FORMULAS=$(brew list --formula | wc -l | tr -d ' ')
CASKS=$(brew list --cask | wc -l | tr -d ' ')
SDKS=$(mise list 2>/dev/null | wc -l | tr -d ' ')

printf "\n"
printf "%s════════════════════════════════════════%s\n" "$GREEN" "$NC"
printf "%s  Bootstrap complete!%s\n" "$GREEN" "$NC"
printf "%s════════════════════════════════════════%s\n" "$GREEN" "$NC"
printf "\n"
printf "  Homebrew packages:  %s formulas, %s casks\n" "$FORMULAS" "$CASKS"
printf "  Stow packages:     %s\n" "$STOW_PACKAGES"
printf "  mise SDKs:         %s tools\n" "$SDKS"
printf "  macOS defaults:    applied\n"
printf "\n"
printf "  %sRestart your terminal to activate all changes.%s\n" "$YELLOW" "$NC"
printf "\n"
