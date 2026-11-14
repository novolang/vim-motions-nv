-- one.lua — run one key vector in a fresh editor and write what came out.
--
-- Usage:  nvim --headless --clean -l tests/oracle/one.lua <case.json> <result.json>
--
-- A fresh editor for each case means that no register, mark, search
-- pattern, undo history or dot-repeat record is left over from another.

local registers = { '"', "0", "1", "-", "a", "b" }

local function configure()
  -- The editor ships with mappings of its own, such as `Y` for `y$` and
  -- `%` through a plugin.  The keys here mean what the manual says.
  for _, mode in ipairs({ "n", "x", "o", "i", "s", "c", "v", "t" }) do
    for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
      pcall(vim.api.nvim_del_keymap, mode, km.lhs)
    end
  end
  local o = vim.o
  o.startofline = true
  o.cpoptions = "aABceFs_"
  o.formatoptions = ""
  o.autoindent = false
  o.smartindent = false
  o.cindent = false
  o.joinspaces = false
  o.nrformats = ""
  o.virtualedit = ""
  o.whichwrap = "b,s"
  o.wrapscan = true
  o.ignorecase = false
  o.smartcase = false
  o.hlsearch = false
  o.incsearch = false
  o.shiftwidth = 8
  o.tabstop = 8
  o.softtabstop = 0
  o.expandtab = false
  o.smarttab = false
  o.matchpairs = "(:),{:},[:]"
  o.iskeyword = "@,48-57,_,192-255"
  o.scrolloff = 0
  o.sidescrolloff = 0
  o.selection = "inclusive"
  o.backspace = "indent,eol,start"
  o.textwidth = 0
  o.comments = ""
  o.wrap = false
  o.hidden = true
  o.report = 9999
  o.shortmess = "filnxtToOFIcCs"
  o.undolevels = 1000
end

local function run_case(c)
  vim.bo.undolevels = -1
  vim.api.nvim_buf_set_lines(0, 0, -1, false, c.text)
  vim.bo.undolevels = 1000
  local line = c.text[c.at[1] + 1]
  vim.api.nvim_win_set_cursor(0, { c.at[1] + 1, vim.fn.byteidx(line, c.at[2]) })
  vim.fn.winrestview({ topline = (c.top or 0) + 1 })
  vim.api.nvim_win_set_cursor(0, { c.at[1] + 1, vim.fn.byteidx(line, c.at[2]) })
  local keys = vim.api.nvim_replace_termcodes(c.keys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cur = vim.api.nvim_win_get_cursor(0)
  local ltext = lines[cur[1]] or ""
  local col = vim.fn.charidx(ltext, cur[2])
  local mode = vim.api.nvim_get_mode().mode
  local mmode
  if mode == "n" then
    mmode = 0
  elseif mode == "v" then
    mmode = 3
  elseif mode == "V" then
    mmode = 4
  else
    error("unexpected final mode " .. mode .. " in case " .. c.name)
  end
  local anl, anc = -1, -1
  if mmode ~= 0 then
    local p = vim.fn.getpos("v")
    anl = p[2] - 1
    anc = vim.fn.charidx(lines[p[2]] or "", p[3] - 1)
  end
  local rt, rl = {}, {}
  for _, r in ipairs(registers) do
    local t = vim.fn.getreg(r)
    local ty = vim.fn.getregtype(r)
    if ty == "V" then
      t = t:gsub("\n$", "")
    end
    rt[#rt + 1] = t
    rl[#rl + 1] = (ty == "V")
  end
  return {
    lines = lines,
    line = cur[1] - 1,
    col = col,
    mode = mmode,
    anl = anl,
    anc = anc,
    top = vim.fn.line("w0") - 1,
    rt = rt,
    rl = rl,
  }
end

configure()
local fin = assert(io.open(arg[1], "r"))
local case = vim.json.decode(fin:read("*a"))
fin:close()
local ok, result = pcall(run_case, case)
if not ok then
  result = { error = tostring(result) }
end
local fout = assert(io.open(arg[2], "w"))
fout:write(vim.json.encode(result))
fout:close()
vim.cmd("qa!")
