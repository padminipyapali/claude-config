# Auto Memory

## Knowledge System

Shared cross-project knowledge lives in `~/.claude/knowledge/` (organized by topic, not project).
Global rules live in `~/.claude/CLAUDE.md` (loaded in every session).
Commands: `/consolidate-learnings`, `/capture-learning`, `/project-setup`, `/memory-guide`.

**Automated knowledge flow:**
- Plan time: Agent reads `~/.claude/knowledge/INDEX.md` + relevant topics (CLAUDE.md directive).
- PR time: Adversarial review step 7 captures learnings (hook-enforced).
- Periodic: `/consolidate-learnings` as safety net.

## Project: second-brain (my_mind_evolved)
- Repo: https://github.com/padminipyapali/second-brain
- Monorepo: packages/server, packages/web, packages/shared
- Stack: TypeScript, Express, React+Vite, Supabase (Postgres+pgvector), Claude API, OpenAI embeddings, Telegram bot
- CLAUDE.md has detailed guidelines — always read it before PRs
- CodeRabbit reviews PRs — address all feedback before merging
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)

## Project: nanny_management (nanny-app)
- Stack: React + TypeScript, Firebase (Firestore + Auth), Vite, Vitest
- Client-side only — no backend server, all calculations in browser
- Firebase security rules for multi-tenant access control (family owner, member, nanny)
- `test:rules` requires Firebase emulator (run separately from unit tests)

## Project: vocab_app (lexica)
- Monorepo: apps/mobile (React Native + Expo), apps/server (Hono + PostgreSQL), packages/shared
- Stack: TypeScript, Hono, React Native + Expo Router v4, PostgreSQL, Claude API (SM-2 spaced repetition)
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Two-phase AI streaming: Phase 1 streams conversation via Sonnet, Phase 2 extracts evaluations via Haiku tool_use

## Project: lullaby
- Path: /Users/padminipyapali/dev/claude_test/lullaby
- Stack: TypeScript, React Native (Expo), Supabase (PostgreSQL + Auth + Realtime)
- Purpose: Beautiful, mobile-first baby tracker app. Core differentiator: delightful UX with minimal taps.
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Separate from nanny_management (different concern: baby tracking vs employee management)

## Project: baby-name-picker
- Path: /Users/padminipyapali/dev/claude_test/baby-name-picker
- Stack: TypeScript, React Native (Expo), SQLite (expo-sqlite + Drizzle), Zustand, Supabase, Claude API
- Purpose: Mobile-first baby name discovery app. Side-by-side comparison, rich name cards, AI taste profiling.
- Core differentiator: rich data on cards + comparison mechanic, NOT social features.
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)

## Project: folio
- Path: /Users/padminipyapali/dev/claude_test/folio
- Stack: TypeScript, React Native (Expo Router v4), Supabase (PostgreSQL + Auth + Realtime), Zustand
- Monorepo: apps/mobile, packages/shared
- Purpose: Family net worth tracker. Two partners independently update 25+ account balances with real-time sync.
- No backend server — direct Supabase client from mobile.
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Key patterns: Result<T> service layer, balance_snapshot trigger + recompute_net_worth RPC, RLS gated by is_household_member()

## Project: command-center
- Stack: TypeScript, Express, grammY (Telegram), @octokit/graphql, Claude CLI agent runner
- Monorepo: packages/shared, packages/server, packages/web (placeholder)
- Purpose: Unified Telegram bot for monitoring 3 projects (status, PRs, agent delegation)
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Key patterns: thin command dispatchers to services, interface-first (AgentRunner, TaskQueue), env-driven project paths

## User Preferences

- **Auto-commit ~/.claude changes:** Whenever files in `~/.claude/` are modified (knowledge, commands, memory, settings, CLAUDE.md, etc.), always commit and push to `origin/main` of the `claude-config` repo before the session ends. Don't ask — just do it.

## Hard Lessons

