-- Cached file lists for the home and whole-computer pickers.
--
-- fd itself is fast (home ~130 ms, / ~700 ms); the slow part was turning
-- hundreds of thousands of lines into picker items on every open. The items
-- paths are split once, in small slices so the editor never freezes, kept in
-- memory as plain strings (cheap) and refreshed in the background after each
-- open. Each picker gets its own item tables, since pickers write scores
-- into them.
local M = {}

local SLICE = 20000 -- lines turned into items per event-loop tick
local EXCLUDE = {'/proc', '/sys', '/dev', '/run', '/tmp', '/var/tmp', '/var/cache',
  '/mnt', '/media', '/archive', '.cache', 'node_modules', '.git'}

local lists = {
  home = {cwd = vim.env.HOME, title = 'Files in ~'},
  all = {cwd = '/', title = 'Files on this computer', absolute = true},
}

local function fd_cmd(list)
  local cmd = {'fd', '--type', 'f', '--color', 'never'}
  table.insert(cmd, list.absolute and '--absolute-path' or '--strip-cwd-prefix')
  for _, pattern in ipairs(EXCLUDE) do vim.list_extend(cmd, {'--exclude', pattern}) end
  return cmd
end

-- Run fd in the background, then build the items a slice at a time.
function M.refresh(key, on_ready)
  local list = lists[key]
  if list.running then
    if on_ready then list.waiting = list.waiting or {}; table.insert(list.waiting, on_ready) end
    return
  end
  list.running = true
  vim.system(fd_cmd(list), {cwd = list.cwd, text = true}, function(result)
    vim.schedule(function()
      local out = result.stdout or ''
      local files, pos, n = {}, 1, 0
      local function step()
        for _ = 1, SLICE do
          local nl = out:find('\n', pos, true)
          if not nl then
            list.files, list.running = files, false
            if on_ready then on_ready() end
            for _, fn in ipairs(list.waiting or {}) do fn() end
            list.waiting = nil
            return
          end
          n = n + 1
          files[n] = out:sub(pos, nl - 1)
          pos = nl + 1
        end
        vim.schedule(step)
      end
      step()
    end)
  end)
end

function M.open(key)
  local list = lists[key]
  if not list.files then
    -- Not warmed yet (only right after startup). vim.wait runs the event loop
    -- but leaves typed keys queued, so they reach the picker input below.
    M.refresh(key)
    vim.wait(3000, function() return list.files ~= nil end, 10)
    if not list.files then return vim.notify('File list is still loading; try again.', vim.log.levels.WARN) end
  end
  local cwd = not list.absolute and list.cwd or nil
  Snacks.picker.pick({
    title = list.title, format = 'file', preview = 'file',
    -- One table is far cheaper than one callback per file.
    finder = function()
      local items = {}
      for i, file in ipairs(list.files) do items[i] = {file = file, text = file, cwd = cwd} end
      return items
    end,
  })
  M.insert_now()
  M.refresh(key) -- pick up new and deleted files for next time
end

-- Snacks enters insert mode on a later tick; while the editor is busy, keys
-- typed right after Space f would run as normal-mode commands. Enter insert
-- mode before the queued keys are read.
function M.insert_now()
  if vim.bo.filetype == 'snacks_picker_input' then vim.cmd('startinsert!') end
end

-- Warm both lists after startup so Space f and Space F open instantly.
function M.setup()
  local function warm()
    vim.defer_fn(function() M.refresh('home') end, 300)
    vim.defer_fn(function() M.refresh('all') end, 1500)
  end
  if vim.v.vim_did_enter == 1 then return warm() end
  vim.api.nvim_create_autocmd('VimEnter', {once = true, callback = warm})
end

return M
