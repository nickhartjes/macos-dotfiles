# 3-Part Restructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure the repo into 3 directories (apps/, dotfiles/, macos/) with a minimal bootstrap and justfile orchestrator.

**Architecture:** Move files into their new directories using `git mv`, then rewrite bootstrap.sh (minimal Homebrew installer), justfile (updated paths + new recipes), and fix all internal path references. CI workflow needs path updates too.

**Tech Stack:** Shell scripts, just, brew, stow, git

---

### Task 1: Create directory structure and move apps/

**Files:**
- Create: `apps/` directory
- Move: `Brewfile` → `apps/Brewfile`

**Step 1: Create apps directory and move Brewfile**

```bash
mkdir -p apps
git mv Brewfile apps/Brewfile
```

**Step 2: Verify**

```bash
ls apps/Brewfile
```
Expected: file exists

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: move Brewfile to apps/"
```

---

### Task 2: Create macos/ and move defaults

**Files:**
- Create: `macos/` directory
- Move: `defaults.sh` → `macos/defaults.sh`

**Step 1: Create macos directory and move defaults**

```bash
mkdir -p macos
git mv defaults.sh macos/defaults.sh
```

**Step 2: Verify**

```bash
ls macos/defaults.sh
```
Expected: file exists

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: move defaults.sh to macos/"
```

---

### Task 3: Restructure dotfiles/ — move stow packages to dotfiles/stow/

**Files:**
- Create: `dotfiles/stow/` directory
- Move: all 16 stow packages from `dotfiles/*` → `dotfiles/stow/*`

The current stow packages are: `aws bat btop direnv fastfetch fish ghostty git k9s lazygit mise nvim ripgrep starship zsh`

**Step 1: Create stow subdirectory and move all packages**

```bash
mkdir -p dotfiles/stow
# Move all stow package directories (not files) into stow/
cd dotfiles
for dir in aws bat btop direnv fastfetch fish ghostty git k9s lazygit mise nvim ripgrep starship zsh; do
  git mv "$dir" stow/
done
cd ..
```

**Step 2: Verify**

```bash
ls dotfiles/stow/
```
Expected: all 16 package directories listed

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: move stow packages to dotfiles/stow/"
```

---

### Task 4: Move themes, scripts, templates into dotfiles/

**Files:**
- Move: `themes/` → `dotfiles/themes/`
- Move: `scripts/` → `dotfiles/scripts/`
- Move: `templates/` → `dotfiles/templates/`

**Step 1: Move directories**

```bash
git mv themes dotfiles/themes
git mv scripts dotfiles/scripts
git mv templates dotfiles/templates
```

**Step 2: Verify**

```bash
ls dotfiles/themes/ dotfiles/scripts/ dotfiles/templates/
```
Expected: all contents preserved

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: move themes, scripts, templates into dotfiles/"
```

---

### Task 5: Move init.sh, repo-sync.sh, repos.yaml into dotfiles/

**Files:**
- Move: `init.sh` → `dotfiles/init.sh`
- Move: `repo-sync.sh` → `dotfiles/repo-sync.sh`
- Move: `repos.yaml` → `dotfiles/repos.yaml`
- Move: `repos.yaml.example` → `dotfiles/repos.yaml.example`

**Step 1: Move files**

```bash
git mv init.sh dotfiles/init.sh
git mv repo-sync.sh dotfiles/repo-sync.sh
git mv repos.yaml dotfiles/repos.yaml
git mv repos.yaml.example dotfiles/repos.yaml.example
```

**Step 2: Verify**

