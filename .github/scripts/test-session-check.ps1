# The checks at the end of test-session.sh: the tmxr session is in the
# directory, ~/.claude.json records it as trusted, and the claude stub was
# started by the user's `c` alias, with its flags, first with --continue and
# then fresh. Paths are compared as the OS compares them.
param(
    [Parameter(Mandatory)] [string]$Directory,
    [Parameter(Mandatory)] [string]$PanePath,
    [Parameter(Mandatory)] [string]$Log
)

$ErrorActionPreference = 'Stop'
$comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
function Test-SamePath([string]$A, [string]$B) {
    $full = { param($p) [IO.Path]::GetFullPath($p).TrimEnd([IO.Path]::DirectorySeparatorChar) }
    [string]::Equals((& $full $A), (& $full $B), $comparison)
}

$failures = [Collections.Generic.List[string]]::new()

if (-not (Test-SamePath $PanePath $Directory)) {
    $failures.Add("the session is in $PanePath, not $Directory")
}

$config = Get-Content -Raw -LiteralPath (Join-Path $HOME '.claude.json') | ConvertFrom-Json -AsHashtable
$entries = @($config.projects.Keys | Where-Object { Test-SamePath $_ $Directory })
if ($entries.Count -ne 1) {
    $failures.Add("~/.claude.json has $($entries.Count) entries for $Directory")
} elseif (-not $config.projects[$entries[0]].hasTrustDialogAccepted) {
    $failures.Add("~/.claude.json does not record $Directory as trusted")
}

$flags = @('--dangerously-skip-permissions', '--remote-control')
$expected = @(
    , ($flags + '--continue')
    , $flags
)
$calls = @(Get-Content -LiteralPath $Log | ForEach-Object { $_ | ConvertFrom-Json })
if ($calls.Count -ne $expected.Count) {
    $failures.Add("claude ran $($calls.Count) times, expected $($expected.Count): --continue, then fresh")
} else {
    for ($i = 0; $i -lt $calls.Count; $i++) {
        $got = @($calls[$i].args) -join ' '
        $want = $expected[$i] -join ' '
        if ($got -ne $want) { $failures.Add("claude call $($i + 1) had args '$got', expected '$want'") }
        if (-not (Test-SamePath $calls[$i].cwd $Directory)) {
            $failures.Add("claude call $($i + 1) ran in $($calls[$i].cwd), not $Directory")
        }
    }
}

if ($failures.Count) {
    $failures | ForEach-Object { Write-Host "::error::$_" }
    exit 1
}
Write-Host 'session flow verified'
