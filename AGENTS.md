# AGENTS.md

This file contains guidelines and configurations for agentic coding agents
operating in this repository.

## Build/Lint/Test Commands

This is a dotfiles repository with no traditional software build processes. The
configuration files are maintained manually.

- No specific build commands
- No automated linting or testing framework
- Manual verification through system testing

## Code Style Guidelines

### General Conventions

- All files use UTF-8 encoding
- Line endings are LF (Unix-style)
- Files end with a newline character
- Trailing whitespace is trimmed

### Indentation and Formatting

- Default indent size: 4 spaces
- Indent style: spaces
- For CSS, HTML, JS, JSX, Lua, MD, SCSS, TOML, TSX, VUE, YAML, YML files: 2
  space indent
- For .gitconfig files: tab indent (indent_size = 8)
- For .gd files: tab indent (indent_size = 4)
- Maximum line width: 80 characters (for C++ according to clang-format)

### Language-Specific Guidelines

#### C/C++

- Follow Google C/C++ Code Style
- Pointer alignment: Left (align on the left)
- Braces for control structures: Custom style with AfterControlStatement: Never
- No short if statements without braces
- Space after cast: false
- Spaces around operators: true, with specific configurations for each operator
  type
- Tab width: 4

#### JavaScript/TypeScript

- Follow Prettier configuration defined in .prettierrc
- Print width: 80 characters
- Use single quotes
- Trailing commas: es5
- proseWrap: always

### Naming Conventions

- Variable and function names: camelCase
- Class names: PascalCase
- Constants: UPPER_CASE
- File names: lowercase with hyphens or underscores
- Configuration file names: lowercase with dots

### Error Handling

- No specific error handling conventions defined in configuration files
- Manual verification through system testing for configuration issues

### Import Styles

- For JavaScript/TypeScript: Standard ES6 import/export syntax
- For shell scripts: Standard sourcing and function-based organization

## Cursor/Rules Configuration

### Existing Rules

- No .cursor/rules directory found
- No .cursorrules file found
- No .github/copilot-instructions.md file found

### Copilot Guidelines

No specific Copilot instructions defined in this repository.

## Development Environment Setup

This repository contains configuration files for:

- Hyprland (Wayland compositor)
- Fish shell
- Neovim with LazyVim
- Alacritty terminal emulator
- Waybar status bar
- Rofi application launcher
- Swaync notification daemon
- Various GNOME and Linux utilities

## Maintenance Process

1. Manual verification of changes
2. Direct editing of configuration files in the repository
3. Testing through system restart or reload mechanisms
4. No automated test suite or build pipeline
