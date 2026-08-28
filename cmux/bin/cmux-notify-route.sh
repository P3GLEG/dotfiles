#!/usr/bin/env bash
# cmux-notify-route.sh — fan cmux notifications out beyond the desktop.
#
# Wired up as notifications.command in cmux.json. cmux runs it with /bin/sh
# on every notification it raises and exports the notification's fields as
# CMUX_* environment variables.
#
# Verified on cmux 0.64.14, the variables are CMUX_NOTIFICATION_TITLE,
# CMUX_NOTIFICATION_SUBTITLE and CMUX_NOTIFICATION_BODY. The full CMUX_*
# environment is still logged on every call so a future build adding fields
# (workspace ref, event kind) shows up without guesswork:
#
#   tail -20 ~/.cache/cmux/notifications.log
#
# Set CMUX_NOTIFY_NTFY_TOPIC (or edit the push block) to route the important
# ones to your phone. Until you set a topic this only logs.
#
# It must stay fast and must never fail: cmux runs it inline per notification.

set -u

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cmux"
LOG="$LOG_DIR/notifications.log"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

TITLE="${CMUX_NOTIFICATION_TITLE:-}"
SUBTITLE="${CMUX_NOTIFICATION_SUBTITLE:-}"
BODY="${CMUX_NOTIFICATION_BODY:-}"

{
  printf '%s\t' "$(date '+%Y-%m-%dT%H:%M:%S')"
  # Drop every credential-bearing CMUX_* var, not just the password:
  # CMUX_SOCKET_CAPABILITY is a signed token that grants socket control.
  env | grep '^CMUX_' \
    | grep -vE '^CMUX_(SOCKET_PASSWORD|SOCKET_CAPABILITY|.*TOKEN|.*SECRET)=' \
    | tr '\n' '\t'
  printf '\n'
} >> "$LOG" 2>/dev/null

# Keep the log from growing without bound.
if [ "$(wc -l < "$LOG" 2>/dev/null || echo 0)" -gt 2000 ]; then
  tail -1000 "$LOG" > "$LOG.tmp" 2>/dev/null && mv -f "$LOG.tmp" "$LOG"
fi

# --- Push to phone -----------------------------------------------------------
# Opt in by exporting CMUX_NOTIFY_NTFY_TOPIC in your shell profile, e.g.
#   export CMUX_NOTIFY_NTFY_TOPIC=pegleg-agents
# Backgrounded and hard-timeboxed so a slow network never stalls cmux.
if [ -n "${CMUX_NOTIFY_NTFY_TOPIC:-}" ]; then
  ( curl -fsS --max-time 5 \
      -H "Title: ${TITLE:-cmux}" \
      -H "Tags: robot" \
      -d "${SUBTITLE:+$SUBTITLE — }${BODY:-agent event}" \
      "https://ntfy.sh/${CMUX_NOTIFY_NTFY_TOPIC}" >/dev/null 2>&1 & ) 
fi

exit 0
