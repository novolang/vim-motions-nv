-- Motions: where the cursor goes.  Every case is run in the editor to get
-- the expected cursor.

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

local function sweep(label, text, positions, keys_list)
  for _, p in ipairs(positions) do
    for _, k in ipairs(keys_list) do
      add(string.format("%s %s from %d,%d", label, k, p[1], p[2]), text, p, k)
    end
  end
end

local prose = { "hello world foo", "  bar.baz(qux) end", "", "last line here" }
local code = { "if (a[1] == {x}) {", "    call(b, c);", "}", "tail" }
local multi = { "one two", "three", "", "", "four five", "six" }
local wide = { "h\u{e9}llo w\u{f6}rld", "caf\u{e9} na\u{ef}ve", "\u{65e5}\u{672c}\u{8a9e} text x" }
local tabs = { "\tindented line", "  \tmixed indent", "plain", "trailing   " }

-- Left, right, up and down.
sweep("hjkl", prose, { { 0, 0 }, { 0, 7 }, { 1, 4 }, { 2, 0 }, { 3, 12 } },
  { "h", "l", "j", "k", "3h", "3l", "2j", "2k", "9l", "9h", "9j", "9k" })
sweep("column memory", prose, { { 0, 10 }, { 1, 12 } }, { "jj", "jjk", "$j", "$jj", "$kj", "5ljj", "3l2j2k" })

-- Within a line.
sweep("line", prose, { { 0, 6 }, { 1, 5 }, { 2, 0 }, { 3, 4 } },
  { "0", "^", "$", "g_", "|", "5|", "99|", "2$", "3$", "2g_", "$h", "$0", "$^", "3|l" })
sweep("line tabs", tabs, { { 0, 3 }, { 1, 5 }, { 3, 2 } }, { "0", "^", "$", "g_", "|", "w", "b", "e" })

-- Words.
sweep("word", prose, { { 0, 0 }, { 0, 3 }, { 0, 11 }, { 1, 0 }, { 1, 8 }, { 1, 16 }, { 2, 0 }, { 3, 5 }, { 3, 13 } },
  { "w", "W", "e", "E", "b", "B", "ge", "gE", "2w", "3W", "2e", "3E", "2b", "3B", "2ge", "3gE", "9w", "9e", "9b", "9ge" })
sweep("word code", code, { { 0, 0 }, { 0, 4 }, { 0, 10 }, { 1, 4 }, { 1, 9 }, { 2, 0 }, { 3, 3 } },
  { "w", "W", "e", "E", "b", "B", "ge", "gE", "2w", "2W", "3e" })
sweep("word multi", multi, { { 0, 6 }, { 1, 4 }, { 2, 0 }, { 3, 0 }, { 4, 8 }, { 5, 0 } },
  { "w", "W", "e", "E", "b", "B", "ge", "gE", "2w", "3b", "2ge" })
sweep("word wide", wide, { { 0, 0 }, { 0, 7 }, { 1, 5 }, { 2, 0 } }, { "w", "e", "b", "$", "l", "3l", "fl", "tl" })

-- Whole text.
sweep("text", prose, { { 0, 5 }, { 2, 0 }, { 3, 9 } },
  { "gg", "G", "2G", "3gg", "99G", "99gg", "ggG", "Ggg", "G$", "gg$", "2Gl" })
sweep("text indent", code, { { 0, 5 }, { 1, 9 } }, { "gg", "G", "2G", "+", "-", "_", "2_", "2+", "2-", "<CR>" })

-- Finding a character.
sweep("find", prose, { { 0, 0 }, { 0, 7 }, { 1, 0 } },
  { "fo", "to", "Fo", "To", "2fo", "2to", "fo;", "fo;;", "fo,", "to;", "to;;", "to,", "Fo;", "To;", "To,", "fz", "tz", "Fz", "Tz", "fo3;", "2to;", "fo2," })
sweep("find line end", prose, { { 0, 13 }, { 0, 14 } }, { "fo", "Fo", "fo;", "to", "To", "2Fo" })

-- Matching brackets.
sweep("percent", code, { { 0, 3 }, { 0, 0 }, { 0, 6 }, { 0, 10 }, { 0, 15 }, { 0, 17 }, { 1, 8 }, { 1, 4 }, { 2, 0 }, { 3, 0 } },
  { "%", "%%" })
