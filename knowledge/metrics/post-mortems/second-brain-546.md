---
project: second-brain
pr: 546
title: "Drop Starred Highlight from morning brief; switch to 2-col layout"
mergedAt: 2026-04-28T21:27:19Z
branch: feat/today-card-2col
loc: { added: 79, removed: 199 }
filesChanged: 2
commits: 1
closes: [545]
followsUp: 544
---

# Post-mortem: second-brain PR #546

## Summary

Removed the Starred Highlight section from the dashboard's TodayCard and switched the insight area to a fixed 2-column grid (Today's Schedule + Active TODOs), with Upcoming Reminders staying full-width below. Added a "No events today" empty-state line in the Schedule column. Server-side `data.starred` preserved; only dashboard UI changed.

This was a follow-up to #544 (3-row restructure) — user reviewed the result and concluded the Starred Highlight wasn't earning its space on the dashboard.

## Loop

| Step | Outcome |
|------|---------|
| 1 — Plan | User proposed redesign; orchestrator confirmed approach (no separate plan doc — small scope). |
| 2 — Implement | Single pass: removed JSX/state/imports + dead CSS; switched grid to fixed 2-col; added empty-state. |
| 3 — Test locally | `npm run lint` + `npm run build --workspace=@second-brain/web` clean. |
| 4a — Simplify | Skipped (delete-heavy diff; no new logic to simplify). |
| 4b — CodeRabbit | 1 finding — `activeTodos.status` fallback inconsistency. False positive: `status` is required in shared type. Correctly skipped. |
| 4c — Adversarial | PASS with 2 minor concerns: empty-Schedule blank-kicker (caught earlier by critic, already fixed); JSDoc trimmed accurate localStorage line (fixed). |
| 5 — Push & PR | PR #546 created, CI green (Vercel SUCCESS), self-merged after user approval. |

## Metrics

- **adversarialCatchRate:** 1.0 (3 in-scope local catches: critic empty-state bug, adversarial JSDoc, CodeRabbit FP correctly rejected; 0 post-push escapes)
- **preMergeIterationCount:** 1 (no fix-up commits — all amendments squashed into the single feature commit before push)
- **fixupCommitRatio:** 0.0
- **postMergeFixRate:** 0.0 (no follow-up fix needed yet)
- **time-to-merge:** ~9m 42s
- **localReview / stepCompliance / stepTiming:** null (PR body did not include the structured sections)
- **escaped findings:** 0

## What worked

- **Critic catch on empty-Schedule column.** Without the empty-state line, the left column would have rendered just a kicker against a blank body whenever Active TODOs had items but Schedule + dueTodos were empty. Caught pre-push by the critic.
- **CodeRabbit FP discipline.** The `?? "OPEN"` fallback suggestion was rejected after a 1-line type check (`packages/shared/src/index.ts:432`) confirmed `status` is required. Avoided unnecessary defensive code per global rule "don't add error handling for scenarios that can't happen."
- **Tight delete-only diff.** Removing dead state, imports, helpers, and CSS in the same pass kept the file from accumulating orphan references — confirmed by the adversarial sweep.

## Process gaps

- **PR body lacked `## Local Review` and `## Step Timing` sections.** Standard recurring gap — measurement still relies on session memory. Recommendation already captured in second-brain-544 post-mortem; no new action.
- **No tests added.** TodayCard has no existing test file in the repo, so the layout change is uncovered. Acceptable per current coverage baseline but worth flagging if test infrastructure is added later.

## Patterns worth capturing

None new. The "kicker + empty-state-line under each column" pattern is already implicit in `design-preferences.md` (always show body content beneath section headers). The "remove orphan refs after deletion" sweep pattern is already part of the adversarial-review checklist (Tier 0 dead-ref scan).

## Notes for follow-up

- `useTodayCard` hook still fetches `starred` data the dashboard no longer uses. Not removed in this PR — server still serves it, and the field may be re-surfaced on the dashboard later. Cleanup deferred until decision is permanent.
