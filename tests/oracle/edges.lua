-- Edges: the motions and operators on tiny texts, where the cursor starts
-- on the first line, the last line, an empty line or the last character.

local cases = {}

local function add(name, text, at, keys)
  cases[#cases + 1] = { name = name, text = text, at = at, keys = keys }
end

local texts = {
  { "x" },
  { "" },
  { "   " },
  { "a b" },
  { "", "" },
  { "a", "" },
  { "", "a" },
  { "  a  ", "  b  " },
  { "a.b c" },
  { "a", "", "b" },
  { "ab", "  ", "cd" },
}

local keys = {
  "w", "W", "e", "E", "b", "B", "ge", "gE", "5w", "5e", "5b", "5ge",
  "dw", "dW", "de", "dE", "db", "dB", "dge", "d5w", "d5e", "d5b",
  "yw", "ye", "yb", "cwX<Esc>", "ceX<Esc>", "cWX<Esc>",
  "}", "{", "d}", "d{", "y}", "5}", "5{", ")", "(", "d)", "d(",
  "x", "X", "D", "J", "dd", "yy", "p", "P", "~", "rx",
}

for ti, t in ipairs(texts) do
  for l = 0, #t - 1 do
    local n = vim.fn.strchars(t[l + 1])
    for c = 0, math.max(n - 1, 0) do
      for _, k in ipairs(keys) do
        add(string.format("edge %s text %d at %d,%d", k, ti, l, c), t, { l, c }, k)
      end
    end
  end
end

-- Objects on tiny texts.
local object_texts = {
  { "a", "", "b" },
  { "(a)", "", "{", "  b", "}" },
  { "  {", "x", "}" },
  { "\"ab\\", "c\"" },
  { "\"ab\\\"", "'c' \"d" },
  { "x \"a\" \"b\" y" },
  { "(((x)))" },
  { "a.", "b", "", "c d. e" },
  { "  ", " " },
  { "a b" },
  { "a b c" },
  { "  ", "", "b" },
  { "{", "  ", "}" },
  { "a \"bc" },
  { "((x) (y))", "z" },
  { "a " },
  { "a  " },
  { "(abc" },
  { "((a)" },
  { "((ab)" },
  { "{", "", "  ", "}" },
}
local object_keys = {
  "diw", "daw", "d2aw", "d3iw", "d9aw", "diW", "daW", "viw", "vaw", "viwiw", "vawaw", "viwiwiw",
  "vhiw", "vhhiw", "vbiw", "vbaw", "vhhawaw", "vbawaw", "vbiwiw",
  "dip", "dap", "d2ap", "d3ip", "vip", "vap", "vipip", "vapap", "vapapap", "vjip", "vkip", "vjap", "vkap", "vjipip",
  "di(", "da(", "d3i(", "di{", "da{", "vi(", "va(", "vi(i(", "va(a(", "vi(i(i(", "vi{", "va{", "vi{i{", "vhi(", "vhhi(i(",
  "di\"", "da\"", "ci\"X<Esc>", "d2i\"", "vi\"", "va\"", "di'",
  "dis", "das", "d2is",
  "v2ap", "vj2ap", "vjapap", "vk2ap", "d4i(", "d2i(", "d4i{", "vi(i(i(i(", "d2a(", "v2i(",
}
for ti, t in ipairs(object_texts) do
  for l = 0, #t - 1 do
    local n = vim.fn.strchars(t[l + 1])
    for c = 0, math.max(n - 1, 0) do
      for _, k in ipairs(object_keys) do
        add(string.format("object %s text %d at %d,%d", k, ti, l, c), t, { l, c }, k)
      end
    end
  end
end

-- Keys that need a previous find, a mark that is not set and counts.
for _, k in ipairs({ ";", ",", "Fo,", "fo,", "to,", "To,", "df;", "d;", "d,", "2;", "'<", "`>", "'?", "mz'z", "m'", "m`", "x'<", "`<" }) do
  add("keys " .. k, { "foo boo", "zoo" }, { 0, 1 }, k)
end
for _, k in ipairs({ "dgu", "dgU", "dg~", "gudgU", "gUgu" }) do
  add("operators " .. k, { "abc def" }, { 0, 1 }, k)
end
for _, k in ipairs({ "5+", "9+", "9-", "d9+", "d9-", "d9_", "9_", "d99G", "5%", "100%", "0%" }) do
  add("lines " .. k, { "a", " b", "c", "  d", "e" }, { 1, 0 }, k)
end
add("star without a word", { "  --  " }, { 0, 0 }, "*")
add("star on blanks", { "   " }, { 0, 1 }, "#")
add("visual dollar replace", { "abc", "de" }, { 0, 1 }, "v$rx")
add("visual join on the last line", { "abc", "de" }, { 1, 0 }, "vJ")
add("visual join on the last line with gJ", { "abc", "de" }, { 1, 0 }, "VgJ")
add("visual put a multiline charwise register", { "ab cd", "ef gh", "ij" }, { 0, 1 }, "vj$yjvlp")
add("visual put a multiline charwise register over lines", { "ab cd", "ef gh", "ij" }, { 0, 1 }, "vj$yjVp")
add("insert control u at the start", { "abc" }, { 0, 0 }, "i<C-u>x<Esc>")
add("star then jump back", { "ab cd ab", "x" }, { 0, 4 }, "w*``")
add("g then a key that is nothing", { "abc" }, { 0, 0 }, "gz")
add("g then escape", { "abc" }, { 0, 0 }, "g<Esc>x")
add("z then a key that is nothing", { "abc" }, { 0, 0 }, "zq")
add("operator then a different operator", { "abc def" }, { 0, 0 }, "dyw")
add("operator then a register", { "abc def" }, { 0, 0 }, "d\"aw")
add("gu then a different key", { "abc def" }, { 0, 0 }, "guz")
add("gv without a selection", { "abc" }, { 0, 0 }, "gv")
add("gv after a selection", { "abc def" }, { 0, 0 }, "vl<Esc>$gvd")
add("a register that does not exist", { "abc" }, { 0, 0 }, "\"!yw")
add("a mark that does not exist as a target", { "abc" }, { 0, 0 }, "m!")
add("redo", { "abc def" }, { 0, 0 }, "xu<C-r>")
add("redo with a count", { "abc def" }, { 0, 0 }, "xu2<C-r>")
add("a large count", { "abc def" }, { 0, 0 }, "99999999999l")
add("g with a motion key that is plain", { "abc", "def" }, { 0, 1 }, "gjgkg0g^g$")
add("capital i after g", { "  abc" }, { 0, 3 }, "gIx<Esc>")
add("tilde on an empty line", { "" }, { 0, 0 }, "~")
add("join count of one", { "a", "b" }, { 0, 0 }, "1J")
add("r on an empty line", { "" }, { 0, 0 }, "rx")
add("operator at pending visual mixing", { "abc def" }, { 0, 0 }, "vd")

-- Backward selections.
local prose = { "hello world foo", "  bar.baz(qux) end", "", "last line here" }
for _, p in ipairs({ { 0, 5 }, { 1, 8 }, { 3, 4 } }) do
  for _, k in ipairs({ "vhd", "vkd", "vhhy", "vbd", "vbcX<Esc>", "vkJ", "vhgU", "vhr-", "voohd", "Vkd", "Vky", "Vk>", "vhx", "vhX", "vhD" }) do
    add(string.format("backward %s from %d,%d", k, p[1], p[2]), prose, p, k)
  end
end

return cases
