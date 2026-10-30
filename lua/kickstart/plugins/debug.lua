-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
}

-- Basic debugging keymaps, feel free to change to your liking!
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Breakpoint' })
-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
-- Only layouts 1 and 2 — layout 3 has its own toggle below.
vim.keymap.set('n', '<F7>', function()
  local dapui = require 'dapui'
  dapui.toggle { layout = 1 }
  dapui.toggle { layout = 2 }
end, { desc = 'Debug: toggle the main UI' })
vim.keymap.set('n', '<leader>dx', function() require('dapui').toggle { layout = 3 } end, { desc = 'Debug: toggle watches/breakpoints/repl column' })
vim.keymap.set('n', '<leader>dq', function() require('dapui').close() end, { desc = 'Debug: close all dap windows' })

local dap = require 'dap'
local dapui = require 'dapui'

require('mason-nvim-dap').setup {
  -- Makes a best effort to setup the various debuggers with
  -- reasonable debug configurations
  automatic_installation = true,

  -- You can provide additional configuration to the handlers,
  -- see mason-nvim-dap README for more information
  handlers = {},

  -- You'll need to check that you have the required things installed
  -- online, please don't ask me how to install them :)
  ensure_installed = {
    -- Update this to ensure that you have the debuggers for the langs you want
    'codelldb',
    -- No JS entry: the sidecar uses bun-dap-x (installed with `bun add -g`),
    -- not Mason. See the sidecar section at the bottom of this file.
  },
}

-- Dap UI setup
-- For more information, see |:help nvim-dap-ui|
---@diagnostic disable-next-line: missing-fields
dapui.setup {
  -- dapui defaults this to false, so long lines in the panes are truncated
  -- rather than wrapped — and the panes are narrow, so error messages and
  -- stack frames get cut off with no way to read the rest.
  -- Applied to every dapui window (dapui/windows/layout.lua:181).
  wrap = true,

  -- 1 and 2 open with the session; 3 is toggled with <leader>dx.
  -- Console is listed FIRST so it opens LAST (dapui opens layouts in reverse)
  -- and spans the full width instead of being cut short by the left column.
  layouts = {
    {
      elements = { { id = 'console', size = 1.0 } },
      size = 12,
      position = 'bottom',
    },
    {
      elements = { { id = 'scopes', size = 0.65 }, { id = 'stacks', size = 0.35 } },
      size = 40,
      position = 'left',
    },
    {
      elements = {
        { id = 'watches', size = 0.3 },
        { id = 'breakpoints', size = 0.2 },
        { id = 'repl', size = 0.5 },
      },
      size = 40,
      position = 'right',
    },
  },
  -- Set icons to characters that are more likely to work in every terminal.
  --    Feel free to remove or use ones that you like more! :)
  --    Don't feel like these are good choices.
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  ---@diagnostic disable-next-line: missing-fields
  controls = {
    -- Default is 'repl', which now lives in the toggled column — the control
    -- bar would be hidden with it. Console is always open.
    element = 'console',
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

-- Change breakpoint icons
-- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
-- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
-- local breakpoint_icons = vim.g.have_nerd_font
--     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
--   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
-- for type, icon in pairs(breakpoint_icons) do
--   local tp = 'Dap' .. type
--   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
--   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
-- end

-- termopen turns wrap off when a buffer becomes a terminal, undoing dapui's
-- setting. Use win_findbuf, not vim.wo: nvim-dap calls termopen inside
-- nvim_buf_call, so the focused window is not the console one.
vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'Re-enable wrap after a terminal takes over a dap buffer',
  group = vim.api.nvim_create_augroup('kickstart-dap-term-wrap', { clear = true }),
  callback = function(event)
    for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
      vim.wo[win].wrap = true
    end
  end,
})

-- Only the always-on layouts; 3 stays closed until <leader>dx.
dap.listeners.after.event_initialized['dapui_config'] = function()
  dapui.open { layout = 1 }
  dapui.open { layout = 2 }
end
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

-- Rust: launch the api-server under codelldb.
--
-- There is no auto-build here. VS Code's CodeLLDB `cargo` block is an
-- extension feature with no nvim-dap equivalent, and building synchronously
-- would freeze the editor for the length of an api-server build. So:
--
--   1. cargo build -p api-server      (in :terminal)
--   2. <F5>
--
-- No `env` block: the sidecar transport settings live in backend.dev.env,
-- which the binary reads itself via --env-file.
--
-- The WORKSPACE root, not the nearest crate. `Cargo.toml` as a marker would
-- stop at packages/api-server/, but cargo puts the binary in the workspace's
-- shared target/ directory. Here the git root and the workspace root are the
-- same directory, so `.git` is the reliable marker.
local function iris_root() return vim.fs.root(0, { '.git' }) or vim.fn.getcwd() end

dap.configurations.rust = {
  {
    name = 'api-server',
    type = 'codelldb',
    request = 'launch',
    program = function() return iris_root() .. '/target/debug/api-server' end,
    args = function() return { '--env-file', iris_root() .. '/backend.dev.env' } end,
    cwd = function() return iris_root() end,
    stopOnEntry = false,
  },
}

-- Sidecar (TypeScript on bun): ATTACH to the inspector port, don't launch.
-- The sidecar runs in its own tmux pane and keeps running; you connect and
-- disconnect at will. Start it with the address and path spelled out:
--
--   bun --watch --env-file=../../backend.dev.env --inspect=127.0.0.1:6499/iris run src/main.ts
--
-- The explicit 127.0.0.1 matters: given a bare port, bun binds IPv6 loopback
-- only and nothing can reach it on 127.0.0.1. The /iris suffix pins the path,
-- which is otherwise random per start.
--
-- NOT vscode-js-debug. That adapter speaks Node's V8 inspector protocol; bun
-- speaks WebKit's. Verified 2026-10-29 by driving both from a standalone DAP
-- client: Node's session goes live, bun's never binds a breakpoint. bun ships
-- no standalone adapter of its own (oven-sh/bun#22914), so this uses the
-- community bridge bun-dap-x, pinned at 0.2.4.
dap.adapters['bun-dap-x'] = {
  type = 'executable',
  command = 'bun-dap-x',
}

local sidecar_attach = {
  name = 'attach to sidecar (6499)',
  type = 'bun-dap-x',
  request = 'attach',
  url = 'ws://127.0.0.1:6499/iris',
  cwd = function() return iris_root() .. '/packages/agent-sidecar-bun' end,
}

dap.configurations.typescript = { sidecar_attach }
dap.configurations.javascript = { sidecar_attach }
