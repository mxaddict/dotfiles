# env.nu

$env.config.edit_mode = 'vi'
$env.config.buffer_editor = 'nvim'
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"
$env.config.show_banner = false
$env.config.history.sync_on_enter = false
$env.EDITOR = "hx"
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense,cobra'
$env.COLORTERM = "truecolor"
$env.LANG = "en_US.UTF-8"
$env.GPG_TTY = (tty)
$env.MANGOHUD = 0

$env.PATH = ($env.PATH | prepend [
    ($env.HOME | path join '.cargo/bin'),
    ($env.HOME | path join '.local/bin'),
    ($env.HOME | path join '.config/composer/vendor/bin'),
    ($env.HOME | path join '.local/share/nvim/mason/bin'),
    '/Library/Application Support/ZeroTier/One',
    '/opt/homebrew/bin',
    '/opt/homebrew/opt/m4/bin',
    '/opt/homebrew/opt/llvm/bin',
])

if not (which fnm | is-empty) {
    fnm env --json | from json | load-env
    $env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH | path join 'bin'))
}

$env.JOBS = (.nproc)
$env.MAKEFLAGS = "-j" + $env.JOBS
