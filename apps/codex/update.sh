#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/openai/codex/releases/latest)
TAG=$(jq -r '.tag_name' <<< "$RELEASE_JSON")
LATEST="${TAG#rust-v}"

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ] || [ "$LATEST" = "$TAG" ]; then
  echo "ERROR: Failed to fetch latest version from GitHub API"
  exit 1
fi

CURRENT=$(rg 'version = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ "$LATEST" = "$CURRENT" ]; then
  echo "Already at latest version: $LATEST"
  exit 0
fi

echo "Updating $CURRENT -> $LATEST"

declare -A PLATFORM_TARGET=(
  ["aarch64-darwin"]="aarch64-apple-darwin"
  ["x86_64-darwin"]="x86_64-apple-darwin"
  ["x86_64-linux"]="x86_64-unknown-linux-musl"
  ["aarch64-linux"]="aarch64-unknown-linux-musl"
)

declare -A HASHES
for system in aarch64-darwin x86_64-darwin x86_64-linux aarch64-linux; do
  target="${PLATFORM_TARGET[$system]}"
  asset="codex-${target}.tar.gz"

  echo "Reading hash for $system..."
  digest=$(jq -er --arg asset "$asset" '.assets[] | select(.name == $asset) | .digest' <<< "$RELEASE_JSON") || {
    echo "ERROR: No release asset digest found for $asset"
    exit 1
  }

  sri_hash=$(nix hash convert --to sri "$digest")

  HASHES[$system]="$sri_hash"
  echo "  $system: $sri_hash"
done

sed -i "s/version = \"$CURRENT\"/version = \"$LATEST\"/" "$PACKAGE_NIX"

for system in aarch64-darwin x86_64-darwin x86_64-linux aarch64-linux; do
  old_hash=$(rg -A3 "\"$system\"" "$PACKAGE_NIX" | rg 'hash = ' | sed 's/.*"\(.*\)".*/\1/')
  new_hash="${HASHES[$system]}"
  if [ -n "$old_hash" ] && [ -n "$new_hash" ]; then
    sed -i "s|$old_hash|$new_hash|" "$PACKAGE_NIX"
  fi
done

echo "Updated package.nix to version $LATEST"
