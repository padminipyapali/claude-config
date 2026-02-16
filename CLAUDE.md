# Global Claude Code Rules

These rules apply to every project. Project-specific CLAUDE.md files supplement and can override these.

Stack-specific sections (marked "When Applicable") apply only when the project uses that technology.

**Precedence**: When rules conflict: project CLAUDE.md > global CLAUDE.md > knowledge files > project memory.

---

## Session Start Protocol

On EVERY session start — including continuations from previous sessions — run these checks before any code changes:

1. **Repo conflict detection.** For each repo you plan to modify, run:
   - `git -C <path> status --porcelain` — check for uncommitted changes.
   - `ps aux | grep -E 'claude|claude-code' | grep -v grep | grep '<path>'` — check for active agents.
   - `ls <path>/.git/index.lock 2>/dev/null` — check for git lock files.
2. **Do NOT trust continuation summaries about repo state.** The summary reflects the *previous* session. Other agents may have started, files may have changed, branches may have moved. Verify it yourself.
3. **If conflicts are detected**, follow the Repo Conflict Detection rules below (queue the task, don't edit).

This is non-negotiable. Skipping this check has caused entire sessions of wasted work when concurrent agents were modifying the same repo.

## New Projects

When creating a new project or initializing a new codebase, always run `/project-setup`. This injects cross-project knowledge, sets up docs, hooks, and the adversarial review skill. Never skip this — even if the user doesn't explicitly ask for it.

## Process

- All changes via PRs — never commit directly to main.
- Feature branches: `<type>/<short-description>` (feat, fix, refactor, chore, docs, test).
- Keep PRs focused on one concern — don't mix refactoring with features.
- Tests required for every feature and bug fix. Docs-only or config PRs may skip with justification.
- Commit messages: complete sentences with periods.
- Pre-PR pipeline (in order): (1) code-simplifier on changed files, (2) `/adversarial-review`, (3) CI checks (build, lint, test).
- Sort config files (.env.example, etc.) alphabetically.
- Never commit secrets, API keys, or credentials. Use environment variables.
- For projects with releases, follow semantic versioning (MAJOR.MINOR.PATCH).
- Issue lifecycle: include `Closes #N` in the PR commit message so GitHub auto-closes the issue on merge. If an issue is addressed across multiple PRs, close it manually with a comment linking to all relevant PRs after the last one merges.
- Post-merge: after merging any PR, automatically run `/post-mortem [PR-number]` in the background. Don't ask — just do it. The command appends metrics and regenerates the self-improvement dashboard.

## Living Documentation

Every PR should update the relevant living documents, if the project maintains them:

- `docs/BUGS.md` — Bug description, root cause, fix applied, lesson learned.
- `docs/DECISIONS.md` — Decisions made during human-Claude discussions.
- `docs/PRODUCT_SPEC.md` — New features and context for why they're added.
- `docs/QA.md` — Technical Q&A to sharpen the human's intuition.

## Feature Flow Diagrams

For features that span **multiple components, systems, or vendors**, create a flow diagram in `docs/features/<feature-name>/flow-diagram.html`. Use `/flow-diagram` to generate these.

- **When to create:** The feature involves 3+ systems (e.g., external vendor → backend → DB → notification channel), crosses network boundaries, or has non-obvious failure modes.
- **When NOT to create:** Single-component features, simple CRUD, UI-only changes.
- **Location:** `docs/features/<feature-name>/flow-diagram.html` — self-contained HTML, no external dependencies.
- **Required sections:** Step-by-step flow, technologies & vendors (with doc links), security notes (if applicable), failure mode table.
- **Not in mockups:** Flow diagrams are technical documentation, not UI mockups. They live in `docs/features/`, not `docs/mockups/`.

## Pre-PR Code Simplification

Before adversarial review, run the code-simplifier agent on all changed files. This refines code for clarity, consistency, and maintainability without changing functionality. Scope: only files modified in the current branch (vs main). Do not simplify unchanged files.

## Adversarial Self-Review

After code simplification, run `/adversarial-review`. The review is **targeted, not exhaustive** — classify changed files by category (async, routes, DB, UI, LLM, shell, config, test-only) and run only the matching checklist sections. See `~/.claude/knowledge/adversarial-review.md` for the category-to-tier mapping. Don't block PRs on checklist items that don't apply to the files changed.

These universal checks always apply regardless of category:

- **Pattern siblings.** When fixing a bug class, grep the ENTIRE codebase for other instances.
- **Walk full access chains.** Check every dereference for null/undefined/nil — not just the first level.
- **Fire-and-forget contract.** Every async operation inside a fire-and-forget method must be error-handled.
- **Error message specificity.** Add specific branches for edge cases — don't let them fall through to generic handlers.

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

## Product Discovery & Ideation

Before jumping to planning, take a product expert's view. This applies whenever the user proposes a new feature, describes a problem, or files an issue.

**Pre-planning questioning (always do this):**
- Ask 2-3 clarifying questions that challenge assumptions and sharpen the idea before committing to a plan. Push the user to think through edge cases and user impact — don't just accept the first framing.
- Questions should probe: "Who hits this and how often?", "What's the manual workaround today?", "What changes if we DON'T build this?", "Is this a symptom of a deeper design gap?"
- Read `~/.claude/knowledge/strategic-decisions.md` before questioning — prior product decisions provide context for whether the new idea aligns or diverges.

**Learning from issues and feature requests:**
- When presented with a GitHub issue or feature request, ask: "What were you doing when this came up?" and "What would you expect to happen instead?" — the answers reveal product assumptions worth capturing.
- Automatically deduce product learnings from changes requested. If the user asks to change existing behavior, note the delta between original design and actual usage — this is high-signal for `strategic-decisions.md`.

**Learning capture:**
- After a feature discussion clarifies a product instinct or decision framework, add it to `~/.claude/knowledge/strategic-decisions.md`.
- Product learnings are distinct from technical patterns — they capture *why* to build something, not *how*.

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

## Repo Conflict Detection & Task Queue

Before making code changes to any repo (not just reading/exploring), check for active work:

**Detection steps:**
1. Run `git -C <repo-path> status --porcelain` — if output is non-empty, there are uncommitted changes.
2. Run `ps aux | grep -E 'claude|claude-code' | grep -v grep | grep '<repo-path>'` — check for other Claude sessions targeting that repo.
3. Check for lock files: `ls <repo-path>/.git/index.lock 2>/dev/null` — indicates an active git operation.

**If active work is detected:**
- Do NOT make code changes to that repo.
- Tell the user what was detected (uncommitted files, running agents, etc.).
- Add the task to `~/.claude/task-queue.md` with this format:
  ```
  ## [PENDING] <short task title>
  - **Repo:** <repo path>
  - **Queued:** <date>
  - **Context:** <what the user asked for — enough detail to execute later>
  - **Detection:** <what was detected — e.g., "3 modified files on branch feat/streaming">
  ```
- Exploration and read-only analysis of the repo is still fine — only code changes are blocked.

**On session start:**
- Check if `~/.claude/task-queue.md` exists and has `[PENDING]` entries.
- For each pending entry, check if the repo is now free (re-run detection steps).
- If free, prompt the user: "There's a queued task for <repo>: <title>. The repo is now free. Want me to execute it?"
- When a queued task is completed, change `[PENDING]` to `[DONE]` and add a completion date.
- Periodically prune `[DONE]` entries older than 7 days.

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
- A product/strategic decision or instinct revealed during feature discussions → `strategic-decisions.md`.

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