sweep("percent then l", code, { { 0, 3 }, { 0, 6 }, { 0, 17 }, { 2, 0 } }, { "%l%" })
add("percent with a count", { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" }, { 0, 0 }, "50%")
add("percent with a count past the end", { "a", "b", "c" }, { 0, 0 }, "101%")
add("percent nested", { "((a)(b))" }, { 0, 1 }, "%")
add("percent nested outer", { "((a)(b))" }, { 0, 0 }, "%")
add("percent over lines", { "{", "  a", "  {", "  }", "}" }, { 0, 0 }, "%")
add("percent back over lines", { "{", "  a", "  {", "  }", "}" }, { 4, 0 }, "%")
add("percent unmatched", { "(abc" }, { 0, 0 }, "%")

-- Paragraphs.
sweep("paragraph", multi, { { 0, 3 }, { 1, 2 }, { 2, 0 }, { 3, 0 }, { 4, 3 }, { 5, 1 } },
  { "}", "{", "2}", "2{", "3}", "9}", "9{", "}}", "{{" })
sweep("paragraph prose", prose, { { 0, 3 }, { 3, 5 } }, { "}", "{", "}}" })

-- The window.
local tall = {}
for i = 1, 60 do
  tall[#tall + 1] = "  line " .. i
end
sweep("window", tall, { { 5, 3 }, { 20, 0 } }, { "H", "M", "L", "3H", "3L", "H$", "L$" })
add("window from a scrolled top", tall, { 12, 2 }, "H", { top = 10 })
add("window middle of a scrolled top", tall, { 12, 2 }, "M", { top = 10 })
add("window bottom of a scrolled top", tall, { 12, 2 }, "L", { top = 10 })
add("window bottom of a short text", { "a", "b", "c" }, { 0, 0 }, "L")
add("window middle of a short text", { "a", "b", "c", "d" }, { 0, 0 }, "M")
add("window count past the top", tall, { 12, 2 }, "30H", { top = 10 })
add("window count past the bottom", tall, { 12, 2 }, "30L", { top = 10 })

-- Marks.
add("mark and back", prose, { 0, 6 }, "majjg_'a")
add("mark and back by backquote", prose, { 0, 6 }, "majj`a")
add("mark of another letter", prose, { 1, 3 }, "mzgg`z")
add("mark not set", prose, { 1, 3 }, "'q")
add("jump back to the previous place", prose, { 1, 3 }, "Gx``")
add("jump back twice", prose, { 1, 3 }, "G''''")
add("jump back after gg", prose, { 3, 5 }, "gg''")
add("mark line goes to first nonblank", prose, { 1, 8 }, "mbgg'b")

-- Keys other than letters.
add("arrow left", prose, { 0, 4 }, "<Left>")
add("arrow right", prose, { 0, 4 }, "<Right>")
add("arrow down", prose, { 0, 4 }, "<Down>")
add("arrow up", prose, { 1, 4 }, "<Up>")
add("home", prose, { 0, 4 }, "<Home>")
add("end", prose, { 0, 4 }, "<End>")
add("enter", prose, { 0, 4 }, "<CR>")
add("space does not wrap in the package", prose, { 0, 4 }, "3<Space>")
add("control n", prose, { 0, 4 }, "<C-n>")
add("control p", prose, { 1, 4 }, "<C-p>")
add("control j", prose, { 0, 4 }, "<C-j>")

-- Search motions with a fixed text.
local doc = { "the cat sat", "on the mat", "the end" }
add("search forward", doc, { 0, 0 }, "/the<CR>")
add("search forward twice", doc, { 0, 0 }, "/the<CR>n")
add("search backward", doc, { 2, 5 }, "?the<CR>")
add("search backward then n", doc, { 2, 5 }, "?the<CR>n")
add("search backward then N", doc, { 2, 5 }, "?the<CR>N")
add("search forward then N", doc, { 0, 0 }, "/at<CR>N")
add("search wraps", doc, { 2, 5 }, "/cat<CR>")
add("search with a count", doc, { 0, 0 }, "2/the<CR>")
add("search not found", doc, { 0, 0 }, "/zzz<CR>")
add("star", doc, { 0, 1 }, "*")
add("star twice", doc, { 0, 1 }, "**")
add("hash", doc, { 2, 1 }, "#")
add("star on a non-word", { "  --  the" }, { 0, 0 }, "*")
add("star count", doc, { 0, 1 }, "2*")

return cases
