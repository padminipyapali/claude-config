# Post-Mortem: second-brain PR #206 -- Add research_tasks schema, shared types, and migration

**Branch:** feat/research-schema -> main | **Author:** padminipyapali | **Duration:** 0.23 hours
**Size:** +358 -0 across 3 files, 4 commits

## Local Review (pre-push)

- **Internal review:** 4 findings, 4 fixed (idempotent migration DDL, ON DELETE CASCADE on user_id FK, IF/ELSIF consolidation in trigger, source-of-truth cross-reference comments)
- **CodeRabbit local:** CLI timed out. Will be reviewed by GitHub app post-push.
- **Adversarial review:** 3 findings, 3 fixed (reverse guard trigger_prevent_entry_user_change_with_research, discard_consistency CHECK constraint, source-of-truth directionality TS->SQL)
- **Playwright:** N/A (schema-only PR, no UI changes)
- **Shift-left rate:** 88% (7 of 8 unique issues caught locally)

## Step Compliance

- Steps run: 1, 2, 3, 4a, 4b, 4c, 4d, 5 (7/8 applicable steps)
- Steps skipped: 3-Playwright (schema-only PR, no UI changes)
- Compliance rate: 87.5%
- Skip assessment: justified (schema-only, zero UI)

## Review Friction (post-push)

- **Review rounds:** 1 (1 CHANGES_REQUESTED before merge)
- **Comments:** 1 inline (from coderabbitai[bot]), 0 general (non-bot)
- **Categories:** { correctness: 1 }
- **Timeline:** created -> first review: 0.07h | first review -> merge: 0.16h | total: 0.23h
- **Self-merge:** YES (author = merger, bot-only review)

### Post-push findings detail

1. **[CORRECTNESS] completed_at trigger fires UPDATE-only, should be INSERT OR UPDATE** -- `trigger_research_completed_at` fired `BEFORE UPDATE` only. Direct INSERTs with `status='DONE'` (test data, manual migrations) would leave `completed_at` as NULL. CodeRabbit flagged as minor/optional. ADDRESSED in commit 14a5855.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% (the 1 post-push finding was identified locally as adversarial Finding #4 but classified LOW and not fixed)
- **Covered but not actioned:** 1 (trigger event scope -- adversarial review explicitly identified "completed_at trigger fires on UPDATE only, consider INSERT OR UPDATE" but classified it as LOW priority and did not apply the fix)
- **Not covered (new category):** 0
- **Fix commits:** 1 of 4 total (25% fix-up ratio)
- **Fix commit classification:**
  - [FEATURE] "Add research_tasks schema, shared types, and migration for async research agent."
  - [FIX-LOCAL] "Address code review findings: idempotent migration, ON DELETE CASCADE, ELSIF, source-of-truth comments."
  - [FIX-LOCAL] "Address adversarial review: reverse guard, discard consistency, source-of-truth directionality."
  - [FIX-REMOTE] "Address PR review: completed_at trigger fires on INSERT OR UPDATE."

## Planning Quality

- **Description:** COMPLETE (Summary with schema highlights, Test Plan with checked/unchecked items, PR 1 of 8 context)
- **Scope:** Clean (schema-only, well-bounded, 3 files)
- **Planning checklist:** Schema design enumerated all constraints, triggers, and indexes. Performance/cost section implicit in index design choices (filtered indexes for common queries).

## Code Quality Signals

- **Recurring issues:** None (only 1 comment)
- **Fix-up ratio:** 25% (1 post-push fix / 4 total commits)
- **Substantive fix-up ratio:** 25% (same -- no marker commits)
- **New unrecorded patterns:** None (trigger event scope already captured in database-patterns.md and adversarial-review.md)

## Process Efficiency

- **Key pattern: "Covered but not actioned" repeats.** This is the second occurrence of the adversarial review identifying an issue, explicitly noting it, and choosing not to fix it -- then having it flagged post-push. PR #198 had the same pattern with `buildTodoInlineButtons` duplication. The adversarial review needs a rule: when an issue is identified, the default should be to FIX it unless there's an active trade-off (performance, scope, breaking change). "Low priority" is not a valid skip reason for a finding the review itself identifies.
- **Schema-only PRs are low-friction.** 1 review round, 1 inline comment, 0.23h total. No test code to mock incorrectly, no UI to break, no async patterns to audit. The well-defined SQL + TypeScript types domain produces high shift-left rates.
- **CodeRabbit CLI timeout is a recurring gap.** The local CodeRabbit CLI timed out, meaning the GitHub app was the only CodeRabbit review. This is the second time the CLI has timed out on this project.
- **CI status:** build/lint/test all passed

## Knowledge Updates

- **database-patterns.md:** Already updated (trigger event scope entry sourced to #206).
- **adversarial-review.md:** Already updated (Tier 4 db-sql checklist item "Trigger event scope" added, sourced to #206).
- **process-patterns.md:** Updated with "covered but not actioned" pattern confirmation and iteration velocity entry.

## Recommendations

1. **Treat adversarial review findings as fix-by-default.** When the adversarial review identifies an issue, fix it unless there's a documented trade-off. "LOW priority" as a skip reason has now produced post-push findings on 2 consecutive PRs (#198, #206). The overhead of fixing a known issue locally (~5 min for trigger change) is always less than the post-push round-trip (~15 min for review + fix commit + re-review wait).
2. **Schema-only PRs are good candidates for the smallest PR strategy.** PR #206 is the cleanest result yet: 358 LOC, 88% shift-left rate, 25% fix-up ratio, single-concern scope. Splitting the 8-PR research agent feature into schema-first is validated.
3. **Investigate CodeRabbit CLI timeout.** Two CLI timeouts suggest a configuration or environment issue. If the CLI consistently fails, consider running it with a longer timeout or documenting as a known limitation.
