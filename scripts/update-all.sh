#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPS_DIR="$ROOT_DIR/apps"

if [ ! -d "$APPS_DIR" ]; then
  echo "No apps directory found; nothing to update."
  exit 0
fi

for app_dir in "$APPS_DIR"/*; do
  [ -d "$app_dir" ] || continue

  app_name=$(basename "$app_dir")
  update_script="$app_dir/update.sh"

  if [ ! -x "$update_script" ]; then
    echo "Skipping $app_name: no update.sh"
    continue
  fi

  echo "Running $app_name update"
  "$update_script"
done
