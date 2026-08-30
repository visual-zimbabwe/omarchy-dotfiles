-- Oligarchy — propaganda-poster light theme.
-- Drives aether.nvim (the colorscheme Omarchy's own neovim.lua template targets)
-- with the poster palette, so the theme carries no upstream dependency of its own.
return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        -- Paper ramp: lightest -> darkest, as a light theme should read.
        bg = "#eae0cb",
        dark_bg = "#e2d7bf",
        darker_bg = "#d8ccb0",
        lighter_bg = "#f0e8d4",

        -- Ink ramp.
        fg = "#1a160f",
        dark_fg = "#6b6152",
        light_fg = "#3b342a",
        bright_fg = "#1a160f",
        muted = "#6b6152",

        red = "#b0281e",
        yellow = "#a9791f",
        orange = "#a9791f",
        green = "#5e6b33",
        cyan = "#2e6e6a",
        blue = "#3e5a78",
        magenta = "#7e3b4e",
        brown = "#553d10",

        bright_red = "#c0271c",
        bright_yellow = "#c99a3a",
        bright_green = "#77863f",
        bright_cyan = "#3e8a84",
        bright_blue = "#4e7095",
        bright_magenta = "#9a5266",

        accent = "#c0271c",
        cursor = "#c0271c",
        foreground = "#1a160f",
        background = "#eae0cb",

        -- Red banner, cream text — as on the poster.
        selection = "#c0271c",
        selection_foreground = "#eae0cb",
        selection_background = "#c0271c",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
