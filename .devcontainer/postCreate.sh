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

echo "=== Post-creation setup complete ==="
