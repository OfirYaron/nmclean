#!/usr/bin/env bash
# Install nmclean into PREFIX (default: ~/.local/bin).
# Works from a clone (./install.sh) or piped from curl.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
URL="https://raw.githubusercontent.com/OfirYaron/nmclean/main/nmclean"

mkdir -p "$PREFIX"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

if [ -n "$script_dir" ] && [ -f "$script_dir/nmclean" ]; then
    cp "$script_dir/nmclean" "$PREFIX/nmclean"
else
    curl -fsSL "$URL" -o "$PREFIX/nmclean"
fi

chmod +x "$PREFIX/nmclean"
echo "Installed nmclean to $PREFIX/nmclean"

case ":$PATH:" in
    *":$PREFIX:"*) ;;
    *)
        echo
        echo "Note: $PREFIX is not on your PATH. Add this to your shell config:"
        echo "  export PATH=\"$PREFIX:\$PATH\""
        ;;
esac
