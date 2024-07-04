-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.color_scheme = 'Kanagawa (Gogh)'
config.font = wezterm.font('CaskaydiaCove NF')
config.font_size = 14
config.enable_tab_bar = false
config.initial_rows = 36
config.initial_cols = 120

-- and finally, return the configuration to wezterm
return config

