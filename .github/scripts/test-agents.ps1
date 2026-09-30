# Installs the claude, codex and opencode CLIs with `krypt system agents` into
# the real home and smoke-tests each: it sits where the command puts it, runs,
# and is what the shell config on this OS resolves first on PATH. Runs on Linux,
# macOS and Windows under PowerShell 7; `krypt` must be on PATH, and fish on
# Linux and macOS.

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$os = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'macos' } else { 'linux' }
$exe = if ($IsWindows) { '.exe' } else { '' }

$expected = [ordered]@{
    claude   = Join-Path $HOME ".local/bin/claude$exe"
    codex    = Join-Path $HOME ".local/bin/codex$exe"
    opencode = Join-Path $HOME ".opencode/bin/opencode$exe"
}

# Steps a run skips once every CLI is installed: all of them on Linux and
# macOS; on Windows the codex shim and opencode's installer run every time.
$skippedWhenInstalled = @{ windows = 2; macos = 3; linux = 3 }[$os]

function Invoke-Agents {
    $report = & krypt system agents 2>&1 | ForEach-Object { "$_" }
    $report | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "krypt system agents exited with $LASTEXITCODE" }
    $report
}

$failures = [Collections.Generic.List[string]]::new()

Push-Location $repo
try {
    Invoke-Agents | Out-Null

    # A second run must leave every installed CLI to its own updater.
    $second = Invoke-Agents
    $skipped = $second | Select-String -Pattern '\((\d+) skipped' | Select-Object -First 1
    $count = if ($skipped) { [int]$skipped.Matches[0].Groups[1].Value } else { -1 }
    if ($count -ne $skippedWhenInstalled) {
        $failures.Add("second run skipped $count step(s), expected $skippedWhenInstalled")
    }

    foreach ($name in $expected.Keys) {
        $path = $expected[$name]
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $failures.Add("${name}: not installed at $path")
            continue
        }
        $version = & $path --version 2>&1 | Out-String
        Write-Host "$name --version: $($version.Trim())"
        if ($LASTEXITCODE -ne 0 -or $version -notmatch '\d+\.\d+\.\d+') {
            $failures.Add("${name}: --version exited $LASTEXITCODE with '$($version.Trim())'")
        }
    }

    if ($os -eq 'windows') {
        # The shim must start codex from its release, where it finds the
        # codex-resources dir its sandbox needs.
        $sandbox = & $expected.codex sandbox cmd /c echo sandbox-ok 2>&1 | Out-String
        Write-Host "codex sandbox: $($sandbox.Trim())"
        if ($LASTEXITCODE -ne 0 -or $sandbox -notmatch 'sandbox-ok') {
            $failures.Add("codex: sandbox through the shim exited $LASTEXITCODE")
        }
    }

    # Take every dir the CLIs live in off PATH (the runner's PATH already has
    # ~/.local/bin), so only the shell config can put them back. Each lookup
    # prints one line, empty when the name is not found, to keep the order.
    $sep = [IO.Path]::PathSeparator
    $cliDirs = @($expected.Values | ForEach-Object { Split-Path -Parent $_ })
    if ($os -eq 'windows') { $cliDirs += Join-Path $env:LOCALAPPDATA 'Programs\OpenAI\Codex\bin' }
    $cliDirs = $cliDirs | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\', '/') }
    $env:PATH = ($env:PATH -split $sep | Where-Object {
            $_ -and [IO.Path]::GetFullPath($_).TrimEnd('\', '/') -notin $cliDirs
        }) -join $sep

    if ($os -eq 'windows') {
        $resolved = pwsh -NoProfile -NonInteractive -Command {
            param($ProfilePath, $Names)
            . $ProfilePath
            foreach ($name in $Names) {
                "$((Get-Command $name -CommandType Application -TotalCount 1 -ErrorAction Ignore).Source)"
            }
        } -args (Join-Path $repo 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'), @($expected.Keys)
    } else {
        # Not --no-config: that also skips fish's own startup, which is what
        # turns fish_add_path's fish_user_paths into PATH entries.
        $names = $expected.Keys -join ' '
        $resolved = fish -c "source '$repo/.config/fish/config.fish'; for name in $names; echo (command -s `$name); end"
    }
    $resolved = @($resolved)
    $i = 0
    foreach ($name in $expected.Keys) {
        $found = if ($i -lt $resolved.Count) { $resolved[$i] } else { '' }
        $i++
        Write-Host "$name resolves to: $found"
        if (-not $found -or [IO.Path]::GetFullPath($found) -ne [IO.Path]::GetFullPath($expected[$name])) {
            $failures.Add("${name}: the $os shell config resolves $found, not $($expected[$name])")
        }
    }
} finally {
    Pop-Location
}

if ($failures.Count) {
    $failures | ForEach-Object { Write-Host "::error::$_" }
    throw "$($failures.Count) agent CLI check(s) failed on $os"
}
Write-Host "claude, codex and opencode verified on $os"
