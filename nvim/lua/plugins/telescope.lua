-- =============================================================================
--                               TELESCOPE FUZZY FINDER
-- =============================================================================
-- Telescope is the ultimate tool for finding files, searching strings,
-- and navigating the project workspace.
-- =============================================================================

return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          path_display = { "truncate" },
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous, -- move to prev result with Ctrl+k
              ["<C-j>"] = actions.move_selection_next,     -- move to next result with Ctrl+j
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            },
          },
        },
      })

      -- Load native fuzzy-finding extension if compilation succeeded
      pcall(telescope.load_extension, "fzf")

      -- --- Keymaps (All with `desc` for Which-Key visualization) ---
      local keymap = vim.keymap.set
      keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files in workspace" })
      keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Find recent files" })
      keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Find string in workspace (grep)" })
      keymap("n", "<leader>fc", "<cmd>Telescope grep_string<CR>", { desc = "Find string under cursor" })
      keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find open buffers (files)" })
      keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Search help documentation" })
      keymap("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "Search active keymaps" })
    end,
  },
}
