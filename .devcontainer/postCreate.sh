#!/bin/bash
# Post-creation setup for the devcontainer.
# Runs after container creation, AFTER volume mounts are in place.
# This ensures npm packages install into the mounted npm-global volume.
set -euo pipefail

echo "=== Updating npm ==="
npm install -g npm@latest

echo "=== Installing AI CLI tools ==="
npm install -g @anthropic-ai/claude-code@latest --verbose
npm install -g @openai/codex
npm install -g @google/gemini-cli
npm install -g opencode-ai@latest

echo "=== Installing testing tools ==="
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install -g @playwright/test

echo "=== Installing cloud CLI tools ==="
npm install -g wrangler@latest
npm install -g vercel@latest

echo "=== Configuring AI tools ==="
ls -lah /home/node/.claude
/usr/local/bin/init-claude-config.sh
/usr/local/bin/init-claude-hooks.sh
/usr/local/bin/init-codex-config.sh
/usr/local/bin/init-opencode-config.sh

echo "=== Setting up Python ==="
/usr/local/bin/init-python.sh

echo "=== Installing shared tooling (rules, skills, commands) ==="
# Setup repo (bind-mounted at ~/.claude-setup)
if [[ -d "$HOME/.claude-setup" ]]; then
    if [[ -x "$HOME/.claude-setup/install.sh" ]]; then
        "$HOME/.claude-setup/install.sh"
    fi
else
    echo "Warning: ~/.claude-setup bind-mount not found — shared tooling not installed"
fi
# Brain plugin (bind-mounted at ~/.brain)
if [[ -d "$HOME/.brain" ]]; then
    if [[ -x "$HOME/.brain/scripts/install-plugin.sh" ]]; then
        "$HOME/.brain/scripts/install-plugin.sh"
    fi
else
    echo "Warning: ~/.brain bind-mount not found — brain plugin not installed"
fi

echo "=== Setting up claude wrapper (yolo mode) ==="
if [[ -x "$HOME/.brain/scripts/launchers/claude-wrapper" ]]; then
    ln -sf "$HOME/.brain/scripts/launchers/claude-wrapper" "$HOME/.local/bin/claude-wrapper"
    echo "✓ claude-wrapper symlinked to ~/.local/bin/claude-wrapper"
else
    echo "Warning: claude-wrapper not found at ~/.brain/scripts/launchers/claude-wrapper"
fi

echo "=== Setting up ralph (AI task orchestrator) ==="
if [[ -f "$HOME/.ralph/ralph_loop.py" ]]; then
    ln -sf "$HOME/.ralph/ralph_loop.py" "$HOME/.local/bin/ralph"
    echo "✓ ralph symlinked to ~/.local/bin/ralph"
else
    echo "Warning: ralph not found at ~/.ralph/ralph_loop.py"
fi

echo "=== Configuring Google Chrome ==="
# Chrome flags are pre-seeded via Docker named-volume initialization (see Dockerfile).
# The google-chrome-shared volume copies chrome-flags.conf from the image on first mount.
if [[ -f "$HOME/.config/google-chrome/chrome-flags.conf" ]]; then
    echo "✓ Chrome flags configured (Wayland, no-sandbox, disable-gpu)"
else
    echo "⚠ Chrome flags not found — volume may need to be recreated"
fi

echo "=== Post-creation setup complete ==="
