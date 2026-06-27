# Shared Knowledge Base

Cross-project learnings organized by topic. These files contain detailed patterns extracted from all projects — load the ones relevant to your current project's stack.

**How this works:**
- When planning a feature or starting significant work, read this INDEX and load relevant topic files.
- When completing a PR (during adversarial review), check if new learnings should be added here.
- `/consolidate-learnings` periodically syncs project docs into these files.

## Topic Files

| File | Stacks | Description |
|------|--------|-------------|
| [typescript-patterns.md](typescript-patterns.md) | TypeScript, Node.js | Type safety, async patterns, API boundaries, env vars |
| [react-patterns.md](react-patterns.md) | React, React Native | Hooks, state management, FlatList, optimistic UI, a11y |
| [llm-integration.md](llm-integration.md) | Claude API, OpenAI, LLMs | Prompt design, output parsing, safety, classification |
| [image-generation-consistency.md](image-generation-consistency.md) | AI image gen (Gemini/DALL·E/diffusion), illustration | Multi-image consistency: deterministic color-grade, axis-split fixes, judge/verify panels, operator color tuner |
| [database-patterns.md](database-patterns.md) | PostgreSQL, SQL, Supabase | Schema design, indexes, triggers, pg driver quirks |
| [firebase-patterns.md](firebase-patterns.md) | Firebase, Firestore | Security rules, multi-tenant access, auth patterns |
| [telegram-bot-patterns.md](telegram-bot-patterns.md) | grammY, Telegram Bot API | Identity mapping, webhooks, bot architecture |
| [architecture-patterns.md](architecture-patterns.md) | All | Service layers, async init, testing, error handling |
| [adversarial-review.md](adversarial-review.md) | All | The shared mechanical review checklist |
| [testing-patterns.md](testing-patterns.md) | Vitest, testing in general | Test strategy, mocking pitfalls, assertion patterns |
| [strategic-decisions.md](strategic-decisions.md) | All | Product thinking, MVP strategy, feature scope, decision frameworks |
| [orchestrator-protocol.md](orchestrator-protocol.md) | All | Team pattern: 3-role structure, sequencing, status messages, duties |
| [development-steps.md](development-steps.md) | All | Detailed step procedures (1a-1c, 2a-2b, 3, 4a-4e), PR body templates |
| [review-and-triage.md](review-and-triage.md) | All | Adversarial review details, outside-diff triage, cleanup sweeps, CodeRabbit |
| [living-documentation.md](living-documentation.md) | All | Feature-organized docs structure, flow diagram guidelines |
| [process-patterns.md](process-patterns.md) | All | Development process: review efficiency, planning, iteration velocity |
| [convention-violations.md](convention-violations.md) | All | Convention violation tracker: recurrence counts, enforcement status, escalation |
| [design-preferences.md](design-preferences.md) | All (HTML/CSS) | Padmini's preferred visual theme, palette, typography, layout, motion (proximity interaction is the default) |
| [color-palettes.md](color-palettes.md) | All (HTML/CSS) | OKLCH color palettes (4 themes) for frontend projects, generated via kigen.design |
| [second-brain-testing.md](second-brain-testing.md) | Second Brain | Local dev setup, bypassing login, running frontend/full stack |
| [annotation-workflow.md](annotation-workflow.md) | All (tooling) | Mockup annotation system: inbox server, bookmarklet, feedback pickup |
| [shared-snippets.md](shared-snippets.md) | TypeScript, Node.js | Canonical copy-paste utilities: escapeXml, stripFences, validators, Express boilerplate |

### Evidence Archives (load on demand, not during normal work)

| File | Parent | Description |
|------|--------|-------------|
| [process-patterns-evidence.md](process-patterns-evidence.md) | process-patterns | Full incident history with PR numbers and dates |
| [react-patterns-evidence.md](react-patterns-evidence.md) | react-patterns | Full incident history with PR numbers and source comments |
| [adversarial-review-evidence.md](adversarial-review-evidence.md) | adversarial-review | Full rationale and backstory for each checklist item |

**When to load evidence files:** Post-mortems, investigating a recurring pattern, or when you need to understand *why* a rule exists.

## Stack Matching Guide

When starting work on a project, load files matching these stacks:

- **TypeScript backend** → typescript-patterns, architecture-patterns, testing-patterns, shared-snippets
- **React web app** → typescript-patterns, react-patterns, testing-patterns, color-palettes
- **React Native app** → typescript-patterns, react-patterns (includes RN section), testing-patterns
- **PostgreSQL** → database-patterns
- **Firebase** → firebase-patterns
- **Telegram bot** → telegram-bot-patterns, architecture-patterns
- **LLM/AI features** → llm-integration
- **AI image generation / illustration** → image-generation-consistency, llm-integration
- **Any project (dev workflow)** → orchestrator-protocol, development-steps
- **Any project pre-PR** → adversarial-review, review-and-triage
- **Any project pre-plan** → strategic-decisions
- **Any project post-merge** → process-patterns, convention-violations

## Last Updated

Updated by: /consolidate-learnings
