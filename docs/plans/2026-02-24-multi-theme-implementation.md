# Multi-Theme Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a theme switching system with FZF picker that applies themes across 8 tools via `just theme`.

**Architecture:** Per-theme directories under `themes/` with `theme.yaml` definitions. A bash script (`scripts/theme.sh`) with per-tool handler functions reads the YAML and rewrites config files. Justfile recipe provides the FZF picker UI.

**Tech Stack:** Bash, yq (YAML processor), sed, awk, fzf, just

**Design doc:** `docs/plans/2026-02-24-multi-theme-support-design.md`

---

## Important Context

- **Stow symlinks:** Files in `dotfiles/<pkg>/.config/...` are symlinked to `~/.config/...` via GNU Stow. Modifying the stow source files updates the live config instantly.
- **Portable sed:** The project targets macOS (BSD sed) but may be tested on Linux (GNU sed). Use the `sedi` helper defined in the script for portable in-place editing.
- **yq is already installed:** Listed in the Brewfile (`brew "yq"`).
- **Current theme:** Tokyo Night, hardcoded across all 8 tool configs.

---

### Task 1: Create theme directory structure + Tokyo Night definition

**Files:**
- Create: `themes/_active`
- Create: `themes/tokyo-night/theme.yaml`
- Copy: `dotfiles/btop/.config/btop/themes/tokyonight.theme` → `themes/tokyo-night/btop.theme`
- Copy: `dotfiles/k9s/.config/k9s/skins/tokyonight.yaml` → `themes/tokyo-night/k9s.yaml`

**Step 1: Create directory structure**

```bash
mkdir -p themes/tokyo-night
```

**Step 2: Create `themes/_active`**

```
tokyo-night
```

(Plain text file, no trailing newline needed, just the theme directory name.)

**Step 3: Create `themes/tokyo-night/theme.yaml`**

Extract values from the current config files. The complete file:

```yaml
name: Tokyo Night

ghostty: "Tokyo Night"
bat: "tokyonight_night"
btop: "tokyonight"
k9s: "tokyonight"

nvim:
  plugin: "folke/tokyonight.nvim"
  opts: 'style = "night"'
  colorscheme: "tokyonight"

starship:
  palette_name: "tokyonight"
  colors:
    rosewater: "#f7768e"
    flamingo: "#f7768e"
    pink: "#bb9af7"
    mauve: "#bb9af7"
    red: "#f7768e"
    maroon: "#f7768e"
    peach: "#ff9e64"
    yellow: "#e0af68"
    green: "#9ece6a"
    teal: "#1abc9c"
    sky: "#7dcfff"
    sapphire: "#7dcfff"
    blue: "#7aa2f7"
    lavender: "#7aa2f7"
    text: "#c0caf5"
    subtext1: "#a9b1d6"
    subtext0: "#a9b1d6"
    overlay2: "#737aa2"
    overlay1: "#565f89"
    overlay0: "#545c7e"
    surface2: "#3b4261"
    surface1: "#292e42"
    surface0: "#232433"
    base: "#1a1b26"
    mantle: "#16161e"
    crust: "#13131e"

lazygit:
  activeBorderColor: "#7aa2f7"
  inactiveBorderColor: "#545c7e"
  optionsTextColor: "#7aa2f7"
  selectedLineBgColor: "#292e42"
  cherryPickedCommitBgColor: "#3b4261"
  cherryPickedCommitFgColor: "#7aa2f7"
  unstagedChangesColor: "#f7768e"
  defaultFgColor: "#c0caf5"
  searchingActiveBorderColor: "#e0af68"
  authorColor: "#bb9af7"

fzf:
  bg_plus: "#292e42"
  bg: "#1a1b26"
  spinner: "#bb9af7"
  hl: "#f7768e"
  fg: "#c0caf5"
  header: "#f7768e"
  info: "#7aa2f7"
  pointer: "#bb9af7"
  marker: "#9ece6a"
  fg_plus: "#c0caf5"
  prompt: "#7aa2f7"
  hl_plus: "#f7768e"
  selected_bg: "#3b4261"
  border: "#565f89"
  label: "#c0caf5"
```

