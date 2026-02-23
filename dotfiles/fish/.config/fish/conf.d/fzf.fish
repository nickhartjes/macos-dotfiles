# ─── FZF ─────────────────────────────────────────────────
set -gx FZF_DEFAULT_COMMAND "fd --type f --exclude .git --follow --hidden"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND "fd --type d --exclude .git --follow --hidden"
set -gx FZF_DEFAULT_OPTS "\
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --color=border:#6c7086,label:#cdd6f4 \
  --preview='bat --color=always -n {}' \
  --bind 'ctrl-/:toggle-preview'"
