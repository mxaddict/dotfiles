#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)

# Shorten home directory
home_short=$(basename "$cwd")

# Format number with k/m/b suffix
fmt_num() {
    n=$1
    if [ "$n" -ge 1000000000 ]; then
        echo "$n 1000000000 b" | awk '{v=$1/$2; if(v==int(v)) printf "%db\n",v; else printf "%.1fb\n",v}'
    elif [ "$n" -ge 1000000 ]; then
        echo "$n 1000000 m" | awk '{v=$1/$2; if(v==int(v)) printf "%dm\n",v; else printf "%.1fm\n",v}'
    elif [ "$n" -ge 1000 ]; then
        echo "$n 1000 k" | awk '{v=$1/$2; if(v==int(v)) printf "%dk\n",v; else printf "%.1fk\n",v}'
    else printf "%d" "$n"; fi
}

# Foreground colors (bright)
FG_BLUE="\e[38;5;75m"      # bright blue    — dir segment
FG_PURPLE="\e[38;5;141m"   # bright purple  — git branch segment
FG_CYAN="\e[38;5;117m"     # bright cyan    — input tokens
FG_PINK="\e[38;5;213m"     # bright pink    — output tokens
FG_RED="\e[38;5;204m"      # bright coral red — effort segment
FG_DARKGREEN="\e[38;5;83m" # bright green   — model/effort segment
SEP="\e[38;5;244m"         # mid separator
RESET="\e[0m"

# Nerd Font icons — vim/lualine style
DIR_ICON=    #  file (buffer icon)
BRANCH_ICON= #  git branch
UP_ICON=     #  arrow-up (in tokens)
DOWN_ICON=   #  arrow-down (out tokens)
MODEL_ICON=  #  android (model)
EFFORT_ICON= #  bolt (effort)
BONE_ICON=🦴   # bone
BAR=" | "

# Build left segments
left=""

left="${left}${FG_BLUE}${DIR_ICON} ${home_short}"

if [ -n "$branch" ]; then
    left="${left}${SEP}${BAR}${FG_PURPLE}${BRANCH_ICON} ${branch}"
fi

caveman_flag="$HOME/.claude/.caveman-active"
if [ -f "$caveman_flag" ]; then
    caveman_mode=$(cat "$caveman_flag" 2>/dev/null)
    caveman_mode=${caveman_mode:-full}
    left="${left}${SEP}${BAR}\e[38;5;172m${BONE_ICON} ${caveman_mode}"
fi

if [ -n "$input_tokens" ]; then
    left="${left}${SEP}${BAR}${FG_CYAN}${UP_ICON} $(fmt_num "$input_tokens")"
fi

if [ -n "$output_tokens" ]; then
    left="${left}${SEP}${BAR}${FG_PINK}${DOWN_ICON} $(fmt_num "$output_tokens")"
fi

ctx_size=$(echo "$input" | jq -r '((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0)) | select(. > 0)')
if [ -n "$ctx_size" ]; then
    max_ctx=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
    max_fmt=$(fmt_num "${max_ctx:-0}")
    ctx_text=" $(fmt_num "$ctx_size") of ${max_fmt} "
    ctx_len=${#ctx_text}
    used_int=${used_pct:-0}
    filled=$(((used_int * (ctx_len + 1) + 50) / 100))
    BG_FILLED="\e[48;5;30m\e[38;5;255m"
    BG_EMPTY="\e[48;5;236m\e[38;5;250m"
    ctx_bar=""
    i=0
    while [ $i -lt $ctx_len ]; do
        ch=$(printf '%s' "$ctx_text" | cut -c$((i + 1)))
        if [ $((i + 1)) -lt $filled ]; then ctx_bar="${ctx_bar}${BG_FILLED}${ch}"; else ctx_bar="${ctx_bar}${BG_EMPTY}${ch}"; fi
        i=$((i + 1))
    done
    left="${left}${SEP}${BAR}${ctx_bar}\e[0m"
fi

if [ -n "$model_name" ]; then
    left="${left}${SEP}${BAR}${FG_DARKGREEN}${MODEL_ICON} ${model_name}"
fi

if [ -n "$effort" ]; then
    left="${left}${SEP}${BAR}${FG_RED}${EFFORT_ICON} ${effort}"
fi

printf "%b\n" "${left}${RESET}"
