#!/usr/bin/env fish
# No greeting text for now
set fish_greeting

# Set some stuff for out path
fish_add_path -g ~/.cargo/bin
fish_add_path -g ~/.local/bin
fish_add_path -g ~/.config/composer/vendor/bin
fish_add_path -g /opt/homebrew/bin
fish_add_path -g /opt/homebrew/opt/m4/bin
fish_add_path -g /opt/homebrew/opt/llvm/bin

# Set default editor to vim
set -gx EDITOR nvim

# Disable MANGOHUD by default
set -gx MANGOHUD 0

# Set JOSBS
set -gx JOBS "$(nproc)"

# Add makeflags
set -gx MAKEFLAGS "-j$JOBS"

# Set paru pager
set -gx PARU_PAGER "bat --color=always"
set -gx MAN_PAGER "bat --color=always"

# FZF theme
set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}'"
set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS \
    --height 100%
    --highlight-line \
    --info=inline-right \
    --ansi \
    --layout=reverse \
    --border=none
    --color=bg+:#283457 \
    --color=bg:#16161e \
    --color=border:#27a1b9 \
    --color=fg:#c0caf5 \
    --color=gutter:#16161e \
    --color=header:#ff9e64 \
    --color=hl+:#2ac3de \
    --color=hl:#2ac3de \
    --color=info:#545c7e \
    --color=marker:#ff007c \
    --color=pointer:#ff007c \
    --color=prompt:#2ac3de \
    --color=query:#c0caf5:regular \
    --color=scrollbar:#27a1b9 \
    --color=separator:#ff9e64 \
    --color=spinner:#ff007c \
    "

# Check for batcat
if command -v batcat >/dev/null
    alias bat batcat
end

# Check for exa and alias to eza
if command -v exa >/dev/null
    alias eza exa
end

# Replace cat with batcat
alias cat "bat --plain"
alias less cat

# Alias for cmatrix
alias c cmatrix

# Replace diff command with a more usefull git command
function diff
    git diff --name-only --relative --diff-filter=d | xargs bat --diff
end

# Git typo
function got
    echo "Hey! Fat fingers!!!"
    git $argv
end

# More git
alias gti got
alias gto got
alias tgi got
alias gut got
alias fur got
alias hot got

# fastfetch
alias f fastfetch
alias ff fastfetch

# Alias for lazygit
alias lg lazygit

# Alias for quick and dirty git commit
alias g 'git commit -am "$(quoty)"; git pull; git push'
alias gg 'git add . && git commit -m "$(quoty)"; git pull; git push'

# Alias for kweri
alias q kweri

# Add navcoin alias
alias nav navcoin-cli

# Replace default ls command with eza
alias ls "eza --group-directories-first"

# Replace tree command with eza
alias tree "eza --tree"

# Some more ls
alias l "ls -lF"
alias la "ls -aF"
alias ll "ls -alF"

# Clear alias
alias cl clear

# I want v to open vi and vi to open vim
alias v nvim
alias vi nvim
alias vim nvim
alias vd "nvim -d"
alias vimdiff "nvim -d"

# Trolling starts here 
alias code    nvim
alias emacs   nvim
alias hx      nvim
alias nano    nvim
alias subl    nvim
alias zeditor nvim

# TokyoNight Color Palette
set -l foreground c0caf5
set -l selection 283457
set -l comment 565f89
set -l red f7768e
set -l orange ff9e64
set -l yellow e0af68
set -l green 9ece6a
set -l purple 9d7cd8
set -l cyan 7dcfff
set -l pink bb9af7

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_option $pink
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
set -g fish_pager_color_selected_background --background=$selection

# Turn on vi mode for fish
fish_vi_key_bindings

# Load fzf
type -q fzf_key_bindings && fzf_key_bindings

# Disable ctrl-d for fish quit/exit
bind --mode insert \cd false
bind --mode default \cd false

# FZF binds
type -q fzf_configure_bindings && fzf_configure_bindings \
    --directory=\cd \
    --git_log=\cg \
    --git_status=\cs \
    --variables=\cv \
    --processes=\cp

# Load zoxide
if command -v zoxide >/dev/null
    zoxide init fish --cmd cd | source
end

# Check for nproc
if command -v nproc >/dev/null
    alias nproc "sysctl -n hw.physicalcpu"
end

# Load starship prompt
if command -v starship >/dev/null
    starship init fish | source
end

# Load the fuck
if command -v thefuck >/dev/null
    thefuck --alias | source
end
