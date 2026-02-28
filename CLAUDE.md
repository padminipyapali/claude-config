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
   If ANY check returns positive: do NOT make code changes (read-only analysis is fine). Tell the user what was detected and queue the task in `~/.claude/task-queue.md`:
   ```
   ## [PENDING] <short task title>
   - **Repo:** <repo path>
   - **Queued:** <date>
   - **Context:** <what the user asked for>
   - **Detection:** <what was detected>
   ```
2. **Check the task queue.** If `~/.claude/task-queue.md` has `[PENDING]` entries, re-run detection for each repo. If free, prompt the user: "There's a queued task for <repo>: <title>. The repo is now free. Want me to execute it?" Mark completed entries `[DONE]` with a date. Prune `[DONE]` entries older than 7 days.
3. **Do NOT trust continuation summaries about repo state.** Verify it yourself — other agents may have started, files changed, branches moved.
4. **Development cycle checkpoint.** Before creating a PR or merging, verify which dev cycle steps (1, 2, 3, 4a-4e, 5) were completed in the *current* session. Walk through the 9 trackable steps explicitly.
5. **Never merge a PR without explicit user approval.** Creating the PR is step 5. The user decides when to merge.
6. **Project infrastructure check.** If the project has no `CLAUDE.md`, run `/project-setup` before any code changes. A project with code but no CLAUDE.md is un-initialized.

This is non-negotiable. Skipping caused: concurrent agent conflicts, PR #255 merged without review (continuation summary bias), summer-camps PR #1 shipped without adversarial review hook.

## New Projects

When creating a new project or initializing a new codebase, always run `/project-setup`. This injects cross-project knowledge, sets up docs, hooks, and the adversarial review skill. Never skip this.

## Process

- **Always use a worktree.** Create a git worktree before any code change to isolate work from the main checkout.
- All changes via PRs — never commit directly to main.
- Feature branches: `<type>/<short-description>` (feat, fix, refactor, chore, docs, test).
- Keep PRs focused on one concern — don't mix refactoring with features.
- Keep PRs under 600 LOC. Shift-left rate degrades sharply above this. Split larger features into 2-3 PRs.
- Tests required for every feature and bug fix. Docs-only or config PRs may skip with justification.
- Commit messages: complete sentences with periods.
- Sort config files (.env.example, etc.) alphabetically.
- Never commit secrets, API keys, or credentials. Use environment variables.
- For projects with releases, follow semantic versioning (MAJOR.MINOR.PATCH).
- Issue lifecycle: include `Closes #N` in PR commit messages. For multi-PR issues, close manually after the last PR merges.
- Post-merge: automatically run `/post-mortem [PR-number]` in the background.

## Development Flow (Numbered Steps)

Every feature/fix follows these steps. The orchestrator announces step transitions to the user. If the team isn't running, the main agent prints step numbers directly.

| Step | Name | What happens |
|------|------|-------------|
| 1 | **Plan** | Three sub-steps: clarifying questions (1a), write plan (1b), adversarial plan review (1c). |
| 2 | **Implement** | Write code on a feature branch. Follow project CLAUDE.md conventions. |
| 3 | **Test locally** | Run test suite, linter, type-checker. If UI changes, run Playwright testing. Fix failures. |
| 4 | **Code review loop** | Auto-run after step 3. Skip ONLY if user explicitly says to AND diff < 50 LOC. |
| 5 | **Push & create PR** | Push branch, `gh pr create`. Include `## Local Review` section in PR body. |
| 6 | **Post-merge** | Auto-run `/post-mortem [PR-number]` in background. |

> **Recording requirement:** When any step is skipped, record it in the PR body's Local Review section with the reason. Skipping without recording is a process violation.

### Orchestrator via Team Pattern (MANDATORY)

All dev flow work uses the three-role team pattern. No exceptions.

- **Orchestrator (team lead):** The main conversation agent. Creates team (`dev-<feature-slug>`), manages task list, prints status, enforces process. Does NOT write or review code.
- **Implementer:** `general-purpose` agent with `isolation: "worktree"`. Writes code, runs tests (Steps 2-3). Does NOT review its own code.
- **Critic:** `general-purpose` agent with fresh context. Runs ALL review steps (4a-4e). Receives ONLY the diff, checklist, and project CLAUDE.md — never implementation context.

