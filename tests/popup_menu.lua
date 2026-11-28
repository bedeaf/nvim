-- Real terminal: a right-click menu must stay open after release and mouse motion.
local file = vim.fn.tempname() .. '.txt'
vim.fn.writefile({'hello world', 'second line', 'third'}, file)
local term = vim.fn.jobstart({'nvim', '-i', 'NONE', file}, {term = true, width = 80, height = 24})
local function screen()
  local ok, text = pcall(function()
    local buf = vim.fn.bufnr('%')
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  end)
  return ok and text or ''
end
local function send(seq) vim.fn.chansend(term, seq); vim.wait(400) end
assert(vim.wait(8000, function() return screen():find('hello world', 1, true) end, 50), 'child must start')
vim.wait(1500)
send('\27[<2;12;2M')
assert(screen():find('Paste', 1, true), 'right press must open the menu')
send('\27[<2;12;2m')
send('\27[<35;13;2M')
send('\27[<35;13;6M')
assert(screen():find('Paste', 1, true), 'menu must stay open after release and mouse motion')
send('\27')
vim.fn.jobstop(term)
print('PASS right-click menu stays open after release and mouse motion')
