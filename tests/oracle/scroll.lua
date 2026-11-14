-- Scrolling: the keys that move the window over the text.  The window is 22
-- lines high.  The first line shown is compared with the host's.

local cases = {}

local function add(name, text, at, keys, top)
  cases[#cases + 1] = { name = name, text = text, at = at, keys = keys, top = top }
end

local tall = {}
for i = 1, 100 do
  tall[#tall + 1] = "  line " .. i
end
local short = { "a", "b", "c", "d", "e" }
local fit = {}
for i = 1, 15 do
  fit[#fit + 1] = "row " .. i
end

local keys = { "<C-e>", "<C-y>", "3<C-e>", "3<C-y>", "30<C-e>", "30<C-y>", "<C-d>", "<C-u>", "5<C-d>", "5<C-u>", "<C-d><C-d>", "<C-u><C-u>",
  "zt", "zz", "zb", "z<CR>", "z.", "z-", "<C-f>", "<C-b>", "2<C-f>", "2<C-b>", "<C-f><C-b>", "<C-b><C-f>" }
local places = { { 0, 0, 0 }, { 5, 2, 0 }, { 30, 2, 20 }, { 50, 4, 40 }, { 70, 0, 60 }, { 99, 2, 78 }, { 25, 0, 10 }, { 10, 0, 10 }, { 31, 0, 10 } }
for _, p in ipairs(places) do
  for _, k in ipairs(keys) do
    add(string.format("scroll %s cursor %d top %d", k, p[1], p[3]), tall, { p[1], p[2] }, k, p[3])
  end
end
for _, t in ipairs({ 1, 2, 3, 10, 19, 20, 21, 22, 55, 70, 74, 75, 76, 77, 78, 79, 90, 99 }) do
  for _, k in ipairs({ "<C-f>", "<C-b>", "2<C-f>", "2<C-b>", "<C-d>", "<C-u>", "<C-e>", "<C-y>" }) do
    add(string.format("scroll edge %s top %d", k, t), tall, { math.min(99, t + 3), 2 }, k, t)
  end
end
for _, k in ipairs({ "<C-e>", "<C-y>", "<C-d>", "<C-u>", "<C-f>", "<C-b>", "zt", "zz", "zb" }) do
  add("scroll short " .. k, short, { 2, 0 }, k, 0)
  add("scroll fit " .. k, fit, { 7, 2 }, k, 0)
  add("scroll fit last " .. k, fit, { 14, 0 }, k, 0)
end

return cases
