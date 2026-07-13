#!/usr/bin/env bash
#
# install.sh — install `runit` so it can be run from anywhere as `runit`.
#
# It symlinks (or copies, with --copy) the runit script into a directory on
# your PATH, marks it executable, and tells you how to fix your PATH if the
# chosen directory isn't on it yet.
#
# Usage:
#   ./install.sh                 # install into the first sensible bin dir
#   ./install.sh --dir DIR       # install into DIR
#   ./install.sh --copy          # copy the file instead of symlinking
#   ./install.sh --uninstall     # remove a previously installed runit
#
set -euo pipefail

NAME="runit"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SRC_DIR/$NAME"

dir=""
mode="symlink"
action="install"

while [ $# -gt 0 ]; do
    case "$1" in
        --dir)       dir="${2:?--dir needs a directory}"; shift 2 ;;
        --dir=*)     dir="${1#*=}"; shift ;;
        --copy)      mode="copy"; shift ;;
        --uninstall) action="uninstall"; shift ;;
        -h|--help)   sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)           echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

# Pick an install directory if the user didn't name one.
if [ -z "$dir" ]; then
    for cand in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
        case ":$PATH:" in
            *":$cand:"*) dir="$cand"; break ;;
        esac
    done
    # Nothing on PATH matched — default to ~/.local/bin and create it.
    [ -z "$dir" ] && dir="$HOME/.local/bin"
fi

target="$dir/$NAME"

if [ "$action" = "uninstall" ]; then
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -- "$target"
        echo "Removed $target"
    else
        echo "Nothing to uninstall at $target"
    fi
    exit 0
fi

if [ ! -f "$SRC" ]; then
    echo "Cannot find $NAME next to this script (looked for $SRC)." >&2
    exit 1
fi

mkdir -p "$dir"
chmod +x "$SRC"

if [ "$mode" = "copy" ]; then
    cp -- "$SRC" "$target"
    chmod +x "$target"
    echo "Copied $NAME -> $target"
else
    ln -sf -- "$SRC" "$target"
    echo "Linked $NAME -> $target"
fi

# Warn if the install dir isn't on PATH.
case ":$PATH:" in
    *":$dir:"*)
        echo "Done. Run: $NAME --list"
        ;;
    *)
        echo
        echo "NOTE: $dir is not on your PATH."
        case "${SHELL:-}" in
            *zsh)  rc="$HOME/.zshrc" ;;
            *bash) rc="$HOME/.bashrc" ;;
            *)     rc="your shell profile" ;;
        esac
        echo "Add this line to $rc, then restart your shell:"
        echo
        echo "    export PATH=\"$dir:\$PATH\""
        ;;
esac
