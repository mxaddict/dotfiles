#!/usr/bin/env bash
# Runs the "Starting a Claude session" flow from .config/agents/AGENTS.md the
# way an agent does: from a shell with no terminal, against the dotfiles krypt
# deployed into $HOME. `t` (through fish, or pwsh on Windows) creates the tmxr
# session, `c` is typed into it, the trust menu is answered, and the result is
# checked. Runs in bash on Linux, macOS and Windows (Git Bash), with tmxr, fish
# (not on Windows) and pwsh on PATH. claude is claude-stub.ps1, since the real
# CLI cannot log in here; everything else is what a user's machine runs.
set -euo pipefail

# It kills the tmxr server when it ends and writes ~/.claude.json, so it runs
# only where both are throwaway.
[ "${CI:-}" = true ] || {
    echo "CI only: it kills the tmxr server and writes ~/.claude.json" >&2
    exit 1
}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
windows=false
[ "${RUNNER_OS:-}" = Windows ] && windows=true

fail() {
    echo "::error::$*"
    exit 1
}
# A path as native programs (pwsh, tmxr) spell it.
native() { if $windows; then cygpath -w "$1"; else printf '%s\n' "$1"; fi; }

base=${RUNNER_TEMP:-$(mktemp -d)}
$windows && base=$(cygpath -u "$base")
work="$base/session-flow"
dir="$work/flow.test"
name=flow.test
mkdir -p "$dir" "$work/bin"

# claude on PATH is the stub, so the aliases reach it as they reach the CLI.
stub=$(native "$repo/.github/scripts/claude-stub.ps1")
CLAUDE_STUB_LOG=$(native "$work/claude-stub.log")
export CLAUDE_STUB_LOG
if $windows; then
    printf '@pwsh -NoProfile -File "%s" %%*\r\n' "$stub" >"$work/bin/claude.cmd"
else
    printf '#!/usr/bin/env bash\nexec pwsh -NoProfile -File "%s" "$@"\n' "$stub" >"$work/bin/claude"
    chmod +x "$work/bin/claude"
    # tmxr panes start $SHELL: fish, the user's login shell.
    SHELL=$(command -v fish)
    export SHELL
fi
export PATH="$work/bin:$PATH"

capture() { tmxr capture-pane -p -t "$name"; }
wait_for() {
    local out
    for _ in $(seq 1 "$2"); do
        out=$(capture)
        grep -qF -- "$1" <<<"$out" && return 0
        sleep 1
    done
    printf '%s\n' "$out"
    fail "timed out after $2s waiting for: $1"
}
trap 'tmxr kill-server 2>/dev/null || true' EXIT

# 1. The name is free.
if tmxr has-session -t "$name" 2>/dev/null; then
    fail "a session named $name already exists"
fi

# 2. Create it with t in the directory, and confirm where it landed.
if $windows; then
    pwsh -Command "Set-Location -LiteralPath '$(native "$dir")'; t" </dev/null
else
    fish -c "cd '$dir'; and t" </dev/null
fi
# The only session: t started this server, and a session tmxr restored from an
# earlier server's save would not be t's work.
sessions=$(tmxr list-sessions -F '#{session_name}')
[ "$sessions" = "$name" ] || fail "expected only a session named $name, found: $sessions"
path=$(tmxr display-message -p -t "$name" '#{pane_current_path}')
tmxr display-message -p -t "$name" '#{pane_current_path} #{pane_current_command}'

# 3. Start Claude with c, and wait for the trust menu.
tmxr send-keys -t "$name" 'c' Enter
wait_for 'Yes, I trust this folder' 60

# 4. "No, exit" starts selected; move to Yes and confirm it before Enter.
grep -qF -- '❯ No, exit' <<<"$(capture)" || {
    capture
    fail 'the trust menu did not start on "No, exit"'
}
tmxr send-keys -t "$name" Down
wait_for '❯ Yes, I trust this folder' 15
tmxr send-keys -t "$name" Enter

# 5. Verify: Claude is up, the trust is saved under the directory, the session
# is where t was run, and c passed the user's flags, falling back from
# --continue to a fresh start.
wait_for 'Claude stub ready' 30
pwsh -NoProfile -File "$(native "$repo/.github/scripts/test-session-check.ps1")" \
    -Directory "$(native "$dir")" -PanePath "$path" -Log "$CLAUDE_STUB_LOG"

# 6. Report.
echo "session $name started in $(native "$dir"); attach with: tmxr attach -t $name"
