# Post-Mortem: PR #739 — fix(calendar): route far-future dated questions to the deterministic agenda (align date reference with the 92-day window)

**Date:** 2026-06-25
**PR:** [#739](https://github.com/padminipyapali/second-brain/pull/739) (Closes [#738](https://github.com/padminipyapali/second-brain/issues/738))
**Branch:** `fix/calendar-date-reference-window` → main (squash-merged as `4ff3645`)
**Time to Merge:** ~57 seconds on GitHub (created 23:15:41, merged 23:16:38 UTC) — the dev loop ran locally before push
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +77 −22 across 2 files, 1 commit

## 1. What Shipped

A classifier-routing fix for far-future dated calendar questions. "Show me the events on 7/25" (asked 2026-06-25, ~30 days out) was being refused with "calendar data only extends through mid-July (up to July 15)" even though the calendar fetch/coverage window is already **92 days** and the deterministic `answerAgenda`/`answerAvailability` paths held the data to answer it. The classifier simply never routed there.

Root cause was a **data-window-vs-prompt-window mismatch** (the #716 confusion class):
1. `CALENDAR_DATE_REFERENCE_DAYS` was hard-coded to **14** — the weekday→date reference the model uses to resolve named dates spanned only 14 days, so 7/25 had no sanctioned way to become `days: ["2026-07-25"]`.
2. The grounding `<events>` block is a deliberately small 21-day excerpt, and the prompt told the model to decline ("say so plainly") for any day outside the listed range — so the model treated the 21-day prompt excerpt as the calendar's true horizon (~July 15) and refused, instead of classifying as `agenda` mode.

The fix (`response.ts`, prompt + one constant):
1. `CALENDAR_DATE_REFERENCE_DAYS` is now a **drift-proof alias of `CALENDAR_LOOKUP_WINDOW_DAYS`** (92), so every date in the answerable window is individually resolvable from the reference (full 92 day-lines, ~600 extra tokens; DST-safe UTC-parts logic unchanged).
2. Reworded the AGENDA/AVAILABILITY rules so a named/dated day sets `days` **even when it falls beyond `<events>`**, scoped the "say so plainly" decline to specific-EVENT lookups ("when is my dentist?"), and added a line framing `<events>` as a near-term excerpt, not the calendar's limit.

Deterministic `answerAgenda`/`answerAvailability`/coverage and `EVENTS_BLOCK_WINDOW_DAYS` (prompt stays small) are untouched — they already handle in-range vs out-of-range once routing reaches them. Intended side effect: `buildCalendarDateReference` is shared by the calendar-*write* classifier, so the write path can now also resolve far-future dates (e.g. "schedule dentist Aug 22") — a capability gain, no regression.

## 2. Process

**SMALL PR (~77 LOC, 2 files) → lightweight review** per the standing rule (skip the separate fresh-context critic + CodeRabbit under ~100 LOC; keep build/lint/test + the adversarial gate). Built via an implementer; the orchestrator reviewed the diff directly and ran the adversarial-review gate.

Validation green: `npm run build`, `npm run lint`, `npm test` — @second-brain/server suite **2215 passed, 48 skipped**. Tests added: the reference now spans the lookup window (incl. a date ~30 days out) + a drift-guard asserting `CALENDAR_DATE_REFERENCE_DAYS === CALENDAR_LOOKUP_WINDOW_DAYS`; deterministic in-window-far-future returns "No events" (not a refusal) and >92d still refuses (already covered). The classifier is an LLM (unit tests mock it), so the real gate is a **live re-test after deploy**: "events on 7/25" should return the deterministic agenda, not a refusal.

No GitHub-side review activity (0 human reviews, 0 CodeRabbit GitHub review, 0 inline comments — 1 Vercel bot comment, excluded). Vercel: SUCCESS.

## 3. adversarialCatchRate

**Unmeasured (0 / 0).** Computed from evidence: this was a lightweight-review small PR, so no separate fresh-context critic was spawned by design. There were therefore **0 critic-caught findings out of 0** — the critic step was not exercised, so an "X caught / Y total" catch rate is not meaningful here. Recorded honestly as unmeasured rather than fabricated as 1.0. The adversarial gate passed with 0 blockers; 0 post-merge escapes.

The meaningful process signal in this PR is a **different** one (see §4): a single-pass exploration agent **misdiagnosed** the root cause, and the orchestrator caught it by independently verifying constants against `origin/main` before implementing.

## 4. What Went Well / What to Improve

**Went well — the load-bearing catch was a diagnosis verification, not a code review:**
The initial diagnosis (from an exploration agent) was **WRONG**: it claimed `CALENDAR_DATE_REFERENCE_DAYS` was still 14 — well, it WAS 14, but the exploration also asserted the *lookup/coverage window* constant needed bumping to 92 (it was already 92 on `origin/main`). The orchestrator caught the misattribution by reading the constants directly against `origin/main`, confirmed the data window was already 92, and **re-diagnosed** the real cause: the 14-day **date reference** (a different constant) plus the decline-from-excerpt prompt instruction. Had the orchestrator trusted the exploration pass, the "fix" would have bumped an already-correct constant and left the actual bug (the date-reference span + the prompt) in place — the refusal would have persisted.

**To improve:**
- The constant-aliasing approach is the right drift-proofing move (a const that must equal another const is now *defined as* that const, with a test pinning the invariant). Watch the ~600-token cost of the now-92-line reference if the lookup window ever grows much larger.
- The LLM classifier can't be unit-tested for the actual routing decision — the post-deploy live re-test is the real gate and must not be skipped.

## 5. Follow-Ups

- **Action required to confirm the fix in prod:** live re-test after deploy — "events on 7/25" (and a write like "schedule dentist Aug 22") should route to the deterministic path, not a refusal.
- If `CALENDAR_LOOKUP_WINDOW_DAYS` is ever raised substantially, re-check the date-reference token cost (currently ~600 extra tokens for 92 day-lines).

## Metrics Summary

| Metric | Value |
|--------|-------|
| adversarialCatchRate | unmeasured (0 caught / 0 total — lightweight review, no critic spawned by design) |
| Post-merge fix rate | 0.0 |
| Pre-merge iteration count | 1 (healthy) |
| Review rounds | 1 |
| GitHub comments | 0 (1 Vercel bot, excluded) |
| Planning quality | complete (Bug + Root cause + Fix + Validation + Designs N/A) |
| Fix-up taxonomy | none (single feature commit) |
| Notable process catch | orchestrator re-diagnosed a wrong exploration-agent root-cause claim by verifying constants against `origin/main` |
| CI | Vercel SUCCESS; server suite 2215 pass / 48 skip |
