-- Registers dap launch targets for the repo this session is in. Each sibling
-- file returns { marker, configurations(root) }, where marker is a file only
-- that repo has. Resolved once at startup, so one repo per nvim session.

local M = {}

function M.load()
  local root = vim.fs.root(0, { '.git' }) or vim.fs.root(vim.uv.cwd(), { '.git' })
  if not root then return end

  local dap = require 'dap'
  local dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'dap-projects')
  for name, kind in vim.fs.dir(dir) do
    if kind == 'file' and name:match '%.lua$' and name ~= 'init.lua' then
      local project = require('custom.dap-projects.' .. name:gsub('%.lua$', ''))
      if vim.uv.fs_stat(vim.fs.joinpath(root, project.marker)) then
        for filetype, configs in pairs(project.configurations(root)) do
          dap.configurations[filetype] = configs
        end
      end
    end
  end
end

return M
