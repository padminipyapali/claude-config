# POST-MORTEM: plush-press PR #374 — Scene editor PR 1: compact backdrop dropdown + cast chips with character popover

Branch: `feat/live-spread-pr1-compact-pickers` → `main` | Author: padminipyapali | GitHub-time 0.063 h (~3.8 min; real work was pre-push on a worktree)
Size: +1203 −238 across 14 files, 6 commits | Merged 2026-07-22T04:20:12Z (self-merged after local review + operator sign-off)

## Context

First PR of the Live Spread scene-editor redesign (spec: `docs/LIVE_SPREAD_SPEC.md`). Built via the orchestrator team pattern: adversarial plan review (4 blockers folded into spec) → implementer → fresh-context critic → operator preview-server feedback loop → CodeRabbit CLI. No GitHub reviews/comments (all review was local); merged on the four green local gates (test 2,892 passed, lint, typecheck, build).

## Local Review (pre-push)
- CodeRabbit CLI: 1 finding (mockup README doc staleness), fixed (commit 6). 1 iteration.
- Fresh-context critic: APPROVE; 1 real nit — missing sibling test assertion (scene-pick path clearing free-scene), fixed (commit 2).
- Adversarial *plan* review: 4 blockers folded into the spec before implementation.
- Operator preview: cast rail reworked from whole-book-cast chips to placed-only chips + popover (commits 3 & 4).
- Shift-left: 100% of issues caught locally; nothing escaped to GitHub or post-merge.

## Step Compliance
Not emitted in the standard `Steps skipped:` format (body used a hand-written `## Review` section), so recorded as `null`. From context, the following ran: 1 + 1c (plan + adversarial plan review), 2, 3 (all four gates), 4b/4c (CodeRabbit), 4c/4d (fresh-context critic), 5 (push + PR). Simplify (4a) not mentioned.

## Step Timing
Not tracked (`null`) — no `## Step Timing` section.

## CI
`studio` check = FAILURE, but the job completed in **2 seconds with zero steps executed** (empty `steps` array, "log not found"). This is an infrastructure/runner-level failure, not a test/quality escape — consistent with the known private-repo free-plan CI flakiness. The four local gates were green; merge was correct.

## Review Friction (post-push)
- Review rounds: 1 (no GitHub CHANGES_REQUESTED — all friction was local/pre-push).
- Comments: 0 inline, 0 general.
- Timeline: created → merged ~3.8 min on GitHub; the consequential review loop happened pre-push on the operator's worktree preview server.

## Fix-up Metrics
- Post-merge fix rate: **0.0** (no follow-up fix PRs; #374 is the newest, #371–373 are unrelated wizard/style work).
- Pre-merge catch by step: 4c (CodeRabbit) 1 · 4d (critic/adversarial) 1 · **operator preview 2** (the cast-rail rework + the doubled-label dedup) — the operator-preview catches have **no bucket** in the fixup step-taxonomy, so `postPush`=0 understates them.
- Pre-merge iteration count: 3 (critic, CodeRabbit, operator preview) — normal for a 1,441-LOC UI PR, but 1 of the 3 was a design-intent rework better spec constraints would have prevented.
- Fix-up taxonomy: correctness 1 (rail rework), test-quality 1, style 1 (label dedup), documentation 1.
- Legacy fixup ratio: 0.667 (4 fix / 6 total commits).

## Planning Quality
Structurally complete: Summary, Designs (mockup + screenshots), Review, Testing sections; backing spec + adversarial plan review. **Content gap (the key finding):** the mockup's load-bearing invariant — "cast rail = characters placed on THIS page only" — was never transcribed into the spec as an explicit constraint. Scope clean otherwise (single-concern first PR of a staged redesign).

## The interesting process lesson (mockup intent ≠ stated constraint)
The mockup rendered a per-page cast rail, but the spec stated no scoping invariant. The implementer reasonably optimized for a different concern — a multi-page placement workflow — and rendered the whole book cast (one chip per character×look, stacked), recreating the exact tall wall the redesign existed to remove. Every diff-scoped gate passed it (plan review, fresh-context critic, CodeRabbit) because none had a stated invariant to check the diff against. It surfaced only on operator eyeballs on the preview server, forcing a whole-component rework mid-PR. A mockup shows a STATE, not the RULE that produced it; the plan must transcribe each surface's load-bearing properties as verifiable invariants, and the operator-preview loop is the backstop for intent/scope regressions no code-review checklist covers.

## Adversarial Review Effectiveness
- In-scope catch rate: 1.0 — the critic caught its one findable nit (test gap, an adversarial-checklist class); CodeRabbit caught the doc staleness.
- The escaped design-intent regression is **out of scope** for any code-review checklist (it is a planning/intent gap, not a correctness/security/style defect), so it was correctly caught earlier in the pipeline by the operator, not by the diff-scoped gates. Nothing escaped to post-merge.

## Knowledge Updates
- `process-patterns.md` → Planning Discipline: added the "transcribe a mockup's load-bearing invariants into the spec as explicit named constraints" pattern (the INVARIANT complement to the existing "enumerate every visible surface by name" rule), with the operator-preview-as-backstop corollary and the note that the fixup step-taxonomy lacks an operator-preview bucket. Source-tagged to #374.

## Recommendations (ranked)
1. **Mockup-invariant transcription (highest leverage).** For every mockup-driven UI plan, add an "Invariants" list: each surface's load-bearing properties as verifiable statements ("this list is scoped to the current selection", "one row per X, not X×Y"). Give the critic those lines to check the diff against — that is what would have caught the wall-of-chips regression before the operator did.
2. **Log operator-preview catches as a first-class step.** For hands-on-lane UI PRs the preview loop is the primary intent gate; the metrics framework has no bucket for it, which understates its role. Add an `operatorPreview` bucket to `preMergeCatchRateByStep`.
3. **Stop letting infra-flaky CI show as FAILURE on a merged PR.** The 2-second zero-step `studio` failure is runner infrastructure, not code. Consider a retry-on-infra-failure or a CI upgrade so the signal isn't noise (recurring theme in this repo's metrics).
