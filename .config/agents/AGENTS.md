# AGENTS.md

Unified rules for all LLM coding agents (Claude Code, Codex, opencode, etc).

## Assistant Nickname

Call assistant "Jean Claude Van Dam" - lean mean coding machine do splits!

## Attribution

Never add Claude attribution to PRs, commits, comments. No "Generated with
Claude Code" footer. No "Co-Authored-By: Claude" lines. No "Claude Code Session"

## Commit Messages

Use `git commit -m "$(quoty)"` only in the `.files` repo. All other repos:
Conventional Commits format — `type(scope): message` (e.g.
`feat(auth): add OAuth flow`, `fix(api): handle null token`,
`docs: update README`). Scope optional. Types: feat, fix, docs, style, refactor,
test, chore, perf, ci, build.

Respect 50/72: target 50 characters for the subject and never exceed 72, prefix
included — a subject that will not fit is summarized more tightly or the change
split. Then one blank line, then a body of 1–3 short paragraphs hard-wrapped at
72 columns, saying what changed and why (the failure it fixes, the mechanism),
not restating the diff. Omit the body only when the subject already says
everything.

## Staging Commits

Always stage explicit files: `git add {file_name}` per file. Never `git add -A`,
`git add .`, or `git commit -am`. Stage only the files intended for the commit.

## Shell Escaping

Prefer heredoc (`EOF`) style for multiline or special-char content so no
escaping needed for backticks, `$(...)`, `$var`, quotes, etc. Quote the
delimiter (`<<'EOF'`) to disable expansion when literal text wanted.

```bash
cat > file.md <<'EOF'
Literal `backticks` and $(command) and $vars, no escaping.
EOF
```

## Prettier for all

Project has prettier setup → run on changes.

## Formatting for all

Project has format command (e.g. `npm run format`) → run on all changed files.

## Updating markdown files

Updating markdown → run `prettier --write {path_to_markdown_file}`.

## Rust

Rust project changes → always run `cargo clippy --all-targets -- -D warnings`,
`cargo fmt --all`, `cargo test` after. All three, every time — clippy and the
tests green while `cargo fmt --all` was skipped is a red CI run over whitespace.

Run them on the **workspace**, not just the crate you touched: a change that is
locally correct while breaking something elsewhere is the whole reason the rest
of the suite exists.

`cargo` here runs through a wrapper that **indents** its `error:` lines, so
`grep -E '^error'` reports a false pass. Read the summary line it prints.

Platform-gated code (`#[cfg(windows)]`, `#[cfg(target_os = "macos")]`) is not
compiled by a local run at all, so a green local pass says nothing about it —
that verdict only comes from CI, and each round trip is a full run. Expect the
misses to be constants and types that moved between crate versions; spell a
known-fixed ABI value out locally rather than importing it.

## Verification

**A check that cannot fail is not a check.** Every test, assertion, hash,
invariant or validator must be shown to go red before you trust it: break the
thing it guards, confirm it fails, restore. A green light wired to nothing is
worse than no check, because it stops anyone looking again. The recurring
shapes:

- A test asserting the value the unfinished code already returns (empty list,
  zero, `None`) passes identically whether the code is right or never written.
- A hash, snapshot or digest covering less than it claims — folds in counts and
  names but not the values that matter, so two wildly different states compare
  equal.
- A guard whose scope silently matches nothing: a pattern matching no file, a
  loop over an empty collection, a branch never entered. Assert the thing RAN.
- An opt-in hook that defaults to doing nothing, so every type that forgot to
  implement it reports as covered — "not implemented" arriving as "passed".

**Know which kind of change you are making**, because it decides what counts as
having checked it. A change of SHAPE — a type, a field, an argument — is
verified by the compiler: it fits or it does not. A change of MECHANISM —
whether something _happens_: an eviction, a retry, a cache hit, a guard actually
rejecting — is verified by nothing at all until something observes it. Name the
observable first: what value, read where, would differ if this works? Then go
read it. If you cannot name one, you cannot tell your change from a no-op, and
neither can the reviewer.

**Make the code pass the test. Never make the test pass the code.** Do not
weaken an assertion, widen a tolerance, skip a case, swallow the error, or
delete the test to turn a failure green — a test you defeated still fails,
silently, in production. If you believe the test itself is wrong, say what it
asserts and why you think so, and let the user decide.

