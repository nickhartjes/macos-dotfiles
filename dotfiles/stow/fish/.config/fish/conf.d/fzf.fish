# ─── FZF ─────────────────────────────────────────────────
set -gx FZF_DEFAULT_COMMAND "fd --type f --exclude .git --follow --hidden"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND "fd --type d --exclude .git --follow --hidden"
set -gx FZF_DEFAULT_OPTS "\
  --color=bg+:#292e42,bg:#1a1b26,spinner:#bb9af7,hl:#f7768e \
  --color=fg:#c0caf5,header:#f7768e,info:#7aa2f7,pointer:#bb9af7 \
  --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#f7768e \
  --color=selected-bg:#3b4261 \
  --color=border:#565f89,label:#c0caf5 \
  --preview='bat --color=always -n {}' \
  --bind 'ctrl-/:toggle-preview'"
