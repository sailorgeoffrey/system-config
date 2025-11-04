#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="bootstrap.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ $CONFIG_FILE not found. Cannot verify keys."
  exit 1
fi

identity_count=$(yq '.github_identities | length' "$CONFIG_FILE")
echo "🔍 Verifying GitHub SSH keys..."
echo

all_ok=true

for i in $(seq 0 $((identity_count - 1))); do
  id=$(yq ".github_identities[$i].id" "$CONFIG_FILE")
  host="gh-$id"
  keyfile="$HOME/.ssh/id_github_$id"

  echo "🔑 $id ($host)"

  if [ ! -f "$keyfile" ]; then
    echo "  ❌ Key file missing: $keyfile"
    all_ok=false
    continue
  fi

  if ! ssh-add -l | grep -q "$keyfile"; then
    echo "  ⚠️  Key not loaded in ssh-agent"
  else
    echo "  ✅ Key loaded in ssh-agent"
  fi

  output=$(ssh -o BatchMode=yes -T git@$host 2>&1 || true)
  if echo "$output" | grep -q "successfully authenticated"; then
    echo "  ✅ GitHub SSH access verified"
  else
    echo "  ❌ Cannot authenticate to $host"
    echo "     ↳ SSH said: $output"
    all_ok=false
  fi
  echo

done

if [ "$all_ok" = true ]; then
  echo "✅ All GitHub SSH keys verified successfully."
else
  echo "❌ One or more keys are not set up correctly."
  exit 1
fi