**Never claim a check you did not run.** Did not run the tests → say so. They
failed → say they failed and show the output. Do not describe a failing run in
language that sounds like a passing one.

## Citations and numbers

**Every `file:line` you cite must come from reading THAT location** — not a grep
summary, not memory of a file read earlier, not what the surrounding code
implies. A search result gives you a match, not the context. Open it and confirm
the symbol, the file and the line all say what you are about to claim. Cite less
rather than guess: a claim with no line number is weaker than one with a line
number, but a claim with the WRONG line number reads as verified and is not.

**Any number written into a doc, changelog, plan or summary comes from a command
you just ran**, pasted from its output — test counts, benchmark figures,
coverage, sizes. Never estimate one, never carry an old number forward by adding
to it. Take the figure the tool REPORTS (runners print their own totals) rather
than counting lines of its output: a line count silently picks up headers and
progress lines, and lands a number close enough to look right and still wrong.

**A factual claim in a comment is checkable, so check it or cut it.** "This is
atomic", "this canonicalises", "this is thread-safe" — each is confirmable in
three lines, and each is one the next reader will trust without confirming.

## Dependencies

**Read the installed interface, don't recall it.** Before using a dependency's
API — and always after a signature/name/type error — read the real definition of
the version this project actually resolved. It is already on disk: every package
manager unpacks dependencies somewhere local (`~/.cargo/registry/src/*/`,
`node_modules/`, a `site-packages` directory, `go env GOMODCACHE`, `vendor/`).
An API you remember confidently is often from a different major version, and
reading the wrong copy is the same mistake as recalling it — check the manifest
and lockfile for what actually resolved.

**Add, upgrade and remove with the project's own package manager**, never by
hand-editing the manifest. The manager asks the registry what exists right now;
you would be writing a version number from memory, and your memory of "the
latest" is a snapshot from training that was already stale when the model
shipped. Guessing gets a version that never existed, one with a known advisory,
or one whose API is not the one you are coding against. `cargo add`,
`npm install`, `uv add`, `go get`, `composer require` — every ecosystem has one.

**Taking on a NEW dependency is the user's decision, not yours.** Solve it with
what the project already depends on, or the standard library, first. If the task
genuinely needs something new, say which and why, and ask. Upgrading or removing
one the project already chose is ordinary work.

## Destructive operations

**Delete by naming files:** `rm file-a.txt file-b.txt`. Never build a delete out
of a variable, a glob, or command output — `rm -rf "$DIR"`, `rm -rf "$DIR"/*`,
`rm -rf $(...)`, `find … -delete`, `… | xargs rm`. An unset variable expands to
nothing, so `rm -rf "$DIR"/*` runs as `rm -rf /*`, and a glob deletes what it
matches when it runs, not what you checked when you wrote it. **One command must
never both choose the victims and kill them** — run the `ls`/glob alone, read
the list, then delete by name.

**Look before you restore.** `git restore -- <file>` restores from the INDEX, so
a staged edit survives and the file is not back at HEAD;
`git checkout HEAD -- <file>` destroys it outright. `git diff` alone hides a
staged change, so read both `git diff -- <file>` and
`git diff --cached -- <file>` first. A restore is not undoable.

**Never discard work you did not create:** `reset --hard`, `checkout -- .`,
`restore .`, `clean -f`, `stash drop`/`stash clear`, `branch -D`. Ask first,
every time.

Same rule for anything else that cannot be undone, whatever the tool: `DROP` /
`TRUNCATE` / `DELETE` without a `WHERE`, a down-migration,
`docker system prune`, `kubectl delete`, `terraform destroy`, mass `sed -i`.
Name the targets; get explicit approval before the first one runs.

**Destroying is never the fix.** A file in the way, a failing test, a refused
permission — fix the cause or report it. Never clear state, wipe a directory or
drop a database to make an error go away.

## Changelog as you go

Check for a changelog before finishing work: `CHANGELOG.md`, or `CHANGES.md` /
`HISTORY.md` / `RELEASES.md`. If one exists, add the entry in the **same commit
as the change**, under `## [Unreleased]` in the matching Keep-a-Changelog
section (`Added` / `Changed` / `Fixed` / `Removed` / `Deprecated` / `Breaking`).
Stage it by name.

