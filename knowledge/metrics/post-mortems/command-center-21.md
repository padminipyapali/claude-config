# Post-Mortem: command-center PR #21 — Add velocity dashboard to Activity view

**Branch:** feat/velocity-dashboard → main | **Author:** padminipyapali | **Duration:** 28 minutes
**Size:** +1039 -34 across 9 files, 5 commits | **Merged:** 2026-02-19T12:56:01Z

## Local Review (pre-push)

- **Code simplification:** 6 issues found, 6 fixed (window shadowing, redundant type annotations, const+push, Props interfaces, cast cleanup, helper reorder)
- **CodeRabbit (local):** 6 issues found, 4 fixed (1 iteration). 2 skipped: interface extraction (scope creep, deferred), mockup @import (unrelated file).
- **Adversarial review:** 9 issues found (0 critical, 0 high, 2 medium, 7 low). 3 fixed (500 test, SVG a11y, null date guard). 6 non-blocking deferred.
- **CI:** Build clean, 105/105 tests pass.
- **Shift-left rate:** 70% (7 of 10 substantive issues caught locally before push)

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4c, 4d, 5 (8/8)
- **Steps skipped:** none
- **Compliance rate:** 100%
- **Skip assessment:** n/a

## Review Friction (post-push)

- **Review rounds:** 2 (2 CHANGES_REQUESTED from CodeRabbit bot)
- **Comments:** 3 inline (all from coderabbitai[bot]), 0 human
- **Categories:** correctness: 1, architecture: 1, documentation: 1
- **Timeline:** created → first review: 8 min | first review → merge: 20 min | total: 28 min
- **Peer review:** Self-merge with bot review only (no human reviewer)

### Post-push findings:
1. **sinceDate UTC normalization** (correctness, Major) — `sinceDate` used raw `Date.now()` time-of-day, excluding today's activity from daily breakdown. Fixed by normalizing to UTC midnight.
2. **GraphQL query asymmetry comment** (documentation, Trivial) — GitHub's pullRequests API lacks server-side `since` filter unlike issues. Added inline code comment explaining the asymmetry.
3. **IVelocityService interface extraction** (architecture, Trivial) — Service should follow project's interface-first convention. Extracted interface, updated dependents.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 50%
- **Covered but missed:** sinceDate UTC normalization — date/timezone checks exist in Tier 3 but the specific "normalize date ranges to midnight" pattern wasn't part of the mechanical grep. The adversarial review should have caught this given the UTC section exists.
- **Covered and deferred:** IVelocityService interface — the local adversarial review identified "interface-first" as applicable but deferred it as "scope creep." CodeRabbit then flagged it. Deferral was reasonable but the interface is small enough to include.
- **Not covered:** GraphQL query documentation — documentation requests aren't a bug class and don't belong in the adversarial checklist.
- **Fix commits:** 4 of 5 total (80% fix-up ratio). 2 are marker updates, 2 are substantive fixes.

## Planning Quality

- **Description:** Complete (summary, files changed, local review, deferred, test plan)
- **Scope:** Clean — 28-minute branch lifetime, no redesign commits, single-concern feature
- **Planning checklist:** All items covered (entry points, performance/cost section in plan, adversarial plan review)

## Code Quality Signals

- **Recurring issues:** None (no category with 2+ comments)
- **Fix-up ratio:** 80% (HIGH) — inflated by 2 marker commits. Substantive: 2 fix / 3 meaningful = 67%.
- **New unrecorded patterns:** UTC midnight normalization for daily bucketing — already captured in knowledge base during review-fix.

## Process Efficiency

- **Automation opportunities:** None identified. The UTC normalization bug is too context-specific for a generic linter. The adversarial checklist now covers it.
- **Iteration:** Normal (2 rounds, both from CodeRabbit bot, all fixed within 28 min)
- **CI status:** All passed (Vercel SUCCESS)

## Knowledge Updates

- `~/.claude/knowledge/typescript-patterns.md` — Added "Normalize date ranges to UTC midnight for daily bucketing" under Date / Timezone Pitfalls (captured during review-fix).
- No new process patterns warranting addition — existing patterns cover the observed behavior.

## Recommendations

1. **Deferring interface-first is a false economy.** The IVelocityService interface was ~3 lines. Deferring it as "scope creep" just pushed it to a fix commit. For small interface extractions, include them in the original PR.
2. **Date computation deserves dedicated adversarial attention.** The sinceDate bug was a correctness issue that slipped through despite the adversarial review having a date/timezone section. Consider adding a mechanical check: "For any `new Date(Date.now() - ...)` or manual date arithmetic, verify the time-of-day is intentional."
3. **80% fix-up ratio is expected for first PR in a new project domain.** This PR was the first velocity feature — the codebase had no prior patterns to copy. Future velocity PRs should have lower ratios.
