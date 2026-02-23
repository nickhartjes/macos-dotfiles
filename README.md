# macOS Dotfiles

GNU Stow-managed dotfiles and Homebrew setup for macOS (Apple Silicon). Tokyo Night themed.

## Make It Your Own

This repo is meant to be forked and customized:

1. **Fork** this repo on GitHub
2. Edit the `Brewfile` to add/remove packages you want
3. Tweak configs under `dotfiles/` to your liking (shell aliases, editor settings, theme, etc.)
4. Update the Bitwarden items with your own secrets (git identity, GPG key, AWS credentials)
5. Follow the Quick Start below to bootstrap your Mac

## Quick Start

```sh
# 1. Fork this repo, then clone your fork
# Use HTTPS on a fresh Mac (no SSH keys yet), switch to SSH later
git clone https://github.com/<your-user>/macos-dotfiles.git ~/.macos-dotfiles && cd ~/.macos-dotfiles

# 2. Bootstrap (installs Homebrew, packages, links dotfiles, SDKs, macOS defaults)
sh bootstrap.sh

# 3. Set up secrets from Bitwarden
bw login
export BW_SESSION=$(bw unlock --raw)
just init

# 4. Verify
just doctor
```

Step 2 uses `sh bootstrap.sh` directly because `just` isn't available yet on a fresh machine. After bootstrap completes, `just` is installed and all subsequent commands use it (`just install` runs the same bootstrap script).

If `BW_SESSION` is not set during bootstrap, secrets are skipped — run `just init` afterwards.

## How It Works

The `Brewfile` is the single source of truth for all installed packages:

- **Add a package:** add to Brewfile, run `just update`
- **Remove a package:** delete from Brewfile, run `just update`

`just update` runs `brew update`, then `brew bundle` to install new additions, then `brew bundle cleanup --force` to remove anything not in the Brewfile.

Dotfiles are managed with [GNU Stow](https://www.gnu.org/software/stow/) — each directory under `dotfiles/` mirrors `$HOME` and is symlinked into place. Adding a new stow package is automatic: create `dotfiles/<name>/` with the right structure and `bootstrap.sh` picks it up.

Sensitive files are never committed — `.gitignore` excludes `repos.yaml` (contains repo URLs), and all secrets (`~/.gitconfig.local`, `~/.aws/credentials`) are generated at runtime by `just init` into locations outside the repo.

## Commands

```sh
just install      # Full bootstrap (same as sh bootstrap.sh)
just init         # Pull secrets from Bitwarden (needs BW_SESSION)
just update       # Install new packages, remove unlisted, cleanup
just stow         # Re-link all dotfiles
just unstow       # Unlink all dotfiles
just defaults     # Re-apply macOS preferences
just repo-sync    # Clone/fetch repos from repos.yaml
just dump         # Export current brew state to Brewfile
just clean        # Remove unused deps and cache
just check        # Shellcheck all scripts
just doctor       # Verify environment health
```

## What's Included

### Packages (Brewfile)

| Category | Packages |
|---|---|
| Core CLI | bitwarden-cli, git, gnupg, shellcheck, gh, curl, wget, jq, yq, ripgrep, fd, bat, eza, fzf, zoxide, tree, stow, starship, direnv, just, neovim, httpie, tldr |
| Shell | fish, antidote (zsh), fastfetch, btop, procs |
| Dev Tools | lazygit, mise, pnpm, gradle |
| Containers & Cloud | kubectl, kubectx, helm, k9s, awscli, argocd, colima, docker, docker-compose, kustomize, opentofu |
| Database | pgcli |
| IDEs & Editors | intellij-idea, visual-studio-code, zed |
| Terminal | ghostty |
| Browsers | firefox, google-chrome |
| Communication | signal, slack, telegram |
| Productivity | raycast, rectangle, bitwarden |
| Knowledge & Notes | anytype |
| DevOps | openlens |
| AI | claude, claude-code, codex, lmstudio |
| Media | spotify |
| Fonts | JetBrains Mono Nerd Font |

### Stow Packages

| Package | What it configures |
|---|---|
| `zsh` | Shell config with Antidote plugins, modular aliases/functions/completions |
| `fish` | Fish shell with Fisher, fzf.fish, kubectl/aws completions |
| `git` | Git config with GPG signing, aliases, global gitignore |
| `starship` | Prompt with git, languages, k8s, aws, opentofu modules |
| `mise` | SDK versions: JDK 21/17, Node LTS, Python 3.12 |
| `ghostty` | Terminal: JetBrains Mono NF, Tokyo Night |
| `nvim` | LazyVim with extras for Java, Python, TypeScript, YAML, Docker, Terraform |
| `bat` | Tokyo Night theme, line numbers, git changes |
| `lazygit` | Tokyo Night theme |
| `btop` | Tokyo Night theme |
| `ripgrep` | Smart-case, search hidden files, exclude .git |
| `direnv` | Silent env diff logging |
| `k9s` | Tokyo Night skin, ArgoCD plugins |
| `aws` | Default region (eu-central-1), JSON output |
| `fastfetch` | System info with Apple logo, Nerd Font icons |

### Shell Setup

Both **zsh** and **fish** are configured side-by-side with feature parity:

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

### Theme

Tokyo Night everywhere:

| Tool | How |
|---|---|
| Ghostty | `theme = Tokyo Night` (built-in) |
| Neovim | folke/tokyonight.nvim plugin (night style) |
| FZF | Tokyo Night color palette in `FZF_DEFAULT_OPTS` |
| Starship | `palette = "tokyonight"` |
| bat | `--theme="tokyonight_night"` |
| btop | Custom theme file |
| lazygit | Tokyo Night blue accent |
| k9s | Tokyo Night skin |

## Secrets Management

Secrets (git identity, GPG key, AWS credentials) are stored in [Bitwarden](https://bitwarden.com/) and pulled during `just init` — nothing sensitive is committed to the repo. Generated files (`~/.gitconfig.local`, `~/.aws/credentials`) live outside the repo, and `repos.yaml` is in `.gitignore`.

### Required Bitwarden Items

**1. `dotfiles` item** (Login type) with custom fields:

| Field | Value | Required |
|---|---|---|
| `GIT_USER_NAME` | Your Name | Yes |
| `GIT_USER_EMAIL` | you@example.com | Yes |
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
cd ~/.macos-dotfiles
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

## macOS Defaults

`defaults.sh` configures:

- **Finder:** show hidden files, path bar, status bar
- **Dock:** autohide, no delay, scale minimize effect
- **Keyboard:** disable auto-correct, smart quotes, smart dashes; enable key repeat (rate 2, delay 15)
- **Clock:** 24-hour format
- **Screenshots:** save to `~/Screenshots` as PNG
- **Battery:** show percentage

## Constraints

- No sudo/root required
- No Nix or system-level daemon changes
- Homebrew at `/opt/homebrew` (Apple Silicon)
- POSIX sh for scripts, shell-specific syntax only in `.zshrc` / `config.fish`
