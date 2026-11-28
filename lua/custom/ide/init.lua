local M = {}

function M.status()
  local clients = vim.lsp.get_clients({bufnr = 0})
  local names = {}
  for _, c in ipairs(clients) do names[#names + 1] = c.name end
  table.sort(names)
  if #names == 0 then return '' end
  return table.concat(names, '+')
end

function M.info()
  local lines = {
    '# Development environment', '',
    'Project: ' .. require('custom.ide.project').root(),
    'File type: ' .. vim.bo.filetype,
    'Python: ' .. require('custom.ide.project').python(), '', 'Attached language servers:',
  }
  for _, c in ipairs(vim.lsp.get_clients({bufnr = 0})) do
    lines[#lines + 1] = ('- %s — %s'):format(c.name, c.root_dir or 'single file')
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'Tools (install missing ones with :Mason):'
  for _, exe in ipairs(require('custom.ide.languages').executables) do
    local path = vim.fn.exepath(exe)
    lines[#lines + 1] = ('- %s: %s'):format(exe, path ~= '' and path or 'NOT INSTALLED')
  end
  vim.list_extend(lines, {'', ':checkhealth vim.lsp — detailed LSP status',
    ':ConformInfo — formatters', ':Mason — tool manager',
    ':OverseerRun — project tasks', ':help dap — debugging',
    'Space ? — everyday keys; wait after Space — command menu'})
  vim.cmd.new()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'wipe', false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype, vim.bo[buf].modifiable = 'markdown', false
  vim.keymap.set('n', 'q', '<cmd>close<cr>', {buffer = buf, desc = 'Close'})
end

function M.attach(client, buf)
  local function map(mode, key, fn, desc)
    vim.keymap.set(mode, key, fn, {buffer = buf, silent = true, desc = desc})
  end
  local lsp = vim.lsp.buf
  map('n', 'gd', lsp.definition, 'Go to definition')
  map('n', 'gD', lsp.declaration, 'Go to declaration')
  map('n', 'gr', function() require('mini.extra').pickers.lsp({scope = 'references'}) end, 'Find references')
  map('n', 'gi', lsp.implementation, 'Go to implementation')
  map('n', 'gy', lsp.type_definition, 'Go to type definition')
  map('n', 'K', lsp.hover, 'Documentation')
  map('n', '<leader>rn', lsp.rename, 'Rename symbol')
  map({'n', 'x'}, '<leader>ca', lsp.code_action, 'Code fix / refactoring')
  map('n', '<leader>ch', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({bufnr = buf}), {bufnr = buf})
  end, 'Type and parameter hints')
  map('n', '<leader>ci', lsp.incoming_calls, 'Callers of this function')
  map('n', '<leader>co', lsp.outgoing_calls, 'Calls made by this function')
  map('n', '<leader>cl', vim.lsp.codelens.run, 'CodeLens action')
  map('n', '<leader>ld', vim.diagnostic.open_float, 'Diagnostic details')
  map('n', '<leader>lq', function() vim.diagnostic.setloclist({open = true}) end, 'File diagnostics')
  map('n', '<leader>ls', function() require('mini.extra').pickers.lsp({scope = 'workspace_symbol'}) end, 'Project symbols')
  if client.name == 'clangd' then
    map('n', '<leader>ks', function()
      client:request('textDocument/switchSourceHeader', {uri = vim.uri_from_bufnr(buf)}, function(err, uri)
        if err then vim.notify(err.message, vim.log.levels.ERROR)
        elseif uri and uri ~= '' then vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri))) end
      end, buf)
    end, 'Switch source / header')
  end
  if client:supports_method('textDocument/inlayHint', buf) then vim.lsp.inlay_hint.enable(true, {bufnr = buf}) end
  local group = vim.api.nvim_create_augroup('IDEBuffer' .. buf, {clear = false})
  if client:supports_method('textDocument/documentHighlight', buf) and not vim.b[buf].ide_highlight then
    vim.b[buf].ide_highlight = true
    vim.api.nvim_create_autocmd('CursorHold', {group = group, buffer = buf, callback = lsp.document_highlight})
    vim.api.nvim_create_autocmd({'CursorMoved', 'InsertEnter'}, {group = group, buffer = buf, callback = lsp.clear_references})
  end
  if client:supports_method('textDocument/codeLens', buf) and not vim.b[buf].ide_codelens then
    vim.b[buf].ide_codelens = true
    vim.lsp.codelens.enable(true, {bufnr = buf})
  end
end

function M.setup()
  vim.o.signcolumn = 'auto:1'
  vim.o.updatetime = 250
  vim.diagnostic.config({
    virtual_text = {current_line = true, spacing = 2, source = 'if_many'},
    virtual_lines = false,
    signs = {text = {[1] = 'E', [2] = 'W', [3] = 'I', [4] = 'H'}},
    underline = true, update_in_insert = false, severity_sort = true,
    float = {border = 'single', source = true},
  })
  local group = vim.api.nvim_create_augroup('IDE', {clear = true})
  vim.api.nvim_create_autocmd('LspAttach', {group = group, callback = function(e)
    local c = vim.lsp.get_client_by_id(e.data.client_id)
    if c then M.attach(c, e.buf) end
  end})
  vim.api.nvim_create_autocmd('BufWipeout', {group = group, callback = function(e)
    pcall(vim.api.nvim_del_augroup_by_name, 'IDEBuffer' .. e.buf)
  end})
  vim.api.nvim_create_user_command('IDEInfo', M.info, {desc = 'Project and language tool status'})
  local function map(key, fn, desc) vim.keymap.set('n', key, fn, {silent = true, desc = desc}) end
  map('<leader>cf', function() require('mini.pick').builtin.files({}, {source = {cwd = require('custom.ide.project').root()}}) end, 'Find file in project')
  map('<leader>cg', function() require('mini.pick').builtin.grep_live({}, {source = {cwd = require('custom.ide.project').root()}}) end, 'Search text in project')
  map('<leader>cs', function() require('mini.extra').pickers.lsp({scope = 'document_symbol'}) end, 'File symbols')
  map('<leader>cS', function() require('mini.extra').pickers.lsp({scope = 'workspace_symbol'}) end, 'Project symbols')
  map('<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', 'Project errors and warnings')
  map('<leader>xq', '<cmd>Trouble qflist toggle<cr>', 'Build errors')
  map('<leader>xb', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', 'File errors and warnings')
  map('<leader>cI', M.info, 'Development environment status')
  map('<leader>e', function() require('oil').open() end, 'Files / move / rename')
  map('[d', function() vim.diagnostic.jump({count = -1, float = true}) end, 'Previous error / warning')
  map(']d', function() vim.diagnostic.jump({count = 1, float = true}) end, 'Next error / warning')
  vim.keymap.set({'n', 'x'}, '<leader>f', function()
    require('conform').format({async = true, lsp_format = 'fallback'})
  end, {desc = 'Format code'})
  vim.ui.select = function(items, opts, callback) require('custom.algo_ui').select(items, opts, callback) end
end

return M
