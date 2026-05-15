# .files

My personal dotfiles for a consistent and productive Linux environment.

![Desktop Screenshot](screenshot.png)

## Philosophy

These dotfiles are curated to provide a sleek, modern, and efficient workflow.
The setup is based on Hyprland, a dynamic tiling Wayland compositor, and a set
of carefully selected tools that enhance productivity and user experience. The
color scheme is based on the popular
[TokyoNight](https://github.com/folke/tokyonight.nvim) theme.

## Prerequisites

- **Distro**: Arch Linux (or an Arch derivative). `.deps` uses `pacman` + `paru`
  exclusively — other distros are unsupported out of the box.
- **Display server**: Wayland (Hyprland). X11 will not work.
- **GPU**: Any modern GPU with a working Wayland driver. Tested on AMD; NVIDIA
  may need additional Hyprland config tweaks.
- **CPU**: x86_64. ARM is untested.
- **Required CLI**: `git`, `bash`, `curl`, `stow`. Everything else `.deps`
  installs.
- **Recommended**: Familiarity with Vim keybindings (Neovim, Vieb, tmux).

## Core Components

- **Window Manager**: [Hyprland](https://hyprland.org/) — dynamic tiling Wayland
  compositor.
- **Shell**: [Fish](https://fishshell.com/) — friendly interactive shell.
- **Terminal**: [Alacritty](https://alacritty.org/) — GPU-accelerated terminal.
- **Editor**: [Neovim](https://neovim.io/) with
  [LazyVim](https://www.lazyvim.org/).
- **Bar**: [Waybar](https://github.com/Alexays/Waybar).
- **Launcher**: [Rofi](https://github.com/davatorium/rofi).
- **Notifications**: [swaync](https://github.com/Lentera/swaync).
- **File Manager**: [Nautilus](https://help.gnome.org/users/nautilus/).
- **Browser**: [Vieb](https://github.com/Jelmerro/Vieb) — vim-like browser.
- **Screenshot**: [Grimblast](https://github.com/hyprwm/contrib).
- **System monitor**: [btop](https://github.com/aristocratos/btop).
- **Prompt**: [Starship](https://starship.rs/).

## Installation

> ⚠ The install scripts assume Arch Linux and will install many packages via
> `paru`. Read `.local/bin/.deps` before running.

### Quick install (curl pipe)

```sh
curl -SsL https://ba.sh/yar3 | sh
```

Raw URL:

```sh
curl -SsL https://raw.github.com/mxaddict/dotfiles/main/.local/bin/.update | sh
```

### Manual install (recommended for skeptics)

```sh
git clone https://github.com/mxaddict/dotfiles.git ~/.files
~/.files/.local/bin/.update --dry-run     # pull only, no changes applied
~/.files/.local/bin/.update               # full install
```

### Forking

Replace the repo URL via env var so `.update` clones your fork:

```sh
DOTFILES_REPO="https://github.com/you/dotfiles.git" ~/.files/.local/bin/.update
```

### Just install deps

```sh
curl -SsL https://ba.sh/zNcw | sh
# or
curl -SsL https://raw.github.com/mxaddict/dotfiles/main/.local/bin/.deps | sh
```

## First-run customization

Two files you almost certainly want to edit immediately after install:

1. **`~/.gitconfig.local`** — copy from `.gitconfig.local.template` and fill in
   your name, email, and (optional) GPG signing key. `~/.gitconfig` includes it
   automatically.
2. **`~/.config/hypr/monitors.conf`** — `.update` seeds this from
   `monitors.template.conf` on first run. Run `hyprctl monitors` to find your
   display names and edit accordingly.

Other common edits:

- `~/.config/hypr/workspaces.conf` — pin workspaces to monitors.
- `~/.config/hypr/hyprpaper.conf` — change wallpaper path.
- `.codex/config.toml` and `.config/opencode/opencode.json` — point Ollama at
  your host (default: `localhost:11434`).

## Keybinding Cheatsheet (Hyprland)

`$mod` = **Super** (Windows key).

### Apps & menus

| Bind                  | Action                         |
| --------------------- | ------------------------------ |
| `$mod + return` / `c` | Terminal (Alacritty)           |
| `$mod + b`            | Browser                        |
| `$mod + e`            | File manager (Nautilus)        |
| `$mod + space`        | App launcher                   |
| `$mod + r`            | Calculator                     |
| `$mod + .`            | Emoji picker                   |
| `$mod + w`            | WiFi menu                      |
| `$mod + a`            | Audio menu                     |
| `$mod + u`            | Bluetooth menu                 |
| `$mod + t`            | Time menu                      |
| `$mod + escape`       | Top processes menu             |
| `$mod + shift + m`    | Power menu                     |
| `$mod + n` / `+S+n`   | Toggle / dismiss notifications |

### Screen

| Bind                 | Action                |
| -------------------- | --------------------- |
| `$mod + p` / `Print` | Screenshot region     |
| `$mod + shift + p`   | Screen record (kooha) |
| `$mod + ctrl + p`    | Color picker          |
| `$mod + m`           | Lock screen           |

### Window management

| Bind                     | Action                   |
| ------------------------ | ------------------------ |
| `$mod + q`               | Close active window      |
| `$mod + f`               | Maximize (fullscreen-1)  |
| `$mod + shift + f`       | True fullscreen          |
| `$mod + v`               | Toggle floating          |
| `$mod + s`               | Toggle split direction   |
| `$mod + h/j/k/l`         | Focus left/down/up/right |
| `$mod + shift + h/j/k/l` | Move window              |
| `ctrl + arrows`          | Resize active window     |
| `$mod + tab`             | Cycle windows            |

### Workspaces

| Bind                  | Action                    |
| --------------------- | ------------------------- |
| `$mod + 1..9,0`       | Switch to workspace 1..10 |
| `$mod + shift + 1..0` | Move window to workspace  |
| `$mod + LMB drag`     | Move window               |
| `$mod + RMB drag`     | Resize window             |

### Autofill (password manager menu)

| Bind              | Action   |
| ----------------- | -------- |
| `$mod + ctrl + j` | Auth     |
| `$mod + ctrl + k` | Username |
| `$mod + ctrl + l` | Password |
| `$mod + ctrl + ;` | OTP      |

### Audio / brightness

`XF86Audio*` and `XF86MonBrightness*` keys are wired via `swayosd-client`.
`$mod + up/down/left/right` doubles as volume +/-/mute. Add `shift` for mic.

## Convention: dotfile-prefixed scripts

Scripts in `.local/bin/` are intentionally named with a leading `.` (e.g.
`.menu-apps`, `.update`). They are hidden from a plain `ls` but show up with
`ls -A`. This keeps the user's "real" PATH visually clean. Use
`ls -A ~/.local/bin/` to discover them.

## Update workflow

```sh
~/.local/bin/.update              # update repo + deps + plugins
~/.local/bin/.update --dry-run    # pull only
~/.local/bin/.update --no-stash   # fail instead of auto-stashing
```

Env vars: `DOTFILES_REPO`, `DOTFILES_DIR`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit style, naming conventions, and
lint expectations.

## License

MIT — see [LICENSE](LICENSE).