**Step 4: Copy btop theme and k9s skin**

```bash
cp dotfiles/btop/.config/btop/themes/tokyonight.theme themes/tokyo-night/btop.theme
cp dotfiles/k9s/.config/k9s/skins/tokyonight.yaml themes/tokyo-night/k9s.yaml
```

These copies become the source of truth. The files in `dotfiles/` are the "active" copies that the switch script manages.

**Step 5: Verify**

```bash
diff themes/tokyo-night/btop.theme dotfiles/btop/.config/btop/themes/tokyonight.theme
diff themes/tokyo-night/k9s.yaml dotfiles/k9s/.config/k9s/skins/tokyonight.yaml
```

Expected: No differences.

**Step 6: Commit**

```bash
git add themes/
git commit -m "feat: add theme directory structure with Tokyo Night definition"
```

---

### Task 2: Write the switch script

**Files:**
- Create: `scripts/theme.sh`

**Step 1: Create `scripts/theme.sh`**

```bash
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
```

**Step 2: Make executable**

```bash
chmod +x scripts/theme.sh
```

**Step 3: Verify script syntax**

```bash
bash -n scripts/theme.sh
```

Expected: No output (no syntax errors).

**Step 4: Commit**

```bash
git add scripts/theme.sh
git commit -m "feat: add theme switch script with per-tool handlers"
```

---

### Task 3: Add Justfile recipe

**Files:**
- Modify: `justfile` (append after line 97)

**Step 1: Add the `theme` recipe to the Justfile**

Append the following at the end of `justfile`:

```just
# Switch terminal theme across all tools
theme name="":
    #!/bin/sh
    if [ -z "{{name}}" ]; then \
        active=""; \
        if [ -f "{{dotfiles_dir}}/themes/_active" ]; then \
            active=$(cat "{{dotfiles_dir}}/themes/_active"); \
        fi; \
        selected=$(ls -d "{{dotfiles_dir}}"/themes/*/  2>/dev/null \
            | xargs -I{} basename {} \
            | fzf --prompt="Theme: " \
                  --header="Current: $active" \
                  --preview="yq '.name' {{dotfiles_dir}}/themes/{}/theme.yaml" \
                  --preview-window=up:1); \
        if [ -n "$selected" ]; then \
            sh "{{dotfiles_dir}}/scripts/theme.sh" "$selected"; \
        fi; \
    else \
        sh "{{dotfiles_dir}}/scripts/theme.sh" "{{name}}"; \
    fi
```

**Step 2: Verify Justfile parses**

```bash
just --list
```

Expected: `theme` appears in the list with description "Switch terminal theme across all tools".

**Step 3: Commit**

```bash
git add justfile
git commit -m "feat: add just theme recipe with FZF picker"
```

---

### Task 4: Create Neovim themes.lua

All 6 theme plugins need to be installed so switching doesn't require `:Lazy sync`.

**Files:**
- Create: `dotfiles/nvim/.config/nvim/lua/plugins/themes.lua`

**Step 1: Create `dotfiles/nvim/.config/nvim/lua/plugins/themes.lua`**

```lua
-- All available theme plugins (installed by LazyVim).
-- The active theme is set in colorscheme.lua.
return {
  { "folke/tokyonight.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "ellisonleao/gruvbox.nvim" },
  { "shaunsingh/nord.nvim" },
  { "Mofiqul/dracula.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
}
```

**Step 2: Verify colorscheme.lua still works**

Confirm `dotfiles/nvim/.config/nvim/lua/plugins/colorscheme.lua` currently contains only the active theme config (no plugin spec duplication):

```lua
return {
  {
    "folke/tokyonight.nvim",
    opts = { style = "night" },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight" },
  },
}
```

This is correct — themes.lua handles plugin installation, colorscheme.lua handles activation.

**Step 3: Commit**

```bash
git add dotfiles/nvim/.config/nvim/lua/plugins/themes.lua
git commit -m "feat: install all theme plugins via themes.lua"
```

---

### Task 5: Smoke test — Tokyo Night idempotent switch

**Step 1: Run the switch script for the current theme**

