# vi: ft=ps1
# PowerShell 7 port of .config/fish/config.fish for Windows. Linux-only
# settings (MANGOHUD, GPG_TTY, PARU_PAGER, MANPAGER, batcat) have no Windows
# counterpart and are left out.

# Alacritty starts the shell in the folder it was itself started in. Launched
# from a shortcut, that is System32 (a shortcut with no "Start in", like the
# Alacritty installer's) or Alacritty's own install folder (scoop's shortcut),
# and never where a new terminal is wanted, so start those at home instead.
# `alacritty --working-directory <dir>` and a terminal opened in any other
# folder keep their folder. Alacritty's own `working_directory` setting would
# need an absolute path per machine: it does not expand `~`.
#
# A `pwsh` from scoop runs through a shim, a small exe with a `.shim` file
# beside it that starts the real pwsh as its child, so the launcher is the
# first parent that is not a shim.
$launcher = (Get-Process -Id $PID).Parent
while ($launcher.Path -and (Test-Path ([IO.Path]::ChangeExtension($launcher.Path, '.shim')))) {
    $launcher = $launcher.Parent
}
if ($launcher.ProcessName -eq 'alacritty' -and
    $PWD.Path -in @([Environment]::SystemDirectory, (Split-Path $launcher.Path))) {
    Set-Location ~
}
Remove-Variable launcher

# The exe a scoop shim starts: its `.shim` file beside it names the real exe.
# Any other path is returned as it is.
function Resolve-ShimTarget([string]$Path) {
    $shim = [IO.Path]::ChangeExtension($Path, '.shim')
    if (-not (Test-Path $shim)) { return $Path }
    $target = Select-String -Path $shim -Pattern '^path = "(.+)"' | Select-Object -First 1
    if ($target) { $target.Matches[0].Groups[1].Value }
}

# uutils coreutils: make every coreutils command win over PowerShell's
# built-in aliases/functions (ls, rm, cp, mkdir, ...) and over same-named
# System32 programs (sort.exe, more.com, timeout.exe, ...).
#
# Aliases to the full exe path are used instead of reordering PATH, so this
# only affects interactive PowerShell and leaves scripts, cmd and PATH lookup
# by other programs untouched. The folder is found through PATH, so an upgrade
# that installs into a new versioned folder keeps working.
#
# It is found from one of its commands, b2sum. scoop puts no coreutils.exe on
# PATH, only a shim per command in its shared shims folder, whose `.shim` file
# names the real exe. Git's usr\bin has a GNU b2sum as well, so the folder must
# also hold coreutils.exe.
#
# `link` is skipped: coreutils' link.exe would shadow MSVC's linker.
$coreutilsDir = Get-Command b2sum.exe -CommandType Application -All -ErrorAction SilentlyContinue |
    ForEach-Object { Resolve-ShimTarget $_.Source } |
    Where-Object { $_ } |
    ForEach-Object { Split-Path $_ } |
    Where-Object { Test-Path (Join-Path $_ 'coreutils.exe') } |
    Select-Object -First 1
if ($coreutilsDir) {
    $skip = @('coreutils', 'link')
    Get-ChildItem $coreutilsDir -Filter *.exe |
        Where-Object { $_.BaseName -notin $skip } |
        # AllScope because some built-ins (cp, dir, echo) carry it and it
        # cannot be removed from an existing alias.
        ForEach-Object { Set-Alias -Name $_.BaseName -Value $_.FullName -Option AllScope -Force -Scope Global }
} else {
    Write-Warning 'uutils coreutils not found on PATH; Unix commands fall back to PowerShell aliases.'
}
Remove-Variable coreutilsDir, skip -ErrorAction Ignore

function Test-Command([string]$Name) {
    [bool](Get-Command $Name -CommandType Application -ErrorAction Ignore)
}

