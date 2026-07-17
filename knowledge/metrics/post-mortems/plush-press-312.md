# POST-MORTEM: plush-press PR #312 — Remove the ✨ Variations feature from the scene editor

Branch: `chore/remove-variations` → `main` | Author: padminipyapali | ~15 min branch lifetime
Size: +30 −638 across 7 files, 2 commits | Merged 2026-07-16T06:08:10Z (self-merged, no peer review)

## Summary

Pure-subtraction PR removing the ✨ Variations control from the scene editor. Deleted the
`Variations.tsx` component, `variationsPrompt.ts` + its test, two test suites
(`Variations.test.tsx`, `SceneCanvasVariations.test.tsx`), and the SceneCanvas wiring (import,
render site, `onVariations` handler, `variationsNotice` state). Added one focused replacement
test in `SceneCanvasRender.test.tsx` to preserve a coverage assertion the deletion would
otherwise have dropped. Verified against `origin/main`: zero Variations residue, `descVariation`
(the unrelated same-name feature) fully intact, candidate picker intact, no post-merge fix PRs.

## LOCAL REVIEW (pre-push)
- CodeRabbit CLI: 0 findings, 7 files (ran clean, on the FREE allowance — repo not connected to an
  accessible CodeRabbit org).
- Adversarial: 1 finding, 1 fixed. Fresh-context critic re-ran all four gates independently and
  specifically verified no shared candidate-picker code was removed as collateral (the main
  regression risk, since Variations and multi-version Re-render share the picker). Its one finding:
  the deleted `SceneCanvasVariations.test.tsx:211` was the only SceneCanvas-level assertion pinning
  `busy = renderBusy || tuneBusy || savingBackdrop`. Fixed immediately per default-to-fix.
- Shift-left: the one issue found was caught and fixed locally (adversarial, step 4d).

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4b, 4c, 4d, 5 (8/9)
- Steps skipped: 4a (/simplify) — justified in PR body: a 638-line pure deletion has nothing to
  simplify.
- Compliance rate: 89%
- Skip assessment: **good** — zero post-merge issues; nothing /simplify could have caught in a
  deletion.
- Note: 2b counted as RUN — the diff adds a `.test.tsx` file (mutation-verified replacement test),
  which is precisely the Step 2b hardening concern.

## STEP TIMING
- No `## Step Timing` section in the PR body; per-step durations NOT tracked (stepTiming largely
  null). Derivable wall-clock only: first commit 05:53:18Z → merge 06:08:10Z ≈ 15 min total; PR
  open 06:02:56Z → merge 06:08:10Z ≈ 5.2 min.
- Known unbilled latency: BOTH the implementer and the critic signalled idle WITHOUT sending their
  reports (reports went to text output the orchestrator cannot see), costing two explicit
  SendMessage nudge round-trips.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED). Self-merged with no GitHub reviews.
- Comments: 0 inline, 0 general.
- Categories: all zero.
- Timeline: created → merge ≈ 5 min; no external review event.

## ADVERSARIAL REVIEW EFFECTIVENESS
- `adversarialCatchRate` = **"unmeasured"** (NOT 1.0). Rationale: zero post-push reviews, zero
  inline comments, zero post-merge fix PRs means the denominator — issues that ESCAPED the local
  gates — has no independent oracle. The PR explicitly did NO live browser click-through (Tune and
  the candidate picker confirmed by tests + static tracing only), so a runtime-regression class was
  never exercised; an escape there would be invisible. The critic found exactly 1 issue and it was
  fixed pre-merge; n=1 with no escape oracle does not support a rate. Recorded honestly as
  unmeasured per the standing anti-fabrication rule.
- Covered but missed: none identified.
- Not covered (candidate new checklist items): the keyword-collision-on-removal check and the
  shared-CSS-module check (see Knowledge Updates) are additions surfaced by this PR.

## FIX-UP METRICS
- Post-merge fix rate: **0.0** (0 post-merge fix commits/PRs within 48h — verified via
  `gh pr list` filter). The ideal.
- Pre-merge catch rate by step: 4a=0, 4b=0, 4c=0, **4d=1**, postPush=0. The single fix commit
  (`9ace0d95`, the replacement test) is attributed to the adversarial critic (4d). Note: the
  keyword classifier would MISS this commit (no fix/address/resolve/nit token in
  "Pin the shared tuneBusy render gate…"), so it was classified by substance per Step 6.
