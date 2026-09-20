#!/bin/bash
# Seats an existing Claude Code conversation as this fleet's root session.
#
# Prepares only. It never starts the fleet: the conversation being seated MUST
# have ended first, or two processes append to the same transcript.
#
#   ./workspace/transplant.sh <claude-session-id>
#
# Then, and only once that conversation is closed:  npm start
set -euo pipefail

ROOT="/Users/photon/projects/silicyte/silicyte-solo-dev"
PRODUCT="/Users/photon/projects/silicyte/silicyte"
ROLE="root"

SESSION="${1:-}"
if [ -z "$SESSION" ]; then
  echo "usage: $0 <claude-session-id>" >&2
  exit 2
fi

TRANSCRIPT="$(find "$HOME/.claude/projects" -maxdepth 2 -name "$SESSION.jsonl" 2>/dev/null | head -1)"
if [ -z "$TRANSCRIPT" ]; then
  echo "no transcript found for session $SESSION under ~/.claude/projects" >&2
  exit 1
fi

if pgrep -f "start\.ts|supervised\.ts" >/dev/null 2>&1; then
  echo "a fleet is already running — stop it before seating a session" >&2
  exit 1
fi

AGE=$(( $(date +%s) - $(stat -f %m "$TRANSCRIPT") ))
if [ "$AGE" -lt 120 ]; then
  echo "WARNING: that transcript was written ${AGE}s ago, so the conversation is probably still open."
  echo "         Close it before running npm start, or two processes will write the same file."
  echo
fi

SID="$ROLE-$(head -c 4 /dev/urandom | xxd -p)"
WORKTREE="$ROOT/.silicyte/worktrees/$SID--silicyte"
BRANCH="silicyte/$SID"

mkdir -p "$ROOT/.silicyte/worktrees"
git -C "$PRODUCT" worktree add -b "$BRANCH" "$WORKTREE" >/dev/null
git -C "$PRODUCT" worktree list | grep "$SID"

cat > "$ROOT/.silicyte/registry.json" <<JSON
[
  {
    "sid": "$SID",
    "claudeSessionId": "$SESSION",
    "role": "$ROLE",
    "title": "$ROLE",
    "reportsTo": null,
    "spawnedBy": "transplant",
    "worktreePathByRepo": { "silicyte": "$WORKTREE" },
    "cwd": "$WORKTREE",
    "branch": "$BRANCH"
  }
]
JSON

echo
echo "registry.json written:   $ROOT/.silicyte/registry.json"
echo "  sid        $SID"
echo "  resuming   $SESSION"
echo "  transcript $TRANSCRIPT"
echo "  worktree   $WORKTREE"
echo
echo "Next, once that conversation is closed:"
echo "  cd $ROOT && npm start"