# Set some stuff for our path; like fish_add_path, only directories that exist
foreach ($dir in @(
        "$HOME/.foundry/bin"
        "$HOME/.cargo/bin"
        "$env:APPDATA/Composer/vendor/bin"
        "$HOME/.dotnet/tools"
        "$HOME/.local/bin"
        "$env:LOCALAPPDATA/nvim-data/mason/bin"
    )) {
    if (-not (Test-Path $dir)) { continue }
    $full = (Resolve-Path $dir).ProviderPath
    if (($env:PATH -split [IO.Path]::PathSeparator) -notcontains $full) {
        $env:PATH = $full + [IO.Path]::PathSeparator + $env:PATH
    }
}
Remove-Variable dir, full -ErrorAction Ignore

# Set default editor to vim
$env:EDITOR = 'hjkl'

# Disable php_cs_fixer Check
$env:PHP_CS_FIXER_IGNORE_ENV = '1'

# Set JOBS
$env:JOBS = [Environment]::ProcessorCount

# Add makeflags
$env:MAKEFLAGS = "-j$env:JOBS"

# Cap cargo at half the system threads to keep desktop responsive
$env:CARGO_BUILD_JOBS = [Math]::Max(1, [Math]::Floor([Environment]::ProcessorCount / 2))

# FZF theme
$env:FZF_CTRL_T_OPTS = "--preview 'bat -n --color=always {}'"
$env:FZF_DEFAULT_OPTS = (@(
        $env:FZF_DEFAULT_OPTS
        '--height 100%'
        '--info=inline-right'
        '--ansi'
        '--layout=reverse'
        '--border=none'
        '--color=bg+:#283457'
        '--color=bg:#16161e'
        '--color=border:#27a1b9'
        '--color=fg:#c0caf5'
        '--color=gutter:#16161e'
        '--color=header:#ff9e64'
        '--color=hl+:#2ac3de'
        '--color=hl:#2ac3de'
        '--color=info:#545c7e'
        '--color=marker:#ff007c'
        '--color=pointer:#ff007c'
        '--color=prompt:#2ac3de'
        '--color=query:#c0caf5:regular'
        '--color=scrollbar:#27a1b9'
        '--color=separator:#ff9e64'
        '--color=spinner:#ff007c'
    ) | Where-Object { $_ }) -join ' '

# Snapshot existing functions: PowerShell resolves aliases before functions,
# so every function defined below drops any alias of the same name (h, gl, nv,
# and coreutils' ls/cat) once they are all declared.
$profileFunctionsBefore = (Get-ChildItem Function:).Name

# Check for exa and alias to eza
if (-not (Test-Command eza) -and (Test-Command exa)) {
    function eza { exa @args }
}

if ((Test-Command eza) -or (Test-Command exa)) {
    # Replace default ls command with eza
    function ls { eza --group-directories-first @args }

    # Replace tree command with eza
    function tree { eza --tree -- @args }

    # Some more ls
    function l { ls -lF -- @args }
    function la { ls -aF -- @args }
    function ll { ls -alF -- @args }
}

# Replace cat with bat
if (Test-Command bat) {
    function cat { bat --plain @args }
}

# Hrdr default: skip perms
function hrdr { & (Get-Command hrdr -CommandType Application -TotalCount 1) --yolo @args }

# Codex default: skip approvals and sandbox
function codex {
    & (Get-Command codex -CommandType Application -TotalCount 1) --dangerously-bypass-approvals-and-sandbox @args
}

# Claude default: skip perms
function claude {
    & (Get-Command claude -CommandType Application -TotalCount 1) --dangerously-skip-permissions --remote-control @args
}

# Claude continue alias. `||` cannot see a native exit code through a
# function call, so test $LASTEXITCODE instead.
function c {
    claude --continue @args
    if ($LASTEXITCODE) { claude }
}

