#!/bin/bash
# Open a shell in the running devcontainer.
# Usage: ./shell.sh [command...]
#   ./shell.sh          # interactive zsh
#   ./shell.sh bash     # interactive bash
#   ./shell.sh ls -la   # run a command

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="/workspaces/$(basename "$REPO_DIR")"

CONTAINER_ID=$(docker ps -q --filter "label=devcontainer.local_folder=$REPO_DIR")

if [ -z "$CONTAINER_ID" ]; then
    echo "No running devcontainer found for $REPO_DIR" >&2
    echo "Start it from VS Code: Ctrl+Shift+P → Dev Containers: Open Folder in Container" >&2
    exit 1
fi

TTY_FLAG="-i"
[ -t 0 ] && TTY_FLAG="-it"

if [ $# -eq 0 ]; then
    exec docker exec $TTY_FLAG -e "TERM=${TERM:-xterm-256color}" -w "$WORKSPACE" "$CONTAINER_ID" zsh -l
else
    exec docker exec $TTY_FLAG -e "TERM=${TERM:-xterm-256color}" -w "$WORKSPACE" "$CONTAINER_ID" "$@"
fi
