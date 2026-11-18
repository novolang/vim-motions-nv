#!/usr/bin/env bash
# tests/consumer_size.sh — what a program that depends on this package gets.
#
# `vimram`, the text in memory of the tests, is for programs that name it.  A
# program that names `vimstep` and `vimmodal` and brings its own text must be
# built without it: `vimstep` holds a `use vimram` behind a condition that is
# false, and the compiler leaves a module out when every `use` that names it
# is behind a false condition.  This builds two programs against the package
# by path and looks at the symbols of each binary.
#
# Run from anywhere:  bash tests/consumer_size.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$(cd "$HERE/.." && pwd)"
NOVO="${NOVO:-$HOME/.novo/bin/novo}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/vim-motions-nv-size.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

fail=0
check() {
  if [ "$1" = "ok" ]; then echo "  ✓ $2"; else echo "  ✗ $2"; fail=1; fi
}

# program NAME: a package named NAME with a path dependency on this package,
# and the text on standard input as its main.
program() {
  local name="$1"
  mkdir -p "$WORK/$name/src"
  cat >"$WORK/$name/novo.toml" <<TOML
[package]
name = "$name"
version = "0.1.0"
main = "src/main.nv"

[dependencies]
vim-motions-nv = { path = "$PKG" }
TOML
  cat >"$WORK/$name/src/main.nv"
  ( cd "$WORK/$name" && NOVO_LEAK_CHECK=0 "$NOVO" build src/main.nv >"$WORK/$name.log" 2>&1 )
}

# has_symbol BINARY MODULE: whether the binary holds code of the module.
has_symbol() {
  # Counting, not `grep -q`: with pipefail, grep quitting early would make
  # the pipeline fail on the SIGPIPE `nm` gets.
  [ "$(nm "$1" | command grep -c "novo_user_$2\\.")" -gt 0 ]
}

# A host with a text of its own: the five methods of `TextView`.
program own_text <<'NOVO_SRC'
use std.list
use vimtext
use vimmodal
use vimstep

struct Lines
    var rows: [[Int]]

impl TextView for Lines
    fn line_count(self) -> Int
        list.len(self.rows)

    fn line_len(self, line: Int) -> Int
        list.len(self.rows[line])

    fn char_at(self, line: Int, col: Int) -> Int
        self.rows[line][col]

    fn top_line(self) -> Int
        0

    fn height(self) -> Int
        24

fn main() [io]
    let text = Lines { rows: [vimtext.decode_utf8("hello")] }
    var m = vimmodal.modal_new()
    let acts = vimstep.step_code_mut(var m, text, 'x')
    println("${list.len(acts)}")
NOVO_SRC

program ram_text <<'NOVO_SRC'
use vimmodal
use vimram

fn main() [io]
    var doc = vimram.doc_new(["hello"], 10)
    var m = vimmodal.modal_new()
    m = vimram.run(var doc, m, "x")
    println(vimram.doc_lines(doc)[0])
NOVO_SRC

for name in own_text ram_text; do
  if [ ! -x "$WORK/$name/$name" ]; then
    echo "  ✗ $name did not build"
    cat "$WORK/$name.log"
    exit 1
  fi
done

if has_symbol "$WORK/own_text/own_text" vimram; then
  check bad "a program with a text of its own has no vimram in it"
else
  check ok "a program with a text of its own has no vimram in it"
fi
if has_symbol "$WORK/own_text/own_text" vimstep; then
  check ok "and it has the vimstep it names"
else
  check bad "and it has the vimstep it names"
fi
if has_symbol "$WORK/ram_text/ram_text" vimram; then
  check ok "a program that names vimram has it"
else
  check bad "a program that names vimram has it"
fi
if [ "$("$WORK/own_text/own_text")" = "2" ] && [ "$("$WORK/ram_text/ram_text")" = "ello" ]; then
  check ok "both programs run"
else
  check bad "both programs run"
fi
exit $fail
