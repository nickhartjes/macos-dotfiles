#!/bin/sh
# Populate local config files from Bitwarden
# Requires: bw (bitwarden-cli), jq, gpg
# Run: just init
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$1"; }

# Get a custom field value from the BW item (empty string if missing)
bw_field() { echo "$BW_ITEM" | jq -r --arg n "$1" '.fields[] | select(.name==$n) | .value // empty'; }

# ─── Check dependencies ────────────────────────────────────
for cmd in bw jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    warn "$cmd not found — run 'just install' first to install dependencies"
    exit 1
  fi
done

# ─── Bitwarden session ─────────────────────────────────────
if [ -z "$BW_SESSION" ]; then
  info "No BW_SESSION found. Log in and unlock Bitwarden:"
  echo ""
  echo "  bw login"
  echo "  export BW_SESSION=\$(bw unlock --raw)"
  echo "  just init"
  echo ""
  exit 1
fi

# ─── Fetch dotfiles item from Bitwarden ────────────────────
info "Fetching 'dotfiles' item from Bitwarden..."
BW_ITEM=$(bw get item "dotfiles" 2>/dev/null) || {
  warn "Bitwarden item 'dotfiles' not found. Create it with these custom fields:"
  echo ""
  echo "  GIT_USER_NAME     Your Name"
  echo "  GIT_USER_EMAIL    you@example.com"
  echo "  GIT_SIGNING_KEY   YOUR_GPG_KEY_ID"
  echo ""
  echo "  Optionally add a secure note named 'dotfiles/gpg' with your armored private key."
  echo ""
  exit 1
}

# ─── .gitconfig.local ──────────────────────────────────────
if [ -f "$HOME/.gitconfig.local" ]; then
  ok "$HOME/.gitconfig.local already exists, skipping"
else
  GIT_USER_NAME=$(bw_field "GIT_USER_NAME")
  GIT_USER_EMAIL=$(bw_field "GIT_USER_EMAIL")
  GIT_SIGNING_KEY=$(bw_field "GIT_SIGNING_KEY")

  sed \
    -e "s|\${GIT_USER_NAME}|$GIT_USER_NAME|" \
    -e "s|\${GIT_USER_EMAIL}|$GIT_USER_EMAIL|" \
    -e "s|\${GIT_SIGNING_KEY}|$GIT_SIGNING_KEY|" \
    "$DOTFILES_DIR/dotfiles/git/.gitconfig.local.tpl" > "$HOME/.gitconfig.local"

  ok "Created ~/.gitconfig.local"
fi

# ─── GPG private key ───────────────────────────────────────
GPG_KEY=$(bw get notes "dotfiles/gpg" 2>/dev/null) || true

if [ -n "$GPG_KEY" ]; then
  if command -v gpg >/dev/null 2>&1; then
    if echo "$GPG_KEY" | gpg --import 2>/dev/null; then
      ok "GPG key imported"
    else
      warn "GPG key import failed (may already exist)"
    fi
  else
    warn "gpg not found, skipping GPG key import"
  fi
else
  warn "No 'dotfiles/gpg' note found in Bitwarden, skipping GPG key import"
fi

# ─── AWS credentials ──────────────────────────────────────
if [ -f "$HOME/.aws/credentials" ]; then
  ok "$HOME/.aws/credentials already exists, skipping"
else
  AWS_PROFILE_TST=$(bw_field "AWS_PROFILE_TST")
  AWS_ACCESS_KEY_ID_TST=$(bw_field "AWS_ACCESS_KEY_ID_TST")
  AWS_SECRET_ACCESS_KEY_TST=$(bw_field "AWS_SECRET_ACCESS_KEY_TST")

  AWS_PROFILE_PRD=$(bw_field "AWS_PROFILE_PRD")
  AWS_ACCESS_KEY_ID_PRD=$(bw_field "AWS_ACCESS_KEY_ID_PRD")
  AWS_SECRET_ACCESS_KEY_PRD=$(bw_field "AWS_SECRET_ACCESS_KEY_PRD")

  if [ -z "$AWS_PROFILE_TST" ] || [ -z "$AWS_ACCESS_KEY_ID_TST" ]; then
    warn "AWS TST fields missing in Bitwarden, skipping AWS credentials"
  else
    mkdir -p "$HOME/.aws"

    # Start with TST profile (required)
    cat > "$HOME/.aws/credentials" <<EOF
[$AWS_PROFILE_TST]
aws_access_key_id = $AWS_ACCESS_KEY_ID_TST
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY_TST
EOF

    # Append PRD profile if credentials exist
    if [ -n "$AWS_PROFILE_PRD" ] && [ -n "$AWS_ACCESS_KEY_ID_PRD" ]; then
      cat >> "$HOME/.aws/credentials" <<EOF

[$AWS_PROFILE_PRD]
aws_access_key_id = $AWS_ACCESS_KEY_ID_PRD
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY_PRD
EOF
    else
      warn "AWS PRD fields missing in Bitwarden, skipping PRD profile"
    fi

    chmod 600 "$HOME/.aws/credentials"
    ok "Created $HOME/.aws/credentials"
  fi
fi

# ─── Kubeconfig (EKS) ────────────────────────────────────
if command -v aws >/dev/null 2>&1; then
  AWS_PROFILE_TST=$(bw_field "AWS_PROFILE_TST")
  AWS_PROFILE_PRD=$(bw_field "AWS_PROFILE_PRD")

  if [ -n "$AWS_PROFILE_TST" ]; then
    info "Adding TST kubeconfig..."
    if aws eks update-kubeconfig \
      --name tst \
      --region eu-central-1 \
      --role-arn arn:aws:iam::654261343536:role/tstEksAccessRole \
      --profile "$AWS_PROFILE_TST" \
      --alias tst 2>/dev/null; then
      ok "Kubeconfig: tst"
    else
      warn "Failed to add TST kubeconfig"
    fi
  fi

  if [ -n "$AWS_PROFILE_PRD" ] && [ -n "$(bw_field 'AWS_ACCESS_KEY_ID_PRD')" ]; then
    info "Adding PRD kubeconfig..."
    if aws eks update-kubeconfig \
      --name prd \
      --region eu-central-1 \
      --role-arn arn:aws:iam::350124346922:role/prdEksAccessRole \
      --profile "$AWS_PROFILE_PRD" \
      --alias prd 2>/dev/null; then
      ok "Kubeconfig: prd"
    else
      warn "Failed to add PRD kubeconfig"
    fi
  fi
else
  warn "aws CLI not found, skipping kubeconfig setup"
fi

ok "Init complete"
