# Post-mortem: plush-press #334 — Show the resolved art style on every render surface (style badge)

- **Branch:** feat/style-badge → main | **Author/merger:** padminipyapali (self-merge, no peer review — solo workflow)
- **Merged:** 2026-07-20T14:20:59Z | branch-to-merge ~26 min
- **Size:** +784 / −36 across 14 files, 1 squashed commit. Declared split: 407 source / 377 test. Over the 600 soft cap on the raw number, declared and justified in the body (comment-heavy presentational component + label fields on one route; single concern).
- **Origin:** operator-driven UX request — she could fire a paid render with zero on-screen indication of which art style it would use (invisible style plumbing after the Art Styles series #327–#333).

## Local review (pre-push)

- **/simplify (4a):** applied — consolidated render-gate comment; single `styleForCurrentBinding` shared by badge and gate.
- **CodeRabbit CLI (4b):** single clean run (no rate-limit retry needed), 3 findings, all fixed:
  - **MAJOR — stale-style rebind race:** a same-book `styleId` rebind could submit the stale style; resolved state was keyed only by book id. Fixed by keying resolved state to the requested binding in both the badge and the render gate + same-project rebind regression test.
  - minor — `useRenderStyleBadge` cache tagged by `styleId` too (rebind refetch shows loading) + hook rerender test.
  - minor — `.text { min-width: 0 }` so long names ellipsize instead of overflowing the toolbar.
- **Fresh-context critic (4c):** SHIP + 2 MINOR — 1 applied, 1 consciously skipped with rationale. Walked entry points (unbound / bound-resolved / bound-dangling / book-switch / same-book rebind / at-cap); confirmed badge mirrors gate cell-by-cell.
- **Gates:** typecheck / lint / build / full suite green locally; re-run green after fixes.
- **Skipped:** Playwright (declared: static indicator, jsdom component tests cover every badge state) and 2b (retired from flow).

## adversarialCatchRate = 0.4 (measured)

n=5 local findings: critic 2, CodeRabbit 3. 0.4 = critic-caught / total. 0 post-push comments, 0 post-merge fixes → shift-left 100%.

**Third consecutive data point on the critic-vs-CodeRabbit division of labor** (#330 partial-failure supersede gap, #333 two-snapshot read, #334 stale-key rebind race): CodeRabbit alone caught the staleness/consistency/TOCTOU-family MAJOR each time on a critic-SHIPped surface, while the critic owns the semantic/latent-landmine family. Established regularity, not coincidence — recorded as such in `process-patterns.md`.

## CI anomaly: merged over a pre-existing red main

The PR's single CI run FAILED — but the failure is `src/lib/scene/__tests__/recipeRefs.test.ts:204` asserting `orphans.toEqual([])` against live repo content, broken by operator autosave commits (`shalu-pini` recipe ref without its crop file) at ~04:53/05:04, ~9 hours before this branch existed. Main was already red/cancelled on those autosaves. This is a recurrence of the known "tests must not couple to product data" class (2026-06-16 incident), now with an allowlist escape hatch (`DOCUMENTED_UNSEEDED`) that proves the coupling — each in-progress character requires a test edit. Merging over red was a judgment call that only works because the failure is provably pre-existing on main; it is in tension with the MERGE GATE rule ("CI green before merge"). Strengthened `testing-patterns.md`.

## Metrics summary

- Review rounds 1; 0 comments; postMergeFixRate 0.0 (checked: #334 is HEAD of main at analysis time, no follow-up fix PRs).
- Pre-merge catch by step: 4a=1, 4c=3, 4d=1, postPush=0. Iterations: 1 (healthy).
- Taxonomy: correctness 2 (rebind race, cache staleness), style 2 (min-width, simplify consolidation); the critic's applied MINOR was not itemized in evidence — 4 of 5 findings classified.
- Planning quality: complete (What & why, state-mirror guarantee design section, per-state entry-point walk, LOC declaration). No Performance & Cost section, but the body explicitly states "no extra request" (badge derives from already-fetched state) — the substantive answer, if not the heading.
- Step compliance: 8/9 (~0.89), skip assessment **good** (no escapes attributable to skips).

## Process notes

- **State-mirror design is the star:** badge derives from the SAME `styleState` the render gate consumes — one source, so the indicator can never disagree with what a click paints. This is the "store computed results alongside display text / single source" convention applied to UI truthfulness, and it is what made the CodeRabbit MAJOR fixable in one place (keying that shared state).
- Operator-language-only strings maintained (`style ref`, never `harmonize`/`specimen`) — consistent with the product-copy rule.
- CodeRabbit needed no retry this time (contrast #330's rate-limit lesson) — one clean run produced the MAJOR.

## Recommendations (ranked)

1. **Fix `recipeRefs.test.ts` orphan assert** — move the live-repo `orphans.toEqual([])` to a fixture block or invariant per `testing-patterns.md`; the allowlist is a treadmill. This is the only reason main/CI is red.
2. **When merging over a red check, record the pre-existence proof in the PR** (link to the failing main run) so the merge-gate exception is auditable rather than silent.
3. **Codify the 3-for-3 division of labor:** on any PR touching cached/keyed async state, treat a critic SHIP as necessary-not-sufficient until CodeRabbit has run clean (now in `process-patterns.md`).
4. Consider itemizing critic MINORs (text + applied/skipped) in the PR body's Local Review section so fix taxonomy is fully computable.

## Knowledge updates

- `~/.claude/knowledge/process-patterns.md` — division-of-labor entry strengthened with the third consecutive data point (#334 stale-key rebind race).
- `~/.claude/knowledge/testing-patterns.md` — live-product-data snapshot entry strengthened with the `recipeRefs.test.ts` recurrence + merged-over-pre-existing-red caveat.
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` — entry appended (473 total); dashboard regenerated.
