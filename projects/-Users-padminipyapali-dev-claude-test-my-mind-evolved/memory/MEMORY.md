# Memory — second-brain (my_mind_evolved)

## Project-Specific
- Monorepo: packages/server, packages/web, packages/shared
- Server entrypoint: packages/server/src/server.ts
- Pipeline orchestrator: packages/server/src/processor/message-processor.ts
- Services: classifier, embedding, entry, response, search (in packages/server/src/services/)
- Channel adapters: packages/server/src/channels/telegram.ts
- All services use interface + implementation pattern (e.g. EntryService / PostgresEntryService)
- MessageProcessorDeps aggregates all service interfaces for DI
- Identity: message.userId = channel-specific (Telegram chat ID). After findOrCreateUser = internal DB UUID. Outbound calls need channel ID.
- Docs: feature-centric layout under docs/features/

## Project Gotchas

- **`schema.sql` is documentation, NOT deployment.** There is no migration runner. Every schema change requires manual SQL execution on Supabase. Code that depends on new tables MUST have graceful degradation.
- **pg returns JS `Date` objects for DATE/TIMESTAMPTZ columns.** Mocks using strings will pass tests but fail at runtime. Always verify pg's actual JS type for each column type.
- **`my_mind_evolved_2` is a separate prod deployment.** Changes here don't propagate there. Don't confuse the two directories.
- **CHAT intent is ephemeral — no entry created.** Thread replies must override CHAT to THOUGHT, otherwise the reply vanishes on refresh.
- **`new Date("2026-02-14T10:00:00")` without `Z` parses as local timezone.** Use `getLocalToday()` helper for user-facing date computations. `USER_TIMEZONE` env var controls timezone.
- **PostgreSQL `AT TIME ZONE` behaves differently for `timestamp` vs `timestamptz`.** Always cast to `::timestamp` (not `::date`) before `AT TIME ZONE` when you want local-to-UTC conversion.

## Design Preferences
- Padmini's preferred HTML theme: "Light Editorial" — warm off-white, sans-serif (Inter), terracotta accent, magazine-like feel. Reference: `docs/features/_cross-cutting/explainers/performance-optimizations.html`. Full spec saved to `~/.claude/knowledge/design-preferences.md`.

## Cross-Project Knowledge
Consolidated into ~/.claude/knowledge/. Load relevant topic files via INDEX.md.
