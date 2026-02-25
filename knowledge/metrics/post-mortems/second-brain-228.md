# Post-Mortem: second-brain PR #228 -- Defer hidden panel fetches for faster dashboard load

**Branch:** `perf/defer-hidden-panel-fetches` -> `main`
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Created:** 2026-02-25T05:34:04Z | **Merged:** 2026-02-25T05:54:27Z | **Duration:** 20 minutes
**Size:** +1528 -71 (1599 total) across 8 files, 4 commits

## Summary

Performance optimization PR that defers hidden panel API fetches (Todo, Inbox, Research) until after the entry feed loads, reducing initial API burst from 10 parallel calls to 2. Also bundled stylelint configuration setup and CSS autofix (~1100 LOC of CSS changes).

## Local Review (pre-push)

- **CodeRabbit local:** 7 findings (0 critical/high, 2 medium, 5 low informational). 2 medium fixed.
- **Adversarial review:** 0 findings, approved.
- **Internal review (4b):** 0 issues found.
- **Shift-left rate:** 33.3% (2 local catches / 6 total actionable issues)

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4c, 4d, 5 (8/8)
- **Steps skipped:** 3-Playwright (no visual changes -- conditional mounting only)
- **Compliance rate:** 100%
- **Skip assessment:** good (no UI rendering changes, Playwright wouldn't have caught anything)

## Review Friction (post-push)

- **Review rounds:** 2 (2 CHANGES_REQUESTED from CodeRabbit before merge)
- **Inline comments:** 5 (all from coderabbitai[bot])
- **General comments:** 2 (Vercel bot deployment, CodeRabbit summary)
- **Human comments:** 0
- **Comment categories:**
  - documentation: 2 (markdownlint MD031 blank line, profiling step sequencing)
  - style: 3 (lint:css not composed into lint, version pinning inconsistency, CSS TODO extraction suggestion)
  - correctness: 0, security: 0, architecture: 0, performance: 0, testing: 0
- **Timeline:** created -> first review: 3 min | first review -> merge: 17 min | total: 20 min

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% (0/5 post-push findings map to adversarial checklist items)
- **Covered but missed:** none
- **Not covered:** markdownlint formatting, npm script composition convention, devDependency version pinning consistency
- **Assessment:** All 5 post-push findings are style/documentation tooling issues -- zero correctness or security issues escaped. The adversarial checklist is designed for code correctness, not tooling conventions.

## Fix Commits

| # | Commit | Classification |
|---|--------|---------------|
| 1 | Defer hidden panel API fetches for faster dashboard first paint. | FEATURE |
| 2 | Set up stylelint with standard config and fix all violations. | FEATURE |
| 3 | Address PR review: fix markdown formatting and profiling step sequencing. | FIX |
| 4 | Address PR review: compose lint scripts and pin devDependency versions. | FIX |

**Fix-up ratio:** 2/4 = 50%

## Planning Quality

- **Description:** Complete (Summary with performance impact table, Test Plan with 7 scenarios)
- **Scope:** Mixed concern -- performance optimization + stylelint setup + CSS autofix bundled
  - CodeRabbit pre-merge check warned about "out-of-scope changes" (stylelint/App.css)
- **Branch lifetime:** 20 minutes
- **Planning checklist:** Performance/cost impact section present with measured metrics
- **Redesign indicators:** None

## Code Quality Signals

- **Recurring issues:** None (all comments unique)
- **New patterns identified:**
  - devDependency version pinning consistency (added to process-patterns.md)
  - Bundling tooling setup with feature PRs inflates LOC/scope (added to process-patterns.md)

## Process Efficiency

- **Automation opportunities:**
  - markdownlint: MD031 could be caught by running `markdownlint-cli2` locally
  - npm script composition was already documented as a pattern but not followed
- **Iteration:** Normal (2 rounds, expected for PR with tooling changes)
- **CI status:** All passed (build, lint, 944 tests)
- **Self-merge:** Yes (author == mergedBy, no human reviews)

## Knowledge Updates

1. **process-patterns.md:** Added devDependency version pinning consistency pattern
2. **process-patterns.md:** Added bundled tooling PR scope inflation pattern (Scope Decisions)
3. **process-patterns.md:** Added iteration velocity entry for PR #228

## Recommendations

1. **Split tooling/config from feature PRs.** The stylelint setup (~1100 LOC CSS autofix) should have been a separate PR. It inflated the total from ~500 to ~1600 LOC, pushing past the 600 LOC threshold and generating all the style-only review findings.

2. **Run markdownlint locally for docs-heavy changes.** `npx markdownlint-cli2 docs/*.md` would catch MD031 before push. This is the third PR (after #141 and #203) where markdownlint findings account for review rounds.

3. **Apply documented patterns from own knowledge base.** The "compose new lint tools into main lint script" pattern was already in process-patterns.md (from CodeRabbit analytics analysis) but wasn't applied when adding stylelint. The local review should cross-reference knowledge files when adding new tooling.
