# POST-MORTEM: plush-press PR #31 — Constrain the scene-picker trigger thumbnail so it stops blowing out the layout.

Branch: fix/scene-picker-thumbnail → main | Author: padminipyapali | self-merged ~13 min after creation
Size: +9 -3 across 1 file, 1 commit (globals.css)

## Summary
A CSS-only regression fix. PR #28 (scenes dropdown) shipped a SceneRow component that renders in two DOM contexts: inside `.ritem` (open-dropdown rows) and inside `.scenepick-trigger` (the collapsed selected-scene chip). The `.thumb/.nm/.st` sizing rules were scoped only to `.ritem`, so the selected scene's 2048px native plate rendered unconstrained in the collapsed trigger — blowing the trigger to a 2066px column and squishing the entire top picker bar. #31 grouped the selectors to apply in both contexts (preserving the `.ritem.new` dashed-box override).

## Root causes (compounding)
1. CSS scoped a SHARED component's sizing to one of its two render contexts.
2. #28 shipped WITHOUT the fresh-context critic (skipped on user request).
3. The #28 implementer's screenshots showed only the empty/open dropdown states — never a SELECTED scene with a real plate in the collapsed trigger, the exact state the bug lived in.

The regression was caught only after a user hit it in the live app. The fix was verified by measuring the real running app (next dev, port 3100): trigger thumbnail `getBoundingClientRect` 2048×2048 BEFORE → 38×38 AFTER; open-dropdown rows unchanged at 38×38 (no regression).

## Local review (pre-push)
- CodeRabbit: not tracked (skipped per session preference — step 4b).
- Adversarial: 0 findings (9-line CSS fix).
- typecheck/lint/build PASS; vitest 203 tests PASS; before/after runtime measurement.

## Step compliance
- Steps run: 1, 2a, 3, 4a, 4c, 4d, 5 (7/9).
- Skipped: 2b (hardening n/a for CSS-only), 4b (CodeRabbit per session preference).
- Compliance: 77.8%. Skip assessment: good — no post-merge issues; PR body explicitly recorded the skip.

## Review friction (post-push)
- 0 inline comments, 0 reviews, 1 round. Self-merged. CI (studio) SUCCESS.
- Timeline: created → merged ≈ 13 min.

## Fix-up metrics
- Post-merge fix rate: 0.0 (this PR IS the post-merge fix for the #28 regression).
- Pre-merge iteration count: 1 (healthy).
- The single commit is a feature/fix commit, not a review-fixup; fixupCommitRatio 0.0.
- adversarialCatchRate: unmeasured (no issues surfaced within this PR's own loop to compute a rate against).

## Planning quality
- Description complete: Summary, Review, Test plan, explicit Steps-skipped line. Clean scope, 1 file.

## Knowledge updates
- process-patterns.md → UI/CSS Gaps: added the "shared component in two DOM contexts + populated-state screenshot gap + critic-skip" rule. Source tagged plush-press #31.

## Recommendations
1. UI screenshots must capture the POPULATED/SELECTED state, not just empty/open — layout blowouts live in the loaded-with-real-data state.
2. When a shared component renders in N DOM contexts, verify its sizing/layout in ALL N (group selectors or duplicate the constraint); never scope to one ancestor and assume.
3. Do not skip the fresh-context critic on UI PRs — the critic is the gate that would have demanded the populated-state screenshot. This regression is the cost of the #28 skip.
