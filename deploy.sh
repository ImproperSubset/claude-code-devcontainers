#!/bin/bash
# Deploy devcontainer config to a project via symlinks.
# Usage: ./deploy.sh /path/to/project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path>" >&2
    exit 1
fi

DEST="$(realpath "$1")"

if [ ! -d "$DEST" ]; then
    echo "Error: $DEST is not a directory" >&2
    exit 1
fi

if [ "$DEST" = "$SCRIPT_DIR" ]; then
    echo "Error: destination is the devcontainers repo itself" >&2
    exit 1
fi

# Symlink .devcontainer/
if [ -e "$DEST/.devcontainer" ]; then
    if [ -L "$DEST/.devcontainer" ]; then
        echo "Updating .devcontainer symlink ..."
        ln -sfn "$SCRIPT_DIR/.devcontainer" "$DEST/.devcontainer"
    else
        echo "Warning: $DEST/.devcontainer exists and is not a symlink — replace? [y/N]"
        read -r answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            rm -rf "$DEST/.devcontainer"
            ln -s "$SCRIPT_DIR/.devcontainer" "$DEST/.devcontainer"
        else
            exit 0
        fi
    fi
else
    echo "Linking .devcontainer/ ..."
    ln -s "$SCRIPT_DIR/.devcontainer" "$DEST/.devcontainer"
fi

# Symlink shell.sh
echo "Linking shell.sh ..."
ln -sfn "$SCRIPT_DIR/shell.sh" "$DEST/shell.sh"

# Copy .env (per-project, not symlinked)
if [ -f "$DEST/.env" ]; then
    echo "Keeping existing $DEST/.env"
elif [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Copying .env ..."
    cp "$SCRIPT_DIR/.env" "$DEST/.env"
else
    echo "Copying .env.example → .env ..."
    cp "$SCRIPT_DIR/.env.example" "$DEST/.env"
fi

# Ensure deployed files are gitignored
gitignore_add() {
    local pattern="$1"
    if [ -f "$DEST/.gitignore" ]; then
        grep -qxF "$pattern" "$DEST/.gitignore" 2>/dev/null && return
        echo "$pattern" >> "$DEST/.gitignore"
    else
        echo "$pattern" > "$DEST/.gitignore"
    fi
}

echo "Updating .gitignore ..."
gitignore_add '.env'
gitignore_add '.devcontainer'
gitignore_add 'shell.sh'

echo ""
echo "Deployed to $DEST (symlinked from $SCRIPT_DIR)"
echo "Next: open in VS Code → Ctrl+Shift+P → Dev Containers: Open Folder in Container"
