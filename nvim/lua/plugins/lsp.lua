-- =============================================================================
--                             LSP CONFIGURATION
-- =============================================================================
-- Sets up Language Server Protocol (LSP) for code intelligence:
--   - Autocomplete suggestions
--   - Jump to definition (gd)
--   - Documentation popup on hover (K)
--   - Refactoring actions (<leader>ca)
--   - Linting & formatting diagnostics
-- Uses Mason to manage language server binaries.
-- Only installs: lua_ls, pyright, clangd, bashls (no bloat).
-- =============================================================================

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      -- Shows visual loading status for LSP servers
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      -- Define LSP keymaps when a language server attaches to a buffer
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, silent = true }

        -- Helper to add descriptions for Which-Key
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, silent = true, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gi", vim.lsp.buf.implementation, "Go to implementation")
        map("gr", require("telescope.builtin").lsp_references, "Find references")
        map("K", vim.lsp.buf.hover, "Hover documentation")
        map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code actions")
        map("<leader>cd", vim.diagnostic.open_float, "Show line diagnostics")
        map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next diagnostic")
      end

      -- Make sure autocompletion capabilities are integrated
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if cmp_status then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      -- Configure diagnostics borders (make them look rounded and premium)
      vim.diagnostic.config({
        float = { border = "rounded" },
      })
      -- Configure hover and signature help borders (rounded/premium)
      vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
        config = config or {}
        config.border = "rounded"
        return vim.lsp.handlers.hover(err, result, ctx, config)
      end
      vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
        config = config or {}
        config.border = "rounded"
        return vim.lsp.handlers.signature_help(err, result, ctx, config)
      end

      -- Initialize Mason
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "→",
            package_uninstalled = "✗",
          },
        },
      })

      -- Bind Mason with lspconfig
      require("mason-lspconfig").setup({
        -- Only install core servers requested by the strategy
        ensure_installed = {
          "lua_ls",  -- Lua (for editor scripting)
          "pyright", -- Python
          "clangd",  -- C/C++
          "bashls",  -- Bash / Shell scripts
        },
        automatic_installation = true,
      })

      -- Configure each individual server
      local lspconfig = require("lspconfig")

      -- 1. Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- 2. C/C++
      lspconfig.clangd.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- 3. Bash/Shell
      lspconfig.bashls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- 4. Lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = {
              -- Recognize the `vim` global variable used in Neovim configuration
              globals = { "vim" },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })
    end,
  },
}
