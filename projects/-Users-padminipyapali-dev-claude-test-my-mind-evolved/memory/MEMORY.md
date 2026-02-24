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
- Docs: BUGS.md, DECISIONS.md, PRODUCT_SPEC.md, QA.md, TODO_HANDLING.md

## Cross-Project Knowledge
All PR review patterns (27 items from PRs #23-#59), architecture learnings, LLM integration patterns, and adversarial review blindspots have been consolidated into ~/.claude/knowledge/. Load relevant topic files via INDEX.md.

## Process Learnings
- When spawning sub-agents for PRs, explicitly instruct them to run adversarial review. Agents follow feature correctness but skip security/robustness unless prompted.
- Parallel agents must use separate branches/worktrees to avoid Edit tool "file modified since read" conflicts.
- Always adversarial-review plans before presenting them. The first plan is often not the best.

## PR Sizing Rule
- Keep PRs under 600 LOC. Post-mortem data across 15+ tracked PRs shows shift-left effectiveness degrades sharply above ~600 LOC (67-100% under vs 14-59% over). The two cleanest large PRs (#142 and #157, both 0% fix-up) sat right at the threshold. Split features over 600 LOC into 2-3 focused PRs.
