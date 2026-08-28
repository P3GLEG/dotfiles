#!/usr/bin/env bash
# cmux-stall-watch.sh — flag Claude Code agents that died quietly.
#
# The failure mode this catches: an agent stops mid-task with no error, no
# Stop hook, no Notification. Nothing in cmux fires, so the workspace just
# sits there looking busy. Screen-scraping read-screen is brittle; this reads
# the heartbeat files that cmux-agent-status.sh writes instead.
#
# A heartbeat is stale when state=="running" and the state file has not been
# touched (PostToolUse bumps its mtime on every tool call) for longer than
# the threshold. On a stale agent it paints a "stall" pill on that workspace,
# logs an error to its sidebar feed, and fires one desktop notification.
# Recovery is left to you on purpose — it never kills anything.
#
# Usage:
#   cmux-stall-watch.sh              # daemon loop (this is what launchd runs)
#   cmux-stall-watch.sh --once       # single sweep, prints a report
#   cmux-stall-watch.sh --clear      # drop every stall pill and reset flags
#
# Env:
#   CMUX_STALL_THRESHOLD  seconds without a tool call before flagging (default 600)
#   CMUX_STALL_INTERVAL   seconds between sweeps (default 60)

set -uo pipefail

THRESHOLD="${CMUX_STALL_THRESHOLD:-600}"
INTERVAL="${CMUX_STALL_INTERVAL:-60}"
STATE_DIR="${CLAUDE_AGENT_STATE_DIR:-$HOME/.claude/agent-state}"

CMUX="${CMUX_BIN:-/Applications/cmux.app/Contents/Resources/bin/cmux}"
if [ ! -x "$CMUX" ]; then
  CMUX="$(command -v cmux 2>/dev/null || true)"
fi
[ -n "$CMUX" ] && [ -x "$CMUX" ] || { echo "cmux CLI not found" >&2; exit 1; }

JQ="$(command -v jq 2>/dev/null || true)"
[ -n "$JQ" ] || { echo "jq not found" >&2; exit 1; }

mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }

sweep() {
  local verbose="${1:-}" now f state ws task age notified sid live
  now="$(date +%s)"

  # Live surface UUIDs, fetched once per sweep. A state file is named after
  # its surface, so a file whose surface is gone is an orphan from a pane
  # closed without SessionEnd. Those used to linger for a full 24h while
  # painting a priority-120 "stalled" pill on a workspace that had moved on --
  # a confident lie on the one signal the whole sidebar design rests on.
  live="$("$CMUX" tree --all --id-format uuids 2>/dev/null | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | tr '\n' ' ')"

  shopt -s nullglob
  for f in "$STATE_DIR"/*.json; do
    state="$("$JQ" -r '.state // ""' "$f" 2>/dev/null || echo '')"
    ws="$("$JQ" -r '.workspace // ""' "$f" 2>/dev/null || echo '')"
    task="$("$JQ" -r '.task // ""' "$f" 2>/dev/null || echo '')"
    notified="$("$JQ" -r '.notified // false' "$f" 2>/dev/null || echo false)"
    age=$(( now - $(mtime "$f") ))

    # Orphan: the surface this file belongs to no longer exists. Clear any
    # pill it left behind, then drop it. Only trust the live list if we
    # actually got one -- an empty result means cmux was unreachable, and
    # deleting every state file on a transient socket error would be worse
    # than keeping them.
    sid="$(basename "$f" .json)"
    if [ -n "$live" ] && [ "${live#*"$sid"}" = "$live" ]; then
      [ -n "$ws" ] && "$CMUX" clear-status stall --workspace "$ws" >/dev/null 2>&1 || true
      rm -f "$f"
      [ -n "$verbose" ] && echo "orphan  $sid (surface gone) -> cleared and removed"
      continue
    fi

    # Last-resort reap for anything the surface check somehow misses.
    if [ "$age" -gt 86400 ]; then rm -f "$f"; continue; fi

    # Only a mid-turn agent can stall. done/blocked are both resting states:
    # "blocked" is already surfaced by its own pill and by cmux's permission
    # notification, and hibernation only ever touches idle agents, so a
    # hibernated agent cannot be mistaken for a stalled one.
    if [ "$state" != "running" ]; then
      [ -n "$verbose" ] && printf '  ok      %-8s %4ss  %s\n' "$state" "$age" "$task"
      continue
    fi

    if [ "$age" -lt "$THRESHOLD" ]; then
      [ -n "$verbose" ] && printf '  ok      running  %4ss  %s\n' "$age" "$task"
      continue
    fi

    [ -n "$verbose" ] && printf '  STALLED running  %4ss  %s\n' "$age" "$task"

    if [ -n "$ws" ]; then
      "$CMUX" set-status stall "stalled ${age}s" --workspace "$ws" \
        --icon "clock.badge.exclamationmark.fill" --color "#C0392B" --priority 120 \
        >/dev/null 2>&1 || true

      if [ "$notified" != "true" ]; then
        "$CMUX" log --level error --source watchdog --workspace "$ws" \
          -- "no tool activity for ${age}s — agent may have stalled" >/dev/null 2>&1 || true
        "$CMUX" notify --title "Agent stalled" \
          --subtitle "${task:-no task recorded}" \
          --body "No tool activity for ${age}s." --workspace "$ws" >/dev/null 2>&1 || true
        tmp="$f.$$"
        "$JQ" '.notified = true' "$f" > "$tmp" 2>/dev/null && mv -f "$tmp" "$f" || rm -f "$tmp"
        # .notified was rewritten, which bumps mtime; re-stamp so the age
        # reported next sweep still reflects the last real tool call.
        touch -t "$(date -r $(( now - age )) +%Y%m%d%H%M.%S)" "$f" 2>/dev/null || true
      fi
    fi
  done
  shopt -u nullglob
}

clear_all() {
  local f ws tmp
  shopt -s nullglob
  for f in "$STATE_DIR"/*.json; do
    ws="$("$JQ" -r '.workspace // ""' "$f" 2>/dev/null || echo '')"
    [ -n "$ws" ] && "$CMUX" clear-status stall --workspace "$ws" >/dev/null 2>&1 || true
    tmp="$f.$$"
    "$JQ" '.notified = false' "$f" > "$tmp" 2>/dev/null && mv -f "$tmp" "$f" || rm -f "$tmp"
  done
  shopt -u nullglob
  echo "cleared stall pills"
}

case "${1:-}" in
  --once)
    echo "sweep: threshold=${THRESHOLD}s state_dir=$STATE_DIR"
    sweep verbose
    ;;
  --clear)
    clear_all
    ;;
  *)
    while :; do
      sweep
      sleep "$INTERVAL"
    done
    ;;
esac
