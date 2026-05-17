# .files

Personal dotfiles for an Arch + Hyprland workstation. Managed by
[krypt](https://github.com/kryptic-sh/krypt) — every install / update /
template-seed / hook is declared in `.krypt.toml` instead of a tangle of bash.

![Desktop Screenshot](screenshot.png)

## Philosophy

Sleek modern Wayland setup. Hyprland tiling, Fish shell, Neovim + LazyVim,
TokyoNight throughout. Config is data: `.krypt.toml` and its included files
describe what lives where, what packages to install, and what commands the user
can invoke. krypt does the work; bash scripts only exist when the logic is
genuinely shell-shaped.

## Prerequisites

- **Distro**: Arch Linux (or derivative). Cross-distro deps are stubbed — expand
  `[[deps]] apt = […]` / `dnf = […]` in `.krypt/deps.toml` to extend.
- **Display server**: Wayland (Hyprland). X11 unsupported.
- **CPU/GPU**: x86_64, any modern Wayland-capable GPU (tested on AMD).
- **CLI bootstrap**: `git`, `bash`, `curl`. Everything else `krypt setup`
  installs.

### Runtime assets (installed via `krypt update`'s deps step)

- **Font**: [Hack Nerd Font](https://www.nerdfonts.com/) (`ttf-hack-nerd`).
- **Cursor**: `Breeze_Light` (`breeze`).
- **GTK theme**: `adw-gtk-theme`.
- **Icon theme**: system default.

## Core Components

- **WM**: [Hyprland](https://hyprland.org/) — Wayland tiling compositor.
- **Shell**: [Fish](https://fishshell.com/).
- **Terminal**: [Alacritty](https://alacritty.org/).
- **Editor**: [Neovim](https://neovim.io/) +
  [LazyVim](https://www.lazyvim.org/).
- **Bar**: [Waybar](https://github.com/Alexays/Waybar).
- **Launcher**: [pikr](https://github.com/kryptic-sh/pikr) — vim-like fuzzy
  picker.
- **Notifications**: [swaync](https://github.com/Lentera/swaync).
- **File Manager**: [Nautilus](https://help.gnome.org/users/nautilus/).
- **Browser**: [Vieb](https://github.com/Jelmerro/Vieb).
- **Screenshot**: [Grimblast](https://github.com/hyprwm/contrib).
- **System monitor**: [btop](https://github.com/aristocratos/btop).
- **Prompt**: [Starship](https://starship.rs/).

## Install

### 1. Install krypt

| Platform | Command                                                                        |
| -------- | ------------------------------------------------------------------------------ |
| Arch     | `paru -S krypt-bin`                                                            |
| macOS    | `brew install kryptic-sh/tap/krypt`                                            |
| Any      | `cargo install krypt-cli`                                                      |
| Manual   | grab a binary from [GH Releases](https://github.com/kryptic-sh/krypt/releases) |

Verify: `krypt --version` should report `0.2.0` or newer.

### 2. Clone + link

```sh
krypt init https://github.com/mxaddict/dotfiles
krypt setup    # interactive: seeds templates, prompts for identity, installs deps
krypt link     # symlink the tree into $HOME
```

`krypt setup` is the wizard pass — runs the `[prompts.*]` blocks defined in
`.krypt.toml` (git identity, hypr defaults, keyboard layout), seeds templates,
then triggers `krypt deps` to install packages.

### 3. Daily updates

```sh
krypt update          # pull repo, install missing deps, run post-update hooks
krypt update --dry-run         # show plan, change nothing
krypt update --skip-hooks      # skip nvim/tmux/dconf/bat/etc. plugin syncs
```

Hooks declared in `.krypt.toml` (`[[hook]] when = "post-update"`) cover:

- mkdir essential `$HOME` dirs + `~/.local/log`
- fisher / nvim Lazy / tpm plugin syncs
- bat cache rebuild, tldr cache refresh
- dconf load from `dconf/user.ini`
- `hyprctl reload` (gated on hyprland running)

### Forking

`krypt init` accepts any HTTPS / SSH git URL. Point it at your fork.

## Migration from the old stow-bash version

If you used `.files` before krypt landed (`.update` / `.setup` bash scripts):

1. `paru -S krypt-bin` (or your platform's install)
2. `git -C ~/.files pull`
3. `krypt update` — replaces the old `.update` chain; reloads hyprland if active
4. Existing `~/.config/hypr/{apps,input,monitors,hyprpaper}.conf` etc. stay
   untouched (gitignored, krypt does not overwrite seeded files)

Bash scripts in `.local/bin/.*` (e.g. `.menu-power`, `.kanata`, `t`) **stay on
disk** — krypt invokes them via `[[command]]` entries. They get full
`shellcheck` + `ft=bash` treatment instead of being inlined into TOML strings.

The Hyprland keybinds in `hyprland.conf` now invoke `krypt menu <name>` instead
of the scripts directly. Same for waybar `on-click` handlers.

## Templates (user-specific, gitignored)

`krypt setup` seeds these from `*.template.*` files on first run. Re-running is
safe — krypt only seeds files that don't exist yet.

| Template (repo)                        | Destination                     | Purpose                          |
| -------------------------------------- | ------------------------------- | -------------------------------- |
| `.gitconfig.local.template`            | `~/.gitconfig.local`            | Name, email, GPG                 |
| `.config/hypr/apps.template.conf`      | `~/.config/hypr/apps.conf`      | `$terminal`, `$browser`, `$lock` |
| `.config/hypr/input.template.conf`     | `~/.config/hypr/input.conf`     | Keyboard layout                  |
| `.config/hypr/monitors.template.conf`  | `~/.config/hypr/monitors.conf`  | Monitor positions                |
| `.config/hypr/hyprpaper.template.conf` | `~/.config/hypr/hyprpaper.conf` | Wallpaper                        |

### Files to edit per-machine

1. `~/.gitconfig.local` — identity + signing.
2. `~/.config/hypr/monitors.conf` — `hyprctl monitors` to discover names.
3. `~/.config/hypr/apps.conf` — terminal / browser / file manager defaults.
4. `~/.config/hypr/input.conf` — change `kb_layout` if not US.

Optional:

- `~/.config/hypr/workspaces.conf` — pin workspaces to monitors.
- `~/.config/hypr/hyprpaper.conf` — wallpaper path.
- `.codex/config.toml`, `.config/opencode/opencode.json` — Ollama host.

## Keybinding cheatsheet (Hyprland)

`$mod` = **Super** (Windows key). Every menu binding invokes `krypt menu <name>`
or another krypt subcommand — see `.krypt/commands.toml` for the underlying
step.

### Apps & menus

| Bind                  | krypt invocation       | Action                  |
| --------------------- | ---------------------- | ----------------------- |
| `$mod + return` / `c` | —                      | Alacritty               |
| `$mod + b`            | —                      | Browser                 |
| `$mod + e`            | —                      | Nautilus                |
| `$mod + space`        | `krypt menu apps`      | App launcher            |
| `$mod + r`            | `krypt menu calc`      | qalculate picker        |
| `$mod + .`            | `krypt menu emoji`     | Emoji picker            |
| `$mod + w`            | `krypt menu wifi`      | WiFi picker             |
| `$mod + a`            | `krypt menu audio`     | wiremix                 |
| `$mod + u`            | `krypt menu bluetooth` | bluetui                 |
| `$mod + t`            | `krypt menu time`      | Timezone picker         |
| `$mod + escape`       | `krypt menu top`       | btop                    |
| `$mod + shift + m`    | `krypt menu power`     | Power picker            |
| `$mod + n` / `+S+n`   | —                      | swaync toggle / dismiss |
| `ctrl + shift + k`    | `krypt kanata toggle`  | Toggle kanata.service   |

### Autofill (pass + wtype)

| Bind              | krypt invocation              |
| ----------------- | ----------------------------- |
| `$mod + ctrl + j` | `krypt menu autofill -- auth` |
| `$mod + ctrl + k` | `krypt menu autofill -- user` |
| `$mod + ctrl + l` | `krypt menu autofill -- pass` |
| `$mod + ctrl + ;` | `krypt menu autofill -- otp`  |

### Screen

| Bind                 | Action                        |
| -------------------- | ----------------------------- |
| `$mod + p` / `Print` | Screenshot region (grimblast) |
| `$mod + shift + p`   | Screen record (kooha)         |
| `$mod + ctrl + p`    | Color picker                  |
| `$mod + m`           | Lock screen                   |

### Window management

| Bind                     | Action                   |
| ------------------------ | ------------------------ |
| `$mod + q`               | Close active             |
| `$mod + f`               | Maximize                 |
| `$mod + shift + f`       | True fullscreen          |
| `$mod + v`               | Toggle floating          |
| `$mod + s`               | Toggle split direction   |
| `$mod + h/j/k/l`         | Focus left/down/up/right |
| `$mod + shift + h/j/k/l` | Move window              |
| `ctrl + arrows`          | Resize                   |
| `$mod + tab`             | Cycle windows            |

### Workspaces

| Bind                  | Action                    |
| --------------------- | ------------------------- |
| `$mod + 1..9,0`       | Switch to workspace 1..10 |
| `$mod + shift + 1..0` | Move window to workspace  |
| `$mod + LMB drag`     | Move window               |
| `$mod + RMB drag`     | Resize window             |

### Audio / brightness

`XF86Audio*` and `XF86MonBrightness*` wired via `swayosd-client`.
`$mod + up/down/left/right` doubles as volume +/-/mute. Add `shift` for mic.

## `.krypt.toml` layout

Top-level `.krypt.toml` declares `[meta]`, `[paths]`, `[prompts.*]`, and
`[[template]]` entries, and includes three sub-files:

| File                   | Holds                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| `.krypt/links.toml`    | `[[link]]` symlink rules (`stow` replacement)                          |
| `.krypt/deps.toml`     | `[[deps]]` groups: cross-distro package mappings                       |
| `.krypt/commands.toml` | `[[command]] group=… name=…` — every `krypt <group> <name>` invocation |

`[[hook]] when = "post-update"` entries live in the top-level `.krypt.toml`.

To add a new menu (e.g. `krypt menu screenshot`):

1. Add `[[command]] group = "menu" name = "screenshot" steps = […]` to
   `.krypt/commands.toml`.
2. (Optional) Add the Hyprland bind in `.config/hypr/hyprland.conf`:
   `bind = $mod shift, s, exec, krypt menu screenshot`.
3. `krypt validate` — fail fast on config errors.

## Convention: dotfile-prefixed scripts

Scripts in `.local/bin/` are intentionally named with a leading `.` (e.g.
`.menu-apps`, `.kanata`). Hidden from `ls` but show with `ls -A`. Keeps the
user's interactive PATH visually clean while still being invocable from
`.krypt.toml`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit style, naming, lint.

## License

MIT — see [LICENSE](LICENSE).
