# Auto Memory

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
Old flat files (BUGS.md, DECISIONS.md, QA.md) have been split into per-feature and _cross-cutting directories. QA content merged into decisions.md. See CLAUDE.md "Living Documentation" for full rules.

## HTML Visualizations (non-mockup)

System-level visualizations live in `~/.claude/docs/`:
- `knowledge-evolution.html` — "The Brain Grows" (git history viz, last generated 2026-02-24)
- `knowledge-system.html` — Cross-project knowledge system structure diagram
- `learning-loop-current.html` — Learning loop feedback cycle
- `development-process.html` — Development process documentation
- `mockups/dashboard-themes/` — 3 dev loop dashboard theme variants
- `mockups/dev-process-themes/` — 5 dev process page theme variants
- `knowledge/metrics/dashboard.html` — Self-improvement metrics dashboard (Chart.js)

## Project: second-brain (my_mind_evolved)
- Repo: https://github.com/padminipyapali/second-brain
- Monorepo: packages/server, packages/web, packages/shared
- Stack: TypeScript, Express, React+Vite, Supabase (Postgres+pgvector), Claude API, OpenAI embeddings, Telegram bot
- CLAUDE.md has detailed guidelines — always read it before PRs
- CodeRabbit reviews PRs — address all feedback before merging
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Docs restructured to feature-centric layout (2026-02-25): async-research-agent, brief-format, changelog, thread-panel, todo-button-feedback, jwt-verification, entry-curator + _cross-cutting
- my_mind_evolved_2 is a stale clone — all unique docs (specs/) merged into my_mind_evolved

## Project: nanny_management (nanny-app)
- Stack: React + TypeScript, Firebase (Firestore + Auth), Vite, Vitest
- Client-side only — no backend server, all calculations in browser
- Firebase security rules for multi-tenant access control (family owner, member, nanny)
- `test:rules` requires Firebase emulator (run separately from unit tests)
- Docs features: dashboard, pay-period-export, setup-wizard + _cross-cutting

## Project: vocab_app (lexica)
- Monorepo: apps/mobile (React Native + Expo), apps/server (Hono + PostgreSQL), packages/shared
- Stack: TypeScript, Hono, React Native + Expo Router v4, PostgreSQL, Claude API (SM-2 spaced repetition)
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Two-phase AI streaming: Phase 1 streams conversation via Sonnet, Phase 2 extracts evaluations via Haiku tool_use
- Docs features: design-exploration (11 UI theme mockups) + _cross-cutting

## Project: lullaby
- Path: /Users/padminipyapali/dev/claude_test/lullaby
- Stack: TypeScript, React Native (Expo), Supabase (PostgreSQL + Auth + Realtime)
- Purpose: Beautiful, mobile-first baby tracker app. Core differentiator: delightful UX with minimal taps.
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Separate from nanny_management (different concern: baby tracking vs employee management)
- Docs features: home-screen, summary-view + _cross-cutting

## Project: baby-name-picker
- Path: /Users/padminipyapali/dev/claude_test/baby-name-picker
- Stack: TypeScript, React Native (Expo), SQLite (expo-sqlite + Drizzle), Zustand, Supabase, Claude API
- Purpose: Mobile-first baby name discovery app. Side-by-side comparison, rich name cards, AI taste profiling.
- Core differentiator: rich data on cards + comparison mechanic, NOT social features.
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Docs features: core-loop (18 mockups across 3 rounds) + _cross-cutting

## Project: folio
- Path: /Users/padminipyapali/dev/claude_test/folio
- Stack: TypeScript, React Native (Expo Router v4), Supabase (PostgreSQL + Auth + Realtime), Zustand
- Monorepo: apps/mobile, packages/shared
- Purpose: Family net worth tracker. Two partners independently update 25+ account balances with real-time sync.
- No backend server — direct Supabase client from mobile.
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Key patterns: Result<T> service layer, balance_snapshot trigger + recompute_net_worth RPC, RLS gated by is_household_member()
- Docs features: _cross-cutting only (no mockups)

## Project: command-center
- Stack: TypeScript, Express, grammY (Telegram), @octokit/graphql, Claude CLI agent runner
- Monorepo: packages/shared, packages/server, packages/web (placeholder)
- Purpose: Unified Telegram bot for monitoring 3 projects (status, PRs, agent delegation)
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Key patterns: thin command dispatchers to services, interface-first (AgentRunner, TaskQueue), env-driven project paths
- Docs features: web-dashboard, coding-sessions, config-changelog + _cross-cutting

## Project: memoir-helper
- Path: /Users/padminipyapali/dev/claude_test/memoir-helper
- Early stage — has docs/features/story-capture/mockups/ (5 HTML mockups) but no product-spec yet

## User Preferences

- **Auto-commit ~/.claude changes:** Whenever files in `~/.claude/` are modified (knowledge, commands, memory, settings, CLAUDE.md, etc.), always commit and push to `origin/main` of the `claude-config` repo before the session ends. Don't ask — just do it.

## Hard Lessons

- **ALWAYS run repo conflict detection before making code changes.** This is in global CLAUDE.md and is NOT optional. Check `git status --porcelain`, `ps aux | grep claude`, and `.git/index.lock` BEFORE any edits. Skipping this caused an entire session of wasted work when concurrent agents were reverting edits (second-brain feat/calendar-command, 2026-02-16).
- **When concurrent agents are detected: use Task agent with `bypassPermissions` for atomic edits.** Apply all changes + build + test in one burst via a delegated agent. This prevents interference from concurrent linters/builds. But this is a workaround — prefer avoiding conflicts in the first place.
- **NEVER skip the review loop or merge without user approval on continuation sessions.** Continuation summaries saying "code pushed, PR not created" do NOT mean the review loop was completed — the prior session likely stopped mid-cycle. Always verify which dev cycle steps (1-6) were actually completed. PR #255 was merged without review on a 182 LOC change because the continuation summary biased toward "just finish the task" (second-brain feat/dev-menu, 2026-02-25).

## In Progress: second-brain Issue #130 — Async Research Agent Mockups

- **Issue:** "Feature: Delegate long-running research tasks to background agent" (Phase 1: explorable TODOs, Phase 2: full async research agent)
- **Status:** 10 mockups + 3 extra flow prototypes now live in `my_mind_evolved/docs/features/async-research-agent/mockups/`
- **Next step:** User reviews flow prototypes and picks a direction. Then proceed to Step 1 planning for implementation.

## Ideas & Specs

- **Ideas index:** `app-ideas.csv` in claude_test root — all app ideas with dates.
- **In-progress specs:** `docs/specs/` in claude_test root — specs being developed. Check here when user asks "what can I work on?"
- **Active spec: Reading Assistant** (`docs/specs/reading-assistant.md`) — Chrome extension for active recall + arguing with articles. Status: waiting on 4 clarifying answers before full spec.

## Cross-Project Learnings

Detailed patterns now live in `~/.claude/knowledge/*.md` topic files (no longer duplicated here).
See `~/.claude/knowledge/INDEX.md` for the full topic list.
See [adversarial-review-patterns.md](adversarial-review-patterns.md) for historical review patterns.
See [schema-patterns.md](schema-patterns.md) for historical schema design patterns.
