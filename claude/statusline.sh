#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Claude Code Statusline
# ═══════════════════════════════════════════════════════════════════════════════
# Dependencies: jq (required), git (optional)
# Modes: nano(<35) micro(35-54) mini(55-79) normal(80+)
# ═══════════════════════════════════════════════════════════════════════════════
command -v jq >/dev/null 2>&1 || { printf 'claude statusline: jq is required\n' >&2; exit 1; }

detect_terminal_width() {
    local w=""

    # Try tput first — fastest, works in most terminals
    w=$(tput cols 2>/dev/null)

    # stty as fallback — but with a 1-second timeout (can hang in hooks)
    if [ -z "$w" ] || [ "$w" = "0" ]; then
        w=$(timeout 1 stty size </dev/tty 2>/dev/null | awk '{print $2}') 2>/dev/null || true
    fi

    # Kitty IPC last — slowest, only when needed
    if { [ -z "$w" ] || [ "$w" = "0" ]; } && [ -n "$KITTY_WINDOW_ID" ] && command -v kitten >/dev/null 2>&1; then
        w=$(timeout 2 kitten @ ls 2>/dev/null | jq -r --argjson wid "$KITTY_WINDOW_ID" \
            '.[].tabs[].windows[] | select(.id==$wid) | .columns' 2>/dev/null) || true
    fi

    # Final fallback
    [ -z "$w" ] || [ "$w" = "0" ] && w=${COLUMNS:-80}

    # Sanity check
    case "$w" in ''|*[!0-9]*) w=80 ;; esac
    [ "$w" -lt 20 ] && w=80

    echo "$w"
}

term_width=$(detect_terminal_width)
if   [ "$term_width" -lt 35 ]; then MODE="nano"
elif [ "$term_width" -lt 55 ]; then MODE="micro"
elif [ "$term_width" -lt 80 ]; then MODE="mini"
else                                 MODE="normal"
fi

# ── configuration ──────────────────────────────────────────────────────────────
# Approximate tokens for system prompt + tools + MCP schemas.
# These are already included in the API's token counts (cache_read, etc.)
# but we subtract them to show "conversation" vs "system" usage separately.
# Typical: ~22k with a few MCP servers. Tune to match your /context output.
# Override via env: CC_CONTEXT_BASELINE=25000
# See: github.com/anthropics/claude-code/issues/13783
CONTEXT_BASELINE=${CC_CONTEXT_BASELINE:-22600}

# ── parse JSON input ───────────────────────────────────────────────────────────
input=$(cat)

