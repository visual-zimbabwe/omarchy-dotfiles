-- Dark Matter: Hyprland configuration
-- Designed for deep pitch-black void (#000000) canvas with obsidian (#0A0906) window accents.

local active_border_color = {
  colors = { "rgba(C9A050ee)", "rgba(0A0906ee)" },
  angle = 45,
}

local inactive_border_color = {
  colors = { "rgba(1A1813aa)", "rgba(0A0906aa)" },
  angle = 90,
}

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 2,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    rounding = 12,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.96,

    shadow = {
      enabled = true,
      range = 24,
      render_power = 4,
      offset = "0 2",
      color = "rgba(00000099)",
      color_inactive = "rgba(00000066)",
    },

    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      new_optimizations = true,
      xray = false,
      contrast = 1.05,
      brightness = 0.9,
      noise = 0.01,
      vibrancy = 0.25,
      vibrancy_darkness = 0.3,
      popups = true,
      special = true,
    },
  },
})

-- Layer rules for Omarchy shell surfaces: frosted glass against the black canvas
hl.layer_rule({
  match = { namespace = "^(omarchy-bar|omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-clipboard|omarchy-emojis|omarchy-image-selector|omarchy-keyboard-panel|omarchy-network-qr)$" },
  blur = true,
  ignore_alpha = 0.25,
})
