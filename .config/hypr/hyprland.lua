-- Hyprland configuration (Lua format — since 0.55 the hyprlang .conf format
-- is deprecated).
-- Docs: https://wiki.hypr.land/Configuring/Start/
--
-- Machine-local, user-editable modules (seeded from *.template.lua by krypt,
-- see [[template]] in .krypt.toml). Edit those files, not this one, for app
-- defaults / input / monitors.
require("monitors")
require("workspaces")
local apps = require("apps")
require("input")

-- Execute your favorite apps at launch
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Breeze_Light 24")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)

-- Set cursor theme and size
hl.env("HYPRCURSOR_THEME", "Breeze_Light")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Breeze_Light")
hl.env("XCURSOR_SIZE", "24")

-- Themes related
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.config({
    misc = {
        disable_hyprland_logo = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,

        vrr = true,
    },

    debug = {
        vfr = true,
    },

    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(33ccff)", "rgb(00ff99)" }, angle = 45 },
            inactive_border = "rgb(595959)",
        },

        layout = "dwindle",
    },

    decoration = {
        rounding = 4,
        blur = { enabled = false },
        shadow = { enabled = false },
    },

    animations = {
        enabled = false,
    },

    dwindle = {
        preserve_split = true,
    },
})

-- Red border when fullscreen
hl.window_rule({
    match = { fullscreen = true },
    border_color = { colors = { "rgb(ff9e64)", "rgb(880808)" }, angle = 45 },
})

-- WINE STUFF: hide explorer.exe windows
local wine = { class = "^(explorer.exe)$" }
hl.window_rule({ match = wine, opacity = "0.0 override 0.0 override" })
hl.window_rule({ match = wine, move = { 0, 0 } })
hl.window_rule({ match = wine, no_anim = true })
hl.window_rule({ match = wine, no_focus = true })
hl.window_rule({ match = wine, no_initial_focus = true })
hl.window_rule({ match = wine, workspace = "10 silent" })

-- Force some apps/windows to be floating
for _, cls in ipairs({
    "^(blueman-manager)$",
    "^(nm-connection-editor)$",
    "^(nwg-displays)$",
    "^(nwg-look)$",
    "^(org.kde.kcalc)$",
}) do
    hl.window_rule({ match = { class = cls }, float = true })
end
for _, title in ipairs({
    "^(Calculator)(.*)$",
    "^(Friends List)(.*)$",
    "^(MetaMask)(.*)$",
    "^(Steam - News)(.*)$",
    "^(btop)(.*)$",
}) do
    hl.window_rule({ match = { title = title }, float = true })
end
hl.window_rule({ match = { class = "floating|bloating" }, float = true })
hl.window_rule({ match = { class = "floating" }, size = { 800, 600 } })
hl.window_rule({ match = { class = "bloating" }, size = { 1024, 768 } })

-- Hide the sharing screen window
local share = { title = "^(.*)(is sharing your screen.)$" }
hl.window_rule({ match = share, opacity = "0.0 override 0.0 override" })
hl.window_rule({ match = share, move = { 0, 0 } })
hl.window_rule({ match = share, no_anim = true })
hl.window_rule({ match = share, no_focus = true })
hl.window_rule({ match = share, no_initial_focus = true })
hl.window_rule({ match = share, workspace = "10 silent" })

-- Send apps to their workspaces
local workspace_rules = {
    { "2 silent", { "^(.*)discord.com(.*)$", "^(.*)teams.microsoft.com(.*)$", "^(.*)teams.cloud.microsoft(.*)$", "discord", "org.telegram.desktop", "teams-for-linux" } },
    { "3 silent", { "org.mozilla.Thunderbird" } },
    { "7 silent", { "Exodus", "Navcoin-Qt" } },
    { "8 silent", { "lutris", "steam" } },
    { "9 silent", { "^(.*)open.spotify.com(.*)$", "obs", "spotify" } },
}
for _, entry in ipairs(workspace_rules) do
    local ws, classes = entry[1], entry[2]
    for _, cls in ipairs(classes) do
        hl.window_rule({ match = { class = cls }, workspace = ws })
    end
end

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
local mod = "SUPER"

-- krypt shortcuts
hl.bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd("krypt system start"))
hl.bind("CTRL + SHIFT + K", hl.dsp.exec_cmd("krypt kanata toggle"))

