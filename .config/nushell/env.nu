# env.nu

$env.config.edit_mode = 'vi'
$env.config.buffer_editor = 'helix'
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"
$env.config.show_banner = false
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

$env.PATH ++= [ '~/.cargo/bin' ]
$env.PATH ++= [ '~/.local/bin' ]
$env.PATH ++= [ '~/.config/composer/vendor/bin' ]
$env.PATH ++= [ '~/.local/share/nvim/mason/bin' ]
$env.PATH ++= [ '/opt/homebrew/bin' ]
$env.PATH ++= [ '/opt/homebrew/opt/m4/bin' ]
$env.PATH ++= [ '/opt/homebrew/opt/llvm/bin' ]
