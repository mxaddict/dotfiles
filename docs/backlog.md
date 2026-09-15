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
  default font, and `krypt deps` cannot install it: winget has no Hack Nerd Font
  package (`DEVCOM.HackNerdFont`, listed before, does not exist in
  microsoft/winget-pkgs). Scoop's `nerd-fonts` bucket has `Hack-NF`; using it
  means adding that bucket and a `scoop` list to the `fonts` group.
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
- **Dotfiles CI builds krypt `main`** (`.github/actions/krypt`) because the
  manifests use unreleased features: per-platform `[[command]]` overrides,
  `platform` lists, `cargo:` deps entries and `krypt deps --check` (latest
  release 0.2.2). Switch `setup.yml` to the release binary once one ships with
  them. Until then, `krypt-bin` 0.2.2 on Linux runs the first entry by name,
  which is still the Linux/generic one. Tracking `main` unpinned means a krypt
  commit can turn this repo's CI red with no dotfiles change, and each new krypt
  commit rebuilds it on all three runners. Pinning a revision in `setup.yml`
  makes runs reproducible but stops this CI from exercising new krypt changes
  until the pin is bumped — which is currently the only end-to-end Windows/macOS
  check krypt gets. Needs a decision.
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
  it can pull, and `test-setup.ps1` uses `krypt link`. `psfzf-update` has not
  been executed at all.
- **lazygit's macOS path comes from its docs** (`docs/Config.md`:
  `~/Library/Application Support/lazygit/config.yml`), not from running lazygit
  on a Mac; lazygit is in the `dev` group, which CI does not install. tealdeer's
  is checked by the deps workflow against `tldr --show-paths`.
- **Alacritty's macOS shell entry is unverified on a Mac.**
  `.config/alacritty/macos.toml` runs fish through `/usr/bin/env` with a PATH
  naming both Homebrew prefixes, because a configured shell is spawned with
  Alacritty's own environment (checked in `alacritty_terminal`'s `tty/unix.rs`)
  and apps started from Finder get launchd's PATH. Alacritty cannot run in CI.
- **Only the `core` group is installed in CI**; every other group is resolved
  with `krypt deps --check`, not installed.
- **Git symlinks still tracked** (`.claude/CLAUDE.md`, `.claude-work/*`,
  `.codex/AGENTS.md`) check out as text files on Windows. krypt does not deploy
  them, so nothing was changed.

## Packages

Gaps `krypt deps --check` confirmed against the distro repositories and
Homebrew/winget catalogs, with no fix available inside the manifest:

- **Not packaged for apt or dnf, and not a crate**: `opencode` (npm
  `opencode-ai`), `gemini-cli` (npm), `doctl` on apt, `lazygit` on dnf, and the
  kryptic-sh tools without a crates.io release (`pikr`, `buffr`, `inbx`, `hodl`,
  `krypt`). The same tools are missing on winget. pikr and buffr publish
  `.deb`/`.rpm` release assets, which neither `krypt deps` nor apt/dnf can
  install by name. Options: a kryptic-sh apt/rpm repository, an npm source in
  krypt, or leaving them to the Arch/Homebrew lists.
- **`cargo:` entries need a default Rust toolchain.** On apt, dnf and winget,
  `cargo:hjkl` and friends (and `cargo:starship` and `cargo:dysk` on dnf) build
  with `cargo`, which Debian's and Fedora's `rustup` packages leave without a
  default toolchain until `rustup default stable` runs — and the
  `rustup-default-stable` hook only runs on `krypt update`, after deps.
- **The scoop bucket is unused.** On a Windows machine with scoop, winget still
  installs every group because none lists scoop packages; the kryptic-sh bucket
  (pikr, buffr, hrdr, krypt) would need `scoop bucket add` before any `scoop`
  list could use it.

## Decisions needed

- **`.config/cargo/config.toml` is deployed where cargo never reads it.** cargo
  reads `$CARGO_HOME/config.toml` (`~/.cargo/config.toml`), and nothing here
  sets `CARGO_HOME`. Its `jobs = 16` is overridden by `CARGO_BUILD_JOBS` from
  the fish and PowerShell configs anyway. Options: retarget it to
  `~/.cargo/config.toml`, or delete it.
- **`src_glob` deploys untracked files.** Globs match the working tree, so
  `.config/tmux/**/*` also deploys the TPM plugin clones under
  `.config/tmux/plugins/` on a machine that has them (hundreds of files); a CI
  checkout has none. Options: exclude `plugins/` in the manifest, or make krypt
  match only tracked files.
