-- Operators: delete, change, yank, shift and the case operators over
-- motions, doubled forms, counts, and the single-key edits.

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
local code = { "if (a[1] == {x}) {", "    call(b, c);", "}", "tail" }
local multi = { "one two", "three", "", "", "four five", "six" }
local wide = { "h\u{e9}llo w\u{f6}rld", "caf\u{e9} na\u{ef}ve" }

local motions = {
  "w", "W", "e", "E", "b", "B", "ge", "gE", "$", "0", "^", "g_", "h", "l", "j", "k", "gg", "G",
  "}", "{", "fo", "to", "Fo", "To", "fo;", "%", "2w", "3e", "2b", "3l", "2j", "2k", "2fo", "3h", "9w", "9b", "9l", "9j", "2G", "3|", "-", "+", "_", "2_", "2$", "dw",
}
local few = { "w", "W", "e", "b", "$", "0", "^", "h", "l", "j", "k", "G", "gg", "}", "{", "fo", "to", "2w", "3l", "2j", "%", "ge" }

-- Delete.
sweep("delete", prose, { { 0, 0 }, { 0, 7 }, { 0, 14 }, { 1, 0 }, { 1, 8 }, { 2, 0 }, { 3, 5 } }, (function()
  local l = {}
  for _, m in ipairs(motions) do
    l[#l + 1] = "d" .. m
  end
  return l
end)())
sweep("delete code", code, { { 0, 3 }, { 0, 6 }, { 0, 17 }, { 1, 4 }, { 1, 9 }, { 2, 0 }, { 3, 2 } }, (function()
  local l = {}
  for _, m in ipairs(few) do
    l[#l + 1] = "d" .. m
  end
  return l
end)())
sweep("delete multi", multi, { { 0, 4 }, { 1, 2 }, { 2, 0 }, { 3, 0 }, { 4, 3 }, { 5, 0 } }, (function()
  local l = {}
  for _, m in ipairs(few) do
    l[#l + 1] = "d" .. m
  end
  return l
end)())
sweep("delete wide", wide, { { 0, 1 }, { 0, 7 }, { 1, 3 } }, { "dw", "de", "db", "dl", "dh", "d$", "d0", "dfl", "dtl", "dd", "x", "X" })

-- Change.
sweep("change", prose, { { 0, 0 }, { 0, 3 }, { 0, 6 }, { 0, 14 }, { 1, 0 }, { 1, 8 }, { 2, 0 }, { 3, 5 } }, (function()
  local l = {}
  for _, m in ipairs({ "w", "W", "e", "E", "b", "B", "$", "0", "^", "h", "l", "j", "k", "G", "gg", "}", "fo", "to", "2w", "3l", "2j", "ge", "iw", "aw" }) do
    l[#l + 1] = "c" .. m
  end
  return l
end)(), "X<Esc>")
sweep("change multi", multi, { { 0, 4 }, { 1, 2 }, { 2, 0 }, { 3, 0 }, { 4, 3 } }, (function()
  local l = {}
  for _, m in ipairs({ "w", "W", "e", "$", "j", "k", "}", "{", "2w", "cc" }) do
    l[#l + 1] = "c" .. m
  end
  return l
end)(), "X<Esc>")

-- Yank, followed by a put so that the text shows what was copied.
sweep("yank", prose, { { 0, 0 }, { 0, 7 }, { 0, 14 }, { 1, 8 }, { 2, 0 }, { 3, 5 } }, (function()
  local l = {}
  for _, m in ipairs(few) do
    l[#l + 1] = "y" .. m
  end
  return l
end)())
sweep("yank and put", prose, { { 0, 3 }, { 1, 8 } }, (function()
  local l = {}
  for _, m in ipairs({ "w", "e", "$", "j", "k", "fo", "2w", "yy" }) do
    l[#l + 1] = "y" .. m .. "P"
  end
  for _, m in ipairs({ "w", "e", "$", "j", "k", "fo", "2w", "yy" }) do
    l[#l + 1] = "y" .. m .. "p"
  end
  return l
end)())

-- Shift and case.
sweep("shift", code, { { 0, 3 }, { 1, 9 }, { 2, 0 }, { 3, 2 } }, { ">>", "<<", "3>>", "2<<", ">j", "<j", ">k", ">G", ">gg", ">}", ">>>>", "<<<<", ">>.", ">>..", "<<." })
sweep("shift tabs", { "\tone", "  two", "        three", "   \t four", "", "five" }, { { 0, 1 }, { 1, 0 }, { 2, 3 }, { 3, 4 }, { 4, 0 } }, { ">>", "<<", "5>>", "5<<", ">j", "<j" })
sweep("case", prose, { { 0, 1 }, { 0, 7 }, { 1, 8 }, { 3, 5 } }, (function()
  local l = {}
  for _, op in ipairs({ "gu", "gU", "g~" }) do
    for _, m in ipairs({ "w", "e", "$", "0", "j", "k", "l", "fo", "2w", "b", "G", "}" }) do
      l[#l + 1] = op .. m
    end
  end
  return l
end)())
sweep("case lines", { "Hello World", "mIxEd CaSe", "", "done" }, { { 0, 3 }, { 1, 5 }, { 2, 0 } }, { "guu", "gUU", "g~~", "gugu", "gUgU", "g~g~", "2guu", "2gUU", "2g~~", "gUj", "g~j", "9gUU", "~", "3~", "9~", "g~w..", "gUw.." })
add("case wide", { "caf\u{e9} \u{f6}ffnung" }, { 0, 0 }, "gUU")
add("case wide lower", { "CAF\u{c9} \u{d6}FFNUNG" }, { 0, 0 }, "guu")
add("tilde wide", { "caf\u{e9}" }, { 0, 0 }, "4~")

-- Doubled operators and counts.
sweep("lines", multi, { { 0, 2 }, { 2, 0 }, { 4, 3 }, { 5, 0 } },
  { "dd", "2dd", "d2d", "2d2d", "99dd", "d99d", "yy", "3yy", "yyp", "yyP", "3yyp", "ddp", "ddP", "dd.", "2dd.", "yyjp", ">>", "3>>" }, "")
sweep("lines change", multi, { { 0, 2 }, { 2, 0 }, { 4, 3 } }, { "cc", "2cc", "S", "3S", "cj", "ck", "c2j" }, "X<Esc>")
sweep("last line", { "a", "b", "c" }, { { 2, 0 }, { 0, 0 } }, { "dd", "2dd", "dj", "dk", "d2j", "d2k", "yj", "yk", "dG", "dgg", "ddp", "ddP", "ddk", "Ydd" })
add("delete the only line", { "only" }, { 0, 2 }, "dd")
add("delete every line", { "a", "b" }, { 0, 0 }, "2dd")
add("delete every line then put", { "a", "b" }, { 0, 0 }, "2ddp")
add("delete the only empty line", { "" }, { 0, 0 }, "dd")

-- Single-key edits.
sweep("edit", prose, { { 0, 0 }, { 0, 7 }, { 0, 14 }, { 1, 0 }, { 1, 8 }, { 2, 0 }, { 3, 5 }, { 3, 12 } },
  { "x", "X", "3x", "3X", "99x", "99X", "D", "2D", "99D", "xp", "Xp", "xP", "J", "gJ", "2J", "3J", "9J", "J.", "gJ.", "~", "5~", "rx", "3rx", "99rx", "r<CR>", "2r<CR>", "r<Esc>", "Y", "YP", "Yp", "xu", "x.", "x..", "3x." })
sweep("edit change", prose, { { 0, 0 }, { 0, 7 }, { 1, 8 }, { 2, 0 }, { 3, 5 } }, { "C", "2C", "s", "3s", "S", "99s" }, "X<Esc>")
sweep("join", { "a", "  b", "c  ", " d", ")e", "", "f", "\tg" }, { { 0, 0 }, { 2, 0 }, { 5, 0 }, { 6, 0 } },
  { "J", "2J", "3J", "4J", "99J", "gJ", "3gJ", "J.", "JJ", "JJJ", "J3J" })
sweep("join tab", { "a\t", "b ", "c" }, { { 0, 0 }, { 1, 0 } }, { "J", "2J", "3J", "gJ" })
add("join an empty line", { "", "b" }, { 0, 0 }, "J")
add("join onto an empty line", { "a", "", "b" }, { 0, 0 }, "3J")
add("join blank lines", { "a", "   ", "b" }, { 0, 0 }, "3J")
add("replace past the end", { "abc" }, { 0, 1 }, "5rx")
add("replace with a line break", { "abc def" }, { 0, 3 }, "r<CR>")
add("replace counted with a line break", { "abc def" }, { 0, 1 }, "3r<CR>")
add("replace on an empty line", { "" }, { 0, 0 }, "rx")
add("x on an empty line", { "", "a" }, { 0, 0 }, "x")
add("x at the end of a line", { "abc" }, { 0, 2 }, "x")
add("x twice at the end of a line", { "abc" }, { 0, 2 }, "xx")
add("X at the start of a line", { "abc" }, { 0, 0 }, "X")
add("D on the last char", { "abc" }, { 0, 2 }, "D")
add("D then p", { "abc def" }, { 0, 3 }, "Dp")

-- Registers.
sweep("register", prose, { { 0, 0 }, { 0, 7 } }, { "\"ayw", "\"ayy", "\"adw", "\"add", "\"ayw\"bywP", "\"ayw\"Aywp", "\"ayy\"Ayyp", "\"ayw\"Ayyp", "\"ayy\"Aywp", "\"_dwP", "\"_ddp", "ywdw\"0P", "ywdwP", "dwdw\"1P", "dwdw\"-P", "dddd\"1p", "dddd\"2p","\"ayw\"ap", "\"adw\"aP", "yy\"0p", "yw\"\"p", "\"1yw\"1p", "5\"ayl\"ap", "\"Ayw\"ap", "dwu\"-p", "d$\"-p", "d$p" })
sweep("register delete shifts", { "1", "2", "3", "4", "5", "6" }, { { 0, 0 } }, { "dddddd\"1p\"2p\"3p", "dddddd\"1p\"2P", "dddddddddddd\"3p","dd\"1p", "ddjdd\"1p\"2p" })
add("big delete goes to register one", { "a (b c) d", "e" }, { 0, 2 }, "d%\"1p")
add("small delete to the minus register", { "ab cd" }, { 0, 0 }, "dw\"-P")
add("delete with a motion that is big", { "a b", "c d", "", "e" }, { 0, 2 }, "d}\"1P")
add("put empty register", { "a" }, { 0, 0 }, "p")
add("put named empty register", { "a" }, { 0, 0 }, "\"zp")
add("put a count of times", { "ab" }, { 0, 0 }, "yl3p")
add("put a count of lines", { "ab", "cd" }, { 0, 0 }, "yy3p")
add("put lines before", { "ab", "cd" }, { 1, 1 }, "yyP")
add("put a word after the end of a line", { "ab", "cd" }, { 0, 1 }, "yw$p")
add("put on an empty line", { "", "cd" }, { 0, 0 }, "jywkp")
add("put a multiline yank", { "ab cd", "ef gh" }, { 0, 3 }, "yjP")
add("put charwise across lines", { "ab cd", "ef gh" }, { 0, 3 }, "y/ef<CR>$p")
add("put charwise across lines before", { "ab cd", "ef gh" }, { 0, 3 }, "y/ef<CR>$P")

return cases
