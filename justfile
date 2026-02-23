# macOS dotfiles task runner

set dotenv-load := false

dotfiles_dir := justfile_directory()
stow_dir := dotfiles_dir / "dotfiles"
stow_packages := "zsh git starship mise ghostty bat k9s aws"

# Set up local secrets from Bitwarden (run once on a new machine)
init:
    sh {{dotfiles_dir}}/init.sh

# Run full bootstrap
install:
    sh {{dotfiles_dir}}/bootstrap.sh

# Update Homebrew and all packages (removes unlisted packages)
update:
    brew update
    brew bundle --file={{dotfiles_dir}}/Brewfile
    brew bundle cleanup --force --file={{dotfiles_dir}}/Brewfile
    brew cleanup

# Re-link all dotfiles via stow
stow:
    #!/bin/sh
    for pkg in {{stow_packages}}; do \
        stow -d {{stow_dir}} -t "$HOME" --restow "$pkg" && \
        echo "Stowed $pkg"; \
    done

# Unlink all dotfiles via stow
unstow:
    #!/bin/sh
    for pkg in {{stow_packages}}; do \
        stow -d {{stow_dir}} -t "$HOME" -D "$pkg" && \
        echo "Unstowed $pkg"; \
    done

# Re-apply macOS defaults
defaults:
    sh {{dotfiles_dir}}/defaults.sh

# Dump current Homebrew state to Brewfile
dump:
    brew bundle dump --force --file={{dotfiles_dir}}/Brewfile

# Cleanup Homebrew (remove unused deps and cache)
clean:
    brew cleanup
    brew autoremove

# Run shellcheck on all shell scripts
check:
    shellcheck {{dotfiles_dir}}/bootstrap.sh {{dotfiles_dir}}/init.sh {{dotfiles_dir}}/defaults.sh

# Verify environment is healthy
doctor:
    #!/bin/sh
    ok()   { printf "  \033[0;32m✓\033[0m %s\n" "$1"; }
    fail() { printf "  \033[0;31m✗\033[0m %s\n" "$1"; }
    echo "Checking environment..."
    # Homebrew
    command -v brew >/dev/null 2>&1 && ok "Homebrew installed" || fail "Homebrew not installed"
    # Bitwarden CLI
    command -v bw >/dev/null 2>&1 && ok "Bitwarden CLI installed" || fail "Bitwarden CLI not installed"
    # GPG
    command -v gpg >/dev/null 2>&1 && ok "GPG installed" || fail "GPG not installed"
    # Stow
    command -v stow >/dev/null 2>&1 && ok "Stow installed" || fail "Stow not installed"
    # mise
    command -v mise >/dev/null 2>&1 && ok "mise installed" || fail "mise not installed"
    # Local git config
    [ -f "$HOME/.gitconfig.local" ] && ok "~/.gitconfig.local exists" || fail "~/.gitconfig.local missing — run 'just init'"
    # GPG key
    if [ -f "$HOME/.gitconfig.local" ]; then \
        key=$(grep signingkey "$HOME/.gitconfig.local" | awk '{print $3}'); \
        if [ -n "$key" ] && gpg --list-secret-keys "$key" >/dev/null 2>&1; then \
            ok "GPG signing key present"; \
        else \
            fail "GPG signing key not found — run 'just init'"; \
        fi; \
    fi
    # Stow links
    all_linked=true; \
    for pkg in {{stow_packages}}; do \
        if ! stow -d {{stow_dir}} -t "$HOME" --no-folding -n --restow "$pkg" >/dev/null 2>&1; then \
            fail "Stow package '$pkg' has conflicts"; \
            all_linked=false; \
        fi; \
    done; \
    [ "$all_linked" = true ] && ok "All stow packages linked"
