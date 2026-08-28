#!/usr/bin/env bash
# cmux-agent-status.sh — paint Claude Code lifecycle into the cmux sidebar.
#
# Invoked from ~/.claude/settings.json with the event name as $1 so the hot
# path (PostToolUse) never has to parse JSON:
#
#   "command": "~/.claude/hooks/cmux-agent-status.sh PostToolUse"
#
# Division of labour with cmux's own Claude Code integration
# (automation.claudeCodeIntegration), which already owns the "claude_code"
# status pill, the active/idle spinner, workspace titles, and turn-complete
# desktop notifications. This script deliberately does NOT duplicate any of
# those. It adds:
#   * a "task" pill holding the task label -- STICKY for the whole session.
#     This is the row's answer to "what is this agent doing". It is written
#     once, on the first substantive prompt, and deliberately NOT overwritten
#     by follow-ups like "yes"/"continue". It is a pill rather than a log line
#     because the log is a scrolling tail: subagent chatter used to flush the
#     label out of view within minutes, which is the whole bug this fixes.
#   * a "turn" pill for turn-complete. NOT a "done" pill -- Stop means the
#     turn ended, not that the task is finished; claiming otherwise every few
#     minutes trains you to distrust the row.
#   * a sidebar log feed of session milestones
#   * a "subagents" pill counting completed Task subagents
#   * an "agent" pill for the blocked state, with the message text
#   * a "repo" pill: emoji + repo name, plus the workspace color, both looked
#     up from ~/.config/cmux/repo-badges.tsv by folder. This is what tells you
#     at a glance WHICH project a row belongs to -- including for plain shells
#     that have no agent and no task label.
#   * a heartbeat file that cmux-stall-watch.sh reads to catch silent stalls
#
# Pill priorities (higher sorts first):
#   stall 120 > agent 100 > task 90 > repo 70 > turn 50 > subagents 40
#
# Exits 0 silently whenever it is not running inside cmux.

set -uo pipefail

EVENT="${1:-}"
[ -n "$EVENT" ] || exit 0

# Not inside a cmux terminal (plain shell, CI, SSH) -> nothing to paint.
[ -n "${CMUX_WORKSPACE_ID:-}" ] || exit 0
[ -n "${CMUX_SURFACE_ID:-}" ] || exit 0

CMUX="${CMUX_BIN:-/Applications/cmux.app/Contents/Resources/bin/cmux}"
if [ ! -x "$CMUX" ]; then
  CMUX="$(command -v cmux 2>/dev/null || true)"
fi
[ -n "$CMUX" ] && [ -x "$CMUX" ] || exit 0

STATE_DIR="${CLAUDE_AGENT_STATE_DIR:-$HOME/.claude/agent-state}"
STATE_FILE="$STATE_DIR/$CMUX_SURFACE_ID.json"

# ---------------------------------------------------------------------------
# Hot path: PostToolUse fires on every single tool call. All it does is bump
# the heartbeat mtime — no JSON parsing, no socket round trip.
# ---------------------------------------------------------------------------
if [ "$EVENT" = "PostToolUse" ]; then
  [ -f "$STATE_FILE" ] && touch "$STATE_FILE"
  exit 0
fi

mkdir -p "$STATE_DIR"

JQ="$(command -v jq 2>/dev/null || true)"
PAYLOAD=""
if [ ! -t 0 ]; then
  PAYLOAD="$(cat 2>/dev/null || true)"
fi

# field <jq-path> — pull one value out of the hook payload, "" if absent.
field() {
  [ -n "$JQ" ] && [ -n "$PAYLOAD" ] || { printf ''; return 0; }
  printf '%s' "$PAYLOAD" | "$JQ" -r "$1 // \"\" | tostring | gsub(\"[\\n\\r\\t]\";\" \")" 2>/dev/null || printf ''
}

# clip <text> <max> — truncate for a sidebar row.
clip() {
  local s="$1" n="$2"
  s="${s#"${s%%[![:space:]]*}"}"   # trim leading whitespace
  s="${s#-}"; s="${s#-}"           # never let a value start with - and look like a flag
  if [ "${#s}" -gt "$n" ]; then printf '%s…' "${s:0:$n}"; else printf '%s' "$s"; fi
}

