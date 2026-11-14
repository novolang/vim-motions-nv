-- Modes: Insert, Replace, Visual, the dot repeat, marks as operator targets,
-- and the other ways a command is built.

local cases = {}

local function add(name, text, at, keys, extra)
  local c = { name = name, text = text, at = at, keys = keys }
  if extra then
    for k, v in pairs(extra) do
      c[k] = v
    end
  end
  cases[#cases + 1] = c
end

local function sweep(label, text, positions, keys_list, suffix)
  for _, p in ipairs(positions) do
    for _, k in ipairs(keys_list) do
      add(string.format("%s %s from %d,%d", label, k, p[1], p[2]), text, p, k .. (suffix or ""))
    end
  end
end

local prose = { "hello world foo", "  bar.baz(qux) end", "", "last line here" }
local multi = { "one two", "three", "", "four five", "six" }
local wide = { "h\u{e9}llo w\u{f6}rld", "caf\u{e9}" }

-- Insert mode.
sweep("insert", prose, { { 0, 0 }, { 0, 7 }, { 0, 14 }, { 1, 0 }, { 1, 8 }, { 2, 0 }, { 3, 12 } },
  { "ix<Esc>", "ax<Esc>", "Ix<Esc>", "Ax<Esc>", "ox<Esc>", "Ox<Esc>", "gIx<Esc>", "3ix<Esc>", "3ax<Esc>", "3Ix<Esc>", "3Ax<Esc>", "3ox<Esc>", "3Ox<Esc>",
    "ixy<Esc>", "ixy<BS><Esc>", "ixy<BS><BS><BS><Esc>", "i<BS><Esc>", "ix<CR>y<Esc>", "ix<CR><BS>y<Esc>", "i<Esc>", "ia b<C-w>c<Esc>", "iab cd<C-u>x<Esc>", "ix<Left>y<Esc>", "ix<Right>y<Esc>", "ix<Up>y<Esc>", "ix<Down>y<Esc>", "ix<Home>y<Esc>", "ix<End>y<Esc>", "i<Del><Esc>", "ix<Del><Esc>", "ix<Esc>.", "ix<Esc>u", "Ax<Esc>.", "ox<Esc>.", "3ix<Esc>.", "2ox<Esc>3." })
sweep("insert registers", prose, { { 0, 0 }, { 0, 7 } }, { "ywi<C-r>\"<Esc>", "ywA <C-r>0<Esc>", "yyi<C-r>\"<Esc>", "dwi<C-r>-<Esc>", "\"ayw$a<C-r>a<Esc>" })
sweep("insert multi", multi, { { 0, 3 }, { 2, 0 }, { 4, 2 } }, { "ia<CR>b<CR>c<Esc>", "3ia<CR>b<Esc>", "Oa<CR>b<Esc>", "oa<CR>b<Esc>", "2oa<CR>b<Esc>", "ia<CR><CR><BS><BS><BS><Esc>" })
sweep("insert wide", wide, { { 0, 1 }, { 0, 7 }, { 1, 3 } }, { "i\u{4e2d}<Esc>", "a\u{4e2d}\u{6587}<Esc>", "A\u{e9}<Esc>", "I\u{e9}<Esc>", "ix<BS><BS><Esc>", "3i\u{e9}<Esc>" })
add("insert keeps the cursor on the last typed character", { "abc" }, { 0, 1 }, "ixyz<Esc>")
add("insert at the start", { "abc" }, { 0, 0 }, "ix<Esc>")
add("append on an empty line", { "" }, { 0, 0 }, "ax<Esc>")
add("tab is a tab", { "abc" }, { 0, 1 }, "i<Tab><Esc>")
add("insert and move and type", { "abc def" }, { 0, 0 }, "ix<Right><Right>y<Esc>")
add("insert and move and dot", { "abc def" }, { 0, 0 }, "ix<Right>y<Esc>.")
add("backspace at the start of a line", { "ab", "cd" }, { 1, 0 }, "i<BS>x<Esc>")
add("backspace at the start of the text", { "ab" }, { 0, 0 }, "i<BS>x<Esc>")
add("control w across blanks", { "abc def  " }, { 0, 8 }, "A<C-w>x<Esc>")
add("control w at the start of a line", { "ab", "cd" }, { 1, 0 }, "i<C-w>x<Esc>")
add("control w over punctuation", { "ab.cd" }, { 0, 4 }, "A<C-w>x<Esc>")
add("control u over typed text", { "ab" }, { 0, 1 }, "Axyz<C-u>q<Esc>")
add("control u over old text", { "abcd" }, { 0, 2 }, "i<C-u>q<Esc>")
add("replace register does not exist in insert", { "ab" }, { 0, 0 }, "i<C-r>z<Esc>")

-- Replace mode.
sweep("replace mode", prose, { { 0, 0 }, { 0, 12 }, { 0, 14 }, { 2, 0 }, { 3, 10 } },
  { "Rxy<Esc>", "Rxyz<Esc>", "Rxyzxyzxyzxyzxyz<Esc>", "Rx<BS><Esc>", "Rxy<BS><Esc>", "Rxy<BS><BS><Esc>", "Rxy<BS><BS><BS><Esc>", "Rx<CR>y<Esc>", "R<Esc>", "3Rab<Esc>", "Rab<Esc>.", "Rab<Esc>l." })
add("replace past the end then backspace", { "ab" }, { 0, 1 }, "Rxyz<BS><BS><Esc>")
add("replace wide", wide, { 0, 0 }, "R\u{4e2d}\u{6587}<Esc>")
add("replace over wide", wide, { 0, 0 }, "Rab<BS><Esc>")

-- Visual mode: selecting and moving.
sweep("visual", prose, { { 0, 3 }, { 1, 8 }, { 2, 0 }, { 3, 12 } },
  { "v", "V", "vl", "vh", "vj", "vk", "v$", "v0", "vw", "ve", "vb", "vjj", "vkk", "vG", "vgg", "vf ", "vt ", "v}", "v{", "v%", "vlo", "vljo", "vljoO", "vlv", "vV", "Vv", "vl<Esc>", "Vj<Esc>", "v3l", "vjjj$", "v$j", "v$h", "v$jj", "vlllljj" })
sweep("visual again", prose, { { 0, 3 }, { 1, 8 } }, { "vl<Esc>gv", "vjj<Esc>gv", "Vj<Esc>gvd", "vl<Esc>jgv<Esc>" })

-- Visual mode: operators.
sweep("visual operator", prose, { { 0, 3 }, { 0, 12 }, { 1, 8 }, { 2, 0 }, { 3, 12 } },
  { "vld", "vlx", "vlX", "vlD", "vly", "vlY","vlcX<Esc>", "vlCX<Esc>", "vlsX<Esc>", "vlSX<Esc>", "vlRX<Esc>", "vl>", "vl<", "vl3>", "vlu", "vlU", "vl~", "vlJ", "vljJ", "vlgJ", "vljjgJ", "vlr-", "vljr-", "vlrx", "vl$d", "v$d", "v$y$p", "vjd", "vjy", "vjdp",
    "Vd", "Vx", "VD", "Vy", "VY","VcX<Esc>", "VCX<Esc>", "VsX<Esc>", "V>", "V<", "V3>", "Vu", "VU", "V~", "VJ", "VgJ", "Vr-", "Vjd", "Vjy","VjcX<Esc>", "Vj>", "Vj<","Vjgu", "VjgU", "Vjg~", "vlgu", "vlgU", "vlg~", "vlgJ" })
sweep("visual put", prose, { { 0, 3 }, { 1, 8 }, { 3, 12 } },
  { "\"aywwvl\"ap", "\"aywwvl\"aP", "ywwvl\"0p", "ywwvl\"0P", "ywwvlp", "ywwvlP", "ywwvlpp","yyjvlp", "yyjvlP", "ywjVp", "yyjVp", "yyjVP", "ywwvjp", "yyjvjp", "yw$vp", "yyVp", "ywvlp\"0p", "ywvlP\"0p", "ywvlpu", "dwvlp", "Vjyjp" })
sweep("visual objects", prose, { { 0, 3 }, { 1, 8 } }, { "viwd", "vawd", "viwy","viwcX<Esc>", "vi(d", "va(d", "vipd", "vapd", "vi\"d", "viwiwd", "viwawd" })
sweep("visual count and register", prose, { { 0, 3 } }, { "\"avly\"ap", "vl\"ay\"ap", "v\"alyP", "vl\"ayy\"ap", "v2ld" })
add("visual join of three", { "a", "b", "c", "d" }, { 0, 0 }, "VjjJ")
add("visual join of one", { "a", "b", "c" }, { 0, 0 }, "VJ")
add("visual replace with a line break", { "abc" }, { 0, 0 }, "vlr<CR>")
add("visual replace over lines", { "ab", "cd", "ef" }, { 0, 1 }, "vjjrx")
add("visual on an empty line deletes the break", { "a", "", "b" }, { 1, 0 }, "vd")
add("visual on the last empty line", { "a", "" }, { 1, 0 }, "vd")
add("visual line on one line then delete it all", { "a" }, { 0, 0 }, "Vd")
add("visual over the end of the text", { "ab", "cd" }, { 1, 0 }, "vjd")
add("visual dollar then j", { "ab cd", "e", "fgh" }, { 0, 1 }, "v$jd")
add("visual dollar then y", { "ab cd", "e" }, { 0, 1 }, "v$y")
add("visual dollar then change", { "ab cd", "e" }, { 0, 1 }, "v$cX<Esc>")
add("visual shift count", { "a", "b" }, { 0, 0 }, "Vj3>")
add("visual shift back", { "\t\ta", "\t\tb" }, { 0, 0 }, "Vj<")
add("visual then colon starts a command line with a range", { "a", "b" }, { 0, 0 }, "Vj:<Esc>")

-- The dot repeat.
sweep("dot", prose, { { 0, 0 }, { 0, 6 }, { 1, 2 }, { 3, 5 } },
  { "x.", "x..", "3x.", "x3.", "2x3.", "dw.", "dw..", "d2w.", "2dw.", "d2w3.", "2d3w.", "dd.", "ddj.", "2dd.", "dd3.", "D.", "dj.","d$.", "dfo.", "dtl.", "df.;.",
    "cwX<Esc>.", "cwX<Esc>w.", "ciwX<Esc>w.", "3cwX<Esc>.", "cw<Esc>.", "ccX<Esc>j.", "SX<Esc>j.", "CX<Esc>j.", "sX<Esc>.", "3sX<Esc>.",
    "A!<Esc>j.", "I-<Esc>j.", "a-<Esc>.", "o-<Esc>.", "O-<Esc>.", "i-<Esc>.", "gI-<Esc>j.", "3A-<Esc>j.", "A-<Esc>j2.", "o-<Esc>j.",
    "rx.", "rxl.", "3rx.", "rxl3.", "~.", "3~.", ">>.", ">>j.", "<<.", ">>3.", ">j.", "J.", "J..", "3J.", "gJ.", "xp.", "xP.", "yyp.", "yyP.", "yyp3.", "ywp.", "ywP.", "p.", "gUiw.", "gUiww.", "guu.", "g~~j.", "gUU2.", "g~w.", "g~wl.", "gUj.",
    "diw.", "daw.", "diwb.", "dap.", "dip.", "di(.", "ci(X<Esc>.", "xyiw.", "xyy.", "dwu.", "ddu.", "xu.", "Rab<Esc>.", "Rab<Esc>j0.",
    "\"add.", "\"adw.", "\"adwj.", "x\"ayw.","\"Adw.", "\"_dw.", "\"adw\"bdw.", "dw\"_.", "\"add\"ap.", "\"ap.", "\"ap\"bp.", "\"Ayy\"ap." })
add("dot with nothing recorded", { "abc" }, { 0, 0 }, ".")
add("dot after a motion only", { "abc def" }, { 0, 0 }, "w.")
add("dot after a visual operator", { "abc def" }, { 0, 0 }, "x.")
add("dot count replaces the recorded count", { "abcdefghij" }, { 0, 0 }, "2x.3.")
add("dot count is remembered", { "abcdefghij" }, { 0, 0 }, "2x3..")
add("dot of an insert with a newline", { "ab", "cd" }, { 0, 0 }, "ix<CR>y<Esc>j.")
add("dot of an insert with backspace", { "abcd" }, { 0, 0 }, "ixy<BS>z<Esc>l.")
add("dot of an insert after a move", { "abcd" }, { 0, 0 }, "ixy<Left>z<Esc>l.")
add("dot of o with a count", { "a", "b" }, { 0, 0 }, "2ox<Esc>j.")
add("dot of a put with a count", { "ab" }, { 0, 0 }, "ylp3.")
add("dot keeps the register of the change", { "ab", "cd" }, { 0, 0 }, "\"add\"_.")

-- Marks as targets.
sweep("mark target", prose, { { 0, 3 }, { 1, 8 }, { 3, 5 } },
  { "majjd'a", "majjd`a", "majjy'aP", "majjy`aP", "majj>'a", "majj<'a", "majjgU'a", "majjgU`a", "majjc'aX<Esc>", "majjc`aX<Esc>", "jmakd'a", "jmakd`a", "mbggd'b", "mbggd`b", "majj'aD", "majjd'a.", "majjd`a.", "majjd'z", "d''", "Gd''", "jmaGd'a", "jmaggd`a" })

-- The other ways to build a command.
sweep("count and register", prose, { { 0, 0 }, { 1, 4 } },
  { "2\"adw", "\"a2dw", "\"a2d2w", "3\"a2dw", "\"adwdw\"ap", "d\"aw" })
sweep("pending keys", prose, { { 0, 3 } }, { "d<Esc>x", "2<Esc>x", "\"<Esc>x", "g<Esc>x", "dg<Esc>x", "df<Esc>x", "d2<Esc>x", "dt<Esc>", "r<Esc>x", "m<Esc>x", "d'<Esc>x", "dd<Esc>", "<Esc>", "<Esc><Esc>x", "dx", "dzx", "ggdG" })
sweep("blank counts", prose, { { 0, 3 } }, { "0", "10l", "100l", "1000l", "01l", "d0", "2d0", "d02w", "20l0", "20l00" })
add("a bare zero is a motion after d", { "abcdef" }, { 0, 3 }, "d0")
add("a counted zero is part of the count", { "abcdefghijklmnop" }, { 0, 0 }, "10l")
add("unmapped key", { "abc" }, { 0, 0 }, "Z")
add("unmapped key after a count", { "abc" }, { 0, 0 }, "3Z")
add("q is refused", { "abc" }, { 0, 0 }, "qa")

return cases
