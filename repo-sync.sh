#!/bin/sh
# Clone or fetch all repositories defined in repos.yaml
# Requires: yq
# Run: just repo-sync
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_FILE="$DOTFILES_DIR/repos.yaml"
BASE_FOLDER="$HOME/projects"
LOG_FILE="$HOME/.local/state/repo-sync.log"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
fail()  { printf "${RED}[err]${NC}   %s\n" "$1"; }

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

if ! command -v yq >/dev/null 2>&1; then
  fail "yq not found — run 'just install' first"
  exit 1
fi

if [ ! -f "$REPOS_FILE" ]; then
  fail "repos.yaml not found — copy the example and edit it:"
  echo ""
  echo "  cp $DOTFILES_DIR/repos.yaml.example $REPOS_FILE"
  echo ""
  exit 1
fi

success_count=0
error_count=0

# Iterate over each folder (top-level key in yaml)
for folder in $(yq 'keys | .[]' "$REPOS_FILE"); do
  full_path="$BASE_FOLDER/$folder"
  mkdir -p "$full_path"
  info "Processing $folder/"

  # Iterate over repos in this folder
  repo_count=$(yq ".$folder | length" "$REPOS_FILE")
  i=0
  while [ "$i" -lt "$repo_count" ]; do
    repo_url=$(yq ".${folder}[${i}]" "$REPOS_FILE")
    repo_name=$(echo "$repo_url" | awk -F'/' '{print $NF}' | sed 's/.git$//')

    if [ -d "$full_path/$repo_name" ]; then
      if git -C "$full_path/$repo_name" fetch 2>>"$LOG_FILE"; then
        ok "Fetched $folder/$repo_name"
        log "Fetched $folder/$repo_name"
        success_count=$((success_count + 1))
      else
        fail "Failed to fetch $folder/$repo_name"
        log "ERROR: Failed to fetch $folder/$repo_name"
        error_count=$((error_count + 1))
      fi
    else
      if git clone "$repo_url" "$full_path/$repo_name" 2>>"$LOG_FILE"; then
        ok "Cloned $folder/$repo_name"
        log "Cloned $folder/$repo_name"
        success_count=$((success_count + 1))
      else
        fail "Failed to clone $folder/$repo_name"
        log "ERROR: Failed to clone $folder/$repo_name"
        error_count=$((error_count + 1))
      fi
    fi

    i=$((i + 1))
  done
done

printf "\n"
if [ "$error_count" -eq 0 ]; then
  ok "All repositories synced ($success_count repos)"
else
  fail "$error_count errors, $success_count successful — check $LOG_FILE"
fi
