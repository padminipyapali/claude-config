# Post-Mortem: plush-press PR #327 — Parameterize the composite-path style language behind StylePromptText (Stage 1 of Art Styles)

- **Branch:** feat/style-composite-path → main | **Author:** padminipyapali | **Merged by:** padminipyapali (self-merge, no peer review — solo repo norm)
- **Created:** 2026-07-20T00:05:35Z | **Merged:** 2026-07-20T00:10:19Z | **Time to merge:** ~5 min (0.08h)
- **Size:** +229 −28 across 3 files, 2 commits (`studio/src/lib/scene/prompts.ts`, tests, `docs/ART_STYLES_SPEC.md`)
- **CI:** studio check SUCCESS (single CI run, green first try)

## What the PR did

Pure parameterization: factored hardcoded soft-watercolor language (7 sites across INTERACT / FREE_INTERACT / SCENE_ONLY / FREE_SCENE_ONLY / `interactBody` / `sceneOnlyBody` / `DESLOP_CLAUSE`) into an optional `StylePromptText { medium, closingLine, deslopClause }` parameter defaulting to `WATERCOLOR_STYLE_TEXT`. No consumer wired — Stage 2 resolves a per-book `style_id`. Byte-identical default proved via golden fixtures, a pre-existing eval seam pin against the live HTML source, an unchanged byte-pin in `SceneCanvasRender.test.tsx`, and executing origin/main's `prompts.ts` against the branch across the input matrix. 2446 tests green; lint/typecheck/build pass.

## Local review (pre-push)

- PR body has **no `## Local Review` section**, no `Steps skipped:` line, no `## Step Timing` section → those fields recorded as null/not-tracked in metrics.
- Evidence from commit history: commit 2 ("Address CodeRabbit review: strengthen the Stage 1 byte-identity proof", committed 00:04:56 — *before* PR creation) shows **1 local CodeRabbit iteration**. Findings count not recorded; per session context all findings were test/documentation strengthening, zero code-behavior changes:
  - Added full-output golden fixtures for SCENE_ONLY / FREE_SCENE_ONLY.
  - Converted absence-of-watercolor checks to **positive** custom-medium/closing-line assertions in both isPlush branches.
  - Documented the `deslopClause` leading-space contract (concatenated with no separator by `buildInvariantsClause`).
  - Reworded the spec's byte-identical claim to cite its actual proofs.
- Adversarial critic (orchestrator team, per session context): ran, zero findings requiring code-behavior changes → recorded adversarialFindings 0 / fixed 0.

## Step compliance / timing

Not tracked — PR body predates/omits the `Steps skipped:` and `## Step Timing` sections. `stepCompliance: null`, `stepTiming: null`.

## Review friction (post-push)

- GitHub reviews: **none** (`reviews: []`, `comments: []`, reviewDecision empty). Inline-comments API returned 503 repeatedly during this analysis, but the PR-level `comments`/`reviews` arrays confirm zero review activity.
- Comment categories: all 0.
- Timeline: created → merge ~5 min; no review-fix cycles post-push.

## Adversarial review effectiveness

- **adversarialCatchRate: "unmeasured"** — there were zero post-push findings and no recorded local finding counts, so no denominator exists. Not fabricated per the metric-integrity rule.
- Covered-but-missed: none observable (no escaped issues).
- New checklist categories: none. The one CodeRabbit lesson (positive assertions beat absence assertions when proving a parameterized path) was captured in process-patterns.md rather than the adversarial checklist — it is a test-design pattern, not a review-tier gap.

## Fix-up metrics

- **Post-merge fix rate: 0.0** — #327 is the most recently merged PR in the repo; no follow-up fix PRs/commits exist (verified against the merged-PR list as of 2026-07-19 analysis time... note merge timestamp is 2026-07-20Z).
- **Pre-merge catch by step:** 4a: 0 | 4b: 0 | 4c (CodeRabbit): 1 | 4d: 0 | post-push: 0. Attribution: commit `7fbcd67` explicitly says "Address CodeRabbit review".
- **Pre-merge iteration count: 1** (healthy).
- **Fix-up taxonomy:** test-quality: 1, documentation: 1 (both from the single fix commit; split because it contains both a test-strengthening body and a doc/spec body). Legacy fixupCommitRatio: 0.5 (1 fix / 2 commits — denominator is tiny; not a quality signal here).

## Planning quality

- Description: **complete** — What & why, proof-of-no-behavior-change section (test plan equivalent), spec/living-doc note. No Performance & Cost section, acceptable for a byte-identical string refactor with zero new API calls.
- Scope: clean — single concern, 257 LOC, branch lifetime under an hour.
- No revert/redesign indicators.

## Process efficiency

- Iteration: efficient (1 local cycle, 0 post-push).
- Automation opportunities: none new — the golden-fixture + old-code-vs-new-code execution harness *was* the automation.
- Improvement note: the PR body omitted the `## Local Review` / `Steps skipped:` / `## Step Timing` sections, which forces post-mortems to reconstruct local-review evidence from commit messages and leaves stepCompliance/stepTiming null. Same omission as recent plush-press PRs (e.g. #325).

## Knowledge updates

- `~/.claude/knowledge/process-patterns.md` — STRENGTHENED the "ship the persistence/parameterization contract first as a byte-identical no-op PR" entry (Multi-PR Feature Coordination section) with #327: the recipe generalizes to prompt-language parameterization behind a default constant, and the positive-assertion-over-absence-assertion test lesson. No new adversarial-review checklist entries.
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` — entry appended (469 PRs total).
- `~/.claude/knowledge/metrics/dashboard.html` — METRICS_DATA regenerated.

## Recommendations

1. **Restore the `## Local Review` + `Steps skipped:` + `## Step Timing` sections in PR bodies.** Two consecutive plush-press PRs (#325, #327) lack them, so shift-left rate, step compliance, and timing are untracked and adversarialCatchRate must stay "unmeasured." The orchestrator template should emit them even when the answer is "0 findings / none skipped."
2. **Keep the positive-assertion discipline** when parameterizing defaults: assert the custom value appears at every substitution site (both branches), not merely that the old literal is gone.
3. **Stage 2 escalation:** the resolution/wiring PR (style_id → StylePromptText) changes runtime behavior for real books — route it through the full fresh-context critic rather than the lightweight gate, per the risk-graduation pattern.
