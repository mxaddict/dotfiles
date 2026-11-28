# Windows ignores agent-lock's shebang, so this runs the bash script beside it
# with Git for Windows' bash: `agent-lock job -- cargo build` then works from
# PowerShell (7, or Windows PowerShell 5.1) as it does elsewhere, on the same
# lock. Not `bash` from PATH, which may be WSL's, with its own processes and
# home. That bash is found from git itself, which works through scoop's shim
# too.
#
# The arguments travel in the environment, not on bash's command line: an MSYS
# program parses its Windows command line itself, expanding globs, braces and ~
# and taking ' as a quote, so `-m "it's"` would arrive mangled. The bash code
# that unpacks them travels the same way, as Windows PowerShell 5.1 does not
# escape the double quotes in an argument it passes.
#
# MSYS also rewrites arguments that look like POSIX paths when it starts a
# Windows program (`cmd /c` would run `cmd C:/`, `/p:Configuration=Release`
# would become a path), and a command typed in PowerShell is a Windows command,
# so conversion is turned off with MSYS2_ARG_CONV_EXCL. Everything the command
# starts inherits that, an MSYS bash script among them.
#
# PowerShell parses a script's arguments before this sees them, and some of
# that is undone here, the rest has to be quoted:
# - `-name:value` arrives as `-name:` and `value`, and is joined back. So is a
#   `-name:` written apart from the word after it, which a native command
#   would have received as two.
# - `a,b` (`--flag=a,b` too) arrives as an array, and is joined back with
#   commas. So is an array variable, which a native command would have
#   received as separate arguments: splat it, `@list`.
# - A bare number arrives as its value: `007` as 7, `0x10` as 16, `1.50` as
#   1.5, `1kb` as 1024. Quote it, `'007'`, to keep its spelling.
# - The first bare `--` on a command line is PowerShell's own end of
#   parameters, so agent-lock never sees it. agent-lock's options end at the
#   first word that is not one anyway, so that only matters for a command that
#   starts with `-`: write `'--'` to pass it through.

# bash's stderr must never turn into a terminating error here, as it would
# under 5.1 for a caller with $ErrorActionPreference = 'Stop' that redirects it.
$ErrorActionPreference = 'Continue'

$git = Get-Command git -CommandType Application -ErrorAction Ignore | Select-Object -First 1
$execPath = if ($git) { & $git --exec-path }
$bash = $null
# The exec path is <Git>\<mingw64|ucrt64|...>\libexec\git-core; bash sits in
# <Git>\bin.
for ($dir = $execPath; $dir; $dir = Split-Path -Parent $dir) {
    $candidate = Join-Path $dir 'bin\bash.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $bash = $candidate
        break
    }
}
if (-not $bash) {
    [Console]::Error.WriteLine("agent-lock: no Git for Windows bash found from git --exec-path ('$execPath'); agent-lock.ps1 needs Git for Windows on PATH")
    exit 2
}

$argv = [Collections.Generic.List[string]]::new()
foreach ($arg in $args) {
    $text = if ($arg -is [array]) { ($arg | ForEach-Object { "$_" }) -join ',' } else { "$arg" }
    $last = $argv.Count - 1
    if ($last -ge 0 -and $argv[$last] -match '^-[^:]+:$') {
        $argv[$last] += $text
    } else {
        $argv.Add($text)
    }
}

# Rebuilds the arguments from the environment, clears it, and runs agent-lock.
# It reaches bash through eval of an unquoted expansion, with globbing off: the
# words are rejoined with single spaces, which this one line of code survives.
$run = 'for ((i = 0; i < AGENT_LOCK_PS1_ARGC; i++)); do v=AGENT_LOCK_PS1_ARG_$i; set -- "$@" "${!v-}"; unset "$v"; done; s=$AGENT_LOCK_PS1_SCRIPT; unset AGENT_LOCK_PS1_ARGC AGENT_LOCK_PS1_SCRIPT AGENT_LOCK_PS1_RUN; export MSYS2_ARG_CONV_EXCL="*"; exec "$BASH" "$s" "$@"'
$values = [ordered]@{
    AGENT_LOCK_PS1_RUN    = $run
    AGENT_LOCK_PS1_SCRIPT = Join-Path $PSScriptRoot 'agent-lock'
    AGENT_LOCK_PS1_ARGC   = "$($argv.Count)"
}
for ($i = 0; $i -lt $argv.Count; $i++) {
    # An empty value unsets the variable, which bash reads back as empty.
    $values["AGENT_LOCK_PS1_ARG_$i"] = $argv[$i]
}
$status = 2
try {
    foreach ($name in $values.Keys) { [Environment]::SetEnvironmentVariable($name, $values[$name]) }
    & $bash -c 'set -f; eval $AGENT_LOCK_PS1_RUN'
    $status = $LASTEXITCODE
} finally {
    foreach ($name in $values.Keys) { [Environment]::SetEnvironmentVariable($name, $null) }
}
exit $status
