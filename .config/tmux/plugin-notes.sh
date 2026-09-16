#!/usr/bin/env bash
# vi: ft=bash
#
# Plugins bind their keys without a note (`bind -N`), so `krypt menu keys` shows
# them as "(no description)" and `prefix ?` skips them. Add a note to each
# plugin bind: `bind -N note -T table key` with no command keeps the bind's
# command. Each entry names the key, a pattern the plugin's command must match,
# and the note.
#
# The pattern keeps a note off a bind the plugin didn't make: with the plugin
# missing, or its key moved by an option, the same key may be a built-in (e.g.
# copy-mode-vi C-h is cursor-left). Such a key is skipped and reported on
# stderr with a non-zero exit. tmux discards a `run` job's stderr: a
# `tmux source-file` from a shell (and `krypt menu keys`) shows "... returned 1",
# and running this script in a pane of that server shows which keys.
#
# Run from tmux.conf after tpm. It acts on the server in $TMUX.

[[ -n ${TMUX-} ]] || {
    echo "plugin-notes: run from tmux.conf or a tmux pane" >&2
    exit 1
}

status=0

# $1 key table, $2 key as `tmux list-keys` names it, $3 extended regex the
# bind's command must match, $4 note, $5 (optional) extended regex it must not.
# With optional=1 in its environment, a key that is missing or bound to
# something else is skipped quietly: for plugins that only bind a free key.
note() {
    local command rc
    # `list-keys -T table key` prints nothing on tmux 3.7, so pick the key out
    # of the whole table. Values go through the environment: `awk -v` would
    # unescape backslashes.
    command=$(tmux list-keys -T "$1" -F '#{key_string}	#{key_command}' | key="$2" awk '
        index($0, ENVIRON["key"] "\t") == 1 { print substr($0, length(ENVIRON["key"]) + 2); exit }
    ')
    if [[ -z $command ]]; then
        [[ -n ${optional-} ]] && return
        echo "plugin-notes: no $1 bind for $2" >&2
        status=1
        return
    fi
    want="$3" unless="${5-}" awk '
        $0 !~ ENVIRON["want"] { exit 1 }
        ENVIRON["unless"] != "" && $0 ~ ENVIRON["unless"] { exit 1 }
    ' <<<"$command"
    rc=$?
    if ((rc == 1)); then
        [[ -n ${optional-} ]] && return
        echo "plugin-notes: $1 $2 is not the plugin's bind: $command" >&2
        status=1
        return
    elif ((rc != 0)); then
        echo "plugin-notes: bad pattern for $1 $2" >&2
        status=1
        return
    fi
    # A bare `;` separates tmux commands, even as its own argument.
    local key=$2
    [[ $key == ";" ]] && key='\;'
    tmux bind-key -N "$4" -T "$1" "$key" || status=1
}

# vim-tmux-navigator. In panes matching @vim_navigator_pattern the root binds
# send the key on to the app instead. @tmux_navigator_disable_when_zoomed wraps
# the command in single quotes, hence the optional '.
note root 'C-h' "select-pane -L'?\"\$" "Focus pane left, or pass the key to vim/fzf-like apps"
note root 'C-j' "select-pane -D'?\"\$" "Focus pane down, or pass the key to vim/fzf-like apps"
note root 'C-k' "select-pane -U'?\"\$" "Focus pane up, or pass the key to vim/fzf-like apps"
note root 'C-l' "select-pane -R'?\"\$" "Focus pane right, or pass the key to vim/fzf-like apps"
note root "C-\\" "select-pane -l'?\"\$" "Focus last pane, or pass the key to vim/fzf-like apps"
note prefix 'C-l' '^send-keys C-l$' "Clear screen (CTRL + l is taken by navigation)"
note copy-mode-vi 'C-h' '^select-pane -L$' "Focus pane left"
note copy-mode-vi 'C-j' '^select-pane -D$' "Focus pane down"
note copy-mode-vi 'C-k' '^select-pane -U$' "Focus pane up"
note copy-mode-vi 'C-l' '^select-pane -R$' "Focus pane right"
note copy-mode-vi "C-\\" '^select-pane -l$' "Focus last pane"

# tmux-sensible binds each of these only if the key is still free, so a key the
# user bound first is skipped. The prefix's "letter" is what sensible's
# prefix_without_ctrl takes: the text after the first `-` (a in C-a and M-a).
prefix=$(tmux show-options -gv prefix)
optional=1 note prefix "$(cut -d - -f 2 <<<"$prefix")" '^last-window$' "Last window"
[[ $prefix == C-b ]] || optional=1 note prefix "$prefix" '^send-prefix$' "Send the prefix key"
optional=1 note prefix 'C-n' '^next-window$' "Next window"
optional=1 note prefix 'C-p' '^previous-window$' "Previous window"
optional=1 note prefix 'R' 'tmux source-file ' "Reload tmux.conf"

# tmux-resurrect
note prefix 'C-s' '/save\.sh$' "Save sessions"
note prefix 'C-r' '/restore\.sh$' "Restore saved sessions"

# tmux-yank binds its copy keys in both copy-mode tables. With no clipboard tool
# it binds y, Y and M-y to an error message instead, and skips the rest.
yank_error="display-message 'Error! tmux-yank"
note prefix 'y' '/copy_line\.sh$' "Copy the command line to the clipboard"
note prefix 'Y' '/copy_pane_pwd\.sh$' "Copy the pane's working directory to the clipboard"
for table in copy-mode-vi copy-mode; do
    note "$table" 'y' '^send-keys -X copy-pipe[a-z-]* .' "Copy selection to the clipboard" "$yank_error"
    note "$table" 'Y' '^send-keys -X copy-pipe[a-z-]* "tmux paste-buffer -p"$' "Paste selection into the pane"
    note "$table" 'M-y' '; tmux paste-buffer -p"$' "Copy selection to the clipboard and paste it"
    note "$table" '!' '^send-keys -X copy-pipe[a-z-]* "tr -d ' "Copy selection to the clipboard without newlines"
    note "$table" 'MouseDragEnd1Pane' '^send-keys -X copy-pipe[a-z-]* .' "Copy mouse selection when the drag ends"
done

# tpm
note prefix 'I' '/install_plugins$' "Install plugins"
note prefix 'U' '/update_plugins$' "Update plugins"
note prefix 'M-u' '/clean_plugins$' "Remove plugins not listed in tmux.conf"

exit "$status"
