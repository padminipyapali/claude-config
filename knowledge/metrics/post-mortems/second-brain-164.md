# Post-Mortem: second-brain PR #164 — Add snooze/defer for TODOs

**Branch:** feat/todo-snooze → main | **Author:** padminipyapali | **0.4 hours**
**Size:** +945 -74 across 22 files, 6 commits

## Local Review (pre-push)

- **CodeRabbit:** 2 high issues found, 2 fixed (1 iteration) — timezone bug in morning brief, trigger missing OPEN-path snooze clear
- **Adversarial review:** 0 issues found
- **Code simplification:** 6 improvements — extracted shared `computeSnoozeUntil()` utility, dedup, CSS consolidation, error state consistency
- **Shift-left rate:** 29% (2 of 7 total issues caught locally)

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4c, 4d, 5 (8/8)
- **Steps skipped:** none
- **Compliance rate:** 100%
- **Skip assessment:** n/a

## Review Friction (post-push)

- **Review rounds:** 2 (2 CHANGES_REQUESTED from CodeRabbit)
- **Comments:** 6 inline (all CodeRabbit), 2 non-bot general
- **Categories:** correctness: 3, style: 2, architecture: 1
- **Timeline:** created → first review: 7min | first review → merge: 17min | total: 24min
- **Self-merge:** Yes, but after CodeRabbit review (2 rounds addressed)

### Post-push findings detail

1. **Snooze on IN_PROGRESS TODOs** (architecture) — Dismissed: intentional by design (snooze is orthogonal to status).
2. **Timezone offset fragility** (correctness) — Fixed: `toLocaleString` approach replaced with `Intl.DateTimeFormat.formatToParts()`.
3. **Undefined CSS variables** (correctness) — Fixed: `--border`/`--surface-hover` replaced with `--card-border`/`--accent-dim`.
4. **Missing `aria-controls`** (style) — Fixed: Added `aria-controls` + `id` pairing on collapsible section.
5. **Missing snoozed pagination** (correctness) — Fixed: Added `loadMoreSnoozed` matching `loadMoreCompleted` pattern.
6. **CSS focus-visible suggestion** (style) — Follow-up nit on round 2, minor.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% (0 of 4 accepted post-push findings were in checklist)
- **Covered but missed:** None — the issues found post-push are not in the adversarial checklist
- **Not covered (new categories):**
  - CSS variable validation (undefined custom properties)
  - `aria-controls`/`aria-expanded` pairing for collapsible sections
  - Pattern consistency across similar hooks (pagination completeness)
  - `toLocaleString` timezone fragility (related to but distinct from Tier 4 "timezone consistency")
- **Fix commits:** 3 of 6 total (50% fix-up ratio). However, 2 fix commits were infrastructure (marker files, gitignore), not code quality. Substantive fix-up ratio: 1/6 (17%).

## Planning Quality

- **Description:** Complete (summary, changes, local review, test plan)
- **Scope:** Clean — branch lifetime 0.4 hours, focused on single feature
- **Redesign indicators:** None
- **Planning checklist:** Complete (entry points enumerated, performance/cost section in plan)

## Code Quality Signals

- **Recurring issues:** CSS variable validation (new), a11y pairing (new)
- **Fix-up ratio:** 50% nominal, 17% substantive
- **New unrecorded patterns:** CSS undefined variable detection, aria attribute pairing, toLocaleString fragility (already captured by /review-fix learnings)

## Process Efficiency

- **Automation opportunities:** CSS variable linting could catch undefined `var()` references automatically. A Biome or Stylelint rule for custom property validation.
- **Iteration:** Normal (2 rounds, standard for large cross-cutting features per process-patterns.md)
- **CI status:** All passed (build + 780 tests)

## Knowledge Updates

- BUG-030 documented in docs/BUGS.md (timezone offset fragility)
- `typescript-patterns.md` — toLocaleString timezone fragility pattern
- `react-patterns.md` — CSS variable validation, aria-controls pairing
- `architecture-patterns.md` — pattern consistency entry
- (All captured during /review-fix, no additional patterns to add)

## Recommendations

1. **CSS variable linting.** Consider adding Stylelint with `custom-property-no-missing-var-function` or a grep pattern to Tier 0 automated checks for `var(--` references against defined `--` properties.
2. **aria attribute pairing.** Add to Tier 3 a11y checks: when `aria-expanded` is present, verify `aria-controls` points to a valid `id`.
3. **Two-round CodeRabbit pattern confirmed.** This is the 4th large PR (after #131, #159, #162) with exactly 2 CodeRabbit rounds. This is the expected baseline for cross-cutting features.
4. **Marker commit noise.** 2 of 3 fix commits were infrastructure (marker files). Consider whether the hook mechanism can be streamlined to avoid marker-related commits in the PR.
