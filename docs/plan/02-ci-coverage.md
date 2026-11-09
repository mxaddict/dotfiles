# CI coverage

CI today proves that the files parse (`lint.yml`), that `krypt link` puts each
one where its tool reads it on Linux, macOS and Windows (`setup.yml` with
`test-setup.ps1`), that every package resolves and `core` installs (`deps.yml`),
that `krypt system root` works on Arch (`setup.yml`'s `root` job) and that the
agent CLIs install (`agents.yml`). What it does not prove is that the deployed
configs load in the programs that read them: only the PowerShell profile is
loaded and checked today.

Each step below is its own commit, pushed when green. Order is by value for the
effort.

## 1. Load the fish config

The PowerShell profile is dot-sourced in `test-setup.ps1` and its functions are
checked; the fish config only gets `fish --no-execute`, which catches syntax
errors and nothing else. On Linux and macOS, start fish on the deployed
`config.fish` and check the aliases resolve (`functions -q t ta tn ls cat ...`),
mirroring the PowerShell checks. `setup.yml` does not install fish; the `agents`
workflow shows how (apt on Linux, brew on macOS).

## 2. Verify the Hyprland config

`Hyprland --verify-config -c <file>` parses the Lua config without starting the
compositor. Checked locally (Hyprland on `mxaddict-pc`, 2026-11-10): it prints
`config ok` and exits 0 on the deployed config, and exits 1 both for a call to
an undefined dispatcher and for an unknown option key. Run it in an Arch
container against the config `krypt link` deployed, so the seeded `apps.lua`,
`input.lua` and `monitors.lua` templates are checked with it.

Unverified: whether `--verify-config` runs in a container with no GPU and no
Wayland session. Prove that first; if it does not, this step goes to the backlog
with the reason.

## 3. Load the Neovim config

Start Neovim headless on the deployed config and fail on any error output.
Checked locally in a throwaway home (2026-11-10):
`nvim --headless "+Lazy! sync" +qa` installs the plugins and exits in about 17
seconds, and **exits 0 even when the config raises an error**, so the job has to
read the output (`Error`, a stack traceback), not trust the exit code. Prove the
check red with a deliberately broken plugin spec before trusting it. Mason
starts installing tools during the sync and aborts them on exit; that output is
noise to filter, not a failure.

## 4. Check the manifests agree with the tree

A script over `.krypt/*.toml` and `git ls-files`, run in `lint.yml`:

- every `${HOME}/.local/bin/...` script a `[[command]]` runs is deployed by a
  `[[link]]` (passes today; it is the check the `.swaync-test` rename needed);
- every `[[link]]` `src` exists and every `src_glob` matches a file (passes
  today);
- every tracked file is deployed, a `[[template]]` source, or on an explicit
  repo-only list (`.github/`, `docs/`, `.krypt*`, `.root/` and
  `.local/bin/.root-configs`, which `krypt system root` runs from the clone,
  README ...).

The third check fails today on `.agents/`, `.codex/config.toml`,
`.config/hjkl/config.toml` and `.config/hrdr/config.toml`, the frozen copies the
backlog's "Decisions needed" asks about. Either that decision lands first, or
those four start on the exception list with a pointer to the backlog entry.

## 5. Run the setup wizard non-interactively

`krypt setup --yes --skip-hooks` fills every prompt with its default and runs
the writers (`gitconfig`, `hypr_vars`, ...), which no CI job runs today. Run it
in `test-setup.ps1`'s sandbox and check what each writer produced, for example
that `~/.gitconfig.local` parses with `git config --file`.

## 6. Parse the git config

`git config --file .gitconfig --list` in `lint.yml`. Cheap, and a typo in the
`.gitconfig` otherwise only shows when git reads it on a machine.

## Not in this phase

Already in the backlog, with their reasons: running `krypt update` and its
post-update hooks in CI (they install packages, the agent CLIs and cargo tools,
so a run is long and needs network), installing every deps group rather than
only `core`, and PSScriptAnalyzer warnings.
