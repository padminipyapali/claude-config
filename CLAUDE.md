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
4. **Development cycle checkpoint.** Before creating a PR or merging, verify which dev cycle steps (1, 2a, 2b, 3, 4a-4e, 5) were completed in the *current* session. Walk through the 10 trackable steps explicitly.
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
- **Post-mortem metric integrity.** The `/post-mortem` command must never write hardcoded or estimated values for `adversarialCatchRate`. It must compute the actual rate from evidence (pre-push findings vs. post-push findings) or explicitly mark the field as `"unmeasured"`. Over 130 PRs had fabricated `adversarialCatchRate: 0.5` baselines — this corrupts the self-improvement dashboard and makes it impossible to detect real improvements or regressions.

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

**Process for changes:**
- To add a new universal convention, you must retire or automate an existing one.
- Category-gated checks (in adversarial-review.md) can be added freely since they only fire when relevant file types are touched.
- Conventions expressible as grep patterns should be promoted to Tier 0 automated checks.
- Low-frequency conventions (score <= 6) should be demoted to reference material in knowledge files.

**Initial audit:** See [command-center#56 comment](https://github.com/padminipyapali/command-center/issues/56) for the full ranked list of 123 conventions with Impact x Frequency scoring.

## Development Flow (Numbered Steps)

Every feature/fix follows these steps. The orchestrator announces step transitions to the user. If the team isn't running, the main agent prints step numbers directly.

| Step | Name | What happens |
|------|------|-------------|
| 1 | **Plan** | Three sub-steps: clarifying questions (1a), write plan (1b), adversarial plan review (1c). |
| 2a | **Implement (functional)** | Write code on a feature branch for correctness. Focus on business logic, data flow, making tests pass. |
| 2b | **Implement (hardening)** | Dedicated second pass: input validation, a11y, error handling, explicit else/default, dead code cleanup. Produces hardening checklist artifact. |
| 3 | **Test locally** | Run test suite, linter, type-checker. If UI changes, run Playwright testing. Fix failures. |
| 4 | **Code review loop** | Auto-run after step 3. Skip ONLY if user explicitly says to AND diff < 50 LOC. |
| 5 | **Push & create PR** | Push branch, `gh pr create`. Include `## Local Review` section in PR body. |
| 6 | **Post-merge** | Auto-run `/post-mortem [PR-number]` in background. |

> **Recording requirement:** When any step is skipped, record it in the PR body's Local Review section with the reason. Skipping without recording is a process violation.

### Orchestrator via Team Pattern (MANDATORY)

All dev flow work uses the three-role team pattern. No exceptions.

- **Orchestrator (team lead):** The main conversation agent. Creates team (`dev-<feature-slug>`), manages task list, prints status, enforces process. Does NOT write or review code.
- **Implementer:** `general-purpose` agent with `isolation: "worktree"`. Writes code, runs tests (Steps 2a-3). Does NOT review its own code.
- **Critic:** `general-purpose` agent with fresh context. Runs ALL review steps (4a-4e). Receives ONLY the diff, checklist, and project CLAUDE.md — never implementation context.

**Key non-negotiable:** The implementer never reviews its own code. Post-mortem data proved author-reviewer identity collapse causes ~10% checklist execution rate. The critic's fresh context and opposing optimization target (finding problems vs. shipping) is what makes review effective.

**Critic's context boundary — what it receives and what it must NOT receive:**
- **Receives:** `git diff main...HEAD`, the adversarial review checklist (`~/.claude/knowledge/adversarial-review.md`), the project's `CLAUDE.md`, and the Convention Complexity Budget section.
- **Must NOT receive:** Implementation conversation history, the implementer's reasoning, plan discussion, debugging context, or any message thread from Steps 1-3. The critic must form its own understanding from the diff alone.
- **Enforcement:** The orchestrator spawns the critic as a fresh `general-purpose` agent — not a subagent of the implementer's conversation. Passing implementation context to the critic (via message, task description, or shared state) is a process violation equivalent to skipping review.

**Full protocol** (sequencing, 10-task tracking table, communication flow, worktree interaction, error recovery, session teardown, "Stage Manager" personality, status message formatting, 6 orchestrator duties): see `~/.claude/knowledge/orchestrator-protocol.md`.

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

### Step 2: Implement (sub-steps)

#### Step 2a: Functional Implementation

Write code on a feature branch for correctness. Focus on:
- Business logic and data flow.
- Making tests pass.
- Following project CLAUDE.md conventions.

This is the "make it work" pass. Do not optimize for hardening concerns yet — get the feature correct first.

#### Step 2b: Hardening Pass

Dedicated second pass over ALL code written in Step 2a. This is a separate, explicit sweep — not something folded into 2a. Focus exclusively on:

1. **Input validation** — every `req.body`, `req.params`, `req.query` access, every user-provided argument. Trim, type-check, bounds-check.
2. **Accessibility** — `aria-*` attributes on interactive elements, keyboard navigation, focus management, semantic HTML.
3. **Error handling** — every async call has explicit error handling. No bare `await` without try/catch or `.catch()`. Fire-and-forget operations get per-await try/catch.
4. **Explicit else/default** — every conditional has an else branch or default case. Every switch is exhaustive. No silent fallthrough.
5. **Dead code and stale references** — remove unused imports, variables, functions, and stale comments left from iteration during 2a.

**Hardening checklist artifact:** At the end of Step 2b, produce a summary checklist that Step 4 can verify:

```
### Hardening Pass Checklist
- **Input validation:** [N] routes/endpoints checked, [N] guards added
- **Accessibility:** [N] interactive components checked, [N] attributes added
- **Error handling:** [N] async calls checked, [N] handlers added
- **Explicit else/default:** [N] conditionals checked, [N] branches added
- **Dead code cleanup:** [N] items removed
```

The critic (Step 4) verifies this checklist against the actual diff — claims without evidence are flagged.

### Step 3: Playwright Testing (mandatory for UI changes)

When the diff touches UI files (React components, CSS, HTML templates, frontend routes), run Playwright local testing.

**What qualifies:** Changes to `packages/web/`, frontend components, CSS/styling, or anything affecting rendered output.

**Procedure:**
1. **Start the dev server** in the background (`npm run dev`, `npx next dev`, or the project's equivalent — check `package.json` scripts). Wait for the "ready" message before proceeding. "No dev server available" is NOT a valid skip reason — every web project has a dev server. If it needs env vars, check `.env.example` and create a `.env.local`. If it genuinely cannot start (missing external service with no mock), document the SPECIFIC blocker (service name, error message) and use a static test harness instead.
2. Navigate to every page/view affected by the change.
3. Verify: no errors, changed elements render correctly, interactions work.
4. For conditional styling (feature flags, content variants), test each visual state.
5. Check browser console for new errors or warnings.
6. Run existing Playwright tests if present: `npx playwright test`.
7. **Stop the dev server** — do not leave it running. Kill the background process explicitly.

**Static test harness fallback:** When the dev server genuinely cannot start (document the specific error, not a generic excuse), create a minimal HTML page with the component's markup/styles and test via `npx serve` or `page.setContent()`.

**Skip conditions:** Backend-only, CLI-only, or test-only changes. Record skip reason in PR body.

**Recording requirement:** The PR body must include one of:
- `Playwright testing: passed` — with the dev server URL and pages tested.
- `Playwright testing: N/A (backend-only)` — with file list confirming no UI files.
- `Playwright testing: static harness used` — with the specific blocker that prevented the dev server.
- Never: `Playwright testing: skipped (no dev server)` — this is a process violation.

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
| 4a | **Code simplification** | Run `/simplify` on changed files (vs main). |
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
- **Hardening pass:** validation [N routes], a11y [N components], error handling [N services], else/default [N conditionals], cleanup [N items]
- **Internal review findings:** N issues found, N fixed
- **CodeRabbit findings:** N issues found, N fixed (N iterations)
- **Adversarial review depth:** N/M checklist items with grep evidence (Tier 0: N/N executed, Tier 1-4: N/M with evidence)
- **Playwright testing:** passed (URL, pages tested) | N/A (backend-only, file list) | static harness (blocker)
- **CI status:** all passed / failures fixed
- **Deferred items:** none | list of items deferred to CI (with justification)

## Fix-Up Metrics
- **Pre-merge catch rate by step:** 4a: N | 4b: N | 4c: N | 4d: N | post-push: N
- **Pre-merge iteration count:** N (1=healthy, 2=normal, 3+=friction)
- **Fix-up taxonomy:** { category: count, ... } (exclude infrastructure)
```

**Depth over compliance.** The adversarial review line records the number of checklist items that produced verifiable grep evidence out of the total applicable items — not just "ran/skipped." This distinguishes genuine execution (grep output logged, callers traced by file:line) from performative compliance (checklist read but items assessed by judgment). Post-mortem data shows PR #272 had 87.5% binary compliance but only 10% actual execution depth.

When the orchestrator team pattern is used, also include a **Step Timing** section:

```
## Step Timing
| Step | Duration | Notes |
|------|----------|-------|
| 1a-1c Plan | ~X min | |
| 2a Implement (functional) | ~X min | |
| 2b Implement (hardening) | ~X min | |
| 3 Test | ~X min | |
| 4a-4e Review | ~X min | bottleneck if applicable |
| 5 Push/PR | ~X min | |
| **Total** | **~X min** | |
```

This data feeds the self-improvement dashboard and post-mortem metrics.

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

**Two-phase execution:**
1. **Tier 0 (automated greps):** Run ALL Tier 0 grep checks mechanically and log exact output. These are pass/fail — no judgment required. See "Tier 0 Execution Protocol" in adversarial-review.md. The review marker cannot be written until Tier 0 execution is confirmed with logged output.
2. **Tier 1-4 (judgment items):** Run only the category-matched items, capped at 15-20 per PR (see "Checklist Item Cap" in adversarial-review.md). Every item must produce structured evidence with grep output or file:line references — not "looks fine."

**Critic subagent parallelization:** For PRs touching 3+ file categories, spawn focused subagents — one per category — each running only the relevant checklist section. Each subagent returns PASS/FAIL/SKIP evidence; the critic aggregates, deduplicates, and fixes.

Universal checks (always apply):

- **Pattern siblings.** When fixing a bug class, grep the entire codebase. Same-file: fix now. Cross-module: file GitHub issues with `outside-diff` label.
- **Walk full access chains.** Check every dereference for null/undefined/nil — not just the first level.
- **Fire-and-forget contract.** Every async operation in fire-and-forget methods must be error-handled.
- **Error message specificity.** Add specific branches for edge cases — no generic fallthrough.
- **Architecture self-review.** For 100+ LOC or 3+ directories: right location, abstraction, boundary, scope? See adversarial-review.md Tier 4.
- **Structured evidence required.** For every checklist item, record `PASS: [evidence]`, `FAIL: [finding]`, or `SKIP: [reason]`. Evidence must be verifiable (grep output, file:line refs, caller lists) — not "looks fine."
- **Default to fix.** Same rule as Step 4 intro: fix every finding immediately. The only valid deferral: "outside the diff's scope" — file a GitHub issue.

## Outside-Diff Triage Protocol

When the adversarial review (Step 4d) or pattern sibling checks (see "Pattern siblings" in Universal checks above) discover issues **outside the current diff**, follow this protocol instead of fixing them inline.

### Per-PR Budget

Each PR may include at most **50 LOC / 2 findings** of outside-diff fixes. Beyond that threshold, file GitHub issues — do not expand the PR's scope.

### Pattern Sibling Split

- **Same-file siblings:** Fix now (counts toward the per-PR budget).
- **Cross-module siblings:** File a GitHub issue with the `outside-diff` label. Do not fix in the current PR.

This refines the "Pattern siblings" universal check in the adversarial review section above. The universal check defines *what* to look for; this section defines *how much* to fix in-PR vs. defer.

### Severity Classification

| Severity | Criteria | Required Action |
|----------|----------|-----------------|
| **P0 — Critical** | Security vulnerability, data loss, or production crash reachable from the current change. | Fix immediately in this PR regardless of budget. Notify the user. |
| **P1 — High** | Bug that affects correctness for common user paths. Not gated by the current change but discovered during review. | Fix if within per-PR budget. Otherwise, file issue with `outside-diff` label and link in the PR body. |
| **P2 — Medium** | Code smell, missing edge-case handling, or inconsistency that doesn't affect current functionality. | File issue with `outside-diff` label. Do not fix in this PR. |
| **P3 — Low** | Style, naming, minor refactoring opportunities. | File issue with `outside-diff` label only if the pattern is systemic (3+ occurrences). Otherwise, skip. |

**P0 overrides the per-PR budget.** All other severities respect it.

### Integration with Review Steps

- **Step 4b (Internal review):** When cross-file consistency checks find siblings outside the diff, classify per this table before acting.
- **Step 4d (Adversarial review):** The critic records outside-diff findings with severity and disposition (`fixed-in-PR` or `issue-filed: #N`) in structured evidence.
- **PR body:** List all outside-diff issues in the Local Review section: severity, file, and disposition.

## Cleanup Sweep Cadence

Over time, `outside-diff` issues accumulate. This section establishes a scheduled cadence to resolve them systematically, preventing backlog growth.

### Trigger and Frequency

**Create a cleanup sweep PR when:**
- 3 feature/fix PRs have been merged since the last sweep (whichever comes first), OR
- 7 days have elapsed since the last sweep.

**Tracking:** Record the timestamp and PR count in a sweep log (e.g., `~/.claude/SWEEP_LOG.md`) to avoid manual date arithmetic.

### Scope and Prioritization

Cleanup sweeps target issues filed with the `outside-diff` label. Query the issue tracker sorted by severity.

**In each sweep, address:**
- **All P1 issues** (high-severity bugs affecting correctness for common user paths).
- **All P2 issues that fit within 400 LOC** (code smells, missing edge-case handling, inconsistencies). If a P2 issue requires >400 LOC, defer to the next sweep or break into smaller issues.

Do not attempt P3 (low-priority style/naming) issues in cleanup sweeps unless they are quick wins (<20 LOC).

### Branch Naming and Process

- **Branch name:** `chore/sweep-<YYYY-MM-DD>` (e.g., `chore/sweep-2026-03-07`).
- **Process:** Sweep PRs follow the standard development flow (Steps 1-5) but with one exception:
  - **Step 1c (Adversarial plan review) is skipped.** Cleanup sweeps are deterministic and low-risk — the plan is simply "resolve these N specific issues from the issue tracker." A separate plan reviewer is unnecessary.
  - Steps 2-5 proceed normally. Sweeps still require Step 3 (local testing), Step 4 (code review), and go through the full critic review pipeline (4a-4e).

- **PR body:** Include the same Local Review section and Step Timing section as standard PRs. Additionally, document:
  ```
  ## Sweep Summary
  - **P1 issues resolved:** [count] (issue numbers)
  - **P2 issues resolved:** [count] (issue numbers)
  - **Issues deferred:** [count] (reason or next sweep date)
  ```

### Metrics and Monitoring

Track and report the following monthly:
1. **Filed vs. resolved:** Issues filed with `outside-diff` vs. issues closed via cleanup sweeps.
2. **Average age:** Mean age of open `outside-diff` issues (from creation to current date).
3. **P1 latency:** Average time from filing to resolution for P1 issues. Target: under 3 days.

Review these metrics in post-mortems and quarterly retrospectives to detect backlog saturation or reviewer bottlenecks.

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
