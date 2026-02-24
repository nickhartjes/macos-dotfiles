#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
THEMES_DIR="$REPO_DIR/themes"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# ─── Portable sed -i ────────────────────────────────────────
sedi() {
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# ─── Dependency check ───────────────────────────────────────
command -v yq >/dev/null 2>&1 || {
    echo "Error: yq is required. Install with: brew install yq"
    exit 1
}

# ─── Theme selection ────────────────────────────────────────
THEME="${1:-}"
if [ -z "$THEME" ]; then
    echo "Usage: theme.sh <theme-name>"
    echo ""
    echo "Available themes:"
    for dir in "$THEMES_DIR"/*/; do
        name=$(basename "$dir")
        if [ -f "$dir/theme.yaml" ]; then
            display=$(yq '.name' "$dir/theme.yaml")
            active=""
            if [ -f "$THEMES_DIR/_active" ] && [ "$(cat "$THEMES_DIR/_active")" = "$name" ]; then
                active=" (active)"
            fi
            echo "  $name — $display$active"
        fi
    done
    exit 1
fi

THEME_DIR="$THEMES_DIR/$THEME"
THEME_YAML="$THEME_DIR/theme.yaml"

if [ ! -f "$THEME_YAML" ]; then
    echo "Error: Theme '$THEME' not found at $THEME_DIR"
    exit 1
fi

DISPLAY_NAME=$(yq '.name' "$THEME_YAML")
echo "Switching to $DISPLAY_NAME..."

# ─── Ghostty ────────────────────────────────────────────────
apply_ghostty() {
    local value
    value=$(yq '.ghostty' "$THEME_YAML")
    local config="$DOTFILES_DIR/ghostty/.config/ghostty/config"
    sedi "s/^theme = .*/theme = $value/" "$config"
    echo "  ✓ Ghostty"
}

# ─── bat ─────────────────────────────────────────────────────
apply_bat() {
    local value
    value=$(yq '.bat' "$THEME_YAML")
    local config="$DOTFILES_DIR/bat/.config/bat/config"
    sedi "s/^--theme=.*/--theme=\"$value\"/" "$config"
    echo "  ✓ bat"
}

# ─── Neovim ─────────────────────────────────────────────────
apply_nvim() {
    local plugin opts colorscheme
    plugin=$(yq '.nvim.plugin' "$THEME_YAML")
    opts=$(yq '.nvim.opts' "$THEME_YAML")
    colorscheme=$(yq '.nvim.colorscheme' "$THEME_YAML")
    local config="$DOTFILES_DIR/nvim/.config/nvim/lua/plugins/colorscheme.lua"
    cat > "$config" <<NVIM_EOF
return {
  {
    "$plugin",
    opts = { $opts },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "$colorscheme" },
  },
}
NVIM_EOF
    echo "  ✓ Neovim"
}

# ─── btop ────────────────────────────────────────────────────
apply_btop() {
    local value
    value=$(yq '.btop' "$THEME_YAML")
    local themes_dest="$DOTFILES_DIR/btop/.config/btop/themes"
    local config="$DOTFILES_DIR/btop/.config/btop/btop.conf"

    # Clear old theme files, copy new one
    rm -f "$themes_dest"/*.theme
    cp "$THEME_DIR/btop.theme" "$themes_dest/$value.theme"

    # Update config reference
    sedi "s/^color_theme = .*/color_theme = \"$value\"/" "$config"
    echo "  ✓ btop"
}

# ─── k9s ─────────────────────────────────────────────────────
apply_k9s() {
    local value
    value=$(yq '.k9s' "$THEME_YAML")
    local skins_dest="$DOTFILES_DIR/k9s/.config/k9s/skins"
    local config="$DOTFILES_DIR/k9s/.config/k9s/config.yaml"

    # Clear old skin files, copy new one
    rm -f "$skins_dest"/*.yaml
    cp "$THEME_DIR/k9s.yaml" "$skins_dest/$value.yaml"

    # Update config reference
    yq -i ".k9s.ui.skin = \"$value\"" "$config"
    echo "  ✓ k9s"
}

# ─── lazygit ─────────────────────────────────────────────────
apply_lazygit() {
    local config="$DOTFILES_DIR/lazygit/.config/lazygit/config.yml"

    local activeBorderColor inactiveBorderColor optionsTextColor selectedLineBgColor
    local cherryPickedCommitBgColor cherryPickedCommitFgColor unstagedChangesColor
    local defaultFgColor searchingActiveBorderColor authorColor

    activeBorderColor=$(yq '.lazygit.activeBorderColor' "$THEME_YAML")
    inactiveBorderColor=$(yq '.lazygit.inactiveBorderColor' "$THEME_YAML")
    optionsTextColor=$(yq '.lazygit.optionsTextColor' "$THEME_YAML")
    selectedLineBgColor=$(yq '.lazygit.selectedLineBgColor' "$THEME_YAML")
    cherryPickedCommitBgColor=$(yq '.lazygit.cherryPickedCommitBgColor' "$THEME_YAML")
    cherryPickedCommitFgColor=$(yq '.lazygit.cherryPickedCommitFgColor' "$THEME_YAML")
    unstagedChangesColor=$(yq '.lazygit.unstagedChangesColor' "$THEME_YAML")
    defaultFgColor=$(yq '.lazygit.defaultFgColor' "$THEME_YAML")
    searchingActiveBorderColor=$(yq '.lazygit.searchingActiveBorderColor' "$THEME_YAML")
    authorColor=$(yq '.lazygit.authorColor' "$THEME_YAML")

    cat > "$config" <<LAZYGIT_EOF
---
gui:
  theme:
    activeBorderColor:
      - "$activeBorderColor"
      - bold
    inactiveBorderColor:
      - "$inactiveBorderColor"
    optionsTextColor:
      - "$optionsTextColor"
    selectedLineBgColor:
      - "$selectedLineBgColor"
    cherryPickedCommitBgColor:
      - "$cherryPickedCommitBgColor"
    cherryPickedCommitFgColor:
      - "$cherryPickedCommitFgColor"
    unstagedChangesColor:
      - "$unstagedChangesColor"
    defaultFgColor:
      - "$defaultFgColor"
    searchingActiveBorderColor:
      - "$searchingActiveBorderColor"

authorColors:
  "*": "$authorColor"
LAZYGIT_EOF
    echo "  ✓ lazygit"
}

# ─── Starship ───────────────────────────────────────────────
apply_starship() {
    local config="$DOTFILES_DIR/starship/.config/starship.toml"
    local palette_name
    palette_name=$(yq '.starship.palette_name' "$THEME_YAML")

    # Update palette reference on line 1
    sedi "1s/.*/palette = \"$palette_name\"/" "$config"

    # Find where palette section starts and truncate there
    local line_num
    line_num=$(grep -n '^\[palettes\.' "$config" | head -1 | cut -d: -f1)
    if [ -n "$line_num" ]; then
        head -n $((line_num - 1)) "$config" > "${config}.tmp"
    else
        cp "$config" "${config}.tmp"
    fi

    # Append new palette section
    echo "[palettes.$palette_name]" >> "${config}.tmp"
    yq '.starship.colors | to_entries | .[] | .key + " = \"" + .value + "\""' "$THEME_YAML" >> "${config}.tmp"

    mv "${config}.tmp" "$config"
    echo "  ✓ Starship"
}

