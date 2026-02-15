# Global Claude Code Rules

These rules apply to every project. Project-specific CLAUDE.md files supplement and can override these.

Stack-specific sections (marked "When Applicable") apply only when the project uses that technology.

---

## New Projects

When creating a new project or initializing a new codebase, always run `/project-setup`. This injects cross-project knowledge, sets up docs, hooks, and the adversarial review skill. Never skip this — even if the user doesn't explicitly ask for it.

## Process

- All changes via PRs — never commit directly to main.
- Feature branches: `<type>/<short-description>` (feat, fix, refactor, chore, docs, test).
- Keep PRs focused on one concern — don't mix refactoring with features.
- Tests required for every feature and bug fix. Docs-only or config PRs may skip with justification.
- Commit messages: complete sentences with periods.
- Pre-PR checks: run all relevant CI checks (build, lint, test) locally before opening a PR.
- Sort config files (.env.example, etc.) alphabetically.
- Never commit secrets, API keys, or credentials. Use environment variables.
- For projects with releases, follow semantic versioning (MAJOR.MINOR.PATCH).

## Living Documentation

Every PR should update the relevant living documents, if the project maintains them:

- `docs/BUGS.md` — Bug description, root cause, fix applied, lesson learned.
- `docs/DECISIONS.md` — Decisions made during human-Claude discussions.
- `docs/PRODUCT_SPEC.md` — New features and context for why they're added.
- `docs/QA.md` — Technical Q&A to sharpen the human's intuition.

## Adversarial Self-Review

Before every PR, perform these universal checks:

- **Pattern siblings.** When fixing a bug class, grep the ENTIRE codebase for other instances.
- **Walk full access chains.** Check every dereference for null/undefined/nil — not just the first level.
- **Fire-and-forget contract.** Every async operation inside a fire-and-forget method must be error-handled.
- **Error message specificity.** Add specific branches for edge cases — don't let them fall through to generic handlers.

For database projects, also review every item in the "Schema & Database" section below.

## Code Quality

- Module-level documentation headers on all top-level files describing the module's purpose.
- Early return before dead computation — don't compute values an early exit won't use.
- Use context-appropriate messages, not generic copy-paste.
- Store computed results alongside display text — don't re-derive what you already know.
- If a fix is under 5 lines, do it now — only defer fixes needing new infrastructure.
- Register global error handlers on long-running services — per-request error handling is necessary but not sufficient.
- Log errors with enough context to reproduce (request ID, user ID, operation name) but never log secrets or PII.

## Defensive Coding

- Scope data access to the authenticated user — never trust client-provided IDs to be globally unique.
- Trim and validate user input at the earliest pipeline entry point.
- Guard every index mapping: bounds-check user-provided numbers against array length.
- Graceful degradation at every layer: independent error handling around each operation.
- Error messages should be specific and actionable, not generic fallthrough.
- Schema changes need migration reminders — schema files are documentation, not deployment, without an automated runner.
- When two queries feed separate display sections and can overlap, filter by authoritative state rather than cross-referencing result sets.

## Planning Requirements

Every feature plan must:
- Enumerate ALL entry points (new vs resume, create vs update, empty vs populated state).
- Trace each path end-to-end: data read, state changed, API calls fired, UI rendered.
- Verify bidirectional state coverage: all values of state A produce correct behavior B.
- Answer: "If a user hit this feature after [alternative entry point], what would happen?"
- **Include a "Performance & Cost Impact" section** covering: (1) latency impact per affected user action, (2) new external API calls introduced and per-call cost, (3) new DB query load, (4) frequency of the affected code path (once/day vs. every user click), (5) mitigations if impact is non-negligible. This also applies to product specs in `docs/PRODUCT_SPEC.md`.

## Testing

- Test every type/feature combination, not just the happy path.
- Assert all side effects, not just the primary return value.
- For route changes: integration tests. For state/flow changes: flow tests. For pure logic: unit tests. Pure-function unit tests alone are NOT sufficient for route or flow changes.

## Architecture Principles

- Thin, stateless API layer: routes validate input and delegate to services. No business logic in controllers.
- Separate app initialization from server binding so tests don't open ports.
- Clean abstractions: each external dependency behind an interface.
- For CI/CD: prefer vendor's official GitHub Action over manual CLI installation.
- Single deployment for tightly coupled services at single-user scale — don't prematurely split.

## Config Repo Auto-Sync

The `~/.claude/` directory is a git repo (`claude-config`) with remote at `origin/main`. Whenever you modify any file in `~/.claude/` (knowledge, commands, memory, settings, CLAUDE.md, etc.), commit and push the changes before the session ends. Do this automatically — don't ask for confirmation.

