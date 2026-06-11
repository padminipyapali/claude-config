# Post-mortem: plush-press PR #16 — Image providers, keeper routing, chain state (MVP PR-1b)

`feat/studio-providers` → main | +2614 −182, 22 files, 4 commits | created→merged: 12 min (branch lifetime ~5.9h) | 2026-06-10

## Local review (pre-push)

Joint pass (fresh-context critic + CodeRabbit CLI, 1 iteration): 16 findings raised — 15 fixed in 41b31c2 (6 should-fix, 9 nits), 1 false positive (`response_format` on gpt-image-1) rejected with in-place evidence. Per-tool split NOT recorded in PR body. Shift-left rate: 100% (15/15 caught locally, 0 post-push).

## Step compliance

Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (9/9) — PR body: "Steps skipped: none." Compliance 100%; skip assessment good. Step timing not tracked (no "## Step Timing" section).

## Review friction (post-push)

1 round, 0 comments, self-merge (solo workflow; local review was the gate). Created → merge: 0.2h.

## Metrics

- `adversarialCatchRate: unmeasured` (zero post-push findings = no denominator).
- Post-merge fix rate: 0% (measured at merge+<1h; recheck at 48h).
- Pre-merge catch by step: 4a:0 | 4b:0 | 4c:0 | 4d:15 (combined critic+CodeRabbit recorded under 4d; per-tool attribution unavailable) | post-push:0. Iteration count: 1.
- Taxonomy: correctness:5, documentation:3, defensive-coding:2, dead-code:2, style:2, test-quality:1.
- Legacy fix-up ratio: 25% (1 fix commit / 4 total).

## Planning & quality signals

- Description complete (Summary, Review, Test plan; references plan-review items M2/M4/M6 — adversarial plan review demonstrably shaped implementation).
- Scope clean but 2796 LOC exceeds the 600-LOC budget; fits the "atomic module + typed interface" exception (typed `ImageProvider` interface, per-candidate result types, exhaustive-never routing switch).
- No explicit "Performance & Cost Impact" section (cost analysis embedded in costs.ts with dated price sources, but the section convention was skipped).
- New patterns extracted: test-file typecheck gate gap; silent attachment-drop in provider wrappers (both promoted to knowledge files).

## Recommendations

1. Record the per-reviewer split (critic vs CodeRabbit) in the PR body's Review section — #16 lost step attribution for metrics.
2. Add the "## Step Timing" section — second consecutive plush-press PR without full timing.
3. Re-check postMergeFixRate at +48h.
4. PR-1c onward: aim back under the 600-LOC budget now that the scaffold + providers exist.
