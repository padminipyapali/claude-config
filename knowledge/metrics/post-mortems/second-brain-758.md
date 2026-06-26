POST-MORTEM: second-brain PR #758 — feat(scheduler): collapse errand/admin runs into one batched calendar event [PR-C of #749]
Branch: feat/lean-scheduler-batching → main (squash-merged 727cffb) | Author: padminipyapali | ~4.8m PR-open-to-merge (local dev loop ran before push)
Size: +973 -14 across 6 files, 1 commit (~337 LOC production + tests)

LOCAL REVIEW (pre-push)
  CodeRabbit: not tracked (4b skipped per lightweight-review preference)
  Adversarial / fresh-context critic: RAN FULLY — 0 blockers, 0 SHOULD-FIX, 2 cosmetic NITs (0 actionable findings)
  Shift-left: review value front-loaded into implementer-ready spec + critic's 4 structural verifications

STEP COMPLIANCE
  Steps run: 1, 2a, 2b, 3, 4c-critic, 4d, 5 (7/9)
  Steps skipped: 4a (/simplify), 4b (CodeRabbit CLI) — reason: lightweight-review preference
  RE-INSTATED: 4c fresh-context critic — because PR-C creates calendar events + touches the commit path (graduated OUT of the A/B lightweight gate)
  Compliance rate: 77.8%
  Skip assessment: good (no post-merge issues; the critic that matters for this risk class WAS run)

STEP TIMING
  not tracked (no per-step timing table in PR body)

REVIEW FRICTION (post-push)
  Review rounds: 1 (fresh-context critic + orchestrator gate; no GitHub CHANGES_REQUESTED)
  Comments: 0 inline, 0 general substantive (only Vercel bot)
  Categories: all 0
  Timeline: created 21:32:46Z → merged 21:37:32Z (~4.8m on GitHub; dev loop local)

ADVERSARIAL REVIEW EFFECTIVENESS
  Pre-push catch potential: the critic verified the 4 user-impacting invariants —
    (1) no overflow/double-booking (firstFit fits within one free interval → non-contiguous reclaim falls back to individuals, never spans a gap)
    (2) member-id survival through persist → parseStoredEvents → commit (memberTodoIds validated string[])
    (3) exactly one createEvent per run (count == runs, not members)
    (4) byte-identical no-op path (zero-errand/admin reconstructs pre-PR-C output)
  Covered but missed: none (0 actionable findings; 0 post-merge escapes)
  Not covered (new categories): none

FIX-UP METRICS
  Post-merge fix rate: 0.0 (#758 is the latest merged PR; PR-D not yet merged; no follow-up fix touches the area)
  Pre-merge catch rate by step: 4a 0 | 4b 0 | 4c 0 | 4d 0 | post-push 0 (single squashed commit, no fix commits)
  Pre-merge iteration count: 1 (healthy)
  Fix-up taxonomy: all 0
  Legacy fix-up ratio: 0.0 (0 fix / 1 total commits)

PLANNING QUALITY
  Description: complete (What / Mechanic / One-event-per-batch / Validation / Known follow-up sections; Closes #749)
  Scope: clean (single concern: post-pack batch collapse; packTodos untouched; ~337 LOC production)
  Branch lifetime: short (local dev loop; ~4.8m PR-open-to-merge)
  Planning checklist: entry points covered (singleton vs ≥2, same-day vs cross-day, errand vs admin, fits vs falls-back, zero-errand/admin byte-identical); known PR-D deferral explicitly enumerated

CODE QUALITY SIGNALS
  Recurring issues: none
  New unrecorded patterns: risk-graduated review gate (escalate the irreversible-side-effect slice to a full critic, pre-committed in the prior PR's post-mortem); two shades of `unmeasured` (critic-ran-clean vs critic-skipped)

PROCESS EFFICIENCY
  Automation opportunities: none beyond existing gates
  Iteration: efficient (1 round, 0 fix commits)
  CI status: Vercel SUCCESS; server 2352 passed / 48 skipped

adversarialCatchRate DECISION
  unmeasured (null). The fresh-context critic RAN FULLY (PR-C graduated to a real critic because it creates calendar events + touches the commit path) and found 0 actionable findings (0 blockers / 0 SHOULD-FIX / 2 NITs). caught/(caught+escaped) = 0/(0+0) = undefined → recorded as unmeasured per the metric-integrity rule, NOT fabricated to 1.0. 0 post-merge escapes. Distinguished from PR-A/B's unmeasured (no critic ran at all) by an explicit note: here the critic ran and the design was genuinely clean (strong negative-finding signal).

KNOWLEDGE UPDATES
  ~/.claude/knowledge/process-patterns.md (Review Efficiency) — risk-graduated review gate, pre-committed escalation; two shades of `unmeasured`.

RECOMMENDATIONS
  1. Build PR-D next (refine-aware batch skip) — "skip #N" on a batched run is a silent no-op today; member ids already persisted on numberMap so PR-D can expand batch id → members.
  2. Keep risk-graduation explicit in future multi-PR sequences — name the irreversible-side-effect slice in the plan + prior post-mortem (as A/B→C did here) and route it to a full critic regardless of LOC.
  3. Continue recording the critic-ran-clean case as `unmeasured` + strong-signal note; never fabricate a 1.0.
