#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="bootstrap.yaml"
STOW_DIR="stow"
TARGET_DIR="$HOME"

# --- Ensure Homebrew is installed ---
if ! command -v brew >/dev/null 2>&1; then
  echo "🛠  Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -d /opt/homebrew/bin ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/bin ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# --- Install dependencies (e.g. yq) ---
echo "📦 Installing packages from Brewfile..."
brew bundle --file=Brewfile

# --- Load config ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ $CONFIG_FILE not found. Please create it before bootstrapping."
  exit 1
fi

full_name=$(yq ".full_name" "$CONFIG_FILE")
email=$(yq ".email" "$CONFIG_FILE")

# --- Generate ~/.gitconfig dynamically ---
echo "📝 Generating ~/.gitconfig..."
cat > "$HOME/.gitconfig" <<EOF
[user]
    name = $full_name
    email = $email

[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true

[core]
    autocrlf = input

[alias]
    bb = !better-branch.sh

[rerere]
    enabled = true

[column]
    ui = auto

[branch]
    sort = -committerdate
EOF

# --- Generate SSH keys and .ssh/config ---
echo "🔧 Preparing ~/.ssh/config..."
ssh_config="$HOME/.ssh/config"
mkdir -p "$(dirname "$ssh_config")"
: > "$ssh_config"

identity_count=$(yq '.github_identities | length' "$CONFIG_FILE")

for i in $(seq 0 $((identity_count - 1))); do
  id=$(yq ".github_identities[$i].id" "$CONFIG_FILE")

  if [[ "$id" =~ [^a-zA-Z0-9_-] ]]; then
    echo "❌ Invalid id '$id'. Only letters, numbers, dashes, and underscores are allowed."
    exit 1
  fi

  host="gh-$id"
  keyfile="$HOME/.ssh/id_github_$id"

  # Read orgs into array without mapfile (for macOS Bash 3.x compatibility)
  orgs=()
  while IFS= read -r org; do
    orgs+=("$org")
  done < <(yq ".github_identities[$i].orgs[]" "$CONFIG_FILE")

  # Generate key if missing
  if [ ! -f "$keyfile" ]; then
    echo "🔐 Generating SSH key for $id..."
    ssh-keygen -t ed25519 -C "$email" -f "$keyfile" -N ""
  fi

  # Add key to ssh-agent
  if ! ssh-add -l | grep -q "$keyfile"; then
    echo "➕ Adding key for $id to ssh-agent"
    ssh-add --apple-use-keychain "$keyfile"
  fi

  # Add host entry to ssh config
  cat >> "$ssh_config" <<EOF
Host $host
  HostName github.com
  User git
  IdentityFile $keyfile
  IdentitiesOnly yes
  UseKeychain yes
  AddKeysToAgent yes
EOF

  # Add insteadOf mappings to .gitconfig
  for org in "${orgs[@]}"; do
    echo "[url \"git@$host:$org/\"]" >> "$HOME/.gitconfig"
    echo "    insteadOf = git@github.com:$org/" >> "$HOME/.gitconfig"
    echo >> "$HOME/.gitconfig"
  done

done

# --- Stow other packages ---
echo "📁 Stowing non-sensitive dotfiles..."
for pkg in "$STOW_DIR"/*; do
  pkgname=$(basename "$pkg")
  if [[ "$pkgname" == "ssh" || "$pkgname" == "git" ]]; then
    continue  # skip ssh and git
  fi
  echo "  🔗 Stowing $pkgname"
  stow --dir="$STOW_DIR" --target="$TARGET_DIR" --adopt "$pkgname"
done

# --- Show public keys ---
echo
echo "📋 SSH Public Keys (add these to GitHub):"
for i in $(seq 0 $((identity_count - 1))); do
  id=$(yq ".github_identities[$i].id" "$CONFIG_FILE")
  pubkey="$HOME/.ssh/id_github_$id.pub"
  if [ -f "$pubkey" ]; then
    echo "🔑 $id:"
    cat "$pubkey"
    echo
  fi
done

echo "✅ Bootstrap complete!"
