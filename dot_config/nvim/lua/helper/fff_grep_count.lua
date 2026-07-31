-- Total match count for fff.nvim live grep.
--
-- fff's grep result only reports `total_matched` for the page it just loaded
-- (rust returns `matches.len()`), so there is no real total to read from the
-- plugin. This runs a debounced `rg --count` alongside the picker and renders
-- the sum as virtual text in the prompt, left of fff's `<S-Tab> plain` hint.
--
-- The count mirrors fff's list semantics: one result per matching line, capped
-- per file by `grep.max_matches_per_file` (a `+` suffix means some file hit the
-- cap). Fuzzy mode is skipped since rg cannot reproduce it.
local M = {}

local DEBOUNCE_MS = 150
local ns = vim.api.nvim_create_namespace('fff_grep_count')

local state = {
  key = nil, -- 'mode\0query' the current text/job belongs to
  seq = 0,   -- bumped per query so stale jobs are dropped
  text = nil,
  job = nil,
}

local function picker() return require('fff.picker_ui.picker_ui') end

--- Split a grep query into an rg pattern plus path globs, mirroring fff's
--- query constraints. Only the common forms are handled: `*.ext` / `**/glob`
--- globs, `!token` excludes and `/segment/` path constraints. Anything else is
--- treated as pattern text, which is what fff does with `enable_filename_constraint`
--- off.
---@param query string
---@return string pattern, string[] globs
local function parse_query(query)
  local parts, globs = {}, {}

  for token in query:gmatch('%S+') do
    local excluded = token:match('^!(.+)$')
    local segment = token:match('^/(.+)/$')
    if excluded then
      table.insert(globs, '!*' .. excluded .. '*')
    elseif segment and not segment:find('/') then
      table.insert(globs, '**/' .. segment .. '/**')
    elseif token:find('%*') then
      table.insert(globs, token)
    else
      table.insert(parts, token)
    end
  end

  return table.concat(parts, ' '), globs
end

local function grep_root()
  local base = require('fff.file_picker').state.base_path
  return (base and base ~= '') and base or vim.fn.getcwd()
end

---@param root string
---@return boolean
local function is_git_repo(root)
  return vim.fn.isdirectory(root .. '/.git') == 1 or vim.fn.filereadable(root .. '/.git') == 1
end

--- Build the rg argv for a query, or nil when the query can't be counted.
---@param query string
---@param mode string
---@param root string
---@return string[]|nil
local function build_cmd(query, mode, root)
  local pattern, globs = parse_query(query)
  if pattern == '' then return nil end

  local conf = require('fff.conf').get() or {}
  local grep = conf.grep or {}

  local cmd = { 'rg', '--count', '--no-messages', '--no-config', '--hidden', '--glob', '!.git/' }

  if mode == 'regex' then
    table.insert(cmd, '--regexp')
  else
    table.insert(cmd, '--fixed-strings')
    table.insert(cmd, '--regexp')
  end
  table.insert(cmd, pattern)

  table.insert(cmd, grep.smart_case ~= false and '--smart-case' or '--case-sensitive')
  if grep.max_file_size and grep.max_file_size > 0 then
    table.insert(cmd, '--max-filesize')
    table.insert(cmd, tostring(grep.max_file_size))
  end

  -- fff indexes hidden files inside git repos but skips these dirs elsewhere.
  if not is_git_repo(root) then
    for _, dir in ipairs({ 'node_modules', '__pycache__', 'venv', '.venv' }) do
      table.insert(cmd, '--glob')
      table.insert(cmd, '!' .. dir .. '/')
    end
  end

  for _, glob in ipairs(globs) do
    table.insert(cmd, '--glob')
    table.insert(cmd, glob)
  end

  table.insert(cmd, '--')
  table.insert(cmd, root)

  return cmd
end

--- Sum `rg --count` output (`path:N` per line), capping each file the way fff does.
---@param stdout string
---@param cap number
---@return number total, boolean capped
local function sum_counts(stdout, cap)
  local total, capped = 0, false

  for line in stdout:gmatch('[^\n]+') do
    local count = tonumber(line:match(':(%d+)$'))
    if count then
      if cap > 0 and count > cap then
        count = cap
        capped = true
      end
      total = total + count
    end
  end

  return total, capped
end

local function draw()
  local s = picker().state
  if not (s.active and s.input_buf and vim.api.nvim_buf_is_valid(s.input_buf)) then return end

  vim.api.nvim_buf_clear_namespace(s.input_buf, ns, 0, -1)
  if not state.text or s.mode ~= 'grep' then return end
  if not (s.input_win and vim.api.nvim_win_is_valid(s.input_win)) then return end

  -- Sit left of whatever fff drew in its own namespace (the grep mode hint).
  local right = vim.api.nvim_win_get_width(s.input_win) - 2
  if s.ns_id then
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(s.input_buf, s.ns_id, 0, -1, { details = true })) do
      local details = mark[4]
      if details and details.virt_text and details.virt_text_win_col then
        right = math.min(right, details.virt_text_win_col)
      end
    end
  end

  local col = right - vim.fn.strdisplaywidth(state.text) - 2
  if col < 0 then return end

  vim.api.nvim_buf_set_extmark(s.input_buf, ns, 0, 0, {
    virt_text = { { state.text, 'Comment' } },
    virt_text_win_col = col,
  })
end

local function cancel_job()
  if state.job then
    pcall(function() state.job:kill(9) end)
    state.job = nil
  end
end

---@param query string
---@param mode string
---@param seq number
local function run_count(query, mode, seq)
  local root = grep_root()
  local cmd = build_cmd(query, mode, root)
  if not cmd then
    state.text = nil
    draw()
    return
  end

  local cap = (require('fff.conf').get().grep or {}).max_matches_per_file or 0

  state.job = vim.system(cmd, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if seq ~= state.seq then return end
      state.job = nil

      -- rg exits 1 with no output when nothing matched; anything above that is
      -- a real failure and gets no count rather than a misleading zero.
      if result.code > 1 then
        state.text = nil
      else
        local total, capped = sum_counts(result.stdout or '', cap)
        state.text = string.format('%d%s results', total, capped and '+' or '')
      end

      draw()
    end)
  end)
end

--- Start a count for the current query if it changed since the last one.
local function refresh()
  local s = picker().state
  local mode = s.grep_mode or 'plain'
  local query = s.query or ''

  if s.mode ~= 'grep' then
    state.key, state.text = nil, nil
    cancel_job()
    return
  end

  local key = mode .. '\0' .. query
  if key == state.key then return end

  state.key = key
  state.seq = state.seq + 1
  local seq = state.seq
  cancel_job()

  if query == '' or mode == 'fuzzy' then
    state.text = nil
    return
  end

  state.text = 'counting…'
  vim.defer_fn(function()
    if seq == state.seq and picker().state.active then run_count(query, mode, seq) end
  end, DEBOUNCE_MS)
end

local installed = false

--- Wrap fff's status renderer so every grep render also refreshes our count.
function M.setup()
  if installed then return end
  if vim.fn.executable('rg') ~= 1 then return end

  local ui = picker()
  local update_status = ui.update_status

  ui.update_status = function(...)
    local ok, err = pcall(update_status, ...)
    pcall(refresh)
    pcall(draw)
    if not ok then error(err) end
  end

  installed = true
end

return M
