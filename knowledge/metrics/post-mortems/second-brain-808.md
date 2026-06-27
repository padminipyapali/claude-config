# POST-MORTEM: second-brain PR #808

**Title:** fix(schedule-todos): exclude nanny-coverage calendars from the todo free-time busy set.
**Branch:** fix/schedule-todos-coverage-busy → main | **Author:** padminipyapali | merged 2026-06-27T20:37:06Z (squash `0d214de`)
**Size:** +221 / -10 across 4 files, 1 commit | open-to-merge ~1 min
**Closes:** #806

## Bug & Root Cause

"schedule my todos" falsely replied *"Your weekdays are fully booked this week, so there's no free 9am–6pm time to slot todos into."* when the user had ample free time.

`computeWeekFreeWindows` built the scheduler's busy set as `hidden-filtered → busy-filtered`, **never excluding COVERAGE calendars**. Coverage events (nanny shifts, e.g. "Shelo 8am–7pm" on the Nannies calendar) are documented as *not* making the parent busy — but a long shift filled the entire 9 AM–6 PM window → `totalFreeMin === 0` → false "fully booked." Amplifier: `filterToBusyCalendars` returns ALL events when `busyCalendarIds` is empty, so an empty/misconfigured `GOOGLE_BUSY_CALENDARS` made every event (including coverage) count as busy at this site.

The availability and agenda paths already excluded coverage from busy/free computation; **only the todo scheduler missed it** — it hand-built its busy set from raw filters instead of routing through the coverage-aware path.

## Fix

New `filterOutCoverageCalendars` helper (the negative complement of `filterToBusyCalendars`); the scheduler's busy set is re-layered as `hidden → coverage-excluded → busy`. Coverage calendars never block todo time, even when `GOOGLE_BUSY_CALENDARS` is empty. Scoped to the scheduler path only; the existing availability/agenda filters were already correct and left untouched. ~54 production LOC (`schedule-todos-proposal.ts` +19/-6, `calendar.ts` +35/-0) + 9 tests (~167 test LOC, 2 test files).

## Process Flow

1. **Diagnose** — a read-only Explore agent root-caused the false "fully booked."
2. **Validate-first probe** — BEFORE writing the fix, the implementer ran a diagnostic probe against the user's REAL calendar, anchored to next week's actual weekdays, quantifying 9 AM–6 PM free minutes under four configs:

   | busy config | free Mon–Fri | result |
   |---|---|---|
   | `busy=Home` (default) | 1965 min | already fine |
   | `busy=EMPTY` (the bug) | 0 min | false "fully booked" |
   | **fixed** + `busy=EMPTY` | 60 min | no longer "fully booked" |
   | **fixed** + `busy=Home` | 1965 min | ✓ |

   The probe printed provenance (the "Shelo 8am–7pm" shifts resolve to a `sourceCalendarId` on the Nannies/coverage calendar, NOT Home), reproducing the symptom on live data, localizing the trigger to the `busy=EMPTY` config, and proving the fix under both broken and correct configs.
3. **Fix + 9 tests + re-probe.**
4. **Fresh-context critic → SHIP** (0 blockers, 0 actionable findings; layering correct, helper scoped to scheduler path, tests assert the #806 repro).
5. **CI** — Vercel Preview SUCCESS. Full server suite (2614) green.

CodeRabbit (4b) NOT run — small fix, per the lightweight-review-for-small-PRs convention.

## Config Dimension (config-vs-code split)

The probe surfaced that this is not purely a code bug. The code fix makes coverage-exclusion robust regardless of config. Separately, for full/accurate free time the user's `GOOGLE_BUSY_CALENDARS` (Railway env) should be the **Home** calendar (`padmini.pyapali@gmail.com`) or unset (→ defaults to Home); **empty, or a broad list including coverage calendars, is the production trigger.**

## Metrics

- **Review rounds:** 1 (no CHANGES_REQUESTED). No GitHub reviews, no inline comments. Self-merged by author; only the Vercel bot commented (excluded).
- **Local review:** CodeRabbit not tracked (null); adversarial 0 findings / 0 fixed (critic ran clean).
- **adversarialCatchRate:** `null` — *critic-ran-clean* shade (critic ran, 0 blockers, 0 findings; undefined fraction 0/0 → null, not fabricated 1.0, not critic-skipped). The load-bearing gate was the real-calendar validate-first probe.
- **Fix-up metrics:** postMergeFixRate 0.0 (no follow-up PRs touch these files); preMergeIterationCount 1; fixup taxonomy all 0 (single feature commit, no fix commits).
- **Step compliance:** ran 1, 2a, 2b, 3, 4a, 4c, 4d, 5; skipped 4b (CodeRabbit, small-PR convention). complianceRate 0.889. **skipAssessment: good** — 0 post-merge escapes; the skipped step (CodeRabbit) would not have caught a semantic free/busy bug the real-data probe + critic already covered.
- **Step timing:** not recorded in PR body (null). Open-to-merge ~1 min; all dev preceded PR creation.
- **Planning quality:** complete (Bug, Root cause, Fix, Validate-first table, Config note, Tests, Review). Cost section N/A (bug fix, no new paid API).
- **PR size:** 231 (additions + deletions).

## Adversarial Review Effectiveness

Pre-push catch potential is high for this bug class but it was caught EARLIER and more cheaply by the validate-first probe, which is the right gate: a code critic reasoning about the diff cannot know that the user's real "Shelo 8am–7pm" shifts live on the coverage calendar or that the production config has an empty busy-list — only a real-calendar probe observes that. The critic correctly verified the *layering* (`hidden → coverage-excluded → busy`) and scoping (no regression to availability/agenda) once the probe had established the root cause. No new adversarial-checklist gap; the lesson is a knowledge-file pattern (sibling-sweep a semantic concept; validate-first for a bug), not a checklist item.

## Knowledge Updates

1. `testing-patterns.md` (Fixtures vs. Live Product Data) — **"Validate-first applies to a BUG too"**: a diagnostic probe that reproduces against real data AND quantifies before/after under each config proves both root cause and fix, and reveals a config-vs-code split. Bug-side companion to the #772/#791 feature-probe family.
2. `process-patterns.md` (Planning Discipline) — **"A cross-cutting SEMANTIC DISTINCTION must be applied at EVERY consumer that computes the same quantity"**: sibling-sweep the *concept* (coverage = you're free), not just a code token; the site that diverges is the one that hand-built its busy-set instead of routing through the shared filter. Semantic-concept axis of the #737 shared-code-path sibling-sweep family.

## Recommendations

1. **Apply the config recommendation in Railway** (out-of-band): set `GOOGLE_BUSY_CALENDARS` to the Home calendar (or unset). The code fix neutralizes the coverage-amplifier, but an empty/broad busy-list still degrades free-time accuracy at every busy-computing site. This is the config half of the config-vs-code split.
2. **Sibling-sweep finished, but keep the semantic-concept lens for the next free/busy change** — any future consumer that computes "am I busy/free" (a new digest, a new scheduler, a new availability surface) must route through the coverage-aware filter, not re-assemble a busy set from `hidden → busy` primitives. The new `filterOutCoverageCalendars` helper is the shared seam to reuse.
3. No process change needed — the validate-first-for-a-bug + fresh-context-critic + small-PR-lightweight-review combination produced a 0-escape outcome at ~54 production LOC. This is the lightweight gate working as designed.