# ─── FZF (zsh + fish) ───────────────────────────────────────
apply_fzf() {
    local bg_plus bg spinner hl fg header info pointer marker fg_plus prompt hl_plus selected_bg border label
    bg_plus=$(yq '.fzf.bg_plus' "$THEME_YAML")
    bg=$(yq '.fzf.bg' "$THEME_YAML")
    spinner=$(yq '.fzf.spinner' "$THEME_YAML")
    hl=$(yq '.fzf.hl' "$THEME_YAML")
    fg=$(yq '.fzf.fg' "$THEME_YAML")
    header=$(yq '.fzf.header' "$THEME_YAML")
    info=$(yq '.fzf.info' "$THEME_YAML")
    pointer=$(yq '.fzf.pointer' "$THEME_YAML")
    marker=$(yq '.fzf.marker' "$THEME_YAML")
    fg_plus=$(yq '.fzf.fg_plus' "$THEME_YAML")
    prompt=$(yq '.fzf.prompt' "$THEME_YAML")
    hl_plus=$(yq '.fzf.hl_plus' "$THEME_YAML")
    selected_bg=$(yq '.fzf.selected_bg' "$THEME_YAML")
    border=$(yq '.fzf.border' "$THEME_YAML")
    label=$(yq '.fzf.label' "$THEME_YAML")

    local c1="  --color=bg+:${bg_plus},bg:${bg},spinner:${spinner},hl:${hl}"
    local c2="  --color=fg:${fg},header:${header},info:${info},pointer:${pointer}"
    local c3="  --color=marker:${marker},fg+:${fg_plus},prompt:${prompt},hl+:${hl_plus}"
    local c4="  --color=selected-bg:${selected_bg}"
    local c5="  --color=border:${border},label:${label}"

    # ── zsh ──
    local zshrc="$DOTFILES_DIR/zsh/.zshrc"
    awk -v c1="$c1" -v c2="$c2" -v c3="$c3" -v c4="$c4" -v c5="$c5" '
        /^[[:space:]]*--color=/ && !replaced {
            print c1; print c2; print c3; print c4; print c5
            replaced=1; next
        }
        /^[[:space:]]*--color=/ { next }
        { print }
    ' "$zshrc" > "${zshrc}.tmp"
    mv "${zshrc}.tmp" "$zshrc"

    # ── fish ──
    local fish_fzf="$DOTFILES_DIR/fish/.config/fish/conf.d/fzf.fish"
    awk -v c1="$c1 \\\\" -v c2="$c2 \\\\" -v c3="$c3 \\\\" -v c4="$c4 \\\\" -v c5="$c5 \\\\" '
        /^[[:space:]]*--color=/ && !replaced {
            print c1; print c2; print c3; print c4; print c5
            replaced=1; next
        }
        /^[[:space:]]*--color=/ { next }
        { print }
    ' "$fish_fzf" > "${fish_fzf}.tmp"
    mv "${fish_fzf}.tmp" "$fish_fzf"

    echo "  ✓ FZF (zsh + fish)"
}

# ─── Apply all ───────────────────────────────────────────────
apply_ghostty
apply_bat
apply_nvim
apply_btop
apply_k9s
apply_lazygit
apply_starship
apply_fzf

# ─── Record active theme ────────────────────────────────────
echo -n "$THEME" > "$THEMES_DIR/_active"

echo ""
echo "Done! $DISPLAY_NAME applied to all tools."
echo "Restart apps to see changes."
