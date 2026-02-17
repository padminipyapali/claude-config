# POST-MORTEM: second-brain PR #135 — Improve /summary: sort TODOs by due date, limit to 5 items

Branch: fix/summary-improvements -> main | Author: padminipyapali | 2026-02-17
Size: +135 -2 across 3 files, 2 commits

## LOCAL REVIEW (pre-push)

- CodeRabbit: not tracked (no local review section in PR body)
- Adversarial: not tracked
- Shift-left rate: n/a

## REVIEW FRICTION (post-push)

- Review rounds: 2 (2 CHANGES_REQUESTED events, both from CodeRabbit bot)
- Comments: 2 inline, 1 general (excluding bots: 1 general from owner explaining false positives)
- Categories: { security: 0, correctness: 0, architecture: 0, style: 0, performance: 0, testing: 1, documentation: 0, other: 1 }
  - testing: 1 (CodeRabbit sandbox failed to run tests due to monorepo build order — false positive)
  - other: 1 (adversarial review marker stale — inherent to mechanism, false positive)
- Timeline: created -> first review: 5min | first review -> merge: 14min | total: 0.31h
- Self-merge: YES

## ADVERSARIAL REVIEW EFFECTIVENESS

- Pre-push catch potential: 100% (no real code issues found by reviewers)
- Covered but missed: none
- Not covered: none (both reviewer findings were false positives)
- Fix commits: 0 of 2 total (0% fix-up ratio)
  - Commit 1: feature — Improve /summary: sort TODOs by due date, limit sections to 5 items
  - Commit 2: marker — Mark adversarial review passed

## PLANNING QUALITY

- Description: complete (summary with 3 bullet points, test plan with 3 items, closes #126)
- Scope: clean — no scope creep or redesign
- Branch lifetime: <1 hour
- CodeRabbit implementation details: auto-generated and thorough

## CODE QUALITY SIGNALS

- Recurring issues: none
- Fix-up ratio: 0.0 (clean — no review-driven fixes needed)
- New unrecorded patterns: none
- Tests: 6 new unit tests added for formatDailySummary

## PROCESS EFFICIENCY

- Automation: CodeRabbit sandbox environment does not build monorepo dependencies — this will continue to produce false positive test failures. Consider documenting this as a known limitation.
- Iteration: minimal (2 review rounds, both false positives, merged without changes)
- CI status: all passed (CodeRabbit SUCCESS, Vercel SUCCESS)
- Owner dismissed both findings with clear explanations in a general comment.

## KNOWLEDGE UPDATES

- No new patterns discovered (clean PR with no real issues)

## RECOMMENDATIONS

1. **Document CodeRabbit monorepo limitation**: CodeRabbit's sandbox runs `npm test` without building shared packages first. This will recur on every PR touching server tests. Consider adding a note to the PR template or CodeRabbit config.
2. **Adversarial review marker is an inherent race**: The marker records the reviewed commit, but committing the marker advances HEAD. CodeRabbit will always flag this. Consider suppressing this check in CodeRabbit config or accepting it as noise.

---
*Generated: 2026-02-17 (post-mortem analysis of merged PR)*
