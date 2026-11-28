local map = vim.keymap.set
local ide = require('custom.ide.actions')
require('custom.mouse').setup()
map('i', 'jk', '<Esc>', {desc = 'Normal mode'})
map('i', 'kj', '<Esc>', {desc = 'Normal mode'})
map('n', '<CR>', 'o', {desc = 'Open a new line below and type'})
map('i', '<S-CR>', '<Esc>o', {desc = 'Open a new line below and type'})
map({'n', 'x', 's', 'i'}, '<PageUp>', '<Cmd>normal! <C-y><CR>', {desc = 'Scroll the view up one line', silent = true})
map({'n', 'x', 's', 'i'}, '<PageDown>', '<Cmd>normal! <C-e><CR>', {desc = 'Scroll the view down one line', silent = true})
-- Reuse LazyVim's line/block movement, including indentation and insert mode.
map({'n', 'x', 'i'}, '<S-Up>', '<A-k>', {remap = true, desc = 'Move line / selection up'})
map({'n', 'x', 'i'}, '<S-Down>', '<A-j>', {remap = true, desc = 'Move line / selection down'})
map('n', '<C-d>', 'viw', {desc = 'Select word'})
map('x', '<C-d>', function() require('multicursor-nvim').matchAddCursor(1) end,
  {desc = 'Add next match to selection'})
map('n', 'cc', 'gcc', {remap = true, desc = 'Comment / uncomment line'})
map('x', 'cc', 'gcgv', {remap = true, desc = 'Comment / uncomment selection'})
map('n', '<leader><leader>', '<cmd>update<cr>', {desc = 'Save'})
local function window_mode(direction)
  if direction then vim.cmd.wincmd(direction) end
  require('which-key').show({keys = '<C-w>', loop = true})
end
for direction, label in pairs({h = 'Left', j = 'Lower', k = 'Upper', l = 'Right'}) do
  map('n', '<leader>' .. direction, function() window_mode(direction) end,
    {desc = label .. ' window; continue with h/j/k/l'})
  map({'n', 'i', 't'}, '<C-' .. direction .. '>', function() vim.cmd.wincmd(direction) end,
    {desc = label .. ' window', silent = true})
end
map('n', '<leader>w', function() window_mode() end, {desc = 'Window mode; Esc to leave'})
map('n', '<leader>n', '<cmd>enew<cr>', {desc = 'New file'})
map('n', '<leader>bn', '<cmd>bnext<cr>', {desc = 'Next file'})
map('n', '<leader>bp', '<cmd>bprevious<cr>', {desc = 'Previous file'})
map('n', '<leader>bo', require('custom.workflow').open_recent, {desc = 'Recent project files'})
-- Explicit system-clipboard access; nonrecursive RHS keeps these working even
-- though the old yank/put keys below are disabled.
map('n', '<C-c>', '"+yy', {desc = 'Copy line to clipboard'})
map('i', '<C-c>', '<C-o>"+yy', {desc = 'Copy line to clipboard'})
map('x', '<C-c>', '"+y', {desc = 'Copy selection to clipboard'})
map('s', '<C-c>', '<C-g>"+y', {desc = 'Copy selection to clipboard'})
map('n', '<C-v>', '"+p', {desc = 'Paste from clipboard'})
map('x', '<C-v>', '"+P', {desc = 'Paste over selection, keep clipboard'})
map('s', '<C-v>', '<C-g>"+P', {desc = 'Paste over selection, keep clipboard'})
map('i', '<C-v>', '<C-r><C-p>+', {desc = 'Paste clipboard text literally'})
map('c', '<C-v>', '<C-r>+', {desc = 'Paste into command line'})
for _, key in ipairs({'y', 'Y', 'p', 'P', 'gp', 'gP', '[p', ']p', '[P', ']P', '<leader>y', '<leader>p'}) do
  map({'n', 'x'}, key, '<Nop>', {desc = 'Disabled: use Ctrl+C / Ctrl+V'})
end
for _, key in ipairs({'<C-Insert>', '<S-Insert>', '<MiddleMouse>'}) do
  map({'n', 'x', 's', 'i', 'c'}, key, '<Nop>', {desc = 'Disabled: use Ctrl+C / Ctrl+V'})
