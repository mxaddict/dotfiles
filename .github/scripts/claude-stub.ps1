# Stands in for the claude CLI in CI, where the real one cannot log in. It does
# what the "Starting a Claude session" flow in AGENTS.md relies on: `--continue`
# fails in a directory with no conversation (the flow always starts in a new
# one), a folder not trusted yet gets a trust menu with "No, exit" selected that
# the arrow keys move, and accepting it is recorded in ~/.claude.json under the
# directory. Each call is logged to $env:CLAUDE_STUB_LOG as one JSON line, so
# the test can check the flags the user's aliases passed.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$cwd = (Get-Location).Path

if ($env:CLAUDE_STUB_LOG) {
    Add-Content -LiteralPath $env:CLAUDE_STUB_LOG -Value (@{ cwd = $cwd; args = @($args) } | ConvertTo-Json -Compress)
}

if ($args -contains '--continue') {
    [Console]::Error.WriteLine('No conversation found to continue.')
    exit 1
}

$configPath = Join-Path $HOME '.claude.json'
$config = if (Test-Path -LiteralPath $configPath) {
    Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json -AsHashtable
} else {
    @{}
}
if (-not $config.ContainsKey('projects')) { $config.projects = @{} }

$project = $config.projects[$cwd]
if (-not ($project -and $project.hasTrustDialogAccepted)) {
    $options = 'No, exit', 'Yes, I trust this folder'
    $selected = 0
    $chosen = $false
    while (-not $chosen) {
        Clear-Host
        Write-Host ' Accessing workspace:'
        Write-Host " $cwd"
        Write-Host ' Quick safety check: Is this a project you created or one you trust?'
        for ($i = 0; $i -lt $options.Count; $i++) {
            $marker = if ($i -eq $selected) { '❯' } else { ' ' }
            Write-Host " $marker $($options[$i])"
        }
        switch ([Console]::ReadKey($true).Key) {
            'DownArrow' { $selected = [Math]::Min($selected + 1, $options.Count - 1) }
            'UpArrow' { $selected = [Math]::Max($selected - 1, 0) }
            'Enter' { $chosen = $true }
        }
    }
    if ($options[$selected] -eq 'No, exit') { exit 1 }
    $config.projects[$cwd] = @{ hasTrustDialogAccepted = $true }
    Set-Content -LiteralPath $configPath -Value ($config | ConvertTo-Json -Depth 10)
}

Clear-Host
Write-Host "Claude stub ready in $cwd"
# Stay up, as Claude does, until the session is killed.
while ($true) { Start-Sleep -Seconds 60 }
