#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

LATEST=$(curl -s https://registry.npmjs.org/@anthropic-ai/claude-code/latest \
  | jq -r '.version')

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
  echo "ERROR: Failed to fetch latest version from npm registry"
  exit 1
fi

CURRENT=$(grep 'version = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ "$LATEST" = "$CURRENT" ]; then
  echo "Already at latest version: $LATEST"
  exit 0
fi

echo "Updating $CURRENT -> $LATEST"

URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${LATEST}.tgz"

echo "Fetching hash for npm tarball..."
sri_hash=$(nix store prefetch-file --json "$URL" | jq -r '.hash')

if [ -z "$sri_hash" ]; then
  echo "ERROR: Failed to fetch hash for npm tarball"
  exit 1
fi

echo "  hash: $sri_hash"

old_hash=$(grep 'hash = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

sed -i "s/version = \"$CURRENT\"/version = \"$LATEST\"/" "$PACKAGE_NIX"
sed -i "s|$old_hash|$sri_hash|" "$PACKAGE_NIX"

echo "Updated package.nix to version $LATEST"
