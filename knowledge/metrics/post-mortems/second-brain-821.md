# POST-MORTEM: second-brain PR #821 — first-class prioritize/reorder refinement edit

**Branch:** feat/sc-... → main | **Author:** padminipyapali | **Open→merge:** ~59s (essentially all dev time preceded PR creation)
**Squash-merged as:** 4aa3f91 | **Closes:** #817 (follow-up to #816/#818)
**Size:** +298 −12 across 8 files, 1 squashed commit (~150 production LOC, ~180 of adds are tests in 4 .test.ts files)

## What & Why

A first-class `prioritizeFirst: number[]` refinement edit so "schedule X first" / "X is highest priority" **deterministically** reorders the schedule-todos proposal.

The interpreter previously expressed "X first" only by emitting N−1 task-dependency edges ("every other todo depends on X") — the model had to DERIVE the full dependency fan-out, which it did unreliably. "prioritize the dentist" produced no edits at all (silent no-op); the reorder was a coin flip. Now the model identifies only WHICH todo(s) to prioritize (the irreducible intent) and the packer (`orderForPacking`) does the ordering deterministically, with the dependency floor preserved.

## Technical verification (against the merged diff)

- **`response.ts`** — `RefinementEdits` gains `prioritizeFirst: number[]`; the `interpret_refinement` prompt + tool-schema add a PRIORITIZE section and an explicit DEPENDENCY-vs-PRIORITIZE rule (addDependency reserved for pairwise "A before B"; prioritizeFirst for blanket "X first"). Validation keeps valid in-range `#numbers` in the model's given order, dedupes first-occurrence, drops non-integer/out-of-range/dup; `input.prioritizeFirst` guarded with `Array.isArray`.
- **`todo-scheduling.ts` `orderForPacking`** — seeds prioritized ids first in the topological walk. **Dependency floor preserved**: `visit` recursion pulls a prioritized todo's dependency chain in ahead of it (blocker emitted before the seed), and `packTodos`'s start-floor is untouched. Prioritization orders the SEED of the walk, never a real ordering constraint.
- **`schedule-todos-refine.ts` `runRefine`** — resolves `prioritizeFirst` `#numbers` → surviving todo ids, in order, deduped; a removed/batch number is dropped (`!survivingIds.has(id)`), so removing AND prioritizing a todo in the same turn is a safe no-op. `?? []` guards a pre-#817 / mock edit object on both seams.
- Back-compat is **byte-identical** when `prioritizeFirst` is omitted (empty seed array → the priority-sorted walk is unchanged).

## Process

- **SAME implementer** — 5th fix in the schedule-todos cluster this session; context reused across the cluster for BUILDING.
- **VALIDATE-FIRST REAL-MODEL RELIABILITY PROBE (N=10)** before+after, run on the LIVE model — the DECISIVE gate:
  - `prioritizeFirst→target`: **0/10 → 10/10** on the reported message ("…is highest priority … First to be scheduled").
  - Controls confirmed the model distinguishes a blanket "X first" (→`prioritizeFirst`) from a pairwise "do diapers before the dentist" (→`addDependency`) — the new prompt's DEPENDENCY-vs-PRIORITIZE rule actually discriminates on the real model. "prioritize the dentist" (was a silent no-op) now resolves.
- **Fresh-context critic = SHIP** — 0 blockers, 0 actionable findings. Load-bearing check (the structural risk): the prioritize seed does NOT violate the dependency floor (verified `orderForPacking` recurses deps first; `packTodos` start-floor untouched). Also confirmed validation drops out-of-range/dups, the removed-id no-op, and clean back-compat.
- **CodeRabbit (4b) NOT run** — ~150 production LOC, lightweight-review-small-PRs lane.
- 14 deterministic tests (no live model): `orderForPacking` (prioritized first, multi-order, empty=unchanged, unknown ignored, **dependency-floor**), `buildProposal`, `runRefine` (compose-with-remove, removed-id no-op), interpret validation (out-of-range/dup/order). Full server suite (2721) green. Vercel CI SUCCESS.

## Metrics

- **adversarialCatchRate:** `null` — **critic-ran-clean shade** (two-shades rule, process-patterns line 21). The critic RAN and returned SHIP with 0 actionable findings → `0/(0+0)` undefined → null (NOT a fabricated 1.0, NOT the critic-skipped null). A real catch-rate fraction is genuinely undefined here.
- **postMergeFixRate:** 0.0 — **0 post-merge escapes.** No PR after #821 touches schedule-todos / `response.ts` / `todo-scheduling.ts`. (#817 was the planned feature this PR closes, not a fix of it.)
- **reviewRounds:** 1 | **totalComments:** 0 | **preMergeIterationCount:** 1 (healthy)
- **stepCompliance:** 8/9 steps run; 4b (CodeRabbit) skipped (lightweight lane); complianceRate 0.889; **skipAssessment: good** (0 escapes, no post-merge issue a CodeRabbit pass would have caught).
- **planningQuality:** complete (What/Why/Validate-first/How/Tests/Review sections in body).
- **stepTiming:** not tracked (no `## Step Timing` section).

## Knowledge captured

`~/.claude/knowledge/llm-integration.md` — new entry (after the EDIT-VOCABULARY pattern):
> **Don't make the LLM emit DERIVED structure it computes unreliably — have it emit the minimal INTENT (the one fact only it knows) and let deterministic code derive the structure. Quantify the win with an N-probe (0/N → N/N).**

The diagnostic question: *is the model emitting a fact only it can know (which todo the user meant), or is it emitting computed/derived structure (the N−1 edges) that deterministic code could produce from a smaller input?* If the latter, push the derivation into code and have the model emit only the irreducible intent. The right gate for "is this LLM output reliable enough" is a real-model N-probe that produces a NUMBER (0/10 → 10/10), not a vibe. Sibling of the probe-as-scoping instrument (#818, which descoped this very work) and the real-model-validation family (#779).

## Process notes / recommendations

- **The 4b-skip remains unrecorded in-artifact.** No explicit `Steps skipped:` line in the PR body — the same gap noted across the schedule-todos cluster (#808/#813/#814/#818) this session. Recorded here as not-tracked (null) for CodeRabbit counts, not zero. A one-line `Steps skipped: 4b (CodeRabbit) — lightweight lane` in the body would close the in-artifact gap.
- **The probe-as-scoping → probe-as-ship-gate arc is the standout process win.** #818's probe found the old "X first" reorder fired ~50% of the time, which DESCOPED this work out of #818 and re-justified it as #817. The same instrument then became the ship-gate here (0/10 → 10/10). This is the validate-first probe doing double duty: first as a scoping descope, then as the reliability gate — the correct instrument for both, because only a real-model probe can quantify prompt-interpretation reliability.