# Claude work account (separate config dir)
function cw {
    $previous = $env:CLAUDE_CONFIG_DIR
    $env:CLAUDE_CONFIG_DIR = "$HOME/.claude-work"
    try {
        claude --continue @args
        if ($LASTEXITCODE) { claude }
    } finally {
        $env:CLAUDE_CONFIG_DIR = $previous
    }
}

# Opencode continue alias
function o {
    opencode --continue @args
    if ($LASTEXITCODE) { opencode }
}

# Git typo
function got {
    Write-Output 'Hey! Fat fingers!!!'
    git @args
}

# More git
function gti { got @args }
function gto { got @args }
function tgi { got @args }
function gut { got @args }
function fur { got @args }
function hot { got @args }

# fastfetch
function ff {
    Clear-Host
    fastfetch @args
}

# Alias for lazygit
function lg { lazygit @args }

# Alias for quick and dirty git commit
function gg {
    $msg = quoty

    if ($msg) {
        git add .
        git commit -m "$msg"
    } else {
        Write-Error "Could'nt get quote from quoty"
        return
    }
    git pull --rebase
    git push
}
function gl {
    $loc = curl -s https://ipinfo.io/loc

    if ($loc) {
        git add .
        git commit -m "$loc"
    } else {
        Write-Error "Could'nt get location"
        return
    }
    git pull --rebase
    git push
}

# Alias for kweri
function q { kweri @args }

# Alias for hjkl
function h { hjkl @args }
function hj { hjkl @args }
function hjk { hjkl @args }

# Alias for sqeel
function s { sqeel @args }
function sq { sqeel @args }
function sql { sqeel @args }

# Add navcoin alias
function nav { navcoin-cli @args }

# Clear alias
function cl { Clear-Host }

# NVM
if (Test-Command fnm) {
    function nvm { fnm @args }
}

# I want v to open vi and vi to open vim
function n { hjkl @args }
function nv { hjkl @args }
function nvi { hjkl @args }
function v { hjkl @args }
function vi { hjkl @args }
function vim { hjkl @args }

(Get-ChildItem Function:).Name |
    Where-Object { $_ -notin $profileFunctionsBefore } |
    ForEach-Object { Remove-Item "Alias:$_" -Force -ErrorAction Ignore }
Remove-Variable profileFunctionsBefore

# TokyoNight Color Palette
$foreground = '#c0caf5'
$selection = "`e[48;2;40;52;87m"
$comment = '#565f89'
$red = '#f7768e'
$yellow = '#e0af68'
$green = '#9ece6a'
$purple = '#9d7cd8'
$cyan = '#7dcfff'
$pink = '#bb9af7'

# Syntax Highlighting and Completion Pager Colors; turn on vi mode. No bell, as
# in fish.
Set-PSReadLineOption -EditMode Vi -ViModeIndicator Cursor -BellStyle None -HistorySearchCursorMovesToEnd -Colors @{
    Default                = $foreground
    Command                = $cyan
    Keyword                = $pink
    String                 = $yellow
    Parameter              = $pink
    Error                  = $red
    Variable               = $purple
    Comment                = $comment
    Selection              = $selection
    Operator               = $green
    InlinePrediction       = $comment
    ListPrediction         = $cyan
    ListPredictionSelected = $selection
    ListPredictionTooltip  = $comment
}
Remove-Variable foreground, selection, comment, red, yellow, green, purple, cyan, pink

# Grey suggestions from history as you type, like fish's autosuggestions.
# PSReadLine refuses them when output is redirected (`pwsh -Command ... > file`),
# failing the whole call, so they get a call of their own.
if (-not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
}

# fish keys in insert mode. The vi defaults for Right and End only move the
# cursor; ForwardChar and EndOfLine also accept the suggestion when the cursor
# is at the end of the line, and ForwardWord takes its next word. Tab opens a
# menu of completions, and Up/Down search history for what is already typed.
$fishKeys = [ordered]@{
    RightArrow       = 'ForwardChar'
    End              = 'EndOfLine'
    'Alt+RightArrow' = 'ForwardWord'
    Tab              = 'MenuComplete'
    UpArrow          = 'HistorySearchBackward'
    DownArrow        = 'HistorySearchForward'
}
foreach ($key in $fishKeys.Keys) {
    Set-PSReadLineKeyHandler -Key $key -Function $fishKeys[$key] -ViMode Insert
}
Remove-Variable fishKeys, key