```bash
ls dotfiles/init.sh dotfiles/repo-sync.sh dotfiles/repos.yaml dotfiles/repos.yaml.example
```
Expected: all files exist

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: move init, repo-sync, repos.yaml into dotfiles/"
```

---

### Task 6: Fix path references in dotfiles/init.sh

**Files:**
- Modify: `dotfiles/init.sh`

The script uses `DOTFILES_DIR` to reference templates and repos.yaml. After the move, `DOTFILES_DIR` points to `dotfiles/` which is correct since templates/ and repos.yaml are now there. But the template path references `dotfiles/git/.gitconfig.local.tpl` which is now at `stow/git/.gitconfig.local.tpl`.

**Step 1: Update template path in init.sh**

In `dotfiles/init.sh`, change line 67:
```
"$DOTFILES_DIR/dotfiles/git/.gitconfig.local.tpl"
```
to:
```
"$DOTFILES_DIR/stow/git/.gitconfig.local.tpl"
```

**Step 2: Verify no other broken paths**

Search for any remaining references to old paths in the file. The `DOTFILES_DIR` variable resolves to the `dotfiles/` directory, so `repos.yaml` reference on line 173 (`$DOTFILES_DIR/repos.yaml`) is correct.

**Step 3: Commit**

```bash
git add dotfiles/init.sh
git commit -m "fix: update template path in init.sh after restructure"
```

---

### Task 7: Fix path references in dotfiles/scripts/theme.sh

**Files:**
- Modify: `dotfiles/scripts/theme.sh`

The script currently derives paths as:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
THEMES_DIR="$REPO_DIR/themes"
DOTFILES_DIR="$REPO_DIR/dotfiles"
```

After the move, `SCRIPT_DIR` = `dotfiles/scripts`, `REPO_DIR` = `dotfiles/`. Themes are now at `dotfiles/themes/` and stow packages at `dotfiles/stow/`.

**Step 1: Update path derivation in theme.sh**

Change lines 6-7 from:
```bash
THEMES_DIR="$REPO_DIR/themes"
DOTFILES_DIR="$REPO_DIR/dotfiles"
```
to:
```bash
THEMES_DIR="$REPO_DIR/themes"
STOW_DIR="$REPO_DIR/stow"
```

Then update all references from `$DOTFILES_DIR` to `$STOW_DIR` in the rest of the file (these reference stow package config files).

**Step 2: Verify by reading the full file and confirming all path references are correct**

**Step 3: Commit**

```bash
git add dotfiles/scripts/theme.sh
git commit -m "fix: update path references in theme.sh after restructure"
```

---

### Task 8: Fix path references in dotfiles/repo-sync.sh

**Files:**
- Modify: `dotfiles/repo-sync.sh`

The script uses `DOTFILES_DIR` to find `repos.yaml`. After the move, the script is in `dotfiles/` and `repos.yaml` is also in `dotfiles/`, so `$DOTFILES_DIR/repos.yaml` is correct. But verify the example path reference on line 35 still makes sense.

**Step 1: Review and update if needed**

Check that the `cp` example path on line 35 is updated:
```
cp $DOTFILES_DIR/repos.yaml.example $REPOS_FILE
```
This is correct since both files are in the same directory now.

**Step 2: Commit (only if changes were made)**

---

### Task 9: Rewrite bootstrap.sh (minimal)

**Files:**
- Modify: `bootstrap.sh`

**Step 1: Rewrite bootstrap.sh**

Replace the entire file with:

```bash
#!/bin/sh
# Bootstrap macOS development environment
# Installs Homebrew and all packages (including just)
# After this, use 'just' for everything: just install
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$1"; }

# ─── 1. Homebrew ─────────────────────────────────────────
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed"
fi

# ─── 2. Install packages (includes just) ─────────────────
info "Running brew bundle..."
brew bundle --file="$REPO_DIR/apps/Brewfile"
ok "Brew bundle complete"

# ─── Done ─────────────────────────────────────────────────
printf "\n"
printf "%s════════════════════════════════════════%s\n" "$GREEN" "$NC"
printf "%s  Bootstrap complete!%s\n" "$GREEN" "$NC"
printf "%s════════════════════════════════════════%s\n" "$GREEN" "$NC"
printf "\n"
printf "  Next steps:\n"
printf "    %sjust install%s    Complete setup (dotfiles + macOS defaults)\n" "$YELLOW" "$NC"
printf "    %sjust init%s       Set up secrets from Bitwarden\n" "$YELLOW" "$NC"
printf "    %sjust doctor%s     Verify environment health\n" "$YELLOW" "$NC"
printf "\n"
```

