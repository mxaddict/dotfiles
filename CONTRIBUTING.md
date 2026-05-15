# Contributing

Thanks for poking around. A few conventions if you want to fork or send a PR.

## Commit style

This repo uses **quote-of-the-day commit subjects** as an intentional aesthetic
choice — `git log` reads like a wall of programming wisdom, not change history.
The diff is the source of truth.

```
git log --oneline -5
c9412c2 Programmer: A machine that turns coffee into code. - Anon
4672ddc Given enough eyeballs, all bugs are shallow. - Linus Torvalds
1732ba8 'why no work', bro I haven't hacked your pc to get live feeds yet - Vaxry
```

This is **only** the convention for `.files` itself. Any other repo I touch (and
any sane project) uses
[Conventional Commits](https://www.conventionalcommits.org/).

If you fork this repo for your own dotfiles, feel free to change the convention
— there's nothing load-bearing about it.

## Naming convention

Scripts in `.local/bin/` use a leading `.` (e.g. `.menu-apps`, `.update`,
`.batrep`). This hides them from `ls` while keeping them on `$PATH`. New scripts
should follow the same pattern.

Exceptions: third-party binaries (`grimblast`, `t`) keep their upstream name.

## Lint / format

The repo has an EditorConfig, a Prettier config, and a clang-format config. Run
them before committing:

```sh
# Markdown / JSON / YAML / TS / etc.
prettier --write <file>

# Shell scripts
shellcheck .local/bin/.<script>

# C / C++
clang-format -i <file>
```

CI runs `shellcheck`, `prettier --check`, and JSON/TOML validation on every push
and PR (see `.github/workflows/lint.yml`).

## Adding a new app config

1. Drop the config under `.config/<app>/` (matches what `stow` expects).
2. If the app stores per-machine state (caches, lockfiles, history) in the same
   directory, add a denylist + allowlist pair in `.gitignore` like the existing
   `.config/Vieb/*` block:
   ```
   !.config/<app>/<file-to-track>
   .config/<app>/*
   ```
3. If the app needs first-run scaffolding, mirror the `hyprpaper.template.conf`
   pattern: ship a `*.template.*` file, have `.local/bin/.update` copy it on
   first install.

## Not in scope

- Distros other than Arch. PRs adding apt/dnf branches to `.deps` are welcome
  but won't be tested.
- X11 support.
- macOS / Windows.

## Reporting issues

GitHub Issues. Include:

- Distro + kernel
- Hyprland / waybar / fish versions
- Output of `.update --dry-run`
