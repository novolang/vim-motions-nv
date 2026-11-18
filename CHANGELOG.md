# Changelog

All notable changes to vim-motions-nv are recorded here. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with the pre-1.0 rule that a breaking change bumps the MINOR number.

## 0.1.1 — 2026-11-18

This release makes a key cheap to step, gives a host the cursor a key was
typed at, and keeps the text in memory out of a program that does not name
it. A call that 0.1.0 accepted still means what it did.

- Every entry point of `vimstep` has a `_mut` form that takes the state as
  `var`, changes it in place and answers the actions alone: `step_mut`,
  `step_code_mut`, `settle_mut`, `set_cursor_mut`, `search_found_mut`,
  `search_failed_mut`, `cmdline_done_mut` and `cmdline_abort_mut`. A key
  stepped this way costs about 1,500 instructions on a text of 20,000 lines;
  `step` copied the registers, the marks and the dot record first and cost
  about 16,000. The plain forms stay, as thin wrappers over the `_mut` forms
  that copy the state first and answer a new one, so a host that keeps the
  old state as well still can. A state is shared by every name that holds it,
  so a host that wants the state as it was before a `_mut` step makes a copy
  with `vimmodal.modal_clone`.
- `Modal` has two new fields, `key_line` and `key_col`: the cursor the last
  key was typed at, after it was brought inside the text. It is the place an
  `UndoMark` of that key names. A `_mut` step leaves a host no old state to
  read the cursor from, and a redo needs it, so the pair is the host's to
  store beside the change at the `Undo` action. The text in memory does this.
- `vimram` is left out of a program that does not name it. `vimstep` holds a
  `use vimram` behind a condition that is false, so the compiler removes the
  module and what only it reached, as SPEC section 9.6 describes. The
  74 KB of code its instances of the key loop for `Doc` took no longer
  reaches a binary that brings its own text. A program that names `vimram`
  gets it as before. The new module `vimcheck` holds no code: it names the
  other modules so that `novo pkg build`, which has no `main` to start from,
  still checks all of them.
- `Modal.reset_pending`, which forgets the count, the operator, the prefix
  key, the register choice and the keys of the command being typed, is named
  in the README and its comment says when a host calls it.
- `vimram.run` does not change the state it is given: it steps a copy.
- A consumer has to change nothing. One thing differs for a program that
  builds a `Modal` with a struct literal instead of `vimmodal.modal_new`: it
  has to give the two new fields.
- `tests/step_mut_tests.nv` checks each `_mut` form against its plain form
  key by key, the cursor of a key and a redo. `tests/consumer_size.sh` builds
  two programs against the package and checks the symbols of each.

## 0.1.0 — 2026-11-14

The first release. It provides Vim's modal editing model as a function of
values, and the means to run it against a text in memory.

- `vimstep.step` takes a state, a text read through the `TextView` trait and
  one keystroke from keymap-nv, and answers a new state and a list of
  actions. The searches and the command line are answered with
  `search_found`, `search_failed`, `cmdline_done` and `cmdline_abort`.
- Motions: `h j k l`, the arrow keys, `0 ^ $ g_ |`, `w W b B e E ge gE`,
  `gg G` with counts, `f t F T ; ,`, `%`, `{ }`, `( )`, `H M L`, `+ - _`,
  marks with `` ` `` and `'`, and `n N * #` as searches.
- Operators: `d c y > < gu gU g~`, doubled for lines, with counts before and
  after, and `x X s S D C Y r ~ J gJ p P u Ctrl-R .`.
- Text objects: `iw aw iW aW is as ip ap`, the blocks of `( [ { <` and the
  quotes `"`, `'` and `` ` ``, in Operator-pending and Visual mode.
- Insert mode and Replace mode, with the text typed recorded for `.`, and
  `i a I A o O gI R` with counts.
- Visual mode over characters and over lines, with the operators, `p`, `r`,
  `J`, `o` and `gv`.
- Registers `""`, `"0` to `"9`, `"-`, `"a` to `"z` and `"_`, and marks `a` to
  `z`, `'`, `<` and `>`.
- `Ctrl-E Ctrl-Y Ctrl-D Ctrl-U Ctrl-F Ctrl-B zt zz zb`.
- `vimram`, a text in memory that applies the actions and keeps an undo
  stack, and `vimkey.keys_of`, which reads keys written as in Vim's
  documentation.
- Blockwise Visual mode is refused. The README lists every other departure
  from Vim.
- The test vectors, 17,771 of them, are checked against Neovim 0.12.
