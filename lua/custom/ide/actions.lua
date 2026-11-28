local M = {}
local project = require('custom.ide.project')

local methods = {
  {'Rename', 'textDocument/rename'},
  {'Code action', 'textDocument/codeAction'},
  {'File symbols', 'textDocument/documentSymbol'},
  {'Project symbols', 'workspace/symbol'},
}

function M.supports(method, buf)
  return #vim.lsp.get_clients({bufnr = buf or 0, method = method}) > 0
end

local function ready(method)
  if M.supports(method) then return true end
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'this file'
  local reason = #vim.lsp.get_clients({bufnr = 0}) == 0
    and 'No language server attached' or 'The attached language server does not support this'
  vim.notify(reason .. ' (' .. ft .. '). Tool and connection status: :IDEInfo', vim.log.levels.WARN)
  return false
end

function M.rename()
  if ready('textDocument/rename') then vim.lsp.buf.rename() end
end

function M.code_action()
  if ready('textDocument/codeAction') then vim.lsp.buf.code_action() end
end

function M.symbols()
  if ready('textDocument/documentSymbol') then
    Snacks.picker.lsp_symbols({cwd = project.root()})
  end
end

function M.workspace_symbols()
  if ready('workspace/symbol') then
    Snacks.picker.lsp_workspace_symbols({cwd = project.root(), filter = {cwd = true}})
  end
end

function M.outline()
  local trouble = require('trouble')
  if trouble.is_open('symbols') then
    local view = trouble.close('symbols')
    -- Trouble also reports pending LSP views as open. Close again after the
    -- first render so an in-flight response cannot reopen a dismissed outline.
    if view then view:wait(function() view:close() end) end
  elseif ready('textDocument/documentSymbol') then
    trouble.open({mode = 'symbols', focus = false})
  end
end

function M.files() Snacks.picker.files({cwd = project.root()}) end
-- Space f: everything under home. Space F: the whole computer.
function M.home_files() require('custom.ide.filelist').open('home') end
function M.all_files() require('custom.ide.filelist').open('all') end
function M.grep() Snacks.picker.grep({cwd = project.root()}) end

function M.terminal()
  local root = project.root()
  local terminal = Snacks.terminal.toggle(nil, {cwd = root, win = {position = 'bottom', height = 0.3}})
  -- Terminals have no file path; keep their origin when invoking project actions.
  if terminal and terminal.buf then vim.b[terminal.buf].workflow_root = root end
end

function M.diagnostics()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  if #vim.diagnostic.get(0, {lnum = line}) == 0 then
    vim.notify('No errors or warnings on this line.', vim.log.levels.INFO)
    return
  end
  vim.diagnostic.open_float({scope = 'line', source = true})
end

function M.info()
  local buf, ft = vim.api.nvim_get_current_buf(), vim.bo.filetype
  local lines = {'Project: ' .. project.root(buf), 'File type: ' .. (ft ~= '' and ft or 'unknown'), '', 'Attached language servers:'}
  local clients = vim.lsp.get_clients({bufnr = buf})
  table.sort(clients, function(a, b) return a.name < b.name end)
  for _, client in ipairs(clients) do
    lines[#lines + 1] = ('  %s — %s'):format(client.name, client.root_dir or 'single file')
  end
  if #clients == 0 then lines[#lines + 1] = '  None; an installed server may still need to be started.' end
  vim.list_extend(lines, {'', 'Actions available in this file:'})
  for _, item in ipairs(methods) do
    lines[#lines + 1] = ('  %s: %s'):format(item[1], M.supports(item[2], buf) and 'ready' or 'no supporting server attached')
  end
  vim.list_extend(lines, {'', 'Language tools for this file:'})
  local tools = require('custom.ide.languages').tools_for(ft)
  for _, tool in ipairs(tools) do
    lines[#lines + 1] = ('  %s: %s'):format(tool.name, tool.path ~= '' and tool.path or 'not installed (' .. tool.command .. ')')
  end
  if #tools == 0 then lines[#lines + 1] = '  No server configured for this file type.' end
  local ok, conform = pcall(require, 'conform')
  if ok then
    vim.list_extend(lines, {'', 'Formatters:'})
    local formatters = conform.list_formatters_for_buffer(buf)
    for _, name in ipairs(formatters) do
      local formatter = conform.get_formatter_info(name, buf)
      lines[#lines + 1] = ('  %s: %s'):format(name, formatter.available
        and (formatter.command or 'ready') or ('not ready — ' .. (formatter.available_msg or 'not installed')))
    end
    if #formatters == 0 then lines[#lines + 1] = '  None; the language server formats if it can.' end
  end
  vim.list_extend(lines, {'', ':Mason — install only the language tools you need',
    ':checkhealth vim.lsp — inspect the connection; :LspLog — server log',
    ':ConformInfo — formatting details',
    'Restart Neovim after installing a tool. Space ? — everyday keys'})
  Snacks.win({text = table.concat(lines, '\n'), enter = true, width = 0.85, height = 0.75,
    title = ' IDE · File and tool status ', border = 'single', ft = 'markdown',
    bo = {modifiable = false}, wo = {wrap = true}, keys = {q = 'close', ['<Esc>'] = 'close'}})
end

return M
