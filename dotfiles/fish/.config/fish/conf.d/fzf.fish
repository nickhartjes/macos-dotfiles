# ─── FZF ─────────────────────────────────────────────────
set -gx FZF_DEFAULT_COMMAND "fd --type f --exclude .git --follow --hidden"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND "fd --type d --exclude .git --follow --hidden"
set -gx FZF_DEFAULT_OPTS "\
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 \
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 \
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 \
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4 \
  --preview='bat --color=always -n {}' \
  --bind 'ctrl-/:toggle-preview'"