**Step 2: Verify it's executable**

```bash
chmod +x bootstrap.sh
```

**Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "refactor: rewrite bootstrap.sh as minimal Homebrew installer"
```

---

### Task 10: Rewrite justfile with updated paths

**Files:**
- Modify: `justfile`

**Step 1: Rewrite justfile**

```just
# macOS dotfiles task runner

set dotenv-load := false

repo_dir := justfile_directory()
apps_dir := repo_dir / "apps"
dotfiles_dir := repo_dir / "dotfiles"
macos_dir := repo_dir / "macos"
stow_dir := dotfiles_dir / "stow"
stow_packages := "zsh fish git starship mise ghostty bat k9s aws fastfetch nvim lazygit ripgrep direnv btop"

# Run full setup (apps + dotfiles + macOS defaults)
install: apps dotfiles macos

# Install all Homebrew packages
apps:
    brew bundle --file={{apps_dir}}/Brewfile

# Set up dotfiles (init + stow + mise + fzf)
dotfiles: init stow
    #!/bin/sh
    echo "Installing mise SDK versions..."
    if command -v mise >/dev/null 2>&1; then
        mise install
        echo "mise SDKs installed"
    else
        echo "mise not found, skipping SDK install"
    fi
    echo "Setting up fzf key bindings..."
    FZF_INSTALL="$(brew --prefix)/opt/fzf/install"
    if [ -x "$FZF_INSTALL" ]; then
        "$FZF_INSTALL" --key-bindings --completion --no-update-rc --no-bash --no-fish
        echo "fzf key bindings installed"
    else
        echo "fzf install script not found"
    fi

# Apply macOS system preferences
macos:
    sh {{macos_dir}}/defaults.sh

# Set up local secrets from Bitwarden
init:
    sh {{dotfiles_dir}}/init.sh

# Link all dotfiles via stow
stow:
    #!/bin/sh
    for pkg in {{stow_packages}}; do \
        stow -d {{stow_dir}} -t "$HOME" --restow "$pkg" && \
        echo "Stowed $pkg"; \
    done

# Unlink all dotfiles via stow
unstow:
    #!/bin/sh
    for pkg in {{stow_packages}}; do \
        stow -d {{stow_dir}} -t "$HOME" -D "$pkg" && \
        echo "Unstowed $pkg"; \
    done

# Update Homebrew and all packages (removes unlisted packages)
update:
    brew update
    brew bundle --file={{apps_dir}}/Brewfile
    brew bundle cleanup --force --file={{apps_dir}}/Brewfile
    brew cleanup

# Re-apply macOS defaults
defaults:
    sh {{macos_dir}}/defaults.sh

# Dump current Homebrew state to Brewfile
dump:
    brew bundle dump --force --file={{apps_dir}}/Brewfile

# Cleanup Homebrew (remove unused deps and cache)
clean:
    brew cleanup
    brew autoremove

# Clone or fetch all repositories defined in repos.yaml
repo-sync:
    sh {{dotfiles_dir}}/repo-sync.sh

# Run all linters via MegaLinter
lint:
    docker run --rm -v {{repo_dir}}:/tmp/lint:rw oxsecurity/megalinter-cupcake:v8 mega-linter-runner

