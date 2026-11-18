# vim-motions-nv

Vim is a modal text editor. The same key means one thing in Normal mode,
another after an operator such as `d`, another in Insert mode and another
in Visual mode, and a command is built from a count, a register, an
operator and a motion. This package is that model as a function of values:
it takes one keystroke and answers a new state and a list of actions for
the host to apply to its own text. It reads and writes no terminal, no file
and no clock. The behaviour is Vim's, as `:help motion.txt`,
`:help change.txt` and `:help visual.txt` describe it, and the test vectors
are the results of a real editor.

The keystroke type is [keymap-nv](https://novo-lang.org/packages/keymap-nv)'s,
so a program that reads the terminal with
[termios-nv](https://novo-lang.org/packages/termios-nv) passes the decoder's
output straight in.

## What it is

A **mode** says what a key means. Normal mode runs commands. Insert mode
types text. Replace mode, entered with `R`, types over the characters it
meets. Visual mode selects characters, or whole lines in the linewise form.
The command line, entered with `:`, `/` and `?`, belongs to the host.

A **command** is typed one key at a time. It can begin with a **count**
(`3`) and a **register** (`"a`). An **operator** (`d`, `c`, `y`, `>`, `<`,
`gu`, `gU`, `g~`) waits for a **motion** (`w`, `$`, `}`, `f,`) or a **text
object** (`iw`, `a(`, `i"`) that says which text it works on. The count may
be typed again after the operator, and the two are multiplied. Typing the
operator twice, as in `dd`, works on lines.

A **register** holds text and whether it is whole lines. The package keeps
the unnamed register, `"0` for yanks, `"1` to `"9` for deletes of a line or
more, `"-` for smaller deletes, and `"a` to `"z`. An upper case name
appends. The black hole register `"_` keeps nothing. A **mark** holds a
place, `a` to `z`, and the place before the last jump.

The **dot repeat** types the last change again, with the same keys and the
text typed in Insert mode. A count typed before `.` replaces the one the
change had.

The package does not own the text. The host implements `TextView`, a trait
of five methods: the number of lines, the length of a line in codepoints,
the codepoint at a line and column, the first line shown in the window and
the window's height. A step reads the text through it and answers
**actions**, which the host applies in order: delete a span, insert text,
join lines, shift lines, change case, put a register, move the window,
begin an undo step, ask for a search or a command line, or refuse the key.
The host keeps its own undo stack, its own search and its own command line.

A column counts codepoints, not bytes, and a tab is one column.

## Install

```
novo pkg add vim-motions-nv
```

## Example

The module `vimram` is a text in memory that applies the actions of a step.
A program with no text store of its own can use it, and the tests use it to
run keys against a text. Keys are written the way Vim's documentation writes
them. A program that does not name `vimram` is built without it, and the
module's 74 KB of code does not reach the binary.

```novo
use std.list
use vimmodal
use vimram

fn main() [io]
    // A text of three lines, shown in a window of ten.
    var doc = vimram.doc_new(["hello world", "second line", "third"], 10)
    var m = vimmodal.modal_new()
    // Delete a word, go down a line, append a bang, leave Insert mode.
    m = vimram.run(var doc, m, "dwjA!<Esc>")
    for line in vimram.doc_lines(doc)
        println(line)
    // The cursor, counted from zero, and the mode.
    println("${m.line},${m.col} ${m.mode_of()}")
```

The output is `world`, `second line!`, `third` and then `1,11 0`: line 1,
column 11, Normal mode.

A program with a terminal reads keys, steps, applies the actions to its text
and draws. This is its loop, with the drawing left out. It changes the
state in place with `step_mut`, which copies nothing. It is marked `ignore`
because it needs a terminal.

```novo ignore
use keydecode
use tioinput
use vimmodal
use vimstep
use vimram

// handle feeds the keys one read produced to the editor model.
fn handle(var doc: Doc, var m: Modal, step: tioinput.TioInputStep)
    for ev in step.events
        match ev
            TioKeyEvent(e) =>
                if e.kind == keydecode.KEY_EVENT_PRESSED
                    let acts = vimstep.step_mut(var m, doc, e.stroke)
                    // Apply the actions in order, then let the model
                    // find the columns that depend on the new text.
                    m = vimram.apply_actions(var doc, m, acts)
                    vimstep.settle_mut(var m, doc)
            TioReplyEvent(r) =>
                continue
```

Each frame, the host writes `doc_lines(doc)` and the cursor `m.line`,
`m.col` into a `tuibuf.TuiBuffer` with `tuibuf.buffer_set_str`, and sends
`tuibuf.diff` and `tuibuf.patch_bytes` to the terminal. A program with its
own text type implements `TextView` for it and applies the actions itself.

## What the package contains

| Module | Contents |
| --- | --- |
| `vimstep` | The entry points: `step`, `settle`, the answers to a search and to a command line, and `set_cursor`, each in a plain form and in a `_mut` form that changes the state in place. |
| `vimmodal` | The state (`Modal`), the actions (`Action`, `Span`, `Step`), the mode, operator and register numbers, and the registers and marks. |
| `vimtext` | `TextView`, `Pos`, the character classes and the reading of UTF-8. |
| `vimkey` | A keystroke as a number, and keys written as text. |
| `vimram` | A text in memory that applies actions, keeps an undo stack and answers searches. A program is built with it only when the program names it. |
| `vimmotion` | The motions as functions of a text and a place. |
| `vimobject` | The text objects of a word, a paragraph, a block and a quoted string. |
| `vimedit` | What an operator does to a range, and `x`, `p`, `J`, `r`, `~`, `o`. |
| `viminsert` | Insert mode and Replace mode. |
| `vimnormal` | Normal, Operator-pending and Visual mode: the key loop. |
| `vimscroll` | `Ctrl-E`, `Ctrl-Y`, `Ctrl-D`, `Ctrl-U`, `Ctrl-F`, `Ctrl-B`, `zt`, `zz` and `zb`. |
| `vimcheck` | No code. It names the modules above so that `novo pkg build` checks them all; `vimram` is left out on purpose, and the test suites check it. |

## How to choose an entry point

**`vimstep.step_mut` takes a keystroke and changes the state it is given.**
It is what a program with a terminal uses, and it answers the list of
actions alone. `vimstep.step_code_mut` takes the number `vimkey.key_code`
makes from a keystroke, for a program that already holds keys as numbers.

**`vimstep.step` and `vimstep.step_code` answer a new state** and leave the
one they were given as it was. They copy the state first, which a key costs
a copy of the registers, the marks and the dot record (about 16,000
instructions on a 20,000-line text), where `step_mut` costs about 1,500. Use
them where the old state is wanted afterwards, as in a test.

Every other entry point has the same two forms: `settle` and `settle_mut`,
`set_cursor` and `set_cursor_mut`, `search_found` and `search_found_mut`,
`search_failed` and `search_failed_mut`, `cmdline_done` and
`cmdline_done_mut`, `cmdline_abort` and `cmdline_abort_mut`.

**`vimram.run` takes keys written as text** and applies each step to a
`Doc`. Use it in tests and for scripted editing.

**The functions of `vimmotion`, `vimobject` and `vimscroll` take a text
and a place** and answer where a motion goes or what an object covers. A
program that wants Vim's `w` or `ip` without the rest calls them directly.

## The rules a user needs

1. A plain step does not change the state it was given. It answers a new
   one and a list of actions. A `_mut` step changes the state in place and
   answers the list. A state is shared by every name that holds it, so a host
   that wants the state as it was before a `_mut` step makes a copy first with
   `vimmodal.modal_clone`.
2. The places in an action refer to the text as it is after the actions
   before it in the same list. The host applies them in order.
3. After applying the actions, the host calls `vimstep.settle` with the
   changed text. It brings the cursor inside the text and finds the column
   of a command such as `>>` that leaves the cursor on the first character
   that is not blank. `step` does this first on the text it is given, so a
   host that reads the cursor only after the next key can skip the call.
4. A characterwise span runs up to but not including its end. A linewise
   span is whole lines, first to last. `Delete` of a linewise span leaves
   one empty line when it takes every line.
5. `UndoMark` begins an undo step. An insert, from `i` to `Esc`, is one
   step. Its place is the cursor to put back when the step is undone.
   `Undo` and `Redo` are for the host to carry out. It then calls
   `vimstep.set_cursor` with the place it chose. A redo needs the cursor the
   key was typed at, and `Modal.key_line` and `Modal.key_col` hold it after
   every step, in the plain form and in the `_mut` form alike: the cursor
   after it was brought inside the text, which is the place an `UndoMark` of
   that key names. A host that keeps a redo stack stores the pair beside the
   change at the `Undo` action and uses it at the `Redo` action.
6. A `Search` action asks the host to find the `count`th match of the
   pattern from the cursor. An empty pattern is the last one. The host
   answers with `vimstep.search_found` or `vimstep.search_failed`. The
   answer moves the cursor, or ends the range of a pending operator, as in
   `d/text`. `n` and `N` ask for the direction the last search had, or the
   opposite.
7. An `EnterCommandLine` action puts the state in command line mode, where
   every key is refused. The host reads the line and answers with
   `vimstep.cmdline_done` or `vimstep.cmdline_abort`. For `/` and `?` the
   answer is a `Search` action; for `:` the host runs the command.
8. A `Bell` action says a key was refused. The command being typed is
   forgotten. Whether to discard the keys typed ahead is the host's choice;
   `vimram.run` discards them, as Vim does.
9. `ScrollBy` moves the first line shown by a number of lines, and
   `ScrollPage` by pages. `vimscroll.page_top` is the rule for pages.
10. `Indent` and `Dedent` are in shift widths. How a shift width is written
    in the text is the host's, and `vimram` uses tabs of eight columns.
11. `JoinLines` removes the blanks that begin each joined line and puts one
    space between the pieces, except where the line before ends in a blank
    or the next begins with `)`. With `spaces` false the lines are joined as
    they are.
12. The registers are in the state: `reg_text` and `reg_is_linewise` read
    them, and `Yank` is only the range, for highlighting.
13. `Modal.reset_pending` forgets the count, the operator, the prefix key
    such as the `g` of `gg`, the register choice and the keys of the command
    being typed, with no key. A host calls it when it ends a command itself:
    when its own key map takes the next key, or when a timeout abandons a
    prefix. The mode, the cursor, the registers and the dot record stay.

## What is not Vim

The package follows Vim's documentation and the source of its `search.c`,
`textobject.c`, `ops.c` and `normal.c`. These are the departures.

- **Blockwise Visual mode.** `Ctrl-V` is refused, because a block is a
  rectangle of screen columns and the package counts characters
  (`:help blockwise-visual`).
- **Columns.** A column is a codepoint index. A tab is one column and a wide
  character is one column. `j` and `k` keep the character column.
- **Lines that wrap.** Windows are lines that do not wrap, so `gj`, `gk`,
  `g0`, `g^` and `g$` are `j`, `k`, `0`, `^` and `$`, and scrolling counts
  text lines.
- **Character classes.** The keyword characters are those of the default
  `iskeyword`, with every codepoint above 255 a keyword character except
  general punctuation. Vim gives each script its own class, so `w` stops
  between a Chinese character and a letter that touch, and the package does
  not.
- **Brackets.** `%` pairs `()`, `[]` and `{}` and does not skip quotes,
  comments or `#if` lines (`:help %`). `i<` and `a<` pair angle brackets.
- **Paragraphs and sections.** A paragraph ends at an empty line. The macros
  of the `paragraphs` and `sections` options, and `[[`, `]]`, `[]`, `][`,
  `[(` and `]}`, are not implemented.
- **Text objects.** `it` and `at` (tags) are not implemented. In Visual
  mode a word, a paragraph and a block extend the selection when typed
  again; a quoted string and a sentence do not, and select from the cursor.
- **Registers.** `".`, `":`, `"%`, `"#`, `"/`, `"=`, `"*` and `"+` are not
  implemented, and neither are recording and playing with `q` and `@`.
- **Marks.** Only `a` to `z`, `'`, `` ` ``, `<` and `>` are kept. Deleting,
  putting and opening lines moves marks; joining lines and the edits of the
  host that the package did not ask for do not.
- **The dot repeat.** A change made in Visual mode is not recorded. Moving
  the cursor in Insert mode starts the recorded text again.
- **Insert mode.** There is no autoindent, text width, abbreviation,
  completion, digraph, `Ctrl-V`, `Ctrl-O`, `Ctrl-T` or `Ctrl-D`. `Ctrl-W`
  and `Ctrl-U` delete back to the start of a word and of the typed text.
- **Commands not implemented.** `Ctrl-A`, `Ctrl-X`, `Ctrl-O` and `Ctrl-I`
  for the jump list, `gp`, `gP`, `gi`, `gn`, `g;`, `&`, `K`, `ZZ`, `gq`,
  `=`, `!` and `g?`.
- **Options.** The options that change what a key does have the values the
  editor has by default: `startofline`, `nojoinspaces`, `wrapscan`, `cpo`
  as `aABceFs_`, `matchpairs` as `(:),{:},[:]`, `shiftwidth` as the host's.
  `Space`, `Backspace` and the arrow keys do not move across lines.
- **The search for `*` and `#`.** The jump mark is set at the start of the
  word, not at the cursor.
- **Scrolling.** `Ctrl-D` and `Ctrl-U` move half the window or the count,
  and `Ctrl-F` and `Ctrl-B` follow the paging rule of recent editors; the
  rule is `vimscroll.page_top`.

## Related packages

[keymap-nv](https://novo-lang.org/packages/keymap-nv) decodes the bytes a
terminal sends into the keystrokes this package reads.
[termios-nv](https://novo-lang.org/packages/termios-nv) puts the terminal in
raw mode and reads those keys. [tui-nv](https://novo-lang.org/packages/tui-nv)
draws a frame of cells. This package is the part between them that knows
what a key means to a modal editor.

## Tests

The suites in `tests/` run 17,000 vectors. Each vector is a text, a cursor
and keys, with the lines, the cursor, the mode, the Visual anchor, the first
line shown and the registers the keys must produce. The expected results were
produced by running the same keys in Neovim 0.12 with the options above, one
fresh editor for each vector: `tests/oracle/*.lua` lists the vectors and
`bash tests/oracle/regen.sh` writes the suites again. Other suites check the
rest of the surface, the cursor staying inside the text after any key of a
fixed random sequence, the `_mut` entry points against the plain ones, and
every line of `src/`: `bash tests/coverage.sh` measures 100 percent.
`bash tests/consumer_size.sh` builds two programs against the package and
checks that the one that does not name `vimram` has no code of it.

Build and test with `novo pkg build` and `novo test`.

## Licence

Apache-2.0.
