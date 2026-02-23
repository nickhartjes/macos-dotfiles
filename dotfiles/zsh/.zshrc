# ─── PATH ────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

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
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
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
fastfetch
