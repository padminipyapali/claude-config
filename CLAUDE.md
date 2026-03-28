# ORCHESTRATOR TEAM PATTERN — REQUIRED FOR ALL CODE CHANGES

**ALL code changes use the 3-role team pattern. NO EXCEPTIONS.**
- This agent is the **orchestrator**. It does NOT write or review code directly.
- Spawn an **implementer** (`general-purpose`) to write code. **Create the worktree manually first** (see below), then spawn WITHOUT `isolation: "worktree"`.
- Spawn a **critic** (`general-purpose`, fresh context) to review code.
- If you catch yourself editing files or running tests directly, STOP — delegate to the team.
- Full protocol: `~/.claude/knowledge/orchestrator-protocol.md`

**Worktree rule:** Never use `isolation: "worktree"` on the Agent tool — it creates a worktree from CWD, which fails when CWD isn't the target repo. Instead:
1. Pre-create: `git -C /path/to/repo worktree add .claude/worktrees/<name> origin/main -b <branch>`
2. Spawn agent WITHOUT `isolation`, passing the full worktree path in the prompt.
3. Agent works directly in the pre-created worktree.

---

# Global Claude Code Rules

These rules apply to every project. Project-specific CLAUDE.md files supplement and can override these.

Stack-specific sections (marked "When Applicable") apply only when the project uses that technology.

**Precedence**: When rules conflict: project CLAUDE.md > global CLAUDE.md > knowledge files > project memory.

---

## Session Start Protocol

On EVERY session start — including continuations from previous sessions — run these checks before any code changes:

0. **Orchestrator mode.** All code changes go through the 3-role team pattern (orchestrator/implementer/critic). Spawn `dev-<slug>` team before ANY implementation. See top of this file and `~/.claude/knowledge/orchestrator-protocol.md`.
1. **Repo conflict detection.** For each repo you plan to modify, run:
   - `git -C <path> status --porcelain` — check for uncommitted changes.
   - `ps aux | grep -E 'claude|claude-code' | grep -v grep | grep '<path>'` — check for active agents.
   - `ls <path>/.git/index.lock 2>/dev/null` — check for git lock files.
   If ANY check returns positive: do NOT make code changes (read-only analysis is fine). Tell the user what was detected and queue the task in `~/.claude/task-queue.md` with: `[PENDING]` title, repo path, date, context, and detection details.
2. **Check the task queue.** If `~/.claude/task-queue.md` has `[PENDING]` entries, re-run detection for each repo. If free, prompt the user to execute. Mark completed `[DONE]` with date. Prune entries older than 7 days.
3. **Do NOT trust continuation summaries about repo state.** Verify it yourself — other agents may have started, files changed, branches moved.
4. **Development cycle checkpoint.** Before creating a PR, verify which dev cycle steps (1, 2a, 2b, 3, 4a-4e, 5) were completed in the *current* session.
5. **Never merge a PR without explicit user approval.** Creating the PR is step 5. The user decides when to merge.
6. **Project infrastructure check.** If the project has no `CLAUDE.md`, run `/project-setup` before any code changes. A project with code but no CLAUDE.md is un-initialized.

This is non-negotiable. Skipping caused concurrent agent conflicts and PRs shipping without review.

## New Projects

When creating a new project or initializing a new codebase, always run `/project-setup`. Never skip this.

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
- **Post-mortem metric integrity.** `/post-mortem` must compute `adversarialCatchRate` from evidence or mark `"unmeasured"` — never hardcode. 130+ PRs had fabricated baselines.

## Convention Complexity Budget

Hard cap: **10 universal manual conventions** maximum. These are conventions requiring manual judgment that apply to EVERY PR regardless of file type. Category-gated checks (Tier 1-4 in adversarial-review.md, which only fire when matching file categories are detected) are outside this budget.

**Current universal manual conventions (10/10):**
1. Sibling sweep — when fixing a bug or pattern, grep the codebase for the same pattern in siblings.
2. Enumerate ALL entry points in plans (new vs resume, create vs update, empty vs populated).
3. Walk full access chains — check every dereference for null/undefined, not just the first level.
4. Caller safety — when error behavior changes (adding throw), trace all callers for the new error path.
5. Default to fix — every local finding must be fixed immediately. No severity triage or deferrals.
6. Tests required — cover every type/feature combination, not just the happy path.
7. Fire-and-forget try/catch granularity — each await inside fire-and-forget methods needs its own try/catch.
8. New union member completeness — grep all switches/maps/conditionals when adding a value to a type union.
9. Error message specificity — edge cases get specific messages, not generic fallthrough.
10. Structured evidence required — PASS/FAIL/SKIP with verifiable evidence per checklist item (no "looks fine").

