#!/bin/bash
set -euo pipefail

CLAUDE_HOME="/home/node/.claude"
MCP_FILE="$CLAUDE_HOME/mcp.json"
MCP_TEMPLATE="/usr/local/share/claude-defaults/mcp.json"
SETTINGS_TEMPLATE="/usr/local/share/claude-defaults/settings.json"

echo "Initializing Claude Code configuration..."

# Create .claude directory if it doesn't exist
if [ ! -d "$CLAUDE_HOME" ]; then
    echo "Creating $CLAUDE_HOME directory..."
    mkdir -p "$CLAUDE_HOME"
    chown -R node:node "$CLAUDE_HOME"
fi

# Copy MCP configuration if it doesn't exist
if [ ! -f "$MCP_FILE" ]; then
    if [ -f "$MCP_TEMPLATE" ]; then
        echo "Copying MCP server configuration..."
        cp "$MCP_TEMPLATE" "$MCP_FILE"
        chown node:node "$MCP_FILE"
        ls -lah "$MCP_FILE"
        echo "✓ MCP servers configured:"
        echo "  - context7 (https://mcp.context7.com/sse)"
        echo "  - cf-docs (https://docs.mcp.cloudflare.com/sse)"
    else
        echo "Warning: MCP template not found at $MCP_TEMPLATE"
    fi
else
    echo "MCP configuration already exists, preserving user settings"
fi

# Always overwrite settings.json from template (template is source of truth;
# hooks and rules are managed separately by install scripts)
if [ -f "$SETTINGS_TEMPLATE" ]; then
    echo "Applying Claude Code settings from template..."
    cp "$SETTINGS_TEMPLATE" "$CLAUDE_HOME/settings.json"
    chown node:node "$CLAUDE_HOME/settings.json"
    echo "✓ Settings applied (yolo mode, timeouts, includeCoAuthoredBy)"
fi

# Ensure npm global directory structure exists (required for npx with MCP servers)
if [ ! -d "/home/node/.npm-global/lib" ]; then
    echo "Creating npm global directory structure..."
    mkdir -p /home/node/.npm-global/lib
    chown -R node:node /home/node/.npm-global
    echo "✓ npm global directory initialized"
fi

echo "Claude Code configuration complete"
