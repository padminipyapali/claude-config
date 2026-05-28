# POST-MORTEM: baby-name-picker PR #83 — Render Top Picks display text in Cormorant Garamond serif

Branch: `fix/top-picks-serif-font` → `main` | Author: padminipyapali | created→merged ~7.7 min
Size: +129 -1 across 2 files, 2 commits (1 fix commit + 1 merge-from-main commit)
Squash-merged to `main` as `bedd19f` on 2026-05-28T21:43:46Z. Self-merged (solo dev).

## Context

Sibling-sweep follow-up to PR #81 (compare detail overlay font fix). PR #81's
adversarial sibling-sweep found the identical `fontFamily`-omission anti-pattern
in `app/top-picks.tsx`: eight display-text styles borrowed `fontSize`/`fontWeight`/
`fontStyle`/`letterSpacing` from the serif `typography` tokens (or hardcoded display
sizes) but omitted `fontFamily`, so the Top Picks title, ranked names, rank numbers,
taste insight, "X wins" meta, keep-going prompt, and empty-state text all fell back
to system sans-serif instead of Cormorant Garamond. #81 scoped this OUT; #83 fixed
it same-day in a focused PR.

Files changed:
- `app/top-picks.tsx` (+10/-1) — added matching `fontFamily` to all 8 display styles
  (names → `displayRegular`, titles/rank numbers → `displayLight`, meaning/insight/
  prompt → `displayLightItalic`), mirroring `NameCard.tsx` / `NameDetailBody.tsx`.
  No sizes, weights, colors, layout, or copy changed.
- `src/__tests__/topPicksFonts.test.tsx` (+120, new) — 11-test regression suite
  asserting resolved serif `fontFamily` on all 8 changed styles, the
  `itemName`/`itemNameTop` style-array invariant, and a negative case (icon glyphs
  stay sans).

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` CodeRabbit line; not run — fontFamily-only diff).
- Adversarial: 0 findings, 0 fixed. Tier 0 greps clean (no placeholders, interactive
  elements, hardcoded colors, or date/state logic); ui-react a11y/animation unaffected.
- Fresh-context critic: SHIP — verified each `fontFamily` choice against design tokens
  and reference components, confirmed all Cormorant weights are loaded via `useFonts`
  (no silent fallback), confirmed scope discipline, validated the regression test.
- Shift-left: n/a (no issues surfaced at any gate; clean mechanical fix).

## STEP COMPLIANCE
Step compliance: not explicitly tracked — the PR body has a `## Local Review` section
but NO `Steps skipped:` line, so per the post-mortem rule `stepCompliance` is recorded
as null. Inferred from body content: Plan (1), Implement (2a), Test/tsc+jest (3, lint
honestly unrunnable), Adversarial (4c), fresh-context critic, Push/PR (5) all ran;
CodeRabbit (4b) and CI (4d, repo has no CI) did not. The missing `Steps skipped:` line
is itself a minor process-drift signal — sibling PRs #78/#80/#81/#84 all carried it.

## STEP TIMING
Not tracked (no `## Step Timing` section). Wall-clock created→merged ~7.7 min.

## REVIEW FRICTION (post-push)
Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general. No GitHub reviews
(solo flow; the fresh-context critic is the in-process reviewer). Timeline: created→merge
~7.7 min total.

## ADVERSARIAL REVIEW EFFECTIVENESS
Pre-push catch potential: n/a — no issues found by any gate, none escaped to post-merge.
Covered but missed: none. Not covered (new categories): none.
adversarialCatchRate = 0.0 (no findings to catch; not a quality signal here).

## FIX-UP METRICS
- Post-merge fix rate: 0.0 — no follow-up PR fixes #83. (PR #84 merged 53s earlier is a
  SEPARATE sibling bug: onboarding boy-card blue + compare-card spacing, not a fix of #83.)
- Pre-merge catch rate by step: all 0 (no fix commits; the single non-merge commit is the
  feature/fix itself).
- Pre-merge iteration count: 1 (healthy — single clean pass).
- Fix-up taxonomy: all 0.
- Legacy fix-up ratio: 0.0.

## PLANNING QUALITY
Description: complete — Summary, Designs (with justified no-mockup rationale + cross-link to
#81's on-device verification), Test plan, Local Review, Notes. Scope: clean, atomic, single
surface, zero scope creep. Branch lifetime: short (~7.7 min created→merged). Planning
checklist: appropriate for a mechanical font-family fix; no Performance & Cost section needed
(no API/DB/perf surface).

## CODE QUALITY SIGNALS
Recurring issue (cross-PR, design-level, not a #83 defect): the `fontFamily`-omission bug
class recurs because each component hand-copies typography-token fields and can silently drop
`fontFamily`. This is now the SECOND instance (#81 NameDetailBody, #83 top-picks). The upstream
fix — a token-derivation helper that carries `fontFamily` by construction — remains uncaptured.
New unrecorded patterns: none (both relevant patterns already in process-patterns.md).

## PROCESS EFFICIENCY
Automation opportunities: (1) a `fontFamily`-by-construction style helper would eliminate the
recurring bug class at the source. (2) install `eslint` + `eslint-config-expo` so the mandated
`npx expo lint` gate actually runs repo-wide (phantom gate, surfaced #81, recorded honestly #83).
Iteration: efficient (1 round). CI status: no CI configured (`statusCheckRollup: []`).

## NOTABLE IMPROVEMENT OVER #81 (lint honesty)
#83 hit the same unrunnable lint gate as #81 but recorded it correctly:
`[ ] npx expo lint — could not run: eslint is not installed ... unrunnable repo-wide`,
plus a Notes paragraph recommending the install. #81 had falsely written
`[x] npx expo lint — no new findings` (a phantom pass — eslint was never installed).
This is the correct pattern when a mandated gate cannot execute: unchecked box + explicit
reason, NOT a false checkmark. Documentation-integrity improvement, PR-over-PR.

## KNOWLEDGE UPDATES
- `process-patterns.md` line 134 (sibling-sweep follow-up) — strengthened: the #81-predicted
  follow-up is now CONFIRMED LANDED as #83; the loop is a full closed cycle (sweep→scope-out→
  same-day atomic follow-up PR with regression test), not just a prediction. Reiterated that the
  upstream `fontFamily`-by-construction helper is still uncaptured and the next display-text
  screen should trigger building it rather than fixing a third instance.
- `process-patterns.md` line 133 (phantom lint gate) — strengthened: #83 models the CORRECT
  behavior (honest `[ ]` + reason) vs #81's phantom `[x]`. Lesson made bidirectional: verify a
  `[x]` has real output AND leave a genuinely unrunnable gate `[ ]` with reason. Escalated the
  eslint-install remediation to a dedicated tooling PR (now spanning #81→#83 unaddressed).

## RECOMMENDATIONS (ranked)
1. Install `eslint` + `eslint-config-expo` in a dedicated tooling PR. The phantom `npx expo lint`
   gate has now spanned #81→#83 unaddressed; per Follow-Up Discipline, escalate prose to a
   committed artifact rather than re-noting it.
2. Build the upstream `fontFamily`-by-construction token-derivation helper so display-text styles
   cannot drop `fontFamily`. Two instances (#81, #83) is the signal to fix the source, not a third
   call site.
3. Include the `Steps skipped:` line in every PR body, even trivial fixes — #83 omitted it, breaking
   the otherwise-consistent #78/#80/#81/#84 step-compliance trail.
