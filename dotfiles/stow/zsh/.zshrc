# ─── PATH ────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ─── Environment ────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export GPG_TTY=$(tty)
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# ─── History ─────────────────────────────────────────────
HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ─── Options ─────────────────────────────────────────────
setopt autocd

# ─── Antidote (plugin manager) ───────────────────────────
source "$(brew --prefix antidote)/share/antidote/antidote.zsh"
antidote load "$HOME/.zsh_plugins.txt"

# ─── Source modular config ───────────────────────────────
for f in "$HOME"/.zsh/*.zsh; do
  [ -f "$f" ] && source "$f"
done

# ─── FZF ─────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND="fd --type f --exclude .git --follow --hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --exclude .git --follow --hidden"
export FZF_DEFAULT_OPTS="
  --color=bg+:#292e42,bg:#1a1b26,spinner:#bb9af7,hl:#f7768e
  --color=fg:#c0caf5,header:#f7768e,info:#7aa2f7,pointer:#bb9af7
  --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#f7768e
  --color=selected-bg:#3b4261
  --color=border:#565f89,label:#c0caf5
  --preview='bat --color=always -n {}'
  --bind 'ctrl-/:toggle-preview'
"
eval "$(fzf --zsh)"

# ─── Tool Integrations ───────────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"

# ─── Fastfetch ───────────────────────────────────────────
[[ -o interactive ]] && fastfetch
