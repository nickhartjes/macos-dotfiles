# ─── PATH ────────────────────────────────────────────────
fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
fish_add_path $HOME/.local/bin

# ─── History ─────────────────────────────────────────────
set -g fish_history_size 5000

# ─── Fisher bootstrap ───────────────────────────────────
if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
    fisher update
end

# ─── Tool Integrations ──────────────────────────────────
starship init fish | source
zoxide init --cmd cd fish | source
direnv hook fish | source
mise activate fish | source

# ─── Fastfetch ──────────────────────────────────────────
if status is-interactive
    fastfetch
end