# write_state <state> [task] — atomic heartbeat/state write for the watchdog.
write_state() {
  local st="$1" task="${2:-}" tmp
  local subs=0
  if [ -f "$STATE_FILE" ] && [ -n "$JQ" ]; then
    subs="$("$JQ" -r '.subagents // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
    [ -z "$task" ] && task="$("$JQ" -r '.task // ""' "$STATE_FILE" 2>/dev/null || echo '')"
  fi
  tmp="$STATE_FILE.$$"
  # Build with jq, never printf. A hand-rolled string only stripped double
  # quotes, so a prompt containing a backslash -- "use \d+ regex", a Windows
  # path -- produced INVALID JSON or silently corrupted the value (\t became a
  # tab). prev_task then failed to parse and the sticky task label quietly
  # stopped being sticky: precisely the bug this script exists to prevent.
  if [ -n "$JQ" ]; then
    "$JQ" -n \
      --arg state "$st" --arg workspace "$CMUX_WORKSPACE_ID" \
      --arg surface "$CMUX_SURFACE_ID" --arg session "$SESSION" \
      --arg cwd "$PWD" --arg task "$task" \
      --argjson subagents "${subs:-0}" --argjson ts "$(date +%s)" \
      '{state:$state,workspace:$workspace,surface:$surface,session:$session,cwd:$cwd,task:$task,subagents:$subagents,ts:$ts,notified:false}' \
      > "$tmp" 2>/dev/null && mv -f "$tmp" "$STATE_FILE" || rm -f "$tmp"
  else
    # jq absent: fall back, but strip anything that could break the JSON.
    local safe_task safe_cwd
    safe_task="$(printf '%s' "$task" | tr -d '\\"')"
    safe_cwd="$(printf '%s' "$PWD" | tr -d '\\"')"
    printf '{"state":"%s","workspace":"%s","surface":"%s","session":"%s","cwd":"%s","task":"%s","subagents":%s,"ts":%s,"notified":false}\n' \
      "$st" "$CMUX_WORKSPACE_ID" "$CMUX_SURFACE_ID" "$SESSION" "$safe_cwd" "$safe_task" "${subs:-0}" "$(date +%s)" \
      > "$tmp" && mv -f "$tmp" "$STATE_FILE"
  fi
}

# The cmux CLI already defaults --workspace/--surface to $CMUX_WORKSPACE_ID /
# $CMUX_SURFACE_ID, which the hook inherits, so no target flags are needed.
cx() { "$CMUX" "$@" >/dev/null 2>&1 || true; }

# prev_task — the task already recorded for THIS session, or "" if none.
# Scoping to the session id is what makes the label reset on a new session
# while surviving every follow-up prompt within one.
prev_task() {
  [ -f "$STATE_FILE" ] && [ -n "$JQ" ] || { printf ''; return 0; }
  local ps
  ps="$("$JQ" -r '.session // ""' "$STATE_FILE" 2>/dev/null || printf '')"
  [ "$ps" = "$SESSION" ] || { printf ''; return 0; }
  "$JQ" -r '.task // ""' "$STATE_FILE" 2>/dev/null || printf ''
}

# is_real_prompt <text> — reject anything that is not a human ask.
# UserPromptSubmit also fires for harness-injected content: background task
# notifications, system reminders, hook feedback. Those are useless as a
# label, and with write-once semantics a junk first "prompt" would stick for
# the entire session -- so they must never claim it.
is_real_prompt() {
  case "$1" in
    '<'*|'[SYSTEM'*|'[Cross-session'*|'[harness'*|'Caveat:'*) return 1 ;;
  esac
  return 0
}

