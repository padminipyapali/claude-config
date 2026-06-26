# Post-Mortem: PR #743 — fix(schedule-todos): don't propose todo slots in the past — clip today's window to the current time

**Date:** 2026-06-25
**PR:** [#743](https://github.com/padminipyapali/second-brain/pull/743) (Closes [#742](https://github.com/padminipyapali/second-brain/issues/742))
**Branch:** `fix/schedule-todos-nowclip` → main (squash-merged as `3e0b206`)
**Time to Merge:** ~3 min on GitHub (created 00:38:10, merged 00:40:54 UTC) — the dev loop ran locally before push
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +272 −8 across 3 files, 2 commits

## 1. What Shipped

A past-slot fix for the "schedule my todos" flow. At 5:23 PM, the scheduler proposed todo slots at 9:30–10:15 AM **the same day** — times that had already passed. `computeWeekFreeWindows` (`schedule-todos-proposal.ts`) built today's free window from 9 AM regardless of the current time.

The fix clips TODAY's effective free-window start to `max(9am, ceil(now → next 5 min))` in the user's timezone:
- 5:23 PM → 5:25 PM (never a past slot); after 6 PM → today contributes nothing (packing starts the next weekday at 9 AM); before 9 AM → today keeps the full 9 AM–6 PM window.
- Future weekdays are unaffected.
- Applied as a **single post-pass to BOTH the calendar-derived and no-calendar branches, after busy-subtraction**, so a proposed slot is never in the past whether or not a calendar is connected. The refine path inherits the fix (same function).
- DST-safe (parts-based, no UTC-noon reformat — the #683 contract). Working hours unchanged (weekdays 9 AM–6 PM).

**Known pre-existing scope left unchanged:** scheduling on a weekend, or after 6 PM Friday, yields "no free weekdays this week" rather than rolling into next week — the fix correctly clips *today* but doesn't widen the week window. Documented as a possible follow-up.

## 2. Process

**Full 3-role team** (implementer → fresh-context critic → adversarial gate) — not the lightweight path, despite the moderate size, because the change touches timezone/DST date math in two branches.

Validation green: `npm run build`, `npm run lint`, `npm test` — @second-brain/server suite **2237 passed, 48 skipped** (up from 2236; the malformed-tz fix added a test). Tests use Z-dates, a fixed non-UTC tz, and an injected `now`: 5:23 PM → no past slot; 7 PM → tomorrow; 8 AM → full day; future weekday unaffected; Saturday → no weekdays; malformed tz → UTC, no throw.

No GitHub-side review activity (0 human reviews, 0 CodeRabbit GitHub review, 0 inline comments — 1 Vercel bot comment, excluded). Vercel: SUCCESS.

## 3. adversarialCatchRate

**1.0 (1 caught / 1 total).** Computed from evidence: the fresh-context critic found **0 blockers + 1 SHOULD-FIX** the implementer missed — `computeWeekFreeWindows` defaulted the timezone to UTC only when *falsy*, so a truthy-but-invalid IANA zone (`"PST"`, `"America/Typo"`) reached `Intl` and threw a `RangeError`, where the sibling window functions (`defaultWeekDays`, `computeFreeWindows`) try/catch-degrade to UTC. The new clip path lacked the invalid-IANA guard its siblings already had. Fixed pre-merge in commit `771feb8` (validate the resolved zone once up front, fall back to UTC). **0 post-merge escapes.** Recorded honestly as 1.0 from real evidence, not fabricated.

## 4. What Went Well / What to Improve

**Went well — the critic caught a real regression class, not a nit.** The implementer correctly handled the clip math, both-branch application, DST, and "today" identification, but introduced a *new* tz-consuming code path without matching the siblings' invalid-IANA contract. A falsy-only default (`tz || "UTC"`) is a silent trap: empty strings degrade cleanly, but `"PST"` crashes the request. The critic's value here was cross-referencing the new path against the existing window functions' error contract — exactly the kind of consistency check a same-author review misses.

**To improve:**
- When introducing a new path that consumes a user-supplied timezone, grep the sibling tz consumers first and copy their try/catch-to-UTC contract up front, rather than discovering the gap in review.
- The weekend / after-6-PM-Friday "no free weekdays this week" semantics are now a known sharp edge — worth a follow-up issue to roll into next week rather than returning empty.

## 5. Follow-Ups

- Consider a follow-up to widen the week window when "today" is a weekend or past 6 PM Friday (roll into next week) instead of returning "no free weekdays this week."
- Captured a cross-project learning in `~/.claude/knowledge/typescript-patterns.md` (Date / Timezone Pitfalls): new `Intl.DateTimeFormat` paths built from user-supplied timezones must guard malformed-but-non-empty IANA strings and match sibling functions' UTC-fallback contract.

## Metrics Summary

| Metric | Value |
|--------|-------|
| adversarialCatchRate | **1.0** (1 caught / 1 total — critic found the malformed-tz throw; fixed pre-merge `771feb8`; 0 post-merge escapes) |
| Post-merge fix rate | 0.0 |
| Pre-merge iteration count | 1 (healthy) |
| Review rounds | 1 |
| GitHub comments | 0 (1 Vercel bot, excluded) |
| Planning quality | complete (Bug + Fix + Known scope + Validation + Designs N/A) |
| Fix-up taxonomy | 1 defensive-coding (the critic-caught malformed-tz fallback) |
| Notable process catch | fresh-context critic caught a new tz path missing the siblings' invalid-IANA UTC-fallback contract |
| CI | Vercel SUCCESS; server suite 2237 pass / 48 skip |