```bash
./scripts/theme.sh tokyo-night
```

Expected output:
```
Switching to Tokyo Night...
  ✓ Ghostty
  ✓ bat
  ✓ Neovim
  ✓ btop
  ✓ k9s
  ✓ lazygit
  ✓ Starship
  ✓ FZF (zsh + fish)

Done! Tokyo Night applied to all tools.
Restart apps to see changes.
```

**Step 2: Verify no config drift**

```bash
git diff
```

Expected: No changes (or only trivial whitespace/formatting differences). If there are differences, fix the handlers so they produce byte-identical output for the current theme. This is important — the handlers must be faithful to the existing config format.

**Step 3: Fix any differences found**

Common issues to watch for:
- Trailing newlines in files
- Quote style differences (yq may output differently)
- TOML/YAML formatting differences

Iterate on handlers until `git diff` is clean after switching to `tokyo-night`.

**Step 4: Commit any handler fixes**

```bash
git add scripts/theme.sh
git commit -m "fix: ensure theme handlers produce idempotent output"
```

(Only if changes were needed.)

---

### Task 6: Create Catppuccin Mocha theme

**Files:**
- Create: `themes/catppuccin-mocha/theme.yaml`
- Create: `themes/catppuccin-mocha/btop.theme`
- Create: `themes/catppuccin-mocha/k9s.yaml`

**Step 1: Create `themes/catppuccin-mocha/theme.yaml`**

```yaml
name: Catppuccin Mocha

ghostty: "catppuccin-mocha"
bat: "Catppuccin Mocha"
btop: "catppuccin_mocha"
k9s: "catppuccin-mocha"

nvim:
  plugin: "catppuccin/nvim"
  opts: 'flavour = "mocha"'
  colorscheme: "catppuccin"

starship:
  palette_name: "catppuccin_mocha"
  colors:
    rosewater: "#f5e0dc"
    flamingo: "#f2cdcd"
    pink: "#f5c2e7"
    mauve: "#cba6f7"
    red: "#f38ba8"
    maroon: "#eba0ac"
    peach: "#fab387"
    yellow: "#f9e2af"
    green: "#a6e3a1"
    teal: "#94e2d5"
    sky: "#89dceb"
    sapphire: "#74c7ec"
    blue: "#89b4fa"
    lavender: "#b4befe"
    text: "#cdd6f4"
    subtext1: "#bac2de"
    subtext0: "#a6adc8"
    overlay2: "#9399b2"
    overlay1: "#7f849c"
    overlay0: "#6c7086"
    surface2: "#585b70"
    surface1: "#45475a"
    surface0: "#313244"
    base: "#1e1e2e"
    mantle: "#181825"
    crust: "#11111b"

lazygit:
  activeBorderColor: "#89b4fa"
  inactiveBorderColor: "#6c7086"
  optionsTextColor: "#89b4fa"
  selectedLineBgColor: "#313244"
  cherryPickedCommitBgColor: "#45475a"
  cherryPickedCommitFgColor: "#89b4fa"
  unstagedChangesColor: "#f38ba8"
  defaultFgColor: "#cdd6f4"
  searchingActiveBorderColor: "#f9e2af"
  authorColor: "#cba6f7"

fzf:
  bg_plus: "#313244"
  bg: "#1e1e2e"
  spinner: "#f5e0dc"
  hl: "#f38ba8"
  fg: "#cdd6f4"
  header: "#f38ba8"
  info: "#cba6f7"
  pointer: "#f5e0dc"
  marker: "#a6e3a1"
  fg_plus: "#cdd6f4"
  prompt: "#cba6f7"
  hl_plus: "#f38ba8"
  selected_bg: "#45475a"
  border: "#7f849c"
  label: "#cdd6f4"
```

**Step 2: Create `themes/catppuccin-mocha/btop.theme`**

Source the btop theme from the official Catppuccin btop repo. Search for `catppuccin/btop` on GitHub, find the Mocha theme file. It follows the same format as the existing `themes/tokyo-night/btop.theme` (84 `theme[key]="value"` lines). Use the Catppuccin Mocha palette:

