#!/usr/bin/env fish
# vi: ft=fish
# No greeting text for now
set fish_greeting

# Set some stuff for out path
fish_add_path -g ~/.cargo/bin
fish_add_path -g ~/.local/bin
fish_add_path -g ~/.config/composer/vendor/bin
fish_add_path -g ~/.local/share/nvim/mason/bin
fish_add_path -g /opt/homebrew/bin
fish_add_path -g /opt/homebrew/opt/m4/bin
fish_add_path -g /opt/homebrew/opt/llvm/bin

# Set default editor to vim
set -gx EDITOR nvim

# Disable MANGOHUD by default
set -gx MANGOHUD 0

# Add support for pin entry via ssh
set -gx GPG_TTY "$(tty)"

# Disable php_cs_fixer Check
set -gx PHP_CS_FIXER_IGNORE_ENV 1

# Set JOSBS
set -gx JOBS "$(.nproc)"

# Add makeflags
set -gx MAKEFLAGS "-j$JOBS"

# Set paru pager
set -gx PARU_PAGER "bat --color=always"
set -gx MANPAGER "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

# FZF theme
set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}'"
set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS \
    --height 100%
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
if command -v -q batcat
    function bat
        batcat $argv
    end
end

# Check for exa and alias to eza
if not command -v -q eza
    function eza
        exa $argv
    end
end

# Replace cat with bat
function cat
    bat --plain $argv
end

# Alias for cmatrix
function c
    cmatrix $argv
end

# Git typo
function got
    echo "Hey! Fat fingers!!!"
    git $argv
end

# More git
function gti
    got $argv
end
function gto
    got $argv
end
function tgi
    got $argv
end
function gut
    got $argv
end
function fur
    got $argv
end
function hot
    got $argv
end

# fastfetch
function ff
    clear
    fastfetch $argv
end

# Alias for lazygit
function lg
    lazygit $argv
end

# Alias for quick and dirty git commit
function gg
    set -l msg (quoty)

    if test -n "$msg"
        git add .
        git commit -m "$msg"
    else
        echo "Error: Could'nt get quote from quoty"
        return 1
    end
end
function gl
    set -l loc (curl -s https://ipinfo.io/loc)

    if test -n "$loc"
        git add .
        git commit -m "$loc"
    else
        echo "Error: Could'nt get location"
        return 1
    end
    git pull --no-edit
    git push
end

# Alias for kweri
function q
    kweri $argv
end

# Add navcoin alias
function nav
    navcoin-cli $argv
end

# Replace default ls command with eza
function ls
    eza --group-directories-first $argv
end

# Replace tree command with eza
function tree
    eza --tree $argv
end

# Some more ls
function l
    ls -lF $argv
end
function la
    ls -aF $argv
end
function ll
    ls -alF $argv
end

# Clear alias
function cl
    clear
end

# NVM
if command -v -q fnm
    function nvm
        fnm $argv
    end
end

# I want v to open vi and vi to open vim
function n
    nvim $argv
end
function nv
    nvim $argv
end
function nvi
    nvim $argv
end
function v
    nvim $argv
end
function vi
    nvim $argv
end
function vim
    nvim $argv
end

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

# FZF binds
type -q fzf_configure_bindings && fzf_configure_bindings \
    --directory=\cf \
    --git_log=\cg \
    --git_status=\cs \
    --variables=\cv \
    --processes=\cp

# Load zoxide
if command -v -q zoxide
    zoxide init fish --cmd cd | source
end

# Load starship prompt
if command -v -q starship
    starship init fish | source
end

# FNM setup env
if command -v -q fnm
    fnm env --shell fish | source
end
