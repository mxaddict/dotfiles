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

Scripts in `.local/bin/` use a leading `.` (e.g. `.menu-apps`, `.kanata`,
`.envup`). This hides them from `ls` while keeping them invocable from
`.krypt/commands.toml`. New scripts should follow the same pattern.

Exceptions: third-party binaries (`grimblast`) and scripts invoked directly from
the shell (`t` — tmux session-per-cwd) keep their upstream / unprefixed name.

## Lint / format

The repo has an EditorConfig, a Prettier config, and a clang-format config. Run
them before committing:

```sh
# Markdown / JSON / YAML / TS / etc.
prettier --write <file>

# Shell scripts
shellcheck .local/bin/.<script>

# .krypt.toml + included sub-files
krypt validate

# C / C++
clang-format -i <file>
```

CI runs `shellcheck`, `prettier --check`, `krypt validate`, and JSON/TOML
validation on every push and PR (see `.github/workflows/lint.yml`).

## Adding a new app config

1. Drop the config under `.config/<app>/`.
2. Add a `[[link]]` entry to `.krypt/links.toml`:
   ```toml
   [[link]]
   src = ".config/<app>"
   dst = "${XDG_CONFIG}/<app>"
   ```
3. If the app stores per-machine state (caches, lockfiles, history) in the same
   directory, add a denylist + allowlist pair in `.gitignore` like the existing
   `.config/Vieb/*` block:
   ```
   !.config/<app>/<file-to-track>
   .config/<app>/*
   ```
4. If the config has user-specific content (paths, credentials, hardware names,
   identity), follow the **template pattern** below.
5. Run `krypt validate` to catch schema mistakes, then `krypt link --dry-run` to
   preview the symlink plan.

## Template pattern (user-configurable files)

Anything a user is expected to edit lives as a `*.template.*` file in the repo
and is copied to `$HOME` on first run by `krypt setup`. The real file lives at
the destination and is **not tracked** by git or symlinked.

To add a new templated file:

1. Create `<path>.template.<ext>` in the repo with sensible defaults + comments
   explaining what to change.
2. Add the destination path to `.gitignore` so the file can never leak back into
   the repo if a user copies it.
3. Add a `[[template]]` entry to `.krypt.toml`:
   ```toml
   [[template]]
   src     = ".config/foo/bar.template.conf"
   dst     = "${XDG_CONFIG}/foo/bar.conf"
   prompts = []     # or ["section-name"] to drive answers from a [prompts.*] block
   ```
4. Document the new file in the README's "Templates" table.
5. (Optional) If the file has high-signal user values, add a prompt block in
   `.krypt.toml`:

   ```toml
   [prompts.foo]
   heading = "Foo configuration"
   writer  = "template"
   src     = ".config/foo/bar.template.conf"
   dst     = "${XDG_CONFIG}/foo/bar.conf"

   [[prompts.foo.fields]]
   key     = "$port"
   prompt  = "Server port"
   default = "8080"
   ```

   Add `prompts = ["foo"]` on the `[[template]]` entry so `krypt setup` patches
   the answers into the seeded file.

`krypt setup` only seeds templates that are missing or empty — it never
overwrites a user's existing customisations. Prompts use the current value as
the default, so pressing Enter preserves it.

## Adding a new `krypt <group> <name>` command

Edit `.krypt/commands.toml`:

```toml
[[command]]
group       = "menu"
name        = "screenshot"
description = "Grimblast region picker"
platform    = "linux"
steps = [
    { run = ["bash", "${HOME}/.local/bin/.menu-screenshot"], ignore_failure = true },
]
```

Then `krypt validate` and (optionally) wire a Hyprland bind:

```
bind = $mod shift, s, exec, krypt menu screenshot
```

Args after `--` forward as `{0}`..`{9}` into steps — see `menu/autofill` for an
example.

## Adding a post-update hook

Edit `.krypt.toml` (hooks live at the top level, not in `.krypt/commands.toml`):

```toml
[[hook]]
name           = "my-thing"
when           = "post-update"
if             = "command_exists:foo"
run            = ["foo", "sync"]
ignore_failure = true
```

`if` predicates: `command_exists:`, `env:VAR`, `env:VAR=value`,
`platform:linux|macos|windows`, `file_exists:`, `!negation`, comma-separated
AND.

## Not in scope

- Distros other than Arch as the primary target. PRs filling in `apt` / `dnf` /
  `brew` arrays in `.krypt/deps.toml` are welcome but won't be tested.
- X11 support.

## Reporting issues

GitHub Issues. Include:

- Distro + kernel
- Hyprland / waybar / fish / krypt versions (`krypt --version`)
- Output of `krypt update --dry-run`
