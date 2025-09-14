# env.nu

$env.config.edit_mode = 'vi'
$env.config.buffer_editor = 'helix'
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"
$env.config.show_banner = false
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense,cobra'
$env.COLORTERM = "truecolor"
$env.LANG = "en_US.UTF-8"
$env.GPG_TTY = (tty)
$env.MANGOHUD = 0

$env.PATH = ($env.PATH | prepend [
    '~/.cargo/bin',
    '~/.local/bin',
    '~/.config/composer/vendor/bin',
    '~/.local/share/nvim/mason/bin',
    '/opt/homebrew/bin',
    '/opt/homebrew/opt/m4/bin',
    '/opt/homebrew/opt/llvm/bin',
])

fnm env --json | from json | load-env

$env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH + '/bin'))

$env.JOBS = (.nproc)
$env.MAKEFLAGS = "-j" + $env.JOBS