**Key non-negotiable:** The implementer never reviews its own code. Post-mortem data proved author-reviewer identity collapse causes ~10% checklist execution rate. The critic's fresh context and opposing optimization target (finding problems vs. shipping) is what makes review effective.

**Full protocol** (sequencing, 9-task tracking table, communication flow, worktree interaction, error recovery, session teardown, "Stage Manager" personality, status message formatting, 5 orchestrator duties): see `~/.claude/knowledge/orchestrator-protocol.md`.

### Step 1: Plan (sub-steps)

#### Step 1a: Ask Clarifying Questions (includes product discovery)

Before writing any plan, read `~/.claude/knowledge/strategic-decisions.md` — prior product decisions provide context for whether a new idea aligns or diverges.

Then ask the user 2-4 clarifying questions. Don't accept the first framing — probe deeper.

- **Scope & intent.** "What's the core problem? What does success look like?"
- **Entry points & edge cases.** "Who hits this and how? What about [alternative path]?"
- **Constraints.** "Are there performance, cost, or timeline constraints I should know about?"
- **Prior art.** "Have you tried anything already? Is there a manual workaround today?"
- **Impact & alternatives.** "What changes if we DON'T build this? Is this a symptom of a deeper design gap?"

For GitHub issues or feature requests, also ask: "What were you doing when this came up?" and "What would you expect to happen instead?"

**Learning capture:** If the discussion clarifies a product instinct, decision framework, or reveals a delta between original design and actual usage, add it to `~/.claude/knowledge/strategic-decisions.md`. Product learnings capture *why* to build something, not *how*.

Wait for answers before proceeding to 1b.

#### Step 1b: Write the Plan

Write the plan using the user's answers. Read relevant knowledge files from `~/.claude/knowledge/`. Enumerate all entry points, trace each path end-to-end. For non-trivial work, enter plan mode.

