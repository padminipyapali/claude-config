# Post-Mortem: plush-press PR #355 — Show the style badge on every book-scoped generation page.

- **Branch:** feat/style-badge-everywhere → main | **Author:** padminipyapali | **Merged:** 2026-07-20T22:53:53Z
- **Size:** +86 −1 across 7 files, 1 commit | **Open → merge:** ~4.7 minutes | **CI:** studio SUCCESS (first run)

## What shipped

Operator demand ("make sure every page has it written very clearly"): the shared display-only `StyleBadge` (verbatim component + states, no new variant) added to every book-scoped generation surface — create-scene top bar (derived from the page's existing 6c backdrop-style state, no extra request) and the Wizard step rail (`useRenderStyleBadge`). Audit confirmed workspace header + SceneCanvas already carried it; non-book-scoped creators deferred to Stage 7 by design.

## Local review (pre-push)

- **Critic (fresh-context adversarial):** OK to ship, 0 must-fixes. 2 findings: 1 NIT (trailing blank line — taken, folded into the single commit) + 1 MINOR (the Wizard's second `fetchRenderStyle` via `useRenderStyleBadge` alongside `useResolvedStyle`).
- **MINOR routing decision (deliberate, recorded in the PR body):** NOT hot-patched. It is the third data point of the duplicated-resolve shape first deferred in #328; the #328 escalation rule is now formally triggered and the fix is routed to the queued `useResolvedConfig` consolidation (`docs/HOOKS_HARDENING_PLAN.md (b)2`), which will consolidate all call sites in one reviewed pass instead of one-of-three in a display-only diff.
- **CodeRabbit CLI** (`-t all --base main`): 0 findings.
- **Gates:** typecheck 0 · lint 0 · full vitest green · next build 0.
- **Shift-left rate: 100%** — every finding surfaced anywhere in the PR's life was caught locally.

## Step compliance

- Steps run: 1, 2a, 2b, 3, 4b (CodeRabbit), 4c (adversarial critic), 4d (CI), 5 → 8/9, compliance 0.89.
- Skipped: 4a (simplify) — small display-only wiring diff; both reviewers ran clean/NIT-only.
- **Skip assessment: good** — 0 post-push comments, 0 post-merge fixes; nothing a simplify pass would have caught escaped.
- Step timing: not tracked (no `## Step Timing` section).

## Review friction (post-push)

- Review rounds: 1 (self-merged after green CI, no GitHub reviews — standing solo-dev pattern). Inline/general comments: 0.
- Timeline: created 22:49:09 → merged 22:53:53 (~4.7 min; CI ran 22:49:14–22:53:49).

## Adversarial review effectiveness

- **adversarialCatchRate = 1.0 (evidence-based):** defect denominator = 2 (critic's NIT + MINOR); post-push findings 0; post-merge fixes 0 (no merged PR after #355 touches this area; open #356 is unrelated JPEG handling). Critic caught 2/2.
- Critic also validated the **per-page badge-truth doctrine**: the badge reflects what THAT page's paid action attaches (create-scene derives from its own backdrop-style state), not a global readout — the correct contract for a display-only trust surface.

## Fix-up metrics

- Post-merge fix rate: 0.0 (ideal).
- Pre-merge catch by step: 4d (adversarial) = 1 fix (the NIT, folded pre-commit); all other steps 0.
- Pre-merge iteration count: 1 (healthy).
- Taxonomy: style 1. Legacy fix-up ratio: 0/1 = 0%.

## Planning quality

- Description: complete (What, audit of surfaces, Local Review, Tests, LOC). Entry points enumerated (which pages carry the badge, which are out of scope until Stage 7). Cost impact addressed inline ("no extra request" on create-scene; the Wizard's extra fetch named and routed).
- Scope: clean — single concern, 87 LOC, branch lifetime minutes.

## Code quality signals

- Recurring class: duplicated async style-resolve hooks (3rd occurrence: #328 → #334-era → #355). Now formally escalated to the `useResolvedConfig` consolidation docket rather than re-deferred ad hoc.
- No new unrecorded defect patterns; no adversarial-review checklist gaps (zero post-push findings to classify).

## Process efficiency

- Automation opportunities: none new — the consolidation docket is the terminal move for the recurring class.
- Iteration: efficient (1 round). CI: all passed first run.

## Docket arc (run closure)

#355 closes the Art-Styles run: **15 merged PRs in ~36 hours (#330–#355), operator-feedback-driven, 100% shift-left throughout** — zero post-push review comments and zero post-merge fix PRs across the run. Process residue: critic/CodeRabbit division of labor (semantic vs cached-async/TOCTOU), the design-time cached-async planning rule (adversarial-review §0.16b), the slim-lane calibration data (#342/#343), the tests-live-data tripwire campaign (#335/#337/#340), and the route-to-docket rule recorded from this PR.

## Knowledge updates

- `process-patterns.md` (Follow-Up Discipline): new entry — route a recurring-redundancy MINOR to its pre-registered consolidation docket at the third data point instead of hot-patching; conditions for legitimate routing (non-correctness finding, named queued artifact, decision recorded in PR body); includes the docket-arc closure note.
- Metrics appended to `post-mortem-metrics.json` (495 PRs); dashboard regenerated.

## Recommendations

1. **Audit the docket landing:** the next plush-press post-mortem that touches style hooks must check whether the `useResolvedConfig` consolidation (`docs/HOOKS_HARDENING_PLAN.md (b)2`) actually shipped — a routed finding that never lands is worse than a spot-fix. If a FOURTH duplicated-resolve data point appears before the docket lands, that is drift; the docket becomes the mandatory next PR.
2. **Stage 7 follow-through:** the non-book-scoped creators (character/look/poses/object) were explicitly deferred; carry the per-page badge-truth doctrine into that stage's plan.
3. No process changes needed — this PR is the shape to repeat (single concern, <100 LOC, both local lenses run, deliberate routing recorded in the body).
