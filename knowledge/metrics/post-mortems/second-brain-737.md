# Post-Mortem: PR #737 — feat(agenda): group events by calendar + distinct nanny-coverage band with free pockets

**Date:** 2026-06-25
**PR:** [#737](https://github.com/padminipyapali/second-brain/pull/737) (Closes [#736](https://github.com/padminipyapali/second-brain/issues/736))
**Branch:** feature branch → main (squash-merged as `b889b95`)
**Time to Merge:** ~3 minutes on GitHub (created 22:25:42, merged 22:28:21 UTC) — the dev loop ran locally before push
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +1003 lines across 9 files, 2 commits

## 1. What Shipped

PR #737 reshapes the "what's on today" Telegram agenda in two ways. First, events are now **grouped into per-calendar sections** — each section header is the calendar's colored dot + name, events are indented chronologically beneath (no per-event dot, no bottom legend), and sections are ordered by their earliest event start. Second, it introduces a **distinct nanny-coverage treatment**: calendars listed in the new `GOOGLE_COVERAGE_CALENDARS` env var are pulled out of the sections and pinned at the top as a `🍼 Covered 8:00 AM–7:00 PM · Shelo` band (one line per coverage interval, naming the coverer from the event title) plus a `🟢 Free 12:30–4:00 PM, 5:00–5:30 PM` line — the open hands-free pockets *inside* coverage (sub-intervals with no overlapping timed commitment, ≥15 min; the line is omitted if there are none). Coverage events are excluded from both the sections and the busy set. Interval math runs in absolute epoch-ms so it is DST-safe, and the pure union/subtract helpers are unit-tested directly. With `GOOGLE_COVERAGE_CALENDARS` unset, the agenda still renders the new grouped layout — just no coverage band.

## 2. Process

Built via the orchestrator **3-role team** (implementer → fresh-context critic → adversarial-review gate).

- **Implementer** wrote the grouping + coverage feature (commit 1).
- **Fresh-context critic** found **1 SHOULD-FIX**: a degenerate coverage event (start === end, or end < start) flowed straight into the coverage interval union, emitting a nonsensical `🍼 Covered 5:00–5:00 PM` band (or a reversed range) AND — because a zero-length point still satisfies the half-open overlap test — leaking its summary into a real band's coverer list. **Fixed pre-merge** (commit 2) by filtering timed coverage to positive-duration spans up front, mirroring the existing `subtractBusy` busy-set guard. Tests were added asserting zero-length and reversed coverage events are ignored.
- **Adversarial-review gate** passed. **0 blockers.**

Validation green: `npm run build`, `npm run lint`, `npm test` — @second-brain/server suite **2213 passed, 48 skipped**. Tests cover grouping/ordering/Other-bucket, coverage extraction, free-pocket interval math (overlap/containment/adjacency/threshold), no-coverage no-op, all-coverage day, fully-busy → no free line, all-day coverage, two sitters, the degenerate-event guard, multi-day, and a DST-safe case with a fixed non-UTC timezone.

No GitHub-side review activity (0 human reviews, 0 CodeRabbit GitHub review, 0 inline comments). Vercel preview: SUCCESS.

## 3. adversarialCatchRate

**1.0** — computed from evidence, all pre-merge.

- **N caught / M total = 1 / 1.**
- The single real issue surfaced by review (the degenerate-interval phantom band + coverer-name leak) was caught by the fresh-context critic — a class the implementer missed — and fixed before merge (commit 2).
- **0 post-merge escapes** (no follow-up fix PRs touching this feature).

This is rigorously computable from the commit record: commit 1 is the feature; commit 2 is the critic-attributed fix. The catch is attributed to step 4c (critic). Not fabricated against any baseline.

## 4. What Went Well / What to Improve

**Went well:**
- The fresh-context critic earned its keep: the degenerate-interval guard is exactly the kind of half-open-interval edge case that passes a happy-path read but corrupts real output. Fixed pre-merge with a test, mirroring an existing sibling guard (`subtractBusy`).
- Scope was narrowed honestly and documented in the PR's Decisions section rather than silently over-shipping.

**Key process learning (planning gap, not a code defect):**
During implementation the team surfaced that the **morning DIGEST uses a separate renderer** (`buildCalendarSection`, with travel times) that does **not** share the formatter used by the "what's on today" Q&A path. As a result the grouping + coverage treatment landed **only on the Q&A path**. The orchestrator's plan had implicitly assumed both surfaces shared one formatter. This shared-vs-separate render-path question should have been resolved in **planning (Step 1)** — by grepping for the renderer of each surface and confirming they are the same symbol — *before* scoping the feature as "applies to the agenda." When the surfaces turned out to use different renderers, the scope was correctly narrowed to the Q&A path and the digest documented as a deliberate follow-up. Captured as a cross-project planning lesson: **verify shared-vs-separate render paths before scoping a feature as "applies to both X and Y."**

## 5. Follow-Ups

- **(a)** Optionally extend the grouping + coverage treatment to the morning-digest renderer (`buildCalendarSection`). Deliberately out of scope here.
- **(b)** **Action required for the feature to appear in prod:** the user must set `GOOGLE_COVERAGE_CALENDARS=<nanny-calendar-id>` (comma-separated, same pattern as `GOOGLE_HIDDEN/BUSY_CALENDARS`; find the id via `npm --workspace @second-brain/server run debug:calendar`). Keep coverage calendar ids OUT of `GOOGLE_BUSY_CALENDARS`. With the var unset, the agenda still renders the new grouped layout — just no coverage band.

## Metrics Summary

| Metric | Value |
|--------|-------|
| adversarialCatchRate | 1.0 (1 caught / 1 total, all pre-merge) |
| Post-merge fix rate | 0.0 |
| Pre-merge iteration count | 1 (healthy) |
| Review rounds | 1 |
| GitHub comments | 0 (1 Vercel bot, excluded) |
| Planning quality | complete (Summary + Decisions + Config + Validation + sample render) |
| Fix-up taxonomy | defensive-coding: 1 (degenerate-interval guard) |
| CI | Vercel SUCCESS; server suite 2213 pass / 48 skip |
