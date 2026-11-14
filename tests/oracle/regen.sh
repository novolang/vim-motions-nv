#!/usr/bin/env bash
# tests/oracle/regen.sh — write the vector suites again from the editor.
#
# Each tests/oracle/<area>.lua is a list of cases.  Every case is typed
# into a real editor, and the result becomes tests/<area>_tests.nv, which
# `novo fmt` then leaves in canonical form.  Run it from anywhere:
#
#   bash tests/oracle/regen.sh [area ...]
#
# NVIM names the editor and NOVO the compiler; they default to the ones on
# the path.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$(cd "$HERE/../.." && pwd)"
NVIM="${NVIM:-nvim}"
NOVO="${NOVO:-novo}"
areas=("$@")
if [ ${#areas[@]} -eq 0 ]; then
  for f in "$HERE"/*.lua; do
    base="$(basename "$f" .lua)"
    [ "$base" = "gen" ] && continue
    [ "$base" = "one" ] && continue
    areas+=("$base")
  done
fi
cd "$PKG"
for a in "${areas[@]}"; do
  "$NVIM" --headless --clean -l tests/oracle/gen.lua "tests/oracle/$a.lua" "tests/${a}_tests.nv" >/dev/null 2>&1
  "$NOVO" fmt "tests/${a}_tests.nv" >/dev/null
  echo "  $a: $(grep -c '^@test' "tests/${a}_tests.nv") cases"
done
