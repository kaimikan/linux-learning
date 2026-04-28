#!/usr/bin/env bash
# serve.sh — launch the MkDocs dev server for this project.
#
# Usage:
#   ./serve.sh           # just serve (visit http://127.0.0.1:8000 manually)
#   ./serve.sh --open    # serve AND open the default browser at the site
#
# The script cd's to its own directory before launching, so it works
# regardless of where you invoke it from.

set -euo pipefail

# Resolve symlinks (in case the script is invoked via a symlink) and cd to
# the directory the *real* script lives in.
cd "$(dirname "$(readlink -f "$0")")"

# If --open was passed, schedule a browser launch ~1 second after mkdocs
# starts. Run it in a background subshell so it doesn't block.
if [[ "${1:-}" == "--open" ]]; then
    (sleep 1 && xdg-open http://127.0.0.1:8000) &
fi

# `exec` replaces the bash process with mkdocs, so Ctrl+C goes straight to
# mkdocs (cleaner shutdown, no orphaned bash wrapper).
exec mkdocs serve