eval "$(printf '%s' "$input" | jq -r '
  "current_dir="    + (.workspace.current_dir // .cwd // ""            | @sh) + "\n" +
  "model_name="     + (.model.display_name    // "Unknown"             | @sh) + "\n" +
  "cc_version="     + (.version               // "?"                   | @sh) + "\n" +
  "duration_ms="    + (.cost.total_duration_ms                // 0 | tostring) + "\n" +
  "total_cost="     + (.cost.total_cost_usd                  // 0 | tostring) + "\n" +
  "lines_added="    + (.cost.total_lines_added                // 0 | tostring) + "\n" +
  "lines_removed="  + (.cost.total_lines_removed              // 0 | tostring) + "\n" +
  "cache_read="     + (.context_window.current_usage.cache_read_input_tokens    // 0 | tostring) + "\n" +
  "cache_creation=" + (.context_window.current_usage.cache_creation_input_tokens// 0 | tostring) + "\n" +
  "input_tokens="   + (.context_window.current_usage.input_tokens               // 0 | tostring) + "\n" +
  "output_tokens="  + (.context_window.current_usage.output_tokens              // 0 | tostring) + "\n" +
  "context_max="    + (.context_window.context_window_size    // 200000 | tostring) + "\n" +
  "ctx_used_pct="   + (.context_window.used_percentage        // 0      | tostring)
')"

dir_name=$(basename "${current_dir:-$PWD}")

# ── MCP servers ────────────────────────────────────────────────────────────────
MCP_COUNT=0; MCP_NAMES=""
USER_JSON="$HOME/.claude.json"
PROJ_JSON="${current_dir}/.mcp.json"

ALL_MCP=$(jq -rns \
    --slurpfile u <([ -f "$USER_JSON" ] && cat "$USER_JSON" || printf '{}') \
    --slurpfile p <([ -f "$PROJ_JSON" ] && cat "$PROJ_JSON" || printf '{}') \
    --arg cwd "$current_dir" '
    ($u[0].mcpServers // {} | keys) +
    ($u[0].projects[$cwd].mcpServers // {} | keys) +
    ($p[0].mcpServers // {} | keys) |
    unique | map(gsub("^mcp-";"") | gsub("^mcp_";"") | gsub("-mcp$";"")) | .[]
' 2>/dev/null || true)

if [ -n "$ALL_MCP" ]; then
    MCP_COUNT=$(printf '%s\n' "$ALL_MCP" | wc -l | tr -d ' ')
    budget=$((term_width - 32)); [ "$budget" -lt 20 ] && budget=20
    built=""; shown=0
    while IFS= read -r name; do
        cand="${built:+$built, }${name}"
        if [ "${#cand}" -le "$budget" ]; then built="$cand"; shown=$((shown+1))
        else break; fi
    done <<< "$ALL_MCP"
    ov=$((MCP_COUNT - shown))
    [ "$ov" -gt 0 ] && MCP_NAMES="${built} +${ov}" || MCP_NAMES="$built"
fi

# ── skills count ───────────────────────────────────────────────────────────────
SKILLS_COUNT=0
CLAUDE_DIR="${HOME}/.claude"
if [ -d "${CLAUDE_DIR}/skills" ]; then
    SKILLS_COUNT=$(ls -d "${CLAUDE_DIR}/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
fi
# Also check project-local skills
if [ -d "${current_dir}/.claude/skills" ]; then
    proj_skills=$(ls -d "${current_dir}/.claude/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
    SKILLS_COUNT=$((SKILLS_COUNT + proj_skills))
fi

# ── hooks count ─────────────────────────────────────────────────────────────────
# Count actual hook commands from all settings sources (user, project, local)
HOOKS_COUNT=$(jq -rs '
    [.[].hooks // {} | to_entries[] | .value[] | .hooks // [] | length] | add // 0
' <([ -f "$HOME/.claude/settings.json" ] && cat "$HOME/.claude/settings.json" || echo '{}') \
  <([ -f "${current_dir}/.claude/settings.json" ] && cat "${current_dir}/.claude/settings.json" || echo '{}') \
  <([ -f "${current_dir}/.claude/settings.local.json" ] && cat "${current_dir}/.claude/settings.local.json" || echo '{}') \
  2>/dev/null)
HOOKS_COUNT=${HOOKS_COUNT:-0}

# ── context / cost / tokens (pure arithmetic — no subshells) ───────────────────
max_k=$((context_max / 1000))

# The API token counts (cache_read, input_tokens, cache_creation) already
# include system prompt, tools, and MCP schemas. No need to add a baseline.
content_tokens=$((cache_read + input_tokens + cache_creation))
context_used=$content_tokens

# Break out system vs conversation tokens so users can see what the
# system prompt costs them.
conversation_tokens=$((content_tokens - CONTEXT_BASELINE))
[ "$conversation_tokens" -lt 0 ] && conversation_tokens=0
conversation_k=$((conversation_tokens / 1000))
baseline_k=$((CONTEXT_BASELINE / 1000))

if [ "$context_max" -gt 0 ] && [ "$context_used" -gt 0 ]; then
    context_pct=$((context_used * 100 / context_max))
    context_k=$((context_used / 1000))
else
    context_pct=0
    context_k=0
fi
[ "$context_pct" -gt 100 ] && context_pct=100

total_input=$((cache_read + input_tokens))
if [ "$total_input" -gt 0 ]; then
    cache_hit_pct=$((cache_read * 100 / total_input))
else
    cache_hit_pct=0
fi
in_k=$(( input_tokens / 1000 ))
out_k=$(( output_tokens / 1000 ))
cache_k=$(( (cache_read + cache_creation) / 1000 ))

duration_sec=$((duration_ms / 1000))
if   [ "$duration_sec" -ge 3600 ]; then time_str="$((duration_sec/3600))h$((duration_sec%3600/60))m"
elif [ "$duration_sec" -ge 60 ];   then time_str="$((duration_sec/60))m$((duration_sec%60))s"
else time_str="${duration_sec}s"
fi

cost_str=$(printf '$%.3f' "$total_cost")
velocity_str=""
if [ "$duration_ms" -gt 10000 ]; then
    velocity_str=$(awk -v c="$total_cost" -v ms="$duration_ms" \
        'BEGIN{ if(c>0.0001){ printf "~$%.2f/hr", c/ms*3600000 } }' /dev/null)
fi

# ── precompute colors ─────────────────────────────────────────────────────────
# pct_color → PC
if   [ "$context_pct" -le 33 ]; then PC='\033[38;2;74;222;128m'
elif [ "$context_pct" -le 66 ]; then PC='\033[38;2;251;191;36m'
else                                  PC='\033[38;2;251;113;133m'
fi

# cache hit color → CC_TOK
if   [ "$cache_hit_pct" -ge 50 ]; then CC_TOK='\033[38;2;74;222;128m'
elif [ "$cache_hit_pct" -ge 20 ]; then CC_TOK='\033[38;2;251;191;36m'
else                                    CC_TOK='\033[38;2;251;113;133m'
fi

# bar_pct_color → BAR_LABEL_COLOR
if [ "$context_pct" -gt 0 ]; then
    BAR_LABEL_COLOR=$(awk -v p="$context_pct" 'BEGIN {
        if(p>100)p=100
        if(p<=33){r=int(74+(250-74)*p/33);g=int(222+(204-222)*p/33);b=int(128+(21-128)*p/33)}
        else if(p<=66){t=p-33;r=int(250+(251-250)*t/33);g=int(204+(146-204)*t/33);b=int(21+(60-21)*t/33)}
        else{t=p-66;r=int(251+(239-251)*t/34);g=int(146+(68-146)*t/34);b=int(60+(68-60)*t/34)}
        printf "\033[38;2;%d;%d;%dm",r,g,b
    }' /dev/null)
else
    BAR_LABEL_COLOR='\033[38;2;74;222;128m'
fi

# ── git (all values precomputed) ──────────────────────────────────────────────
GIT_AVAIL=false
if git -C "${current_dir:-.}" rev-parse --git-dir &>/dev/null 2>&1; then
    GIT_AVAIL=true
    branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null || printf 'detached')
    modified=$(git -C "$current_dir" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged=$(git -C "$current_dir" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$current_dir" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    stash_count=$(git -C "$current_dir" stash list 2>/dev/null | wc -l | tr -d ' ')
    total_changed=$((modified + staged))

    # Deleted files (subset of modified+staged, for three-way split)
    deleted=$(git -C "$current_dir" --no-optional-locks diff --diff-filter=D --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged_del_files=$(git -C "$current_dir" --no-optional-locks diff --cached --diff-filter=D --name-only 2>/dev/null | wc -l | tr -d ' ')
    total_deleted=$((deleted + staged_del_files))
    total_modified=$((total_changed - total_deleted))

    diff_stats=$(git -C "$current_dir" --no-optional-locks diff --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {printf "%d %d", a+0, d+0}')
    diff_ins=${diff_stats%% *}
    diff_del=${diff_stats##* }
    staged_stats=$(git -C "$current_dir" --no-optional-locks diff --cached --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {printf "%d %d", a+0, d+0}')
    staged_ins=${staged_stats%% *}
    staged_del=${staged_stats##* }
    git_diff_ins=$((diff_ins + staged_ins))
    git_diff_del=$((diff_del + staged_del))

    ahead=0; behind=0
    ab=$(git -C "$current_dir" rev-list --left-right --count HEAD...@{u} 2>/dev/null)
    if [ -n "$ab" ]; then
        ahead=$(printf '%s' "$ab" | awk '{print $1}')
        behind=$(printf '%s' "$ab" | awk '{print $2}')
    fi

    age_str=""; age_era="old"
    lce=$(git -C "$current_dir" log -1 --format='%ct' 2>/dev/null)
    if [ -n "$lce" ]; then
        now=$(date +%s); age_s=$((now - lce))
        age_m=$((age_s/60)); age_h=$((age_s/3600)); age_d=$((age_s/86400))
        if   [ "$age_m" -lt 1  ]; then age_str="now";       age_era="fresh"
        elif [ "$age_h" -lt 1  ]; then age_str="${age_m}m";  age_era="fresh"
        elif [ "$age_h" -lt 24 ]; then age_str="${age_h}h";  age_era="recent"
        elif [ "$age_d" -lt 7  ]; then age_str="${age_d}d";  age_era="stale"
        elif [ "$age_d" -lt 30 ]; then age_str="$((age_d/7))w";  age_era="old"
        else                           age_str="$((age_d/30))mo"; age_era="old"
        fi
    fi
    [ "$total_changed" -gt 0 ] || [ "$untracked" -gt 0 ] && git_clean=false || git_clean=true

    case "$age_era" in
        fresh)  AC='\033[38;2;125;211;252m' ;;
        recent) AC='\033[38;2;96;165;250m' ;;
        stale)  AC='\033[38;2;59;130;246m' ;;
        *)      AC='\033[38;2;99;102;241m' ;;
    esac

    SS=""
    [ "$ahead"  -gt 0 ] && SS="${SS}\033[38;2;125;211;252m↑${ahead}\033[0m"
    [ "$behind" -gt 0 ] && SS="${SS}\033[38;2;165;180;252m↓${behind}\033[0m"
fi

# ── ANSI palette ───────────────────────────────────────────────────────────────
R='\033[0m'
S3='\033[38;2;203;213;225m'
S4='\033[38;2;148;163;184m'
S5='\033[38;2;100;116;139m'
S6='\033[38;2;71;85;105m'
EM='\033[38;2;74;222;128m'
RO='\033[38;2;251;113;133m'
AM='\033[38;2;251;191;36m'
HDR='\033[38;2;99;102;241m'
EV='\033[38;2;59;130;246m'
EB='\033[1;38;2;255;255;255m'
ET='\033[38;2;251;191;36m'
ML='\033[38;2;16;185;129m'
MC='\033[38;2;52;211;153m'
MN='\033[38;2;110;231;183m'
CP='\033[38;2;129;140;248m'
CS='\033[38;2;165;180;252m'
CA='\033[38;2;139;92;246m'
CE='\033[38;2;75;82;95m'
GP='\033[38;2;56;189;248m'
GV='\033[38;2;186;230;253m'
GD='\033[38;2;147;197;253m'
GC='\033[38;2;125;211;252m'
GM='\033[38;2;96;165;250m'
GA='\033[38;2;59;130;246m'
GS='\033[38;2;165;180;252m'
TK='\033[38;2;103;232;249m'
CH='\033[38;2;52;211;153m'
SK='\033[38;2;251;191;36m'

# ── helper functions ───────────────────────────────────────────────────────────

print_divider() {
    printf '%b' "$S6"
    printf '%*s' "$term_width" '' | tr ' ' '─'
    printf '%b\n' "$R"
}

print_bar() {
    local width="$1" pct="$2"
    [ "$pct" -gt 100 ] && pct=100
    local filled=$(( pct * width / 100 ))
    local use_gap=0
    [ "$width" -gt 8 ] && use_gap=1
    awk -v w="$width" -v f="$filled" -v gap="$use_gap" 'BEGIN {
        for (i = 1; i <= w; i++) {
            p = int(i * 100 / w)
            if (p <= 33) { r = int(74+(250-74)*p/33); g = int(222+(204-222)*p/33); b = int(128+(21-128)*p/33) }
            else if (p <= 66) { t=p-33; r = int(250+(251-250)*t/33); g = int(204+(146-204)*t/33); b = int(21+(60-21)*t/33) }
            else { t=p-66; r = int(251+(239-251)*t/34); g = int(146+(68-146)*t/34); b = int(60+(68-60)*t/34) }
            if (i <= f) printf "\033[38;2;%d;%d;%dm\xe2\x96\x93\033[0m", r, g, b
            else        printf "\033[38;2;75;82;95m\xe2\x96\x91\033[0m"
            if (gap && i < w) printf " "
        }
    }' /dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# RENDER
# ═══════════════════════════════════════════════════════════════════════════════

# ── HEADER (merged: branding + version + model + pwd + skills) ─────────────────
case "$MODE" in
    nano)
        hdr_fill=$((term_width - 10)); [ "$hdr_fill" -lt 1 ] && hdr_fill=1
        printf '%b' "${S6}── │${R} ${HDR}CC${R} ${S6}│ "
        printf '%*s' "$hdr_fill" '' | tr ' ' '─'
        printf '%b\n' "${R}"
        printf '%b\n' "${EV}v${cc_version}${R} ${EB}${model_name}${R} ${GD}${dir_name}${R} ${SK}S:${SKILLS_COUNT}${R} ${SK}H:${HOOKS_COUNT}${R}"
        ;;
    micro)
        hdr_fill=$((term_width - 19)); [ "$hdr_fill" -lt 1 ] && hdr_fill=1
        printf '%b' "${S6}── │${R} ${HDR}CLAUDE CODE${R} ${S6}│ "
        printf '%*s' "$hdr_fill" '' | tr ' ' '─'
        printf '%b\n' "${R}"
        printf '%b\n' "${S4}v${R}${EV}${cc_version}${R}  ${S6}│${R}  ${EB}${model_name}${R}  ${S6}│${R}  ${GD}${dir_name}${R}  ${S6}│${R}  ${SK}S:${SKILLS_COUNT}${R} ${SK}H:${HOOKS_COUNT}${R}"
        ;;
    mini)
        hdr_fill=$((term_width - 19)); [ "$hdr_fill" -lt 1 ] && hdr_fill=1
        printf '%b' "${S6}── │${R} ${HDR}CLAUDE CODE${R} ${S6}│ "
        printf '%*s' "$hdr_fill" '' | tr ' ' '─'
        printf '%b\n' "${R}"
        printf '%b\n' "${S4}v${R}${EV}${cc_version}${R}  ${S6}│${R}  ${EB}${model_name}${R}  ${S6}│${R}  ${GP}PWD:${R} ${GD}${dir_name}${R}  ${S6}│${R}  ${S4}Skills:${R}${SK}${SKILLS_COUNT}${R}  ${S4}Hooks:${R}${SK}${HOOKS_COUNT}${R}"
        ;;
    normal)
        hdr_fill=$((term_width - 19)); [ "$hdr_fill" -lt 1 ] && hdr_fill=1
        printf '%b' "${S6}── │${R} ${HDR}CLAUDE CODE${R} ${S6}│ "
        printf '%*s' "$hdr_fill" '' | tr ' ' '─'
        printf '%b\n' "${R}"
        printf '%b\n' "${S4}v${R}${EV}${cc_version}${R}  ${S6}│${R}  ${EB}${model_name}${R}  ${S6}│${R}  ${GP}PWD:${R} ${GD}${dir_name}${R}  ${S6}│${R}  ${S4}Skills:${R} ${SK}${SKILLS_COUNT}${R}  ${S6}│${R}  ${S4}Hooks:${R} ${SK}${HOOKS_COUNT}${R}"
        ;;
esac

# ── MCP ────────────────────────────────────────────────────────────────────────
case "$MODE" in
    nano)
        printf '%b\n' "${ML}MCP${R} ${MC}${MCP_COUNT}${R}"
        ;;
    micro)
        printf '%b' "${ML}MCP:${R}  ${MC}⬡ ${MCP_COUNT}${R}"
        [ -n "$MCP_NAMES" ] && printf '%b' "  ${S6}[${R}${MN}${MCP_NAMES}${R}${S6}]${R}"
        printf '\n'
        ;;
    mini|normal)
        printf '%b' "${ML}MCP:${R}  ${MC}⬡ ${MCP_COUNT} server$([ "$MCP_COUNT" -ne 1 ] && printf 's')${R}"
        [ -n "$MCP_NAMES" ] && printf '%b' "  ${S6}[${R}${MN}${MCP_NAMES}${R}${S6}]${R}"
        printf '\n'
        ;;
esac

print_divider

# ── CONTEXT ────────────────────────────────────────────────────────────────────
case "$MODE" in
    nano)
        printf '%b' "${CP}◉${R} "
        print_bar 5 "$context_pct"
        printf '%b\n' " ${PC}${context_pct}%${R}  ${S5}${time_str}${R}"
        ;;
    micro)
        printf '%b' "${CP}◉${R} "
        print_bar 6 "$context_pct"
        printf '%b\n' "  ${PC}${context_pct}%${R} ${S5}(${context_k}k)${R}  ${CA}⏱${R} ${S3}${time_str}${R}"
        ;;
    mini)
        printf '%b' "${CP}◉${R} ${CS}CTX:${R} "
        print_bar 8 "$context_pct"
        printf '%b' "  ${PC}${context_pct}%${R} ${S5}(${context_k}k/${max_k}k)${R}"
        printf '%b\n' "  ${CA}⏱${R} ${S3}${time_str}${R}  ${S5}${cost_str}${R}"
        ;;
    normal)
        printf '%b' "${CP}◉${R} ${CS}CONTEXT:${R} "
        print_bar 16 "$context_pct"
        printf '%b' "  ${BAR_LABEL_COLOR}${context_pct}%${R} ${S5}(${context_k}k/${max_k}k)${R}"
        printf '%b' "  ${S6}│${R}  ${CA}⏱${R} ${S3}${time_str}${R}"
        printf '%b' "  ${S6}│${R}  ${S5}${cost_str}${R}"
        [ -n "$velocity_str" ] && printf '%b' " ${S6}(${R}${S4}${velocity_str}${R}${S6})${R}"
        printf '\n'
        # Token breakdown — show system prompt cost vs conversation tokens
        printf '%b\n' "   ${S6}└─${R}  ${S5}sys:${R}${AM}~${baseline_k}k${R}  ${S5}conv:${R}${TK}${conversation_k}k${R}  ${S5}cache:${R}${CC_TOK}${cache_hit_pct}%${R}  ${S5}in:${R}${TK}${in_k}k${R}  ${S5}out:${R}${TK}${out_k}k${R}"
        ;;
esac

print_divider

# ── GIT (PWD removed — now in header) ─────────────────────────────────────────
if $GIT_AVAIL; then
    case "$MODE" in
        nano)
            printf '%b' "${GP}◈${R} ${GV}${branch}${R} "
            $git_clean && printf '%b' "${GC}✓${R}" || { [ "$total_modified" -gt 0 ] && printf '%b' "${GM}~${total_modified}${R}"; [ "$total_deleted" -gt 0 ] && printf '%b' " ${RO}-${total_deleted}${R}"; }
            [ "$git_diff_ins" -gt 0 ] || [ "$git_diff_del" -gt 0 ] && printf '%b' " ${EM}+${git_diff_ins}${R} ${RO}-${git_diff_del}${R}"
            [ -n "$SS" ] && printf ' %b' "$SS"
            printf '\n'
            ;;
        micro)
            printf '%b' "${GP}◈${R} ${GV}${branch}${R}"
            [ -n "$age_str" ] && printf '%b' "  ${AC}${age_str}${R}"
            printf '  '
            if $git_clean; then
                printf '%b' "${GC}✓${R}"
            else
                [ "$total_modified" -gt 0 ] && printf '%b' "${GM}~${total_modified}${R}"
                [ "$untracked"      -gt 0 ] && printf '%b' " ${GA}+${untracked}${R}"
                [ "$total_deleted"  -gt 0 ] && printf '%b' " ${RO}-${total_deleted}${R}"
            fi
            [ "$git_diff_ins" -gt 0 ] || [ "$git_diff_del" -gt 0 ] && printf '%b' "  ${EM}+${git_diff_ins}${R} ${RO}-${git_diff_del}${R}"
            [ -n "$SS" ] && printf '  %b' "$SS"
            printf '\n'
            ;;
        mini)
            printf '%b' "${GP}◈${R} ${GV}${branch}${R}"
            [ -n "$age_str" ] && printf '%b' "  ${S6}│${R}  ${AC}${age_str}${R}"
            [ -n "$SS"      ] && printf '%b' "  ${S6}│${R}  ${SS}"
            printf '%b' "  ${S6}│${R}  "
            if $git_clean; then
                printf '%b' "${GC}✓ clean${R}"
            else
                [ "$total_modified" -gt 0 ] && printf '%b' "${GM}~${total_modified}${R}"
                [ "$untracked"      -gt 0 ] && printf '%b' " ${GA}+${untracked}${R}"
                [ "$total_deleted"  -gt 0 ] && printf '%b' " ${RO}-${total_deleted}${R}"
            fi
            [ "$git_diff_ins" -gt 0 ] || [ "$git_diff_del" -gt 0 ] && printf '%b' "  ${S6}│${R}  ${EM}+${git_diff_ins}${R} ${RO}-${git_diff_del}${R}"
            printf '\n'
            ;;
        normal)
            printf '%b' "${GP}◈${R}  ${GP}Branch:${R} ${GV}${branch}${R}"
            [ -n "$age_str" ] && { [ "$age_str" = "now" ] && printf '%b' "  ${S6}│${R}  ${GP}Commit:${R} ${AC}${age_str}${R}" || printf '%b' "  ${S6}│${R}  ${GP}Commit:${R} ${AC}${age_str} ago${R}"; }
            [ "$stash_count" -gt 0 ] && printf '%b' "  ${S6}│${R}  ${GP}Stash:${R} ${GS}${stash_count}${R}"
            [ -n "$SS"             ] && printf '%b' "  ${S6}│${R}  ${SS}"
            printf '%b' "  ${S6}│${R}  "
            if $git_clean; then
                printf '%b' "${GC}✓ clean${R}"
            else
                printf '%b' "${GP}Files:${R}"
                [ "$total_modified" -gt 0 ] && printf '%b' " ${GM}~${total_modified}${R}"
                [ "$untracked"      -gt 0 ] && printf '%b' " ${GA}+${untracked}${R}"
                [ "$total_deleted"  -gt 0 ] && printf '%b' " ${RO}-${total_deleted}${R}"
            fi
            if [ "$git_diff_ins" -gt 0 ] || [ "$git_diff_del" -gt 0 ]; then
                printf '%b' "  ${S6}│${R}  ${GP}Lines:${R} ${EM}+${git_diff_ins}${R} ${RO}-${git_diff_del}${R}"
            fi
            if [ "${lines_added:-0}" -gt 0 ] || [ "${lines_removed:-0}" -gt 0 ]; then
                printf '%b' "  ${S6}│${R}  ${EM}+${lines_added}${R}${S6}/${R}${RO}-${lines_removed}${R}"
            fi
            printf '\n'
            ;;
    esac

    print_divider
fi

