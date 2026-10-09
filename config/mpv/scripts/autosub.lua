-- autosub.lua: Automatic and on-demand subtitle downloader for mpv
-- Hotkey: Press 'b' or 'Ctrl+s' to download / cycle next English subtitle track

local utils = require 'mp.utils'
local msg = require 'mp.msg'

local current_track_idx = 0
local script_path = mp.find_config_file("scripts/fetch_subtitles.py") or (os.getenv("HOME") .. "/.config/mpv/scripts/fetch_subtitles.py")

local function get_best_title()
    local title = mp.get_property("media-title")
    if not title or title == "" or title:find("^http") or title:find("^/") then
        title = mp.get_property("filename") or ""
    end
    return title
end

local function has_subtitles()
    local track_list = mp.get_property_native("track-list") or {}
    for _, track in ipairs(track_list) do
        if track["type"] == "sub" then
            return true
        end
    end
    return false
end

local function download_subtitles(track_idx, is_manual)
    local title = get_best_title()
    if not title or title == "" then
        if is_manual then
            mp.osd_message("Cannot identify media title for subtitles", 3)
        end
        return
    end

    if is_manual then
        mp.osd_message("🔍 Searching English subtitles...", 3)
    end

    local cmd_args = { "python3", script_path, title, tostring(track_idx) }

    mp.command_native_async({
        name = "subprocess",
        args = cmd_args,
        capture_stdout = true,
        capture_stderr = true
    }, function(success, res, err)
        if success and res and res.status == 0 and res.stdout then
            local sub_path = res.stdout:gsub("^%s*(.-)%s*$", "%1")
            if sub_path ~= "" then
                mp.commandv("sub-add", sub_path, "select")
                mp.set_property("sub-visibility", "yes")
                mp.osd_message("✔ English subtitles active (Track " .. (track_idx + 1) .. ")", 4)
                msg.info("Successfully loaded subtitle: " .. sub_path)
                return
            end
        end

        if is_manual then
            mp.osd_message("❌ No English subtitles found", 3)
        end
    end)
end

local function on_file_loaded()
    mp.add_timeout(1.0, function()
        if not has_subtitles() then
            download_subtitles(0, false)
        end
    end)
end

local function manual_fetch()
    current_track_idx = current_track_idx + 1
    download_subtitles(current_track_idx, true)
end

mp.register_event("file-loaded", on_file_loaded)
mp.add_key_binding("b", "download-subtitles", manual_fetch)
mp.add_key_binding("Ctrl+s", "download-subtitles-ctrl", manual_fetch)

msg.info("autosub.lua loaded.")
