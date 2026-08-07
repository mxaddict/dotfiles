-- Keyboard / pointer / touchpad config.
-- Docs: https://wiki.hypr.land/Configuring/Basics/Variables/#input
--
-- Change kb_layout to your locale (de, gb, fr, etc).
-- Run `localectl list-x11-keymap-layouts` for the full list.
hl.config({
    input = {
        kb_layout  = "{{kb_layout}}",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        sensitivity    = 0,
        follow_mouse   = true,
        natural_scroll = true,
        force_no_accel = true,

        touchpad = {
            natural_scroll      = true,
            clickfinger_behavior = true,
        },
    },
})
