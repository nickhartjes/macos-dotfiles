# ─── PATH ────────────────────────────────────────────────
fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
fish_add_path $HOME/.local/bin

# ─── Environment ────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GPG_TTY (tty)
set -gx RIPGREP_CONFIG_PATH $HOME/.config/ripgrep/config

# ─── Shell ──────────────────────────────────────────────
set -g fish_greeting

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
