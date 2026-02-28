# ─── Navigation ──────────────────────────────────────────
abbr -a -- .. "cd .."
abbr -a -- ... "cd ../.."

# ─── Modern CLI replacements ────────────────────────────
alias grep="rg"
alias htop="btop"
alias ps="procs"
alias cat="bat"
alias ls="eza --icons --group-directories-first"

# ─── Kubernetes ──────────────────────────────────────────
abbr -a k kubectl
abbr -a kx kubectx
abbr -a kn kubens

# ─── Git ─────────────────────────────────────────────────
abbr -a g git
abbr -a gs "git status"
abbr -a gd "git diff"
abbr -a gl "git log --oneline"

# ─── Docker ──────────────────────────────────────────────
abbr -a dc "docker compose"

# ─── OpenTofu ────────────────────────────────────────────
abbr -a tf tofu

# ─── Node ────────────────────────────────────────────────
alias npm="pnpm"

# ─── Gradle ──────────────────────────────────────────────
abbr -a be ./gradlew

# ─── Network ────────────────────────────────────────────
abbr -a myip "curl https://ipecho.net/plain; echo"

# ─── Repos ──────────────────────────────────────────────
abbr -a repo-sync "just -f ~/.macos-dotfiles/justfile repo-sync"
abbr -a repo-log "tail -f ~/.local/state/repo-sync.log"
