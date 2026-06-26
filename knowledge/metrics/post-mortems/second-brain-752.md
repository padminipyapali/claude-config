# Post-Mortem: second-brain PR #752 — feat(scheduler): exclude decision-mode todos from the calendar + Decisions section [PR-B of #749]

**Date:** 2026-06-26
**Branch:** `feat/lean-scheduler-decisions` → main (squash-merged `da6e729`)
**Author / Merged by:** padminipyapali (self-merge, solo dev)
**Time to Merge:** ~0m on GitHub (created 18:17:27, merged 18:17:46 UTC; dev loop ran locally before push)
**Size:** +292 −7 across 4 files (2 source, 2 test), 1 squashed commit

## What Shipped

PR-B of the lean smart-scheduler (#749) — the **first behavioral use** of PR-A's `actionMode`. Todos tagged `actionMode === "decision"` are partitioned OUT before packing in `buildProposal`: no `SchedulableTodo`, no `Placement`, no event, no `numberMap` entry. They render only in a new un-numbered **"Decisions / to mull"** section in `formatProposal`. Removes ~7 mis-scheduled decisions ("Can I swing a NYC trip?", "decide baluster material", "What are sanctions?") from the user's real list.

Files: `schedule-todos-proposal.ts` (partition + dangling-dep filter), `todo-scheduling.ts` (`DecisionItem` type, `ProposalInput.decisions`, formatter section), plus their tests. `packTodos`/`placementsToEvents`/commit/events untouched. All-`block` path byte-identical to pre-PR-B.

## Load-bearing change

The **dangling-dependency filter**: each surviving (non-decision) todo's `dependsOn` is `.filter((d) => !decisionIds.has(d))`. Without it, a non-decision that `dependsOn` a now-excluded decision would carry a phantom blocker — the packer sees a dependency that never gets placed and strands the dependent as unplaced. A dedicated test asserts the dependent still packs (at the unfloored start). This is the generalizable pattern captured this cycle: drop nodes from a dependency graph → scrub references to the dropped nodes from survivors.

## Pipeline

Lean-scheduler design workflow → implementer-ready spec → implementer wrote the code → **lightweight orchestrator gate** (fresh-context critic **deliberately skipped** per the standing lightweight-review-for-small-additive-PRs preference + the active velocity push "let's get these merged"). Gate kept and verified: build/lint/test (**2321 passed / 48 skipped**), the dangling-dep filter (dependent of an excluded decision still packs), stable numbering (decisions occupy no number), decisions never reaching events/`numberMap`, all-`block` byte-identity, adversarial-review marker.

**Scope note:** PR-C (errand/admin batching + event creation, **touches the commit path**) is being **paused for a real fresh-context critic** — the lightweight waiver is scoped to small additive/well-tested A/B PRs, not commit-path/event-creation changes.

## Review Friction (post-push)

- Review rounds: 1 (lightweight gate; no GitHub CHANGES_REQUESTED).
- Comments: 0 inline, 0 substantive general (Vercel bot only).
- Reviews: none. Self-merge.
- CI: Vercel SUCCESS; server suite green (2321 passed).

## adversarialCatchRate — Evidence

**`unmeasured` (null).** No separate fresh-context critic ran — **deliberately skipped** per the lightweight-gate convention and the velocity push; PR-B used a lightweight orchestrator gate, NOT a critic. The gate surfaced no must-fix findings (code matched the spec; dangling-dep filter, stable numbering, and events/`numberMap` exclusion all verified present). #752 is the latest merged PR with **0 post-merge escapes**. caught/(caught+escaped) = 0/(0+0) = undefined → recorded as `unmeasured`, NOT fabricated to 1.0. Note attached: lightweight gate, not a fresh-context critic.

## Fix-up Metrics

- Post-merge fix rate: **0.0** (#752 is the latest merged PR; nothing merged after touches the area).
- Pre-merge catch rate by step: all zeros (single squashed commit, no fix commits). Review value front-loaded into the implementer-ready spec + the gate's four structural checks (dangling-dep, stable numbering, events/numberMap exclusion, byte-identity) — not captured by per-commit fix attribution.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all zeros (no fix commits).
- Legacy fix-up ratio: 0.0 (0 fix / 1 commit).

## Planning Quality

- Description: **complete** — What / Changes / Validation / Reviewed sections; enumerates the dangling-dep filter, stable numbering, byte-identity claim, and the multi-PR scope (part of #749, PR-B; PR-C deferred).
- Scope: **clean** — 299 LOC, single focused behavioral commit, branch lifetime minutes.
- Redesign indicators: none.

## Code Quality Signals

- Recurring issues: none.
- New unrecorded pattern: **drop nodes from a dependency graph before processing → scrub references to the dropped nodes from the survivors, or they inherit phantom blockers** — captured to `typescript-patterns.md` (Data Modeling).

## Process Efficiency

- Automation opportunities: the "decision never reaches events/`numberMap`" and "all-block byte-identity" gate checks are now codified as tests in the PR — they no longer require a manual gate step on future scheduler PRs. The dangling-dep cross-edge case is also a standing regression test.
- Iteration: efficient (1 round, 0 escapes).
- CI: all passed.

## Knowledge Updates

- `~/.claude/knowledge/typescript-patterns.md` (Data Modeling): added the "scrub references to dropped nodes from survivors / phantom-blocker" bullet (Source: second-brain #752).

## Recommendations

1. Do NOT extend the lightweight-gate waiver to PR-C — it touches the commit path and creates events; run the fresh-context critic (already the plan).
2. Carry the dangling-dependency check into PR-C's batching: re-verify no survivor inherits a reference to a node merged/dropped during batching, and numbering stays stable across the new grouping.
3. For deliberately-skipped-critic lightweight PRs, record `unmeasured`, not a fabricated 1.0.
</content>
