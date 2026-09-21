# Backlog

## Windows machine state

- **`krypt diff` still lists a removed link.** Dropping the Windows mpv
  `[[link]]` left `%APPDATA%\mpv\mpv.conf` in krypt's manifest, so it shows as
  `missing` after the file was deleted. krypt has no command that forgets a
  manifest entry whose link is gone (tracked in krypt's backlog).
- **Machines set up with winget keep those installs.** The Windows groups moved
  from winget to scoop, and nothing uninstalls the winget copies, so a machine
  that ran the old `krypt deps` has both (e.g. `Git.Git` under `Program Files`
  and scoop's `git`). Which one runs depends on `PATH` order; removing the
  winget ones is a manual `winget uninstall` per package. Done on the first
  Windows machine on 2026-09-21, which found: close winget's Alacritty and
  anything running its Git Bash first, since both are files in use (Claude
  Code's Bash tool is one: point `CLAUDE_CODE_GIT_BASH_PATH` at scoop's
  `apps\git\current\bin\bash.exe` before removing `Git.Git`). The Neovim and
  starship MSIs failed under `winget uninstall --silent` with 1603, but
  `msiexec /x {product-code} /qn` run elevated removed them (so did GitHub CLI
  and Node). Unverified: that Terminal's default `PowerShell` profile moves to
  scoop's pwsh once winget's `Microsoft.PowerShell` is gone. Two traps:
  - **rustup**: winget's uninstall runs `rustup self uninstall`, which deletes
    `~/.cargo` and `~/.rustup` (toolchains and `cargo install`ed tools). Scoop's
    rustup keeps both in `~/scoop/persist/rustup`, so move them there before
    `scoop install rustup`, then delete only the `Rustup` key under
    `HKCU\...\Uninstall` so winget forgets it.
  - **Thunderbird/Firefox**: a new install location is a new "install" to
    Mozilla, which makes itself a fresh profile. Before first start, point
    `Default=` for the install in `profiles.ini` and `installs.ini` at the
    existing profile (the install's hash only appears after one start, so start
    once, close, fix, start again).
- **fnm's profile branches have not run anywhere.** fnm is in no deps group. The
  other tools' branches do run: `deps.yml` dot-sources the profile after
  installing the scoop `core` group (checking only the coreutils aliases), and
  `test-setup.ps1` loads it without them.

## PowerShell profile

- **Interactive keys, partly verified.** Driven in a real Alacritty with
  SendKeys on the first Windows machine: the grey history suggestion, → taking
  it, ↑ searching for the typed prefix, and Tab opening gh's completion menu.
  Not exercised: End, Alt+→, ↓, the `:q` Enter rewrite, and what the PSFzf
  bindings (Ctrl+T, Ctrl+R, Ctrl+F, Ctrl+G, Ctrl+S) do once pressed; the profile
  check only proves they are bound. CI checks Tab, ↑ and → are bound.
- **Tool completions are cached** under `%LOCALAPPDATA%\PowerShell\completions`
  and printed again when the tool's exe is newer than its cache. cobra-based
  tools (gh, glab, doctl) print `Completion ended with directive: ...` on stderr
  for every completion; an interactive shell does not show it, but a
  `pwsh -Command` run whose stderr is captured does.
- **fzf.fish's variables (Ctrl+V) and processes (Ctrl+P) pickers have no PSFzf
  equivalent** and were not ported; those keys keep PSReadLine defaults.
- Left out as Linux-only: `MANGOHUD`, `GPG_TTY`, `PARU_PAGER`, `MANPAGER`, the
  `batcat` shim and the Homebrew `PATH` entries.

## krypt

- **`[[command]]` steps swallow output and have no stdin.** `RealProcessExec` in
  `krypt-core/src/runner.rs` pipes stdout/stderr and nulls stdin for every step;
  output survives only through `capture`. So `krypt system nproc` prints
  nothing, `krypt system clearkeys` cannot prompt and `krypt tmux open` cannot
  attach — on every OS, not just Windows. Options: inherit stdio for steps
  without `capture`/`pipe` (hooks would then stream their output during
  `krypt update`), or add a per-step `interactive = true`. Needs a decision.
- **`${DOCUMENTS}` is `%USERPROFILE%\Documents` on Windows**
  (`Resolver::resolve_var_with_stack`). When Documents is redirected (OneDrive
  folder backup is common on Windows 11), the PowerShell profile deploys where
  PowerShell does not read it. Options: resolve the Documents known folder
  unless `HOME` is overridden (keeps sandboxed runs working), or set
  `[paths] DOCUMENTS` per machine. Not an issue on the current machine.
- **Dotfiles CI builds krypt `main`** (`.github/actions/krypt`) because the
  manifests used features unreleased at the time: per-platform `[[command]]`
  overrides, `platform` lists, `cargo:` deps entries and `krypt deps --check`.
  Everything the manifests use has shipped as of krypt **0.4.1** (2026-09-21:
  scoop buckets and state, the recorded-repo lookup, `krypt adopt`), which is
  `krypt_min`, and it is on GitHub Releases, the tap, the scoop bucket and the
  AUR. `setup.yml` can switch from building `main` to that release binary.
  Tracking `main` unpinned still means a krypt commit can turn this repo's CI
  red with no dotfiles change; pinning a tag makes runs reproducible at the cost
  of no longer exercising new krypt changes. Needs a decision.
- **krypt's own open items** (notify backends, interactive steps, CI toolchain)
  are tracked in `kryptic-sh/krypt` under `docs/backlog.md`.

## Not ported to Windows

- `system clear`, `system clearkeys`, `tmux open`, `menu mail`,
  `menu emoji-update` and `browser open` are gated to Linux/macOS (or Linux) and
  refuse on Windows, and their bash scripts are not deployed there. `env up`,
  `env down`, `system nproc` and `ollama pull-all` have PowerShell ports in
  `.local/bin/*.ps1`, which duplicate the bucket name, stage list and model
  lookup of their bash originals.
- **fish on Windows**: Alacritty and the profile use PowerShell 7 with uutils
  coreutils until a usable native fish build exists; fish, tmux and their
  configs are Linux/macOS only.
- `.local/bin/.pull-all-models` reads `$HOME/.files/.config/opencode/`, which
  only exists when the repo is cloned to `~/.files`; the PowerShell port reads
  the deployed `~/.config/opencode/opencode.json` instead.

## CI

- **PSScriptAnalyzer enforces only `ParseError` and `Error` severity** (the
  `psscriptanalyzer` job in `lint.yml`). Warning-level rules are not enforced;
  how many warnings the existing `.ps1` files raise has not been measured, so
  turning them on may need fixes or per-rule suppressions first.

## Coverage gaps

- **Post-update hooks are not run anywhere in CI**: `krypt update` needs a repo
  it can pull, and `test-setup.ps1` uses `krypt link`.
- **Alacritty's macOS shell entry is unverified on a Mac.**
  `.config/alacritty/macos.toml` runs fish through `/usr/bin/env` with a PATH
  naming both Homebrew prefixes, because a configured shell is spawned with
  Alacritty's own environment (checked in `alacritty_terminal`'s `tty/unix.rs`)
  and apps started from Finder get launchd's PATH. Alacritty cannot run in CI.
- **The `developer-mode` hooks, partly verified.** On the first Windows machine,
  with Developer Mode switched off, `krypt setup` turned it back on through the
  `post-setup` hook (one UAC prompt), and `krypt system devmode` exits without
  prompting when it is already on. The `post-update` hook runs the same command
  but was not run through a real `krypt update`, and a declined UAC prompt was
  not tried. CI never runs `krypt setup` or the hooks.
- **Only the `core` group is installed in CI**; every other group is resolved
  with `krypt deps --check`, not installed.

## Packages

Gaps `krypt deps --check` confirmed against the distro repositories and
Homebrew/scoop catalogs, with no fix available inside the manifest:

- **Not packaged for apt or dnf, and not a crate**: `opencode` (npm
  `opencode-ai`), `gemini-cli` (npm), `doctl` on apt, `lazygit` on dnf, and the
  kryptic-sh tools without a crates.io release (`pikr`, `buffr`, `inbx`, `hodl`,
  `krypt`). On Windows the kryptic-sh scoop bucket has pikr, buffr, hrdr and
  krypt; `inbx`, `hodl` and `gemini-cli` are missing there. pikr and buffr
  publish `.deb`/`.rpm` release assets, which neither `krypt deps` nor apt/dnf
  can install by name. Options: a kryptic-sh apt/rpm repository, an npm source
  in krypt, or leaving them to the Arch/Homebrew lists.
- **`cargo:` entries need a default Rust toolchain.** On apt, dnf and scoop,
  `cargo:hjkl` and friends (and `cargo:starship` and `cargo:dysk` on dnf) build
  with `cargo`, which Debian's and Fedora's `rustup` packages leave without a
  default toolchain until `rustup default stable` runs — and the
  `rustup-default-stable` hook only runs on `krypt update`, after deps. On
  Windows, krypt 0.4.1 picks up the `PATH` a scoop `rustup` install adds, so the
  `cargo:` entries no longer need a second run; not yet seen on a fresh machine.
- **The kryptic-sh Homebrew tap must be trusted**
  (`brew trust --tap kryptic-sh/tap`) before Homebrew installs anything from it,
  including krypt itself. krypt does not trust taps on its own; the README and
  the macOS deps job do it explicitly.
- **Alacritty has no Homebrew install on macOS.** Homebrew disabled the
  `alacritty` cask on 2026-09-01 because it does not pass Gatekeeper, so it was
  dropped from the `core` brew list. Options: the signed DMG from Alacritty's
  GitHub releases by hand, `cargo:alacritty` (a binary without the `.app`
  bundle, so no Dock/Finder launch), or another terminal on macOS. The macOS
  entry point in `.config/alacritty/` still deploys for a manual install.

## Git

- **A clone made before `.gitattributes` still has CRLF.** `.gitattributes`
  (`* text=auto eol=lf`) now pins LF, but an existing Windows checkout made
  under Git for Windows' system `core.autocrlf = true` keeps its CRLF working
  tree, and `krypt link` copies those bytes out. Re-check it out once
  (`git rm -rq --cached . && git reset -q --hard` on a clean tree), then
  `krypt link`.
- **`core.excludesfile = ~/.gitignore` names a file nothing deploys.** The
  repo's `.gitignore` is repo-meta, not a global ignore list, so on a krypt-only
  machine git has no global ignores. Options: a dedicated global ignore file
  with a `[[link]]`, or drop the setting.
- **gh rewrites the tracked `.config/gh/hosts.yml`.** `gh auth login` re-indents
  it (4 spaces instead of 2, content otherwise identical), so `krypt diff`
  reports it drifted and `krypt link` skips it as a conflict after every login.
  Options: commit gh's formatting, or stop tracking a file gh owns.
- **Claude Code rewrites the deployed `~/.claude/settings.json`.** Changing a
  setting through `/config` writes to that file, so `krypt diff` reports it
  drifted and `krypt link` skips it as a conflict until the change is pulled
  back with `krypt adopt ~/.claude/settings.json` or the file is replaced.
  Settings are meant to be changed in `.claude/settings.json` here instead.
- **`krypt setup` drops most template comments.** Writing `~/.gitconfig.local`
  from `.gitconfig.local.template` kept only the commented-out
  `; signingkey = ...` and `; gpgsign = true` lines; the explanatory comments
  and the `; [commit]` header above `gpgsign` are gone. Cosmetic here; belongs
  in krypt's own backlog (the `gitconfig` writer).

## Decisions needed

- **`.config/cargo/config.toml` is deployed where cargo never reads it.** cargo
  reads `$CARGO_HOME/config.toml` (`~/.cargo/config.toml`), and nothing here
  sets `CARGO_HOME`. Its `jobs = 16` is overridden by `CARGO_BUILD_JOBS` from
  the fish and PowerShell configs anyway. Options: retarget it to
  `~/.cargo/config.toml`, or delete it.
- **Configs deployed by the old stow setup but not by krypt stay symlinked.**
  This machine was migrated from the whole-repo stow symlinks to krypt's
  copy-based deploy, but `.krypt/links.toml` covers only a curated subset. So
  `.config/nushell`, `.config/hjkl/config.toml`, `.config/hrdr/config.toml`,
  `.agents`, `.codex/config.toml`, plus repo-meta (`docs`, `.krypt.toml`,
  `.gitignore`) are still `~ -> .files` symlinks, not krypt-managed. Decision:
  add the real configs among these to `[[link]]` entries so krypt owns them, or
  leave them symlinked deliberately. Repo-meta should stay out of krypt either
  way. `~/.claude`, `~/.claude-work` and `~/.codex` are now `[[link]]`
  destinations (the agent rules, Claude settings and statusline), so on that
  machine any `~ -> .files` symlink among those three has to become a real
  directory before the next `krypt link`: through the symlink, krypt would write
  its copies back into the repo's gitignored `.claude*/` and `.codex/`, and copy
  `.claude/settings.json` onto itself.
- **Runtime data still lives in the repo working tree after the migration.**
  Because the old model symlinked `~/.config/{tmux,fish,nvim,opencode}` into the
  repo, plugin managers wrote their clones there (gitignored): `~58M` of
  `opencode/node_modules`, the TPM plugins under `.config/tmux/plugins/`, fisher
  functions, `nvim/lazy-lock.json`. The migration copied these into the real
  `~/.config` dirs, so the repo's copies are now orphaned duplicates. They are
  gitignored (harmless), but the repo tree could be pruned of them.
- **`tpm-install` hook can't bootstrap tpm on a fresh krypt deploy.** Its `if`
  guard requires `${XDG_CONFIG}/tmux/plugins/tpm/bin/install_plugins` to already
  exist, which the old dir-symlink guaranteed but a copy-based deploy does not
  (tpm is untracked, so `src_glob` no longer sweeps it in). A fresh machine now
  needs a hook that clones tpm first. On this machine tpm was preserved by
  copying it over, so nothing is broken here yet.