- Pre-merge iteration count: **1** (healthy).
- Fix-up taxonomy: test-quality=1, all others 0.
- Legacy fix-up ratio: **0.5** (1 fix / 2 commits) — INFLATED by the tiny commit count, not by
  churn. The "fix" is a test-quality addition that closes a real coverage gap pre-merge; that is
  the gate working, not rework.

## PLANNING QUALITY
- Description: **complete** — clear "What's removed / What's deliberately kept / Coverage /
  Verification / Not verified" structure. Notably names each surviving sibling (`descVariation`,
  the `/tune` route, the candidate picker, the shared `tune*` CSS) so a reviewer can confirm the
  removal boundary.
- Scope: **clean** — pure subtraction, single concern, one deliberate justified skip. No redesign
  or revert commits.
- Branch lifetime: ~15 min.
- Planning checklist: the removal-boundary enumeration substitutes appropriately for the
  entry-point/perf sections (a deletion adds no code paths or cost).

## CODE QUALITY SIGNALS
- Recurring issues: none in the code.
- Recurring PROCESS issue: report-before-idle failure recurred cross-project AND extended to the
  critic role (previously logged for implementers on the second-brain admin series).
- New unrecorded patterns captured: keyword-collision triage on removal PRs; shared-CSS-module
  "not orphaned" rule; mutation-verify-the-pinning-test; orchestrator-brief citations are
  hypotheses the implementer should correct.

## PROCESS EFFICIENCY
- Automation opportunities: the shared-CSS-module regression class escapes lint/typecheck/test
  entirely (CSS-module member access is untyped, unused-class detection isn't standard) — a
  candidate for a future dead-CSS-class linter, but only a browser check or the manual grep catches
  it today.
- Iteration: **efficient** (1 round, 0 post-merge fixes).
- CI status: `studio` check SUCCESS.

## KNOWLEDGE UPDATES
- `process-patterns.md` → **Scope Decisions**: two new rules — (a) a removal PR's grep sweep is a
  NAME-collision surface; triage by owning feature and name out-of-scope partitions in the PR body
  (the `descVariation` near-miss); (b) ask "what else uses this?" of every touched artifact — a
  zero-diff on a file you expected to shrink is a legitimate outcome (the shared `/tune` route +
  helper).
- `process-patterns.md` → **UI/CSS Gaps**: CSS-module classes are shared by file scope; never treat
  a class as orphaned because one component that used it was deleted (the `scene.module.css`
  zero-change finding).
- `process-patterns.md` → **Review Discipline**: an implementer that contradicts the orchestrator's
  spawn-brief code citation is doing its job; brief citations are hypotheses (the 2293-vs-643 render
  gate correction).
- `testing-patterns.md` → **Test Design**: mutation-verify any test written to pin a specific line
  (break → RED → restore); a green run only proves the test passes, never that it tests anything —
  most important for a replacement test closing a deletion's coverage gap.
- `orchestrator-protocol.md` → strengthened the existing Report-Before-Idle rule: it is NOT
  implementer-specific (put it in EVERY teammate brief, critics included), name the mechanism
  ("text output is invisible; the only delivery is SendMessage"), and note it's a
  liveness/plumbing failure not a quality one.
- Repo ledger candidate (NOT yet written — awaiting approval): `docs/DECISIONS.md` has no entry for
  killing Variations; per project CLAUDE.md, retiring a shipped feature is a notable decision worth
  a dated entry.

## RECOMMENDATIONS (ranked)
1. Bake the report-before-idle sentence — naming SendMessage as the only visible delivery channel —
   into the SHARED spawn-brief template both implementer and critic inherit. This failure has now
   recurred across two projects and both agent roles; per-spawn reminders aren't sticking.
2. Add a "removal triage" line to the removal-PR path: partition the grep sweep by owning feature,
   name out-of-scope same-name partitions in the PR body. #312 did this well organically — make it
   the standard so the next deletion doesn't rely on the implementer remembering.
3. Consider a dead-CSS-module-class linter for the studio — the one regression class here that no
   existing gate can see.
4. Write the `docs/DECISIONS.md` entry recording the Variations retirement (pending operator
   approval per the reporting rule).
