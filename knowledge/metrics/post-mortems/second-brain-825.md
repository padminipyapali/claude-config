# POST-MORTEM: second-brain PR #825 — deadline-aware dated todos in the proposal

**Branch:** feat/sc-... → main | **Author:** padminipyapali | **Open→merge:** ~59s (essentially all dev time preceded PR creation)
**Squash-merged as:** 7a62556 | **Closes:** #820
**Size:** +351 −35 across 7 files, 1 squashed commit (~250 production LOC; the 16 new tests live in 3 .test.ts files)

## Bug

`schedule my todos` silently DROPPED every due-dated todo. The `schedule-todos-handler` selection filtered the candidate set to `open.filter(t => !t.dueDate)`, so a todo the user explicitly marked due 6/29 — the real **"Mira packing list for Yosemite" due 2026-06-29** — vanished from the proposal entirely. Not placed, not flagged, not even counted in the remaining count. The user found it by exercising the live bot.

## Fix (deadline-aware placement)

1. **Selection** — the candidate set now includes dated todos, ordered dated-first with the soonest deadline leading, so a near deadline can't be crowded out of the cap; the remaining-count covers all open todos including dated ones.
2. **Threading** — `dueDate` flows through `ProposalTodo` → `SchedulableTodo` → `Placement`, and is preserved across the refine re-pack round-trip.
3. **Packer** — `packTodos` scans earliest-day-first and NEVER places a dated todo AFTER its due date. Past-due → placed ASAP; due-after-window → placed in-window; can't-fit-before-deadline → surfaced in a distinct "couldn't schedule by the deadline" flag, **never silently dropped**. Composes with the #817 `prioritizeFirst` floor and the dependency floor (a dated todo's dependency chain is still pulled in ahead of it).
4. **Rendering** — placed dated todos show their deadline inline ("(due Mon, Jun 29)"); deadline-misses get their own section.

## Technical verification (against the merged diff)

- **Never placed after deadline** — verified via a TIMEZONE-IMMUNE `YYYY-MM-DD` string compare. `dueDateToYmd` converts the pg `DATE` to a UTC `YYYY-MM-DD` with no off-by-one; `packTodos` rejects any candidate day whose ymd > the deadline ymd. The invariant holds regardless of server/user timezone.
- **Undated path byte-identical** — a todo with no `dueDate` threads through selection/packer/render exactly as pre-#825; the dated branch is additive, gated on `dueDate` being present.
- **`dueDateToYmd` never throws** — pg `DATE` is always a valid date or null; null short-circuits to the undated path.
- **Composition holds** — dated-first / soonest-deadline-leading selection preserves the #817 `prioritizeFirst` floor and the dependency floor; the #812 weekend rollover still applies to the undated remainder.

## Process

