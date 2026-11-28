#!/usr/bin/env bash
# Tests agent-lock's protocol end to end: jobs share the machine, a measurement
# excludes them and other measurements, entries a dead process left are cleaned
# up while live ones are kept, a measurement's expiry counts from the end of
# its drain, exits and signals release what was taken, a lost lock is reported,
# nested calls do not deadlock, and status reads well. Each case runs in its
# own state directory with a short poll. Runs in bash on Linux, macOS and
# Windows (Git Bash). A case that cannot fail on this OS reports itself
# skipped. The work directory is removed when every case passes and kept, and
# named, when one fails.
#
#   test-agent-lock.sh [AGENT-LOCK]   (default: .local/bin/agent-lock here)
#
# AGENT_LOCK_BASH names the bash to run agent-lock with (macOS: /bin/bash, the
# 3.2 a user's `env bash` may find); without it agent-lock runs by its shebang.
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
real_lock=${1:-$repo/.local/bin/agent-lock}
tmp=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
# The runner's temp dir is a Windows path there (D:\a\_temp); the cases compare
# paths as bash spells them.
command -v cygpath >/dev/null && tmp=$(cygpath -u "$tmp")
prefix=$tmp/agent-lock-test.
base=$(mktemp -d "${prefix}XXXXXX") || exit 1
export AGENT_LOCK_POLL=0.2
# Seconds of wall clock. TIMEOUT bounds a wait that should end: long enough for
# a slow runner, shorter than agent-lock's MUTEX_STALE_MIN, so a held mutex is
# never yet stale. QUIET is how long a negative check watches, once a positive
# sign (a waiting line in the log) says the thing it watches has had its chance.
TIMEOUT=30
QUIET=3

lock=$real_lock
if [ -n "${AGENT_LOCK_BASH:-}" ]; then
    lock=$base/agent-lock
    printf '#!/bin/sh\nexec "%s" "%s" "$@"\n' "$AGENT_LOCK_BASH" "$real_lock" >"$lock"
    chmod +x "$lock"
    echo "agent-lock runs under $AGENT_LOCK_BASH: $("$AGENT_LOCK_BASH" --version | head -n1)"
else
    echo "agent-lock runs under $(command -v bash): $(bash --version | head -n1)"
fi

# A command that marks $M/NAME.started, then waits for $M/NAME.go (or
# $M/ALL.go, every gate's) and exits with the number in $M/NAME.exit (0
# without one).
gate=$base/gate
cat >"$gate" <<'EOF'
#!/usr/bin/env bash
touch "$M/$1.started"
while [ ! -e "$M/$1.go" ] && [ ! -e "$M/ALL.go" ]; do sleep 0.05; done
exit "$(cat "$M/$1.exit" 2>/dev/null || echo 0)"
EOF
# Gate NAME, then an inner `agent-lock job` that records in $M/NAME.count how
# many jobs are registered while it runs.
nested=$base/nested
cat >"$nested" <<'EOF'
#!/usr/bin/env bash
"$GATE" "$1" || exit
"$LOCK" job --what inner -- sh -c 'ls "$AGENT_LOCK_DIR/jobs" | wc -l | tr -d " " >"$M/$0.count"' "$1"
EOF
# A ps that fails, for liveness that cannot be told.
mkdir "$base/failing-ps"
printf '#!/bin/sh\nexit 1\n' >"$base/failing-ps/ps"
# A date that refuses GNU's -d, as BSD's does, and takes BSD's -r SECONDS
# (handing it to the real date as -d @SECONDS where that is GNU's).
mkdir "$base/bsd-date"
cat >"$base/bsd-date/date" <<'EOF'
#!/usr/bin/env bash
real=$REAL_DATE
for a in "$@"; do case $a in -d*) exit 1 ;; esac; done
"$real" -d @0 >/dev/null 2>&1 || exec "$real" "$@"
args=()
while [ $# -gt 0 ]; do
    case $1 in
    -r) args+=(-d "@$2") && shift 2 ;;
    *) args+=("$1") && shift ;;
    esac
