# cmux config for many concurrent Claude Code agents

Verified against **cmux 0.64.22 (102)** and Claude Code 2.1.250 on macOS.

The design bet: **the sidebar is the "all agents at once" view.** A live grid
of terminals stops being readable past four to six panes, so panes are for
looking at one agent and the sidebar is for knowing the state of all of them.
Everything here exists to make a sidebar row answer "what is this agent doing
and does it need me" without opening it.

## Files

| File | Installs to | Purpose |
|---|---|---|
| `cmux.json` | `~/.config/cmux/cmux.json` | Declarative config: sidebar dashboard, notification policy, hibernation, workspace groups |
| `hooks/cmux-agent-status.sh` | `~/.claude/hooks/` | Claude Code lifecycle hook: sidebar log feed, subagent counter, blocked pill, heartbeat |
| `bin/cmux-stall-watch.sh` | `~/.claude/hooks/` | Watchdog for agents that die without firing `Stop` |
| `bin/cmux-notify-route.sh` | `~/.claude/hooks/` | `notifications.command` target: logs every notification, optionally pushes to ntfy |
| `bin/install-claude-hooks.py` | — | Idempotently merges the hook entries into `~/.claude/settings.json` |
| `bin/new-task.sh` | `~/.config/cmux/` | Repo picker → git worktree → named workspace with Claude running. Bound to the **+** button via `ui.newWorkspace.action` |
| `repo-badges.tsv` | `~/.config/cmux/` | Repo-name glob → emoji + colour, painted as the `repo` pill and the workspace colour |
| `rules/cmux-workspace-hygiene.md` | `~/.claude/rules/` | Field-ownership table and the don't-pile-tabs rule, loaded as a global Claude rule |
| `launchd/com.pegleg.cmux-stall-watch.plist` | `~/Library/LaunchAgents/` | Runs the watchdog at login |

## Where terminal appearance actually comes from

Three files, in increasing precedence. This trips people up, because the
in-app theme picker silently creates the highest-precedence one:

| File | In git? | Wins? |
|---|---|---|
| `~/.config/ghostty/config` (symlink of `ghostty/config` here) | yes | base |
| `~/Library/Application Support/com.cmuxterm.app/config.ghostty` | **no** | **overrides the above** |
| `cmux.json` | yes | cmux chrome only (sidebar, rails, pills) -- not terminal colours |

`cmux themes set` writes to the middle one. Because it is outside the repo,
a theme set through the picker does not follow you to a new machine -- the
classic "why does it look different over here". Keep font and theme in
`ghostty/config` and run `cmux themes clear` to hand control back; `cmux
themes` prints the effective `Source:` so you can always tell which file won.

## The model

**Repo → group; task → workspace; parallel views of one task → panes;
alternates within one view → tabs.** Every sidebar feature listed below
renders at *workspace* granularity, so several tasks sharing one workspace
makes all of it inert. That is the failure this config exists to prevent.

Pill priorities, highest first: `stall` 120 · `agent` 100 · `task` 90 ·
`repo` 70 · `turn` 50 · `subagents` 40.

The `task` pill is written **once per session**, on the first substantive
prompt, and is never overwritten by follow-ups like "yes" or "continue" —
that stickiness is the whole point. Harness-injected text (`<task-notification>`,
`[SYSTEM …`) is filtered out so it can never claim the label.

`install.sh` section 7 wires all of it up. Set `WITH_CMUX_WATCHDOG=0` to skip
the launchd agent.

## Division of labour with cmux's built-in integration

`automation.claudeCodeIntegration` is on, and cmux already owns:

- the `claude_code` status pill (Running / idle)
- the sidebar activity spinner
- workspace titles derived from the conversation
- turn-complete and permission-prompt desktop notifications
- session → surface mapping in `~/.cmuxterm/claude-hook-sessions.json`

So `cmux-agent-status.sh` deliberately does **not** re-notify on `Stop`, does
not rename workspaces, and does not touch the `claude_code` status key. It
adds only what cmux leaves on the table:

| Key / feature | Event | Result |
|---|---|---|
| sidebar log feed | all | `▶ task` / `⏸ blocked` / `✔ done` timeline per workspace |
| `agent` pill | `Notification` | orange pill carrying the actual blocking message, priority 100 |
| `subagents` pill | `SubagentStop` | purple `N done` counter for parallel Task subagents |
| heartbeat file | `PostToolUse` | `~/.claude/agent-state/<surface-uuid>.json`, mtime bumped per tool call |
| `stall` pill | watchdog | red pill + one notification when a running agent goes quiet |

