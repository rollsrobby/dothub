local mod = "SUPER"
local terminal = "ghostty"
local menu = "walker"
local browser = "helium"

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.33,
})

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "altgr-intl",
    follow_mouse = 1,
    repeat_rate = 50,
    repeat_delay = 200,
    scroll_factor = 0.6,
    touchpad = {
      scroll_factor = 0.6,
    },
  },
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    col = {
      active_border = "rgba(8db4ffcc)",
      inactive_border = "rgba(2a2f3acc)",
    },
    layout = "dwindle",
  },
  decoration = {
    rounding = 4,
  },
  animations = {
    enabled = false,
  },
})

hl.env("HYPRCURSOR_THEME", "")
hl.env("HYPRCURSOR_SIZE", "")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
  hl.exec_cmd("clamshell-display")
end)

hl.window_rule({
  match = { class = "org.gnome.NautilusPreviewer" },
  float = true,
})
hl.window_rule({
  match = { class = "org.gnome.NautilusPreviewer" },
  center = true,
})

hl.bind(mod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + KP_Enter", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("pidof hyprlock >/dev/null || hyprlock"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("walker -m clipboard"))

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Keep lid actions in Hyprland so closing and opening the lid reapplies display setup.
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("clamshell-display"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("clamshell-display"), { locked = true })
