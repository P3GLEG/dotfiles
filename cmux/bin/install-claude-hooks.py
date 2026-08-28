#!/usr/bin/env python3
"""Merge the cmux agent-status hooks into ~/.claude/settings.json.

~/.claude/settings.json holds personal state (permissions, model, MCP servers)
so it is deliberately not a symlinked dotfile. This merges our hook entries in
place instead, idempotently: re-running replaces our own entries and leaves
every other hook untouched.

  install-claude-hooks.py            # install / update
  install-claude-hooks.py --remove   # take them back out
"""
from __future__ import annotations

import json
import shutil
import sys
import time
from pathlib import Path

SETTINGS = Path.home() / ".claude" / "settings.json"
HOOK = "~/.claude/hooks/cmux-agent-status.sh"

# event -> (matcher, timeout). PostToolUse is the hot path, so it gets a tight
# timeout; it only touches a file.
EVENTS = {
    "SessionStart":     ("", 5),
    "UserPromptSubmit": ("", 5),
    "PostToolUse":      ("*", 2),
    "Notification":     ("", 5),
    "SubagentStop":     ("", 5),
    "Stop":             ("", 5),
    "PreCompact":       ("", 5),
    "SessionEnd":       ("", 5),
}

# Entries we consider ours and will replace or drop. Includes the older
# cmux-notify.sh hook, which guarded on /tmp/cmux.sock — a path cmux has not
# used in this build (the socket lives in ~/.local/state/cmux/), so it has
# been silently no-oping on every Stop.
OWNED = ("cmux-agent-status.sh", "cmux-notify.sh")


def is_ours(entry: dict) -> bool:
    cmd = entry.get("command", "")
    return any(marker in cmd for marker in OWNED)


def main() -> int:
    remove = "--remove" in sys.argv

    if not SETTINGS.exists():
        print(f"{SETTINGS} not found", file=sys.stderr)
        return 1

    raw = SETTINGS.read_text()
    settings = json.loads(raw)

    backup = SETTINGS.with_suffix(f".json.bak.{time.strftime('%Y%m%d%H%M%S')}")
    shutil.copy2(SETTINGS, backup)

    hooks = settings.setdefault("hooks", {})

    # Strip every entry we own, from every event, before re-adding.
    for event in list(hooks):
        groups = []
        for group in hooks.get(event) or []:
            kept = [h for h in group.get("hooks", []) if not is_ours(h)]
            if kept:
                group["hooks"] = kept
                groups.append(group)
        if groups:
            hooks[event] = groups
        else:
            del hooks[event]

    if not remove:
        for event, (matcher, timeout) in EVENTS.items():
            entry = {"type": "command", "command": f"{HOOK} {event}", "timeout": timeout}
            group: dict = {"hooks": [entry]}
            if matcher:
                group["matcher"] = matcher
            hooks.setdefault(event, []).append(group)

    if not hooks:
        settings.pop("hooks", None)

    SETTINGS.write_text(json.dumps(settings, indent=2) + "\n")
    action = "Removed" if remove else "Installed"
    print(f"{action} cmux agent-status hooks in {SETTINGS}")
    print(f"Backup: {backup}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
