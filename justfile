# macOS dotfiles task runner

set dotenv-load := false

dotfiles_dir := justfile_directory()
stow_dir := dotfiles_dir / "dotfiles"
stow_packages := "zsh git starship mise ghostty bat"

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
