# Runs agent-lock through agent-lock.ps1 from PowerShell, the way an agent
# whose shell is PowerShell runs it: exit statuses and arguments arrive as
# given (what PowerShell splits is joined back, as the wrapper's comment says),
# a bare `--` is handled as that comment says, a job registered through it is
# the same lock Git Bash sees, and a machine without Git for Windows gets a
# clear error. Windows only, with Git for Windows on PATH; run it under each
# PowerShell to check (7 as pwsh, 5.1 as powershell). The work directory is
# removed when every check passes and kept, and named, when one fails.

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$wrapper = Join-Path $repo '.local/bin/agent-lock.ps1'
$lock = Join-Path $repo '.local/bin/agent-lock'
# This PowerShell, for the child processes the checks start.
$self = (Get-Process -Id $PID).Path

$tempRoot = [IO.Path]::GetTempPath()
$work = Join-Path $tempRoot "agent-lock-ps1-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $work | Out-Null
$env:AGENT_LOCK_DIR = Join-Path $work 'state'
$env:AGENT_LOCK_POLL = '0.2'
# The bash beside git, for checking from Git Bash what the wrapper registered.
$bash = Join-Path (Split-Path (Split-Path (Split-Path (git --exec-path)))) 'bin/bash.exe'

$failures = [Collections.Generic.List[string]]::new()

# Exit status passes through, a bare `--` is PowerShell's, and `/c` reaches
# cmd unconverted.
& $wrapper job --what status -- cmd /c exit 5
if ($LASTEXITCODE -ne 5) { $failures.Add("job -- cmd /c exit 5 exited $LASTEXITCODE, not 5") }

# Test-Arrived LABEL EXPECTED, after a command run through the wrapper wrote its
# arguments to $out: they were EXPECTED. Each check types its arguments
# literally, as PowerShell parses them before the wrapper sees them.
$out = Join-Path $work 'args.txt'
$printArgs = 'printf "%s\n" "$@" >"$0"'
function Test-Arrived([string]$Label, [string[]]$Expected) {
    $exit = $LASTEXITCODE
    $got = if (Test-Path -LiteralPath $out) { @(Get-Content -LiteralPath $out -Encoding utf8) } else { @('(no output)') }
    Remove-Item -LiteralPath $out -ErrorAction Ignore
    if ($exit -ne 0 -or ($got -join '|') -ne ($Expected -join '|')) {
        $failures.Add("${Label}: arrived as [$($got -join '] [')], not [$($Expected -join '] [')] (exit $exit)")
    }
}

# What MSYS would glob, brace-expand, tilde-expand or unquote, an empty
# argument, and non-ASCII.
$sent = @("it's", '*', '', '{a,b}', '~', 'x"y', 'a  b', "caf$([char]0xE9)", '\')
& $wrapper job -- sh -c $printArgs $out @sent
Test-Arrived 'arguments MSYS would rewrite' $sent

# What PowerShell splits: `-name:value` into two, `a,b` into an array.
& $wrapper job -- sh -c $printArgs $out -p:Configuration=Release --flag=a,b a,b,c -x:"a b"
Test-Arrived 'arguments PowerShell splits' @('-p:Configuration=Release', '--flag=a,b', 'a,b,c', '-x:a b')

# A command that starts with `-` needs a quoted `--`: bare, PowerShell takes it
# and agent-lock refuses the option; quoted, agent-lock runs it (and the shell
# cannot find it). Their stderr is expected, and must not stop this script.
$ErrorActionPreference = 'Continue'
& $wrapper job -- -not-a-command 2>$null
$bare = $LASTEXITCODE
& $wrapper job '--' -not-a-command 2>$null
$quoted = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($bare -ne 2) { $failures.Add("job with a bare -- before -not-a-command exited $bare, not 2") }
if ($quoted -ne 127) { $failures.Add("job with a quoted -- before -not-a-command exited $quoted, not 127") }

# A job registered through the wrapper, seen from a separate Git Bash: listed,
# and its Windows pid found alive, so not stale.
$started = Join-Path $work 'job.started'
$go = Join-Path $work 'job.go'
$state = $env:AGENT_LOCK_DIR
$job = Start-Job -ScriptBlock {
    $env:AGENT_LOCK_DIR = $using:state
    $env:AGENT_LOCK_POLL = '0.2'
    # Its stderr as text, so a failure is reported rather than thrown.
    $log = & $using:wrapper job --what 'from powershell' -- $using:self -NoProfile -Command "New-Item -ItemType File '$using:started' | Out-Null; while (-not (Test-Path '$using:go')) { Start-Sleep -Milliseconds 100 }" 2>&1 |
        ForEach-Object { "$_" }
    [pscustomobject]@{ Code = $LASTEXITCODE; Log = $log -join "`n" }
}
try {
    $deadline = (Get-Date).AddSeconds(60)
    while (-not (Test-Path -LiteralPath $started) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 100 }
    if (-not (Test-Path -LiteralPath $started)) {
        $failures.Add('the job started through the wrapper never ran')
    } else {
        $status = (& $bash $lock status) -join "`n"
        if ($status -notmatch 'jobs: 1 running' -or $status -notmatch ': from powershell') {
            $failures.Add("Git Bash's status does not list the wrapper's job:`n$status")
        }
        if ($status -cmatch '\[STALE') { $failures.Add("Git Bash's status calls the wrapper's running job stale:`n$status") }
    }
} finally {
    New-Item -ItemType File -Path $go -Force | Out-Null
    $result = $job | Wait-Job -Timeout 60 | Receive-Job
    $job | Remove-Job -Force
}
if (-not $result -or $result.Code -ne 0) {
    $failures.Add("the wrapper's job exited '$($result.Code)', not 0: $($result.Log)")
}
$status = (& $bash $lock status) -join "`n"
if ($status -notmatch 'jobs: 0 running') { $failures.Add("the wrapper's job is still registered after it ended:`n$status") }

# Without git on PATH there is no bash to find: a clear error, status 2.
$ErrorActionPreference = 'Continue'
$message = & $self -NoProfile -Command "`$env:PATH = ''; & '$wrapper' status; exit `$LASTEXITCODE" 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($code -ne 2 -or "$message" -notmatch 'no Git for Windows bash found') {
    $failures.Add("without git on PATH the wrapper exited $code with: $message")
}

$version = $PSVersionTable.PSVersion
if ($failures.Count) {
    Write-Host "agent-lock.ps1 tests under PowerShell ${version}: $($failures.Count) failed (work dir kept: $work)"
    $failures | ForEach-Object { Write-Host "::error::$_" }
    exit 1
}
# Only the directory made above: in the temp dir, named for this suite and a
# GUID.
$madeHere = (Split-Path -Parent $work) -eq $tempRoot.TrimEnd('/', '\') -and
    (Split-Path -Leaf $work) -match '^agent-lock-ps1-[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$'
if ($madeHere) {
    Remove-Item -LiteralPath $work -Recurse -Force
} else {
    Write-Host "not removing ${work}: not the work dir this run made"
}
Write-Host "agent-lock.ps1 tests under PowerShell ${version}: 0 failed"
