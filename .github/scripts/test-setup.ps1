# Deploys the dotfiles with krypt into a throwaway home and checks that every
# file lands where the tools on this OS read it. Runs on Linux, macOS and
# Windows under PowerShell 7; `krypt` must be on PATH.

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$os = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'macos' } else { 'linux' }

$sandbox = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-home-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $sandbox | Out-Null
$manifest = Join-Path $sandbox 'krypt-manifest.json'

# Point every home-derived location krypt resolves at the sandbox.
$env:HOME = $sandbox
$env:USERPROFILE = $sandbox
$env:APPDATA = Join-Path $sandbox 'AppData/Roaming'
$env:LOCALAPPDATA = Join-Path $sandbox 'AppData/Local'
foreach ($var in 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CACHE_HOME') {
    Remove-Item "Env:$var" -ErrorAction Ignore
}

function Invoke-Krypt {
    & krypt @args
    if ($LASTEXITCODE -ne 0) { throw "krypt $args exited with $LASTEXITCODE" }
}

# The count after `<Label>:` in a `krypt link` report; 0 when the line is absent
# (krypt omits zero-valued lines other than the first).
function Get-ReportCount([object[]]$Report, [string]$Label) {
    $match = $Report | Select-String -Pattern "^\s*$([regex]::Escape($Label)): (\d+)$" | Select-Object -First 1
    if ($match) { [int]$match.Matches[0].Groups[1].Value } else { 0 }
}

$failures = [Collections.Generic.List[string]]::new()

function Assert-Deployed([string]$Destination, [string]$Source) {
    $dst = Join-Path $sandbox $Destination
    if (-not (Test-Path -LiteralPath $dst -PathType Leaf)) {
        $failures.Add("missing: $Destination")
    } elseif ((Get-FileHash -LiteralPath $dst).Hash -ne (Get-FileHash -LiteralPath (Join-Path $repo $Source)).Hash) {
        $failures.Add("differs from ${Source}: $Destination")
    }
}

function Assert-Absent([string]$Destination) {
    if (Test-Path -LiteralPath (Join-Path $sandbox $Destination)) {
        $failures.Add("deployed on $os but belongs to another OS: $Destination")
    }
}

