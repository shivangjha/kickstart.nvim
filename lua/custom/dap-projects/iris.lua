-- Launch targets for the iris repo. Applied only when backend.dev.env sits in
-- the git root.

return {
  marker = 'backend.dev.env',

  configurations = function(root)
    -- No auto-build. VS Code's CodeLLDB `cargo` block has no nvim-dap
    -- equivalent, so run `cargo build -p api-server` first, then <F5>.
    local api_server = {
      name = 'api-server',
      type = 'codelldb',
      request = 'launch',
      program = function() return root .. '/target/debug/api-server' end,
      args = function() return { '--env-file', root .. '/backend.dev.env' } end,
      cwd = function() return root end,
      stopOnEntry = false,
    }

    -- Attach, not launch: the sidecar runs in its own tmux pane. Start it with
    --   bun --watch --env-file=../../backend.dev.env --inspect=127.0.0.1:6499/iris run src/main.ts
    -- The explicit 127.0.0.1 matters; a bare port binds IPv6 loopback only.
    local sidecar = {
      name = 'attach to sidecar (6499)',
      type = 'bun-dap-x',
      request = 'attach',
      url = 'ws://127.0.0.1:6499/iris',
      cwd = function() return root .. '/packages/agent-sidecar-bun' end,
    }

    return {
      rust = { api_server },
      typescript = { sidecar },
      javascript = { sidecar },
    }
  end,
}