# repo_name — the PROJECT this pane belongs to, not the directory it sits in.
# For a worktree, --show-toplevel returns the worktree dir (the task slug),
# so resolve through --git-common-dir, which always points at the main repo.
repo_name() {
  local common
  common="$(git rev-parse --git-common-dir 2>/dev/null)" || { basename "$PWD"; return; }
  case "$common" in
    /*) : ;;
    *) common="$PWD/$common" ;;
  esac
  basename "$(dirname "$(cd "$common" 2>/dev/null && pwd -P || printf '%s' "$common")")"
}

# paint_repo — emoji + color for the folder, from repo-badges.tsv. First
# glob match wins. Silently does nothing if the map is missing.
paint_repo() {
  local map="${CMUX_REPO_BADGES:-$HOME/.config/cmux/repo-badges.tsv}"
  [ -f "$map" ] || return 0
  local name emoji color line pat e c
  name="$(repo_name)"
  [ -n "$name" ] || return 0
  while IFS=$'\t' read -r pat e c; do
    case "$pat" in ''|'#'*) continue ;; esac
    # shellcheck disable=SC2254
    case "$name" in
      $pat) emoji="$e"; color="$c"; break ;;
    esac
  done < "$map"
  [ -n "${emoji:-}" ] || return 0
  cx set-status repo "$emoji $name" --icon folder.fill --color "${color:-#1A5276}" --priority 70
  [ -n "${color:-}" ] && cx workspace-action --action set-color --color "$color"
}

# paint_task <label> — the sticky "what is this agent doing" pill.
paint_task() {
  [ -n "$1" ] || return 0
  cx set-status task "$1" --icon text.bubble.fill --color "#4C8DFF" --priority 90
}

SESSION="$(field '.session_id')"

case "$EVENT" in

  SessionStart)
    SRC="$(field '.source')"
    # A resume/compact keeps the same session id, so the task label survives.
    # A genuinely new session has a new id, so prev_task returns "" and the
    # pill is cleared, ready for the first substantive prompt.
    PREV="$(prev_task)"
    # write_state preserves the existing .task when handed an empty string,
    # which would resurrect the PREVIOUS session's label here. A genuinely new
    # session must start clean, so drop the file outright -- that also resets
    # the subagent counter, which should never carry across sessions.
    [ -n "$PREV" ] || rm -f "$STATE_FILE"
    write_state running "$PREV"
    cx clear-status stall
    cx clear-status turn
    if [ -n "$PREV" ]; then paint_task "$PREV"; else cx clear-status task; fi
    paint_repo
    cx log --level info --source claude -- "session start${SRC:+ ($SRC)}"
    ;;

  UserPromptSubmit)
    NEW="$(clip "$(field '.prompt')" 60)"
    TASK="$(prev_task)"
    # Claim the label only on the first SUBSTANTIVE prompt of the session.
    # Short follow-ups ("yes", "go on", "continue") must never overwrite it --
    # that is what made the label useless. 12 chars is the cut.
    if [ -z "$TASK" ] && [ "${#NEW}" -ge 12 ] && is_real_prompt "$NEW"; then TASK="$NEW"; fi
    write_state running "$TASK"
    cx clear-status agent
    cx clear-status stall
    cx clear-status turn
    paint_task "$TASK"
    cx log --level progress --source claude -- "▶ ${NEW:-new turn}"
    ;;

  Notification)
    MSG="$(clip "$(field '.message')" 60)"
    NTYPE="$(field '.notification_type')"
    # Don't paint an alarm pill for benign events. auth_success is not a
    # request for your attention, and a false needs-input signal is worse
    # than none -- the triage loop depends on this pill meaning one thing.
    case "$NTYPE" in
      auth_success)
        cx log --level info --source claude -- "auth ok"
        ;;
      *)
        write_state blocked
        cx clear-status turn
        cx set-status agent "${MSG:-needs input}" \
          --icon exclamationmark.triangle.fill --color "#FF9500" --priority 100
        cx log --level warning --source claude -- "⏸ ${MSG:-needs input}"
        ;;
    esac
    ;;

  SubagentStop)
    N=1
    if [ -f "$STATE_FILE" ] && [ -n "$JQ" ]; then
      N=$(( $("$JQ" -r '.subagents // 0' "$STATE_FILE" 2>/dev/null || echo 0) + 1 ))
      tmp="$STATE_FILE.$$"
      "$JQ" --argjson n "$N" '.subagents = $n | .ts = (now|floor)' "$STATE_FILE" > "$tmp" 2>/dev/null \
        && mv -f "$tmp" "$STATE_FILE" || rm -f "$tmp"
    fi
    # The pill already carries the count. The per-subagent log line is what
    # used to flush the task label out of the visible log tail -- a
    # subagent-heavy turn could bury it within seconds. Pill only.
    # Cap the display: "114 done" is noise. The exact count lives in the
    # state file for the watchdog; the row only needs "a lot" vs "a few".
    if [ "$N" -gt 9 ]; then LBL="9+ done"; else LBL="$N done"; fi
    cx set-status subagents "$LBL" --icon person.2.fill --color "#7A4FD8" --priority 40
    ;;

  Stop)
    LAST="$(clip "$(field '.last_assistant_message')" 70)"
    write_state done
    cx clear-status agent
    cx clear-status stall
    cx clear-progress
    # Separate key, and deliberately worded as "idle", not "done". The task
    # pill stays untouched so the row still says what this agent is FOR.
    cx set-status turn "idle" --icon pause.circle --color "#8E8E93" --priority 50
    cx log --level success --source claude -- "✔ ${LAST:-turn complete}"
    ;;

  PreCompact)
    cx log --level info --source claude -- "compacting context"
    ;;

  SessionEnd)
    cx clear-status agent
    cx clear-status subagents
    cx clear-status stall
    cx clear-status task
    cx clear-status turn
    cx clear-progress
    cx log --level info --source claude -- "session end"
    rm -f "$STATE_FILE"
    ;;

esac

exit 0