-- Notification center
hl.bind(mod .. " + N", hl.dsp.exec_cmd(apps.notify .. " -t -sw"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd(apps.notify .. " -d -sw"))
hl.bind(mod .. " + ALT + N", hl.dsp.exec_cmd(apps.notify .. " -C -sw"))

-- Browser
hl.bind(mod .. " + B", hl.dsp.exec_cmd(apps.browser))

-- Terminal
hl.bind(mod .. " + C", hl.dsp.exec_cmd(apps.terminal))
hl.bind(mod .. " + return", hl.dsp.exec_cmd(apps.terminal))

-- File manager
hl.bind(mod .. " + E", hl.dsp.exec_cmd(apps.filemanager))

-- Lock screen
hl.bind(mod .. " + M", hl.dsp.exec_cmd(apps.lock))

-- Colorpicker
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd(apps.colorpicker))

-- Screenshot
local screenshot_file = [[~/Pictures/Screenshots/`date "+%Y%m%d_%Hh%Mm%Ss"`.png]]
hl.bind(mod .. " + P", hl.dsp.exec_cmd(apps.screenshot .. " " .. screenshot_file))
hl.bind("Print", hl.dsp.exec_cmd(apps.screenshot .. " " .. screenshot_file))

-- Screenrecord
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd(apps.record))

-- Menus
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("krypt menu power"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("krypt menu power"))
hl.bind(mod .. " + space", hl.dsp.exec_cmd("krypt menu apps"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("krypt menu calc"))
hl.bind(mod .. " + period", hl.dsp.exec_cmd("krypt menu emoji"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("krypt menu wifi"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("krypt menu audio"))
hl.bind(mod .. " + U", hl.dsp.exec_cmd("krypt menu bluetooth"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("krypt menu time"))
hl.bind(mod .. " + escape", hl.dsp.exec_cmd("krypt menu top"))

hl.bind(mod .. " + CTRL + J", hl.dsp.exec_cmd("krypt menu autofill -- auth"))
hl.bind(mod .. " + CTRL + K", hl.dsp.exec_cmd("krypt menu autofill -- user"))
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("krypt menu autofill -- pass"))
hl.bind(mod .. " + CTRL + semicolon", hl.dsp.exec_cmd("krypt menu autofill -- otp"))

-- Systemcontrol binds
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "set" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "unset" }))
hl.bind(mod .. " + Q", hl.dsp.window.kill())
hl.bind(mod .. " + S", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

-- Brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness=-10"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness=+10"))

-- Volume control
hl.bind(mod .. " + up", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=+10"))
hl.bind(mod .. " + down", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=-10"))
hl.bind(mod .. " + left", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=mute-toggle"))
hl.bind(mod .. " + right", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=mute-toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=+10"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=-10"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --max-volume=140 --output-volume=mute-toggle"))

-- Microphone control
hl.bind(mod .. " + SHIFT + up", hl.dsp.exec_cmd("swayosd-client --input-volume=+10"))
hl.bind(mod .. " + SHIFT + down", hl.dsp.exec_cmd("swayosd-client --input-volume=-10"))
hl.bind(mod .. " + SHIFT + left", hl.dsp.exec_cmd("swayosd-client --input-volume=mute-toggle"))
hl.bind(mod .. " + SHIFT + right", hl.dsp.exec_cmd("swayosd-client --input-volume=mute-toggle"))
hl.bind(mod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --input-volume=+10"))
hl.bind(mod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --input-volume=-10"))
hl.bind(mod .. " + XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --input-volume=mute-toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume=mute-toggle"))

-- Move focus with mod + hjkl keys
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Window TAB for switching while in fullscreen or fakefullscreen
hl.bind(mod .. " + tab", hl.dsp.window.cycle_next())
hl.bind(mod .. " + SHIFT + tab", hl.dsp.window.cycle_next({ next = false }))

-- Window size changes
hl.bind("CTRL + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind("CTRL + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind("CTRL + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind("CTRL + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- Move window with mod + hjkl keys
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- Switch workspaces with mod + [0-9]
-- Move active window to a workspace with mod + shift + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move/resize windows with mod + LMB/RMB and dragging
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
