#!/usr/bin/env bash
# Stop hook: if this branch changed files but .claude/memory/ was not touched,
# block Claude from finishing until it updates memory.

input=$(cat)

# Already blocked once in this turn: let it stop, avoid an endless loop.
if echo "$input" | grep -q '"stop_hook_active": *true'; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Uncommitted changes + commits on this branch that are not on origin/main yet.
uncommitted=$(git status --porcelain --untracked-files=all 2>/dev/null)
committed=$(git diff --name-only origin/main...HEAD 2>/dev/null)
changed="$uncommitted
$committed"

if ! echo "$changed" | grep -q '[^[:space:]]'; then
    exit 0
fi

if echo "$changed" | grep -q '\.claude/memory/'; then
    exit 0
fi

echo '{"decision": "block", "reason": "Files changed but .claude/memory/ was not updated. Update STATE.md (session log, current state) and DECISIONS.md / BACKLOG.md / LEARNING.md as described in .claude/CLAUDE.md, commit it with the work, then finish."}'
exit 0
