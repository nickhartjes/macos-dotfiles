# 3-Part Repo Restructure Design

**Date:** 2026-02-28
**Status:** Approved

## Goal

Restructure the single-repo setup into 3 clearly separated directories — apps, dotfiles, and mac settings — while keeping everything in one git repository.

## Directory Structure

```
.
├── apps/
│   └── Brewfile                 # all brew/cask/mas installs
│
├── dotfiles/
│   ├── stow/                    # stow packages (zsh, git, nvim, ghostty, etc.)
│   ├── themes/                  # theme definitions + _active marker
│   ├── scripts/                 # theme.sh and helpers
│   ├── templates/               # .gitconfig.local.tpl etc.
│   ├── init.sh                  # Bitwarden secrets setup
│   ├── repos.yaml               # repo definitions
│   └── repo-sync.sh             # clone/fetch repos
│
├── macos/
│   └── defaults.sh              # macOS system preferences
│
├── bootstrap.sh                 # minimal: install Homebrew + Brewfile, then "run just install"
├── justfile                     # root orchestrator
├── README.md
└── ...config files (.gitignore, .mega-linter.yml, etc.)
```

## Bootstrap (minimal)

`bootstrap.sh` only does two things:

1. Install Homebrew if missing
2. Run `brew bundle --file=apps/Brewfile` (installs everything including `just`)
3. Print instructions: "Run `just install` to complete setup"

No secrets, no stow, no defaults — those are `just` recipes.

## Justfile Recipes

| Recipe | What it does |
|---|---|
| `just install` | Runs `just apps` + `just dotfiles` + `just macos` in order |
| `just apps` | `brew bundle --file=apps/Brewfile` |
| `just dotfiles` | Runs init.sh, stows all packages, installs mise SDKs, sets up fzf |
| `just macos` | Runs `macos/defaults.sh` |
| `just init` | Just the Bitwarden secrets part |
| `just stow` / `just unstow` | Link/unlink dotfiles |
| `just theme` | Theme switcher |
| `just update` | Brew update + bundle + cleanup |
| `just doctor` | Health check |
| `just repo-sync` | Clone/fetch repos |
| `just dump` | Dump current brew state |
| `just clean` | Brew cleanup |
| `just lint` | MegaLinter |

## Migration Map

| Current location | New location |
|---|---|
| `Brewfile` | `apps/Brewfile` |
| `dotfiles/*` (stow packages) | `dotfiles/stow/*` |
| `themes/` | `dotfiles/themes/` |
| `scripts/` | `dotfiles/scripts/` |
| `templates/` | `dotfiles/templates/` |
| `init.sh` | `dotfiles/init.sh` |
| `repos.yaml` + `repos.yaml.example` | `dotfiles/` |
| `repo-sync.sh` | `dotfiles/repo-sync.sh` |
| `defaults.sh` | `macos/defaults.sh` |
| `bootstrap.sh` | Rewritten (minimal) |
| `justfile` | Rewritten (updated paths) |

## Design Decisions

- **justfile at root**: Single entry point for all operations after bootstrap
- **bootstrap.sh is minimal**: Only solves the chicken-and-egg problem (need Homebrew to install `just`)
- **Stow packages under dotfiles/stow/**: Separates stow packages from dotfiles infrastructure (themes, scripts, init)
- **Themes under dotfiles/**: Themes configure dotfile-managed tools, so they belong with dotfiles
- **Same repo**: All three parts stay in one repo for simplicity and atomic commits
