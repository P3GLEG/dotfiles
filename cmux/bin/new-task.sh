#!/usr/bin/env bash
# new-task.sh — one cmux workspace per TASK, in its own git worktree.
#
# Pick a repo, name the task, and get:
#   * a worktree at ~/workspace/.worktrees/<repo>/<slug>
#   * a branch  task/<slug>, based on the repo's real default branch
#   * a cmux workspace named after the task, with Claude already running
#
# Why not just `claude --worktree`? That is a real feature and it works, but
# it puts worktrees at <repo>/.claude/worktrees/<name> and names branches
# worktree-<name>. This wrapper exists only to place them under one prunable
# root and to create the named cmux workspace. Everything else defers to git.
#
# Wire-up (cmux.json):
#   "actions": { "task.new": { "type": "command", "title": "New Task Workspace",
#     "command": "bash -lc '~/.config/cmux/new-task.sh'" } }
# cmux runs commands through a NON-interactive shell that never reads
# ~/.zshrc, hence the `bash -lc`.

set -uo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/workspace}"
WT_ROOT="${WT_ROOT:-$HOME/workspace/.worktrees}"
CMUX="${CMUX_BUNDLED_CLI_PATH:-/Applications/cmux.app/Contents/Resources/bin/cmux}"
[ -x "$CMUX" ] || CMUX="$(command -v cmux 2>/dev/null || true)"

die() { printf '\n\033[31merror:\033[0m %s\n' "$*" >&2; printf 'press enter to close…'; read -r _; exit 1; }

[ -n "$CMUX" ] && [ -x "$CMUX" ] || die "cmux CLI not found"
command -v git >/dev/null || die "git not found"

# --- 1. pick a repo -------------------------------------------------------
# Exclude the worktree root and any nested .claude/worktrees, so worktrees
# never show up as spawnable repos. Depth 2 = direct children of the
# workspace root; raise REPO_DEPTH to reach nested clones, at the cost of
# pulling in vendored/research checkouts.
# `mapfile` is bash 4+; macOS ships bash 3.2, so read the list the portable way.
REPO_DEPTH="${REPO_DEPTH:-2}"
REPOS=()
while IFS= read -r line; do
  [ -n "$line" ] && REPOS+=("$line")
done < <(
  find "$WORKSPACE_ROOT" -mindepth 2 -maxdepth "$REPO_DEPTH" -name .git -print 2>/dev/null \
    | sed 's#/\.git$##' \
    | grep -v -e '/\.worktrees/' -e '/\.claude/worktrees/' \
    | while IFS= read -r d; do printf '%s\t%s\n' "$(stat -f %m "$d" 2>/dev/null || echo 0)" "$d"; done \
    | sort -rn | cut -f2-
)
[ "${#REPOS[@]}" -gt 0 ] || die "no git repos found under $WORKSPACE_ROOT"

if command -v fzf >/dev/null 2>&1; then
  REPO="$(printf '%s\n' "${REPOS[@]}" | sed "s#^$HOME#~#" \
          | fzf --prompt='repo > ' --height=40% --reverse)" || exit 0
  REPO="${REPO/#\~/$HOME}"
else
  echo "repos under ${WORKSPACE_ROOT/#$HOME/\~}:"
  i=1; for r in "${REPOS[@]}"; do printf '  %2d) %s\n' "$i" "$(basename "$r")"; i=$((i+1)); done
  printf 'number (or q) > '; read -r n
  [ "$n" = "q" ] && exit 0
  case "$n" in ''|*[!0-9]*) die "not a number: $n" ;; esac
  [ "$n" -ge 1 ] && [ "$n" -le "${#REPOS[@]}" ] || die "out of range: $n"
  REPO="${REPOS[$((n-1))]}"
fi
[ -n "${REPO:-}" ] && [ -d "$REPO" ] || exit 0
REPO_NAME="$(basename "$REPO")"

# --- 2. name the task -----------------------------------------------------
printf 'task (4-6 words) > '; read -r TASK
TASK="$(printf '%s' "$TASK" | tr -d '\n\r\t' | sed 's/^ *//; s/ *$//')"
[ -n "$TASK" ] || exit 0

# Slug: lowercase, spaces->dash, drop everything else. Guard against empty,
# leading dashes/dots, and git's invalid ref characters.
SLUG="$(printf '%s' "$TASK" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' _' '--' \
        | tr -cd 'a-z0-9-' \
        | sed 's/-\{2,\}/-/g; s/^-*//; s/-*$//' \
        | cut -c1-40)"
[ -n "$SLUG" ] || die "task name produced an empty slug: '$TASK'"
case "$SLUG" in .*|*..*) die "unsafe slug: '$SLUG'" ;; esac

# Truncation at 40 chars means two different tasks can collapse to the same
# slug -- "…routing layer for android" and "…routing layer for ios" both
# become "refactor-the-notification-routing-layer-". Silently reusing that
# worktree would put two agents in ONE checkout, destroying the isolation
# this whole design exists for. Suffix a short digest of the full text.
SUM="$(printf '%s' "$TASK" | shasum | cut -c1-4)"
SLUG="$(printf '%s' "$SLUG" | cut -c1-35)-$SUM"

# --- 3. resolve the base ref ---------------------------------------------
# Never assume 'main'. brobot is on origin/main, dotfiles on origin/master,
# and some repos have no origin/HEAD at all.
BASE="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"
if [ -z "$BASE" ]; then
  BASE="$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ -n "$BASE" ] && [ "$BASE" != "HEAD" ] || die "cannot determine a base ref in $REPO_NAME (detached HEAD or no commits)"
fi

# --- 4. create (or reuse) the worktree ------------------------------------
WT="$WT_ROOT/$REPO_NAME/$SLUG"
BRANCH="task/$SLUG"

if [ -d "$WT" ]; then
  # Only reuse a directory git actually knows about as a worktree of THIS
  # repo. A leftover directory that git has forgotten is not a safe place to
  # start work -- fail loudly rather than silently sharing a checkout.
  git -C "$REPO" worktree list --porcelain 2>/dev/null | grep -qxF "worktree $WT" \
    || die "$WT exists but is not a registered worktree of $REPO_NAME -- remove it or pick another task name"
  echo "reusing existing worktree $WT"
elif git -C "$REPO" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  mkdir -p "$(dirname "$WT")"
  git -C "$REPO" worktree add "$WT" "$BRANCH" || die "worktree add failed (branch $BRANCH exists)"
else
  mkdir -p "$(dirname "$WT")"
  git -C "$REPO" worktree add -b "$BRANCH" "$WT" "$BASE" \
    || die "worktree add failed: $REPO_NAME $BRANCH from $BASE"
fi

# --- 5. the cmux workspace ------------------------------------------------
# --command and --focus are both required: without them the workspace opens
# empty and unfocused. Description is written ONCE here and never touched by
# a hook -- the task pill and the auto-name own the other two fields.
"$CMUX" workspace create \
  --name "$TASK" \
  --description "$REPO_NAME · $BRANCH" \
  --cwd "$WT" \
  --command "claude" \
  --focus true \
  || die "cmux workspace create failed"

echo "✔ $TASK"
echo "  worktree $WT"
echo "  branch   $BRANCH (from $BASE)"