- **ALWAYS run repo conflict detection before making code changes.** This is in global CLAUDE.md and is NOT optional. Check `git status --porcelain`, `ps aux | grep claude`, and `.git/index.lock` BEFORE any edits. Skipping this caused an entire session of wasted work when concurrent agents were reverting edits (second-brain feat/calendar-command, 2026-02-16).
- **When concurrent agents are detected: use Task agent with `bypassPermissions` for atomic edits.** Apply all changes + build + test in one burst via a delegated agent. This prevents interference from concurrent linters/builds. But this is a workaround — prefer avoiding conflicts in the first place.
- **NEVER skip the review loop or merge without user approval on continuation sessions.** Continuation summaries saying "code pushed, PR not created" do NOT mean the review loop was completed — the prior session likely stopped mid-cycle. Always verify which dev cycle steps (1-6) were actually completed. PR #255 was merged without review on a 182 LOC change because the continuation summary biased toward "just finish the task" (second-brain feat/dev-menu, 2026-02-25).

## In Progress: second-brain Issue #130 — Async Research Agent Mockups

- **Issue:** "Feature: Delegate long-running research tasks to background agent" (Phase 1: explorable TODOs, Phase 2: full async research agent)
- **Status:** 5 interactive HTML mockups created at `docs/mockups/second-brain/async-research-agent/`
  1. `01-telegram-native.html` — Chat-first flow, everything inside Telegram (digest cards, inline buttons, progress messages)
  2. `02-dashboard-command-center.html` — Dedicated "Research" dashboard section with sidebar queue + detail view
  3. `03-card-digest.html` — Warm editorial aesthetic, card-based digest with AI-suggested explorations
  4. `04-timeline-progress.html` — GitHub-dark theme, real-time vertical timeline with step-by-step findings
  5. `05-minimalist-split-pane.html` — Monospace/code-editor aesthetic, split queue + report reader
- **Round 2:** 5 flow prototypes showing dashboard integration (how Research lives in the existing UI):
  1. `flow-01-right-panel.html` — Research as a right-slide panel (like TODOs/Inbox), with "Research" button in feed header
  2. `flow-02-view-toggle.html` — Feed/Research toggle below the title, replaces masonry with research-specific two-column layout
  3. `flow-03-thread-integrated.html` — No new nav. Research block lives inside the existing thread panel for each entry
  4. `flow-04-floating-widget.html` — Persistent floating pill in bottom-right, expands to mini-queue card with context drawer
  5. `flow-05-filter-chip-overlay.html` — Research as a special filter chip in the existing chip row, detail via centered overlay modal
- Each prototype has 5 clickable steps: dashboard → mark explore → view research → in-progress → add context
- All match the existing noir theme (colors, fonts, card styles, panel patterns from actual codebase)
- **Next step:** User reviews flow prototypes and picks a direction. Then proceed to Step 1 planning for implementation.

## Ideas & Specs

- **Ideas index:** `app-ideas.csv` in claude_test root — all app ideas with dates.
- **In-progress specs:** `docs/specs/` — specs being developed. Check here when user asks "what can I work on?"
- **Active spec: Reading Assistant** (`docs/specs/reading-assistant.md`) — Chrome extension for active recall + arguing with articles. Status: waiting on 4 clarifying answers before full spec. Strongest idea from the batch — builds on vocab_app (spaced repetition) and second-brain (LLM + knowledge capture) experience.

## Knowledge Evolution Visualization

- **Path:** `docs/knowledge-evolution.html` in claude_test root
- **What:** Interactive dark-themed page visualizing how `~/.claude/` has evolved (hero stats, daily heatmap, category bubbles, file hotspots, project contributions, commit stream timeline)
- **Data source:** `git log` of the `~/.claude/` config repo
- **Update periodically:** Regenerate when the knowledge base has grown significantly (e.g., every ~50 new commits or when the user asks). Re-run the Python data extraction from the git log and rebuild the embedded JSON data in the HTML.
- **Last generated:** 2026-02-24 (173 commits, 35K lines, 11 days, 5 projects)

## Cross-Project Learnings

Detailed patterns now live in `~/.claude/knowledge/*.md` topic files (no longer duplicated here).
See `~/.claude/knowledge/INDEX.md` for the full topic list.
See [adversarial-review-patterns.md](adversarial-review-patterns.md) for historical review patterns.
See [schema-patterns.md](schema-patterns.md) for historical schema design patterns.
