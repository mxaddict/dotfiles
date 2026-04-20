#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort_level // .effortLevel // empty')

# Shorten home directory
home_short=$(echo "$cwd" | sed "s|^$HOME|~|")

# ANSI color helpers
# Backgrounds (256-color)
BG_BLUE="\e[48;5;24m"      # dark blue    — dir segment
BG_PURPLE="\e[48;5;55m"    # purple       — git branch segment
BG_TEAL="\e[48;5;30m"      # teal         — token segment
BG_ORANGE="\e[48;5;130m"   # orange       — ctx token count segment
BG_GRAY="\e[48;5;238m"     # dark gray    — context % segment
BG_DARKGREEN="\e[48;5;22m" # dark green   — model/effort segment
FG_WHITE="\e[38;5;255m"    # bright white text
RESET="\e[0m"

# Symbols
DIR_ICON="\xf0\x9f\x93\x82" # 📂
BRANCH_ICON="\xe2\x9c\xa6"  # ✦
UP_ICON="\xe2\xac\x86"      # ⬆
DOWN_ICON="\xe2\xac\x87"    # ⬇
CTX_ICON="\xe2\x97\x8f"     # ●

# Segment 1: directory (dark blue)
seg1="${BG_BLUE}${FG_WHITE} ${DIR_ICON} ${home_short} "

# Segment 2: git branch (purple) — only when inside a git repo
seg2=""
if [ -n "$branch" ]; then
    seg2="${BG_PURPLE}${FG_WHITE} ${BRANCH_ICON} ${branch} "
fi

# Segment 3: token counts (teal) — only when we have token data
seg3=""
if [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
    seg3="${BG_TEAL}${FG_WHITE} ${UP_ICON}${input_tokens} ${DOWN_ICON}${output_tokens} "
fi

# Segment 4: raw context token count (orange) — only when current_usage is available
ctx_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
seg4=""
if [ -n "$ctx_tokens" ]; then
    seg4="${BG_ORANGE}${FG_WHITE} ${CTX_ICON}ctx: ${ctx_tokens} "
fi

# Segment 5: context used % (gray) — only when percentage is available
seg5=""
if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")
    seg5="${BG_GRAY}${FG_WHITE} ${CTX_ICON}${used_int}% "
fi

# Right segment: model | effort (dark green) — only when model name is available
seg_right=""
seg_right_text=""
if [ -n "$model_name" ]; then
    if [ -n "$effort" ]; then
        seg_right_text=" ${model_name} | ${effort} "
    else
        seg_right_text=" ${model_name} "
    fi
    seg_right="${BG_DARKGREEN}${FG_WHITE}${seg_right_text}"
fi

# Calculate padding to right-align the right segment
if [ -n "$seg_right" ]; then
    # Build plain-text version of left side by stripping ANSI escapes
    left_plain=$(printf "%b" "${seg1}${seg2}${seg3}${seg4}${seg5}" | sed 's/\x1b\[[0-9;]*m//g')
    left_len=$(printf "%s" "$left_plain" | wc -m | tr -d ' ')
    right_len=$(printf "%s" "$seg_right_text" | wc -m | tr -d ' ')
    term_width=$(tput cols 2>/dev/null || echo 80)
    pad=$((term_width - left_len - right_len))
    if [ "$pad" -lt 1 ]; then
        pad=1
    fi
    padding=$(printf "%${pad}s" "")
    printf "%b\n" "${seg1}${seg2}${seg3}${seg4}${seg5}${RESET}${padding}${seg_right}${RESET}"
else
    printf "%b\n" "${seg1}${seg2}${seg3}${seg4}${seg5}${RESET}"
fi
