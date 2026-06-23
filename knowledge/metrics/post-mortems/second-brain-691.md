# POST-MORTEM: second-brain PR #691 — fix(web): resolve undefined CSS custom properties and clear App.css stylelint errors

Branch: `fix/css-stylelint-689` → `main` | Author: padminipyapali | created→merged ~68s (self-merged)
Size: +72 −42 across 1 file (`packages/web/src/App.css`), 1 commit
Merged: 2026-06-23T04:14:04Z | Closes #689

## Context

The deferred follow-up to #688. #688 fixed a biome error that had been short-circuiting the
chained root lint script `biome lint . && npm run lint:css`; fixing biome unmasked 83
previously-hidden stylelint errors in `App.css`, correctly deferred to issue #689 with proper
bug framing rather than dismissed as cosmetic. #691 closes #689.

The diff has three components:
1. **Real visual bug (11 undefined custom properties)** — `App.css` referenced
   `--coral-rgb` (×10) and `--text-tertiary` (×1), custom properties that are NEVER defined
   (introduced in PR #594). The browser silently dropped those declarations, so the affected UI
   rendered with inherited/wrong colors: active `.project-detail-tab` text+underline,
   `.project-notes` drag-active outline+bg tint, coral primary buttons, and `.today-card`
   empty-state text. Fixed by mapping each to the existing token it was clearly meant to be —
   `--coral-rgb`→`--accent-rgb` (`179 74 42`/`#b34a2a`), `--text-tertiary`→`--text-muted`
   (`#a8a49c`). No new colors invented. Sibling-swept all of `packages/web/src/` (.css+.tsx):
   zero stale references.
2. **Value-preserving cosmetic auto-fixes** — modern space-separated `rgb()`, `%` alpha,
   `rgb()` over `rgba()`, blank-line conventions, `word-wrap`→`overflow-wrap`. Verified no color
   VALUES changed (`rgba(0,0,0,0.06)`→`rgb(0 0 0 / 6%)`).
3. **Out-of-bucket lint fixes (mid-scope escalation)** — see below.

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` line; folded — see below).
- Adversarial: 0 findings, 0 fixed — single fresh-context reviewer folded the critic role into
  the adversarial gate, gate PASSED.
- Shift-left: n/a (no findings surfaced).

The review process for this PR was: implementer → ONE fresh-context reviewer that did the
critic's job AND the adversarial gate in a single pass, consistent with the user's
lightweight-review-for-small-PRs preference (MEMORY.md). Justified: small, mostly-cosmetic
CSS-only diff. The gate verified token mappings semantically correct, every rgba()→rgb()
conversion value-preserving, and zero stale keyframe references. PASS.

## STEP COMPLIANCE
- Steps run: 1, 2a, 3, 4c, 5 (the standalone 4a/4b folded into the single fresh-context reviewer)
- Steps skipped (as separate steps): 4a /simplify, 4b CodeRabbit — folded into 4c, not omitted
- Compliance rate: ~56% (by the 9-step rubric; understates reality — the review WORK happened,
  just in one collapsed reviewer pass)
- Skip assessment: **good** — 0 post-merge issues; #691 is the latest merged PR.
- Tracking gap: body has a `## Verification` section with green-lint evidence but NO explicit
  `Steps skipped:` line, so the post-mortem reconstructed the lane from the orchestrator narrative.

## STEP TIMING
Not tracked (no `## Step Timing` section).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; no GitHub reviews — self-merged solo dev)
- Comments: 0 inline, 0 substantive general (1 Vercel bot comment, excluded)
- Categories: all zero
- Timeline: created → merged ~68 seconds. Vercel preview check SUCCESS. No peer review (expected
  for solo dev; not flagged as a defect).

## ADVERSARIAL REVIEW EFFECTIVENESS
- adversarialCatchRate: **unmeasured** — the reviewer VALIDATED the implementer's claims (PASS)
  with no evidence it independently CAUGHT an escaped issue, so the catch denominator is
  ill-defined. Marked unmeasured per the post-mortem-integrity rule, not hardcoded.
