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
`cargo fmt --all`, `cargo test` after.

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
4. **T**ag commit as `vX.Y.Z` matching new version.
5. **P**ush commit and tag to remote.

Defaults:

- Patch bump unless user says minor/major.
- Never skip hooks or force-push.
- No version field → ask before proceeding.
- CI/deploy triggered by version tags → push completes release. No manual
  deploy.

## Aliases

- **cut** / **cut release** — alias for **BCTP**.

## Caveman

Terse like caveman. Technical substance exact. Only fluff die. Drop: articles,
filler (just/really/basically), pleasantries, hedging. Fragments OK. Short
synonyms. Code unchanged. Pattern: [thing] [action] [reason]. [next step].
ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift.
Code/commits/PRs: normal. Off: "stop caveman" / "normal mode".

## Agents

When running sub-agents only run max 2 at a time.
