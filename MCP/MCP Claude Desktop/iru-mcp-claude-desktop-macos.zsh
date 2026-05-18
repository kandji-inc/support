#!/bin/zsh

###################################################################################################
# Created by Iru, Inc.
###################################################################################################
# Software Information
###################################################################################################
#
#   Version 1.0.1
#
#   Wires Claude Desktop to Iru's hosted MCP using npx + mcp-remote (stdio bridge).
#
#   Documentation: https://docs.iru.com/en/endpoint/api/model-context-protocol/iru-mcp
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2026 Iru, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
###################################################################################################

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────
# Export these BEFORE running; do not put secrets directly in this file.
#
# Use the JSON from Copy MCP configuration in Iru (MCP configuration): map url to IRU_MCP_URL,
# X-API-Key to IRU_X_API_KEY, and X-MCP-Profile to IRU_X_MCP_PROFILE (same names as in the Iru MCP article).
#
# Example (replace PASTE_ placeholders with those three values from MCP configuration, then export):
#   export IRU_MCP_URL="PASTE_MCP_CONFIGURATION_URL"
#   export IRU_X_API_KEY="PASTE_MCP_CONFIGURATION_X_API_KEY"
#   export IRU_X_MCP_PROFILE="PASTE_MCP_CONFIGURATION_X_MCP_PROFILE"
#
# Cursor can use the same MCP configuration; Claude Desktop uses this stdio bridge via npx + mcp-remote.
# Override the bridge package if needed:
IRU_MCP_REMOTE_PKG="${IRU_MCP_REMOTE_PKG:-mcp-remote@0.1.13}"

IRU_MCP_URL="${IRU_MCP_URL:?Set IRU_MCP_URL before running this script}"
IRU_X_API_KEY="${IRU_X_API_KEY:?Set IRU_X_API_KEY before running this script}"
IRU_X_MCP_PROFILE="${IRU_X_MCP_PROFILE:?Set IRU_X_MCP_PROFILE before running this script}"

# ── Detect config path by OS ────────────────────────────────────────
case "$(uname -s)" in
  Darwin)  CONFIG_DIR="$HOME/Library/Application Support/Claude" ;;
  Linux)   CONFIG_DIR="$HOME/.config/Claude" ;;
  MINGW*|MSYS*|CYGWIN*)
           CONFIG_DIR="$APPDATA/Claude" ;;
  *)       echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

# ── Ensure dependencies ─────────────────────────────────────────────
if ! command -v npx &>/dev/null; then
  echo "Error: npx not found. Install Node.js (v20+) first." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq not found. Install it (brew install jq / apt install jq)." >&2
  exit 1
fi

# ── Build the server entry (stdio → mcp-remote → same URL/headers as Cursor) ───
SERVER_ENTRY=$(jq -n \
  --arg pkg "$IRU_MCP_REMOTE_PKG" \
  --arg url "$IRU_MCP_URL" \
  --arg key "$IRU_X_API_KEY" \
  --arg profile "$IRU_X_MCP_PROFILE" \
  '{
    command: "npx",
    args: [
      "-y",
      $pkg,
      $url,
      "--header",
      "X-API-Key:${IRU_X_API_KEY}",
      "--header",
      "X-MCP-Profile:${IRU_X_MCP_PROFILE}"
    ],
    env: {
      IRU_X_API_KEY: $key,
      IRU_X_MCP_PROFILE: $profile
    }
  }')

# ── Merge into existing config (or create new) ─────────────────────
mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
  echo "Backed up existing config to $(basename "$CONFIG_FILE").bak"

  UPDATED=$(jq --argjson entry "$SERVER_ENTRY" \
    '{mcpServers: ((.mcpServers // {}) | .iru = $entry)} + (del(.mcpServers))' "$CONFIG_FILE")
else
  UPDATED=$(jq -n --argjson entry "$SERVER_ENTRY" \
    '{ mcpServers: { iru: $entry } }')
fi

echo "$UPDATED" > "$CONFIG_FILE"

# ── Done ────────────────────────────────────────────────────────────
cat <<EOF

✓ IRU MCP server added to Claude Desktop config.
  Config: $CONFIG_FILE
  Bridge package: ${IRU_MCP_REMOTE_PKG}

Next steps:
  1. Fully quit Claude Desktop (Cmd+Q / right-click tray → Quit), then reopen it.
  2. Open a new chat.
  3. Click the + button beside the composer.
  4. Choose Ask Iru.
  5. Start typing a message so Claude can use the Iru MCP.
  6. To turn Iru on or off without editing the config, click +, open Connectors, and use the Iru toggle.
  7. If something fails: in Claude Desktop open Settings → Developer to review the Iru MCP
     server configuration, whether it is running, and any errors.

(Credentials not echoed; verify in $CONFIG_FILE if needed)
EOF
