# macOS dotfiles task runner

set dotenv-load := false

repo_dir := justfile_directory()
apps_dir := repo_dir / "apps"
dotfiles_dir := repo_dir / "dotfiles"
macos_dir := repo_dir / "macos"
stow_dir := dotfiles_dir / "stow"
stow_packages := "zsh fish git starship mise ghostty bat k9s aws fastfetch nvim lazygit ripgrep direnv btop"

# Run full setup (apps + dotfiles + macOS defaults)
install: apps dotfiles macos

# Install all Homebrew packages
apps:
    brew bundle --file={{apps_dir}}/Brewfile

# Set up dotfiles (init + stow + mise + fzf)
dotfiles: init stow
    #!/bin/sh
    echo "Installing mise SDK versions..."
    if command -v mise >/dev/null 2>&1; then
        mise install
        echo "mise SDKs installed"
    else
        echo "mise not found, skipping SDK install"
    fi
    echo "Setting up fzf key bindings..."
    FZF_INSTALL="$(brew --prefix)/opt/fzf/install"
    if [ -x "$FZF_INSTALL" ]; then
        "$FZF_INSTALL" --key-bindings --completion --no-update-rc --no-bash --no-fish
        echo "fzf key bindings installed"
    else
        echo "fzf install script not found"
    fi

# Apply macOS system preferences
macos:
    sh {{macos_dir}}/defaults.sh

# Set up local secrets from Bitwarden
init:
    sh {{dotfiles_dir}}/init.sh

# Link all dotfiles via stow
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

# Update Homebrew and all packages (removes unlisted packages)
update:
    brew update
    brew bundle --file={{apps_dir}}/Brewfile
    brew bundle cleanup --force --file={{apps_dir}}/Brewfile
    brew cleanup

# Re-apply macOS defaults
defaults:
    sh {{macos_dir}}/defaults.sh

# Dump current Homebrew state to Brewfile
dump:
    brew bundle dump --force --file={{apps_dir}}/Brewfile

# Cleanup Homebrew (remove unused deps and cache)
clean:
    brew cleanup
    brew autoremove

# Clone or fetch all repositories defined in repos.yaml
repo-sync:
    sh {{dotfiles_dir}}/repo-sync.sh

# Run all linters via MegaLinter
lint:
    docker run --rm -v {{repo_dir}}:/tmp/lint:rw oxsecurity/megalinter-cupcake:v8 mega-linter-runner

# Verify environment is healthy
doctor:
    #!/bin/sh
    ok()   { printf "  \033[0;32m✓\033[0m %s\n" "$1"; }
    fail() { printf "  \033[0;31m✗\033[0m %s\n" "$1"; }
    echo "Checking environment..."
    command -v brew >/dev/null 2>&1 && ok "Homebrew installed" || fail "Homebrew not installed"
    command -v bw >/dev/null 2>&1 && ok "Bitwarden CLI installed" || fail "Bitwarden CLI not installed"
    command -v gpg >/dev/null 2>&1 && ok "GPG installed" || fail "GPG not installed"
    command -v stow >/dev/null 2>&1 && ok "Stow installed" || fail "Stow not installed"
    command -v mise >/dev/null 2>&1 && ok "mise installed" || fail "mise not installed"
    [ -f "$HOME/.gitconfig.local" ] && ok "~/.gitconfig.local exists" || fail "~/.gitconfig.local missing — run 'just init'"
    if [ -f "$HOME/.gitconfig.local" ]; then \
        key=$(grep signingkey "$HOME/.gitconfig.local" | awk '{print $3}'); \
        if [ -n "$key" ] && gpg --list-secret-keys "$key" >/dev/null 2>&1; then \
            ok "GPG signing key present"; \
        else \
            fail "GPG signing key not found — run 'just init'"; \
        fi; \
    fi
    all_linked=true; \
    for pkg in {{stow_packages}}; do \
        if ! stow -d {{stow_dir}} -t "$HOME" --no-folding -n --restow "$pkg" >/dev/null 2>&1; then \
            fail "Stow package '$pkg' has conflicts"; \
            all_linked=false; \
        fi; \
    done; \
    [ "$all_linked" = true ] && ok "All stow packages linked"

# Switch terminal theme across all tools
theme name="":
    #!/bin/sh
    if [ -z "{{name}}" ]; then \
        active=""; \
        if [ -f "{{dotfiles_dir}}/themes/_active" ]; then \
            active=$(cat "{{dotfiles_dir}}/themes/_active"); \
        fi; \
        themes_dir="{{dotfiles_dir}}/themes"; \
        selected=$( \
            for dir in "$themes_dir"/*/; do \
                slug=$(basename "$dir"); \
                [ -f "$dir/theme.yaml" ] || continue; \
                name=$(yq '.name' "$dir/theme.yaml"); \
                variant=$(yq '.variant // "dark"' "$dir/theme.yaml"); \
                printf "%s\t[%s]  %s\n" "$slug" "$variant" "$name"; \
            done \
            | sort -t'	' -k2,2 -k3,3 \
            | fzf --prompt="Theme: " \
                  --header="Current: $active" \
                  --with-nth=2.. \
                  --delimiter='\t' \
                  --preview="yq '.name' $themes_dir/{1}/theme.yaml" \
                  --preview-window=up:1 \
            | cut -f1); \
        if [ -n "$selected" ]; then \
            sh "{{dotfiles_dir}}/scripts/theme.sh" "$selected"; \
        fi; \
    else \
        sh "{{dotfiles_dir}}/scripts/theme.sh" "{{name}}"; \
    fi