done
exec "$real" "${args[@]}"
EOF
chmod +x "$gate" "$nested" "$base/failing-ps/ps" "$base/bsd-date/date"
REAL_DATE=$(command -v date)
export GATE=$gate LOCK=$lock REAL_DATE

pids=()
# Stops whatever a failed case left running: the agent-locks by the pids it
# started, and the gates they ran (which a SIGKILLed agent-lock leaves behind,
# one perhaps still starting) by opening them all.
stop_all() {
    local p
    for p in ${pids[@]+"${pids[@]}"}; do kill -9 "$p" 2>/dev/null; done
    pids=()
    [ -d "${M:-}" ] && touch "$M/ALL.go"
}
trap stop_all EXIT

# Starts agent-lock in the background with its output in $M/NAME.log; its pid
# is in $!.
bg() {
    local name=$1
    shift
    "$lock" "$@" >"$M/$name.log" 2>&1 &
    pids+=($!)
}

fail() {
    FAILED=$*
    return 1
}
SKIP=77
# A case calls `skip REASON; return` where it cannot fail on this OS.
skip() {
    SKIPPED=$*
    return "$SKIP"
}
release() { touch "$M/$1.go"; }
started() { [ -e "$M/$1.started" ]; }
# logged NAME TEXT: agent-lock NAME's output has TEXT.
logged() { grep -qF -- "$2" "$M/$1.log"; }
jobs_count() {
    local n=0 f
    for f in "$AGENT_LOCK_DIR/jobs"/*; do [ -e "$f" ] && n=$((n + 1)); done
    echo "$n"
}
no_jobs() { [ "$(jobs_count)" = 0 ]; }
perf_held() { [ -d "$AGENT_LOCK_DIR/perf" ]; }
owner=perf/owner
# entry_field FILE KEY: KEY's value in an entry under the state dir.
entry_field() { sed -n "s/^$2=//p" "$AGENT_LOCK_DIR/$1"; }

# wait_until DESCRIPTION COMMAND...: polls COMMAND until it succeeds.
wait_until() {
    local what=$1 end=$((SECONDS + TIMEOUT))
    shift
    until "$@"; do
        [ "$SECONDS" -lt "$end" ] || fail "timed out after ${TIMEOUT}s waiting until $what" || return
        sleep 0.05
    done
}

# Watches for QUIET seconds that COMMAND stays false.
stays_false() {
    local what=$1 end=$((SECONDS + QUIET))
    shift
    while [ "$SECONDS" -lt "$end" ]; do
        if "$@"; then
            fail "$what"
            return 1
        fi
        sleep 0.05
    done
    return 0
}

# wait_exit PID: waits for a background agent-lock to end and sets STATUS.
wait_exit() {
    local end=$((SECONDS + TIMEOUT))
    while kill -0 "$1" 2>/dev/null; do
        if [ "$SECONDS" -ge "$end" ]; then
            kill -9 "$1" 2>/dev/null
            fail "pid $1 still running after ${TIMEOUT}s"
            return 1
        fi
        sleep 0.05
    done
    wait "$1"
    STATUS=$?
}

expect_status() {
    [ "$STATUS" = "$1" ] || fail "$2 exited $STATUS, not $1"
}

# set_field FILE KEY VALUE: rewrites KEY in an entry under the state dir.
set_field() {
    sed "s/^$2=.*/$2=$3/" "$AGENT_LOCK_DIR/$1" >"$M/entry.tmp" && mv -f "$M/entry.tmp" "$AGENT_LOCK_DIR/$1"
}
# Rewrites an entry's expiry to the epoch's first second, as if it had been
# taken long ago with a short --expires.
expire() { set_field "$1" expires_epoch 1; }
only_job() {
    local f
    for f in "$AGENT_LOCK_DIR/jobs"/*; do printf '%s\n' "jobs/${f##*/}"; done
}

