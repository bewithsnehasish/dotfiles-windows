-- Mirrors %APPDATA%\alacritty\alacritty.toml so both terminals look the same
local wezterm = require "wezterm"
local act = wezterm.action

return {
  default_prog = { "pwsh", "-NoLogo" },

  font = wezterm.font_with_fallback { "Maple Mono NF", "JetBrainsMono NFM" },
  font_size = 12.0,
  window_padding = { left = 10, right = 10, top = 10, bottom = 10 },
  default_cursor_style = "SteadyBar",

  -- No title bar; the tab bar holds the window buttons and drags the window when it floats
  window_decorations = "INTEGRATED_BUTTONS|RESIZE",

  -- Same palette as alacritty/catppuccin-mocha.toml
  colors = {
    foreground = "#bfbdb6",
    background = "#0b0e14",
    cursor_bg = "#bfbdb6",
    cursor_fg = "#0b0e14",
    selection_fg = "#bfbdb6",
    selection_bg = "#1b3a5b",
    ansi = { "#1e232b", "#ea6c73", "#7fd962", "#f9af4f", "#53bdfa", "#cda1fa", "#90e1c6", "#c7c7c7" },
    brights = { "#686868", "#f07178", "#aad94c", "#ffb454", "#59c2ff", "#d2a6ff", "#95e6cb", "#ffffff" },
  },

  -- Tabs at the bottom, hidden when only one tab is open (Ctrl+Shift+B shows it to drag the window)
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = true,

  keys = {
    { key = "F11", action = act.ToggleFullScreen },
    { key = "v", mods = "CTRL", action = act.PasteFrom "Clipboard" },
    { key = "UpArrow", mods = "SHIFT", action = act.ScrollByPage(-1) },
    { key = "DownArrow", mods = "SHIFT", action = act.ScrollByPage(1) },
    { key = "UpArrow", mods = "CTRL", action = act.ScrollToTop },
    { key = "Enter", mods = "SHIFT", action = act.SendString "\x1b\r" },
    -- Show or hide the tab bar in this window, to drag it around while it floats
    { key = "b", mods = "CTRL|SHIFT", action = wezterm.action_callback(function(window)
      local o = window:get_config_overrides() or {}
      if o.hide_tab_bar_if_only_one_tab == false then
        o.hide_tab_bar_if_only_one_tab = nil
      else
        o.hide_tab_bar_if_only_one_tab = false
      end
      window:set_config_overrides(o)
    end) },
  },
}