| Role | Hex |
|------|-----|
| main_bg | `#1e1e2e` |
| main_fg | `#cdd6f4` |
| title | `#cdd6f4` |
| hi_fg | `#89b4fa` |
| selected_bg | `#313244` |
| selected_fg | `#89b4fa` |
| inactive_fg | `#7f849c` |
| graph_text | `#bac2de` |
| meter_bg | `#313244` |
| proc_misc | `#bac2de` |
| cpu_box | `#cba6f7` |
| mem_box | `#a6e3a1` |
| net_box | `#f38ba8` |
| proc_box | `#89b4fa` |
| div_line | `#6c7086` |
| temp_start/mid/end | `#a6e3a1` / `#f9e2af` / `#f38ba8` |
| cpu_start/mid/end | `#94e2d5` / `#89dceb` / `#89b4fa` |
| free_start/mid/end | `#cba6f7` / `#89b4fa` / `#89dceb` |
| cached_start/mid/end | `#89dceb` / `#89b4fa` / `#cba6f7` |
| available_start/mid/end | `#fab387` / `#f38ba8` / `#f38ba8` |
| used_start/mid/end | `#a6e3a1` / `#94e2d5` / `#89dceb` |
| download_start/mid/end | `#fab387` / `#f38ba8` / `#f38ba8` |
| upload_start/mid/end | `#a6e3a1` / `#94e2d5` / `#89dceb` |
| process_start/mid/end | `#89dceb` / `#89b4fa` / `#cba6f7` |

Write the file in the same format as `themes/tokyo-night/btop.theme`.

**Step 3: Create `themes/catppuccin-mocha/k9s.yaml`**

Source from the official Catppuccin k9s repo (`catppuccin/k9s` on GitHub). Write in the same YAML structure as `themes/tokyo-night/k9s.yaml` (102 lines), mapping the Catppuccin Mocha palette to k9s skin fields. Use the same field structure — only the hex color values change.

**Step 4: Commit**

```bash
git add themes/catppuccin-mocha/
git commit -m "feat: add Catppuccin Mocha theme definition"
```

---

### Task 7: Test theme switching — round-trip

**Step 1: Switch to Catppuccin Mocha**

```bash
./scripts/theme.sh catppuccin-mocha
```

Expected: All 8 handlers report success.

**Step 2: Verify config changes**

```bash
git diff
```

Verify each file was updated:
- `dotfiles/ghostty/.config/ghostty/config` → `theme = catppuccin-mocha`
- `dotfiles/bat/.config/bat/config` → `--theme="Catppuccin Mocha"`
- `dotfiles/nvim/.config/nvim/lua/plugins/colorscheme.lua` → catppuccin plugin
- `dotfiles/btop/.config/btop/btop.conf` → `color_theme = "catppuccin_mocha"`
- `dotfiles/btop/.config/btop/themes/catppuccin_mocha.theme` → new file
- `dotfiles/k9s/.config/k9s/config.yaml` → `skin: catppuccin-mocha`
- `dotfiles/k9s/.config/k9s/skins/catppuccin-mocha.yaml` → new file
- `dotfiles/lazygit/.config/lazygit/config.yml` → new colors
- `dotfiles/starship/.config/starship.toml` → new palette
- `dotfiles/zsh/.zshrc` → new FZF colors
- `dotfiles/fish/.config/fish/conf.d/fzf.fish` → new FZF colors
- `themes/_active` → `catppuccin-mocha`

**Step 3: Switch back to Tokyo Night**

```bash
./scripts/theme.sh tokyo-night
```

**Step 4: Verify clean state**

```bash
git diff
```

Expected: No differences — configs are back to their original state.

**Step 5: Fix any issues found**

If the round-trip isn't clean, fix the handlers and re-test. Common issues:
- File mode changes
- Trailing whitespace
- yq output format differences

---

### Task 8: Create Gruvbox theme

**Files:**
- Create: `themes/gruvbox/theme.yaml`
- Create: `themes/gruvbox/btop.theme`
- Create: `themes/gruvbox/k9s.yaml`

**Step 1: Create `themes/gruvbox/theme.yaml`**

Use the Gruvbox Dark palette. Key colors:

