# Post-Mortem: second-brain PR #818 — route refinements sent as a new message; detect priority/ordering language

**Date:** 2026-06-27
**PR:** [#818](https://github.com/padminipyapali/second-brain/pull/818) — Closes [#816](https://github.com/padminipyapali/second-brain/issues/816). Deferred follow-up [#817](https://github.com/padminipyapali/second-brain/issues/817) (first-class prioritize/reorder edit) stays OPEN.
**Branch:** `fix/schedule-todos-refine-routing` → main (squash-merged as `a6796ef`)
**Time to Merge:** ~60s on GitHub (created 2026-06-27T22:12:59Z, merged 22:13:59Z). The full dev loop ran locally before push; the window is wall-clock until merge, not active GitHub review.
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +303 −11 across 5 files, 1 commit (~150 production LOC; ~172 of the additions are tests)

## 1. What Shipped

A two-part fix for the bug where, after a "schedule my todos" (SCHEDULE_TODOS) proposal, a refinement typed as a **new message** (e.g. "Mira packing list is highest priority, schedule it first") was SAVED as a new todo instead of refining the pending proposal.

Three compounding causes were traced; two were fixed here, the third descoped (see §2):

1. **Routing (fixed).** The refine path only fired on a Telegram **reply-to**. `message-processor.ts` now also routes a refinement-looking **standalone** message to the refine interpreter when a recent (≤ 45 min) UNCONFIRMED SCHEDULE_TODOS proposal is pending. A new `tryNoReplyScheduleRefine` helper looks up the most-recent `SCHEDULE_TODOS_PENDING`, applies a UTC-epoch recency TTL (`SCHEDULE_REFINE_NO_REPLY_TTL_MS = 45 min`), skips already-committed proposals BEFORE the LLM call (`metadata.confirmedAt`), and calls `runRefine`. The interpreter is the authority (per #761): a genuine non-refinement returns null and **falls through to normal classification + save** — the message is never dropped. A DB-lookup failure or interpreter exception also returns null → normal save (no throw, no swallow). The reply-to path is unchanged.
2. **Detection (fixed).** `looksLikeRefinement` (in `schedule-todos-refine.ts`) now recognizes priority/ordering cues via a new `\b`-bounded `PRIORITY_ORDER_RE` (priority/prioritize/first/last/before/after/order/rank/earliest/latest/sooner/soonest). `\b` boundaries keep "order" from firing inside "border"/"recorder"; no ReDoS. The reported message matched NONE of the prior cues (no `#N`, no bare number, no duration, "scheduled" ≠ `\bschedule\b`), which is why it fell through to classification.
3. **Explicit prioritize/reorder edit (DEFERRED to #817).** See §2 — descoped after a real-model probe.

Supporting change: `entry.ts` `findMostRecentBotResponse` now returns `createdAt` on the `BotResponse` record so the caller can apply the recency TTL (a reply-to is already scoped to one message, so it carries no TTL).

## 2. Development Loop

Pipeline: explore (read-only Explore agent traced the 3 compounding causes) → **validate-first real-model probe BEFORE coding** → implement (same implementer context as the #806/#808/#812/#814 cluster) → INDEPENDENT fresh-context critic → SHIP → adversarial gate PASS.

**The probe was a scoping instrument, not just a verification gate.** Run BEFORE the implementer wrote code, fed the user's exact message, it established two things:

- **It descoped cause #3.** The interpreter already encodes "put X first" as task-**dependency** edits, so a planned first-class `prioritize`/reorder edit (~200 LOC) was largely REDUNDANT for the core fix. The build was descoped to routing + detection only.
- **It re-justified a narrower follow-up.** The same probe caught the model's NON-DETERMINISM: `isRefinement=true` fires reliably for the verbose/typo phrasing, but the "X first" dependency edits fire only ~**50%** of the time. That unreliability — not an "it's missing" premise — is the real justification for #817 (a first-class, *reliable* prioritize edit), filed as a tracked follow-up rather than built here.

**Gates:** lint clean, server tsc clean, full server suite (2699) green (+10 new tests). Vercel Preview CI SUCCESS. CodeRabbit (4b) NOT run (~150 production LOC — lightweight-review lane). No GitHub reviews / inline comments (solo workflow; all review pre-push).

**Tests (10):** routing — pending + priority → refine; interpreter-rejects → save; non-refinement → no lookup/save; stale / committed / no-pending → no route; reply-to unaffected — plus the priority-cue detector cases (including the `\b` negatives "border"/"recorder").

## 3. Adversarial / Critic Effectiveness — adversarialCatchRate = unmeasured (critic-ran-clean shade)

A fresh-context critic RAN against the diff and returned **SHIP with 0 blockers / 0 actionable findings**. It verified:

- **No silent-drop path** — every null/error branch in `tryNoReplyScheduleRefine` falls through to normal classification + save.
- **Unconfirmed filter matches the commit path** — the `metadata.confirmedAt` check aligns with the stamp the commit path writes, so a committed proposal cannot re-trigger.
- **`createdAt` TTL is UTC-epoch correct** — `Date.getTime()` math; `undefined` treated as stale (don't hijack).
- **Detector regex is `\b`-bounded** — no "border"/"recorder" false match, no ReDoS.
- **No classification regression** — the gate only adds a route in front of normal classify; non-refinements are unaffected.

Because `adversarialFindings = 0`, a true catch-rate fraction is undefined (0/0) → recorded as `unmeasured` per the metric-integrity rule. This is the **critic-ran-clean** shade (a strong clean signal), NOT a fabricated 1.0 and NOT the critic-skipped null — the critic DID run. The load-bearing correctness gate for this PR was the validate-first probe (§2), which both descoped redundant work and surfaced the non-determinism behind #817.

Post-merge escapes = **0** — no follow-up PR touches `message-processor.ts` / `schedule-todos-refine.ts` / `entry.ts`; #817 is a NEW deferred feature, not a fix of this PR's code.

## 4. Process Notes & Learnings

- **4th fix in the schedule-todos cluster this session** (#806/#808/#812/#814/#816). The SAME implementer context was reused for BUILDING (no re-exploration tax, inter-fix consistency), but each fix earned an INDEPENDENT fresh-context critic for REVIEWING.
- **PROBE-BEFORE-BUILD descoping** (captured in `~/.claude/knowledge/process-patterns.md`, Scope Decisions): probe the model's CURRENT behavior before building an LLM capability you assume is missing — the model frequently already does it (here via dependency-encoding of ordering), which descopes the build; and if the probe shows it works but UNRELIABLY, that non-determinism is the narrower justification for a deferred reliability upgrade (#817).
- **Interpreter-as-authority routing** (captured in `~/.claude/knowledge/llm-integration.md`, Technique Selection): a cheap keyword gate bounds COST, the LLM interpreter is the real GATE, and every reject/error/stale/null path must FALL THROUGH to normal save — never drop the message. This extends the #761 interpreter-as-authority decision from the reply-to path to the no-reply pending path.
- **Process gap (recurring):** the PR body had no explicit `Steps skipped:` line, so the 4b (CodeRabbit) skip was unrecorded in-artifact — the same gap noted on siblings #814/#813/#808 this session. Recorded here as not-tracked (null) for the CodeRabbit counts, not zero.

## 5. Metrics Summary

| Field | Value |
|-------|-------|
| Review rounds | 1 |
| Total comments (non-bot) | 0 |
| localReview.adversarial | 0 found / 0 fixed |
| localReview.coderabbit | not tracked (4b not run) |
| adversarialCatchRate | unmeasured (critic-ran-clean shade) |
| postMergeFixRate | 0.0 (0 escapes) |
| preMergeIterationCount | 1 |
| Step compliance | 8/9 (89%) — 4b skipped, assessment: good |
| Planning quality | complete |
| PR size | 314 (303 add / 11 del) |
| Time to merge | ~60s wall-clock to merge (loop ran pre-push) |
