# Post-Mortem: my_mind_evolved PR #297 — Remove research feature code

**Branch:** refactor/remove-research -> main
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Duration:** 1.23 hours (created 2026-03-01T04:55:35Z, merged 2026-03-01T06:09:24Z)
**Size:** +80 -5959 across 34 files, 3 commits

## Summary

Large-scale feature removal PR: deleted the incomplete async research feature (research service, routes, interceptor, UI components, hooks, API functions, CSS, types). Deleted 10 source/test files, edited 22 files. Preserved docs for future reference. Narrowed `CuratorSuggestionType` from 3 values to 2 (`MAKE_TODO`, `ADD_TO_IDEAS`; removed `PURSUE_EXPLORATION`).

## Local Review (pre-push)

- **CodeRabbit:** Skipped locally (rationale: "deletion-only PR, no new logic").
- **Adversarial review:** 20/20 checklist items reported with grep evidence (Tier 0: 4/4, Tier 1-4: 16/16). 1 finding (response.ts self-description mentioned "research"), 1 fixed.
- **Shift-left rate:** 33% (1 of 3 total fix-worthy issues caught locally).

## Step Compliance

- **Steps run:** 2a, 2b, 3, 4a, 4b, 4d, 5 (7/9)
- **Steps skipped:** 1a-1c (plan pre-approved in prior session), 4c (CodeRabbit skipped locally — deletion-only), 3-Playwright (N/A — all deletions)
- **Compliance rate:** 77.8%
- **Skip assessment:** **bad** — Skipping CodeRabbit locally (step 4c) directly resulted in 2 post-push findings from CodeRabbit that were in-scope for the adversarial checklist (Tier 4: "Type sync between SQL and TypeScript"). The adversarial review claimed 20/20 but missed the SQL/TS type mismatch that CodeRabbit caught. If CodeRabbit had been run locally, both issues would have been pre-push catches.

## Step Timing

Not tracked (no Step Timing section in PR body).

## Review Friction (post-push)

- **Review rounds:** 2 (2 CHANGES_REQUESTED from CodeRabbit bot before merge)
- **Comments:** 2 inline (CodeRabbit), 2 general (1 Vercel deploy, 1 CodeRabbit summary)
- **Human comments:** 0
- **Categories:** { correctness: 2 }
- **Timeline:**
  - Created -> first review: 0.08h (5 min)
  - First review -> merge: 1.15h
  - Total: 1.23h
- **Self-merge:** Yes, with bot-only review (no human peer review).

## Adversarial Review Effectiveness

### Pre-push catch potential: 0%

Both post-push findings were in-scope for the adversarial checklist but were missed:

1. **Covered but missed: Tier 4 "Type sync between SQL and TypeScript" (line 448 of adversarial-review.md).** The `CuratorSuggestionType` union was narrowed from 3 to 2 values, but the SQL CHECK constraint in `007-curator-suggestions.sql` still allows `PURSUE_EXPLORATION`. The adversarial review claimed 20/20 items with grep evidence but did not catch this mismatch. This item explicitly says: "CHECK constraints and unions match. Verify 'source of truth' comments agree on directionality."

2. **Covered but missed: Tier 4 "Migration-gated defensive filtering" (adjacent to type sync).** The removal of `PURSUE_EXPLORATION` from the TS union is a `value-removed` semantic tag, which auto-injects the forced question: "Where in the codebase is the removed value still referenced?" The adversarial review did not surface the SQL constraint as a reference point.

### Not covered (new categories): None

All findings map to existing checklist items.

## Fix-Up Metrics

### Commits

1. `Remove research feature code while preserving docs for future reference.` — **feature**
2. `Address PR review: document deliberate SQL/TS type mismatch.` — **fix** (post-push, responding to CodeRabbit comment 1)
3. `Address PR review: add migration to narrow CHECK constraint.` — **fix** (post-push, responding to CodeRabbit comment 2)

### Metrics

- **Post-merge fix rate:** 0.0% (PR #298 "Replace /todos inline buttons with dashboard link" is unrelated)
- **Pre-merge catch rate by step:**
  - 4a (simplify): 0 | 4b (internal): 1 fix (response.ts research mention) | 4c (CodeRabbit): 0 (skipped locally) | 4d (adversarial): 0 | post-push: 2 fixes
- **Pre-merge iteration count:** 2 (2 CHANGES_REQUESTED rounds, 2 fix commits)
- **Fix-up taxonomy:** { correctness: 1 (SQL constraint mismatch fix), documentation: 1 (SQL comment update) }
- **Legacy fix-up ratio:** 67% (2 fix / 3 total commits)

## Planning Quality

- **Description:** Complete — Summary, Test Plan, Local Review sections all present.
- **Scope:** Clean — deletion-only, no scope creep.
- **Branch lifetime:** 1.23 hours.
- **Planning checklist:** Partial — plan was pre-approved in prior session (step 1a-1c skipped). The pre-approved plan apparently did not flag the SQL/TS type sync concern for `CuratorSuggestionType`.

## Code Quality Signals

- **Recurring issues:** SQL/TS type sync (this is the 2nd occurrence — first was second-brain PR #191 which introduced the adversarial checklist item).
- **New unrecorded patterns:** None.

## Process Efficiency

- **Automation opportunities:**
  1. A Tier 0 automated grep for `value-removed` semantic tag could mechanically check SQL CHECK constraints vs. TS unions.
  2. The "skipping CodeRabbit for deletion-only PRs" heuristic proved wrong here — CodeRabbit caught what the adversarial review missed despite 20/20 claimed execution.
- **Iteration:** Normal (2 rounds, both mechanical fixes).
- **CI status:** All passed (build, lint, 989 tests).

## Key Findings

1. **"Deletion-only" is not a valid reason to skip CodeRabbit.** This PR removed a type union member (`PURSUE_EXPLORATION`) and narrowed `CuratorSuggestionType`. That's a semantic change, not just file deletions. The adversarial review's 20/20 claim masked a real gap (SQL/TS type sync), and CodeRabbit's scripts-based analysis caught it. Lesson: skip CodeRabbit only for truly non-functional changes (README updates, comment-only edits). Any diff touching type definitions or database schema should always go through CodeRabbit.

2. **Adversarial review 20/20 does not guarantee depth.** The PR body claims "20/20 checklist items with grep evidence" but missed a Tier 4 item that has explicit checklist wording. The `value-removed` semantic tag should have auto-injected the forced question "Where in the codebase is the removed value still referenced?" which would have surfaced the SQL constraint. This reinforces the "covered but not executed" anti-pattern documented in process-patterns.md.

3. **Self-merge with bot-only review continues.** No human review occurred. Bot review caught real issues, but architectural questions (should we create a migration? is the mismatch intentional?) required human judgment that the bot provided as a suggestion.

## Knowledge Updates

- **process-patterns.md:** Added pattern about CodeRabbit skip heuristic for deletion-only PRs.
- **adversarial-review.md:** No structural changes needed — the items exist. The gap is execution depth, not coverage.

## Recommendations

1. **Do not skip CodeRabbit for PRs that remove type union members or modify database schemas.** Add this to the skip conditions documentation.
2. **When the adversarial review claims 20/20, spot-check the semantic tags.** The `value-removed` tag should have triggered the forced question about SQL references.
3. **Consider adding a Tier 0 grep check:** When `value-removed` is detected, automatically grep for the removed literal in `.sql` files and CHECK constraints.
