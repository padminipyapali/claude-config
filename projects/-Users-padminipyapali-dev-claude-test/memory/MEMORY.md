# Auto Memory — claude_test workspace

## Knowledge System

Shared cross-project knowledge lives in `~/.claude/knowledge/` (organized by topic, not project).
Global rules live in `~/.claude/CLAUDE.md` (loaded in every session).
Commands: `/consolidate-learnings`, `/capture-learning`, `/project-setup`, `/memory-guide`.

**Automated knowledge flow:**
- Plan time: Agent reads `~/.claude/knowledge/INDEX.md` + relevant topics (CLAUDE.md directive).
- PR time: Adversarial review step 7 captures learnings (hook-enforced).
- Periodic: `/consolidate-learnings` as safety net.

## Docs Structure (feature-centric)

All projects now use a feature-centric docs layout (updated 2026-02-25):
```
docs/
  product-spec.md
  features/
    <feature-name>/
      spec.md, mockups/, explainers/, decisions.md, bugs.md, post-mortems/
    _cross-cutting/
      decisions.md, bugs.md
```
See CLAUDE.md "Living Documentation" for full rules.

## HTML Visualizations (non-mockup)

System-level visualizations live in `~/.claude/docs/`:
- `knowledge-evolution.html` — "The Brain Grows" (git history viz, last generated 2026-02-24)
- `knowledge-system.html` — Cross-project knowledge system structure diagram
- `learning-loop-current.html` — Learning loop feedback cycle
- `development-process.html` — Development process documentation
- `mockups/dashboard-themes/` — 3 dev loop dashboard theme variants
- `mockups/dev-process-themes/` — 5 dev process page theme variants
- `knowledge/metrics/dashboard.html` — Self-improvement metrics dashboard (Chart.js)

## User Preferences

- **Auto-commit ~/.claude changes:** Whenever files in `~/.claude/` are modified (knowledge, commands, memory, settings, CLAUDE.md, etc.), always commit and push to `origin/main` of the `claude-config` repo before the session ends. Don't ask — just do it.

## In Progress: second-brain Issue #130 — Async Research Agent Mockups

- **Issue:** "Feature: Delegate long-running research tasks to background agent" (Phase 1: explorable TODOs, Phase 2: full async research agent)
- **Status:** 10 mockups + 3 extra flow prototypes now live in `my_mind_evolved/docs/features/async-research-agent/mockups/`
- **Next step:** User reviews flow prototypes and picks a direction. Then proceed to Step 1 planning for implementation.

## Ideas & Specs

- **Ideas index:** `app-ideas.csv` in claude_test root — all app ideas with dates.
- **In-progress specs:** `docs/specs/` in claude_test root — specs being developed. Check here when user asks "what can I work on?"
- **Active spec: Reading Assistant** (`docs/specs/reading-assistant.md`) — Chrome extension for active recall + arguing with articles. Status: waiting on 4 clarifying answers before full spec.
