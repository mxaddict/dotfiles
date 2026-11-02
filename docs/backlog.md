# Backlog

## Agent CLIs (`krypt system agents`)

- **CI covers the install, not the hooks or the self-updates.** The `agents`
  workflow (`.github/scripts/test-agents.ps1`) runs `krypt system agents` twice
  on Ubuntu, macOS and Windows runners and checks each CLI's path and
  `--version`, codex's sandbox through the Windows shim, and that the fish
  config or PowerShell profile resolves each first on `PATH`. Not covered: the
  `agent-clis` hooks inside a real `krypt setup` or `krypt update`, and each CLI
  updating itself afterwards.
- **opencode's README and its served installer disagree.** The README says the
  install script honours `OPENCODE_INSTALL_DIR`, `XDG_BIN_DIR` and `~/bin`; the
  script served at `opencode.ai/install` (checked 2026-09-29) hardcodes
  `~/.opencode/bin`, and its self-update re-runs that script. If the script
  starts honouring them, installs move and the `!file_exists` step and the
  `PATH` lines miss them; the `agents` job would fail on that. opencode's docs
  give the script for macOS and Linux only (choco, scoop, npm or mise on
  Windows), but it handles Git Bash on Windows (`MINGW*` → `windows-x64`).
- **Package-manager opencode stays installed on existing machines.** opencode
  left the `dev` group (pacman, brew, scoop), but nothing uninstalls it, and
  opencode's installer skips when the `opencode` on PATH is already the latest,
  which makes `krypt system agents` fail with a message naming it. Remove it by
  hand (`sudo pacman -Rns opencode`, `brew uninstall opencode`); scoop's was
  removed on the first Windows machine.