case_jobs_run_together() {
    bg a job --what a -- "$gate" a
    local a=$!
    bg b job --what b -- "$gate" b
    local b=$!
    wait_until "both jobs are inside their command" eval 'started a && started b' || return
    [ "$(jobs_count)" = 2 ] || fail "$(jobs_count) jobs registered while two run" || return
    release a
    release b
    wait_exit $a && expect_status 0 "job a" || return
    wait_exit $b && expect_status 0 "job b" || return
    [ "$(jobs_count)" = 0 ] || fail "$(jobs_count) job files left after both ended"
}

case_job_waits_for_perf() {
    local id j
    id=$("$lock" perf-acquire --what held 2>"$M/acquire.log") || fail "perf-acquire exited $?" || return
    bg j job -- "$gate" j
    j=$!
    wait_until "the job says it waits for the perf lock" logged j 'waiting: perf lock held' || return
    logged j 'taken back after' || fail "the job does not say when the lock is taken back: $(cat "$M/j.log")" || return
    stays_false "the job started while perf/ was held" started j || return
    "$lock" perf-release "$id" || fail "perf-release exited $?" || return
    wait_until "the job starts after the release" started j || return
    release j
    wait_exit $j && expect_status 0 "job"
}

case_perf_waits_for_job() {
    local j p
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    bg p perf -- "$gate" p
    p=$!
    wait_until "the measurement says it waits for the job" logged p 'waiting for 1 running job' || return
    stays_false "the measurement ran while a job was running" started p || return
    release j
    wait_exit $j && expect_status 0 "job" || return
    wait_until "the measurement runs once the job is done" started p || return
    release p
    wait_exit $p && expect_status 0 "perf" || return
    ! perf_held || fail "perf/ left after the measurement ended"
}

case_perf_excludes_perf() {
    local a b
    bg a perf -- "$gate" a
    a=$!
    wait_until "the first measurement runs" started a || return
    bg b perf -- "$gate" b
    b=$!
    wait_until "the second measurement says it waits" logged b 'waiting: perf lock held' || return
    stays_false "two measurements ran at once" started b || return
    release a
    wait_exit $a && expect_status 0 "the first measurement" || return
    wait_until "the second measurement runs after the first" started b || return
    release b
    wait_exit $b && expect_status 0 "the second measurement"
}

case_killed_job_is_cleaned() {
    local j p
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    kill -9 $j
    wait $j 2>/dev/null
    release j
    [ "$(jobs_count)" = 1 ] || fail "the killed job's file is not there to clean" || return
    "$lock" clean 2>"$M/clean.log" || fail "clean exited $?" || return
    [ "$(jobs_count)" = 0 ] || fail "clean kept the file of a killed job" || return

    bg k job -- "$gate" k
    j=$!
    wait_until "the second job is running" started k || return
    kill -9 $j
    wait $j 2>/dev/null
    release k
    bg p perf -- true
    p=$!
    wait_exit $p && expect_status 0 "perf after a killed job" || return
    [ "$(jobs_count)" = 0 ] || fail "the measurement did not remove the killed job's file"
}

# The state dir is local: a host name that changed since (macOS renames itself
# by network) does not keep a dead job's entry.
case_host_is_display_only() {
    local j
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    kill -9 $j
    wait $j 2>/dev/null
    release j
    set_field "$(only_job)" host elsewhere
    "$lock" clean 2>"$M/clean.log" || fail "clean exited $?" || return
    [ "$(jobs_count)" = 0 ] || fail "clean kept a dead job recorded under another host name"
}

case_live_job_past_expiry_is_kept() {
    local j
    bg j job --expires 0 -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    expire "$(only_job)"
    "$lock" clean 2>"$M/clean.log" || fail "clean exited $?" || return
    [ "$(jobs_count)" = 1 ] || fail "clean removed a running job past its expiry" || return
    release j
    wait_exit $j && expect_status 0 "job"
}

