#!/usr/bin/env bash
# Launch a shell into the devcontainer without VSCode
set -euo pipefail

WORKSPACE_FOLDER="$(cd "$(dirname "$0")/.." && pwd)"

# Check if container is running, start if needed
if ! devcontainer exec --workspace-folder "$WORKSPACE_FOLDER" true 2>/dev/null; then
    echo "Container not running, starting..."
    devcontainer up --workspace-folder "$WORKSPACE_FOLDER"
fi

exec devcontainer exec --workspace-folder "$WORKSPACE_FOLDER" zsh
