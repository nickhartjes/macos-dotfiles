# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Modern CLI replacements
alias grep="rg"
alias htop="btop"
alias ps="procs"
alias cat="bat"
alias ls="eza --icons --group-directories-first"

# Kubernetes
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"

# Git
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline"

# Docker
alias dc="docker compose"

# OpenTofu
alias tf="tofu"

# Node
alias npm="pnpm"

# Gradle
alias be="./gradlew"

# Network
alias myip="curl https://ipecho.net/plain; echo"

# Repos
alias repo-sync="just -f ~/.macos-dotfiles/justfile repo-sync"
alias repo-log="tail -f ~/.local/state/repo-sync.log"
