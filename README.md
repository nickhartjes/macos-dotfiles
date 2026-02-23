# macOS Dotfiles

GNU Stow-managed dotfiles and Homebrew setup for macOS (Apple Silicon).

## How It Works

This setup is **declarative** — the `Brewfile` is the single source of truth for all installed packages. Instead of manually running `brew install` and `brew uninstall`, you edit the Brewfile and run `just update`.

- **Add a package:** add it to the Brewfile, run `just update` — it gets installed.
- **Remove a package:** delete it from the Brewfile, run `just update` — it gets uninstalled.

This works because `just update` runs `brew bundle cleanup --force`, which removes any formula or cask that is installed on the system but not listed in the Brewfile. This keeps your Mac in sync with the Brewfile at all times, similar to how NixOS or Ansible manage packages declaratively.

To preview what would be removed without actually uninstalling:

```sh
brew bundle cleanup --file=Brewfile
```

## Quick Start

### New machine (full setup)

```mermaid
flowchart TD
    A["git clone repo ~/.dotfiles && cd ~/.dotfiles"] --> B[just install]
    B --> C[Install Homebrew]
    C --> D[brew bundle]
    D --> E{BW_SESSION set?}
    E -- yes --> F[just init]
    E -- no --> G[warn, continue]
    G -.-> |run later| F
    D --> H[Stow dotfiles]
    D --> I[mise SDKs]
    D --> J[macOS defaults]
    D --> K[fzf key bindings]

    F --> L[~/.gitconfig.local]
    F --> M[GPG key import]
    F --> N[~/.aws/credentials]
    F --> O{PRD access?}
    O -- yes --> P[kubeconfig: tst + prd]
    O -- no --> Q[kubeconfig: tst only]

    P --> R[just doctor]
    Q --> R
    H --> R
    I --> R
    J --> R
    K --> R
```

### Step by step

```sh
# 1. Clone and enter the repo
git clone <repo> ~/.dotfiles && cd ~/.dotfiles

# 2. Run bootstrap (installs everything, links dotfiles)
just install

# 3. Log in to Bitwarden and set up secrets
bw login
export BW_SESSION=$(bw unlock --raw)
just init

# 4. Verify everything is healthy
just doctor
```

If `BW_SESSION` is not set during `just install`, secrets are skipped — run `just init` afterwards. Each init step is idempotent and skips what's already configured.

## Secrets Management

