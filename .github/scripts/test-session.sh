#!/usr/bin/env bash
# Runs the "Starting a Claude session" flow from .config/agents/AGENTS.md the
# way an agent does: from a shell with no terminal, against the dotfiles krypt
# deployed into $HOME. `t` (through fish, or pwsh on Windows) creates the tmxr
# session, or the one already there is used, `c` is typed into it, the trust
# menu is answered, and the result is checked. Both cases run: a session the
# user made earlier with t, then a directory with none. Runs in bash on Linux, macOS and Windows (Git Bash), with tmxr, fish
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
reused_dir="$work/flow.reused"
reused=flow.reused
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

capture() { tmxr capture-pane -p -t "$1"; }
wait_for() {
    local out
    for _ in $(seq 1 "$3"); do
        out=$(capture "$1")
        grep -qF -- "$2" <<<"$out" && return 0
        sleep 1
    done
    printf '%s\n' "$out"
    fail "timed out after $3s waiting for: $2"
}
pane() { tmxr display-message -p -t "$1" "#{$2}"; }
sessions() { tmxr list-sessions -F '#{session_name}' | sort | paste -sd ' ' -; }
# t, run as an agent runs it: through the shell that defines it, in the
# directory, with no terminal.
t_in() {
    if $windows; then
        pwsh -Command "Set-Location -LiteralPath '$(native "$1")'; t" </dev/null
    else
        fish -c "cd '$1'; and t" </dev/null
    fi
}
# The shell tmxr panes start, as #{pane_current_command} names it.
shell=fish
$windows && shell=pwsh
trap 'tmxr kill-server 2>/dev/null || true' EXIT

# The flow's steps, for session $1 in directory $2.
start_claude() {
    local name=$1 dir=$2 path command

    # 1. Use the session if it already exists, when its pane is at the shell
    # in the directory.
    if tmxr has-session -t "$name" 2>/dev/null; then
        path=$(pane "$name" pane_current_path)
        command=$(pane "$name" pane_current_command)
        [ "$path" = "$(native "$dir")" ] && [ "$command" = "$shell" ] ||
            fail "the existing session $name is at $command in $path, not $shell in $(native "$dir")"
    else
        # 2. Create it with t in the directory, and confirm where it landed.
        t_in "$dir"
        path=$(pane "$name" pane_current_path)
    fi
    tmxr display-message -p -t "$name" '#{pane_current_path} #{pane_current_command}'

    # 3. Start Claude with c, and wait for the trust menu.
    tmxr send-keys -t "$name" 'c' Enter
    wait_for "$name" 'Yes, I trust this folder' 60

    # 4. "No, exit" starts selected; move to Yes and confirm it before Enter.
    grep -qF -- '❯ No, exit' <<<"$(capture "$name")" || {
        capture "$name"
        fail 'the trust menu did not start on "No, exit"'
    }
    tmxr send-keys -t "$name" Down
    wait_for "$name" '❯ Yes, I trust this folder' 15
    tmxr send-keys -t "$name" Enter

    # 5. Verify: Claude is up, the trust is saved under the directory, the
    # session is in it, and c passed the user's flags, falling back from
    # --continue to a fresh start.
    wait_for "$name" 'Claude stub ready' 30
    pwsh -NoProfile -File "$(native "$repo/.github/scripts/test-session-check.ps1")" \
        -Directory "$(native "$dir")" -PanePath "$path" -Log "$CLAUDE_STUB_LOG"

    # 6. Report.
    echo "Claude started in session $name in $(native "$dir"); attach with: tmxr attach -t $name"
}

# A session the user made earlier with t, idle at the shell. It must be t's
# work alone: a session tmxr restored from an earlier server's save is not.
mkdir -p "$reused_dir"
t_in "$reused_dir"
[ "$(sessions)" = "$reused" ] || fail "expected only a session named $reused, found: $(sessions)"
# Its shell's process: a session killed and made again gets a new one.
reused_shell=$(pane "$reused" pane_pid)
start_claude "$reused" "$reused_dir"
[ "$(pane "$reused" pane_pid)" = "$reused_shell" ] ||
    fail "Claude is not in the shell of the existing session $reused"
[ "$(sessions)" = "$reused" ] || fail "reusing $reused left sessions: $(sessions)"

# A directory with no session yet: t makes one, and only one.
start_claude "$name" "$dir"
[ "$(sessions)" = "$reused $name" ] || fail "expected sessions $reused $name, found: $(sessions)"
