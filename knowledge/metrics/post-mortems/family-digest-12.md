# Post-Mortem: family-digest PR #12 — PR 2c: Telegram draft + CLI approve/edit/cancel

**Branch:** `feat/pr2c-telegram-bot` -> `main`
**Author:** padminipyapali
**Created:** 2026-04-28 20:42:19 UTC
**Merged:** 2026-04-28 21:00:15 UTC (self-merge)
**Duration:** ~17.9 minutes (open -> merged)
**Size:** +2471 / -277 across 22 files, 9 commits

## Summary

Fourth implementation PR of the v0 family-digest stack. Adds the Telegram-driven draft/approve/edit/cancel loop on top of the PR 2b pipeline: a send-only Telegram client (no `getUpdates`, second-brain owns polling), a JSON-file state store with atomic writes and ISO `weekKey`, an LLM-applied edit module that preserves the structured weekend section verbatim and reuses the hallucination guard, a shared `pipeline.ts` helper extracted from `friday.ts`, and a rewritten CLI with five subcommands (`draft`, `show`, `edit`, `approve`, `cancel`). 66 new tests bring the suite from 147 to 213. Source ~1,227 LOC, declared over the 600-LOC cap with drivers itemised in the PR body. Self-merged ~18 minutes after open with no peer reviews and no CI checks. Adversarial review caught 2 substantive issues pre-push (missing CLI tests, weekKey year-boundary asserted on format only) — both fixed in a single cycle before push.

## Local Review (pre-push)

