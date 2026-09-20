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
- **The scoop bucket is unused.** On a Windows machine with scoop, winget still
  installs every group because none lists scoop packages; the kryptic-sh bucket
  (pikr, buffr, hrdr, krypt) would need `scoop bucket add` before any `scoop`
  list could use it.

## `.menu-bluetooth` (pikr Bluetooth picker)

`krypt menu bluetooth` runs `.local/bin/.menu-bluetooth`: reads go through one
`busctl` `GetManagedObjects` snapshot shaped by `jq`, connect / disconnect /
forget / power are `busctl` calls verified by re-reading the property, and only
scanning and pairing use `bluetoothctl`. Verified against a stub harness (fake
`busctl`, `bluetoothctl`, `pikr` on `PATH`, canned D-Bus JSON), with each guard
broken once to see its test fail. Pairing, bonding and forgetting were also run
against real hardware (AirPods Pro 2 on junji-pc) and checked in an HCI trace;
everything else below was not run against real hardware unless it says so.

### Not covered

- **Passkey and PIN pairing.** The picker pairs under bluetoothctl's
  `KeyboardDisplay` agent, so bluez can negotiate a passkey or a numeric
  comparison — but the script only ever writes `default-agent` and `pair` to
  that session and never answers a prompt, so a device that asks for one times
  out and is handed to bluetui with a notification. Doing it inline means
  reading the session's prompts back and rendering them in a picker.
- **Audio does not follow a fresh pairing.** Reported on junji-pc: connecting an
  already-paired device moves the default sink, pairing a new one does not.
  `module-switch-on-connect` is loaded
  (`.config/pipewire/pipewire-pulse.conf.d/switch-on-connect.conf`) and
  WirePlumber's `default-nodes` already names the device, so routing is
  configured. Reading the module's source for the installed version,
  `manager_added` looks the sink's card up in the manager and `return`s silently
  when it is not there yet — before the `considering switching to` log line —
  which would fire exactly when a card and its sink node appear together, as
  they do on a first pairing. That is a candidate, not a finding: it was never
  reproduced under instrumentation. To settle it, run pipewire-pulse with
  `PIPEWIRE_DEBUG=mod.switch-on-connect#5` and pair a device: no
  `considering switching to` line at all means the card lookup; a line followed
  by `not switching to …` names a different check. Nothing in this script is
  implicated either way — it is a pipewire question.
- **A mouse cannot scan, forget or power off when pikr has `--kb-custom`.**
  Those three are bound to keys (`^S`, `^O`, `Right`) and named in the prompt,
  and `build_list` adds the row through to the actions list only when the keys
  are absent. pikr makes nothing but a row clickable — its sole `Click` handler
  is on the row stack in `ui/view.rs` — so a mouse route means an action row in
  the device list, or a second waybar binding. Both were considered and
  declined: the device lists are meant to hold devices and nothing else, and the
  bar icon is meant to have one click. So with a fork pikr a mouse connects and
  disconnects, and bluetui stays the fallback for the rest. This is a known
  departure from "mouse + keyboard, both work, always"; reopening it means
  giving up one of those two, or a pikr that can make something other than a row
  clickable.
- **Just Works has no MITM protection.** That is the protocol, not the script,
  but it is what inline pairing amounts to.
- **A second adapter.** The first `org.bluez.Adapter1` object (sorted by path)
  is used; devices on another adapter are not listed.
- **Nameless devices** are left out of the scan list (random-address LE beacons
  mostly), so a device that advertises no name can't be paired from the picker.
- **Block / unblock, untrust, rename, per-profile connect.** bluetui does the
  first three; a blocked device is shown as such and refused.

### Not verified

- `bluetoothctl`'s exit status when the daemon returns a D-Bus error. The script
  does not depend on it: success is the `Paired` / `Connected` property.
- When `pair` returns relative to the trust and connect bluetoothctl does after
  pairing. The script sets `Trusted` itself, polls `Connected`, and calls
  `Connect` only if the device is still not connected.
- That discovery ends when the scanning `bluetoothctl` is killed. It is why a
  `busctl` `StartDiscovery` was not used; the BlueZ docs say sessions are per
  client but not that a client's exit releases them.
- `AuthenticationFailed` is broader than "needs a passkey"; handing those to
  bluetui is still the useful response.
- The pikr flags it uses when present (`--kb-custom`, `--loading`) are not in a
  pikr release yet; the stock-pikr paths were exercised in the harness only.

### Shared code with `.menu-wifi`

`notify`, `uptime_ms`, the debounce / toggle / `flock` block and the
rows-file-to-line-number pick mapping are the same logic in both scripts,
written with the same names so they can move. Extract them to a sourced
`.local/bin/.menu-lib` and convert both scripts in one pure-move change. The lib
needs its own `[[link]]`; CI's shellcheck glob only lints executables, so either
make it executable or prove it is reached through `shellcheck -x`.

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
