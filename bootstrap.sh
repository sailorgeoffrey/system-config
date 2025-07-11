#!/usr/bin/env bash
set -euo pipefail

STOW_DIR="stow"
TARGET_DIR="$HOME"

# Confirm we're running from the right place
if [ ! -d "$STOW_DIR" ]; then
  echo "ERROR: Could not find '$STOW_DIR' directory. Run this from the root of your system-config repo."
  exit 1
fi

# --- Ensure Homebrew is installed ---
if ! command -v brew >/dev/null 2>&1; then
  echo "🛠  Homebrew not found. Installing it now..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Ensure brew is on PATH (needed for new shells)
  if [[ -d /opt/homebrew/bin ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/bin ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# --- Install Homebrew packages first ---
if command -v brew >/dev/null 2>&1; then
  echo "📦 Installing Homebrew packages from Brewfile..."
  brew bundle --file=Brewfile
else
  echo "⚠️ Homebrew not found. Skipping Brewfile installation."
fi

echo "Bootstrapping dotfiles from '$STOW_DIR' to '$TARGET_DIR'..."

# Backup and stow
for pkg in "$STOW_DIR"/*; do
  pkgname=$(basename "$pkg")
  echo "Checking $pkgname..."

  for file in $(find "$pkg" -type f); do
    relpath="${file#$pkg/}"
    target="$TARGET_DIR/$relpath"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "  Backing up existing $target -> $target.bak"
      mv "$target" "$target.bak"
    fi
  done

  echo "  Stowing $pkgname"
  stow --dir="$STOW_DIR" --target="$TARGET_DIR" --adopt "$pkgname"
done

echo "✅ Bootstrap complete."
