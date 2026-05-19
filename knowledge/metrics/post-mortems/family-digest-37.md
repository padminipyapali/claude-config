# POST-MORTEM: family-digest PR #37 - Remove frozen SIMULATED_NOW default from digest CLI.

**Branch:** fix/remove-simulated-now -> main
**Author:** padminipyapali
**Created -> Merged:** 2026-05-16T00:52:11Z -> 2026-05-16T03:37:36Z (2.76h)
**Size:** +89 / -7 across 2 files, 1 commit
**Merged by:** padminipyapali (self-merge)

## LOCAL REVIEW (pre-push)

- /simplify: skipped - diff is a 1-line default swap plus a regression test; no surface to simplify.
- CodeRabbit CLI: skipped (single-line behavior change + regression test).
- Adversarial review: PASSED - critic agent in fresh context, then orchestrator re-run. Zero findings.

Tracked: adversarial 0/0. CodeRabbit null (not run).
Shift-left rate: n/a (no issues raised by any gate).

## STEP COMPLIANCE

- PR body: "Steps skipped: None material. Steps 1-4 ran via orchestrator/implementer/critic."
- Compliance rate: 1.0.
- Skip assessment: good - no post-merge issues; the skipped sub-gates (/simplify, CodeRabbit) were appropriate for the diff shape.

## STEP TIMING

Not tracked in PR body.

## REVIEW FRICTION (post-push)

- Review rounds: 1 (no CHANGES_REQUESTED, no APPROVED reviews).
- Inline comments: 0. General comments: 0. All categories zero.
- Timeline: created -> merged 2.76h (no external reviewer).

## ADVERSARIAL REVIEW EFFECTIVENESS

adversarialCatchRate = "unmeasured" - no defects surfaced anywhere in the lifecycle, so we cannot compute a catch rate from evidence. Adversarial review reported PASS.

Covered but missed: none. Not covered: none.

## FIX-UP METRICS

- Post-merge fix rate: 0.0 (no follow-up PRs in 48h window referencing this fix).
- Pre-merge catch rate by step: all zeros (no fix commits - only the feature/fix commit).
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all zeros.
- Legacy fix-up ratio: 0.0.

## PLANNING QUALITY

- Description: complete - Summary, Test plan, Local Review, Steps skipped all present.
- Scope: clean - single-purpose bug fix.
- Branch lifetime: 2.83h.
- Planning checklist: entry points (CLI vs Railway cron vs scheduler) enumerated in the sibling-sweep paragraph. No explicit Performance & Cost section, but the diff is a constant-time default swap.

## CODE QUALITY SIGNALS

- Recurring issues: none.
- New patterns worth capturing: regression test that bans year-prefixed new Date("YYYY-...") literals in production entry-point scripts.

## PROCESS EFFICIENCY

- Automation: the new no-frozen-now.test.ts IS the automation - pins the CLI default `now` between two wall-clock samples and forbids year-prefixed date literals in entry-point scripts. Exact shift-left for this defect class.
- Iteration: efficient (1 round).
- CI: no checks configured (statusCheckRollup empty).

## RECOMMENDATIONS

1. Promote the regression-test pattern. When fixing a stale-constant default ("simulated now" frozen to a literal date), add a test that fails if any production entry point reintroduces a hardcoded year-prefixed date literal. Capture in ~/.claude/knowledge/testing-patterns.md and/or typescript-patterns.md.
2. Audit sibling repos for the same anti-pattern. Any entry-point CLI/scheduler that defaults a clock dep to a literal new Date("2026-...") rather than () => new Date() will silently freeze. Sweep across second-brain, nanny-app, etc.
3. Solo-merge workflow is calibrated correctly for this PR shape - no process change needed.
