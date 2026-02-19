# Post-Mortem: command-center PR #23 — Add coding sessions to Activity view

**Branch:** feat/activity-sessions → main | **Author:** padminipyapali | **0.4h elapsed**
**Size:** +1214 -72 across 11 files, 3 commits

## Local Review (pre-push)

- **CodeRabbit:** not tracked (skipped local review loop)
- **Adversarial:** not tracked (skipped local review loop)
- **Shift-left rate:** 0% — all issues found post-push

## Step Compliance

- **Steps run:** 2 (implement), 3 (test), 5 (push+PR) — 3/8
- **Steps skipped:** 1a-1c (plan approved separately), 4a-4d (review loop) — "plan approved separately; review loop skipped"
- **Compliance rate:** 37.5%
- **Skip assessment:** **bad** — CodeRabbit found 8 issues post-push that the review loop (steps 4a-4d) would have caught. The adversarial review step alone would have caught at least 3 (off-by-one, null guards, loading state gate).

## Review Friction (post-push)

- **Review rounds:** 2 (2 CHANGES_REQUESTED from CodeRabbit bot)
- **Comments:** 8 inline (all from coderabbitai[bot]), 0 human
- **Categories:** correctness: 5, architecture: 1, style: 1, testing: 1
- **Timeline:** created → first review: 6min | first review → merge: 17min | total: 23min
- **Self-merge:** Yes — no human peer review (bot reviews only)

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 37.5% (3 of 8 issues covered by checklist)
- **Covered but missed:**
  - Off-by-one `>` vs `>=` (Tier 3: boundary value checks)
  - Unguarded `repo.mergedPrs.nodes` null access (Tier 1: walk full access chains)
  - Missing `sessionsLoading` in loading gate (UI: destructure all hook fields)
- **Not covered (new categories):**
  - Fractional minute display formatting
  - Non-unique React keys across repos (PR number collision)
  - Missing focus-visible on interactive elements
  - GraphQL ordering mismatch (UPDATED_AT vs CREATED_AT)
  - Repeated day group label key collision
- **Fix commits:** 2 of 3 total (67% fix-up ratio) — HIGH

## Planning Quality

- **Description:** complete (Summary, Architecture, Test Plan, Local Review sections)
- **Scope:** clean — focused on one feature, no scope creep
- **Branch lifetime:** 23 minutes
- **Planning checklist:** plan was approved separately (pre-PR step 1 done in plan mode)

## Code Quality Signals

- **Recurring issues:** correctness (5 comments) — dominant category, all around boundary conditions, null safety, and data integrity
- **Fix-up ratio:** 67% — HIGH, indicates adversarial review would have been valuable
- **New patterns captured:** boundary test coverage, GraphQL null guards, hook loading state, utility duplication divergence, truncation flags

## Process Efficiency

- **Automation opportunities:** All 8 issues were catchable by local review (adversarial + CodeRabbit). Running the review loop pre-push would have eliminated both fix-up rounds.
- **Iteration:** high friction (2 rounds of bot review)
- **CI status:** all passed (build + 123 tests after fixes)

## Recommendations

1. **Don't skip the review loop (steps 4a-4d).** This PR demonstrates the cost: 67% fix-up ratio, 2 review rounds. The ~15 minutes spent on 2 fix rounds would have been ~10 minutes running the review loop once pre-push.
2. **Run adversarial review even on "clean" PRs.** The off-by-one and null guard issues are exactly what the adversarial checklist catches. Skipping it on a 1200+ LOC PR was the wrong call.
3. **Extract utilities immediately, don't copy.** The `getDayLabel` duplication with divergent behavior was caught by the adversarial review but wouldn't have existed if the shared utility was created from the start.
