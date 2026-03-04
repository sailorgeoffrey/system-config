#!/usr/bin/env bash
set -euo pipefail

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

# --- Stow other packages ---
echo "📂 Stowing dotfiles..."
stow zsh
stow tmux
stow aws-sso-profile
stow 1Password
stow ssh
stow git

# --- Configure 1Password SSH Agent ---
echo "🔑 Configuring 1Password SSH agent..."

# Enable SSH agent in 1Password (requires 1Password 8+)
# Note: This may require manual approval in 1Password GUI on first run
if command -v op >/dev/null 2>&1; then
  # Create SSH directory if it doesn't exist
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  # Configure SSH to use 1Password agent
  if [[ ! -f ~/.ssh/config ]] || ! grep -q "IdentityAgent" ~/.ssh/config; then
    echo "Adding 1Password SSH agent configuration to ~/.ssh/config..."
    cat >> ~/.ssh/config << 'EOF'

# 1Password SSH Agent
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
    chmod 600 ~/.ssh/config
  fi

  # Generate public key files for all SSH keys stored in 1Password
  echo "Generating public key files for 1Password SSH keys..."

  # Get all public keys from the SSH agent
  if ! ssh-add -L >/dev/null 2>&1; then
    echo "⚠️  No SSH keys loaded in agent. Make sure:"
    echo "   1. 1Password SSH agent is enabled (Settings → Developer → Use SSH agent)"
    echo "   2. Your SSH keys in 1Password have 'Use with SSH' enabled"
    return 1
  fi

  if op account list >/dev/null 2>&1; then
    # Simply use the comment field from the SSH keys
    while IFS= read -r line; do
      # Extract comment (last field) from ssh-add -L output
      comment=$(echo "$line" | awk '{print $NF}')
      if [[ -n "$comment" && "$comment" != ssh-* ]]; then
        echo "  - Generating public key for: $comment"
        filename=$(echo "$comment" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
        echo "$line" > ~/.ssh/"${filename}.pub"
        chmod 644 ~/.ssh/"${filename}.pub"
      fi
    done < <(ssh-add -L)
    echo "Public key files generated in ~/.ssh/"
  else
    echo "⚠️  Could not access 1Password. Make sure 1Password is running and you're signed in."
    echo "   Falling back to generating keys from agent comments..."
    ssh-add -L | while read -r keytype keydata comment; do
      if [[ -n "$comment" ]]; then
        filename=$(echo "$comment" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | sed 's/@.*//')
        echo "$keytype $keydata $comment" > ~/.ssh/"${filename}.pub"
        chmod 644 ~/.ssh/"${filename}.pub"
        echo "  - Generated: ${filename}.pub"
      fi
    done
  fi
else
  echo "⚠️  1Password CLI (op) not found. Install it to manage SSH keys programmatically."
  echo "   You can still enable SSH agent manually in 1Password settings."
fi

echo ""
# --- Generate authorized_keys from public keys (excluding github*) ---
find ~/.ssh -maxdepth 1 -name "*.pub" ! -name "github*" -exec cat {} + >| ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# --- Generate allowed_signers from public keys (starting with github*) ---
default_email=$(git config --global user.email || echo "user@example.com")
# Clear the file first
: >| ~/.ssh/allowed_signers
find ~/.ssh -maxdepth 1 -name "github*.pub" | while read -r keyfile; do
  email="$default_email"
  # Use specific email for github-ev
  if [[ "$keyfile" == *"github-ev"* ]]; then
    # Look for the email in .gitconfig-ev if it exists
    ev_config="$HOME/system-config/git/.gitconfig-ev"
    if [[ -f "$ev_config" ]]; then
      email=$(grep "email =" "$ev_config" | cut -d'=' -f2 | xargs)
    fi
  fi
  echo "$email $(cat "$keyfile")" >> ~/.ssh/allowed_signers
done
chmod 600 ~/.ssh/allowed_signers

echo "🔍 Verifying setup..."
[[ -f ~/.ssh/authorized_keys ]] && echo "  ✓ authorized_keys created"
[[ -f ~/.ssh/allowed_signers ]] && echo "  ✓ allowed_signers created"
ssh-add -L >/dev/null 2>&1 && echo "  ✓ SSH agent has keys"

echo "✅ Bootstrap complete!"