`PostToolUse` is the hot path — it fires on every tool call, so it takes the
event name as `$1` (no JSON parsing) and does nothing but `touch` the state
file. No socket round trip.

## Stall detection

The failure this catches: an agent stops mid-task with no error and no `Stop`
hook. Nothing in cmux fires, so the workspace sits there looking busy.

The watchdog reads heartbeat files rather than scraping `read-screen`, because
terminal output is a redraw stream and file mtimes are not. An agent is stale
when `state == "running"` and its file has not been touched for
`CMUX_STALL_THRESHOLD` (default 600s). Only `running` counts: `blocked` and
`done` are resting states, and agent hibernation only ever targets *idle*
agents, so a hibernated agent can never be mistaken for a stalled one.

It flags and notifies once. It never kills anything — recovery is yours:

```sh
cmux-stall-watch.sh --once      # report, no daemon
cmux-stall-watch.sh --clear     # drop every stall pill
cmux send-key --workspace <ws> ctrl+c   # if you do want to stop a runaway
```

## Push to phone

`notifications.command` runs `cmux-notify-route.sh` on every notification.
cmux exports `CMUX_NOTIFICATION_TITLE`, `CMUX_NOTIFICATION_SUBTITLE`, and
`CMUX_NOTIFICATION_BODY` (verified on 0.64.14). Turn on push with:

```sh
export CMUX_NOTIFY_NTFY_TOPIC=some-unguessable-topic
```

The topic is a public URL on ntfy.sh — anyone who guesses it reads your agent
notifications, so make it long and random, or self-host.

## Daily driving

| Keys | Does |
|---|---|
| `Cmd+1`–`Cmd+9` | jump to workspace N |
| `Cmd+Shift+U` | jump to the most recent unread agent |
| `Cmd+I` | notification panel |
| `Cmd+P` | workspace switcher |
| `Cmd+Shift+P` | command palette (searches all agents' output — `commandPaletteSearchesAllSurfaces`) |
| `Cmd+Shift+Enter` | zoom the focused pane |
| `Ctrl+Cmd+C` / `Ctrl+Cmd+T` / `Ctrl+Cmd+O` | canvas / tidy into grid / overview zoom |

`app.reorderOnNotification` floats whatever needs attention to the top of the
sidebar, so the top rows are the queue.

```sh
cmux workspace list --json          # every agent, scriptable
cmux read-screen --workspace ws:3   # peek without stealing focus
cmux send --workspace ws:3 "..."    # answer an agent from anywhere
cmux sidebar-state --workspace ws:3 # cwd, branch, ports, status, progress, logs
```

## Applying changes

```sh
cmux config doctor      # validate JSONC + report which keys are file-managed
cmux reload-config      # applies cmux.json AND ~/.config/ghostty/config, no restart
```

Anything set in `cmux.json` overrides the GUI Settings pane and the pane shows
it as file-managed. Delete a key to hand control back to the GUI.

## Notes on the source research

Checked against this build rather than taken on faith:

- The socket is `~/.local/state/cmux/cmux-501.sock`, **not** `/tmp/cmux.sock`.
  Hook scripts that guard on `[ -S /tmp/cmux.sock ]` silently no-op forever.
  These scripts guard on `$CMUX_WORKSPACE_ID` instead, which is both correct
  and free.
- `wait-for -S`, `set-hook`, `pipe-pane`, `set-buffer`/`paste-buffer`,
  `display-message`, `resize-pane -L/-R/-U/-D`, `read-screen`, `tree`, and
  `surface-health` **do** exist in 0.64.14, contrary to the "unverified
  community convention" framing.
- `spawn` and `resize-pane -Z` do not exist. Use `cmux workspace create` and
  `Cmd+Shift+Enter`.
- `cmux hooks setup` covers codex, opencode, gemini, amp, cursor and friends
  but **not** Claude Code — cmux injects those hooks through its own Claude
  wrapper, which is why this repo ships a hook script instead.

## Not done yet

- **Git worktree per agent.** cmux does not isolate file changes; two agents in
  the same repo will collide. This is the largest remaining gap.
- **A JSONL-reading TUI** once more than ~6 agents run routinely.