# A recorded pid that now names a process started at another time is a reused
# pid: the job is gone. An unknown start time falls back to the pid alone.
case_pid_reuse_reads_dead() {
    local j k
    bg j job -- "$gate" j
    j=$!
    bg k job -- "$gate" k
    k=$!
    wait_until "both jobs are running" eval 'started j && started k' || return
    local jf kf f
    for f in $(only_job); do
        case $(entry_field "$f" command) in
        *" j") jf=$f ;;
        *" k") kf=$f ;;
        esac
    done
    set_field "$jf" pid_start 99:99:99
    set_field "$kf" pid_start ''
    "$lock" clean 2>"$M/clean.log" || fail "clean exited $?" || return
    [ ! -e "$AGENT_LOCK_DIR/$jf" ] || fail "clean kept a job whose pid now has another start time" || return
    [ -e "$AGENT_LOCK_DIR/$kf" ] || fail "clean removed a live job that recorded no start time" || return
    grep -qF 'is now another process' "$M/clean.log" || fail "no reason given: $(cat "$M/clean.log")" || return
    release j
    release k
    wait_exit $j && wait_exit $k
}

# A ps that fails says nothing about whether a process lives: its entries stay.
# On Windows ps -W is the liveness check, on macOS it reads the start time;
# on Linux kill -0 and /proc decide, and ps is never asked.
case_unknown_liveness_is_alive() {
    local j out
    [ "$(uname -s)" = Linux ] && {
        skip "Linux tells liveness by kill -0 and /proc, without ps"
        return
    }
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    PATH="$base/failing-ps:$PATH" "$lock" clean 2>"$M/clean.log" || fail "clean exited $?" || return
    [ "$(jobs_count)" = 1 ] || fail "clean removed a job whose liveness ps could not tell" || return
    out=$(PATH="$base/failing-ps:$PATH" "$lock" status)
    if grep -q STALE <<<"$out"; then
        fail "status calls a job stale when ps fails: $out"
        return 1
    fi
    release j
    wait_exit $j && expect_status 0 "job"
}

# The lock was taken from a running measurement (its expiry passed): the
# measurement says so and exits LOST_EXIT, and so does perf-extend for it.
case_lost_lock_is_reported() {
    local p j id
    bg p perf -- "$gate" p
    p=$!
    wait_until "the measurement is running" started p || return
    id=$(entry_field "$owner" id)
    expire "$owner"
    bg j job -- true
    j=$!
    wait_exit $j && expect_status 0 "job after an expired perf lock" || return
    ! perf_held || fail "an expired perf lock with a live pid was kept" || return
    "$lock" perf-extend "$id" 2>"$M/extend.log"
    STATUS=$?
    expect_status 3 "perf-extend of a lost lock" || return
    grep -qF 'LOST' "$M/extend.log" || fail "perf-extend did not say the lock was lost: $(cat "$M/extend.log")" || return
    release p
    wait_exit $p && expect_status 3 "a measurement that lost its lock" || return
    logged p 'busy machine' || fail "the measurement did not warn about its numbers"
}

# A drain that outlasts the measurement's expiry: the lock holds (only a dead
# process frees it then), and its expiry counts from the drain's end.
case_drain_outlasts_expiry() {
    local j p k t
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    bg p perf --expires 0 -- "$gate" p
    p=$!
    wait_until "the measurement says it waits for the job" logged p 'waiting for 1 running job' || return
    expire "$owner"
    bg k job -- "$gate" k
    k=$!
    wait_until "a new job says it waits for the perf lock" logged k 'waiting: perf lock held' || return
    logged k 'it gives up at' || fail "the job does not say when the drain gives up: $(cat "$M/k.log")" || return
    stays_false "a job got in while a measurement waited past its expiry" started k || return
    t=$(date +%s)
    release j
    wait_exit $j && expect_status 0 "the first job" || return
    wait_until "the measurement runs" started p || return
    [ "$(entry_field "$owner" expires_epoch)" -ge "$t" ] ||
        fail "the expiry was not counted from the end of the drain" || return
    stays_false "a job got in during the measurement" started k || return
    release p
    wait_exit $p && expect_status 0 "the measurement" || return
    wait_until "the waiting job runs after the measurement" started k || return
    release k
    wait_exit $k && expect_status 0 "the waiting job"
}

