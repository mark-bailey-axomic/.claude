#!/usr/bin/env bash
# Restores Claude Code plugins from ~/.claude/settings.json
# Usage: bash restore-plugins.sh [path-to-settings.json]

set -euo pipefail

SETTINGS_FILE="${1:-$HOME/.claude/settings.json}"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Error: settings file not found at $SETTINGS_FILE"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it first."
  exit 1
fi

# Extract enabled plugin names from enabledPlugins object
plugins=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$SETTINGS_FILE")

if [ -z "$plugins" ]; then
  echo "No enabled plugins found in $SETTINGS_FILE"
  exit 0
fi

# Check marketplace exists, add official one if missing
marketplaces=$(claude plugin marketplace list 2>/dev/null || true)
if ! echo "$marketplaces" | grep -q "claude-plugins-official"; then
  echo "Adding official marketplace..."
  claude plugin marketplace add anthropics/claude-plugins-official
fi

while IFS= read -r plugin; do
  echo "Installing $plugin..."
  claude plugin install "$plugin" 2>/dev/null && echo "  OK" || echo "  Already installed or failed"
done <<< "$plugins"

echo "Done."
