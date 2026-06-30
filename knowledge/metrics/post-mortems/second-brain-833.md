# POST-MORTEM: second-brain PR #833

**Title:** fix(calendar): cap calendar-query replies to Telegram's 4096-char limit (weekly agenda crash).
**Branch:** fix/weekly-agenda-crash → main | **Author:** padminipyapali (self-merged, local-review-gate model)
**Merged:** 2026-06-30T19:38:45Z (squash `136581c`, sole commit `0bc42425`) | **Closes:** #832
**Size:** +295 / −1 across 4 files (~110 prod LOC + 6 tests), 1 commit
**Open→merge wall-clock:** ~61 seconds (0.0169h) — the full dev loop ran PRE-PUSH; the GitHub window only reflects push+merge.

## The bug (#832)
"what do I have going on this week" → "Sorry, something went wrong. Please try again." The multi-day agenda
answer rendered **4532 chars**, over Telegram's 4096-char `ctx.reply` limit → Telegram 400 "message too long"
→ the channel's top-level catch → generic error. The agenda was broken for any weekly/multi-day calendar query.

**Root cause — a LATENT missing-length-guard, not a logic bug in the recent #830/#831.** `formatAgendaAnswer`
(the CALENDAR_QUERY agenda path, since #737) never had the 4096-char guard the weekly-VIEW renderer
`formatCalendarWeek` has carried since #737. #831 ("honor requested time range"), **merged by a different
session**, widened "this week" to a real 7-day range, pushing the agenda output from ~960 chars (always under
the cap) to 4532 — **exposing** the dormant gap. Single-day "tomorrow" (960 chars) stayed short, so it worked.

## The fix (two layers, defense-in-depth)
1. **Per-day clamp** — `formatAgendaAnswer` clamps its body to ≤4096, dropping whole trailing day blocks
   (never cutting a day mid-line) with a "(…more days…)" continuation note, reserving headroom for the
   out-of-range append. Mirrors `formatCalendarWeek`'s existing guard.
2. **Final BACKSTOP (the durable layer)** — `generateCalendarQueryResponse` routes EVERY answer (agenda,
   availability, the out-of-range append, the catch fallback) through ONE `capTelegramText()` chokepoint at
   its single return site (`response.ts:2607`; helper at `response.ts:443`). Guarantees ≤4096 regardless of
   append size or availability length, and covers producers added later. This also closed a **latent overflow
   on the sibling availability path** (`answerAvailability`) that had no guard at all.

**Validate-first probe (real calendar):** "this week" 4532 → **3827 chars** (≤4096, ends cleanly);
"tomorrow" 960, unchanged.

**Tests (6):** per-day clamp (3: over-4096 → clamped + "more days" note with early days kept; short body
untouched; single oversized day hard-truncated) + backstop (2: a 7-day agenda + 50-date out-of-range append
forces the backstop and asserts the truncated note; a long availability answer stays ≤4096) — all assert real
≤4096 length. Full server suite **2791 passed / 0 failures**.

## LOCAL REVIEW (pre-push)
- **CodeRabbit (4b):** not run (~110 prod LOC bug fix, lightweight-review lane) → not tracked (null).
- **Adversarial (4c):** 1 finding, 1 fixed — a **two-round** review. **This is a MEASURED found-and-fixed
  catch, not a fabricated 1.0 and not a critic-ran-clean null.**
  - **Round 1:** the implementer's first fix added the per-day clamp to `formatAgendaAnswer` ONLY. The
    fresh-context critic proved with **character-budget math** that two paths could STILL exceed 4096 and
    re-crash: (a) the out-of-range append concatenated AFTER the clamped body (`clamp(body)+append` blows the
    cap the body alone respected — the clamp budgeted the wrong quantity), and (b) the sibling availability
    path had no guard at all. Verdict: **FIX-THEN-SHIP, marker WITHHELD.**
  - **Round 2:** added the single output-chokepoint backstop. Re-review proved `capTelegramText`'s ceiling is
    EXACTLY 4096 on pathological inputs (no linebreak, break-at-index-0), the chokepoint covers every exit,
    clarify passes through, back-compat byte-identical for under-cap answers → **SHIP, marker granted.**
  - Shipping the round-1 fix would have left #832's exact crash reachable via the append and availability
    paths — a **recurring production crash** the gate prevented from re-shipping.

## METRICS
- **adversarialCatchRate = 1.0** (MEASURED found-and-fixed: caught 1, escaped 0 → 1/(1+0)). Same shade as
  #828 (1/1) and #831 (4/4); distinct from #830's critic-ran-clean (0/0 → null).
- **postMergeFixRate = 0.0** — no follow-up fix to this feature area (#833 is the latest merged PR; nothing
  after it touches `calendar-agenda.ts` / the `capTelegramText` chokepoint).
- **preMergeIterationCount = 2** (two adversarial rounds — round-1 withhold + round-2 ship).
- **preMergeCatchRateByStep:** 4c = 1; all others 0.
- **fixupTaxonomy:** defensive-coding = 1 (the length-guard backstop).
- **stepCompliance:** ran 1, 2, 3, 4c, 4d, 5; skipped 4a (folded into single-pass implement) and 4b
  (CodeRabbit, lightweight-review lane). complianceRate 0.667. **skipAssessment good** — 0 post-merge escapes
  and the one in-scope blocker was caught by the step that ran (4c).
- **CI:** Vercel preview SUCCESS. NOTE: actual deployment is **Railway, not Vercel** — the Vercel check is
  preview-only, not the deploy target.
- **planningQuality:** complete (clear bug/root-cause/fix/validate/tests/review sections).

## KNOWLEDGE UPDATES (`~/.claude/knowledge/process-patterns.md`)
1. **Planning Discipline — new bullet:** a hard limit/guard added to ONE producer must be swept across ALL
   sibling producers feeding the same boundary; the durable form is a SINGLE backstop at the shared OUTPUT
   chokepoint (per-producer-GUARD axis of the #737/#808/#830 sibling-sweep family).
2. **Planning Discipline — new bullet:** cross-session latent exposure — when another session/PR WIDENS an
   input domain (date range, list size, page count, output length), it can EXPOSE a latent downstream
   size/length/bounds assumption; the widening session owns the downstream audit. (#831 widened the window →
   exposed #833's latent gap.)
3. **Review Completeness — new bullet:** a first crash-fix that addresses the reported path but not its
   siblings is a still-crashing fix; the two-round adversarial gate run with character/resource-budget MATH
   (not "looks fine") is what caught the escape. Concrete evidence the gate works.

## RECOMMENDATIONS
1. **Promote the output-chokepoint pattern to a Tier-0 grep check:** any `ctx.reply(` / response send on a
   user-facing path should flow through a single cap helper; flag new direct sends that bypass `capTelegramText`.
2. **Domain-widening audit as a planning-checklist item:** when a PR enlarges a query window / fetch limit /
   batch / max-tokens, the plan's "Performance & Cost Impact" section should explicitly list downstream
   size/length assumptions re-verified at the new maximum.
3. **In-artifact step tracking still absent:** no `## Local Review` / `Steps skipped:` / `## Step Timing`
   sections in the PR body (recurring across #821/#825/#828/#830/#831/#833) — compliance/timing keep being
   reconstructed from evidence. A PR-body template stub would let these be recorded rather than inferred.