Secrets (git identity, GPG key, AWS credentials) are stored in [Bitwarden](https://bitwarden.com/) and pulled during init — nothing sensitive is committed to the repo.

### Setup

1. Install dependencies (handled by `just install`):
   ```sh
   brew install bitwarden-cli gnupg jq
   ```

2. Create a Bitwarden item named **`dotfiles`** with these custom fields:

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

   PRD fields are optional — not everyone has production access. If missing, the PRD profile and kubeconfig are skipped.

3. *(Optional)* Create a Bitwarden secure note named **`dotfiles/gpg`** with your armored GPG private key as the note content:
   ```sh
   gpg --export-secret-keys --armor YOUR_KEY_ID
   ```
   Copy the full output (including `-----BEGIN PGP PRIVATE KEY BLOCK-----`) into the note.

4. *(Optional)* Create a Bitwarden secure note named **`dotfiles/repos`** with your `repos.yaml` content (list of git repos to clone). See `repos.yaml.example` for the format.

5. Log in and run init:
   ```sh
   bw login
   export BW_SESSION=$(bw unlock --raw)
   just init
   ```

### Creating Bitwarden items via CLI

Instead of using the web vault, you can create all items from the terminal:

```sh
cd ~/homebrew  # run from the repo root
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

> Field type `0` = text (visible), type `1` = hidden (masked in the Bitwarden UI). AWS keys use hidden.

### What init does

| Step | Output | Idempotent |
|---|---|---|
| Git identity | `~/.gitconfig.local` from template | Skips if exists |
| GPG key | Imports into keyring | Skips if already imported |
| AWS credentials | `~/.aws/credentials` with TST (+ PRD if available) | Skips if exists |
| Kubeconfig | Adds `tst` and `prd` EKS contexts | Safe to re-run |
| Repos | `repos.yaml` from Bitwarden note | Skips if exists |

## What's Included

### Brewfile

| Category | Packages |
|---|---|
| Core CLI | bitwarden-cli, git, gnupg, shellcheck, gh, curl, wget, jq, yq, ripgrep, fd, bat, eza, fzf, zoxide, tree, stow, starship, direnv, just, neovim, httpie, tldr |
| Shell & Plugins | antidote, fastfetch, btop, procs |
| Dev Tools | mise, pnpm, gradle |
| Containers & Cloud | kubectl, kubectx, helm, k9s, awscli, argocd, colima, docker (CLI, required by colima), docker-compose, kustomize, opentofu |
| Database | pgcli |
| IDEs & Editors | intellij-idea, visual-studio-code, zed |
| Terminal | ghostty |
| Browsers | firefox, google-chrome |
| Communication | signal, slack, telegram |
| Productivity | raycast, rectangle, bitwarden |
| Knowledge & Notes | anytype |
| DevOps | openlens |
| AI | claude (desktop), claude-code (CLI), codex (OpenAI CLI), lmstudio |
| Media | spotify |
| Fonts | JetBrains Mono Nerd Font |

### Stow Packages

Each package under `dotfiles/` mirrors `$HOME` and is symlinked via GNU Stow:

| Package | Files | Description |
|---|---|---|
| `zsh` | `.zshrc`, `.zsh_plugins.txt`, `.zsh/*.zsh` | Shell config with Antidote plugins, modular aliases/functions/completions |
| `git` | `.gitconfig`, `.gitconfig.local.tpl`, `.gitignore_global` | Git config with GPG signing, aliases, global gitignore, local identity template |
| `starship` | `.config/starship.toml` | Prompt showing git, languages, k8s, aws, terraform |
| `mise` | `.config/mise/config.toml` | SDK versions: JDK 21, Node LTS, Python 3.12 |
| `ghostty` | `.config/ghostty/config` | Terminal: JetBrains Mono NF, Catppuccin Mocha |
| `bat` | `.config/bat/config` | line numbers |
| `k9s` | `.config/k9s/config.yaml`, `skins/catppuccin.yaml` | Catppuccin theme, ArgoCD and cert-manager plugins |
| `aws` | `.aws/config` | Default region (eu-central-1), credentials managed by init |

### Shell Setup

- **Plugin manager:** Antidote with zsh-autosuggestions, zsh-completions, fzf-tab, syntax-highlighting, and OMZ plugins (git, kubectl, aws, gradle, etc.)
- **Prompt:** Starship
- **Fuzzy finder:** fzf with Dracula theme and bat preview
- **Smart cd:** zoxide (aliased to `cd`)
- **Aliases:** `k`=kubectl, `g`=git, `cat`=bat, `ls`=eza, `npm`=pnpm, `dc`=docker compose, `tf`=terraform, `be`=./gradlew

## Commands

```sh
just init       # Pull secrets from Bitwarden (run once, needs BW_SESSION)
just install    # Full bootstrap (Homebrew, brew bundle, stow, mise, defaults, fzf)
just update     # Update packages, remove unlisted, cleanup
just repo-sync  # Clone or fetch all repositories from repos.yaml
just stow       # Re-link all dotfiles
just unstow     # Unlink all dotfiles
just defaults   # Re-apply macOS preferences
just dump       # Export current brew state to Brewfile
just clean      # Remove unused deps and cache
just check      # Run shellcheck on all shell scripts
just doctor     # Verify environment is healthy
```

## Bootstrap Steps

`bootstrap.sh` is idempotent (safe to re-run):

1. Install Homebrew if missing
2. `brew bundle` from Brewfile
3. Init secrets from Bitwarden (skips if `~/.gitconfig.local` exists or `BW_SESSION` not set)
4. Stow all dotfile packages
5. `mise install` (JDK 21, Node LTS, Python 3.12)
6. Apply macOS defaults (Finder, Dock, keyboard, screenshots)
7. Set up fzf key bindings
8. Print summary

## macOS Defaults

`defaults.sh` configures:

- **Finder:** show hidden files, path bar, status bar
- **Dock:** autohide, no delay, hide permanently
- **Clock:** 24-hour format
- **Keyboard:** disable auto-correct, smart quotes, smart dashes; enable key repeat (rate 2, delay 15)
- **Screenshots:** save to `~/Screenshots` as PNG
- **Battery:** show percentage

Browse all available defaults at [macos-defaults.com](https://macos-defaults.com/).

## Directory Structure

```
homebrew/
├── Brewfile
├── bootstrap.sh
├── init.sh
├── defaults.sh
├── repo-sync.sh
├── repos.yaml.example
├── justfile
└── dotfiles/
    ├── aws/.aws/config
    ├── aws/.aws/credentials.tpl
    ├── bat/.config/bat/config
    ├── ghostty/.config/ghostty/config
    ├── git/.gitconfig
    ├── git/.gitconfig.local.tpl
    ├── git/.gitignore_global
    ├── k9s/.config/k9s/config.yaml
    ├── k9s/.config/k9s/skins/catppuccin.yaml
    ├── mise/.config/mise/config.toml
    ├── starship/.config/starship.toml
    └── zsh/
        ├── .zshrc
        ├── .zsh_plugins.txt
        └── .zsh/
            ├── aliases.zsh
            ├── completions.zsh
            ├── functions.zsh
            └── kubernetes.zsh
```

## Adding a New Stow Package

1. Create `dotfiles/<name>/` mirroring the home directory structure
2. Add the package name to `stow_packages` in `justfile` and `STOW_PACKAGES` in `bootstrap.sh`
3. Run `just stow`

## Constraints

- No sudo/root required (BeyondTrust managed Mac)
- No Nix or system-level daemon changes
- Homebrew at `/opt/homebrew` (Apple Silicon)
- POSIX sh for scripts, zsh-specific only in `.zshrc`