**Process for changes:** To add a convention, retire or automate an existing one. Grep-expressible conventions should be promoted to Tier 0 automated checks. Low-frequency conventions (score <= 6) should be demoted to knowledge files. See [command-center#56](https://github.com/padminipyapali/command-center/issues/56) for the full ranked list.

## Development Flow (Numbered Steps)

Every feature/fix follows these steps. The orchestrator announces step transitions to the user. If the team isn't running, the main agent prints step numbers directly.

| Step | Name | What happens |
|------|------|-------------|
| 1 | **Plan** | Clarifying questions (1a), write plan (1b), adversarial plan review (1c). |
| 2 | **Implement** | Single pass on a feature branch. Correctness, validation, error handling together. |
| 3 | **Test locally** | Build, lint, type-check. If UI changes, Playwright testing. Fix failures. |
| 4 | **Local review** | `/simplify` (4a) + CodeRabbit CLI (4b) + adversarial review (4c). Fix all findings. |
| 5 | **Push & create PR** | Push branch, `gh pr create`. No `/review-fix-loop` — local review is the gate. |
| 6 | **Post-merge** | Auto-run `/post-mortem [PR-number]` in background. |

**What's intentionally NOT in this flow:** Separate hardening pass (2b), internal line-by-line review, GitHub CodeRabbit reviews, CI verification loop, hardening checklist artifact. These were over-engineered for solo development. The local review (Step 4) catches the same issues faster.

**Step 4 detail:** Run sequentially: (4a) `/simplify` on changed files, (4b) `coderabbit review --plain -t all --base main` via CLI, (4c) adversarial review checklist. Fix all findings between each. If CodeRabbit CLI times out, retry once with 2-min backoff — don't skip.

> **Details:** See `~/.claude/knowledge/development-steps.md` for full sub-step procedures and PR body templates.

> **Team pattern:** See `~/.claude/knowledge/orchestrator-protocol.md`. The implementer never reviews its own code — author-reviewer identity collapse causes ~10% checklist execution rate.

> **Adversarial review, outside-diff triage, cleanup sweeps:** See `~/.claude/knowledge/review-and-triage.md`.

> **Living documentation:** See `~/.claude/knowledge/living-documentation.md`.

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
- **Include a "Performance & Cost Impact" section** — latency, new API calls + cost, DB query load, code path frequency, mitigations.

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

The `~/.claude/` directory is a git repo (`claude-config`). Whenever you modify any file in `~/.claude/`, commit and push before the session ends. Do this automatically — don't ask for confirmation.

## Cross-Project Knowledge & Learning Capture

A shared knowledge base lives at `~/.claude/knowledge/` with topic-organized learnings from ALL projects.

**When planning or starting significant work:** Read `~/.claude/knowledge/INDEX.md`, load topic files matching the project's stack (see INDEX.md's Stack Matching Guide), and apply relevant patterns. This is not optional — skipping means repeating bugs already solved elsewhere.

**Proactive capture** — add to `~/.claude/knowledge/*.md` topic files when you encounter: recurring bug patterns, general workflow preferences, defensive coding patterns, or product decisions (`strategic-decisions.md`).

**At PR time**, verify: (1) new cross-project patterns to capture? (2) project `docs/` updated? (3) bug class exists in sibling projects?

---

# When Applicable: TypeScript / JavaScript

> Full patterns: `~/.claude/knowledge/typescript-patterns.md`, `testing-patterns.md`

- Don't mark functions `async` unless they `await` something.
- Exhaustive `never` checks should throw, not return — fail fast on unhandled types.
- When adding a new value to a type union, grep the ENTIRE codebase for every switch/conditional that maps that type. Each consumer needs explicit handling.
- Fire-and-forget operations MUST have `.catch()` handlers. Inside those methods, each `await` needs its own try/catch.
- `new Date("2026-02-14T10:00:00")` without `Z` suffix parses in local timezone, making tests flaky on CI.

# When Applicable: Web UI

> Full patterns: `~/.claude/knowledge/react-patterns.md` (UI Patterns section)

- Explicit `type` on every `<button>`: `type="button"` (default) or `type="submit"` (forms only).
- When a hook returns `{ data, loading, error }`, ALWAYS destructure and render the `error`.
- CSS viewport units (`dvh`/`svh`/`lvh`) don't account for virtual keyboards on mobile. Use the `visualViewport` API.

# When Applicable: React Native

- FlatList memoizes renderItem aggressively. External state used in renderItem MUST be passed via `extraData`.

# When Applicable: Databases (SQL)

> Full patterns: `~/.claude/knowledge/database-patterns.md`

- Enforce invariants at DB level with triggers, not application code.
- Bidirectional enforcement: guard both child INSERT and parent UPDATE.
- Never use OR in WHERE clauses that defeat index usage — split into two queries.
- Index leading columns must match WHERE clause order. Composite PK (A,B) only indexes queries by A.
- SQL constraints and application-level type unions must stay in sync. Document which is source of truth.

# When Applicable: LLM Integration

> Full patterns: `~/.claude/knowledge/llm-integration.md`

- Always strip markdown code fences before parsing LLM output as structured data.
- Always validate/filter LLM structured output against the source of truth before sending to clients.
- Separate user-provided content from system instructions to prevent prompt injection.

# When Applicable: Firebase / Firestore

> Full patterns: `~/.claude/knowledge/firebase-patterns.md`

- Wildcard security rules can hide permission gaps — use specific subcollection rules for fine-grained permissions.
- Test security rule changes across every role/account type defined in the app.
- Indexed lookups (subcollection references) over full-collection scans for permission checks.

@RTK.md
