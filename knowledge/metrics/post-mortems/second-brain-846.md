# Post-Mortem: second-brain PR #846 — slot-check (per-slot free/conflict + coverage) + respect Google event transparency

**Date:** 2026-07-02
**PR:** [#846](https://github.com/padminipyapali/second-brain/pull/846) — Closes [#843](https://github.com/padminipyapali/second-brain/issues/843) (slot-check), [#844](https://github.com/padminipyapali/second-brain/issues/844) (transparency).
**Branch:** `feat/calendar-slot-check` → main (squash-merged, 1 commit `8603ea9`; feature commit `4072ccef`)
**Time to Merge:** ~58s wall-clock (created 2026-07-03T00:20:20Z, merged 00:21:18Z). The full dev loop (understand → plan → implement → test → fresh-context adversarial review) ran PRE-PUSH; the GitHub window is push-to-merge only, not active review time.
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +798 −4 across 7 files, 1 commit. All 7 files are `packages/server/src/services/`: `calendar-availability.ts` (+226) / `.test.ts` (+174), `response.ts` (+244) / `response.calendar-query.test.ts` (+120), `calendar.ts` (+13), `classifier.ts` (+2) / `.test.ts` (+19). ~25 new tests.

## 1. What Shipped

A "slot-check" sub-mode of CALENDAR_QUERY plus a co-fixed free/busy transparency bug, both surfaced by a real scheduling message.

- **#843 — slot-check.** User pastes a scheduling message listing several DATED candidate slots (e.g. a doctor's office: Thu Jul 9 1–3pm / Fri Jul 10 10am–3pm / Tue Jul 14 10am, 11am, 2:30pm) + "which am I free?" → a per-slot checkmark reply: **✅ free / ❌ conflict** (busy-filtered to `GOOGLE_BUSY_CALENDARS`, naming the conflicting event), a **🍼 coverage** vs **⚠️ no-coverage** note (a nanny on shift), and a **📅 heads-up** note for all-day trips. Handles ranges, discrete time points (→ ~30-min window), per-date independence (no windows×days cross-product), DST-safe. `checkSlots` is a pure engine reusing the existing availability interval math; `response.ts` adds a slots tool variant + SLOT-CHECK prompt rule + few-shot + `parseSlotsInput` + `answerSlots`/`formatSlotsAnswer`; `classifier.ts` gains a pasted-multi-slot few-shot. Reply capped to Telegram's 4096 limit (per #833).
- **#844 — respect Google event `transparency`.** NO free/busy path respected the `transparency` flag, so every "Free"-marked event counted as busy → over-blocking. `transparency` is now threaded `CalendarEvent → CalendarQueryEvent → AvailabilityEvent`; `busyIntervalsForDay` SKIPS transparent TIMED events. This fixes slot-check AND the pre-existing over-block in the shipped "am I free" availability path. All-day transparent events (option c, user's pick): a transparent all-day trip (e.g. "Tahoe" marked Free) does NOT hard-block — a slot whose only overlap is Tahoe is FREE — but it surfaces as a 📅 heads-up note. Opaque all-day events still block. Coverage detection deliberately IGNORES transparency (a nanny shift is coverage regardless of its Free flag).

## 2. Development Loop

Pipeline: **UNDERSTAND** (read-only explore of the availability path) → **PLAN** (2 product forks resolved with the user) → **VALIDATE-FIRST real-model+real-calendar probe** → single-pass implement on a feature branch → gates (build + biome lint + full server suite **2835 passed / 0 failed**) → **fresh-context adversarial review → SHIP** + marker written → self-merge. No GitHub reviews or inline comments (solo workflow; all review pre-push; the only PR comment is the Vercel bot — a skipped/ignored server deployment, since deploy is Railway not Vercel). CI: Vercel Preview SUCCESS. **CodeRabbit was NOT run.**

Two design decisions shaped by the understand+probe front-loading:
1. **Understand-first re-shaped the feature.** The explore mapped the availability path and found it uses a windows×days CROSS-PRODUCT that structurally CANNOT represent a per-date candidate-slot list — so rather than contort availability, the plan added a clean new slot-check sub-mode that REUSES the interval math but computes per-date independently. Mapping the real code before scoping produced the right architecture (the #791/#805 understand-before-scoping family).
2. **Validate-first surfaced a latent bug.** The real-calendar probe (the exact 6 Dr. Hurd slots) exposed that no free/busy path respected `transparency` — a Free-marked all-day "Tahoe" event was over-blocking. This is a PRE-EXISTING bug in the shipped availability path; slot-check was just the first path validated against a real calendar that contained a Free-marked all-day event, so it surfaced there first.

## 3. Adversarial / Review Effectiveness — adversarialCatchRate = 1.0 (MEASURED found-and-fixed)

**adversarialCatchRate is a MEASURED `1.0`, NOT a fabricated/hardcoded value and NOT a critic-ran-clean null.** The distinction from the #830/#841 null shade: a review activity caught a GENUINE would-be-wrong behavior pre-merge, it was fixed WITHIN this PR, and 0 escaped.

- **The catch:** the VALIDATE-FIRST real-data probe (a review activity — validate-first against real external state, the gate for a feature reading a live calendar) caught the transparency over-block that the opaque-only unit fixtures were structurally blind to. This is a real defect (a Free-marked event wrongly blocking free slots) that would otherwise have shipped in slot-check AND remained latent in the availability path. It was found and fixed within this PR (the #844 co-fix), 0 escaped → `1 / (1 + 0) = 1.0`.
- **The fresh-context critic** additionally (a) SURFACED the sibling-sweep gap — 3 other free/busy consumers (Today-Card api.ts ~L3518, todo-scheduler schedule-todos-proposal.ts ~L214, agenda free-pockets) still dropping transparency → tracked as **#845 (OPEN)**, correctly triaged as a zero-regression conservative-over-block FOLLOW-UP, not a blocker; and (b) VALIDATED data-safety and the `checkSlots` math against real assertions; and (c) produced one FALSE-POSITIVE finding (a "PROBE_DEBUG console.error" that was actually a legit `probe` local variable), correctly caught by grepping the committed diff before acting.
- **Numerator (defects caught by a review activity pre-merge): 1** (the transparency over-block).
- **Denominator (caught + escaped): 1** — post-merge escapes = 0. #846 is the most recent merged PR; no later PR touches its files. **#845 is NOT an escape** — it is deliberate, tracked, zero-regression follow-up work (the 3 unswept consumers are UNCHANGED-from-before and conservatively over-block, never double-book), filed at 00:16Z, four minutes before merge.
- **preMergeCatchRateByStep:** the transparency fix was folded into the single implementation pass (the probe ran before/during implement, not as a post-implement fix commit), so there are 0 discrete fix commits — the catch is real but landed inside the one feature commit rather than as a separate `fix:` commit.

## 4. Process Learnings (captured to knowledge base)

Five learnings, all recurring-theme reinforcements rather than novel:

1. **Real-data probe catches what synthetic unit fixtures cannot — the unimagined-input class.** 25 passing unit tests were all OPAQUE-event (the author's mental model of "busy"); the real calendar contained a Free-marked all-day trip no fixture encoded, and the probe exposed the over-block in one shot. → `process-patterns.md` validate-first family (fixtures-vs-reality axis, complementing #772/#791/#825/#837).
2. **A new feature exposes a pre-existing latent bug in a shared substrate.** The transparency over-block predated slot-check in the availability path's `busyIntervalsForDay`; slot-check was the first caller to exercise it against real data. When new code misbehaves through a shared primitive, fix the substrate (fixes all callers), not the symptom in one call site. → `architecture-patterns.md` → Debugging Process.
3. **Sibling-sweep a SEMANTIC CONCEPT across all consumers, not a code pattern across the diff.** Transparency-respect had to reach every free/busy consumer (availability, slot-check, Today-Card, todo-scheduler, agenda free-pockets) — they compute busy differently, so a syntactic grep misses them; sweep by tracing the concept. Same class as coverage-vs-busy (#808/#830) and the batch-404 contract-twin sweep (#837). → `process-patterns.md` → Review Discipline.
4. **Verify a critic's SPECIFIC cited finding against the actual committed diff before acting.** The "PROBE_DEBUG console.error" was a false positive (a legit `probe` variable); grepping the diff avoided a needless amend + re-review. Per-finding verification, not blanket distrust (the untracked temp probe FILE the critic also flagged was real and correctly deleted). → `process-patterns.md` → Review Discipline.
5. **One owner per worktree — idle ≠ dead; confirm stand-down before spawning a replacement.** The reused implementer went idle for hours; the orchestrator spawned a fresh one AND the old one resumed — both briefly owned the same worktree. Caught immediately (old stood down, fresh stopped, no double-commit). Distinct from the plush-press #25 replace-a-dead-agent rule: a definitively-killed agent may be replaced, but a merely-idle one can resume and edit the tree — so the baton pass requires a confirmed release, not an inferred timeout. → `orchestrator-protocol.md` → Error Recovery.

## 5. Planning Quality

**Complete.** PR body has per-issue Problem + Fix (naming what stays unchanged — coverage ignores transparency, opaque all-day still blocks, the non-slot availability path), a Validate-first section recording the real-model+real-calendar probe result, Tests (25 new, itemized by unit + the full-suite 2835/0 count), a Review section (SHIP + the #845 sibling-sweep triage with explicit zero-regression justification), and Closes #843, #844. Two product forks were resolved WITH the user before finalizing (free = my-calendar + coverage-aware; all-day transparent a/b/c → user picked c). No explicit Performance & Cost section — acceptable: the classifier few-shot adds a small prompt-token cost and slot-check is one extra tool variant on an existing LLM call path (no new external API round-trips, no added DB load; `checkSlots` is pure in-memory interval math). Scope is clean: one squash commit, no revert/redesign churn, all 7 files in one service package.

## 6. Metrics Summary

| Field | Value |
|-------|-------|
| Review rounds | 1 |
| Total comments (non-bot) | 0 |
| localReview.coderabbit | null (CodeRabbit NOT run; no `## Local Review` section) |
| localReview.adversarial | 1 found / 1 fixed (the transparency over-block, caught by the validate-first probe, fixed in-PR) |
| adversarialCatchRate | **1.0** (MEASURED found-and-fixed — the real-data probe caught the transparency over-block pre-merge; 0 escaped) |
| postMergeFixRate | 0.0 (0 escapes; #845 is tracked zero-regression follow-up, not a fix of this PR) |
| preMergeIterationCount | 1 (single implementation pass; catch folded into the feature commit) |
| Fix-up taxonomy | all zero (0 discrete fix commits) |
| Step compliance | understand + plan + implement + test + adversarial(4c) ran; 4b (CodeRabbit) NOT run → skip assessment: neutral-leaning-good (adversarial gate + full suite green; no post-merge signal that CodeRabbit would have caught anything) |
| Planning quality | complete |
| PR size | 802 (798 add / 4 del) |
| Time to merge | ~58s wall-clock (full loop ran pre-push) |

## 7. Recommendations

1. **Keep the validate-first-real-data probe as a MANDATORY plan step for any feature reading real external state.** It is the single highest-value gate here — it caught a pre-existing latent bug that a green 25-test opaque-only suite never could, and it shaped the architecture. Put "real-data probe against live source" in the plan explicitly, not as ad-hoc polish. (Now reinforced in `process-patterns.md`.)
2. **Ship the #845 sibling-sweep follow-up before the next free/busy feature lands.** Three consumers still drop transparency; each new free/busy path added on top of the inconsistent substrate risks the same over-block resurfacing. The concept-level fix (respect transparency in the shared engine everywhere) closes the class.
3. **Record the review lane explicitly in the PR body.** A one-line `Steps skipped: 4b (CodeRabbit) — reason: <full adversarial gate + real-data probe + 2835/0 suite covered it>` would make the metric pipeline self-describing instead of reconstructed from evidence (recurring recommendation across recent PRs).
4. **Enforce the one-owner-per-worktree baton pass.** The idle-implementer overlap was caught with no damage, but the cheap fix is to never create the overlap — require a confirmed stand-down ACK (not an inferred timeout) before any replacement touches a shared worktree. (Now in `orchestrator-protocol.md`.)
5. **The 1.0 shade here is honest and measured** — a real review activity (the validate-first probe) caught a genuine would-be-wrong behavior pre-merge and it was fixed in-PR. This is distinct from the #830/#841 critic-ran-clean null; do not collapse the two shades.