end
map({'i', 'c'}, '<C-r>', '<Nop>', {desc = 'Disabled: use Ctrl+V'})
map('t', '<Esc>', '<C-\\><C-n>', {desc = 'Terminal to normal mode'})
-- Window controls use Space in normal mode; Escape leaves terminal input.
local function close_window()
  if vim.api.nvim_win_get_config(0).relative == '' and #vim.api.nvim_list_tabpages() == 1 then
    local editors = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative == '' then editors = editors + 1 end
    end
    if editors == 1 then
      vim.notify('The last window stays open. Use :q to quit Neovim.')
      return
    end
  end
  vim.cmd.close()
end
map('n', '<leader>q', close_window, {desc = 'Close this window', silent = true, nowait = true})
map({'n', 'i', 't'}, 'q', require('custom.mouse').q, {expr = true, desc = 'Close the file tree under the mouse', silent = true, nowait = true})
map('n', 'Q', 'q', {desc = 'Record macro'})
map('n', '<C-w>q', close_window, {desc = 'Close this window', silent = true})
map('n', '<leader>t', function() require('custom.ide.tasks').toggle_output() end,
  {desc = 'Toggle output panel', silent = true})
map('n', '<leader>+', '<cmd>resize +3<cr>', {desc = 'Taller window', silent = true})
map('n', '<leader>-', '<cmd>resize -3<cr>', {desc = 'Shorter window', silent = true})
map('n', '<leader>0', function() Snacks.zen.zoom() end, {desc = 'Zoom window / restore'})
map({'n', 'x'}, '<C-Left>', 'b', {desc = 'Previous word'})
map({'n', 'x'}, '<C-Right>', 'w', {desc = 'Next word'})
map('i', '<C-Left>', '<C-o>b')
map('i', '<C-Right>', '<C-o>w')
map({'n', 'x'}, '<C-Up>', '{', {desc = 'Previous block boundary'})
map({'n', 'x'}, '<C-Down>', '}', {desc = 'Next block boundary'})
map('i', '<C-Up>', '<C-o>{', {desc = 'Previous block boundary'})
map('i', '<C-Down>', '<C-o>}', {desc = 'Next block boundary'})
map('s', '<C-Up>', '<C-g>{<C-g>', {desc = 'Previous block boundary'})
map('s', '<C-Down>', '<C-g>}<C-g>', {desc = 'Next block boundary'})
map({'i', 'c'}, '<C-BS>', '<C-w>')
map('n', '<leader>cI', ide.info, {desc = 'IDE and tool status for this file'})
map('n', '<leader>rn', ide.rename, {desc = 'Rename symbol'})
map('n', '<F2>', ide.rename, {desc = 'Rename symbol'})
map({'n', 'x'}, '<F4>', ide.code_action, {desc = 'Code action / refactoring'})
map('n', 'gO', ide.symbols, {desc = 'Find function / symbol in file'})
map('n', '<leader>cs', ide.symbols, {desc = 'Find function / symbol in file'})
map('n', '<leader>cS', ide.workspace_symbols, {desc = 'Find symbol in project'})
map('n', '<leader>co', ide.outline, {desc = 'Toggle file outline'})
map('n', 'gl', ide.diagnostics, {desc = 'Diagnostic for this line'})
map({'n', 't'}, '<F7>', ide.terminal, {desc = 'Toggle project terminal'})
map('n', '<leader>xq', function() Snacks.picker.qflist() end, {desc = 'Build errors'})
map('n', '<leader>cg', ide.grep, {desc = 'Search text in project'})
map('n', '<leader>/', ide.grep, {desc = 'Search text in project'})
map('n', '<leader>ff', ide.files, {desc = 'Find file in project'})
map('n', '<leader>mm', function() vim.ui.open('https://exercism.org/tracks') end,
  {desc = 'Exercism: open exercises in browser'})
map('n', '<leader>mf', function() Snacks.picker.files({cwd = vim.fn.expand('~/code/exercism')}) end,
  {desc = 'Exercism: exercise files'})