Push-Location $repo
try {
    Invoke-Krypt validate .krypt.toml
    Invoke-Krypt link --config .krypt.toml --manifest $manifest --dry-run
    $firstLink = Invoke-Krypt link --config .krypt.toml --manifest $manifest
    $firstLink
    # A second run must find every destination tracked and nothing to fix:
    # it rewrites exactly what the first run wrote, all of it byte-identical.
    $secondLink = Invoke-Krypt link --config .krypt.toml --manifest $manifest
    $secondLink
    $firstWrote = Get-ReportCount $firstLink 'wrote'
    $secondWrote = Get-ReportCount $secondLink 'wrote'
    $idempotent = Get-ReportCount $secondLink 'idempotent re-deploys'
    if ($firstWrote -eq 0 -or $secondWrote -ne $firstWrote -or $idempotent -ne $secondWrote) {
        $failures.Add("second link was not idempotent: first wrote $firstWrote, second wrote $secondWrote with $idempotent idempotent re-deploys")
    }

    # Read from ~/.config on every OS (Alacritty's shared file on Windows
    # through the AppData entry point's import).
    Assert-Deployed '.gitconfig' '.gitconfig'
    Assert-Deployed '.config/starship.toml' '.config/starship.toml'
    Assert-Deployed '.config/alacritty/common.toml' '.config/alacritty/common.toml'
    $alacrittyEntry = @{ linux = '.config/alacritty/alacritty.toml'; macos = '.config/alacritty/macos.toml' }[$os]
    if ($alacrittyEntry) {
        Assert-Deployed '.config/alacritty/alacritty.toml' $alacrittyEntry
    } else {
        Assert-Absent '.config/alacritty/alacritty.toml'
    }
    Assert-Deployed '.config/opencode/AGENTS.md' '.config/agents/AGENTS.md'
    if (-not (Test-Path (Join-Path $sandbox '.gitconfig.local'))) { $failures.Add('missing: .gitconfig.local') }

    $windowsOnly = [ordered]@{
        'AppData/Roaming/alacritty/alacritty.toml'                = 'AppData/Roaming/alacritty/alacritty.toml'
        'AppData/Local/nvim/init.lua'                             = '.config/nvim/init.lua'
        'AppData/Local/lazygit/config.yml'                        = '.config/lazygit/config.yml'
        'AppData/Roaming/bat/config'                              = '.config/bat/config'
        'AppData/Roaming/GitHub CLI/config.yml'                   = '.config/gh/config.yml'
        'AppData/Roaming/tealdeer/config/config.toml'             = '.config/tealdeer/config.toml'
        'AppData/Roaming/mpv/mpv.conf'                            = '.config/mpv/mpv.conf'
        'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'   = 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
        '.local/bin/.envup.ps1'                                   = '.local/bin/.envup.ps1'
    }
    # ~/.config copies of tools that read a native folder on Windows, and
    # shell tooling Windows has no use for.
    $unixOnly = [ordered]@{
        '.config/nvim/init.lua'     = '.config/nvim/init.lua'
        '.config/bat/config'        = '.config/bat/config'
        '.config/gh/config.yml'     = '.config/gh/config.yml'
        '.config/mpv/mpv.conf'      = '.config/mpv/mpv.conf'
        '.config/tealdeer/config.toml' = '.config/tealdeer/config.toml'
        '.config/fish/config.fish'  = '.config/fish/config.fish'
        '.config/tmux/tmux.conf'    = '.config/tmux/tmux.conf'
        '.local/bin/t'              = '.local/bin/t'
        '.local/bin/.nproc'         = '.local/bin/.nproc'
    }
    $macosOnly = [ordered]@{
        'Library/Application Support/lazygit/config.yml' = '.config/lazygit/config.yml'
    }
    $linuxOnly = [ordered]@{
        '.config/hypr/hyprland.lua'    = '.config/hypr/hyprland.lua'
        '.config/lazygit/config.yml'   = '.config/lazygit/config.yml'
        '.gtkrc-2.0'                   = '.gtkrc-2.0'
        '.local/bin/grimblast'         = '.local/bin/grimblast'
    }
    $expected = @(
        @{ Entries = $windowsOnly; On = @('windows') }
        @{ Entries = $unixOnly; On = @('linux', 'macos') }
        @{ Entries = $macosOnly; On = @('macos') }
        @{ Entries = $linuxOnly; On = @('linux') }
    )
    foreach ($set in $expected) {
        foreach ($entry in $set.Entries.GetEnumerator()) {
            if ($os -in $set.On) { Assert-Deployed $entry.Key $entry.Value } else { Assert-Absent $entry.Key }
        }
    }

    # Commands: the per-OS entry runs, and a Linux-only one refuses elsewhere.
    Invoke-Krypt system nproc
    if ($os -ne 'linux') {
        # Any failure would exit non-zero (the script it runs is not deployed
        # here either), so require krypt's own platform refusal.
        $refusal = & { $ErrorActionPreference = 'Continue'; & krypt browser open 2>&1 | ForEach-Object { "$_" } }
        $refusal
        if ($LASTEXITCODE -eq 0 -or -not ($refusal -match 'restricted to linux')) {
            $failures.Add("krypt browser open on $os did not refuse as linux-only")
        }
    }
    if ($os -eq 'windows') {
        # Gated by a platform list, so the refusal names both platforms.
        $refusal = & { $ErrorActionPreference = 'Continue'; & krypt tmux open 2>&1 | ForEach-Object { "$_" } }
        $refusal
        if ($LASTEXITCODE -eq 0 -or -not ($refusal -match 'restricted to linux, macos')) {
            $failures.Add('krypt tmux open on windows did not refuse as linux/macos-only')
        }
    }

    # Installing and resolving packages is the deps workflow's job; here only
    # that the included deps file is read for this OS's managers.
    $managers = @{ windows = @('winget'); macos = @('brew'); linux = @('pacman', 'apt', 'dnf') }[$os]
    foreach ($manager in $managers) {
        $plan = Invoke-Krypt deps --config .krypt.toml --dry-run --manager $manager
        $plan
        if (-not ($plan -match '^would install: .+')) { $failures.Add("krypt deps queued nothing for $manager") }
    }

    if ($os -eq 'windows') {
        $profilePath = Join-Path $sandbox 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
        pwsh -NoProfile -NonInteractive -Command {
            param($ProfilePath)
            $ErrorActionPreference = 'Stop'
            . $ProfilePath
            # Each of these shadows a built-in alias the profile must remove.
            foreach ($name in 'h', 'gl', 'nv') {
                if ((Get-Command $name).CommandType -ne 'Function') { throw "$name does not resolve to the profile function" }
            }
            if ((Get-PSReadLineOption).EditMode -ne 'Vi') { throw 'vi mode is not enabled' }
        } -args $profilePath
        if ($LASTEXITCODE -ne 0) { $failures.Add('PowerShell profile failed to load cleanly') }
    }
} finally {
    Pop-Location
}

if ($failures.Count) {
    $failures | ForEach-Object { Write-Host "::error::$_" }
    throw "$($failures.Count) setup check(s) failed on $os"
}
Write-Host "dotfiles setup verified on $os"