- **SAME implementer** — 6th fix in the schedule-todos cluster this session; context reused across the cluster for BUILDING (never for reviewing).
- **VALIDATE-FIRST AGAINST PRODUCTION DATA — the decisive gate.** The probe did NOT inject a synthetic fixture. It QUERIED THE REAL PRODUCTION DB for the user's actual open todos, found the genuine **"Mira packing list for Yosemite" due 2026-06-29** (the exact record from the bug report) plus two genuinely past-due todos, and ran the full flow against the real Google Calendar:
  - **Before** the fix: the real record was dropped (excluded by `!t.dueDate`, absent even from the remaining-count).
  - **After** the fix: it APPEARS, **placed ON 6/29** (its deadline); the past-due pair placed ASAP with due dates rendered inline.
  - This is the strongest form of the validate-first family (#772/#779/#791/#808): the fix was proven on the EXACT failing input pulled live from production — zero gap between "what we tested" and "what the user hit."
- **Fresh-context critic = SHIP** — 0 blockers, 0 actionable findings. Load-bearing checks: never-placed-after-deadline (tz-immune `YYYY-MM-DD` compare), undated-path byte-identical, `dueDateToYmd` never throws, composition with #817 + dependencies + #812 weekend rollover.
- **CodeRabbit (4b) NOT run** — ~250 production LOC, lightweight-review-small-PRs lane.
- 16 tests: on-deadline / never-after / past-due→ASAP / due-after-window / can't-fit→deadline-reason / undated byte-identical / compose-with-`prioritizeFirst` / due-date inline / distinct deadline-miss section / remaining-count-includes-dated. The old "excludes dated todos" test (which asserted the bug) was REPLACED. Full server suite (2735) green. Vercel CI SUCCESS.

## Metrics

- **adversarialCatchRate:** `null` — **critic-ran-clean shade** (two-shades rule, process-patterns line 21). The critic RAN and returned SHIP with 0 actionable findings → `0/(0+0)` undefined → null (NOT a fabricated 1.0, NOT the critic-skipped null). The decisive correctness gate was the production-data probe, not the critic.
- **postMergeFixRate:** 0.0 — **0 post-merge escapes.** No PR after #825 has touched the schedule-todos / todo-scheduling files.
- **reviewRounds:** 1 | **totalComments:** 0 | **preMergeIterationCount:** 1 (healthy)
- **stepCompliance:** 8/9 steps run; 4b (CodeRabbit) skipped (lightweight lane); complianceRate 0.889; **skipAssessment: good** (0 escapes, no post-merge issue a CodeRabbit pass would have caught).
- **planningQuality:** complete (Bug / Fix / Validate-first / Tests / Review sections in body).
- **stepTiming:** not tracked (no `## Step Timing` section).

## Noted follow-up (recorded, not fixed)

- **No EXPLICIT test for the "dated todo blocked by an UNPLACED dependency → reason=deadline" combined edge.** The behavior is correct-by-construction and its constituent paths are each tested individually (can't-fit-before-deadline → deadline reason; dependency floor), but the specific intersection isn't asserted by a dedicated test. Legitimate as a tracked follow-up (both constituents covered, behavior correct), NOT a ship-blocker.

## Knowledge captured

`~/.claude/knowledge/process-patterns.md` — three updates:
1. **Cluster entry (line 87) extended** to CONFIRMED-AT-FULL-CLUSTER-SCALE: the single schedule-todos feature generated SIX fixes in one session (#806/#808, #812/#814, #816/#818, #817/#821, #820/#825), EVERY one surfaced by the user exercising the LIVE BOT. General lesson: a complex feature isn't "done" at v1; ship → real use → next bug is the real loop, and live-bot dogfooding out-finds the entire pre-merge gate stack for an interactive feature. Reusing one implementer's context across the cluster was efficient and kept the fixes mutually consistent; each still earned an independent fresh-context critic.
2. **Validate-first family (after #772)** — new STRONGEST-FORM entry: a probe that QUERIES PRODUCTION DATA and finds the user's ACTUAL failing record (not a synthetic fixture) and proves before/after on THAT record is the highest-confidence validate-first gate — stronger than real-model (#779/#818/#821) or real-sheet (#772) probes, because it closes the gap between "what we tested" and "what the user hit." For a data-driven bug whose failing input is a specific persisted record, query the real store for that record and run the fix on it.
3. **Combined-edge test-gap deferral rule** — new entry (test-coverage sibling of the #791 correct-not-wrong deferral): a missing test for the INTERSECTION of two individually-covered, correct-by-construction paths may ship as a tracked follow-up; a missing test for a path with NO coverage may not.

## Process notes / recommendations

- **The 4b-skip remains unrecorded in-artifact** — no explicit `Steps skipped:` line in the PR body, the same gap noted across the whole schedule-todos cluster (#808/#813/#814/#818/#821) this session. A one-line `Steps skipped: 4b (CodeRabbit) — lightweight lane` in the body would close it. Recorded here as not-tracked (null) for CodeRabbit counts, not zero.
- **The cluster is the headline process signal.** Six fixes on one feature in one session, every one found by live use — the strongest evidence yet that live-bot dogfooding is the highest-yield bug finder for interactive features and that v1 of a multi-branch feature should be budgeted as a cluster, not a one-shot.
