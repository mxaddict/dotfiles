# Backlog

## Windows machine state

- **Seven destinations were left as conflicts by `krypt link`** on the Windows
  box: `~/.gitconfig`, `%APPDATA%\GitHub CLI\config.yml` and `hosts.yml`, the
  PowerShell profile, `%LOCALAPPDATA%\lazygit\config.yml`, and both Alacritty
  configs. The Alacritty files are byte-identical to the repo but untracked by
  the manifest. The existing profile's uutils coreutils block is carried over
  verbatim into `Documents/PowerShell/Microsoft.PowerShell_profile.ps1`. Before
  `krypt link --force`: run `krypt setup` so the `[user]` identity in the old
  `~/.gitconfig` moves to `~/.gitconfig.local`, and compare the gh and lazygit
  files, which hold state written by those tools.
- **`Hack Nerd Font Mono` is not installed**, so Alacritty falls back to a
  default font. `krypt deps --group fonts` now installs `DEVCOM.HackNerdFont`;
  it has not been run.
- **Tools the PowerShell profile wires up are not installed** (eza, bat, fzf,
  zoxide, starship, fnm, PSFzf), so only the tool-absent branches of the profile
  have been exercised, locally and in CI. `krypt deps --group core` plus the
  `psfzf-update` hook install them.

## PowerShell profile

- **Interactive key handlers are untested**: the `:q` Enter rewrite and the
  PSFzf bindings (Ctrl+T, Ctrl+R, Ctrl+F, Ctrl+G, Ctrl+S) need a real console.
  CI only proves the profile loads, removes shadowing aliases and enables vi
  mode.
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
- **Dotfiles CI builds krypt `main`** because per-platform `[[command]]`
  overrides are unreleased (latest release 0.2.2). Switch `setup.yml` to the
  release binary once one ships with them. Until then, `krypt-bin` 0.2.2 on
  Linux runs the first entry by name, which is still the Linux/generic one.
  Tracking `main` unpinned means a krypt commit can turn this repo's CI red with
  no dotfiles change, and each new krypt commit rebuilds it on all three
  runners. Pinning a revision in `setup.yml` makes runs reproducible but stops
  this CI from exercising new krypt changes until the pin is bumped — which is
  currently the only end-to-end Windows/macOS check krypt gets. Needs a
  decision.
- **krypt's own open items** (notify backends, interactive steps, CI toolchain)
  are tracked in `kryptic-sh/krypt` under `docs/backlog.md`.

## Not ported to Windows

- `system clear`, `system clearkeys`, `menu mail`, `menu emoji-update` and
  `browser open` are gated to Linux/macOS and refuse on Windows. `tmux open`
  stays ungated and silently skips its step wherever tmux is absent. `env up`,
  `env down`, `system nproc` and `ollama pull-all` have PowerShell ports in
  `.local/bin/*.ps1`, which duplicate the bucket name, stage list and model
  lookup of their bash originals.
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
  it can pull, and `test-setup.ps1` uses `krypt link`. `psfzf-update` has not
  been executed at all.
- **macOS native paths are unverified.** lazygit and tealdeer may read
  `~/Library/Application Support` on macOS while the links target `~/.config`;
  not checked.
- **Git symlinks still tracked** (`.claude/CLAUDE.md`, `.claude-work/*`,
  `.codex/AGENTS.md`) check out as text files on Windows. krypt does not deploy
  them, so nothing was changed.
