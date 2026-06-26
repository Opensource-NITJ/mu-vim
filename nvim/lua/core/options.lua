-- =============================================================================
--                               EDITOR OPTIONS
-- =============================================================================
-- This file configures standard Neovim behavior (indentation, search, UI, etc.).
-- These options are chosen to feel intuitive to users coming from VS Code
-- or other graphical text editors while preserving Vim's keyboard power.
-- =============================================================================

local opt = vim.opt

-- --- 1. Line Numbers ---
opt.number = true          -- Show line numbers on the gutter
opt.relativenumber = true  -- Show relative numbers (great for learning vertical movement)

-- --- 2. Indentation & Spacing ---
opt.tabstop = 4            -- 1 tab = 4 spaces
opt.shiftwidth = 4         -- Number of spaces for auto-indentation
opt.expandtab = true       -- Convert tabs to spaces
opt.autoindent = true      -- Copy indent from current line when starting a new one
opt.smartindent = true     -- Make indenting smart for programming languages

-- --- 3. Clipboard Integration ---
-- Allows Neovim to share clipboard with your operating system.
-- Yanking (y) will copy to system clipboard, and pasting (p) will paste from it.
opt.clipboard = "unnamedplus"

-- --- 4. Mouse Support ---
-- Highly recommended for beginners! Allows scrolling, selecting text,
-- and switching windows/buffers with the mouse.
opt.mouse = "a"

-- --- 5. Search Behavior ---
opt.ignorecase = true      -- Ignore case when searching...
opt.smartcase = true       -- ...unless search query contains uppercase letters
opt.hlsearch = true        -- Highlight all matches of the search query
opt.incsearch = true       -- Show matches as you type the query

-- --- 6. UI & Appearance ---
opt.termguicolors = true   -- Enable 24-bit RGB colors in terminal (required for Catppuccin)
opt.cursorline = true      -- Highlight the line under the cursor (visually identifies position)
opt.signcolumn = "yes"     -- Always show sign column (prevents text shifting for LSP/git icons)
opt.wrap = false           -- Do not wrap long lines automatically
opt.scrolloff = 8          -- Keep at least 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8      -- Keep at least 8 columns to the left/right of cursor

-- --- 7. Window Splits ---
opt.splitbelow = true      -- Horizontal splits open below the current window
opt.splitright = true      -- Vertical splits open to the right of the current window

-- --- 8. File History & Safety ---
opt.swapfile = false       -- Do not create .swp files (prevents recovery warnings)
opt.backup = false         -- Do not create backup files
opt.writebackup = false    -- Do not write backup before overwriting a file
opt.undofile = true        -- Enable persistent undo history (saves undo history to disk)

-- --- 9. Key Combo Timeouts ---
-- The time (in milliseconds) to wait for a mapped sequence to complete.
-- Helps Which-Key trigger faster when you pause typing.
opt.timeoutlen = 300

-- --- 10. Autocomplete Options ---
opt.completeopt = "menu,menuone,noselect" -- Modern menu completion defaults

-- --- 11. Windows Shell Guard ---
-- Ensures Neovim uses pwsh (PowerShell Core) instead of cmd.exe on Windows hosts.
-- This is critical for Mason installations, build steps, and terminal execution.
if vim.fn.has("win32") == 1 then
  opt.shell = "pwsh"
  opt.shellcmdflag = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -Command"
  opt.shellxquote = ""
end
