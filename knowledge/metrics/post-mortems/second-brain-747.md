# POST-MORTEM: second-brain PR #747 — feat(tags): canonicalize tag names at write time so variants converge

Branch: feat/tag-write-canonicalization → main | Author: padminipyapali | ~9m create→merge
Size: +95 -19 across 4 files (2 source, 2 test), 1 squashed commit
Merged: 2026-06-26T06:15:18Z | Closes #746

## LOCAL REVIEW (pre-push)
  CodeRabbit: not tracked (skipped — lightweight review for sub-100-LOC, server-only PR)
  Adversarial: 0 findings, 0 fixed (gate PASS, 0 must-fix, all tiers evidenced)
  Critic: skipped per lightweight-review convention (plan was independently adversarially reviewed)
  Shift-left rate: n/a (nothing surfaced to shift left; review value landed at the plan stage)

## STEP COMPLIANCE
  Steps run: 1, 2a, 2b, 3, 4c, 4d, 5 (7/9)
  Steps skipped: 4a (/simplify), 4b (CodeRabbit) — reason: documented sub-100-LOC lightweight-review convention
  Compliance rate: 77.8%
  Skip assessment: good (0 post-merge issues; plan was adversarially reviewed, so the skipped critic had no gap to fill)

## STEP TIMING
  not parseable into per-step minutes — body has a ## Step Timing section but as narrative prose:
  explore → architect → adversarial plan review (GREENLIGHT-with-split) → implement (1 pass) → gates → adversarial gate → PR, single session.
  Per-step minutes recorded as null; emit the | Step | Duration | table next time.

## REVIEW FRICTION (post-push)
  Review rounds: 1 (adversarial gate only; no GitHub review rounds)
  Comments: 0 inline, 0 substantive general (only Vercel bot)
  Categories: all 0
  Timeline: created → merged: ~9m (local dev loop ran before push)

## ADVERSARIAL REVIEW EFFECTIVENESS
  Pre-push catch potential: n/a — adversarial gate found 0 must-fix / 0 should-fix; code matched the pre-reviewed plan.
  Covered but missed: none
  Not covered (new categories): none

## FIX-UP METRICS
  Post-merge fix rate: 0.0 (0 post-merge fix PRs — #747 is the latest merged PR, verified via gh pr list)
  Pre-merge catch rate by step: 4a:0 | 4b:0 | 4c:0 | 4d:0 | post-push:0 (single squashed commit, no fix commits)
  Pre-merge iteration count: 1 (single pass; plan pre-reviewed)
  Fix-up taxonomy: all 0
  Legacy fix-up ratio: 0.0 (0 fix / 1 total commit)

## adversarialCatchRate
  Value: UNMEASURED (not 1.0, not 0).
  caught-in-code = 0 (critic intentionally skipped; adversarial gate found nothing in the implementation).
  escaped-post-merge = 0 (latest merged PR; no follow-up fix touches the feature area).
  0/(0+0) is undefined → recorded as "unmeasured" per the metric-integrity rule. The clean result reflects
  that the substantive review happened at the PLAN stage (adversarial plan review), not the code stage.

## PLANNING QUALITY
  Description: complete (What & why, How, Scope, Testing, Local Review, Step Timing — the #745 recommendation was acted on)
  Scope: clean — deliberately right-sized ~3× via mid-stream product conversation (canonicalize core only; pg_trgm hint + destructive backfill deferred)
  Branch lifetime: ~9m on GitHub (single session)
  Planning checklist: covered (entry points enumerated across all write sites; search.ts read lane intentionally untouched)

## CODE QUALITY SIGNALS
  Recurring issues: none
  New unrecorded patterns: 1 — "phase-gate the destructive/scale-sensitive parts of a feature behind an actual-data trigger"

## PROCESS EFFICIENCY
  Automation opportunities: emit the ## Step Timing table (per-step durations) so the skill can parse minutes instead of null
  Iteration: efficient (1 round)
  CI status: Vercel SUCCESS; server 2282 passed / 48 skipped

## KNOWLEDGE UPDATES
  - strategic-decisions.md (Feature Scope): added the phase-gate/right-size-to-actual-scale bullet (net-new — distinct from "cut unproven config" and from baby-name-picker's "defer the decorative layer").
  - Canonicalization / normalizer-ordering class NOT duplicated — already fully in database-patterns.md (#746 + #740 bullets); #747 is a clean application, not a new instance.
  - Project artifact: docs/features/_cross-cutting/post-mortems/POST_MORTEM_PR747.md
  - Metrics + dashboard updated (402 PRs).

## RECOMMENDATIONS
  1. Keep the ## Local Review + Steps skipped: + ## Step Timing sections (the #745 recommendation worked); next time emit Step Timing as the parseable per-step table.
  2. When the deferred backfill PR lands, collapse search.ts's dual canonical+literal candidate set to canonical-only and ship the migration with a dry-run (standing #740/#746 lesson).
  3. For deliberately-skipped-critic lightweight PRs, record adversarialCatchRate as "unmeasured", never a fabricated 1.0.
