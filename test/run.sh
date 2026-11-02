#!/usr/bin/env bash
# Tests for nmclean. Builds a throwaway directory tree under $TMPDIR and runs
# nmclean against it only - never against real directories.
#
#   ./test/run.sh                 # run with the bash on PATH
#   TEST_BASH=/bin/bash ./test/run.sh   # e.g. macOS's bash 3.2
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nmclean="$here/../nmclean"
shell="${TEST_BASH:-bash}"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/nmclean-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# A fake npm so tests never consult (or depend on) the real global prefix
mkdir -p "$tmp/bin"
cat > "$tmp/bin/npm" <<'NPM'
#!/bin/sh
[ "$1 $2" = "prefix -g" ] && echo "$FAKE_NPM_PREFIX"
NPM
chmod +x "$tmp/bin/npm"
export PATH="$tmp/bin:$PATH"
unset NMCLEAN_ROOT

pass=0
fail=0
out=""

ok()  { pass=$((pass + 1)); echo "ok   - $1"; }
bad() { fail=$((fail + 1)); echo "FAIL - $1"; printf '%s\n' "$out" | sed 's/^/       | /'; }

run() { out="$("$shell" "$nmclean" "$@" 2>&1 </dev/null)"; }

lists()     { if printf '%s\n' "$out" | grep -qF -- "$1"; then ok "$2"; else bad "$2"; fi; }
not_lists() { if printf '%s\n' "$out" | grep -qF -- "$1"; then bad "$2"; else ok "$2"; fi; }
exists()    { if [ -d "$1" ]; then ok "$2"; else bad "$2"; fi; }
gone()      { if [ -e "$1" ]; then bad "$2"; else ok "$2"; fi; }

# Build a home-like tree
build() {
    rm -rf "$tmp/home"
    h="$tmp/home"
    mkdir -p \
        "$h/projects/api/node_modules/pkg/node_modules" \
        "$h/projects/my web/node_modules" \
        "$h/projects/api/.cache/node_modules" \
        "$h/.npm-global/lib/node_modules/npm" \
        "$h/.cursor/extensions/ext-a/node_modules" \
        "$h/.vscode/extensions/ext-b/node_modules" \
        "$h/.config/tool/node_modules" \
        "$h/npm-prefix/lib/node_modules/some-cli"
    ln -s "$h/npm-prefix" "$h/npm-prefix-link"
    export FAKE_NPM_PREFIX="$h/npm-prefix-link"
}

echo "# using $("$shell" -c 'echo bash $BASH_VERSION')"

echo "# default: hidden directories are skipped"
build
run -n "$h"
lists     "$h/projects/api/node_modules"               "lists a project node_modules"
lists     "$h/projects/my web/node_modules"            "lists paths with spaces"
not_lists "pkg/node_modules"                           "skips nested node_modules"
not_lists "$h/.npm-global"                             "skips ~/.npm-global"
not_lists "$h/.cursor"                                 "skips ~/.cursor extensions"
not_lists "$h/.vscode"                                 "skips ~/.vscode extensions"
not_lists "$h/.config"                                 "skips other dot-dirs"
not_lists "$h/projects/api/.cache"                     "skips dot-dirs below the top level"
lists     "Skipping npm global packages: $h/npm-prefix/lib/node_modules" "skips npm global prefix (via symlinked prefix)"
lists     "Found 2 folders"                            "finds exactly 2 folders"

echo "# --include-hidden opts in"
run -n --include-hidden "$h"
lists     "$h/.cursor/extensions/ext-a/node_modules"   "lists hidden folders"
lists     "$h/projects/api/.cache/node_modules"        "lists nested hidden folders"
lists     "Skipping npm global packages"               "still skips npm global prefix"
not_lists "pkg/node_modules"                           "still skips nested node_modules"

echo "# an explicitly given hidden root is searched"
run -n "$h/.cursor/extensions"
lists     "$h/.cursor/extensions/ext-a/node_modules"   "searches a hidden root"
run -n "$h/.config/tool"
lists     "$h/.config/tool/node_modules"               "searches a root inside a dot-dir"
(cd "$h/projects" && run -n . && lists "./api/node_modules" "searches '.' as root")

echo "# root that is itself a node_modules folder"
run -n "$h/projects/api/node_modules"
lists     "$h/projects/api/node_modules"               "lists the root itself"
not_lists "pkg/node_modules"                           "does not descend into it"
run -n "$h/npm-prefix/lib/node_modules"
lists     "No node_modules folders found."             "refuses the npm global folder as root"

echo "# without npm on PATH"
build
out="$(PATH="/usr/bin:/bin" "$shell" "$nmclean" -n "$h" 2>&1 </dev/null)"
lists     "$h/npm-prefix/lib/node_modules"             "works without npm (no global to protect)"

echo "# -y deletes only what was listed"
build
run -y "$h"
gone      "$h/projects/api/node_modules"               "deleted project node_modules"
gone      "$h/projects/my web/node_modules"            "deleted path with spaces"
exists    "$h/projects/api"                            "kept project folder"
exists    "$h/.npm-global/lib/node_modules/npm"        "kept ~/.npm-global"
exists    "$h/.cursor/extensions/ext-a/node_modules"   "kept ~/.cursor extension"
exists    "$h/.vscode/extensions/ext-b/node_modules"   "kept ~/.vscode extension"
exists    "$h/projects/api/.cache/node_modules"        "kept nested hidden folder"
exists    "$h/npm-prefix/lib/node_modules/some-cli"    "kept npm global packages"

echo "# -y --include-hidden still protects npm global"
build
run -y --include-hidden "$h"
gone      "$h/.cursor/extensions/ext-a/node_modules"   "deleted hidden folder when opted in"
exists    "$h/npm-prefix/lib/node_modules/some-cli"    "kept npm global packages"

echo "# options"
run --help
lists     "--include-hidden"                           "--help documents --include-hidden"
run --version
lists     "nmclean 1.1.0"                              "version is 1.1.0"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
