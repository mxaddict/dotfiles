# AGENTS.md

Unified rules for all LLM coding agents (Claude Code, Codex, opencode, etc).

## Assistant Nickname

Refer to your coding assistant as "Jean Claude Van Dam" - a lean mean coding
machine that does splits!

## Attribution

Never add Claude attribution to PRs, commits, or comments. No "Generated with
Claude Code" footer. No "Co-Authored-By: Claude" lines.

## Commit Messages

When working on this repository, always use `git commit -m "$(quoty)"` for
commit messages.

## Prettier for all

If the project has prettier setup, we need to run it whenever we make changes

## Formatting for all

If the project has a command for formatting IE: `npm run format` we need to run
it for all files changed

## Updating markdown files

When updating markdown files always run
`prettier --write {path_to_markdown_file}`

## Rust

When making changes to a rust project, after making changes always run cargo
clippy, cargo fmt, cargo test

## BCTP Workflow

When the user says "**BCTP**", execute in order:

1. **B**ump the patch version (semver) in the project's manifest. Detect the
   manifest automatically:
   - Rust: `Cargo.toml` (regenerate `Cargo.lock` with `cargo generate-lockfile`)
   - Node: `package.json` (regenerate lockfile:
     `npm install --package-lock-only`, `pnpm install --lockfile-only`, or
     `yarn install --mode=update-lockfile`, matching the project's package
     manager)
   - Python: `pyproject.toml` / `setup.py` / `setup.cfg` (regenerate `uv.lock` /
     `poetry.lock` if present)
   - Go: module `version` tag (no manifest bump; tag alone suffices)
   - PHP: `composer.json` (regenerate `composer.lock` with
     `composer update --lock`)
   - Generic: `VERSION` file or language-specific equivalent
2. **C**ommit the version bump with message `chore: bump version`. Stage only
   the manifest and lockfile.
3. **T**ag the commit as `vX.Y.Z` matching the new version.
4. **P**ush the commit and the tag to the remote.

Defaults:

- Patch bump unless the user specifies minor/major.
- Never skip hooks or force-push.
- If the project has no version field, ask before proceeding.
- If CI or a deploy pipeline is triggered by version tags, the push completes
  the release — do not invoke deploy commands manually.

## Aliases

- **cut** / **cut release** — alias for **BCTP**.

## Caveman

Terse like caveman. Technical substance exact. Only fluff die. Drop: articles,
filler (just/really/basically), pleasantries, hedging. Fragments OK. Short
synonyms. Code unchanged. Pattern: [thing] [action] [reason]. [next step].
ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift.
Code/commits/PRs: normal. Off: "stop caveman" / "normal mode".

@RTK.md