# The lock changed hands while the measurement drained: it does not measure.
case_lost_during_drain() {
    local j p
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    bg p perf -- "$gate" p
    p=$!
    wait_until "the measurement says it waits for the job" logged p 'waiting for 1 running job' || return
    set_field "$owner" id someone-else
    release j
    wait_exit $j && expect_status 0 "job" || return
    wait_exit $p && expect_status 3 "a measurement whose lock changed hands while it drained" || return
    ! started p || fail "the measurement ran on a lock it no longer held"
}

case_killed_perf_is_removed() {
    local p j
    bg p perf -- "$gate" p
    p=$!
    wait_until "the measurement is running" started p || return
    kill -9 $p
    wait $p 2>/dev/null
    release p
    perf_held || fail "the killed measurement left no lock to clean" || return
    bg j job -- true
    j=$!
    wait_exit $j && expect_status 0 "job after a killed measurement" || return
    ! perf_held || fail "the killed measurement's lock was kept"
}

# A drain past --drain gives up: the measurement does not run, the lock is
# released, the jobs still running are named, and the exit says so.
case_drain_limit() {
    local j k
    bg j job --what "a watcher" -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    # In the background, so a drain that never gives up fails the wait instead
    # of hanging the suite.
    bg p perf --drain 0 -- touch "$M/perf.ran"
    wait_exit $! && expect_status 4 "a measurement past its drain limit" || return
    [ ! -e "$M/perf.ran" ] || fail "a measurement ran though its jobs never drained" || return
    ! perf_held || fail "a measurement that gave up kept the lock" || return
    logged p 'giving up' && logged p ': a watcher' || fail "no list of the jobs still running: $(cat "$M/p.log")" || return
    "$lock" perf-acquire --drain 0 >"$M/acquire.out" 2>"$M/a.log" &
    pids+=($!)
    wait_exit $! && expect_status 4 "perf-acquire past its drain limit" || return
    [ ! -s "$M/acquire.out" ] || fail "perf-acquire printed an id though it gave up" || return
    ! perf_held || fail "perf-acquire that gave up kept the lock" || return
    "$lock" job --drain 1 -- true 2>"$M/k.log"
    STATUS=$?
    expect_status 2 "job with --drain" || return
    bg k job -- true
    k=$!
    wait_exit $k && expect_status 0 "a job after the measurement gave up" || return
    release j
    wait_exit $j
}

# perf-acquire whose id cannot be handed over releases the lock: no pid-less
# lock is left that nobody knows the id of.
case_perf_acquire_unprinted_id() {
    "$lock" perf-acquire >&- 2>"$M/a.log"
    STATUS=$?
    [ "$STATUS" != 0 ] || fail "perf-acquire with a closed stdout exited 0" || return
    ! perf_held || fail "perf-acquire kept a lock whose id it could not print: $(cat "$AGENT_LOCK_DIR/$owner")"
}

# perf-acquire killed while it waits for the jobs: its pid frees the lock.
case_perf_acquire_killed_mid_drain() {
    local j a k
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    bg a perf-acquire
    a=$!
    wait_until "perf-acquire says it waits for the job" logged a 'waiting for 1 running job' || return
    kill -9 $a
    wait $a 2>/dev/null
    bg k job -- true
    k=$!
    wait_exit $k && expect_status 0 "a job after perf-acquire was killed mid-drain" || return
    ! perf_held || fail "the killed perf-acquire's lock was kept" || return
    release j
    wait_exit $j
}