# Verify environment is healthy
doctor:
    #!/bin/sh
    ok()   { printf "  \033[0;32m✓\033[0m %s\n" "$1"; }
    fail() { printf "  \033[0;31m✗\033[0m %s\n" "$1"; }
    echo "Checking environment..."
    command -v brew >/dev/null 2>&1 && ok "Homebrew installed" || fail "Homebrew not installed"
    command -v bw >/dev/null 2>&1 && ok "Bitwarden CLI installed" || fail "Bitwarden CLI not installed"
    command -v gpg >/dev/null 2>&1 && ok "GPG installed" || fail "GPG not installed"
    command -v stow >/dev/null 2>&1 && ok "Stow installed" || fail "Stow not installed"
    command -v mise >/dev/null 2>&1 && ok "mise installed" || fail "mise not installed"
    [ -f "$HOME/.gitconfig.local" ] && ok "~/.gitconfig.local exists" || fail "~/.gitconfig.local missing — run 'just init'"
    if [ -f "$HOME/.gitconfig.local" ]; then \
        key=$(grep signingkey "$HOME/.gitconfig.local" | awk '{print $3}'); \
        if [ -n "$key" ] && gpg --list-secret-keys "$key" >/dev/null 2>&1; then \
            ok "GPG signing key present"; \
        else \
            fail "GPG signing key not found — run 'just init'"; \
        fi; \
    fi
    all_linked=true; \
    for pkg in {{stow_packages}}; do \
        if ! stow -d {{stow_dir}} -t "$HOME" --no-folding -n --restow "$pkg" >/dev/null 2>&1; then \
            fail "Stow package '$pkg' has conflicts"; \
            all_linked=false; \
        fi; \
    done; \
    [ "$all_linked" = true ] && ok "All stow packages linked"

# Switch terminal theme across all tools
theme name="":
    #!/bin/sh
    if [ -z "{{name}}" ]; then \
        active=""; \
        if [ -f "{{dotfiles_dir}}/themes/_active" ]; then \
            active=$(cat "{{dotfiles_dir}}/themes/_active"); \
        fi; \
        themes_dir="{{dotfiles_dir}}/themes"; \
        selected=$( \
            for dir in "$themes_dir"/*/; do \
                slug=$(basename "$dir"); \
                [ -f "$dir/theme.yaml" ] || continue; \
                name=$(yq '.name' "$dir/theme.yaml"); \
                variant=$(yq '.variant // "dark"' "$dir/theme.yaml"); \
                printf "%s\t[%s]  %s\n" "$slug" "$variant" "$name"; \
            done \
            | sort -t'	' -k2,2 -k3,3 \
            | fzf --prompt="Theme: " \
                  --header="Current: $active" \
                  --with-nth=2.. \
                  --delimiter='\t' \
                  --preview="yq '.name' $themes_dir/{1}/theme.yaml" \
                  --preview-window=up:1 \
            | cut -f1); \
        if [ -n "$selected" ]; then \
            sh "{{dotfiles_dir}}/scripts/theme.sh" "$selected"; \
        fi; \
    else \
        sh "{{dotfiles_dir}}/scripts/theme.sh" "{{name}}"; \
    fi
```

**Step 2: Verify syntax**

```bash
just --list
```
Expected: all recipes listed without errors

**Step 3: Commit**

```bash
git add justfile
git commit -m "refactor: rewrite justfile with 3-part directory structure"
```

---

### Task 11: Update CI workflow paths

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Update stow validation path and Brewfile path**

Change the validate-stow job's `run` block — update path from `dotfiles/*/` to `dotfiles/stow/*/`:
```yaml
        run: |
          errors=0
          for pkg in dotfiles/stow/*/; do
```

Change the validate-brewfile job's `run` block — update path from `Brewfile` to `apps/Brewfile`:
```yaml
          done < apps/Brewfile
```

**Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "fix: update CI workflow paths after restructure"
```

---

### Task 12: Update .gitignore

**Files:**
- Modify: `.gitignore`

**Step 1: Update repos.yaml path**

Change:
```
repos.yaml
```
to:
```
dotfiles/repos.yaml
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "fix: update .gitignore path for repos.yaml"
```

---

### Task 13: Final verification

**Step 1: Verify directory structure looks correct**

```bash
tree -L 2 -I '.git|megalinter-reports|.claude'
```

Expected structure matches the design doc.

**Step 2: Verify no broken path references remain**

```bash
# Search for old paths that should have been updated
grep -r "dotfiles/git/" --include="*.sh" .
grep -r '"$DOTFILES_DIR/dotfiles/' --include="*.sh" .
grep -rn 'Brewfile' --include="*.sh" --include="*.yml" --include="justfile" .
```

Expected: only references to `apps/Brewfile`, no references to root-level `Brewfile`.

**Step 3: Run just --list to verify justfile parses**

```bash
just --list
```

**Step 4: Commit any remaining fixes if needed**
