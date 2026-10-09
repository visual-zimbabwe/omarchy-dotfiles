-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal OLED display (2.8K @ 120Hz, scaled for HiDPI)
hl.monitor({
  output = "eDP-1",
  mode = "2880x1800@120",
  position = "0x0",
  scale = 1.6,
})

-- Samsung Odyssey G91SD / External Ultrawide Display (Above laptop)
hl.monitor({
  output = "HDMI-A-1",
  mode = "preferred",
  position = "auto-up",
  scale = 1.0,
  vrr = 1,
})

-- DisplayPort / USB-C connection fallback for external monitor
hl.monitor({
  output = "DP-1",
  mode = "preferred",
  position = "auto-up",
  scale = 1.0,
  vrr = 1,
})
hl.monitor({
  output = "DP-2",
  mode = "preferred",
  position = "auto-up",
  scale = 1.0,
  vrr = 1,
})

-- Fallback for any other newly connected display
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.0,
})
