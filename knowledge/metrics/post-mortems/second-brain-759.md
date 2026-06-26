# Post-Mortem: PR #759 — feat(scheduler): refine-aware batch skip ("skip #N" on a run removes its members)

**Date:** 2026-06-26
**PR:** [#759](https://github.com/padminipyapali/second-brain/pull/759) — PR-D (the final slice) of the lean smart-scheduler ([#749](https://github.com/padminipyapali/second-brain/issues/749))
**Branch:** `feat/lean-scheduler-refine-batch` → main (squash-merged as `c1ea068`)
**Time to Merge:** ~18s on GitHub (created 22:03:26, merged 22:03:44 UTC) — the dev loop ran locally before push
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +366 −11 across 3 files, 1 squashed commit

## 1. What Shipped

The final slice of the lean scheduler. PR-C collapsed errand/admin runs into a batched block with a **synthetic id (`batch:…`) occupying one proposal number**; until now, **"skip #N" on a batched run was a silent no-op** (the synthetic id matched no real todo). PR-D makes refine **remove** work on a batch.

Mechanic — all in `schedule-todos-refine.ts`:
- **`numbersToIds` (the remove resolver) expands a batch number → all its `memberTodoIds`**; an individual number still resolves to its single `todoId`. The synthetic `batch:` id is never added to the remove set.
- **`parseRefinableMetadata` now preserves `memberTodoIds`** on each `numberMap` entry (validated as a non-empty array of non-empty strings; malformed entries dropped). It previously rebuilt `{number, todoId}` only and silently dropped the member ids PR-C had persisted.
- **`setDuration` / `addDependency` on a batch number are documented intentional no-ops** — a synthetic batch id isn't in the analysis Map, and a run can't take a per-todo duration/dependency edit. No crash; other edits in the same reply still apply.

PR-C's packing/collapse/event logic is untouched. The change is **refine-internal: it changes which todos are in the proposal; events are only created on confirm** — no external side effects in this PR.

## 2. The Process Story — Risk-Graduated Review (the closing bookend)

This PR is the **counterpart** to PR-C's escalation. PR-C (#758) **re-instated the full fresh-context critic** because it crossed into the irreversible-side-effect path (calendar-event creation + commit). PR-D **steps back down to the lightweight orchestrator gate** because it is purely refine-internal:

- It only changes **which todos are in the in-flight proposal**; it creates **no events** (events are created later, only on confirm).
- It is **additive/internal** — it makes a previously silent no-op do the right thing, and the new behavior is bounded by the already-persisted `memberTodoIds`.

This is the risk-graduated rule applied correctly in both directions: the lightweight waiver is by **blast radius**, not LOC. The discriminator — *"does this PR create/mutate external side effects (calendar events, emails, irreversible writes)?"* — answers **no** here, so the full critic was not required.

**The lightweight gate that ran:** `npm run build`, `npm run lint`, `npm test` (**2359 passed, 48 skipped**) all green; the adversarial-review marker for HEAD; and a focused diff verification of the two load-bearing changes — the **remove-expansion** (batch number → all `memberTodoIds`) and the **`memberTodoIds` preservation/validation** in `parseRefinableMetadata`.

## 3. Metrics

| Metric | Value |
|--------|-------|
| **Additions** | 366 lines |
| **Deletions** | 11 lines |
| **PR size (add+del)** | 377 lines |
| **Files changed** | 3 |
| **Commits** | 1 (squashed feature commit) |
| **PR open to merge** | ~18s (local dev loop ran before push) |
| **Review rounds** | 1 (lightweight orchestrator gate; no GitHub review rounds) |
| **GitHub review comments** | 0 substantive (only Vercel bot) |
| **CI** | Vercel SUCCESS; server **2359 passed / 48 skipped** |
| **adversarialCatchRate** | **unmeasured** (see §5) |
| **Post-merge fix rate** | 0.0 (no follow-up fix touches `schedule-todos-refine.ts`; #760 is a tags PR) |

## 4. Pipeline (how it was built)

1. **Implementer-ready spec** drove the change: the remove-resolver expansion, the `memberTodoIds` preserve+validate, and the documented setDuration/addDependency no-ops were specified before coding — and the seam (member ids persisted on `numberMap`) was deliberately laid down by PR-C precisely so PR-D could expand a batch id → its members.
2. **Implementer wrote the code** directly from the spec.
3. **Lightweight orchestrator gate (no separate fresh-context critic)** — build/lint/test (2359 passed) + adversarial marker + a focused diff verification of remove-expansion and member-id preservation. `/simplify` (4a), CodeRabbit CLI (4b), and the fresh-context critic (4c) were skipped per the lightweight-review preference for additive/internal PRs.

## 5. adversarialCatchRate — Evidence

**Value: `unmeasured` (null)** — recorded honestly; NOT fabricated and NOT 0.

- **No separate fresh-context critic ran** (lightweight gate). This is the **critic-skipped shade** of `unmeasured` — there is **no critic signal at all** for this PR (distinct from PR-C, where the critic ran fully and found the design clean).
- The lightweight gate did its job: build/lint/test green (2359 passed), adversarial marker present, diff verified.
- caught / (caught + escaped) is **undefined** because no critic was run to produce a numerator → recorded as **`unmeasured`** per the metric-integrity rule.
- **0 post-merge escapes:** no follow-up fix PR touches `schedule-todos-refine.ts`; the next merged PR (#760) is unrelated (tags UI cleanup).

Per the two-shades distinction captured for #758: this is the **lightweight-gate / critic-skipped** `null` (no signal), whereas #758 was the **full-critic-ran-clean** `null` (strong clean signal). Both are honestly `null` to avoid inflating the catch-rate trend; the note records which.

## 6. What Went Well

- **The seam paid off as designed.** PR-C persisted `memberTodoIds` on `numberMap` *specifically* so PR-D could expand a batch id → its members. The contract was laid down a PR in advance and consumed exactly as planned — a clean multi-PR hand-off.
- **The round-trip is tested, not assumed.** The test pins the full loop: propose batched → "skip #1" → **all N members removed** → renumber → confirm creates events **without** them. Plus: individual "skip #N" unchanged; mixed batch+individual removal; `setDuration`/`addDependency` on a batch = no-op (other edits still apply); `parseRefinableMetadata` preserves/validates `memberTodoIds` (malformed dropped).
- **The no-op edits are documented intentional, not accidental.** `setDuration`/`addDependency` on a batch number don't crash and don't silently corrupt — they are explicit no-ops, and other edits in the same reply still apply.
- **Risk-graduation held in both directions** — PR-C escalated to a full critic for the event-creating slice; PR-D correctly stepped back to the lightweight gate for the refine-internal slice. Symmetric application of the same rule.
- **0 post-merge escapes**, completing the feature.

## 7. Process / Quality Signals

- **adversarialCatchRate is `unmeasured`, not a number** — no critic ran (critic-skipped shade); `caught/(caught+escaped)` has no numerator and must not be hardcoded.
- **Single squashed commit, no fix commits** → `fixupCommitRatio` = 0.0 and the per-step catch table is all zeros. Review value was front-loaded into the spec and the focused diff verification, which the per-commit fix-attribution model doesn't capture; recorded narratively.
- **Step compliance 6/9** (skipped 4a/4b/4c). Skip assessment: **good** — no post-merge issues, and the PR is in the additive/internal risk class for which the lightweight gate is the project convention.

## 8. Feature Complete — The Lean Smart-Scheduler

PR-D **completes** the lean smart-scheduler. The four sequenced PRs all merged:

| PR | Slice | Review gate |
|----|-------|-------------|
| **PR-A #751** | classify todos by `actionMode` + `batchKey` (analysis-only, byte-identical) | lightweight |
| **PR-B #752** | exclude decisions from the schedule + Decisions section | lightweight |
| **PR-C #758** | batch errands + admin into single calendar events (commit + event creation) | **full critic** |
| **PR-D #759** | refine-aware batch skip ("skip #N" removes a run's members) | lightweight |

**Validated payoff: 51 → 29 calendar items (−43%) on real data.** Each slice was standalone and shippable; review was graduated by each slice's blast radius.

## 9. Learnings — Status

**Net-new (captured this post-mortem):**

- **Risk-graduation is symmetric: step the gate back down once the irreversible-side-effect slice is behind you.** Added to `~/.claude/knowledge/process-patterns.md` (Review Efficiency). PR-C escalated to a full critic because it created calendar events; PR-D, which only changes *which todos are in an in-flight proposal* (events created later, only on confirm), correctly returned to the lightweight gate. The discriminator is the same in both directions — *does this PR create/mutate external side effects?* — so a multi-PR sequence should escalate **and de-escalate** by blast radius, not ratchet "once strict, always strict."

**Already captured — NOT duplicated:**

- **`unmeasured` has two distinguishable shades** — captured from #758; this PR is a clean instance of the **critic-skipped** shade (no signal), recorded with the note.
- **Lightweight review for sub-threshold additive/internal PRs** — project convention + `MEMORY.md`.
- **Multi-PR feature coordination (contract-first A, consumers B/C/D; seam laid down a PR in advance)** — in `process-patterns.md` from #751/#752/#758; PR-D is the consumer of PR-C's `memberTodoIds` seam.
- **Convention #3 (walk full access chains)** — `parseRefinableMetadata` validating `memberTodoIds` as a non-empty array of non-empty strings (malformed dropped) is an application, already a universal manual convention.

## 10. Recommendations

1. **Adopt symmetric risk-graduation as the standard for multi-PR sequences** — name the escalation slice (irreversible side effects) AND allow the de-escalation back to the lightweight gate for the internal slices that follow. A/B (lightweight) → C (full critic) → D (lightweight) is the model to reuse.
2. **Continue recording the critic-skipped case as `unmeasured` with the no-signal note** — do not let "0 post-merge escapes" tempt a fabricated catch rate; the honest `null` + shade note is correct.
3. **Feature is complete; no further scheduler refine work is queued.** The one gap PR-C introduced (refine on a batched run) is now closed.
