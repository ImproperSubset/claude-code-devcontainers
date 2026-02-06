#!/bin/bash
# Deploy devcontainer config to a project via symlinks.
# Usage: ./deploy.sh /path/to/project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BEGIN_MARKER="# BEGIN devcontainer (managed by deploy.sh)"
END_MARKER="# END devcontainer"

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

# Ensure deployed files are gitignored using section markers
echo "Updating .gitignore ..."

gitignore="$DEST/.gitignore"

MANAGED_ENTRIES=".env
.devcontainer
shell.sh"

MANAGED_BLOCK="$BEGIN_MARKER
$MANAGED_ENTRIES
$END_MARKER"

if [ -f "$gitignore" ]; then
    if grep -qF "$BEGIN_MARKER" "$gitignore"; then
        # Replace existing managed section
        awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v block="$MANAGED_BLOCK" '
            $0 == begin { print block; skip=1; next }
            $0 == end { skip=0; next }
            !skip { print }
        ' "$gitignore" > "$gitignore.tmp"
        mv "$gitignore.tmp" "$gitignore"
        echo "  Updated managed section"
    else
        # Remove old raw entries that are now managed
        temp="$gitignore.tmp"
        cp "$gitignore" "$temp"
        for pattern in '.env' '.devcontainer' 'shell.sh'; do
            grep -vxF "$pattern" "$temp" > "$temp.2" && mv "$temp.2" "$temp" || true
        done
        mv "$temp" "$gitignore"

        # Append managed section
        echo "" >> "$gitignore"
        echo "$MANAGED_BLOCK" >> "$gitignore"
        echo "  Added managed section"
    fi
else
    echo "$MANAGED_BLOCK" > "$gitignore"
    echo "  Created .gitignore with managed section"
fi

echo ""
echo "Deployed to $DEST (symlinked from $SCRIPT_DIR)"
echo "Next: open in VS Code → Ctrl+Shift+P → Dev Containers: Open Folder in Container"