```yaml
name: Gruvbox Dark

ghostty: "GruvboxDark"
bat: "gruvbox-dark"
btop: "gruvbox_dark"
k9s: "gruvbox-dark"

nvim:
  plugin: "ellisonleao/gruvbox.nvim"
  opts: 'contrast = "hard"'
  colorscheme: "gruvbox"

starship:
  palette_name: "gruvbox_dark"
  colors:
    rosewater: "#d65d0e"
    flamingo: "#d65d0e"
    pink: "#d3869b"
    mauve: "#b16286"
    red: "#cc241d"
    maroon: "#fb4934"
    peach: "#fe8019"
    yellow: "#d79921"
    green: "#98971a"
    teal: "#689d6a"
    sky: "#83a598"
    sapphire: "#458588"
    blue: "#458588"
    lavender: "#83a598"
    text: "#ebdbb2"
    subtext1: "#d5c4a1"
    subtext0: "#bdae93"
    overlay2: "#a89984"
    overlay1: "#928374"
    overlay0: "#7c6f64"
    surface2: "#504945"
    surface1: "#3c3836"
    surface0: "#32302f"
    base: "#282828"
    mantle: "#1d2021"
    crust: "#1d2021"

lazygit:
  activeBorderColor: "#d79921"
  inactiveBorderColor: "#7c6f64"
  optionsTextColor: "#458588"
  selectedLineBgColor: "#3c3836"
  cherryPickedCommitBgColor: "#504945"
  cherryPickedCommitFgColor: "#d79921"
  unstagedChangesColor: "#cc241d"
  defaultFgColor: "#ebdbb2"
  searchingActiveBorderColor: "#fe8019"
  authorColor: "#b16286"

fzf:
  bg_plus: "#3c3836"
  bg: "#282828"
  spinner: "#d65d0e"
  hl: "#cc241d"
  fg: "#ebdbb2"
  header: "#458588"
  info: "#d79921"
  pointer: "#d65d0e"
  marker: "#98971a"
  fg_plus: "#ebdbb2"
  prompt: "#d79921"
  hl_plus: "#cc241d"
  selected_bg: "#504945"
  border: "#928374"
  label: "#ebdbb2"
```

**Step 2:** Create `themes/gruvbox/btop.theme` — same format as Tokyo Night btop.theme, mapped to Gruvbox Dark palette.

**Step 3:** Create `themes/gruvbox/k9s.yaml` — same structure as Tokyo Night k9s.yaml, mapped to Gruvbox Dark palette.

**Step 4: Commit**

```bash
git add themes/gruvbox/
git commit -m "feat: add Gruvbox Dark theme definition"
```

---

### Task 9: Create Nord theme

**Files:**
- Create: `themes/nord/theme.yaml`
- Create: `themes/nord/btop.theme`
- Create: `themes/nord/k9s.yaml`

**Step 1: Create `themes/nord/theme.yaml`**

```yaml
name: Nord

ghostty: "nord"
bat: "Nord"
btop: "nord"
k9s: "nord"

nvim:
  plugin: "shaunsingh/nord.nvim"
  opts: ""
  colorscheme: "nord"

starship:
  palette_name: "nord"
  colors:
    rosewater: "#d08770"
    flamingo: "#d08770"
    pink: "#b48ead"
    mauve: "#b48ead"
    red: "#bf616a"
    maroon: "#bf616a"
    peach: "#d08770"
    yellow: "#ebcb8b"
    green: "#a3be8c"
    teal: "#8fbcbb"
    sky: "#88c0d0"
    sapphire: "#81a1c1"
    blue: "#5e81ac"
    lavender: "#81a1c1"
    text: "#eceff4"
    subtext1: "#e5e9f0"
    subtext0: "#d8dee9"
    overlay2: "#4c566a"
    overlay1: "#434c5e"
    overlay0: "#3b4252"
    surface2: "#434c5e"
    surface1: "#3b4252"
    surface0: "#2e3440"
    base: "#2e3440"
    mantle: "#2e3440"
    crust: "#2e3440"

lazygit:
  activeBorderColor: "#88c0d0"
  inactiveBorderColor: "#4c566a"
  optionsTextColor: "#81a1c1"
  selectedLineBgColor: "#3b4252"
  cherryPickedCommitBgColor: "#434c5e"
  cherryPickedCommitFgColor: "#88c0d0"
  unstagedChangesColor: "#bf616a"
  defaultFgColor: "#eceff4"
  searchingActiveBorderColor: "#ebcb8b"
  authorColor: "#b48ead"

fzf:
  bg_plus: "#3b4252"
  bg: "#2e3440"
  spinner: "#b48ead"
  hl: "#bf616a"
  fg: "#eceff4"
  header: "#bf616a"
  info: "#88c0d0"
  pointer: "#b48ead"
  marker: "#a3be8c"
  fg_plus: "#eceff4"
  prompt: "#88c0d0"
  hl_plus: "#bf616a"
  selected_bg: "#434c5e"
  border: "#4c566a"
  label: "#eceff4"
```

