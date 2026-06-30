# Post-Mortem: second-brain PR #831 — honor requested time range and keyword in calendar inquiries

**Date:** 2026-06-30
**PR:** [#831](https://github.com/padminipyapali/second-brain/pull/831) — Closes [#827](https://github.com/padminipyapali/second-brain/issues/827).
**Branch:** `fix/calendar-inquiry-range-keyword` → main (squash-merged, 1 commit)
**Time to Merge:** ~1.84h wall-clock (created 2026-06-30T03:38:37Z, merged 05:28:52Z). The full local loop — CodeRabbit CLI + 3 adversarial rounds + the 2779-test server suite — ran pre-push; the window is wall-clock until merge, not active GitHub review.
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +860 −18 across 8 files, 1 commit (~378 net source LOC; the rest is the new `response.calendar-query-planner.test.ts` plus additions to `calendar.test.ts`, `calendar-query-handler.test.ts`, `calendar-write-handler.test.ts`)

## 1. What Shipped

A fix for the bug (#827) where asking "what meetings do I have related to **randall museum** in the **next 8 months**" only searched a short window and answered "I can only see the next several weeks." The inquiry path fetched a **fixed** window (`CALENDAR_LOOKUP_WINDOW_DAYS = 92`) *before* the LLM ever saw the question, so an explicit range was ignored and far-future events were never fetched; matching was LLM-text-only with no keyword search.

The fix inserts a lightweight **planner** step before the event fetch:

1. **Planner** — new `planCalendarQuery` on `ResponseService` (Haiku, tool-forced structured output) reads the question with **no calendar data** (cheap) and returns `{ windowDays, keyword, rangeClampedNote }`.
2. **Window** — `windowDays` is **floored at the current default (92) and capped at 365**; it only ever *widens*, never shrinks, so the existing #715 far-future availability window is preserved and normal queries don't regress.
3. **Keyword** — for a specific-event lookup the planner returns a `keyword`, passed as Google Calendar's `q` so a wide window stays small and the event is found server-side.
4. **Pagination** — per-calendar `nextPageToken` paging (`maxResults: 250`, 10-page safety cap) so wide windows aren't silently truncated at Google's 250 default.

So "randall museum in the next 8 months" → a 240-day window with `q="randall museum"` — server-side filtered, small payload, event found.

## 2. Development Loop

Pipeline: explore → blueprint → implement (single pass) → local review pipeline (CodeRabbit CLI 4b + 3 adversarial rounds 4c) → SHIP → adversarial gate PASS. **Gates:** lint clean, server tsc clean, full server suite (2779) green, Vercel Preview CI SUCCESS. No GitHub reviews or inline comments (solo workflow; all review pre-push). The calendar-**write** path and `getTodayEvents` are untouched (write handler never calls the planner; all new params optional).

This PR is a positive outlier in its session cluster: unlike siblings #825/#830 which ran the lightweight-review lane (4b skipped), #831 ran the **full** local-review trio on a substantial diff and it paid off — 4 genuine defects were caught and fixed pre-push.

## 3. Adversarial / Review Effectiveness — adversarialCatchRate = 1.0 (measured found-and-fixed shade)

**The local review pipeline caught 4 genuine in-scope defects, ALL fixed pre-push, with 0 escapes to date.** This is a MEASURED 1.0 (real findings, real fixes, zero escapes — the same found-and-fixed shade as #828's 1/1), NOT a fabricated 1.0 and NOT the #830 critic-ran-clean null.

**Numerator = 4 caught defects:**

1. **(CodeRabbit, correctness)** The keyword filter wrongly narrowed **availability/agenda** fetches. For "when am I free to meet Dr. Lee next month?" an entity is named, but free/busy and agenda need the *complete* calendar — filtering by `q` would have **hidden real conflicts**. Fixed by forcing `keyword: null` for availability/agenda questions in the planner prompt.
2. **(CodeRabbit, validation)** Generic planner keywords were not validated server-side. Fixed with a `GENERIC_KEYWORD_STOPWORDS` denylist that coerces terms like "meeting"/"schedule"/"appointment" to null **regardless of model output** (validate LLM output against the source of truth).
3. **(Adversarial, defensive-coding)** Pagination partial-failure **discarded already-fetched pages**. Fixed so a page-2+ failure logs and returns the pages already collected for that calendar, while a first-page failure still propagates — preserving the per-calendar `allSettled` rejection and the "all calendars failed → throw" total-outage signal.
4. **(Implementer self-catch, correctness)** The blueprint assumed a stale default window (14); the actual `CALENDAR_LOOKUP_WINDOW_DAYS` is **92**. The implementer caught this and **floored `windowDays` at 92** so the planner can only widen — avoiding a silent regression of the #715 far-future availability window.

**Denominator = caught + escaped = 4 + 0 = 4. Rate = 4/4 = 1.0.** Post-merge escapes = **0** (no follow-up PR touches the calendar-query / planner / pagination files).

Findings 1–3 are the review steps' catches (4b: 2, 4c: 1); finding 4 was caught at implementation time (not a review step), so it doesn't appear in the per-step attribution but counts toward the real-defects-caught total.

## 4. Process Learning — CodeRabbit run against a STALE base inflated noise ~10×

The CodeRabbit CLI was invoked with `--base main` against a **LOCAL `main` that was 10 commits behind `origin/main`**. The review surface therefore became `local-main..HEAD` — the feature diff **plus** those 10 already-merged commits — so **~21 of 23 raw findings were about already-merged code (noise)** and only **2 were in-scope** to the actual PR diff (both legit, both fixed; findings 1–2 above).

**Recommendation (now captured in `~/.claude/knowledge/process-patterns.md` → Stale-Base Detection):** before running 4b, verify the review base is current — `git fetch origin && git rev-parse origin/main` vs `git rev-parse main`; if local `main` is behind, fast-forward it (`git fetch origin main:main`) or point CodeRabbit at the remote tip directly (`--base origin/main`). This is the review-tool analogue of the pre-push stale-base guard: that guard catches a stale *branch*; this catches a stale *review base*, which fails silently by burying the 2 real findings under 21 noise findings. When recording metrics, count only the in-scope/actionable findings (2), not the raw total (23).

## 5. Planning Quality

PR body is **complete**: Problem, Fix, Correctness guards (from review), Tests, Known limitations (4 explicitly deferred follow-ons), **Performance & Cost Impact** (one extra Haiku call per inquiry, ~$0.0003, ~80–150ms; wide windows kept cheap by the `q` filter + 10-page cap), Designs (no UI), Closes #827. The "Known limitations" section is a model of honest scope-bounding — abbreviation matching, far-future keyword-less agenda, lookup-vs-availability model judgment, and punctuation-suffixed stopwords are each named as deferred rather than silently omitted.

## 6. Metrics Summary

| Field | Value |
|-------|-------|
| Review rounds | 1 |
| Total comments (non-bot) | 0 |
| localReview.coderabbit | 2 in-scope found / 2 fixed (1 iteration; 21 raw findings were stale-base noise) |
| localReview.adversarial | 1 found / 1 fixed (3 rounds run) |
| adversarialCatchRate | **1.0** (measured found-and-fixed: 4 caught / 0 escaped) |
| postMergeFixRate | 0.0 (0 escapes) |
| preMergeIterationCount | 2 |
| Fix-up taxonomy | correctness:2, validation:1, defensive-coding:1 |
| Step compliance | 8/9 (89%) — 4a /simplify folded into single-pass implement; assessment: good |
| Planning quality | complete |
| PR size | 878 (860 add / 18 del) |
| Time to merge | ~1.84h wall-clock (loop ran pre-push) |
