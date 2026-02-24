# Multi-Theme Support Design

## Problem

Theme configuration is hardcoded across 8 tools and 12+ files. Switching themes requires manually editing each file (as evidenced by the Catppuccin → Tokyo Night migration touching 15 files in commit c03a54e).

## Solution

A hybrid theme registry + per-tool handler system with an interactive FZF picker.

## Architecture

### Theme Registry (`themes/`)

Each theme is a self-contained directory:

```
themes/
  _active                      # plain text file: current theme name
  tokyo-night/
    theme.yaml                 # per-tool settings + color values
    btop.theme                 # custom btop theme file
    k9s.yaml                   # custom k9s skin file
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
```

### Theme Definition (`theme.yaml`)

Each theme.yaml maps the theme to per-tool identifiers and color values:

```yaml
name: Tokyo Night

# Tools with built-in theme support
ghostty: "Tokyo Night"
bat: "tokyonight_night"
btop: "tokyonight"
k9s: "tokyonight"

# Neovim plugin + colorscheme
nvim:
  plugin: "folke/tokyonight.nvim"
  opts: 'style = "night"'
  colorscheme: "tokyonight"

# Starship palette
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

# Lazygit color values
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

# FZF color values
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

### Switch Script (`scripts/theme.sh`)

A bash script with per-tool handler functions:

| Tool | Handler Action | Config File |
|------|---------------|-------------|
| Ghostty | sed `theme = ` line | `dotfiles/ghostty/.config/ghostty/config` |
| bat | sed `--theme=` line | `dotfiles/bat/.config/bat/config` |
| Neovim | Rewrite `colorscheme.lua` | `dotfiles/nvim/.config/nvim/lua/plugins/colorscheme.lua` |
| btop | Copy theme file + sed `color_theme` | `dotfiles/btop/.config/btop/btop.conf` + theme file |
| k9s | Copy skin file + sed `skin:` | `dotfiles/k9s/.config/k9s/config.yaml` + skin file |
| lazygit | Rewrite `gui.theme` section via yq | `dotfiles/lazygit/.config/lazygit/config.yml` |
| Starship | Rewrite palette line + colors section | `dotfiles/starship/.config/starship.toml` |
| FZF | Rewrite color lines in shell configs | `dotfiles/zsh/.zshrc` + `dotfiles/fish/.config/fish/conf.d/fzf.fish` |

The script modifies stow source files. Since stow creates symlinks, changes are immediately reflected in `~/.config/`.

### Justfile Integration

```
just theme              # Interactive FZF picker
just theme tokyo-night  # Direct switch (skip picker)
```

The picker:
- Lists subdirectories of `themes/` (excluding `_active`)
- Highlights the currently active theme
- Passes selection to `scripts/theme.sh`

### Neovim Plugin Strategy

All 6 theme plugins are listed in `lua/plugins/themes.lua` so LazyVim installs them all. The `colorscheme.lua` only controls which one is active. This avoids needing to run `:Lazy sync` on every theme switch.

## Themes at Launch

| Theme | Ghostty | Neovim Plugin | bat |
|-------|---------|--------------|-----|
| Tokyo Night | built-in | `folke/tokyonight.nvim` | built-in |
| Catppuccin Mocha | built-in | `catppuccin/nvim` | built-in |
| Gruvbox | built-in | `ellisonleao/gruvbox.nvim` | built-in |
| Nord | built-in | `shaunsingh/nord.nvim` | built-in |
| Dracula | built-in | `Mofiqul/dracula.nvim` | built-in |
| Rose Pine | built-in | `rose-pine/neovim` | built-in |

btop, k9s, lazygit, Starship, and FZF require custom theme files/values per theme.

## Error Handling

- Missing theme: script exits with error, lists available themes
- Missing yq: script exits with install instructions
- `themes/_active` defaults to `tokyo-night` (current state)

## Adding a New Theme

1. Create `themes/<name>/theme.yaml` with all per-tool settings
2. Add custom files (`btop.theme`, `k9s.yaml`) if needed
3. Add the Neovim plugin to `lua/plugins/themes.lua`
4. Run `just theme <name>` — done

## Adding a New Tool

1. Add a handler function to `scripts/theme.sh`
2. Add the tool's config key to each `theme.yaml`
