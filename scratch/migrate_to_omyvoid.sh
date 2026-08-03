#!/bin/bash
set -euo pipefail

OLD_DIR="/home/erick/repos/omarchy"
NEW_DIR="/home/erick/repos/omyvoid"

echo "=== Starting Omyvoid directory and symlink migration ==="

if [[ ! -d "$OLD_DIR" ]]; then
  echo "Error: Old directory $OLD_DIR does not exist." >&2
  exit 1
fi

if [[ -d "$NEW_DIR" ]]; then
  echo "Error: Target directory $NEW_DIR already exists." >&2
  exit 1
fi

# Rename the repository folder
echo "Renaming repository directory..."
mv "$OLD_DIR" "$NEW_DIR"

# Helper function to recreate symlink
recreate_symlink() {
  local target="$1"
  local link_name="$2"
  echo "Updating symlink: $link_name -> $target"
  # Remove if it exists (file, directory, or symlink)
  rm -f "$link_name" || true
  # Create symlink
  ln -sfn "$target" "$link_name"
}

# 1. Update .local/share/omyvoid
recreate_symlink "$NEW_DIR" "/home/erick/.local/share/omyvoid"

# 2. Update elephant menus
recreate_symlink "$NEW_DIR/default/elephant/omyvoid_themes.lua" "/home/erick/.config/elephant/menus/omyvoid_themes.lua"
recreate_symlink "$NEW_DIR/default/elephant/omyvoid_background_selector.lua" "/home/erick/.config/elephant/menus/omyvoid_background_selector.lua"
recreate_symlink "$NEW_DIR/default/elephant/omyvoid_unlocks.lua" "/home/erick/.config/elephant/menus/omyvoid_unlocks.lua"

# 3. Update agent skills
recreate_symlink "$NEW_DIR/default/omyvoid-skill" "/home/erick/.claude/skills/omyvoid"
recreate_symlink "$NEW_DIR/default/omyvoid-skill" "/home/erick/.agents/skills/omyvoid"
recreate_symlink "$NEW_DIR/default/omyvoid-skill" "/home/erick/.codex/skills/omyvoid"
recreate_symlink "$NEW_DIR/default/omyvoid-skill" "/home/erick/.pi/agent/skills/omyvoid"

echo "=== Migration completed successfully! ==="