- Automation note: this entire class (undefined CSS custom properties) is automatable via
  `stylelint-value-no-unknown-custom-properties` — already captured in process-patterns.md
  UI/CSS Gaps. The chained-`&&`-lint short-circuit that hid these is captured under Automation
  Opportunities (sourced #688). #691 is the downstream cleanup of both.

## FIX-UP METRICS
- Post-merge fix rate: 0% (0 post-merge fix commits — #691 is the latest merged PR)
- Pre-merge catch rate by step: all 0 (single clean commit, no fix-up commits)
- Pre-merge iteration count: 1 (healthy)
- Fix-up taxonomy: all 0
- Legacy fix-up ratio: 0% (0 fix / 1 total commit)

## PLANNING QUALITY
- Description: **complete** — What & why, per-bucket breakdown, Designs (before→after color
  resolution), Verification (stylelint 0/83, root lint exit 0, 285 web tests pass), Closes #689.
- Scope: clean — single concept (resolve App.css lint to green), no redesign/revert commits.
- Branch lifetime: minutes.

## CODE QUALITY SIGNALS
- Recurring issues: none in this PR.
- New patterns captured: TWO process-level learnings (below).

## PROCESS EFFICIENCY
- Iteration: efficient (1 round, 1 commit, 0 fix-ups).
- CI: Vercel preview SUCCESS; root `npm run lint` exit 0; 285 web tests pass.

## KNOWLEDGE UPDATES
1. `process-patterns.md` → Scope Decisions: **Mid-scope escalation** — when reaching a
   fully-green gate requires touching errors OUTSIDE the plan's stated scope buckets, the
   implementer must ESCALATE for a scope decision (never silently expand, never silently leave
   the gate red). Mid-implementation the implementer found 14 errors outside the two scoped
   buckets (vendor-prefix `appearance`, non-kebab keyframe names, single-line keyframe
   declarations, deprecated `word-break`) and asked rather than silently expanding/leaving red;
   orchestrator approved fixing all 14. Implementer owns DETECTING out-of-scope work, orchestrator
   owns the DECISION to absorb-or-defer. Both anti-patterns (silent scope creep, silently-red
   gate) named.
2. `process-patterns.md` → Process Compliance: **Lightweight-review fold-critic-into-gate** —
   for a small mechanical single-file diff, folding the standalone critic into a single
   fresh-context reviewer that also runs the adversarial gate is a legitimate review-lane
   calibration, NOT a skip, PROVIDED fresh context (author-reviewer separation) is preserved and
   the reviewer can plausibly cover the whole surface. Boundary stated (not license to drop fresh
   context or fold on multi-surface/logic-heavy PRs). Notes the `Steps skipped:` tracking gap.

Checked both against existing patterns before adding: line 141 (mechanical auto-fixes are safe
skip candidates) and line 151's justified-skip buckets are adjacent but neither captured the
fold-critic-into-single-reviewer calibration or the mid-scope escalation decision point — both
are genuinely new.

## RECOMMENDATIONS
1. **Add the `Steps skipped:` line to the PR-body template / orchestrator hand-off** even when a
   `## Verification` section exists. #691's lane (fold-critic-into-gate) was reconstructible only
   from orchestrator narrative; an explicit `Steps skipped: 4a, 4b — folded into single
   fresh-context reviewer (small mechanical CSS diff)` line would have made the lane self-evident
   and kept the metric pipeline honest. (Recurring across second-brain #603/#688 and baby-name-picker #172.)
2. **Promote `stylelint-value-no-unknown-custom-properties` to the local lint gate** so undefined
   custom properties fail fast at author time rather than lurking behind a chained-`&&`
   short-circuit (the #594→#688→#689→#691 chain is the cost of not having this). Already noted in
   UI/CSS Gaps; the action is to wire it into `npm run lint:css`.
3. No further action on review depth — the lightweight lane was correctly calibrated for this
   diff and shipped 0 post-merge fixes.
