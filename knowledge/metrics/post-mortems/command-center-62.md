# Post-Mortem: command-center PR #62 — Show GitHub issues in dashboard and PRs views

**Branch:** feat/issue-dashboard → main | **Author:** padminipyapali | **0.39h**
**Size:** +466 -8 across 15 files, 3 commits

## Local Review (pre-push)

- **CodeRabbit (local):** not run (no local CLI invocation recorded)
- **Adversarial (critic):** 4 findings, 4 fixed (Step 4b internal review)
  - syncProjects missing issueCache displayName update
  - PR row a11y: missing role="button", tabIndex, onKeyDown (x2 — DashboardView, PrsView)
  - Dead onOpenDetail prop on CommandPalette
- **Shift-left rate:** 4/6 total issues caught locally = 67%

## Step Compliance

- Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (9/9)
- Steps skipped: none
- Compliance rate: 100%
- Skip assessment: n/a

## Step Timing

Not tracked (no Step Timing section in PR body).

## Review Friction (post-push)

- Review rounds: 1 (bot COMMENTED, no CHANGES_REQUESTED)
- Comments: 3 inline (all from coderabbitai[bot]), 2 general (Vercel + CodeRabbit walkthrough)
- Categories: { correctness: 1 (false positive), other: 2 (a11y) }
- Timeline: created → first review: ~4m | first review → merge: ~20m | total: 0.39h
- Self-merge: yes (no human peer review — personal project)

## Adversarial Review Effectiveness

- Pre-push catch potential: 33% (1/3 post-push comments was addressable by existing checklist)
- Covered but missed:
  - `role="button"` elements need `aria-label` — covered by react-patterns.md line 38 (role="button" pattern) but the critic added role/tabIndex/onKeyDown without aria-label. The checklist catches the interactive role itself but not the aria-label requirement on it.
- Not covered (new categories):
  - `aria-label` on non-interactive generic elements is invalid (WAI-ARIA). Not in adversarial checklist. **Added to react-patterns.md during review-fix step.**
- False positive: label.color `#` prefix comment — CodeRabbit didn't trace through to `mapIssueNode` which already normalizes. Multi-file tracing gap in CodeRabbit's analysis.

## Fix-Up Metrics

- **Post-merge fix rate:** 0% (no post-merge fix PRs)
- **Pre-merge catch rate by step:**
  - 4a (simplify): 0 fixes
  - 4b (internal review): 4 fixes (syncProjects, PR row a11y x2, dead prop)
  - 4c (CodeRabbit local): 0 (not run locally)
  - 4d (adversarial): 0 fixes
  - post-push: 2 fixes (aria-label removal + addition to interactive rows)
- **Pre-merge iteration count:** 2 (1 pre-push critic round + 1 post-push review-fix)
- **Fix-up taxonomy:** { a11y: 5, defensive-coding: 1, dead-code: 1 }
- **Legacy fix-up ratio:** 67% (2 fix / 3 total commits)

## Planning Quality

- Description: complete (Summary, Test Plan, Local Review, Files Changed sections)
- Scope: clean (1 deferred item: ActivityEvent type union — appropriate scope boundary)
- Branch lifetime: 0.39 hours
- Planning checklist: covered (entry points enumerated in plan, adversarial plan review ran with REVISE→APPROVE cycle)

## Code Quality Signals

- Recurring issues: **a11y** (5 of 7 total fixes were a11y-related). The hardening pass (Step 2b) reported "4 elements, 6 attrs" but missed aria-label on non-interactive spans and aria-label on interactive role="button" rows.
- New patterns captured:
  1. `aria-label` invalid on non-interactive generic elements → added to `react-patterns.md`
  2. `role="button"` elements need `aria-label` → strengthened existing pattern in `react-patterns.md`

## Process Efficiency

- Automation opportunities: The aria-label-on-non-interactive-span could be caught by Biome lint (`useAriaPropsSupportedByRole`). Consider adding this rule to the project's Biome config.
- Iteration: normal (2 rounds)
- CI status: all passed (CodeRabbit SUCCESS, Vercel SUCCESS)

## Knowledge Updates

- `react-patterns.md`: Added new pattern — `aria-label` invalid on non-interactive elements
- `react-patterns.md`: Strengthened `role="button"` pattern — added `<tr>` exception and `aria-label` requirement

## Recommendations

1. **Run CodeRabbit locally (Step 4c).** This PR skipped the local CodeRabbit CLI run. The 2 a11y issues caught post-push would likely have been caught pre-push, improving shift-left rate from 67% to potentially 100%.
2. **Add Biome `useAriaPropsSupportedByRole` rule.** This would automatically catch invalid `aria-label` placement on non-interactive elements, converting a manual review catch into a lint-time catch.
3. **Hardening pass (Step 2b) should include aria-label audit.** The hardening pass reported a11y work but didn't verify aria-label validity or completeness on interactive elements. Consider adding "verify aria-label on all `role=button` elements" to the hardening checklist.