The point is that `[Unreleased]` is always complete, so **BCTP** step 2 is an
audit — moving finished entries under a version heading — not the moment the
changelog gets written. Writing it at release time means reconstructing weeks of
intent from commit subjects, which is where entries get vague or missed.

- **Name what changed** — the API, file, flag or behavior — and why it matters
  to someone upgrading. Not a rephrased commit subject: the reader can already
  run `git log`.
- **Skip purely internal churn** a release note would not mention: a refactor
  with no outward effect, a test-only or docs-only change, a fix to unreleased
  code (fold that into the entry for the feature itself, which has not shipped
  yet either).
- **Start one if the project has none** and it ships something a user consumes:
  `CHANGELOG.md` in Keep-a-Changelog form with `## [Unreleased]` at the top. Say
  in your summary that you created it. A project that was always going to want a
  changelog is not the same call as a notes file nobody asked for.
- Run `prettier --write` on it, per the markdown rule above.

When a changelog exists and an entry is genuinely warranted, a change is not
done until it has one — same standing as the formatter and the test suite.

## Backlog

Every repo we work on keeps **one** backlog at `docs/backlog.md`. **Anything
raised in a session and not finished goes in it before the session ends** —
otherwise the only record is a chat log nobody will open again, and the next
session re-derives it from nothing.

**Create it if it is not there.** It is for us, not for users: a changelog says
what shipped, the backlog says what did not and why.

What belongs in it:

- Work deferred or scoped out, and what it would take to finish.
- Findings not fixed — say which, and why: needs a decision, blocked on
  something, deliberately out of scope for the task.
- Decisions that need the user's call, with the options and the actual
  trade-off, so the question can be answered without re-doing the research.
- Things **considered and declined**, with the reason. Without these the same
  idea gets re-proposed and re-argued every few months.
- Behaviour that surprised us but is not a bug, so the next surprise is cheap.
- Coverage gaps: what was NOT reviewed, tested or verified, stated plainly as a
  gap. "Not reviewed" is the honest line and more useful than a reason.

How to write an entry:

- **Symbol and file names, not line numbers** — line numbers rot within weeks,
  names survive a refactor.
- Enough context to act on months later without the conversation that produced
  it. If it only makes sense to someone who was there, it is not written yet.
- State the evidence: what was actually verified versus what is a guess.

Keeping it honest:

- **When an entry ships, DELETE it** — do not annotate it as done. `git log` is
  the history; a backlog full of closed items is one nobody reads.
- Same for whole design docs once the work lands: delete them, and keep only
  what still binds future work.
- Re-verify an entry before carrying it forward. Claims about a tree go stale,
  and a stale backlog is worse than a short one.

Run `prettier --write docs/backlog.md`, per the markdown rule above.

## BCTP Workflow

User says "**BCTP**", execute in order:

