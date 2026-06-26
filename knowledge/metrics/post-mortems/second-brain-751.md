# Post-Mortem: second-brain PR #751 — feat(scheduler): classify todos by actionMode + batchKey (analysis only, byte-identical) [PR-A of #749]

**Date:** 2026-06-26
**Branch:** `feat/lean-scheduler-actionmode` → main (squash-merged `4ed3f96`)
**Author / Merged by:** padminipyapali (self-merge, solo dev)
**Time to Merge:** ~0m on GitHub (created 18:09:01, merged 18:09:20 UTC; dev loop ran locally before push)
**Size:** +362 −3 across 8 files, 1 squashed commit

## What Shipped

PR-A of the lean smart-scheduler (#749). Adds two **optional** `TodoAnalysis` fields — `actionMode` (`decision｜errand｜outreach｜admin｜block`) and `batchKey` — tagged by the LLM (`analyzeTodos`, Sonnet) and a deterministic archetype table. **Zero behavioral change:** `buildProposal`/packer/formatter/`placementsToEvents`/commit read nothing; scheduler output byte-identical (verified — zero scheduler references to the new fields; all pre-existing proposal/refine tests pass unchanged).

Files: shared taxonomy (`todo-archetypes.ts`), `TodoAnalysis` + `analyze_todos` tool schema + Sonnet prompt (`response.ts`), main coercion (`response.ts`), refine `coerceAnalysis` (`schedule-todos-refine.ts` — load-bearing), archetype default (`schedule-todos-handler.ts`), plus tests.

## Load-bearing change

The refine `coerceAnalysis` re-validates + re-normalizes `actionMode`/`batchKey` on the persisted-analysis round trip (`Object.fromEntries` → `parseRefinableMetadata` → `coerceAnalysis`) with logic **identical** to the main coercion, so the LLM's grouping survives every refine round instead of being silently erased on first refine. A mandatory round-trip regression test guards it (`actionMode:"errand", batchKey:"baby-kids"` survives verbatim).

## Pipeline

Design workflow → implementer-ready spec (post-pack-collapse mechanic over synthetic-blocks-in-the-packer) → implementer wrote the code → **lightweight orchestrator gate** (fresh-context critic **deliberately waved off by the user**: "keep going... merge PR A", per the standing lightweight-review-for-small-additive-PRs preference). Gate kept: build/lint/test (**2295 passed / 48 skipped**), byte-identity verification (zero scheduler reads), A5/A6 coercion-consistency (main vs. refine logic identical), schema-`required` discipline (new fields not required → old analyses valid), adversarial-review marker.

## Review Friction (post-push)

- Review rounds: 1 (lightweight gate; no GitHub CHANGES_REQUESTED).
- Comments: 0 inline, 0 substantive general (Vercel bot only).
- Reviews: none. Self-merge.
- CI: Vercel SUCCESS; server suite green.

## adversarialCatchRate — Evidence

**`unmeasured` (null).** No separate fresh-context critic ran — **deliberately skipped per explicit user direction**; PR-A used a lightweight orchestrator gate, NOT a critic. The gate surfaced no must-fix findings (code matched the design-workflow spec). #751 is the latest merged PR with **0 post-merge escapes**. caught/(caught+escaped) = 0/(0+0) = undefined → recorded as `unmeasured`, NOT fabricated to 1.0. Note attached: lightweight gate, not a fresh-context critic.

## Fix-up Metrics

- Post-merge fix rate: **0.0** (0 follow-up fix PRs; nothing merged after #751 touches the area).
- Pre-merge catch rate by step: all zeros (single squashed commit, no fix commits). Review value front-loaded into the design workflow + the gate's structural checks (byte-identity, coercion symmetry, schema discipline) — not captured by per-commit fix attribution.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all zeros (no fix commits).
- Legacy fix-up ratio: 0.0 (0 fix / 1 commit).

## Planning Quality

- Description: **complete** — What / Changes / Validation / Reviewed sections; enumerates the byte-identity claim and the round-trip contract; the multi-PR scope (PR-B/C deferred) is explicit.
- Scope: **clean** — 365 LOC, single focused additive commit, branch lifetime minutes.
- Redesign indicators: none.

## Code Quality Signals

- Recurring issues: none.
- New unrecorded pattern: **ship the persistence/round-trip contract FIRST as a byte-identical no-op PR with a mandatory round-trip regression test, before any consumer exists** — captured to `process-patterns.md` (Multi-PR Feature Coordination).

## Process Efficiency

- Automation opportunities: the A5/A6 coercion-symmetry check (main vs. refine coercer identical) is currently a manual gate step; a structural test asserting both coercers produce identical output for the same input set would automate it permanently.
- Iteration: efficient (1 round, 0 escapes).
- CI: all passed.

## Knowledge Updates

- `~/.claude/knowledge/process-patterns.md` (Multi-PR Feature Coordination): added the "contract-first, byte-identical no-op PR with a round-trip regression test" bullet (Source: second-brain #751).

## Recommendations

1. Carry the coercion-symmetry invariant into PR-B/C; extend the round-trip test to new grouping values rather than trusting symmetry by inspection.
2. Keep emitting the lightweight-gate structural evidence (byte-identity, coercion-consistency, schema-`required`) — for a no-op contract PR these are the real review record, not a fix-commit count.
3. For deliberately-skipped-critic lightweight PRs, record `unmeasured`, not a fabricated 1.0.
