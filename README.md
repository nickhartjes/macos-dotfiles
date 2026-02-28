# macOS Dotfiles

<p align="center">
  <img src="assets/banner.svg" alt="macOS Dotfiles" width="100%">
</p>

<p align="center">
  <a href="#quick-start"><img src="https://img.shields.io/badge/Quick_Start-7aa2f7?style=flat-square" alt="Quick Start"></a>
  <a href="#whats-included"><img src="https://img.shields.io/badge/What's_Included-bb9af7?style=flat-square" alt="What's Included"></a>
  <a href="#secrets-management"><img src="https://img.shields.io/badge/Secrets-9ece6a?style=flat-square" alt="Secrets"></a>
</p>

GNU Stow-managed dotfiles, Homebrew packages, and macOS system preferences for Apple Silicon.

## Structure

```
apps/          Homebrew packages (Brewfile)
dotfiles/      Stow packages, themes, scripts, secrets setup
macos/         macOS system preferences and security defaults
```

- `apps/Brewfile` is the single source of truth for all installed packages
- `dotfiles/stow/` contains GNU Stow packages that symlink configs into `$HOME`
- `macos/defaults.sh` configures Finder, Dock, keyboard, security, and more

## Make It Your Own

1. **Fork** this repo
2. Edit `apps/Brewfile` to add/remove packages
3. Tweak configs under `dotfiles/stow/` (shell aliases, editor settings, themes)
4. Update the Bitwarden items with your own secrets (see [Secrets Management](#secrets-management))
5. Follow the Quick Start below

## Prerequisites

- macOS (Apple Silicon)
- A [Bitwarden](https://bitwarden.com/) account with the required items (see [Secrets Management](#secrets-management))

## Quick Start

```sh
# 1. Clone the repo
git clone https://github.com/<your-user>/homebrew.git ~/.homebrew
cd ~/.homebrew

# 2. Bootstrap (installs Homebrew + all packages including just)
sh bootstrap.sh

# 3. Complete setup (dotfiles + macOS defaults)
just install

# 4. Set up secrets from Bitwarden
bw login
export BW_SESSION=$(bw unlock --raw)
just init

# 5. Verify
just doctor
```

`bootstrap.sh` only installs Homebrew and runs the Brewfile (which includes `just`). After that, `just` handles everything.

## Commands

```sh
just install      # Full setup: apps + dotfiles + macOS defaults
just apps         # Install Homebrew packages only
just dotfiles     # Link dotfiles, install SDKs, set up fzf
just macos        # Apply macOS system preferences
just init         # Pull secrets from Bitwarden (needs BW_SESSION)
just update       # Install new packages, remove unlisted, cleanup
just stow         # Re-link all dotfiles
just unstow       # Unlink all dotfiles
just defaults     # Re-apply macOS preferences
just theme        # Switch terminal theme (interactive picker)
just repo-sync    # Clone/fetch repos from repos.yaml
just dump         # Export current brew state to Brewfile
just clean        # Remove unused deps and cache
just lint         # Run MegaLinter (shellcheck + yamllint + markdownlint)
just doctor       # Verify environment health
```

## How It Works

**Apps** — `apps/Brewfile` declares all Homebrew formulas, casks, and Mac App Store apps. `just update` installs additions and removes anything not in the Brewfile.

**Dotfiles** — managed with [GNU Stow](https://www.gnu.org/software/stow/). Each directory under `dotfiles/stow/` mirrors `$HOME` and is symlinked into place. Adding a new package: create `dotfiles/stow/<name>/` with the right structure and run `just stow`.

**macOS** — `macos/defaults.sh` sets system preferences idempotently. Run `just macos` to reapply.

**Secrets** — never committed. `.gitignore` excludes `repos.yaml`, and all secrets (`~/.gitconfig.local`, `~/.aws/credentials`) are generated at runtime by `just init` into locations outside the repo.

**Themes** — `just theme` switches the active theme across all configured tools (Ghostty, bat, Neovim, btop, k9s, lazygit, Starship, zsh, fish). Theme definitions live in `dotfiles/themes/`.

## What's Included

### Packages (Brewfile)

| Category | Packages |
|---|---|
| Bootstrap | bitwarden-cli, git, gnupg, just, mise, stow |
| Core CLI | bat, curl, direnv, eza, fd, fzf, gh, httpie, jq, neovim, ripgrep, shellcheck, starship, tldr, tree, wget, yq, zoxide |
| Shell | fish, antidote (zsh), btop, fastfetch, procs, taproom |
| Dev Tools | bun, gradle, lazygit, pnpm |
| Containers & Cloud | argocd, awscli, colima, docker, docker-compose, helm, k9s, kubectl, kubectx, kustomize, opentofu |
| Database | pgcli |
| IDEs & Editors | IntelliJ IDEA, VS Code, Zed |
| Terminal | Alacritty, Ghostty, iTerm2, Kitty, Warp, WezTerm |
| Browsers | Arc, Brave, Chromium, Firefox, Chrome, Edge, Orion, Vivaldi |
| Communication | Signal, Slack, Telegram |
| Productivity | Bitwarden, Raycast, Rectangle |
| Knowledge & Notes | Anytype, Archi, Obsidian |
| DevOps | OpenLens |
| AI | Claude, Claude Code, Codex, llmfit, LM Studio, opencode |
| Media | Spotify, VLC |
| Fonts | Fira Code, Hack, JetBrains Mono, Meslo, Monaspace (all Nerd Font) |

### Stow Packages

| Package | What it configures |
|---|---|
| `zsh` | Shell config with Antidote plugins, modular aliases/functions/completions |
| `fish` | Fish shell with Fisher, fzf.fish, kubectl/aws completions |
| `git` | Git config with GPG signing, aliases, global gitignore |
| `starship` | Prompt with git, languages, k8s, aws, opentofu modules |
| `mise` | SDK versions: JDK 21/17, Node LTS, Python 3.12 |
| `ghostty` | Terminal config |
| `nvim` | LazyVim with extras for Java, Python, TypeScript, YAML, Docker, Terraform |
| `bat` | Syntax highlighting with theme support |
| `lazygit` | Terminal UI for git |
| `btop` | Interactive process viewer with theme support |
| `ripgrep` | Smart-case, search hidden files, exclude .git |
| `direnv` | Silent env diff logging |
| `k9s` | Kubernetes TUI with theme and ArgoCD plugins |
| `aws` | Default region (eu-central-1), JSON output |
| `fastfetch` | System info with Apple logo, Nerd Font icons |

### Shell Setup

Both **zsh** and **fish** are configured with feature parity:

| Feature | Zsh | Fish |
|---|---|---|
| Plugin manager | Antidote | Fisher (auto-bootstraps) |
| Autosuggestions | zsh-autosuggestions plugin | Built-in |
| Syntax highlighting | zsh-syntax-highlighting plugin | Built-in |
| Fuzzy finder | fzf + fzf-tab | fzf.fish |
| Completions | OMZ plugins (git, kubectl, aws, gh, gradle) | fish-kubectl-completions, plugin-aws |
| Prompt | Starship | Starship |
| Smart cd | zoxide (`cd`) | zoxide (`cd`) |
| Env management | direnv, mise | direnv, mise |

**Aliases** (identical in both shells): `k`=kubectl, `g`=git, `cat`=bat, `ls`=eza, `npm`=pnpm, `dc`=docker compose, `tf`=tofu, `be`=./gradlew

## macOS Defaults

`macos/defaults.sh` configures:

- **Finder:** show hidden files, path bar, status bar
- **Dock:** autohide, no delay, scale minimize effect
- **Keyboard:** disable auto-correct, smart quotes, smart dashes; enable key repeat (rate 2, delay 15)
- **Clock:** 24-hour format
- **Screenshots:** save to `~/Screenshots` as PNG
- **Battery:** show percentage
- **Firewall:** enable macOS application firewall
- **Screensaver:** require password within 5 seconds, activate after 5 minutes idle
- **SSH:** ensure `~/.ssh` has secure permissions (700/600)

## Secrets Management

Secrets (git identity, GPG key, AWS credentials) are stored in [Bitwarden](https://bitwarden.com/) and pulled during `just init` — nothing sensitive is committed to the repo. Generated files (`~/.gitconfig.local`, `~/.aws/credentials`) live outside the repo, and `repos.yaml` is in `.gitignore`.

### Required Bitwarden Items

**1. `dotfiles` item** (Login type) with custom fields:

| Field | Value | Required |
|---|---|---|
| `GIT_USER_NAME` | Your Name | Yes |
| `GIT_USER_EMAIL` | `you@example.com` | Yes |
| `GIT_SIGNING_KEY` | Your GPG key ID | Yes |
| `AWS_PROFILE_TST` | TST profile name (e.g. `tst`) | Yes |
| `AWS_ACCESS_KEY_ID_TST` | TST access key | Yes |
| `AWS_SECRET_ACCESS_KEY_TST` | TST secret key | Yes |
| `AWS_PROFILE_PRD` | PRD profile name (e.g. `prd`) | No |
| `AWS_ACCESS_KEY_ID_PRD` | PRD access key | No |
| `AWS_SECRET_ACCESS_KEY_PRD` | PRD secret key | No |

PRD fields are optional — if missing, the PRD profile and kubeconfig are skipped.

**2. `dotfiles/gpg` item** *(optional)* — Secure note with your armored GPG private key:

```sh
gpg --export-secret-keys --armor YOUR_KEY_ID
```

**3. `dotfiles/repos` item** *(optional)* — Secure note with `repos.yaml` content. See `repos.yaml.example`.

### Creating Bitwarden items via CLI

> Requires jq 1.6+ (Homebrew installs the latest).

```sh
cd ~/.homebrew
bw login
export BW_SESSION=$(bw unlock --raw)

# 1. dotfiles item with custom fields
bw get template item | jq '
  .name = "dotfiles" |
  .type = 1 |
  .login = {} |
  .fields = [
    {name: "GIT_USER_NAME", value: "Your Name", type: 0},
    {name: "GIT_USER_EMAIL", value: "you@example.com", type: 0},
    {name: "GIT_SIGNING_KEY", value: "YOUR_GPG_KEY_ID", type: 0},
    {name: "AWS_PROFILE_TST", value: "tst", type: 0},
    {name: "AWS_ACCESS_KEY_ID_TST", value: "AKIA...", type: 1},
    {name: "AWS_SECRET_ACCESS_KEY_TST", value: "wJal...", type: 1},
    {name: "AWS_PROFILE_PRD", value: "prd", type: 0},
    {name: "AWS_ACCESS_KEY_ID_PRD", value: "AKIA...", type: 1},
    {name: "AWS_SECRET_ACCESS_KEY_PRD", value: "wJal...", type: 1}
  ]' | bw encode | bw create item

# 2. GPG private key (optional)
bw get template item | jq '
  .name = "dotfiles/gpg" |
  .type = 2 |
  .secureNote = {type: 0} |
  .notes = "PASTE_ARMORED_GPG_KEY_HERE"
' | bw encode | bw create item

# 3. repos.yaml (optional)
bw get template item | jq --rawfile notes repos.yaml.example '
  .name = "dotfiles/repos" |
  .type = 2 |
  .secureNote = {type: 0} |
  .notes = $notes
' | bw encode | bw create item
```

> Field type `0` = text (visible), type `1` = hidden (masked in the Bitwarden UI).

### What init does

| Step | Output | Idempotent |
|---|---|---|
| Git identity | `~/.gitconfig.local` from template | Skips if exists |
| GPG key | Imports into keyring | Skips if already imported |
| AWS credentials | `~/.aws/credentials` with TST (+ PRD if available) | Skips if exists |
| Kubeconfig | Adds `tst` and `prd` EKS contexts | Safe to re-run |
| Repos | `repos.yaml` from Bitwarden note | Skips if exists |

## Doctor Checks

`just doctor` verifies:

- Homebrew, Bitwarden CLI, GPG, Stow, mise installed
- `~/.gitconfig.local` exists with valid GPG signing key
- All stow packages linked without conflicts
- FileVault disk encryption enabled
- macOS firewall enabled
- macOS software updates current

## Constraints

- Homebrew at `/opt/homebrew` (Apple Silicon)
- POSIX sh for scripts, shell-specific syntax only in `.zshrc` / `config.fish`
- Firewall and FileVault checks require sudo
