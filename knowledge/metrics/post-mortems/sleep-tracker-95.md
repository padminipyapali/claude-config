# Post-Mortem: sleep-tracker PR #95 — Add week navigation and 4 insight cards to Trends page

**Branch:** feat/trends-insights-v2 → main
**Author:** padminipyapali | **Merged:** 2026-03-18T21:11:10Z
**Size:** +1146 -42 across 8 files, 2 commits
**Time to merge:** ~7 minutes (created → merged)

## Local Review (pre-push)

- **CodeRabbit:** not run (CLI skipped)
- **Adversarial:** plan-level review only (8 flags, 3 infos, 2 passes). Code-level adversarial review not run.
- **Internal critic (Step 4b):** Caught 2 bugs + 2 issues, all fixed pre-push.
- **Shift-left rate:** 100% of issues caught locally (4/4 by internal critic)

## Step Compliance

- Steps run: 1 (plan), 2a (implement), 3 (test/lint), 4b (internal critic), 5 (push/PR)
- Steps skipped: 2b (hardening), 4a (/simplify), 4c (CodeRabbit CLI), 4d (code-level adversarial)
- Compliance rate: 55.6% (5/9)
- Skip assessment: neutral — no post-push issues found, but skipped steps untested

## Review Friction (post-push)

- Review rounds: 0 (self-merged, no peer review)
- Comments: 0 human (1 Vercel bot)
- Timeline: created → merged: 7 minutes

## Adversarial Review Effectiveness

- Plan-level adversarial review was thorough (8 flags covering date attribution, null handling, contract preservation, stale closures)
- All 8 flags were addressed in the implementation spec before coding began
- Code-level adversarial review was NOT run — the internal critic served as substitute
- Pre-push catch potential: high (plan review prevented architectural bugs)

## Fix-Up Metrics

- Post-merge fix rate: 0% (no post-merge fixes needed)
- Pre-merge catch rate by step:
  - 4b (internal critic): 4 fixes (2 correctness bugs, 1 defensive-coding, 1 infrastructure)
  - Post-push: 0 fixes
- Pre-merge iteration count: 1 (single implement → review → fix cycle)
- Fix-up taxonomy: correctness (2), defensive-coding (1), infrastructure (1)
- Legacy fix-up ratio: 50% (1 fix / 2 total commits)

### Fix details:
1. **BUG: Nap-only days show "--"** (correctness) — totalMinutes was null when nightMinutes was null, even if napMinutes > 0
2. **BUG: Crib-only naps inflate total** (correctness) — crib-time fallback added crib duration for events where child never slept
3. **ISSUE: Midnight drift** (infrastructure) — isCurrentWeek could drift if page stayed open past midnight
4. **ISSUE: Waking averages denominator** (defensive-coding) — averages excluded quiet nights, skewing results

## Planning Quality

- Description: complete (Summary, Architecture, Review findings, Test plan)
- Scope: clean (8 files, all trends-related)
- Branch lifetime: ~7 minutes
- Planning checklist: entry points enumerated, performance section included

## Code Quality Signals

- All new components wrapped in React.memo()
- Pure compute functions extracted per metric (testable in isolation)
- Existing interfaces preserved (non-breaking additions to WeeklyTrends)
- No new dependencies

## Process Efficiency

- Automation opportunities: CodeRabbit CLI and /simplify were skipped — could have caught additional style issues
- Iteration: efficient (1 round)
- CI status: Vercel SUCCESS

## Recommendations

1. **Run CodeRabbit CLI even on large feature PRs** — the 1146 LOC size is exactly where automated review adds most value
2. **The internal critic (orchestrator pattern) continues to prove effective** — caught 2 real bugs and 2 design issues that would have shipped otherwise
3. **Plan-level adversarial review was highly effective** — prevented 8 architectural issues from ever being coded. This pattern (plan review → targeted implementation) is efficient for multi-feature PRs.

## Knowledge Updates

- No new cross-project patterns identified. Existing patterns applied correctly:
  - Defensive access on optional fields (awakePeriods ?? [])
  - Attribution date vs raw date distinction (existing sleep-tracker domain knowledge)
  - React.memo on pure display components
