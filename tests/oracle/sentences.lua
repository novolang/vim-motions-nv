-- Sentences: the motions ( and ).

local cases = {}

local function add(name, text, at, keys)
  cases[#cases + 1] = { name = name, text = text, at = at, keys = keys }
end

local function sweep(label, text, positions, keys_list)
  for _, p in ipairs(positions) do
    for _, k in ipairs(keys_list) do
      add(string.format("%s %s from %d,%d", label, k, p[1], p[2]), text, p, k)
    end
  end
end

local prose = { "First one. Second one!  Third? Fourth.", "Next line starts here. And ends (really.) now.", "", "After a gap.  \"Quoted.\"  Done" }
local keys = { "(", ")", "2(", "2)", "3)", "9)", "9(", "))", "((", "d)", "d(", "y)", "y(", "c)X<Esc>", "c(X<Esc>", ">)", "gU)", "d2)" }
local positions = {}
for _, p in ipairs({ { 0, 0 }, { 0, 3 }, { 0, 7 }, { 0, 10 }, { 0, 11 }, { 0, 12 }, { 0, 24 }, { 0, 31 }, { 0, 37 }, { 1, 0 }, { 1, 5 }, { 1, 22 }, { 1, 30 }, { 1, 40 }, { 1, 44 }, { 2, 0 }, { 3, 0 }, { 3, 14 }, { 3, 17 }, { 3, 27 } }) do
  positions[#positions + 1] = p
end
sweep("sentence", prose, positions, keys)
for ti, t in ipairs({ { "a..  b" }, { "wow!!!  yes?!  ok" }, { "End.   " }, { "x", "End.  ", "  y." } }) do
  for l = 0, #t - 1 do
    for c = 0, #t[l + 1] - 1 do
      for _, k in ipairs({ ")", "(", "2)", "2(", "d)", "d(", "das", "dis", "vas" }) do
        add(string.format("sentence tiny %s text %d at %d,%d", k, ti, l, c), t, { l, c }, k)
      end
    end
  end
end
add("sentence in one line", { "One. Two." }, { 0, 0 }, ")")
add("sentence at the end of the text", { "One. Two." }, { 0, 7 }, ")")
add("sentence at the start of the text", { "One. Two." }, { 0, 2 }, "(")
add("sentence across blank lines", { "One.", "", "", "Two." }, { 0, 0 }, "))")
add("sentence back across blank lines", { "One.", "", "", "Two." }, { 3, 2 }, "((")
add("sentence without an end", { "no end here", "still none" }, { 0, 3 }, ")")
add("sentence without an end back", { "no end here", "still none" }, { 1, 3 }, "(")

local objs = {}
for _, o in ipairs({ "is", "as", "2is", "2as", "3is" }) do
  for _, op in ipairs({ "d", "y", "gU" }) do
    objs[#objs + 1] = op .. o
  end
end
objs[#objs + 1] = "cisX<Esc>"
objs[#objs + 1] = "casX<Esc>"
objs[#objs + 1] = "vis"
sweep("sentence object", prose, positions, objs)
local without_gap = {}
for _, p in ipairs(positions) do
  if p[1] ~= 2 then
    without_gap[#without_gap + 1] = p
  end
end
sweep("sentence object around", prose, without_gap, { "vas" })
add("sentence object in one line", { "One. Two. Three." }, { 0, 7 }, "das")
add("sentence object last in a line", { "One. Two. Three." }, { 0, 13 }, "das")
add("sentence object on blanks", { "One.   Two." }, { 0, 5 }, "dis")
add("sentence object on blanks around", { "One.   Two." }, { 0, 5 }, "das")

return cases
