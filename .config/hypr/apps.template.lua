-- User-configurable app launchers used by hyprland.lua binds.
-- Edit this file (not hyprland.lua) to swap your defaults.
-- Seeded from this template by krypt (see [[template]] in .krypt.toml).
return {
    terminal    = "{{terminal}}",
    browser     = "{{browser}}",
    filemanager = "{{filemanager}}",
    lock        = "{{lock}}",
    colorpicker = "hyprpicker --no-fancy --autocopy",
    screenshot  = "grimblast --notify --freeze copysave area",
    record      = "kooha",
    notify      = "swaync-client",
}
