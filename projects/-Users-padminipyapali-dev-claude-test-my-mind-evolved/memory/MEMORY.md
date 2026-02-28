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

## Cross-Project Knowledge
Consolidated into ~/.claude/knowledge/. Load relevant topic files via INDEX.md.