- **opencode cannot update itself on Windows.** Its self-update pipes
  `opencode.ai/install` into bare `bash`, which on Windows is the WSL launcher:
  with WSL installed, the install lands inside WSL. `krypt update` keeps it
  current instead (the Windows variant runs opencode's installer on every call).
  Option: put Git's `bin` ahead of `WindowsApps` on `PATH` in the PowerShell
  profile, which makes `bash` there mean Git Bash instead of WSL. Needs a
  decision.
- **codex's Windows installer adds its own bin dir to the user `PATH`**, ahead
  of `~/.local/bin`, so outside the PowerShell profile `codex` resolves there
  directly. Same binary as the shim, so harmless.
- **Declined: `CODEX_INSTALL_DIR=~/.local/bin` on Windows.** The installer turns
  its install dir into a junction to the current release, which would replace
  `~/.local/bin` and everything in it.
- **Shims, not symlinks, on Windows.** Windows gives a symlinked exe the link's
  path as its own: pwsh started through one looked for its DLLs beside the link
  and failed. A symlinked codex still ran its sandbox in a test, but the shim
  makes that independent of how codex finds `codex-resources` and `codex-path`.
  The shims use scoop's `kiennq` shim.exe, so they need scoop.

## Windows machine state

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
  output survives only through `capture`. So `krypt system nproc` prints nothing
  and `krypt system clearkeys` cannot prompt — on every OS, not just Windows.
  Options: inherit stdio for steps without `capture`/`pipe` (hooks would then
  stream their output during `krypt update`), or add a per-step
  `interactive = true`. Needs a decision.
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
- **`krypt diff` lists template destinations as drifted.** On `slowassdell`
  (Arch, krypt 0.4.4, 2026-10-26) it reports `~/.config/hypr/apps.lua`,
  `~/.config/hypr/input.lua` and `~/.gitconfig.local`, which `krypt setup`
  renders from their `[[template]]` sources, so they differ from the repo on
  purpose. krypt 0.4.3 stopped counting a destination that already matches its
  source as a conflict, and 0.4.4 forgot the 15 entries this repo had deleted,
  which cleared the 31 dirty entries recorded on 2026-10-21.
- **krypt's own open items** (notify backends, interactive steps, CI toolchain)
  are tracked in `kryptic-sh/krypt` under `docs/backlog.md`.

## Not ported to Windows

- `system clear`, `system clearkeys`, `menu mail`, `menu emoji-update` and
  `browser open` are gated to Linux/macOS (or Linux) and refuse on Windows, and
  their bash scripts are not deployed there. `env up`, `env down`,
  `system nproc` and `ollama pull-all` have PowerShell ports in
  `.local/bin/*.ps1`, which duplicate the bucket name, stage list and model
  lookup of their bash originals.
- **fish on Windows**: Alacritty and the profile use PowerShell 7 with uutils
  coreutils until a usable native fish build exists; fish and its config are
  Linux/macOS only.

## tmxr

tmxr replaced tmux: its built-in defaults are a port of the old `tmux.conf` and
its plugins, so the repo deploys no tmxr config, and `t` is a shell alias for
`tmxr`, whose bare form opens the session named after the current directory.

- **Considered and declined: keeping the old `t` script's three windows.** The
  `[hooks] session-created = ["new-window -d", "new-window -d"]` config tmxr
  documents for this also fires when tmxr restores a saved session at server
  start (`resurrect.rs` builds it through `Server::new_session`, which queues
  `session-created`). Verified with tmxr 0.9.0 on a scratch `-L` server: a
  three-window session came back with five, and would gain two more on every
  restart. Revisit once tmxr skips the hook on restore.
- **tmux stays installed on existing machines.** It left the `core` deps group,
  but `krypt deps` installs only; remove the package by hand where it is no
  longer wanted.
- **PowerShell's OSC 9;9 prompt hook is unverified under tmxr.** The profile's
  `Invoke-Starship-PreCommand` announces the directory so tmxr's splits open
  there on Windows, as tmxr's README describes; nobody has yet split a pane in
  tmxr on Windows with it. It only runs when starship draws the prompt.

## lyr

lyr replaced waybar and swaync on 2026-10-26: Hyprland starts it, and the
notification, Wi-Fi, audio and Bluetooth binds and the `krypt menu` commands run
`lyr` subcommands.

- **waybar is still deployed as a fallback**, by the owner's choice, though not
  installed everywhere: on `slowassdell` the package was removed with
  `paru -Rns` on 2026-10-26, and its config is still deployed there. In the repo
  `.config/waybar/`, its `src_glob` link and the `waybar` pacman package stay;
  its `custom/notification` module still calls `swaync-client`, guarded by
  `exec-if`, so it hides once swaync is gone. lyr's plan
  (`docs/plan/05-layout-and-config.md` in kryptic-sh/lyr) removes waybar once
  lyr has run as the daily bar for a while. Retiring it means deleting
  `.config/waybar/`, its `[[link]]`, the package and the fallback line under
  "Bar" in the README. Needs the owner's call on when.
- **swaync's package stays installed until removed by hand on each machine.**
  The dotfiles dropped swaync on 2026-11-02, but `krypt deps` only installs, so
  machines that had it keep it, and with it a D-Bus activation file
  (`/usr/share/dbus-1/services/org.erikreider.swaync.service`): the first
  notification sent while nothing owns `org.freedesktop.Notifications` starts
  swaync, which keeps the name, and lyr leaves notifications to it. Removing it
  takes `sudo pacman -Rns swaync`, then `systemctl --user stop swaync` if it is
  running, then restarting lyr so it claims the name. Done on `slowassdell`
  (2026-10-26).
- **lyr is off by default on macOS and Windows**, by the owner's choice on
  2026-10-26: the `kryptic` group installs it there (`kryptic-sh/tap/lyr`,
  `kryptic-sh/lyr`), but nothing starts it, since only `hyprland.lua` runs it.
  Turning it on later would take a launchd agent on macOS (plus, under
  AeroSpace, an `exec-and-forget lyr event workspace` callback, as `lyr --help`
  describes) and a Startup-folder shortcut or scheduled task on Windows, each
  deployed by a `[[link]]`.
- **Existing `apps.lua` files keep `notify = "swaync-client"`.** It was dropped
  from `apps.template.lua`, but `krypt setup` renders that template once, so
  machines set up before keep the line. Nothing reads it any more; delete it by
  hand if wanted.

## CI

- **PSScriptAnalyzer enforces only `ParseError` and `Error` severity** (the
  `psscriptanalyzer` job in `lint.yml`). Warning-level rules are not enforced;
  how many warnings the existing `.ps1` files raise has not been measured, so
  turning them on may need fixes or per-rule suppressions first.

## Coverage gaps

- **The README's `~/.files` migration misses chained links.** Step 3 resolves
  each link with `readlink -f`, which follows the whole chain, so a link into
  the clone whose target there is itself a link pointing outside it resolves
  outside `~/.files` and is not listed; deleting the clone then breaks it. No
  such link existed on `slowassdell`, so the snippet stayed simple. Fix if one
  turns up: resolve one hop (`readlink`, made absolute) instead of the chain.
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

- **Not packaged for apt or dnf, and not a crate**: `gemini-cli` (npm), `doctl`
  on apt, `lazygit` on dnf, and the kryptic-sh tools without a crates.io release
  (`pikr`, `buffr`, `inbx`, `hodl`, `krypt`). On Windows the kryptic-sh scoop
  bucket has pikr, buffr, hrdr, krypt, lyr and tmxr; `inbx`, `hodl` and
  `gemini-cli` are missing there. pikr and buffr publish `.deb`/`.rpm` release
  assets, which neither `krypt deps` nor apt/dnf can install by name. Options: a
  kryptic-sh apt/rpm repository, an npm source in krypt, or leaving them to the
  Arch/Homebrew lists.
- **`cargo:` entries need a default Rust toolchain.** On apt, dnf and scoop,
  `cargo:hjkl` and friends (and `cargo:starship` and `cargo:dysk` on dnf) build
  with `cargo`, which Debian's and Fedora's `rustup` packages leave without a
  default toolchain until `rustup default stable` runs — and the
  `rustup-default-stable` hook only runs on `krypt update`, never on a manual
  `krypt deps`. So on a fresh apt or dnf machine the `kryptic-deps` post-setup
  hook (`cargo:gpur`, `cargo:hjkl`, ...) fails until the first `krypt update`,
  whose `kryptic-deps` hook runs after `rustup-default-stable`. Unverified: no
  apt/dnf machine has run either hook yet. On Windows, krypt 0.4.1 picks up the
  `PATH` a scoop `rustup` install adds, so the `cargo:` entries no longer need a
  second run; not yet seen on a fresh machine.
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

### Arch machine package state (audited 2026-11-01)

An audit of the Arch machine removed every orphan `pacman -Qtd` reported (59
packages, ~940 MiB) after checking that no installed ELF file under `/usr/bin`,
`/usr/lib`, `/usr/lib32`, `/usr/libexec` or `/opt` names any of their sonames.
`.config/paru/paru.conf` now enables `RemoveMake` and `CleanAfter`, which was
the cause of most of them. That file replaces `/etc/paru.conf` instead of
extending it, so it `Include`s the system config first; dropping that line
silently turns off `PgpFetch`, `Devel`, `Provides` and `DevelSuffixes`. What the
audit raised and did not settle:

- **`sway` and `rofi` are installed but in no deps group.** The machine runs
  Hyprland (the `hyprland` group); `sway` pulls `wlroots0.20`, and `rofi` is
  configured under `.config/rofi/` while the `hyprland` group never names it.
  Decision: add both to a group, or uninstall them. `sway`'s old `wlroots0.19`
  was removed in the audit, so nothing depends on the leftover.
- **`wpebackend-fdo` and `libwpe` exist in no repository and no AUR package any
  more.** Both are marked foreign; `wpebackend-fdo` is explicitly installed and
  `libwpe` is its only dependant. No installed binary names
  `libWPEBackend-fdo-1.0.so`, so nothing uses them, and neither can be
  reinstalled or upgraded once removed. Probably left from a `webkit2gtk` WPE
  backend that moved on. Not removed: they were explicit, so the intent behind
  installing them is unknown.
- **`paru-debug` 2.1.0 is a stale debug package** from a local `paru` build;
  `paru` itself is 2.2.0, and no other `-debug` package is installed. Removable
  with no effect on `paru`.
- **`breeze` (38.79 MiB) is declared in the `apps` group, but only its
  `breeze-cursors` dependency is in use** — the `Breeze_Light` cursor named by
  `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini`,
  `.config/dconf/user.ini` and `hyprland.lua`. Its other dependency,
  `breeze-icons`, is required by `kiconthemes` for `hyprqt6engine`, so it stays
  either way; nothing reads the Plasma style itself, since
  `QT_QPA_PLATFORMTHEME` is `hyprqt6engine`. Option: swap `breeze` for
  `breeze-cursors` in the group. Unverified: whether `hyprqt6engine` falls back
  to the Breeze style for anything.
- **`vieb-bin` is declared in the `apps` group but is not installed** on this
  machine, and `openbox` was installed by hand and removed in the audit (it
  shipped eleven GTK2 themes under `/usr/share/themes` that nothing selects).
- **The caches were not cleaned**: `/var/cache/pacman/pkg` holds 5.1 GiB over
  1638 package files and `~/.cache/paru` 1.2 GiB. `CleanAfter` only covers paru
  builds from now on; the existing 1.2 GiB and the pacman cache need `paru -Sc`
  / `paccache -r` by hand. No retention policy is configured and no `paccache`
  timer is enabled.
- **Not reviewed:** the 181 packages `pacman -Qt` lists that are kept only by
  another package's `optdepends`. They are not orphans and were left alone; no
  judgement was formed about whether the optional features they serve are
  wanted.

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
- **Configs the old stow setup deployed but krypt does not are frozen copies.**
  On the Arch machine the `~/.files` clone was retired on 2026-10-21 (krypt's
  clone is now `~/.config/krypt/repo`), and each `~ -> .files` symlink was
  replaced by the file it pointed to. None of these is in `.krypt/links.toml`,
  so repo changes no longer reach them: `.config/nushell`,
  `.config/hjkl/config.toml`, `.config/hrdr/config.toml`, `.agents`,
  `.codex/config.toml`, plus repo-meta (`docs`, `.krypt.toml`, `.krypt`,
  `.gitignore`). Decision: add the real configs among these to `[[link]]`
  entries so krypt owns them, or leave them unmanaged deliberately. Repo-meta
  should stay out of krypt, and its copies in `$HOME` can go, except
  `~/.gitignore`: the `.gitconfig` names it as `core.excludesfile`, so every
  repo on the machine ignores what this repo ignores (`*.lock`, `*.log`,
  `.cache`, ...). It needs its own global excludes file, or the setting dropped.
  A machine that still has a `~/.files` clone needs the same treatment before
  the clone goes: `~/.claude`, `~/.claude-work` and `~/.codex` were symlinks
  into it holding credentials and session state.