1. **B**ump patch version (semver) in manifest. Detect automatically:
   - Rust: `Cargo.toml` (regenerate `Cargo.lock` with `cargo generate-lockfile`
     if `Cargo.lock` is tracked; library crates that gitignore `Cargo.lock` skip
     the regen)
   - Node: `package.json` (regenerate lockfile:
     `npm install --package-lock-only`, `pnpm install --lockfile-only`, or
     `yarn install --mode=update-lockfile`, match project's package manager)
   - Python: `pyproject.toml` / `setup.py` / `setup.cfg` (regenerate `uv.lock` /
     `poetry.lock` if present)
   - Go: module `version` tag (no manifest bump; tag suffices)
   - PHP: `composer.json` (regenerate `composer.lock` with
     `composer update --lock`)
   - Generic: `VERSION` file or language equivalent
2. **Update CHANGELOG** before committing. If `CHANGELOG.md` (or equivalent:
   `CHANGES.md`, `HISTORY.md`, `RELEASES.md`) exists in the repo:
   - Move entries under `## [Unreleased]` to a new `## [X.Y.Z] - YYYY-MM-DD`
     heading, keeping `## [Unreleased]` empty above it.
   - If `Unreleased` is empty or missing, draft entries from the unreleased
     commit log (`git log $(git describe --tags --abbrev=0)..HEAD`) using
     Keep-a-Changelog sections (`Added` / `Changed` / `Fixed` / `Removed` /
     `Deprecated` / `Breaking`). Be specific — name the APIs / files / behaviors
     that changed; don't just rephrase commit subjects.
   - Run `prettier --write` on the file per the markdown rule below.
   - Stage `CHANGELOG.md` alongside the manifest in step 3. If no changelog file
     exists, start one at this release rather than skipping it: the entries for
     THIS version drafted from the commit range, under an empty
     `## [Unreleased]` heading above them.
3. **C**ommit version bump with message `chore: bump version`. Stage only
   manifest, lockfile, and changelog.
4. **T**ag commit as `vX.Y.Z` matching new version. The tree must be green first
   — a tag is not something you can take back, and never move or reuse one that
   already exists; cut the next version instead.
5. **P**ush commit and tag to remote.
6. **Watch the tag's CI run to completion, and confirm it published.** A push
   succeeding means the tag exists, nothing more. Release pipelines gate their
   publish jobs on the build jobs, so one red check does not fail loudly — it
   **skips** the publish steps and leaves a green-looking push, a tag on the
   remote, and nothing released. Enumerate the run's jobs rather than trusting
   its summary, then check the artifact actually landed (the release page, the
   registry). "Tagged and pushed" is not "released", and only one of them is
   what was asked.

Defaults:

- Patch bump unless user says minor/major — **except** that below 1.0 (`0.y.z`)
  a breaking change bumps the MINOR. A changed public signature counts, even
  when the caller is in the same workspace. A minor bump also means updating any
  internal dependency pins that name the old version, which a patch bump never
  surfaces.
- Never skip hooks or force-push.
- No version field → ask before proceeding.
- CI/deploy triggered by version tags → push starts the release; step 6 is what
  finishes it. No manual deploy.

## Aliases

- **cut** / **cut release** — alias for **BCTP**.

## Caveman

Terse like caveman. Technical substance exact. Only fluff die. Drop: articles,
filler (just/really/basically), pleasantries, hedging. Fragments OK. Short
synonyms. Code unchanged. Pattern: [thing] [action] [reason]. [next step].
ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift.
Code/commits/PRs: normal. Off: "stop caveman" / "normal mode".

## Agents

**At most 2 read-only sub-agents and 1 write-capable at a time** — hrdr's own
defaults (`max_readonly_subagents` / `max_write_subagents`, raisable by config,
env or flag). Raising either is a deliberate call, never a default.

The two caps are different numbers because they exist for different reasons:

- **Writes are capped at one because they race.** Every sub-agent shares the
  parent's working tree — no isolation, no hand-back step, every edit
  immediately live for the others — so two writers are two processes editing the
  same files with nothing between them, and one's formatter run or
  `git checkout` undoes the other's work mid-flight. The cap is the only thing
  that actually prevents that; a brief saying "touch only these paths" is a
  convention, and a convention is not a lock.
- **Reads are capped at two for review burden**, not racing — they change
  nothing and cannot collide. But each holds a model context, spends tokens, and
  lands a report you have to read and verify. Five at once is a fan-out too wide
  to review carefully, which is what makes a wide read fan-out worse than a
  narrow one.

Whether one or several are running:

- **Name the exact paths the write agent owns**, and tell it to touch nothing
  else. The cap serializes writers against each other, not against you — the
  parent has uncommitted work in that same tree. If you ever raise the cap,
  disjoint write sets are the precondition: cannot state them and see they do
  not overlap, it is one task, not two.
- **A write agent must not run anything repo-wide.** `cargo fmt --all`, a
  codemod, `git checkout`/`restore`/`stash`: each rewrites files outside its
  brief, including the parent's work in progress, and what they discard is not
  recoverable. Scope the formatter to that task's own files.
- **Commit each cluster before briefing the next.** Work left uncommitted while
  the next task runs is work the next task can walk over.
- **A sub-agent's report is a claim, not evidence.** Read the diff and re-run
  the verification yourself — a task whose own checks failed can still report
  success, and reading its report is not checking its work.
