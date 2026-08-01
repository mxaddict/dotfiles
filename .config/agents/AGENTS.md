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
- **Never create a changelog that isn't there** unless asked.
- Run `prettier --write` on it, per the markdown rule above.

When a changelog exists and an entry is genuinely warranted, a change is not
done until it has one — same standing as the formatter and the test suite.

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
     exists, skip — don't create one unless asked.
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

**One write-capable sub-agent at a time. Read-only sub-agents run at max
concurrency** — fan them out as wide as the work genuinely splits.

The asymmetry is the point: read-only agents change nothing, so they cannot race
each other. Write-capable ones share the parent's working tree — no isolation,
no hand-back step, every edit immediately live for the others — so two writers
are two processes editing the same files with nothing between them, and one's
formatter run or `git checkout` undoes the other's work mid-flight. Serializing
writes is the only thing that actually prevents that; a brief saying "touch only
these paths" is a convention, and a convention is not a lock.

Reads are not free even so: each holds a model context, spends tokens, and lands
a report you have to read and verify. Fan out as wide as the work splits, not
wider than you will actually review.

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