case_exit_status_and_release() {
    "$lock" job -- sh -c 'exit 3'
    STATUS=$?
    expect_status 3 "a failing job" || return
    [ "$(jobs_count)" = 0 ] || fail "a failing job left its file" || return
    "$lock" perf -- sh -c 'exit 4'
    STATUS=$?
    expect_status 4 "a failing measurement" || return
    ! perf_held || fail "a failing measurement kept perf/"
}

# SIGTERM to agent-lock alone: the lock is held while the command runs, and
# released with status 143 once it returns.
case_sigterm_releases() {
    local j
    bg j job -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    kill -TERM $j
    stays_false "the job was released while its command still ran" no_jobs || return
    release j
    wait_exit $j && expect_status 143 "a terminated job" || return
    [ "$(jobs_count)" = 0 ] || fail "a terminated job left its file"
}

# SIGINT to the process group, as a terminal's Ctrl+C sends it. Job control
# gives the background job its own group and keeps SIGINT from being ignored.
case_sigint_releases() {
    local p
    set -m
    bg p perf -- "$gate" p
    p=$!
    set +m
    wait_until "the measurement is running" started p || return
    kill -INT -- -$p
    wait_exit $p && expect_status 130 "an interrupted measurement" || return
    ! perf_held || fail "an interrupted measurement kept perf/"
}

case_nested_job_in_job() {
    local o p
    bg o job --what outer -- "$nested" o
    o=$!
    wait_until "the outer job is running" started o || return
    # A measurement now waits on the outer job, with perf/ held: an inner job
    # that waited for perf/ would never run.
    bg p perf -- touch "$M/perf.ran"
    p=$!
    wait_until "the measurement holds perf/" perf_held || return
    release o
    wait_exit $o && expect_status 0 "the outer job" || return
    [ "$(cat "$M/o.count" 2>/dev/null)" = 1 ] ||
        fail "$(cat "$M/o.count" 2>/dev/null) jobs registered inside a nested job, not 1" || return
    wait_exit $p && expect_status 0 "perf" || return
    [ -e "$M/perf.ran" ] || fail "the measurement did not run"
}

case_nested_job_in_perf() {
    local p
    release i
    bg p perf -- "$nested" i
    p=$!
    wait_exit $p && expect_status 0 "a measurement running a nested job" || return
    [ "$(cat "$M/i.count" 2>/dev/null)" = 0 ] ||
        fail "$(cat "$M/i.count" 2>/dev/null) jobs registered by a job inside perf, not 0"
}

case_perf_in_job_is_refused() {
    local j
    bg j job -- "$lock" perf -- true
    j=$!
    wait_exit $j && expect_status 2 "a measurement inside a job" || return
    grep -q 'would wait for that job forever' "$M/j.log" || fail "no reason given: $(cat "$M/j.log")"
}

case_perf_extend_keeps_owner() {
    local p id before after
    bg p perf -- "$gate" p
    p=$!
    wait_until "the measurement is running" started p || return
    before=$(grep -v '^expires' "$AGENT_LOCK_DIR/$owner")
    id=$(entry_field "$owner" id)
    expire "$owner"
    "$lock" perf-extend "$id" --expires 90 2>"$M/extend.log" || fail "perf-extend exited $?" || return
    after=$(grep -v '^expires' "$AGENT_LOCK_DIR/$owner")
    [ "$before" = "$after" ] || fail "perf-extend changed more than the expiry: $before -> $after" || return
    [ "$(entry_field "$owner" expires_epoch)" -gt "$(date +%s)" ] ||
        fail "perf-extend did not move the expiry forward" || return
    release p
    wait_exit $p && expect_status 0 "perf"
}

