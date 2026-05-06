# Development Steps — Detailed Procedures

Loaded on demand by the orchestrator during the dev flow. CLAUDE.md has the step table; this file has the procedures.

## Step 1: Plan (sub-steps)

### Step 1a: Ask Clarifying Questions (includes product discovery)

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

### Step 1b: Write the Plan

Write the plan using the user's answers. Read relevant knowledge files from `~/.claude/knowledge/`. Enumerate all entry points, trace each path end-to-end. For non-trivial work, enter plan mode.

Every plan must include a `### Knowledge Loaded` section listing:
- Which topic files from `~/.claude/knowledge/` were read (must align with INDEX.md's Stack Matching Guide).
- 1-3 relevant patterns from those files that informed the plan, with file attribution.

**Escape hatch:** Non-source-code changes (config, CI, docs) may use `### Knowledge Loaded: N/A — [justification]`.

### Step 1c: Adversarial Plan Review (automatic after plan is written)

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

## Step 2: Implement (sub-steps)

### Step 2a: Functional Implementation

Write code on a feature branch for correctness. Focus on:
- Business logic and data flow.
- Making tests pass.
- Following project CLAUDE.md conventions.

This is the "make it work" pass. Do not optimize for hardening concerns yet — get the feature correct first.

### Step 2b: Hardening Pass

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

## Step 3: Playwright Testing (mandatory for UI changes)

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

## Step 4: Code Review Loop (auto-run, mandatory for >= 50 LOC)

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

### Step 4b: Internal Review (details)

Manual, line-by-line review of `git diff main...HEAD` focused on what automated tools miss.

**Check for:**
- **Cross-file consistency.** When a pattern is fixed in one file, grep for the same pattern in siblings.
- **Interface compliance.** Verify all implementations match full interface signatures. TS structural typing won't catch missing optional params.
- **Caller safety.** When error behavior changes (e.g., adding `throw`), trace all callers for the new error path.
- **Comment/code alignment.** Stale JSDoc, misleading inline comments, comments inside data structures.
- **Semantic correctness.** Values technically valid but semantically wrong (empty-string edge cases, off-by-one).

Fix all issues found, then proceed to 4c.

After the loop completes, report summary and proceed to Step 5. Step 4d writes the review marker to `~/.claude/review-markers/` — the pre-push hook checks this automatically.

## Step 5: Push & Open PR

Before `git push`, run:

```
git -C <worktree> fetch origin main --quiet
git -C <worktree> rev-list --count HEAD..origin/main
```

If the count is non-zero, `origin/main` advanced while you were working — **rebase before pushing**:

```
git -C <worktree> rebase origin/main
```

**Why this matters.** When the branch's base falls behind, `git diff origin/main..HEAD` reports phantom deletions for files modified in PRs that merged during your work, even though your branch never touched them. The PR diff on GitHub shows the same phantom changes, and the critic will flag them as scope creep. Real-world signal from second-brain (2026-05-06): two of three PRs in a single session — #602 (#603 had merged during work, removing `.brand { line-height: 1 }` from the diff) and #614 (#610 had merged during work, removing `EntryFeed.test.tsx` from the diff) — required rebase-after-the-fact when the critic caught the spurious diff. Catch it before push instead.

If rebase produces conflicts that aren't trivial (one-line whitespace, import ordering), stop and review — your branch may genuinely conflict with newly-merged work.

After rebase, push with `-u` and open the PR. The body must use the project's `PULL_REQUEST_TEMPLATE.md` if present, including the `Steps skipped:` line and `## Performance & Cost Impact` section.

## PR Body Templates

### Local Review Section

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

### Step Timing Section

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
