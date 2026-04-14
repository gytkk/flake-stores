#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"
LOCKFILE="$SCRIPT_DIR/package-lock.json"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $1" >&2
    exit 1
  }
}

for cmd in npm jq nix python3 rg mktemp tar; do
  require_cmd "$cmd"
done

LATEST_JSON=$(npm view openclaw version dist.integrity --json)
LATEST=$(echo "$LATEST_JSON" | jq -r '.version')
INTEGRITY=$(echo "$LATEST_JSON" | jq -r '."dist.integrity"')

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ] || [ -z "$INTEGRITY" ] || [ "$INTEGRITY" = "null" ]; then
  echo "ERROR: failed to fetch latest npm metadata for openclaw" >&2
  exit 1
fi

readarray -t CURRENT_VALUES < <(python3 - "$PACKAGE_NIX" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text()
patterns = [
    r'version = "([^"]+)";',
    r'hash = "([^"]+)";',
    r'npmDepsHash = "([^"]+)";',
]
for pattern in patterns:
    match = re.search(pattern, text)
    if not match:
        raise SystemExit(f"missing pattern: {pattern}")
    print(match.group(1))
PY
)

CURRENT="${CURRENT_VALUES[0]}"
CURRENT_SRC_HASH="${CURRENT_VALUES[1]}"
CURRENT_NPM_HASH="${CURRENT_VALUES[2]}"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"
PKG=$(npm pack --silent "openclaw@$LATEST")
tar xzf "$PKG"
cd package
npm install --omit=dev --package-lock-only --ignore-scripts --no-audit --no-fund --legacy-peer-deps >/dev/null
cp package-lock.json "$LOCKFILE"

NEW_NPM_HASH=$(nix shell --inputs-from "$REPO_ROOT" nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$LOCKFILE")

echo "Updating $CURRENT -> $LATEST"
python3 - "$PACKAGE_NIX" "$CURRENT" "$LATEST" "$CURRENT_SRC_HASH" "$INTEGRITY" "$CURRENT_NPM_HASH" "$NEW_NPM_HASH" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
replacements = [
    (f'version = "{sys.argv[2]}";', f'version = "{sys.argv[3]}";'),
    (f'hash = "{sys.argv[4]}";', f'hash = "{sys.argv[5]}";'),
    (f'npmDepsHash = "{sys.argv[6]}";', f'npmDepsHash = "{sys.argv[7]}";'),
]
for old, new in replacements:
    if old not in text:
        raise SystemExit(f"missing text to replace: {old}")
    text = text.replace(old, new, 1)
path.write_text(text)
PY

rg -n 'version = |hash = |npmDepsHash = ' "$PACKAGE_NIX" >/dev/null

echo "Updated package.nix to version $LATEST"
echo "Updated package-lock.json"
