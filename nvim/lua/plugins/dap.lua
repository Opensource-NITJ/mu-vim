-- =============================================================================
--                             DEBUGGER (DAP) SETTINGS
-- =============================================================================
-- Configures the Debug Adapter Protocol (DAP) for debugging code inside Neovim.
-- Includes:
--   - nvim-dap (Core debugger client)
--   - nvim-dap-ui (Rich IDE-like debug panel UI)
--   - nvim-dap-virtual-text (Inline variable evaluations as you step through code)
-- Pre-configured adapters:
--   - Python (via Mason debugpy)
--   - C/C++ (via Mason codelldb)
--   - Lua (via local-lua-debugger)
-- =============================================================================

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- Required dependency for dap-ui
      "theHamsta/nvim-dap-virtual-text",
      "mason-org/mason.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local virtual_text = require("nvim-dap-virtual-text")

      -- Initialize virtual text (displays variable states inline in code editor)
      virtual_text.setup({})

      -- Initialize DAP UI
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
          },
        },
      })

      -- Automatically open/close DAP UI when debugging starts/stops
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Customize breakpoint icons
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "Visual", numhl = "Visual" })

      -- --- 1. Python Debugger Config ---
      -- Uses Mason's `debugpy` package.
      dap.adapters.python = function(cb, config)
        if config.request == "attach" then
          local port = (config.connect or config).port
          local host = (config.connect or config).host or "127.0.0.1"
          cb({
            type = "server",
            port = assert(port, "`connect.port` is required for a python attach configuration"),
            host = host,
            options = { source_filetype = "python" },
          })
        else
          cb({
            type = "executable",
            command = vim.fn.has("win32") == 1
                and vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/Scripts/python.exe"
                or vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
            args = { "-m", "debugpy.adapter" },
            options = { source_filetype = "python" },
          })
        end
      end

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch Current File",
          program = "${file}",
          pythonPath = function()
            -- Check for virtual environments in the current working directory
            local cwd = vim.fn.getcwd()
            if vim.fn.has("win32") == 1 then
              if vim.fn.executable(cwd .. "\\venv\\Scripts\\python.exe") == 1 then
                return cwd .. "\\venv\\Scripts\\python.exe"
              elseif vim.fn.executable(cwd .. "\\.venv\\Scripts\\python.exe") == 1 then
                return cwd .. "\\.venv\\Scripts\\python.exe"
              end
              return "python"
            else
              if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
                return cwd .. "/venv/bin/python"
              elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                return cwd .. "/.venv/bin/python"
              end
              return "python3"
            end
          end,
        },
      }

      -- --- 2. C/C++ Debugger Config ---
      -- Uses Mason's `codelldb` package.
      -- NOTE FOR WINDOWS NATIVE USERS:
      -- Native Windows compilation (MSVC or MinGW) must be set up properly on the host machine.
      -- CodeLLDB requires the C++ compiler's debugging symbols (.pdb or dwarf symbols) to load.
      -- If codelldb fails to download via Mason on Windows, download the Windows release package (.vsix)
      -- manually from: https://github.com/vadimcn/codelldb/releases and install/extract it.
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.has("win32") == 1
              and vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb.exe"
              or vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.cpp = {
        {
          name = "Launch C/C++ Executable",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to binary/executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp

      -- --- 3. Lua Debugger Config ---
      -- Uses Mason's `local-lua-debugger-vscode` package.
      dap.adapters.local_lua = {
        type = "executable",
        command = "node",
        args = {
          vim.fn.stdpath("data") .. "/mason/packages/local-lua-debugger-vscode/extension/extension/debugAdapter.js",
        },
      }

      dap.configurations.lua = {
        {
          name = "Debug Current Lua File",
          type = "local_lua",
          request = "launch",
          program = {
            lua = "lua",
            file = "${file}",
          },
          files = {},
        },
      }

      -- --- Keymaps (All with `desc` for Which-Key visualization) ---
      local keymap = vim.keymap.set
      local opts = { silent = true }

      keymap("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
      keymap("n", "<leader>dB", function()
        vim.ui.input({ prompt = "Breakpoint condition: " }, function(input)
          if input and input ~= "" then
            dap.set_breakpoint(input)
          end
        end)
      end, { desc = "DAP: Conditional Breakpoint" })
      keymap("n", "<leader>dc", dap.continue, { desc = "DAP: Continue / Start" })
      keymap("n", "<leader>di", dap.step_into, { desc = "DAP: Step Into" })
      keymap("n", "<leader>do", dap.step_over, { desc = "DAP: Step Over" })
      keymap("n", "<leader>dO", dap.step_out, { desc = "DAP: Step Out" })
      keymap("n", "<leader>dt", dap.terminate, { desc = "DAP: Terminate" })
      keymap("n", "<leader>du", dapui.toggle, { desc = "DAP: Toggle Debug UI" })
      keymap("n", "<leader>de", dapui.eval, { desc = "DAP: Evaluate variable under cursor" })
    end,
  },
}
