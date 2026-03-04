# Post-Mortem: second-brain PR #351

**Title:** Add proactive connections evening reflection scheduler
**Branch:** feat/proactive-connections -> main
**Author:** padminipyapali | **Merged by:** padminipyapali
**Created:** 2026-03-04T04:44:16Z | **Merged:** 2026-03-04T05:21:46Z
**Size:** +983 -1 across 11 files, 3 commits

## Local Review (pre-push)

- **Steps skipped:** none
- **Internal review findings:** 2 found, 2 fixed (hour validation, a11y role)
- **CodeRabbit findings:** 0 critical/high
- **Adversarial review depth:** Tier 0: 7/7 with grep evidence. Tier 1-4: 15/15 with structured evidence
- **Shift-left rate:** 2/8 total fixes caught locally = 25%

## Step Compliance

- **Steps run:** 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 4e, 5 (10/10)
- **Steps skipped:** none
- **Compliance rate:** 100%
- **Skip assessment:** n/a

## Step Timing

Not tracked in PR body. Total elapsed: ~38 minutes (PR created to merged).

## Review Friction (post-push)

- **Review rounds:** 2 (1 CHANGES_REQUESTED + 1 COMMENTED)
- **Comments:** 7 inline (all CodeRabbit bot), 2 general (Vercel + CodeRabbit summary)
- **Human comments:** 0
- **Categories:** { security: 1, correctness: 3, architecture: 1, performance: 1, other: 1 }
- **Timeline:** created -> merged: 38 min
- **Self-merge:** Yes, bot-only review (no human reviewer)

## Adversarial Review Effectiveness

- **Pre-push catch potential:** ~14% (1 of 7 post-push issues was in the adversarial checklist scope)
- **Covered but missed:**
  - Config validation (threshold/maxConnections/minAgeDays) — input validation IS a universal adversarial check, but the review marked it PASS. The existing hour validation was caught by step 4b, but the parallel config fields were not.
- **Not covered (new categories):**
  - `hourCycle: "h23"` vs `hour12: false` — Intl API behavior not in checklist
  - Self-link CHECK constraint on junction tables — DB invariant not in checklist
  - Redundant index with UNIQUE — index optimization not in checklist
  - Hard-coded channel string violating hexagonal architecture — architecture check not in checklist
  - Conflicting threshold filters at two layers — not in checklist

## Fix-Up Metrics

- **Post-merge fix rate:** 0% (no post-merge fixes needed)
- **Pre-merge catch rate by step:**
  - 4b (internal review): 2 fixes (hour validation, a11y role)
  - post-push: 6 fixes (self-link CHECK, remove redundant index, config validation, hourCycle, channel injection, remove similarity floor)
- **Pre-merge iteration count:** 2 (1 pre-push + 1 post-push cycle)
- **Fix-up taxonomy:** { validation: 3, a11y: 1, correctness: 2, architecture: 1, performance: 1, infrastructure: 1 }
- **Legacy fix-up ratio:** 67% (2 fix commits / 3 total commits)

## Planning Quality

- **Description:** Complete (Summary, How it works, Configuration, Migration, Local Review, Test Plan)
- **Scope:** Clean — single feature, no scope creep
- **Branch lifetime:** <1 hour
- **Planning checklist:** Entry points enumerated, performance/cost section included

## Code Quality Signals

- **Recurring issues:** validation (3 instances — config fields missed despite hour being validated)
- **New patterns captured:**
  - `hourCycle: "h23"` → typescript-patterns.md
  - UNIQUE index covers leading-column lookups → database-patterns.md

## Process Efficiency

- **Automation opportunities:**
  - Config validation could be a linter rule: "constructor that validates some params but not all config fields"
  - `hourCycle` check could be a Tier 0 grep: `grep -rn "hour12: false"` → flag and suggest `hourCycle: "h23"`
- **Iteration:** Normal (2 rounds — 1 pre-push, 1 post-push)
- **CI status:** All passed

## Recommendations

1. **Add `hour12: false` grep to Tier 0 adversarial checks.** This is a mechanical check that catches a real ECMAScript spec issue. Pattern: `grep -rn "hour12:\s*false"` in changed files. Filed as issue #352 for sibling fix.
2. **Config validation sibling sweep.** When one constructor param is validated, the adversarial review should check ALL constructor params — not just the one explicitly mentioned. The review caught `hour` validation but missed `threshold/maxConnections/minAgeDays`.
3. **Consider adding "conflicting filters at two layers" to adversarial checklist.** The hard-coded 0.5 similarity floor in SQL conflicted with the configurable 0.78 threshold at the application layer. Pattern: when a configurable threshold exists, verify no hard-coded floor exists below it.
