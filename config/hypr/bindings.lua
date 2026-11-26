-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

o.bind("SUPER + N", "Notification Center", "omarchy-shell jankeesvw.notification-center toggle")
o.bind("SUPER + CTRL + J", "omanki", "omarchy-shell shell toggle yamz8.omanki")

-- Restore classic Hyprland global workspaces (1-10 shared across all monitors),
-- disabling Omarchy's per-monitor workspace blocks (default/hypr/monitor-workspaces.lua).
if o.workspaces then
  o.workspaces.reconcile = function() end
  function o.workspaces.workspace_id(_, slot)
    return slot
  end
  function o.workspaces.focus(slot)
    return hl.dsp.focus({ workspace = tostring(slot) })
  end
  function o.workspaces.move_window(slot, follow)
    return hl.dsp.window.move({ workspace = tostring(slot), follow = follow ~= false })
  end
  function o.workspaces.move_to_monitor(direction)
    return function()
      local target = hl.get_monitor(direction)
      if target then
        hl.dispatch(hl.dsp.workspace.move({ monitor = target.name }))
      end
    end
  end
end

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = true }))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

o.rebind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.rebind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.rebind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))
o.rebind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
o.rebind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

o.rebind("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", o.workspaces.move_to_monitor("l"))
o.rebind("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", o.workspaces.move_to_monitor("r"))
o.rebind("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", o.workspaces.move_to_monitor("u"))
o.rebind("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", o.workspaces.move_to_monitor("d"))

