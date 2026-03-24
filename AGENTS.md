# AGENTS.md

This file provides guidance to AI coding agents working in this repository. It
is symlinked as `CLAUDE.md` and `GEMINI.md` so all agents share the same
instructions.

## What This Is

Personal dotfiles repository for an Arch Linux (Hyprland) desktop environment.
Configs are symlinked into `$HOME` using
[GNU Stow](https://www.gnu.org/software/stow/). The repo root mirrors the home
directory structure — files at `.config/foo/bar` get stowed to
`~/.config/foo/bar`.

## Key Commands

- **Install/update everything**: `.update` (or `~/.local/bin/.update`) — pulls
  repo, installs deps, stows dotfiles, updates plugins
- **Install dependencies only**: `.deps` (or `~/.local/bin/.deps`) — installs
  system packages via pacman/paru, dnf, apt, or brew depending on platform
- **Quick git commit with random quote**: `gg` (fish function) — stages all,
  commits with a quote from `quoty`, pulls, pushes

There are no build, lint, or test commands — this is a config-only repo.

## Repository Structure

- **`.config/`** — XDG config files (the bulk of the repo)
  - `hypr/` — Hyprland compositor (tiling WM, keybindings, idle, lock,
    wallpaper)
  - `nvim/` — Neovim config based on LazyVim (`lua/plugins/` for plugin specs,
    `lua/config/` for options/keymaps/autocmds)
  - `fish/config.fish` — Fish shell config (aliases, env vars, vi mode,
    TokyoNight colors, starship/fzf/zoxide integration)
  - `alacritty/` — Terminal emulator config
  - `tmux/` — Tmux config (plugins managed by TPM, stored in `plugins/` which is
    gitignored)
  - `waybar/` — Status bar config
  - `rofi/` — Application launcher theme
  - `swaync/` — Notification daemon config
  - `starship.toml` — Shell prompt config
- **`.claude/`** — Claude Code settings (model, env vars, permissions, plugins)
- **`.local/bin/`** — Custom scripts (prefixed with `.`): menus (`.menu-*`),
  system helpers (`.update`, `.deps`, `.swap`, `.start`), bat wrappers
  (`.batlog`, `.batrep`), plus `t` (tmux session launcher)
- **`.root/`** — System-level configs (`/etc/` files) copied by `.deps` script —
  kanata keyboard remapping, pacman.conf, systemd units, udev rules
- **`.gitconfig`** — Git config (GPG signing enabled, auto setup remote on push)
- **`.editorconfig`** — 4-space indent default; 2-space for
  CSS/HTML/JS/JSON/Lua/MD/YAML/TOML; tabs for .gitconfig and .gd files
- **`.stow-local-ignore`** — Excludes non-config files (markdown, screenshots,
  LICENSE, `.root/`) from stow

## Code Style

- Follow `.editorconfig` for indentation rules
- JS/TS: Prettier with single quotes, trailing commas (es5), 80 char width,
  prose wrap always
- C/C++: `.clang-format` based on Google style, 4-space tabs, 80 char max width
- Shell scripts: use `set -euo pipefail` in bash; fish scripts use fish idioms
- Theme: TokyoNight throughout (Alacritty, Neovim, Fish, Waybar, Rofi, FZF)

## Important Conventions

- Scripts in `.local/bin/` are prefixed with `.` (e.g., `.update`, `.deps`,
  `.menu-power`)
- The `.deps` script handles multi-distro support (Arch/Fedora/Debian/macOS) —
  maintain all platform branches when editing
- Neovim plugins go in `lua/plugins/` as individual files following LazyVim
  plugin spec format
- Git commits are GPG-signed; the repo uses `main` as the default branch
