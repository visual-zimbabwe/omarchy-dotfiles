-- Dark Matter: Neovim Theme Configuration
return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      transparent = false,
      colors = {
        bg = "#000000",
        dark_bg = "#0A0906",
        darker_bg = "#050403",
        lighter_bg = "#14120E",

        fg = "#ECE6D8",
        dark_fg = "#7A7362",
        light_fg = "#FAF7EE",
        bright_fg = "#FFFFFF",
        muted = "#5C5648",

        red = "#E05A47",
        yellow = "#E5B842",
        orange = "#E68A38",
        green = "#7EBA68",
        cyan = "#4EB8BA",
        blue = "#5D93B8",
        magenta = "#A872D1",
        brown = "#6E4D30",

        bright_red = "#FF6E5A",
        bright_yellow = "#FFD05B",
        bright_green = "#98D87E",
        bright_cyan = "#6AD4D6",
        bright_blue = "#78B0D6",
        bright_magenta = "#C28BEA",

        accent = "#C9A050",
        cursor = "#FFFFFF",
        foreground = "#ECE6D8",
        background = "#000000",
        selection = "#26231C",
        selection_foreground = "#FFFDF8",
        selection_background = "#26231C",
      },
      on_highlights = function(hl, c)
        hl.Normal = { bg = "#000000", fg = c.fg }
        hl.NormalNC = { bg = "#0A0906", fg = c.dark_fg }
        hl.NormalFloat = { bg = "#0A0906", fg = c.fg }
        hl.FloatBorder = { bg = "#0A0906", fg = "#C9A050" }
        hl.CursorLine = { bg = "#14120E" }
        hl.CursorLineNr = { fg = "#C9A050", bold = true }
        hl.LineNr = { fg = "#5C5648" }
        hl.Visual = { bg = "#26231C", fg = "#FFFDF8", bold = true }
        hl.Pmenu = { bg = "#0A0906", fg = c.fg }
        hl.PmenuSel = { bg = "#26231C", fg = "#C9A050", bold = true }
        hl.PmenuThumb = { bg = "#38342A" }
        hl.StatusLine = { bg = "#0A0906", fg = c.fg }
        hl.StatusLineNC = { bg = "#050403", fg = c.muted }
        hl.TabLine = { bg = "#050403", fg = c.muted }
        hl.TabLineSel = { bg = "#0A0906", fg = "#C9A050", bold = true }
        hl.TabLineFill = { bg = "#000000" }
        hl.SignColumn = { bg = "#000000" }
        hl.GitSignsAdd = { fg = c.green }
        hl.GitSignsChange = { fg = c.yellow }
        hl.GitSignsDelete = { fg = c.red }
        hl.TelescopeBorder = { bg = "#0A0906", fg = "#38342A" }
        hl.TelescopePromptBorder = { bg = "#14120E", fg = "#C9A050" }
        hl.TelescopePromptNormal = { bg = "#14120E", fg = c.fg }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
