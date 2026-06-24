-- =============================================================================
--                               UI PLUGINS
-- =============================================================================
-- Configures the visual appearance of mu-vim.
-- Includes:
--   1. Catppuccin Mocha (Default colorscheme)
--   2. Lualine (Aesthetic status line at the bottom)
--   3. Alpha (Minimal startup dashboard with μ logo, buttons, and rotating tips)
-- =============================================================================

return {
  -- --- 1. Colorscheme: Catppuccin ---
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Load this plugin first on startup
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- Mocha is the dark theme (non-negotiable)
        transparent_background = false,
        integrations = {
          alpha = true,
          cmp = true,
          gitsigns = true,
          indent_blankline = {
            enabled = true,
            scope_color = "lavender", -- highlight active indent with lavender
          },
          mason = true,
          neotree = true,
          treesitter = true,
          which_key = true,
          dap = true,
          dap_ui = true,
        },
      })
      -- Apply Catppuccin as the default colorscheme
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- --- 2. Statusline: Lualine ---
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin", -- matching Catppuccin theme
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = { "alpha" }, -- Disable statusline on dashboard
          },
        },
        sections = {
          lualine_a = { { "mode", separator = { left = "", right = "" } } },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } }, -- Path = 1 shows relative file path
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { { "location", separator = { left = "", right = "" } } },
        },
      })
    end,
  },

  -- --- 3. Dashboard: Alpha-nvim ---
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      -- The stylized Greek letter mu (μ) header in Catppuccin Mocha Lavender
      dashboard.section.header.val = {
        " ",
        "     ██╗    ██╗        ██╗   ██╗██╗███╗   ███╗",
        "     ██║    ██║        ██║   ██║██║████╗ ████║ compact",
        "     ██║    ██║ █████╗ ██║   ██║██║██╔████╔██║ opinionated",
        "     ████████╔╝ ╚════╝ ╚██╗ ██╔╝██║██║╚██╔╝██║ atomically customizable",
        "     ██╔═════╝          ╚████╔╝ ██║██║ ╚═╝ ██║ made with ♡",
        "     ╚═╝                 ╚═══╝  ╚═╝╚═╝     ╚═╝",
        " ",
      }

      -- Custom color highlighting for the header (Lavender)
      vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#b4befe" })
      dashboard.section.header.opts.hl = "AlphaHeader"

      -- Quick access buttons
      dashboard.section.buttons.val = {
        dashboard.button("n", "󰏪  New File", "<cmd>ene <BAR> startinsert <CR>"),
        dashboard.button("f", "󰈞  Find File", "<cmd>Telescope find_files<CR>"),
        dashboard.button("r", "󰄉  Recent Files", "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
      }

      -- Set color for buttons
      vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#cdd6f4" })
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaHeader"
      end

      -- Curated rotating footer items: Vim tips, resource links, and motivational lines
      local footer_items = {
        -- --- Vim Tips ---
        "Tip: Learn motions like 'ciw' (change inner word) to edit text incredibly fast!",
        "Tip: Use 'u' to undo, 'Ctrl+r' to redo. Undo history is saved to disk and persists!",
        "Tip: Press 'Ctrl+h/j/k/l' to easily jump between open window splits.",
        "Tip: Use 'Shift+h' and 'Shift+l' to cycle between active buffers (open files).",
        "Tip: Press '<leader>e' to toggle the Neo-tree file sidebar explorer.",
        "Tip: Type ':%s/old/new/g' to search and replace all instances of 'old' with 'new' in the file.",
        "Tip: Learn 'd' followed by a motion to delete. e.g. 'dt,' deletes until a comma.",
        "Tip: In visual mode, use '>' and '<' to shift code indentations without losing selection.",
        "Tip: Use '*' to search for the word currently under your cursor.",
        "Tip: Press 'gd' over a symbol to jump directly to its definition (LSP power!).",
        "Tip: Use '<leader>ff' to find files instantly using Telescope search.",
        "Tip: Press '<leader>ca' to open LSP Code Actions for quick refactoring fixes.",
        "Tip: Running 'vimtutor' in your terminal is the absolute best way to learn basic Vim keys.",
        "Tip: To comment lines, use 'gcc' in normal mode or 'gc' in visual mode.",
        "Tip: Use '<leader>db' to set a debugging breakpoint, and '<leader>dc' to start debugging.",
        "Tip: Toggle GitHub Copilot suggestions using '<leader>cp'.",
        "Tip: Use '<leader>cc' to open the Copilot Chat interface.",
        "Tip: Keep your hands on the home row! Use 'hjkl' instead of the arrow keys.",
        -- --- Resource Links ---
        "Resource: Run 'vimtutor' in your terminal to practice core movement skills.",
        "Resource: Read the interactive tutorial at github.com/iggredible/Learn-Vim",
        "Resource: Watch TJ DeVries' Youtube channel for Neovim deep dives & tips.",
        "Resource: Watch Typecraft's 'Neovim for Beginners' series to master the editor.",
        "Resource: Play Vim Adventures (vim-adventures.com) to gamify learning motions.",
        "Resource: Browse the official documentation inside Neovim by typing ':help'.",
        -- --- Motivational Lines ---
        "Motivation: 'The only way to write fast code is to write code fast.' — Keep practicing!",
        "Motivation: Every developer was once a beginner. Take it one shortcut at a time.",
        "Motivation: Learning Vim keyboard motions is an investment that pays off for life!",
        "Motivation: Customizing your editor is the programmer's ultimate superpower.",
      }

      -- Pick a random item on launch
      math.randomseed(os.time())
      local random_index = math.random(1, #footer_items)
      dashboard.section.footer.val = footer_items[random_index]
      
      -- Format footer style (Catppuccin Lavender/Muted Pink color)
      vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#f5c2e7", italic = true })
      dashboard.section.footer.opts.hl = "AlphaFooter"

      alpha.setup(dashboard.opts)
    end,
  },
}
