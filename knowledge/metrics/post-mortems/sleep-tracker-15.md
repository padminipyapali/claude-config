# Post-Mortem: sleep-tracker PR #15

**feat: V3 visual polish — unified design tokens and mockup alignment**

Branch: feat/v3-visual-polish → main | Author: padminipyapali | 2.6 hours
Size: +211 -100 across 15 files, 3 commits

## Local Review (pre-push)

- **CodeRabbit:** skipped (CLI not installed)
- **Adversarial:** Grep verification for old hex values — 0 findings (checklist items executed)
- **Internal review (4b):** 3 missed hex-to-variable replacements found and fixed
- **Shift-left rate:** 50% (1/2 fix commits caught pre-push)

## Step Compliance

- Steps run: 1, 2a, 3, 4a, 4b, 4d, 5 (7/9)
- Steps skipped: 2b (N/A styling PR), 4c (CodeRabbit CLI not installed)
- Compliance rate: 78%
- **Skip assessment: BAD** — skipping 4c led to post-push CodeRabbit finding semantic token mismatch that local CodeRabbit would have caught

## Step Timing

| Step | Duration | Notes |
|------|----------|-------|
| 1a-1c Plan | ~15 min | Explored styling, wrote plan, adversarial review |
| 2a Implement | ~8 min | 15 files, mostly hex→var() replacements |
| 2b Hardening | N/A | Styling PR |
| 3 Test | ~3 min | Build + test + Playwright login check |
| 4a-4e Review | ~5 min | Critic found 3 missed replacements |
| 5 Push/PR | ~2 min | |
| **Total** | **~33 min** | |

## Review Friction (post-push)

- **Review rounds:** 2 (both from CodeRabbit bot, both CHANGES_REQUESTED)
- **Comments:** 3 inline (2 in-diff, 1 outside-diff), all from coderabbitai[bot]
- **Categories:** correctness: 1 (semantic token mismatch), style: 2 (hardcoded values)
- **Timeline:** created → first review: 5min | first review → merge: 2.5h | total: 2.6h
- **Self-merge:** Yes, merged by author. No human peer review (bot reviews only).
- **Unaddressed comment:** TeamActivity.tsx #FFF hardcoded background (2nd CodeRabbit round, post-fix push). Not fixed before merge.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 33% (1 of 3 comments had a matching checklist item)
- **Covered but missed:** TimeScrollPicker hardcoded colors — falls under "CSS token consistency" checklist item, but the container-level styles were outside the diff that the implementer edited
- **Not covered (new):** Semantic token role mismatch (using `--primary-text` as `background`). **Now added** to adversarial-review.md as a sub-check under CSS token consistency.

## Fix-Up Metrics

- **Post-merge fix rate:** 0% (no post-merge fixes needed)
- **Pre-merge catch rate by step:**
  - 4b (internal review): 1 fix (missed hex replacements)
  - post-push: 1 fix (semantic token mismatch + hardcoded colors)
- **Pre-merge iteration count:** 2 (1 local fix + 1 post-push fix)
- **Fix-up taxonomy:** style: 1, correctness: 1
- **Legacy fix-up ratio:** 67% (2 fix / 3 total commits)

## Planning Quality

- **Description:** Complete (Summary, Test Plan, Local Review, Step Timing all present)
- **Scope:** Clean — 311 LOC, under 600 LOC cap, single concern (visual polish)
- **No redesign indicators** — all commits aligned with plan
- **Planning checklist:** Entry points enumerated (14 files mapped), performance N/A (styling only)

## Code Quality Signals

- **Recurring issues:** Style consistency (3 missed hex replacements + 2 hardcoded values + 1 semantic mismatch = 6 total color token issues). This is expected for a 60-replacement PR — completeness was the main challenge.
- **New pattern captured:** Semantic token role mismatch → added to adversarial-review.md

## Process Efficiency

- **Automation opportunity:** The semantic token mismatch could be caught by a grep-based Tier 0 check: `grep -rn 'background.*var(--.*-text)' src/`. Added to adversarial-review.md.
- **Iteration:** Normal (2 rounds: 1 local, 1 post-push). The local CodeRabbit skip inflated the post-push round.
- **CI:** All passed (CodeRabbit status: SUCCESS, Vercel: SUCCESS)

## Knowledge Updates

1. **Strengthened** `adversarial-review.md` CSS token consistency check with semantic role mismatch sub-pattern and grep pattern `background.*var(--.*-text)`. <!-- Source: post-mortem, sleep-tracker #15, 2026-03-03 -->

## Recommendations

1. **Install CodeRabbit CLI.** Skipping step 4c led directly to the post-push round. Running `coderabbit review` locally would have caught the semantic token mismatch pre-push, saving the review-fix-push round trip (~2h).
2. **Add Tier 0 grep for token role mismatches.** `background.*var(--.*-text)` and `color.*var(--.*-soft)` as automated checks would catch the most common semantic mismatch directions.
3. **Unaddressed comment:** TeamActivity.tsx `#FFF` hardcoded card background. Low severity (it's `white`, which is intentional for card surfaces), but should be `var(--card-bg, #FFF)` for theme consistency. File as outside-diff issue.
