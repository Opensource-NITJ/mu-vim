-- =============================================================================
--                                WEZTERM CONFIG
-- =============================================================================
-- This is a clean, modern WezTerm configuration preconfigured with Catppuccin Mocha,
-- JetBrains Mono Nerd Font, and sensible cross-platform rendering defaults.
--
-- For details and documentation, see: https://wezfurlong.org/wezterm/
-- =============================================================================

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- --- 1. System & Rendering Defaults (Wayland & X11 Safe) ---
-- Ensures WezTerm runs cleanly across Linux display servers and macOS.
config.front_end = "WebGpu" -- Use fast GPU rendering
config.webgpu_power_preference = "HighPerformance"

-- --- 2. Styling & Theme ---
-- Catppuccin Mocha is the default theme (non-negotiable).
config.color_scheme = "Catppuccin Mocha"

-- Window appearance customizations
config.window_background_opacity = 0.60 -- Translucent background (0.0 to 1.0)
config.win32_system_backdrop = "Acrylic" -- Premium blur effect on Windows (Acrylic/Mica/Tabbed/Disable)
config.window_padding = {
  left = 12,
  right = 12,
  top = 12,
  bottom = 12,
}

-- --- 3. Typography ---
-- JetBrains Mono Nerd Font is highly legible and includes code icons.
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13.0

-- Disable cursor blinking for performance (or set to true if preferred)
config.cursor_blink_rate = 800

-- --- 4. Tab Bar ---
-- Enable a clean, minimal tab bar at the top of the terminal.
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false

-- --- 5. WSL2 Configuration ---
-- For Windows users running WSL2, you can configure WezTerm to open
-- directly into your WSL environment (e.g. Ubuntu) by uncommenting the line below:
-- config.default_domain = 'WSL:Ubuntu'

-- --- 6. Custom Key Bindings Section ---
-- Default shortcuts for splits, copy/paste, and tabs are enabled.
-- You can add custom hotkeys below using the keys table.
config.keys = {
  -- Example: press Alt+v to split window vertically
  -- { key = 'v', mods = 'ALT', action = wezterm.action.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
  -- Example: press Alt+h to split window horizontally
  -- { key = 'h', mods = 'ALT', action = wezterm.action.SplitVertical{ domain = 'CurrentPaneDomain' } },
}

return config
