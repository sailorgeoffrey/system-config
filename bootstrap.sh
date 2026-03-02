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
stow git

echo "✅ Bootstrap complete!"
