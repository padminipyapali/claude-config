# Post-Mortem: second-brain PR #184 — Move review markers outside repo

**Branch:** fix/review-marker-location → main | **Author:** padminipyapali | **0.3 hours**
**Size:** +21 -10 across 5 files, 2 commits

## Local Review (pre-push)

- **CodeRabbit:** n/a (skipped — infrastructure-only)
- **Adversarial review:** n/a (skipped — infrastructure-only)
- **Shift-left rate:** n/a

## Step Compliance

- **Steps run:** 1, 2, 5 (3/8)
- **Steps skipped:** 3, 4a, 4b, 4c, 4d — infrastructure-only change, no application code
- **Compliance rate:** 37.5%
- **Skip assessment:** neutral (skipped steps target app code quality; this is shell scripts + markdown)

## Review Friction (post-push)

- **Review rounds:** 1 (1 CHANGES_REQUESTED, then APPROVED)
- **Comments:** 3 inline (all CodeRabbit) — all about hash computation robustness
- **Categories:** correctness: 3
- **Timeline:** created → first review: 4min | first review → merge: 11min | total: 15min

### Post-push findings

All 3 comments addressed the same underlying issue:
1. **Hook**: Use `md5 -q` on macOS + add empty hash guard
2. **Adversarial skill**: Align hash logic with hook (cross-platform fallback + `$HOME` quoting)
3. **Review-fix skill**: Same alignment

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% (adversarial review was skipped)
- **Fix commits:** 1 of 2 (50% fix-up ratio). First commit is the feature, second addresses review.
- Note: Mechanical keyword matching classifies both as "fix" (100%) due to "review" in the first commit message. Substantive ratio is 50%.

## Planning Quality

- **Description:** partial (summary + test plan, but no performance/cost section — not applicable for infra)
- **Scope:** clean — focused single concern
- **Redesign indicators:** none

## Recommendations

- For infra-only PRs touching shell scripts, step 3 (lint/test) could still catch bash syntax issues. Consider running `shellcheck` as part of CI.
- The 3 review comments were all about the same pattern (hash robustness) — a single defensive coding check would have caught all 3.