# perf-extend that cannot write the new owner says so, and changes nothing.
case_perf_extend_write_failure() {
    local id before
    id=$("$lock" perf-acquire 2>"$M/acquire.log") || fail "perf-acquire exited $?" || return
    before=$(cat "$AGENT_LOCK_DIR/$owner")
    mkdir "$AGENT_LOCK_DIR/tmp.$id"
    "$lock" perf-extend "$id" --expires 90 2>"$M/extend.log"
    STATUS=$?
    rmdir "$AGENT_LOCK_DIR/tmp.$id"
    expect_status 2 "perf-extend that could not write" || return
    [ "$(cat "$AGENT_LOCK_DIR/$owner")" = "$before" ] || fail "a failed perf-extend changed the owner" || return
    "$lock" perf-release "$id"
}

case_fresh_state_dir() {
    export AGENT_LOCK_DIR=$M/fresh
    bg c clean
    wait_exit $! && expect_status 0 "clean on a state dir that does not exist yet" || return
    bg r perf-release nobody
    wait_exit $! && expect_status 3 "perf-release of a lock nobody holds"
}

# A mutex left by a process that died inside it is removed; a fresh one is
# waited for.
case_stale_mutex() {
    local a
    mkdir -p "$AGENT_LOCK_DIR/jobs" "$AGENT_LOCK_DIR/mutex"
    bg a perf-acquire
    a=$!
    stays_false "perf-acquire took a fresh mutex from its holder" perf_held || return
    touch -t 202001010000 "$AGENT_LOCK_DIR/mutex"
    wait_exit $a && expect_status 0 "perf-acquire past an old mutex" || return
    logged a 'removing a mutex left by a dead process' || fail "no reason given: $(cat "$M/a.log")" || return
    "$lock" perf-release "$(entry_field "$owner" id)"
}

case_clean_removes_old_tmp() {
    mkdir -p "$AGENT_LOCK_DIR/jobs"
    touch "$AGENT_LOCK_DIR/tmp.old" "$AGENT_LOCK_DIR/tmp.new"
    touch -t 202001010000 "$AGENT_LOCK_DIR/tmp.old"
    "$lock" clean 2>"$M/clean.log" || fail "clean exited $?" || return
    [ ! -e "$AGENT_LOCK_DIR/tmp.old" ] || fail "clean kept an old temporary file" || return
    [ -e "$AGENT_LOCK_DIR/tmp.new" ] || fail "clean removed a temporary file a writer may still rename"
}

# iso_matches EPOCH ISO OFFSET OFFSET_SECONDS: ISO is EPOCH's local time in a
# zone OFFSET_SECONDS east of UTC, spelled with OFFSET.
iso_matches() {
    local utc
    utc=$(date -u -d "@$(($1 + $4))" +%Y-%m-%dT%H:%M:%S 2>/dev/null ||
        date -u -r "$(($1 + $4))" +%Y-%m-%dT%H:%M:%S)
    [ "$2" = "$utc$3" ]
}

# Times are ISO-8601 with a colon in the offset, from either date: GNU's -d
# @SECONDS, or (refused) BSD's -r SECONDS.
case_iso_times() {
    local id form iso epoch
    for form in native bsd; do
        if [ $form = bsd ]; then
            id=$(PATH="$base/bsd-date:$PATH" TZ=XYZ-5:30 "$lock" perf-acquire 2>"$M/acquire.log")
        else
            id=$(TZ=XYZ-5:30 "$lock" perf-acquire 2>"$M/acquire.log")
        fi || fail "perf-acquire ($form date) exited $?" || return
        iso=$(entry_field "$owner" expires)
        epoch=$(entry_field "$owner" expires_epoch)
        printf '%s\n' "$iso" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$' ||
            fail "$form date: expires=$iso is not ISO-8601 with a colon in the offset" || return
        iso_matches "$epoch" "$iso" +05:30 19800 ||
            fail "$form date: expires=$iso is not epoch $epoch at +05:30" || return
        "$lock" perf-release "$id" || fail "perf-release exited $?" || return
    done
}

