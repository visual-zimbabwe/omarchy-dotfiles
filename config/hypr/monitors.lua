-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Detect whether we are on a laptop with an internal eDP display
local has_edp = false
local edp_check = io.open("/sys/class/drm/card0-eDP-1/status", "r") or io.open("/sys/class/drm/card1-eDP-1/status", "r")
if edp_check then
  has_edp = true
  edp_check:close()
end

if has_edp then
  -- Laptop internal OLED display (2.8K @ 120Hz, scaled for HiDPI)
  hl.env("GDK_SCALE", "2")
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
else
  -- Desktop machine (Dell XPS with standard DPI 1440p / 1.0 scale)
  hl.env("GDK_SCALE", "1")
  hl.monitor({
    output = "DP-2",
    mode = "2560x1440@120",
    position = "0x0",
    scale = 1.0,
  })

  hl.monitor({
    output = "DP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1.0,
  })

  hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "0x0",
    scale = 1.0,
  })
end

-- Fallback for any other newly connected display
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.0,
})
