#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPS_DIR="$ROOT_DIR/apps"
SETTINGS="$ROOT_DIR/settings.json"

if [ ! -d "$APPS_DIR" ]; then
  echo "No apps directory found; nothing to update."
  exit 0
fi

DENY_LIST=""
if [ -f "$SETTINGS" ]; then
  DENY_LIST=$(jq -r '.update.deny // [] | .[]' "$SETTINGS" 2>/dev/null || echo "")
fi

for app_dir in "$APPS_DIR"/*; do
  [ -d "$app_dir" ] || continue

  app_name=$(basename "$app_dir")
  update_script="$app_dir/update.sh"

  if [ ! -x "$update_script" ]; then
    echo "Skipping $app_name: no update.sh"
    continue
  fi

  if echo "$DENY_LIST" | grep -qx "$app_name"; then
    echo "Skipping $app_name: denied in settings.json"
    continue
  fi

  echo "Running $app_name update"
  "$update_script"
done