case_status_counts_stale() {
    local j k out
    bg j job -- "$gate" j
    j=$!
    bg k job -- "$gate" k
    k=$!
    wait_until "both jobs are running" eval 'started j && started k' || return
    kill -9 $k
    wait $k 2>/dev/null
    release k
    out=$("$lock" status)
    grep -qF 'jobs: 1 running, 1 stale' <<<"$out" || fail "status does not count the live and the stale job apart: $out" || return
    release j
    wait_exit $j
}

case_status_reads_well() {
    local j id out
    bg j job --what "build the thing" -- "$gate" j
    j=$!
    wait_until "the job is running" started j || return
    out=$("$lock" status)
    printf '%s\n' "$out" >"$M/status-job.out"
    for want in "perf: free" "jobs: 1 running" ": build the thing" "\$ $gate j" "expires "; do
        grep -qF -- "$want" <<<"$out" || fail "status with a job lacks '$want': $out" || return
    done
    if grep -q 'STALE' <<<"$out"; then
        fail "status calls a running job stale: $out"
        return 1
    fi
    release j
    wait_exit $j && expect_status 0 "job" || return
    id=$("$lock" perf-acquire --what "bench the thing" 2>/dev/null) || fail "perf-acquire exited $?" || return
    out=$("$lock" status)
    printf '%s\n' "$out" >"$M/status-perf.out"
    for want in "perf: held by" "($id," ": bench the thing" "jobs: 0 running"; do
        grep -qF -- "$want" <<<"$out" || fail "status with a perf lock lacks '$want': $out" || return
    done
    "$lock" perf-release "$id"
}

cases=(
    case_jobs_run_together
    case_job_waits_for_perf
    case_perf_waits_for_job
    case_perf_excludes_perf
    case_killed_job_is_cleaned
    case_host_is_display_only
    case_live_job_past_expiry_is_kept
    case_pid_reuse_reads_dead
    case_unknown_liveness_is_alive
    case_lost_lock_is_reported
    case_drain_outlasts_expiry
    case_lost_during_drain
    case_killed_perf_is_removed
    case_perf_acquire_killed_mid_drain
    case_drain_limit
    case_perf_acquire_unprinted_id
    case_exit_status_and_release
    case_sigterm_releases
    case_sigint_releases
    case_nested_job_in_job
    case_nested_job_in_perf
    case_perf_in_job_is_refused
    case_perf_extend_keeps_owner
    case_perf_extend_write_failure
    case_fresh_state_dir
    case_stale_mutex
    case_clean_removes_old_tmp
    case_iso_times
    case_status_counts_stale
    case_status_reads_well
)
passed=0
skipped=0
failed=0
for c in "${cases[@]}"; do
    M=$base/${c#case_}
    mkdir -p "$M"
    export M AGENT_LOCK_DIR=$M/state
    FAILED=
    SKIPPED=
    "$c"
    r=$?
    if [ "$r" = "$SKIP" ] && [ -z "$FAILED" ]; then
        echo "skip $c: $SKIPPED"
        skipped=$((skipped + 1))
    elif [ "$r" = 0 ] && [ -z "$FAILED" ]; then
        echo "ok   $c"
        passed=$((passed + 1))
    else
        echo "FAIL $c: ${FAILED:-returned non-zero}"
        failed=$((failed + 1))
        for log in "$M"/*.log; do
            [ -f "$log" ] && sed "s#^#    ${log##*/}: #" "$log"
        done
    fi
    stop_all
done
summary="agent-lock tests: $passed passed, $skipped skipped, $failed failed"
if [ "$failed" != 0 ]; then
    echo "$summary (work dir kept: $base)"
else
    # Only the directory mktemp made here: the prefix and six letters or digits.
    case ${base:?} in
    "$prefix"[[:alnum:]][[:alnum:]][[:alnum:]][[:alnum:]][[:alnum:]][[:alnum:]]) rm -rf -- "${base:?}" ;;
    *) echo "not removing $base: not the work dir this run made" >&2 ;;
    esac
    echo "$summary"
fi
[ "$failed" = 0 ]
