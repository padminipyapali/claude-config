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

## Project: command-center
- Stack: TypeScript, Express, grammY (Telegram), @octokit/graphql, Claude CLI agent runner
- Monorepo: packages/shared, packages/server, packages/web (placeholder)
- Purpose: Unified Telegram bot for monitoring 3 projects (status, PRs, agent delegation)
- Has adversarial review hook (.claude/hooks/require-adversarial-review.sh)
- Key patterns: thin command dispatchers to services, interface-first (AgentRunner, TaskQueue), env-driven project paths

## User Preferences

- **Auto-commit ~/.claude changes:** Whenever files in `~/.claude/` are modified (knowledge, commands, memory, settings, CLAUDE.md, etc.), always commit and push to `origin/main` of the `claude-config` repo before the session ends. Don't ask — just do it.

## Cross-Project Learnings

Detailed patterns now live in `~/.claude/knowledge/*.md` topic files (no longer duplicated here).
See `~/.claude/knowledge/INDEX.md` for the full topic list.
See [adversarial-review-patterns.md](adversarial-review-patterns.md) for historical review patterns.
See [schema-patterns.md](schema-patterns.md) for historical schema design patterns.
