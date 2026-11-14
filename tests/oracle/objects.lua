-- Text objects: a word, a paragraph, a block and a quoted string, taken by
-- an operator or selected in Visual mode.

local cases = {}

local function add(name, text, at, keys)
  cases[#cases + 1] = { name = name, text = text, at = at, keys = keys }
end

local function sweep(label, text, positions, keys_list, suffix)
  for _, p in ipairs(positions) do
    for _, k in ipairs(keys_list) do
      add(string.format("%s %s from %d,%d", label, k, p[1], p[2]), text, p, k .. (suffix or ""))
    end
  end
end

local function ops(objs, with)
  local l = {}
  for _, o in ipairs(objs) do
    for _, op in ipairs(with or { "d", "y", "gU" }) do
      l[#l + 1] = op .. o
    end
  end
  return l
end

local prose = { "hello world foo", "  bar.baz(qux)   end", "", "last line here", "x  y" }

-- Words.
sweep("word", prose, { { 0, 0 }, { 0, 3 }, { 0, 5 }, { 0, 6 }, { 0, 14 }, { 1, 0 }, { 1, 1 }, { 1, 2 }, { 1, 6 }, { 1, 12 }, { 1, 14 }, { 1, 17 }, { 2, 0 }, { 3, 12 }, { 4, 1 }, { 4, 2 } },
  ops({ "iw", "aw", "iW", "aW", "2iw", "2aw", "3iw", "3aw", "2iW", "2aW" }))
sweep("word change", prose, { { 0, 3 }, { 0, 5 }, { 1, 0 }, { 1, 6 }, { 3, 12 } }, { "ciw", "caw", "ciW", "caW", "c2aw" }, "X<Esc>")
sweep("word select", prose, { { 0, 3 }, { 0, 5 }, { 1, 6 }, { 3, 12 } }, { "viw", "vaw", "viW", "vaW", "v2iw", "v2aw", "viwiw", "vawaw", "viwiwiw", "viwo", "viwh", "vawl" })

-- Paragraphs.
local paras = { "a", "b", "", "", "c", "", "d", "e", "f", "", "g" }
sweep("paragraph", paras, { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 }, { 7, 0 }, { 9, 0 }, { 10, 0 } },
  ops({ "ip", "ap", "2ip", "2ap", "3ip", "3ap" }))
sweep("paragraph select", paras, { { 0, 0 }, { 3, 0 }, { 7, 0 }, { 10, 0 } }, { "vip", "vap", "v2ip", "v2ap", "vipip", "vapap" })
sweep("paragraph change", paras, { { 0, 0 }, { 4, 0 }, { 7, 0 } }, { "cip", "cap" }, "X<Esc>")

-- Blocks.
local code = { "if (a[1] == {x}) {", "    call(b, (c, d));", "    if (e) { f }", "}", "tail" }
sweep("block", code, { { 0, 4 }, { 0, 5 }, { 0, 7 }, { 0, 10 }, { 0, 11 }, { 0, 12 }, { 0, 16 }, { 1, 9 }, { 1, 12 }, { 1, 16 }, { 2, 8 }, { 2, 14 }, { 3, 0 }, { 4, 1 } },
  ops({ "i(", "a(", "ib", "ab", "i)", "a)", "i[", "a[", "i]", "a]", "i{", "a{", "iB", "aB", "i}", "a}", "i<", "a<", "2i(", "2a(", "2i{", "2a{" }))
sweep("block change", code, { { 0, 5 }, { 0, 11 }, { 1, 12 }, { 2, 14 } }, { "ci(", "ca(", "ci{", "ca{", "ci[", "cib" }, "X<Esc>")
sweep("block select", code, { { 0, 5 }, { 1, 12 }, { 2, 14 } }, { "vi(", "va(", "vi{", "va{", "vi(i(", "va(a(", "vib" })
add("block on separate lines", { "f(", "  a,", "  b", ")" }, { 1, 3 }, "di(")
add("block on separate lines around", { "f(", "  a,", "  b", ")" }, { 1, 3 }, "da(")
add("block empty", { "f()" }, { 0, 1 }, "di(")
add("block empty change", { "f()" }, { 0, 1 }, "ci(X<Esc>")
add("block empty around", { "f()" }, { 0, 1 }, "da(")
add("block across lines yank", { "{", "  x", "}" }, { 1, 2 }, "yi{P")
add("block with a close brace on its own line", { "{", "  x", "  }" }, { 1, 2 }, "di{")
add("block no block", { "plain text" }, { 0, 3 }, "di(")
add("block angle", { "a <b c> d" }, { 0, 4 }, "di<")
add("block angle around", { "a <b c> d" }, { 0, 4 }, "da<")

-- Quotes.
local quotes = { "say \"hi there\" now", "a 'b c' d `e f` g", "x = \"a\\\"b\" + \"c\"", "no quotes here", "\"lead\" mid \"trail\"" }
sweep("quote", quotes, { { 0, 0 }, { 0, 4 }, { 0, 5 }, { 0, 8 }, { 0, 14 }, { 0, 16 }, { 1, 0 }, { 1, 3 }, { 1, 4 }, { 1, 12 }, { 2, 6 }, { 2, 9 }, { 2, 14 }, { 3, 4 }, { 4, 1 }, { 4, 8 }, { 4, 15 } },
  ops({ "i\"", "a\"", "i'", "a'", "i`", "a`", "2i\"" }))
sweep("quote change", quotes, { { 0, 6 }, { 1, 3 }, { 2, 14 }, { 4, 8 } }, { "ci\"", "ca\"", "ci'", "ci`" }, "X<Esc>")
sweep("quote select", quotes, { { 0, 6 }, { 2, 14 } }, { "vi\"", "va\"" })

-- Objects that are not found.
add("object not found", { "abc" }, { 0, 1 }, "d2ap")
add("object bad kind", { "abc" }, { 0, 1 }, "diz")

return cases