-- Search/navigation follow the same project root as build and debug.
map('n', '<leader>fp', function() Snacks.picker.projects() end, {desc = 'Open / switch project'})
map('n', '<leader>fr', function() Snacks.picker.recent({cwd = require('custom.ide.project').root(), filter = {cwd = true}}) end,
  {desc = 'Recent project files'})
map({'n', 'x'}, '<leader>sw', function() Snacks.picker.grep_word({cwd = require('custom.ide.project').root()}) end,
  {desc = 'Search word / selection in project'})
map('n', '<leader>sR', function() Snacks.picker.resume() end, {desc = 'Resume last search'})
map('n', '<C-u>', '<C-u>zz', {desc = 'Half page up; center cursor'})
map('n', 'n', 'nzzzv', {desc = 'Next match, centered'})
map('n', 'N', 'Nzzzv', {desc = 'Previous match, centered'})

require('custom.ide.tasks').setup()
require('custom.ide.debug').keys()
require('custom.ide.ui').setup()
map('n', '<leader>e', function() require('custom.ide.ui').explorer(false) end, {desc = 'Project files'})
map({'n', 'i'}, '<C-s>', function() require('custom.ide.ui').action(2) end, {desc = 'Save'})
map('n', '<C-p>', ide.files, {desc = 'Find file in project'})
map('n', '<leader>:', function() Snacks.picker.keymaps() end, {desc = 'Search commands'})
vim.api.nvim_create_user_command('IDEInfo', ide.info, {})

local function help()
  Snacks.win({
    text = table.concat({
      'Space Space      Save',
      'Ctrl s / Ctrl p  Save / find file',
      'Page Up / Down   Scroll the view one line up / down',
      'Ctrl ↑ / ↓       Previous / next block boundary',
      'Shift ↑ / ↓      Move line / selected block',
      'Ctrl d           Select word; press again: add match',
      'c → type → Esc Esc  Change selected matches and leave',
      'Ctrl c / Ctrl v  Copy / paste keeping the clipboard',
      'cc               Comment / uncomment line or selection',
      'Enter (normal)   Open a new line below and type',
      'Shift Enter (insert)  Open a new line below and type',
      'F6 / Space rr    Build and run',
      'F7               Toggle project terminal',
      'Space t / rl     Toggle output panel',
      'Space q          Close the current window',
      'Ctrl h/j/k/l     Left / lower / upper / right window',
      'Space h/j/k/l    Move; repeat with h/j/k/l; Esc leaves',
      'Space + / -      Taller / shorter window',
      'Space 0          Zoom window / restore',
      'Shift-F6 / Space rx  Stop the program',
      'Space rb / rB    Build / build preview',
      'Space e          Toggle file tree',
      'Space ff / fp    Find file / open project',
      'Space ba / bh    Pin file / pinned files',
      'Space 1–5        Go to pinned file',
      'Space sw / sR    Search word / resume last search',
      '-                Edit folder (Oil)',
      'Space / / cg     Search text in project',
      'F2 / Space rn    Rename symbol',
      'F4               Code action / refactoring',
      'gO / Space cs    File symbols (C#: gO)',
      'Space cS / co    Project symbols / file outline',
      'gl / Space cI    Line diagnostic / language tool status',
      'Space cf         Format code',
      'Space xq         Build errors',
      'F5 / F9          Debug / breakpoint',
      'Ctrl+n / Space cn  New project (C++ / OpenGL included)',
      'Space ri / rt    Install dependencies / test',
      'Space bs / br    Save / restore session',
      'Space mm / mf    Exercism: site / files',
      '',
      'In output, i: type input  |  Esc: normal mode  |  q: close',
    }, '\n'),
    width = 62, height = 0.85, border = 'single', title = ' Neovim · Everyday keys ',
    bo = {modifiable = false}, wo = {wrap = false},
    keys = {q = 'close', ['<Esc>'] = 'close'},
  })
end
vim.api.nvim_create_user_command('KolayTuslar', help, {})
map('n', '<leader>?', help, {desc = 'Everyday keys'})