# Alias for :q to exit terminal. PowerShell parses `:q` as a loop label, so no
# function can catch it; rewrite the line to `exit` when it is submitted.
foreach ($mode in 'Insert', 'Command') {
    Set-PSReadLineKeyHandler -Key Enter -ViMode $mode -BriefDescription 'AcceptLineOrQuit' -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($line.Trim() -eq ':q') {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, 'exit')
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}
Remove-Variable mode

# Load fzf. PSFzf is the PowerShell counterpart of the fzf.fish plugin; the
# fzf.fish variables (Ctrl+V) and processes (Ctrl+P) pickers have no PSFzf
# equivalent, so those keys keep their PSReadLine defaults.
if ((Test-Command fzf) -and (Get-Module -ListAvailable PSFzf)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

    # FZF binds
    $insertSelection = {
        param($Selection)
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        if ($Selection) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($Selection -join ' ')
        }
    }
    Set-PSReadLineKeyHandler -Key Ctrl+f -BriefDescription 'FzfDirectory' -ScriptBlock {
        Invoke-FzfPsReadlineHandlerProvider
    }
    Set-PSReadLineKeyHandler -Key Ctrl+g -BriefDescription 'FzfGitLog' -ScriptBlock ({
        & $insertSelection (Invoke-PsFzfGitHashes)
    }.GetNewClosure())
    Set-PSReadLineKeyHandler -Key Ctrl+s -BriefDescription 'FzfGitStatus' -ScriptBlock ({
        & $insertSelection (Invoke-PsFzfGitFiles)
    }.GetNewClosure())
    Remove-Variable insertSelection
}

# Argument completers the tools print for PowerShell, as fish has for most
# commands. Printing them takes some tools over a second, so each is cached and
# printed again only when the tool's exe is newer than its cache. Dot-sourced
# here, not in a function, because the completers call helper functions the
# scripts define, which must outlive the call.
$completions = [ordered]@{
    doctl  = { doctl completion powershell }
    gh     = { gh completion -s powershell }
    glab   = { glab completion -s powershell }
    rustup = { rustup completions powershell }
}
$completionCache = Join-Path $env:LOCALAPPDATA 'PowerShell/completions'
foreach ($name in $completions.Keys) {
    $cmd = Get-Command $name -CommandType Application -TotalCount 1 -ErrorAction Ignore
    if (-not $cmd) { continue }
    $exe = Resolve-ShimTarget $cmd.Source
    $cache = Join-Path $completionCache "$name.ps1"
    if (-not (Test-Path $cache) -or ($exe -and (Get-Item $cache).LastWriteTime -lt (Get-Item $exe).LastWriteTime)) {
        $script = & $completions[$name] | Out-String
        if ($LASTEXITCODE -or -not $script.Trim()) {
            Write-Warning "$name printed no PowerShell completions (exit $LASTEXITCODE); skipped."
            continue
        }
        New-Item -ItemType Directory -Force $completionCache | Out-Null
        Set-Content -LiteralPath $cache -Value $script
    }
    . $cache
}
Remove-Variable completions, completionCache, name, cmd, exe, cache, script -ErrorAction Ignore

# Load starship prompt
if (Test-Command starship) {
    Invoke-Expression (& starship init powershell)
}

# FNM setup env
if (Test-Command fnm) {
    fnm env --shell powershell | Out-String | Invoke-Expression
}

# Load zoxide. It records directories from a hook in the `prompt` function, so
# it must come after anything that redefines `prompt` (starship does), or the
# hook is dropped and the database never fills.
if (Test-Command zoxide) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
