local M = {}

local function dedup_definitions(locations)
  local function get_uri(loc) return loc.uri or loc.targetUri end
  local function get_range(loc) return loc.range or loc.targetSelectionRange end

  local function is_point(r)
    return r.start.line == r['end'].line and r.start.character == r['end'].character
  end

  local function contains(outer, inner)
    local s_ok = outer.start.line < inner.start.line
        or (outer.start.line == inner.start.line and outer.start.character <= inner.start.character)
    local e_ok = outer['end'].line > inner['end'].line
        or (outer['end'].line == inner['end'].line and outer['end'].character >= inner['end'].character)
    return s_ok and e_ok
  end

  local result = {}
  for i, a in ipairs(locations) do
    local superseded = false
    for j, b in ipairs(locations) do
      if i ~= j and get_uri(a) == get_uri(b) then
        local ra, rb = get_range(a), get_range(b)
        if is_point(ra) and not is_point(rb) then
          -- a point is superseded by any range starting on the same line or containing it
          if ra.start.line == rb.start.line or contains(rb, ra) then
            superseded = true
            break
          end
        elseif not is_point(ra) and not is_point(rb) then
          -- two ranges: superseded if b strictly contains a, or same start line with larger span
          if contains(rb, ra) and not contains(ra, rb) then
            superseded = true
            break
          end
          local a_lines = ra['end'].line - ra.start.line
          local b_lines = rb['end'].line - rb.start.line
          if ra.start.line == rb.start.line then
            if b_lines > a_lines or (b_lines == a_lines and rb['end'].character > ra['end'].character) then
              superseded = true
              break
            end
          end
        end
      end
    end
    if not superseded then table.insert(result, a) end
  end
  return result
end

M.goto_definition = function(split_cmd)
  local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })
  if #clients == 0 then return end
  local encoding = clients[1].offset_encoding
  local params = vim.lsp.util.make_position_params(vim.api.nvim_get_current_win(), encoding)
  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx)
    if err or not result then return end
    local locations = vim.islist(result) and result or { result }
    if #locations == 0 then return end
    local deduped = dedup_definitions(locations)
    local enc = (vim.lsp.get_client_by_id(ctx.client_id) or clients[1]).offset_encoding
    if #deduped == 1 then
      if split_cmd then vim.cmd(split_cmd) end
      vim.lsp.util.show_document(deduped[1], enc, { focus = true })
    else
      local items = vim.lsp.util.locations_to_items(deduped, enc)
      vim.fn.setqflist({}, ' ', { title = 'LSP definitions', items = items })
      vim.cmd('botright copen')
    end
  end)
end

return M
