# AGENTS.md

Unified rules for all LLM coding agents (Claude Code, Codex, opencode, etc).

## Assistant Nickname

Call assistant "Jean Claude Van Dam" - lean mean coding machine do splits!

## Attribution

Never add Claude attribution to PRs, commits, comments. No "Generated with
Claude Code" footer. No "Co-Authored-By: Claude" lines.

## Commit Messages

Use `git commit -m "$(quoty)"` only in the `.files` repo. All other repos:
Conventional Commits format — `type(scope): message` (e.g.
`feat(auth): add OAuth flow`, `fix(api): handle null token`,
`docs: update README`). Scope optional. Types: feat, fix, docs, style, refactor,
test, chore, perf, ci, build.

## Prettier for all

Project has prettier setup → run on changes.

## Formatting for all

Project has format command (e.g. `npm run format`) → run on all changed files.

## Updating markdown files

Updating markdown → run `prettier --write {path_to_markdown_file}`.

## Rust

Rust project changes → always run cargo clippy, cargo fmt, cargo test after.

## BCTP Workflow

User says "**BCTP**", execute in order:

1. **B**ump patch version (semver) in manifest. Detect automatically:
   - Rust: `Cargo.toml` (regenerate `Cargo.lock` with `cargo generate-lockfile`)
   - Node: `package.json` (regenerate lockfile:
     `npm install --package-lock-only`, `pnpm install --lockfile-only`, or
     `yarn install --mode=update-lockfile`, match project's package manager)
   - Python: `pyproject.toml` / `setup.py` / `setup.cfg` (regenerate `uv.lock` /
     `poetry.lock` if present)
   - Go: module `version` tag (no manifest bump; tag suffices)
   - PHP: `composer.json` (regenerate `composer.lock` with
     `composer update --lock`)
   - Generic: `VERSION` file or language equivalent
2. **C**ommit version bump with message `chore: bump version`. Stage only
   manifest and lockfile.
3. **T**ag commit as `vX.Y.Z` matching new version.
4. **P**ush commit and tag to remote.

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

@RTK.md
