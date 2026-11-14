# Changelog

All notable changes to vim-motions-nv are recorded here. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with the pre-1.0 rule that a breaking change bumps the MINOR number.

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
