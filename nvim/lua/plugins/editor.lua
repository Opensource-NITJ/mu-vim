-- =============================================================================
--                             EDITOR CORE UTILITIES
-- =============================================================================
-- Essential coding helpers: syntax highlighting, brackets, and indent guides.
-- Includes:
--   1. Treesitter (Better syntax coloring & structure understanding)
--   2. Autopairs (Auto-inserts matching close bracket/quote)
--   3. TS Autotag (Auto-closes HTML/XML tags using Treesitter)
--   4. Indent-Blankline (Visual lines highlighting code indent levels)
-- =============================================================================

return {
  -- --- 1. Syntax Highlighting: Treesitter ---
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")
      configs.setup({
        -- Automatically install parser for these standard developer languages
        ensure_installed = {
          "lua",
          "python",
          "c",
          "cpp",
          "bash",
          "html",
          "css",
          "javascript",
          "typescript",
          "markdown",
          "markdown_inline",
        },
        sync_install = true,
        highlight = {
          enable = true,       -- Enable syntax highlighting
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,        -- Enable smart auto-indentation based on Treesitter
        },
      })
    end,
  },

  -- --- 2. Bracket Auto-pairs ---
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true, -- Enable Treesitter check inside pairs
      })
    end,
  },

  -- --- 3. Tag Auto-close (HTML/XML/JSX) ---
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "InsertEnter",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },

  -- --- 4. Indent Guides: Indent-Blankline ---
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      -- Version 3.x setup
      require("ibl").setup({
        indent = {
          char = "│", -- The vertical line character
        },
        scope = {
          enabled = true,
          show_start = false,
          show_end = false,
        },
      })
    end,
  },

  -- --- 5. Easy Comments: Comment.nvim ---
  -- Map 'gcc' to comment current line, and 'gc' to comment selected block in visual mode.
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },
}