**Step 2-3:** Create `themes/nord/btop.theme` and `themes/nord/k9s.yaml` using Nord palette colors.

**Step 4: Commit**

```bash
git add themes/nord/
git commit -m "feat: add Nord theme definition"
```

---

### Task 10: Create Dracula theme

**Files:**
- Create: `themes/dracula/theme.yaml`
- Create: `themes/dracula/btop.theme`
- Create: `themes/dracula/k9s.yaml`

**Step 1: Create `themes/dracula/theme.yaml`**

```yaml
name: Dracula

ghostty: "Dracula"
bat: "Dracula"
btop: "dracula"
k9s: "dracula"

nvim:
  plugin: "Mofiqul/dracula.nvim"
  opts: ""
  colorscheme: "dracula"

starship:
  palette_name: "dracula"
  colors:
    rosewater: "#ff79c6"
    flamingo: "#ff79c6"
    pink: "#ff79c6"
    mauve: "#bd93f9"
    red: "#ff5555"
    maroon: "#ff5555"
    peach: "#ffb86c"
    yellow: "#f1fa8c"
    green: "#50fa7b"
    teal: "#8be9fd"
    sky: "#8be9fd"
    sapphire: "#8be9fd"
    blue: "#6272a4"
    lavender: "#bd93f9"
    text: "#f8f8f2"
    subtext1: "#f8f8f2"
    subtext0: "#bfbfbf"
    overlay2: "#6272a4"
    overlay1: "#6272a4"
    overlay0: "#44475a"
    surface2: "#44475a"
    surface1: "#383a59"
    surface0: "#21222c"
    base: "#282a36"
    mantle: "#1e1f29"
    crust: "#191a21"

lazygit:
  activeBorderColor: "#bd93f9"
  inactiveBorderColor: "#6272a4"
  optionsTextColor: "#8be9fd"
  selectedLineBgColor: "#44475a"
  cherryPickedCommitBgColor: "#44475a"
  cherryPickedCommitFgColor: "#bd93f9"
  unstagedChangesColor: "#ff5555"
  defaultFgColor: "#f8f8f2"
  searchingActiveBorderColor: "#f1fa8c"
  authorColor: "#ff79c6"

fzf:
  bg_plus: "#44475a"
  bg: "#282a36"
  spinner: "#ff79c6"
  hl: "#ff5555"
  fg: "#f8f8f2"
  header: "#ff5555"
  info: "#bd93f9"
  pointer: "#ff79c6"
  marker: "#50fa7b"
  fg_plus: "#f8f8f2"
  prompt: "#bd93f9"
  hl_plus: "#ff5555"
  selected_bg: "#44475a"
  border: "#6272a4"
  label: "#f8f8f2"
```

**Step 2-3:** Create btop.theme and k9s.yaml using Dracula palette.

**Step 4: Commit**

```bash
git add themes/dracula/
git commit -m "feat: add Dracula theme definition"
```

---

### Task 11: Create Rose Pine theme

**Files:**
- Create: `themes/rose-pine/theme.yaml`
- Create: `themes/rose-pine/btop.theme`
- Create: `themes/rose-pine/k9s.yaml`

**Step 1: Create `themes/rose-pine/theme.yaml`**

