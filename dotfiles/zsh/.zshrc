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
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
  --color=border:#6c7086,label:#cdd6f4
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