Every plan must include a `### Knowledge Loaded` section listing:
- Which topic files from `~/.claude/knowledge/` were read (must align with INDEX.md's Stack Matching Guide).
- 1-3 relevant patterns from those files that informed the plan, with file attribution.

**Escape hatch:** Non-source-code changes (config, CI, docs) may use `### Knowledge Loaded: N/A — [justification]`.

#### Step 1c: Adversarial Plan Review (automatic after plan is written)

After Step 1b, spawn a separate `Plan` subagent to adversarially review. Fresh context — it sees only the plan and knowledge files. The reviewer checks:

- **Knowledge consumption verification.** Is the "Knowledge Loaded" section present with correct topic files per INDEX.md? Are patterns cited and connected to decisions? Verdict: "revise" if missing, wrong files, or no patterns.
- **Missed entry points.** Unaccounted user paths, edge cases, or state transitions?
- **Assumption challenges.** Unverified assumptions about existing code? Implicit dependencies?
- **Scope.** Too much for one PR, or missing something that forces a follow-up?
- **Alternative approaches.** Simpler or more robust way to achieve the same goal?
- **Risk flags.** Data loss, breaking changes, performance, security.
- **Knowledge file contradictions.** Does it contradict patterns from `~/.claude/knowledge/`?

**Product-level review:**
- Is this worth building? User impact vs. engineering cost?
- Lighter-weight alternatives (config changes, library features, UI tweaks) that achieve 80% of the value?
- How often will users hit this — daily pain or monthly inconvenience?
- Ship minimal now and iterate, or is the full plan necessary?
- Maintenance burden, user confusion, or irreversible design lock-in?

Verdict: **approve**, **approve with notes**, or **revise**. If "revise", address feedback and re-run. No round cap. If the same finding oscillates for 3+ rounds, escalate to the user for a tiebreaker.

### Step 3: Playwright Testing (mandatory for UI changes)

When the diff touches UI files (React components, CSS, HTML templates, frontend routes), run Playwright local testing.

**What qualifies:** Changes to `packages/web/`, frontend components, CSS/styling, or anything affecting rendered output.

**Procedure:**
1. **Start the dev server** in the background. "No dev server available" is NOT a valid skip reason. If it needs env vars, check `.env.example`. If it genuinely cannot start (missing external service with no mock), document the SPECIFIC blocker and use a static test harness.
2. Navigate to every page/view affected by the change.
3. Verify: no errors, changed elements render correctly, interactions work.
4. For conditional styling (feature flags, content variants), test each visual state.
5. Check browser console for new errors or warnings.
6. Run existing Playwright tests if present: `npx playwright test`.
7. **Stop the dev server.**

**Static test harness fallback:** For CSS interaction bugs, create a minimal HTML page with the component's markup/styles and test via `npx serve` or `page.setContent()`.

**Skip conditions:** Backend-only, CLI-only, or test-only changes. Record skip reason in PR body.

### Step 4: Code Review Loop (auto-run, mandatory for >= 50 LOC)

After step 3, the orchestrator spawns the critic agent for the review loop.

**LOC threshold — computed by script, not by judgment:**
```bash
git diff main...HEAD --stat | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+'
```
>= 50: mandatory, no exceptions. < 50: user may explicitly request skipping. The number is the number — no distinguishing "logic" from "tests."

**The critic runs these sub-steps sequentially:**

| Sub-step | Name | What happens |
|----------|------|-------------|
| 4a | **Code simplification** | Run `code-simplifier:code-simplifier` agent on changed files (vs main). |
| 4b | **Internal review** | Read the full diff for cross-file consistency, interface compliance, missed siblings. See details below. |
| 4c | **CodeRabbit review** | Run `coderabbit review --plain -t all --base main -c .coderabbit.yaml CLAUDE.md` (fall back to `/coderabbit:review --base main`). Fix critical/high findings. Re-run to confirm. |
| 4d | **Adversarial review** | Run the adversarial review checklist. May spawn focused subagents per file category. |
| 4e | **CI checks** | Run build, lint, test. If any sub-step produced fixes, re-run from 4c. Cap at 3 iterations. |

**Default to fix — no severity triage on local findings:**
Every finding MUST be fixed immediately. Do not classify as "low" or "non-blocking." A 5-minute local fix beats a 30-60 minute post-push round-trip. The ONLY valid deferral: "fixing this would change the PR's scope" — file a GitHub issue instead.

#### Step 4b: Internal Review (details)

Manual, line-by-line review of `git diff main...HEAD` focused on what automated tools miss.

**Check for:**
- **Cross-file consistency.** When a pattern is fixed in one file, grep for the same pattern in siblings.
- **Interface compliance.** Verify all implementations match full interface signatures. TS structural typing won't catch missing optional params.
- **Caller safety.** When error behavior changes (e.g., adding `throw`), trace all callers for the new error path.
- **Comment/code alignment.** Stale JSDoc, misleading inline comments, comments inside data structures.
- **Semantic correctness.** Values technically valid but semantically wrong (empty-string edge cases, off-by-one).

Fix all issues found, then proceed to 4c.

After the loop completes, report summary and proceed to Step 5. Step 4d writes the review marker to `~/.claude/review-markers/` — the pre-push hook checks this automatically.

### PR Body: Local Review Section

Include in every PR body:

```
## Local Review
- **Steps skipped:** none | list with reason (e.g., "3-Playwright: backend-only, 4a-4e: skipped")
- **Internal review findings:** N issues found, N fixed
- **CodeRabbit findings:** N issues found, N fixed (N iterations)
- **Adversarial review findings:** N issues found, N fixed
- **Playwright testing:** passed | N/A (no UI changes) | issues found and fixed
- **CI status:** all passed / failures fixed
```

This data feeds the self-improvement dashboard.

## Living Documentation

Documentation is organized **by feature**, not by type. Everything about a feature lives together.

### Directory structure

```
docs/
  product-spec.md              # overall product direction & roadmap
  features/
    <feature-name>/
      spec.md                  # feature spec (starts as proposal, evolves)
      mockups/                 # UI mockups (self-contained HTML)
      explainers/              # flow diagrams, architecture docs, tech docs
      decisions.md             # feature-scoped decisions
      bugs.md                  # feature-scoped bugs
      post-mortems/            # one file per PR/incident
    _cross-cutting/            # for things spanning multiple features
      decisions.md
      bugs.md
```

### Rules

- Create feature directories only when there's content — not for theoretical features.
- Specs start in `docs/specs/` during ideation, move to `docs/features/<feature>/spec.md` at implementation.
- Every PR should update relevant feature docs. Cross-cutting changes update `_cross-cutting/`.
- `product-spec.md` stays top-level as the bird's-eye view.
- QA entries go in the feature's `decisions.md`.

### Flow diagrams

For features spanning **3+ systems**, create `docs/features/<feature-name>/explainers/flow-diagram.html` via `/flow-diagram`.

- **Create when:** Crosses network boundaries or has non-obvious failure modes.
- **Skip when:** Single-component, simple CRUD, or UI-only.
- **Required sections:** Step-by-step flow, technologies & vendors (with doc links), security notes (if applicable), failure mode table.

## Adversarial Review (run by the critic, not the implementer)

Step 4d is run by the **critic** agent — a separate teammate with a fresh context window. The critic receives a deliberately limited context (see `~/.claude/knowledge/orchestrator-protocol.md` "Critic's Fresh Context" for exact inputs/exclusions). This separation is mandatory — the implementer reviewing its own code has ~10% checklist execution rate.

The review is **targeted, not exhaustive** — classify changed files by category (async, routes, DB, UI, LLM, shell, config, test-only) and run only the matching checklist sections. See `~/.claude/knowledge/adversarial-review.md` for the category-to-tier mapping.

**Critic subagent parallelization:** For PRs touching 3+ file categories, spawn focused subagents — one per category — each running only the relevant checklist section. Each subagent returns PASS/FAIL/SKIP evidence; the critic aggregates, deduplicates, and fixes.

Universal checks (always apply):

- **Pattern siblings.** When fixing a bug class, grep the entire codebase. Same-file: fix now. Cross-module: file GitHub issues with `outside-diff` label.
- **Walk full access chains.** Check every dereference for null/undefined/nil — not just the first level.
- **Fire-and-forget contract.** Every async operation in fire-and-forget methods must be error-handled.
- **Error message specificity.** Add specific branches for edge cases — no generic fallthrough.
- **Architecture self-review.** For 100+ LOC or 3+ directories: right location, abstraction, boundary, scope? See adversarial-review.md Tier 4.
- **Structured evidence required.** For every checklist item, record `PASS: [evidence]`, `FAIL: [finding]`, or `SKIP: [reason]`. Evidence must be verifiable (grep output, file:line refs, caller lists) — not "looks fine."
- **Default to fix.** Same rule as Step 4 intro: fix every finding immediately. The only valid deferral: "outside the diff's scope" — file a GitHub issue.

## CodeRabbit Local Review Notes

Step 4c uses the CLI directly:

```bash
coderabbit review --plain -t all --base main -c .coderabbit.yaml CLAUDE.md
```

The `-c` flag feeds project instructions and CLAUDE.md to the reviewer. Fall back to `/coderabbit:review --base main` if no `.coderabbit.yaml` exists.

**Every project should have a `.coderabbit.yaml`** with:
- `profile: "assertive"` — catches issues the default "chill" profile skips.
- `path_instructions` — domain-specific guidance per file pattern.
- `knowledge_base.code_guidelines.filePatterns: ["CLAUDE.md"]` — feeds conventions to the reviewer.

- **Never skip CodeRabbit local.** If rate-limited, wait — don't skip. Skipping drops shift-left rates from ~80% to ~37%.
- **Review time:** 7-30+ minutes. Run in background when possible.
- **Minor style suggestions** can be skipped if they conflict with project conventions.

## Code Quality

- Module-level doc headers on all top-level files.
- Early return before dead computation.
- Use context-appropriate messages, not generic copy-paste.
- Store computed results alongside display text — don't re-derive.
- Fix under-5-line issues now — only defer fixes needing new infrastructure.
- Register global error handlers on long-running services — per-request handling alone is insufficient.
- Log errors with reproduction context (request ID, user ID, operation) but never secrets or PII.
- When conditional logic for a mode/variant appears in 2+ components, extract to a shared utility immediately.

## Defensive Coding

- Scope data access to the authenticated user — never trust client-provided IDs to be globally unique.
- Trim and validate user input at the earliest pipeline entry point. Remember: whitespace-only strings are truthy in JS — guard on `!text.trim()` not `!text`.
- Guard every index mapping: bounds-check user-provided numbers against array length.
- Graceful degradation at every layer: independent error handling around each operation.
- Error messages should be specific and actionable, not generic fallthrough.
- Schema changes need migration reminders — schema files are documentation, not deployment, without an automated runner.
- When two queries feed separate display sections and can overlap, filter by authoritative state rather than cross-referencing result sets.
- Catch blocks: only return defaults (`[]`, `null`) for *expected* errors (not found, empty result). Unexpected errors (connection failure, syntax error) must propagate — `catch { return [] }` masks real outages.

## Planning Requirements

Every feature plan must:
- Enumerate ALL entry points (new vs resume, create vs update, empty vs populated state).
- Trace each path end-to-end: data read, state changed, API calls fired, UI rendered.
- Verify bidirectional state coverage: all values of state A produce correct behavior B.
- Answer: "If a user hit this feature after [alternative entry point], what would happen?"
- **Include a "Performance & Cost Impact" section** covering: (1) latency impact per affected user action, (2) new external API calls introduced and per-call cost, (3) new DB query load, (4) frequency of the affected code path (once/day vs. every user click), (5) mitigations if impact is non-negligible.

## Testing

- Test every type/feature combination, not just the happy path.
- When a component has conditional UI branches (e.g., `isNightNurse`), write at least one test per branch — don't only test the default path.
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

## Cross-Project Knowledge & Learning Capture

A shared knowledge base lives at `~/.claude/knowledge/` with topic-organized learnings from ALL projects.

**When planning or starting significant work:**
1. Read `~/.claude/knowledge/INDEX.md` for available topics.
2. Load topic files matching the project's stack (see INDEX.md's Stack Matching Guide).
3. Apply relevant patterns during implementation.