```yaml
name: Rosé Pine

ghostty: "rose-pine"
bat: "rose-pine"
btop: "rose-pine"
k9s: "rose-pine"

nvim:
  plugin: "rose-pine/neovim"
  opts: ""
  colorscheme: "rose-pine"

starship:
  palette_name: "rose_pine"
  colors:
    rosewater: "#ebbcba"
    flamingo: "#ebbcba"
    pink: "#eb6f92"
    mauve: "#c4a7e7"
    red: "#eb6f92"
    maroon: "#eb6f92"
    peach: "#f6c177"
    yellow: "#f6c177"
    green: "#31748f"
    teal: "#9ccfd8"
    sky: "#9ccfd8"
    sapphire: "#31748f"
    blue: "#31748f"
    lavender: "#c4a7e7"
    text: "#e0def4"
    subtext1: "#e0def4"
    subtext0: "#908caa"
    overlay2: "#6e6a86"
    overlay1: "#524f67"
    overlay0: "#403d52"
    surface2: "#403d52"
    surface1: "#2a283e"
    surface0: "#1f1d2e"
    base: "#191724"
    mantle: "#1f1d2e"
    crust: "#191724"

lazygit:
  activeBorderColor: "#c4a7e7"
  inactiveBorderColor: "#6e6a86"
  optionsTextColor: "#31748f"
  selectedLineBgColor: "#2a283e"
  cherryPickedCommitBgColor: "#403d52"
  cherryPickedCommitFgColor: "#c4a7e7"
  unstagedChangesColor: "#eb6f92"
  defaultFgColor: "#e0def4"
  searchingActiveBorderColor: "#f6c177"
  authorColor: "#ebbcba"

fzf:
  bg_plus: "#2a283e"
  bg: "#191724"
  spinner: "#ebbcba"
  hl: "#eb6f92"
  fg: "#e0def4"
  header: "#eb6f92"
  info: "#c4a7e7"
  pointer: "#ebbcba"
  marker: "#31748f"
  fg_plus: "#e0def4"
  prompt: "#c4a7e7"
  hl_plus: "#eb6f92"
  selected_bg: "#403d52"
  border: "#524f67"
  label: "#e0def4"
```

**Step 2-3:** Create btop.theme and k9s.yaml using Rosé Pine palette.

**Step 4: Commit**

```bash
git add themes/rose-pine/
git commit -m "feat: add Rosé Pine theme definition"
```

---

### Task 12: Final verification — full round-trip

**Step 1: Cycle through all 6 themes**

```bash
for theme in tokyo-night catppuccin-mocha gruvbox nord dracula rose-pine; do
    echo "=== Testing: $theme ==="
    ./scripts/theme.sh "$theme"
    echo ""
done
```

Expected: All 6 themes apply without errors.

**Step 2: Verify final state**

```bash
cat themes/_active
```

Expected: `rose-pine` (last theme applied).

**Step 3: Switch back to Tokyo Night**

```bash
./scripts/theme.sh tokyo-night
```

**Step 4: Verify clean state**

```bash
git diff
```

Expected: No differences — back to the original Tokyo Night configs.

**Step 5: Test the FZF picker**

```bash
just theme
```

Expected: FZF picker appears showing all 6 themes with "Current: tokyo-night" header.

---

### Task 13: Final commit and cleanup

**Step 1: Ensure all files are committed**

```bash
git status
```

All theme directories and scripts should be tracked.

**Step 2: Verify the full file tree**

Expected structure:
```
themes/
  _active
  tokyo-night/
    theme.yaml
    btop.theme
    k9s.yaml
  catppuccin-mocha/
    theme.yaml
    btop.theme
    k9s.yaml
  gruvbox/
    theme.yaml
    btop.theme
    k9s.yaml
  nord/
    theme.yaml
    btop.theme
    k9s.yaml
  dracula/
    theme.yaml
    btop.theme
    k9s.yaml
  rose-pine/
    theme.yaml
    btop.theme
    k9s.yaml
scripts/
  theme.sh
dotfiles/
  nvim/.config/nvim/lua/plugins/themes.lua
```