- **CodeRabbit:** not tracked. No `## Local Review` section in PR body; CodeRabbit CLI was not invoked. Fourth consecutive PR with this gap (PRs #1, #3, #4 all skipped). Recommendation drift now spans four PRs.
- **Adversarial:** 2 findings, 2 fixed in one cycle. Both are explicitly named in the PR body Test plan: "missing CLI tests" (commit 8: `Test runCli subcommand dispatch and error paths.`) and "weekKey year-boundary asserted on format only" (commit 9: `Assert exact weekKey values across ISO year boundary.`).
- **Shift-left rate:** 100% of known issues caught locally; 0 post-push findings.

## Step Compliance

- **Step compliance:** not tracked (PR body has no `Steps skipped:` line). Fourth consecutive PR without compliance tracking.
- **Inferred from PR body:** Step 1 (plan implied — multi-PR sequencing 2a/2b/2c continues; PR explicitly carves out 2d work), Step 2 (implement), Step 3 (`tsc --noEmit` + `vitest run` 213/213 + `eslint` clean per Test plan), Step 4c (adversarial review APPROVE after one fix cycle), Step 5 (push+PR). No evidence of Step 4a (`/simplify`) or Step 4b (CodeRabbit CLI).
- **Skip assessment:** neutral — no post-push review happened, so we cannot confirm whether `/simplify` or CodeRabbit would have caught additional issues. The pipeline extraction from `friday.ts` into `scheduler/pipeline.ts` (a deliberate de-duplication move) is exactly the class of refactor `/simplify` exists to suggest; here the author did the extraction unprompted, demonstrating that the gap can be papered over by author discipline but is not closed.

## Step Timing

Not tracked (no `## Step Timing` section in PR body). The 18-minute open-to-merge window is the tightest in family-digest history (PR #1: ~6h, #3: ~1.7 min from a draft, #4: ~61h). The compressed window suggests the author had already completed local review/test cycles before opening the PR; the GitHub PR record is essentially a publish step here.

## Review Friction (post-push)

- **Review rounds:** 0. No reviewers assigned; `reviewDecision` empty; `reviews: []`; `comments: []`; inline comments empty.
- **Comments:** 0 inline, 0 general.
- **Categories:** all zero.
- **Timeline:** created 2026-04-28 20:42:19Z -> merged 2026-04-28 21:00:15Z (~17.9 min elapsed). No peer review gate applied. Self-merge by author.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 100% (2/2 substantive issues caught pre-push; 0 escaped to post-push review).
- **Covered and caught:**
  - Missing CLI tests for the new subcommand dispatcher (Tier: testing — every new entry point needs at least one happy-path + one error-path test). Aligns with the Testing checklist's "test every type/feature combination."
  - `weekKey` ISO year-boundary asserted on format only, not on exact values (Tier: correctness / date-arithmetic edge cases on boundary days, plus testing — assert all side effects, not just the primary return value). Aligns with the recurring date-and-timezone defensive-coding cluster in `process-patterns.md` and the `typescript-patterns.md` rule "`new Date(...)` without `Z` parses local timezone."
- **Not covered (no new categories required):** none. Both findings map to existing checklist categories.

## Fix-up Metrics

- **Post-merge fix rate:** 0% (PR #12 is the most recent merged PR in the repo at post-mortem time; `gh pr list --state merged --search "fix"` returned only the previously merged fix PRs that all predate #12). No follow-up fix PR has landed against this feature area.
- **Pre-merge catch rate by step:**
  - 4a (simplify): 0 fixes (not run; the `pipeline.ts` extraction was author-initiated, not `/simplify`-driven)
  - 4b (CodeRabbit CLI): 0 fixes (not run)
  - 4c (adversarial): 2 fixes (commits 8 and 9: `Test runCli subcommand dispatch and error paths.`, `Assert exact weekKey values across ISO year boundary.`)
  - 4d (CI): 0 fixes (no CI configured)
  - post-push: 0 fixes
- **Pre-merge iteration count:** 1 (healthy; single adversarial fix cycle, both commits part of the same review pass per the Test plan).
- **Fix-up taxonomy:** test-quality 2 (both fixes strengthen the test suite — one adds missing coverage of the CLI dispatcher, the other tightens an existing assertion from format-only to exact-value). No validation, a11y, defensive-coding, correctness, dead-code, documentation, style, or infrastructure fixes.
- **Legacy fix-up ratio:** 22.2% (2 fix / 9 total commits). Lowest in family-digest history (PR #1: n/a, PR #3: 28.6%, PR #4: 37.5%). Caveat unchanged: fix commits land individually rather than squashed into the commits they amend; iteration count (1) remains the more meaningful signal.

## Planning Quality

- **Description:** complete — Summary by file, "New CLI surface" code block, "New modules" itemisation, explicit `State machine` description, `Env` section listing the three new vars (one with the negative-chat-id caveat), `Test plan` checkboxes (4/4 checked including the adversarial cycle), explicit `Performance & cost` section quantifying the new Sonnet 4.6 call (~2K in / ~1K out), explicit `What's NOT in this PR` carve-out enumerating five deferred items, and the 600-LOC overrun declared with five named drivers (state schema, atomic store, edit module, full CLI, pipeline extraction). This is the most thorough PR body in family-digest history.
- **Scope:** clean — five tightly-coupled modules (telegram, state, edit, pipeline extraction, CLI rewrite) land together because the CLI requires all of them to dispatch any subcommand. No scope creep, no redesign indicators in commit history. Commit titles are sequential and topical (Telegram → state → edit → pipeline → scheduler → CLI → env → tests → tests).
- **Branch lifetime:** ~17.9 min open-to-merge. The pre-PR work (authoring 9 commits + adversarial fix cycle locally) happened on the branch before the PR was opened — the published PR window is essentially a "click merge" step.
- **Planning checklist:** entry points enumerated explicitly via the five-subcommand CLI surface (each subcommand is its own entry point). `Performance & cost` section present and accurate. 600-LOC overrun declared with named drivers ("Size note" pattern continued from PR #4). `What's NOT in this PR` deferred-scope enumeration is new this PR and is a planning-quality improvement.

## Code Quality Signals

- **Recurring issues:** none across the 4-PR family-digest history. Adversarial review has caught 1 (PR #1), 4 (PR #3), 3 (PR #4), and 2 (PR #12) issues with 100% pre-push catch rate. The fix-up taxonomy has shifted from pure correctness (PR #4: 3 correctness fixes) to test-quality (PR #12: 2 test-quality fixes), suggesting the planning + correctness front is well-covered and the marginal find is now in test rigor.
- **New unrecorded patterns observed:**
  - **`What's NOT in this PR` deferred-scope section.** The PR body explicitly enumerates the five items intentionally deferred to PR 2d (Gmail send, HTML email, launchd auto-trigger, Telegram polling, etc.). This makes scope boundaries reviewable and prevents the reviewer from wasting cycles on "where's the email?" questions. Generalizable across any multi-PR feature sequence.
  - **Single-bot-token boundary protocol ("Path A — send-only via shared bot token").** The PR explicitly documents that `getUpdates` is owned by a different process (second-brain) to avoid Telegram's single-consumer constraint on `getUpdates`. This cross-process ownership boundary is a Telegram-specific gotcha that would otherwise cause silent message loss; capturing it once in shared knowledge prevents the next project from rediscovering it.
  - **State-machine display-only terminal states.** `approve` and `cancel` only update the Telegram message prefix (✅/✗); the body remains unchanged so the next pipeline stage (PR 2d's authoritative send) operates on stable state. This pattern — "user-visible state transitions that do not mutate the canonical payload" — is generalizable to any approve/edit/cancel flow that has a downstream consumer.
  - **Atomic JSON-file state store as a v0 substitute for a database.** The state store uses temp-file + rename for atomic writes, ISO weekKey for partition, and lives at `~/.family-digest/state.json`. Generalizable to any single-user CLI tool that needs durable state without operating a database. The atomicity primitive (write-temp-then-rename) is the load-bearing detail.

## Process Efficiency

- **Automation opportunities:**
  - The `## Local Review`, `## Step Compliance`, and `## Step Timing` sections remain absent for the fourth consecutive PR. The recommendation appears in PR #1, #3, and #4 post-mortems and remains unaddressed. Per process-patterns.md "recommendation drift" pattern, the next escalation is a project artifact, not another prose recommendation.
  - CodeRabbit CLI not invoked, fourth PR in a row.
  - No GitHub Actions CI configured (`statusCheckRollup: []`); fourth PR in a row. Local checks remain the only gate.
  - 18-minute open-to-merge window means even if a CI workflow existed, it likely would not finish before the merge — which suggests adding a CI workflow alone is insufficient; the merge gate must require the workflow to complete.
- **Iteration:** efficient (1 adversarial cycle, 0 post-push rounds).
- **CI status:** none configured. Local `tsc`, `vitest` (213/213), `eslint` clean per PR body.

## Risks & Observations

- **Self-merge with no peer review, fourth time.** Same posture as PRs #1, #3, #4. At this point self-merge without peer review is the project's de-facto policy; further "no peer review" callouts add no signal until the policy itself changes (solo project — peer review is unlikely to materialise).
- **Recommendation drift now confirmed across 4 consecutive PRs.** The PR-body template, CodeRabbit CLI, and CI workflow recommendations have been raised in 3 prior post-mortems and remain unimplemented. Per process-patterns.md, the next post-mortem-derived action must be a project artifact (PR template file committed; CI workflow committed; lint rule added), not another recommendation paragraph.
- **18-minute open-to-merge window outpaces any reasonable CI gate.** Even if CI is added, the merge gate must require checks to complete (not just be present); otherwise the workflow-exists/workflow-passes distinction collapses and CI becomes ornamental.
- **600-LOC exception declared but not enforced via process — second time.** PR #4 raised this; PR #12 demonstrates the same pattern (1,227 source LOC, drivers itemised, no automated gate). A `prSize > 600 && body !~ /Size note:|Scaffolding exception:/` check would close the loop.
- **Adversarial finding mix is shifting from correctness to test-quality.** PRs #3 and #4 found mostly correctness/planning bugs; PR #12 finds test-rigor gaps. This is a healthy maturation signal (the planning + correctness checklist is doing its job) but suggests the `/adversarial-review` skill might benefit from a dedicated "test rigor" sub-checklist (assertion specificity, error-path coverage, boundary-value coverage) rather than only the planning/correctness/architecture tiers.

## Recommendations (ranked)

1. **Convert the PR-body template recommendation into a committed artifact.** Four consecutive PRs without `## Local Review`/`## Step Compliance`/`## Step Timing` sections confirms prose recommendations do not stick on this project. Action: commit `.github/PULL_REQUEST_TEMPLATE.md` to family-digest with the three sections as scaffolded checkbox blocks. This is the single highest-leverage change carried forward from PR #4's post-mortem and is overdue.
2. **Add a minimal GitHub Actions CI workflow AND make it a required check.** Minimum: `tsc --noEmit` + `vitest run` + `eslint`. Crucially, configure the branch protection rule (or repository setting) so the workflow must complete before merge — otherwise an 18-minute open-to-merge window will skip CI even when it exists. PR #4's recommendation #3 had only the workflow half; this PR demonstrates the gating half is equally necessary.
3. **Add a "test rigor" sub-checklist to `/adversarial-review`.** With planning + correctness now well-handled, the marginal pre-push find is in test-quality (PR #12: 2/2 findings in this category). New checklist items: "Are exact values asserted (not just shape/format)?" "Is each new entry point covered by at least one error-path test?" "Are boundary conditions (year/month/day boundaries, empty inputs, max inputs) explicitly asserted?" Source: `~/.claude/knowledge/adversarial-review.md`.
4. **Capture the single-consumer-boundary pattern in shared knowledge.** The Telegram `getUpdates` ownership decision is a non-obvious cross-process boundary that another project (or the second-brain integration itself) could re-encounter. Add to `~/.claude/knowledge/llm-integration.md` or a new `external-api-patterns.md` file.
5. **Capture atomic-JSON-file state store as a reusable v0 pattern.** The temp-file + rename + ISO weekKey approach is a generalizable v0 substitute for a database in single-user CLI tools. Add to `~/.claude/knowledge/architecture-patterns.md` under a "v0 / single-user persistence" sub-section.

## Knowledge Updates

- `process-patterns.md`: strengthen the "recommendation drift" entry with a 4-PR confirmation: the same three recommendations (PR template, CodeRabbit CLI, CI workflow) have now appeared in four consecutive family-digest post-mortems without adoption. Promote the next mention from "recommendation" to "demand a project artifact." Source: post-mortem, family-digest #12, 2026-04-22.
- `process-patterns.md`: add new pattern under "Planning Quality" — "What's NOT in this PR" deferred-scope enumeration. When a feature ships across multiple PRs, explicitly listing items deferred to a later PR makes scope boundaries reviewable. Source: post-mortem, family-digest #12, 2026-04-22.
- `architecture-patterns.md`: add new pattern — atomic JSON-file state store (temp-file + rename, ISO weekKey partition) as a v0 single-user persistence primitive. Source: post-mortem, family-digest #12, 2026-04-22.
- `architecture-patterns.md`: add new pattern — display-only terminal states. State transitions (approve/cancel) that update user-visible markers without mutating the canonical payload, so a downstream stage can act on stable state. Source: post-mortem, family-digest #12, 2026-04-22.
- New external-API knowledge entry — Telegram bot single-consumer constraint on `getUpdates`. Document the cross-process ownership decision pattern (one process polls, others send-only). Source: post-mortem, family-digest #12, 2026-04-22.
- `adversarial-review.md`: add a "Test rigor" sub-checklist (exact-value vs format assertions, error-path coverage per entry point, boundary-value assertions). Source: post-mortem, family-digest #12, 2026-04-22.
