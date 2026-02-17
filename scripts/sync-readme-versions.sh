#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT_DIR/README.md"
APPS_DIR="$ROOT_DIR/apps"

if [ ! -f "$README" ]; then
  exit 0
fi

if ! grep -q "^## App versions" "$README"; then
  echo "WARNING: '## App versions' section not found in README.md"
  exit 0
fi

section_file=$(mktemp)
trap 'rm -f "$section_file"' EXIT

{
  echo "## App versions"
  echo ""
  echo "| App | Version |"
  echo "|-----|---------|"
  for pkg in "$APPS_DIR"/*/package.nix; do
    [ -f "$pkg" ] || continue
    app=$(basename "$(dirname "$pkg")")
    ver=$(grep 'version = ' "$pkg" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    echo "| $app | $ver |"
  done | sort
} > "$section_file"

awk -v sf="$section_file" '
  /^## App versions/ {
    while ((getline line < sf) > 0) print line
    print ""
    skip = 1
    next
  }
  skip && /^## / { skip = 0 }
  skip { next }
  { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"
