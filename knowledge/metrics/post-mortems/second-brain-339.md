# Post-Mortem: second-brain PR #339

**Title:** Add progressive search with FTS-first rendering, skeleton UI, and pre-fetching
**Branch:** feat/progressive-search → main
**Author:** padminipyapali | **Merged by:** padminipyapali
**Created:** 2026-03-03T18:04:59Z | **Merged:** 2026-03-03T20:52:55Z
**Size:** +346 -22 across 9 files, 4 commits

## Local Review (pre-push)

- **Internal review (4b):** 2 findings, 2 fixed (offsetRef race on cache hit, missing prefers-reduced-motion)
- **CodeRabbit local (4c):** Still processing at push time — 0 findings caught locally
- **Adversarial review (4d):** 16/16 Tier 0 checks, 4/4 Tier 1-3 items, 0 findings
- **Shift-left rate:** 2/7 total findings caught pre-push = 28.6%

## Step Compliance

- **Steps run:** 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (9/9)
- **Compliance rate:** 100%
- **Skip assessment:** n/a

## Step Timing

| Step | Duration | Notes |
|------|----------|-------|
| 1a-1c Plan | ~15 min | Prior session |
| 2a Implement | ~8 min | All 4 tasks parallel |
| 2b Hardening | included in 2a | |
| 3 Test | ~2 min | build + lint + 1049 tests |
| 4a-4e Review | ~10 min | 2 findings in 4b |
| 5 Push/PR | ~2 min | |
| **Total** | **~37 min** | |

## Review Friction (post-push)

- **Review rounds:** 3 (2 CHANGES_REQUESTED, 1 APPROVED)
- **Comments:** 5 inline (all from coderabbitai[bot]), 0 human
- **Categories:** correctness: 2, a11y: 2, style: 1
- **Timeline:** created→first review: 6min | first review→merge: 2.7h | total: 2.8h

## Post-Push Findings (5 issues across 2 CodeRabbit rounds)

### Round 1 (4 findings)
1. **Mode serialization (style)** — `searchEntries()` only serialized `"fts"`, dropped `"hybrid"`. Fix: serialize all mode values.
2. **Opacity pulse animation (a11y)** — `.search-enhancing` reused `skeleton-pulse` (background-color), wrong for text. Fix: new opacity-based keyframes.
3. **ARIA live regions (a11y)** — Loading skeleton and "Refining results..." were visual-only, invisible to screen readers. Fix: added `role="status"` + `aria-live="polite"`.
4. **Cache-hit revalidation race (correctness)** — Cache hit left `enhancing=false`, allowing `loadMore` to append rows that hybrid replace would clobber. Fix: set `enhancing=true` immediately on cache hit.

### Round 2 (1 finding)
5. **`<output>` semantics (a11y)** — `<output>` is for computed form results, not loading states. Fix: replaced with `<div role="status">` + biome-ignore comment.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0/5 = 0% — none of the 5 post-push findings are in the current checklist
- **Covered but missed:** 0
- **Not covered (new categories):**
  - ARIA live regions for loading/status states (a11y gap)
  - Stale-while-revalidate race with concurrent mutations (async/hooks gap)
  - Animation type appropriateness (background-color pulse vs opacity pulse for text)
  - Semantic HTML element correctness (`<output>` vs `role="status"`)

## Fix-Up Metrics

- **Post-merge fix rate:** 0% (no post-merge fixes needed)
- **Pre-merge catch rate by step:**
  - 4a (simplify): 0 | 4b (internal): 2 | 4c (CodeRabbit local): 0
  - 4d (adversarial): 0 | post-push: 5
- **Pre-merge iteration count:** 2 (2 review-fix cycles)
- **Fix-up taxonomy:** a11y: 4, correctness: 2, style: 1
- **Legacy fix-up ratio:** 75% (3 fix / 4 total commits)

## Planning Quality

- **Description:** Complete (Summary, Local Review, Fix-Up Metrics, Step Timing)
- **Scope:** Clean — 368 LOC, under 600 cap, single concern
- **Branch lifetime:** 2.8 hours
- **Planning checklist:** Entry points enumerated, performance/cost section present

## Process Efficiency

- **Automation opportunities:**
  - ARIA live region check could become a Tier 0 grep: `grep -rn 'loading.*SkeletonCard\|loading.*skeleton' --include='*.tsx'` → verify parent has `role="status"`
  - Animation type check could be a Tier 0 grep: `grep -rn 'animation:.*skeleton-pulse' --include='*.css'` → verify it's on a skeleton element, not text
- **Iteration:** Normal (2 rounds — CodeRabbit found real issues the local review missed)
- **CI:** All passed

## Knowledge Updates

- **react-patterns.md:** Added 2 new patterns:
  1. "ARIA live regions for loading/status indicators" (new)
  2. "Stale-while-revalidate must block concurrent mutations" (new)
  - Pattern 1 strengthened in round 2: corrected `<output>` recommendation to `<div role="status">` with biome-ignore

## Recommendations

1. **Add Tier 0 ARIA live region check.** Loading/skeleton states are a recurring a11y gap. A grep for skeleton renders without `role="status"` would catch this mechanically.
2. **Wait for CodeRabbit local before pushing.** The 5 post-push findings were all catchable by CodeRabbit — the local run was still processing when the PR was created. A "wait for CodeRabbit" policy would shift these left.
3. **Add cache-hit revalidation race to React hook patterns checklist.** The stale-while-revalidate pattern is increasingly common and the race with `loadMore` is non-obvious.