This is not optional. Skipping means repeating bugs already solved elsewhere.

**Proactive capture — add to the appropriate `~/.claude/knowledge/*.md` topic file when you encounter:**
- A bug pattern that could recur in other projects.
- A general preference (not project-specific) for tools, workflow, or communication.
- A defensive coding pattern discovered through a bug fix.
- A product/strategic decision or instinct → `strategic-decisions.md`.

**At PR time (during adversarial review), verify:**
1. Are there new cross-project patterns to capture in `~/.claude/knowledge/`?
2. Have project `docs/` (bugs, decisions) been updated?
3. If a bug was fixed, would the same class exist in a sibling project? If yes, capture the pattern.

---

# When Applicable: TypeScript / JavaScript

- Don't mark functions `async` unless they `await` something.
- Exhaustive `never` checks should throw, not return — fail fast on unhandled types.
- When adding a new value to a type union, grep the ENTIRE codebase for every switch/conditional that maps that type to a style, label, color, or behavior. Each consumer needs explicit handling — fallthrough to default produces wrong results.
- Fire-and-forget operations MUST have `.catch()` handlers to prevent unhandled rejections. Inside those methods, each `await` needs its own try/catch — a single outer try/catch means one failure skips all subsequent awaits.
- Runtime arrays derived from TS types need "keep in sync" comments (types erased at runtime).
- Build tools (@types, typescript, vite, tsx, vitest) in devDependencies.
- npm workspaces use `*` not `workspace:*` (that's pnpm/yarn).
- Full object assertions in tests, not `objectContaining`, unless partial matching is intentional.
- `new Date("2026-02-14T10:00:00")` without `Z` suffix parses in local timezone, making tests flaky on CI. Always use `new Date("2026-02-14T10:00:00Z")`.
- Negative async assertions ("should NOT have been called") need settle time — polling helpers (waitFor) pass immediately for negatives. Use a timeout to let promises settle first.

# When Applicable: Web UI

- Explicit `type` on every `<button>`: `type="button"` (default) or `type="submit"` (forms only).
- When a hook returns `{ data, loading, error }`, ALWAYS destructure and render the `error`. Silently ignoring errors creates invisible failures.
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
