# cmux workspace hygiene

Applies when running inside cmux (`$CMUX_WORKSPACE_ID` is set).

The sidebar is the user's dashboard for many concurrent agents. Every row
has to answer "what is this agent doing" without being opened. The tooling
makes one-workspace-per-task possible; these habits are what make it happen.

## Don't pile unrelated work into one workspace

If the user gives you a task unrelated to this workspace's current one, do
**not** open a tab here. Say so, and offer to spawn a proper workspace:

```bash
~/.config/cmux/new-task.sh          # repo picker -> worktree -> named workspace
```

or directly:

```bash
cmux workspace create --name "<task in 4-6 words>" --cwd <repo> \
  --command claude --focus true
```

A workspace holding eight unrelated tasks makes every sidebar feature
useless, because all of them render at workspace granularity.

## Keep the row honest

```bash
cmux rename-workspace "fix token refresh race"    # 4-6 words, when the task shifts
cmux workspace-action --action set-color --color Amber
cmux set-status <key> <value> --icon hammer --priority 80
```

Field ownership — respect it, or fields will fight each other:

| Field | Owner | Rule |
|---|---|---|
| name | `workspaceAutoNaming` | manual rename wins permanently; rename when the topic really changes |
| description | spawn-time | written once as `<repo> · <branch>`; **never overwrite it** |
| `task` pill | `cmux-agent-status.sh` | written once per session, on the first substantive prompt |
| `turn` pill | `cmux-agent-status.sh` | turn-complete only |
| status lane | cmux | auto-inferred; **read-only** |

Use a private key for any `set-status` you add (`build`, `tests`). Never
write to `claude_code`, `subagents`, `agent`, `task`, `turn`, or `stall` —
those are owned by cmux or by the status hook.

## Don't touch

- **`cmux todo`** — that checklist belongs to the user. Don't add, edit,
  complete, or replace items unless explicitly asked.
- **`cmux workspace status set`** — the lane is inferred from live signals.
  Don't pin it.
- **`cmux notify`** — cmux's Claude wrapper already raises turn-complete
  notifications. Calling it from a Stop hook produces duplicate alerts.