## Cross-Project Knowledge

A shared knowledge base lives at `~/.claude/knowledge/`. It contains topic-organized learnings from ALL projects.

**When planning a feature or starting significant work:**
1. Read `~/.claude/knowledge/INDEX.md` to see available topics.
2. Load the topic files matching the current project's stack (see the Stack Matching Guide in INDEX.md).
3. Apply relevant patterns during implementation — these are hard-won lessons from sibling projects.

This is not optional. Skipping this means repeating bugs that were already solved in another project.

## Proactive Learning Capture

When you encounter any of the following during a session, proactively add them to the appropriate `~/.claude/knowledge/*.md` topic file:
- A bug pattern that could recur in other projects.
- A decision that reflects a general preference (not project-specific).
- A user-expressed preference for tools, workflow, or communication.
- A defensive coding pattern discovered through a bug fix.

When creating a PR (during adversarial review), verify:
1. Are there new cross-project patterns that should be captured in `~/.claude/knowledge/`?
2. Have project `docs/` (BUGS.md, DECISIONS.md) been updated?
3. If a bug was fixed, would the same bug class exist in a sibling project? If yes, capture the pattern.

---

# When Applicable: TypeScript / JavaScript

- Don't mark functions `async` unless they `await` something.
- Exhaustive `never` checks should throw, not return — fail fast on unhandled types.
- Fire-and-forget operations MUST have `.catch()` handlers to prevent unhandled rejections.
- Runtime arrays derived from TS types need "keep in sync" comments (types erased at runtime).
- Build tools (@types, typescript, vite, tsx, vitest) in devDependencies.
- npm workspaces use `*` not `workspace:*` (that's pnpm/yarn).
- Full object assertions in tests, not `objectContaining`, unless partial matching is intentional.
- Negative async assertions ("should NOT have been called") need settle time — polling helpers (waitFor) pass immediately for negatives. Use a timeout to let promises settle first.

# When Applicable: Web UI

- Explicit `type` on every `<button>`: `type="button"` (default) or `type="submit"` (forms only).
- Don't rely on Unicode characters for icons — use SVG for consistent sizing across platforms.
- Don't impose arbitrary UI truncation — make content expandable if length varies.
- Use placeholder hints instead of default values for user-configurable settings.
- CSS viewport units (`dvh`/`svh`/`lvh`) don't account for virtual keyboards on mobile. Use the `visualViewport` API for panels with fixed-position input fields.

# When Applicable: React Native

- FlatList memoizes renderItem aggressively. External state used in renderItem MUST be passed via `extraData`, or items won't re-render when that state changes.

# When Applicable: Databases (SQL)

- Enforce invariants at DB level with triggers, not application code.
- Bidirectional enforcement: guard both child INSERT and parent UPDATE.
- Use partial unique indexes (`WHERE col IS NOT NULL`) for nullable columns that should be unique when present.
- Never use OR in WHERE clauses that defeat index usage — split into two queries.
- FTS indexes must cover ALL searchable text columns.
- Auto-manage derived fields (completed_at, updated_at) via triggers.
- Index leading columns must match WHERE clause order. Composite PK (A,B) only indexes queries by A.
- Timestamp propagation: child changes should touch parent updated_at for recency-sorted feeds.
- SQL constraints and application-level type unions must stay in sync. Document which is source of truth.
- (PostgreSQL) `AT TIME ZONE`: always cast to `::timestamp` before applying — `date` implicitly casts to `timestamptz` which reverses the conversion.
- (node-postgres) pg returns DATE as JS Date, TIMESTAMPTZ as Date, JSONB as object — mock-based tests can't catch these type mismatches. Verify pg's actual return type when adding new columns.

# When Applicable: LLM Integration

- Always strip markdown code fences before parsing LLM output as structured data. This is the common case, not an edge case.
- Always validate/filter LLM structured output against the source of truth before sending to clients.
- For open-ended natural language parsing, use LLM extraction not regex/stopword lists.
- Classifier prompts need explicit negative examples for ambiguous categories.
- Few-shot examples at decision boundaries are more effective than abstract rules.
- Separate user-provided content from system instructions to prevent prompt injection. For Claude API: user content in the user message (inside XML tags), not the system prompt.
- Classification intents designed for one input mode (standalone messages) may not apply in another (thread replies). Verify each classification outcome makes sense per input context.

# When Applicable: Firebase / Firestore

- Wildcard security rules can hide permission gaps — use specific subcollection rules for fine-grained permissions.
- Test security rule changes across every role/account type defined in the app.
- Indexed lookups (subcollection references) over full-collection scans for permission checks.
