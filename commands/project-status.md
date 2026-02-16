---
description: Show development activity status across all projects
allowed-tools: Bash, Read, Grep, Glob
---

Scan all tracked projects and display a concise status dashboard showing what's happening in each one.

## Projects to scan

These are the known project repos. Check each one:

| Project | Repo Path |
|---------|-----------|
| second-brain | `/Users/padminipyapali/dev/claude_test/my_mind_evolved` |
| second-brain v2 | `/Users/padminipyapali/dev/claude_test/my_mind_evolved_2` |
| nanny-app | `/Users/padminipyapali/dev/claude_test/nanny_management/nanny-app` |
| lexica | `/Users/padminipyapali/dev/claude_test/vocab_app/lexica` |
| command-center | `/Users/padminipyapali/dev/claude_test/command-center` |

## For each project, gather

Run these checks **in parallel across all projects** using the Bash tool:

1. **Current branch** — `git -C <path> branch --show-current`
2. **Uncommitted changes** — `git -C <path> status --porcelain` (count modified/added/deleted)
3. **Active Claude agents** — `ps aux | grep -E 'claude|claude-code' | grep -v grep | grep '<path>'`
4. **Git lock files** — `ls <path>/.git/index.lock 2>/dev/null`
5. **Last commit** — `git -C <path> log -1 --format='%ar — %s'`
6. **Open feature branches** — `git -C <path> branch --list | grep -v main | grep -v master | head -5`
7. **Stashed changes** — `git -C <path> stash list | head -3`

## Display format

Present the results as a compact dashboard. Use this format:

```
PROJECT STATUS DASHBOARD
========================

<project-name> [<branch>]
  Last commit: <relative time> — <message>
  Changes: <N modified, N added, N deleted> (or "Clean")
  Agents: <active / none>
  Branches: <list of non-main branches, or "main only">
  Stash: <count or "none">
  ⚠ <any warnings: lock files, agent conflicts>

---
(repeat for each project)
```

Use these status indicators at the start of each project line:
- `●` — Active work (uncommitted changes or active agents)
- `○` — Clean (no changes, no agents)
- `⚠` — Conflict/issue (lock files, detached HEAD, etc.)

## After displaying

Summarize: how many projects have active work, how many are clean, and flag any that need attention (lock files, very old branches, etc.).

Also check `~/.claude/task-queue.md` for any `[PENDING]` tasks and mention them if found.
