# POST-MORTEM: second-brain PR #791 — feat(calendar): nightly nanny-coverage gap check for the week ahead.

**Branch:** `feat/nightly-coverage-check` → `main` | **Author:** padminipyapali | **Merged:** 2026-06-27T18:08:47Z (squash → `e47ac2a`, from `04eba9a`)
**Size:** +916 −3 across 7 files, 1 commit (~457 production LOC + ~459 test LOC, 29 new tests) | **Closes #787; deferred follow-ups → #789**
**Open-to-merge window:** ~7.5 min (created 18:01:17Z → merged 18:08:47Z)

## Feature

A nightly scheduler (`CoverageScheduler`, mirroring `MorningBriefScheduler`: 60s poll, hour-in-timezone gate, restart-safe, never-throws, opt-in) plus a pure gap engine (`detectCoverageGaps`, reusing calendar-agenda's `subtractBusy`/`unionIntervals`). It scans the next 7 days, flags timed Home-calendar commitments (`NEEDS_COVERAGE_CALENDARS`) with no overlapping nanny shift (`GOOGLE_COVERAGE_CALENDARS`), and pushes a Telegram digest grouped by local day (DST-safe wall-clock, HTML-escaped titles). All-day nanny events cover their whole day; all-day commitments are skipped; gaps < 30 min ignored.

## LOCAL REVIEW (pre-push)
- **CodeRabbit:** NOT run on this PR → recorded `null` (not-tracked, not 0).
- **Adversarial / fresh-context critic:** RAN → **SHIP** with exactly ONE non-blocking should-fix (no-coverage-events sentinel) plus an acknowledged product question (evening cutoff for late-night adult events). **Both deliberately DEFERRED to tracked follow-up #789.** 0 blockers. `adversarialFindings: 1, adversarialFixed: 0`.
- **Real-data validate-first probe (load-bearing correctness gate):** after the 29 unit tests, the engine was run against the user's LIVE calendar over the real next-7-days → **12 Home commitments + 8 nanny shifts → 3 genuine gaps** (two evening events past the last shift + a 30-min date-night tail). Every weekday commitment inside the 8 AM–7 PM shifts correctly produced NO gap. DST, cross-midnight rendering, and HTML-escaping all verified on real data.
- **Shift-left:** the one surfaced finding was caught pre-push by the critic (then deferred); zero issues escaped to GitHub review or post-merge.

## STEP COMPLIANCE
- **Steps run:** 1 (plan, incl. a 5-agent parallel read-only UNDERSTAND pass), 2a+2b (implement), 3 (test), 4a (simplify), 4c (adversarial/critic SHIP), 4d (CI = Vercel SUCCESS), 5 (push+PR) — **8/9**.
- **Steps skipped:** 4b (CodeRabbit) — not run on this PR (recorded not-tracked).
- **Compliance rate:** 88.9%.
- **Skip assessment:** **good** — 0 post-merge escapes; the real-data probe + critic substituted as the correctness gate.

## STEP TIMING
Not recorded in PR body (`stepTiming: null` fields). Open-to-merge ~7.5 min; the bulk of dev effort (understand pass, implementation, 29 tests, real-data probe, critic) preceded PR creation.

## REVIEW FRICTION (post-push)
- **Review rounds:** 1 (0 CHANGES_REQUESTED; self-merged, the local critic was the gate — expected for solo dev).
- **Comments:** 0 inline, 0 human general (only bot comments: Vercel deployment status).
- **Categories:** all 0.
- **Timeline:** created → merged in ~7.5 min; no GitHub review round.
- **Self-merge:** yes, no peer review — the multi-lens local gate (understand pass + unit tests + real-data probe + fresh-context critic) is the substitute, consistent with this project's established lightweight-review-for-clean-PRs posture.

## ADVERSARIAL REVIEW EFFECTIVENESS
- Critic verified gap-math arg order, all-day handling, scheduler safety (lastSentDate-before-await, restart-suppression, never-throws), 7-day window bounds, DST-safety, HTML-escaping.
- **Covered:** the one surfaced finding (degenerate "empty coverage source → flag everything" noise) is a real should-fix the critic caught; deferred to #789 on the strength of the probe showing the coverage source IS populated (degenerate branch dormant in prod).
- **adversarialCatchRate:** `null` (unmeasured) — critic-ran-clean shade. A real fraction is undefined (0 fixed of 0 blockers; the 1 finding was a deferral, not a blocker). NOT fabricated 1.0, NOT a critic-skipped null. Distinguished in `adversarialCatchRateNote`.

## FIX-UP METRICS
- **Post-merge fix rate:** 0% (0 post-merge fix commits — #789 is deferred *feature* follow-ups, not bug fixes for escaped defects).
- **Pre-merge catch rate by step:** 4a: 0 | 4b: 0 | 4c: 0 | 4d: 0 | post-push: 0 (single squashed commit, no fix commits — the one finding was deferred, not fixed in-PR).
- **Pre-merge iteration count:** 1 (healthy).
- **Fix-up taxonomy:** all 0.
- **Legacy fix-up ratio:** 0% (0 fix / 1 total commit).

## PLANNING QUALITY
- **Description:** complete — What / How it works / Config / Validate-first (real-data) / Tests (29) / Review / Follow-ups (deferred, #789). The "What's NOT in this PR" discipline is satisfied via the explicit deferred-follow-ups section.
- **Scope:** clean — single commit, single concern, branch lifetime well under 48h.
- **No redesign indicators.**
- **Planning checklist:** entry points and the degenerate (empty-coverage) state were enumerated and routed to #789; no explicit "Performance & Cost Impact" header, acceptable here (nightly internal job reusing existing calendar fetches; no new paid API call).

## CODE QUALITY SIGNALS
- **Recurring issues:** none.
- **New unrecorded patterns captured:**
  1. **UNDERSTAND-BEFORE-SCOPING corrected a false premise** — the orchestrator assumed #678's coverage-gap detection already existed; a 5-agent parallel read-only understand pass over the real code found what shipped (#737) was the INVERSE (free pockets *inside* coverage, not events *lacking* coverage). Reading the actual code before writing the spec prevented building on a false assumption. Codebase-internal analogue of validate-first-against-real-data.
  2. **REAL-DATA probe does double duty** — confirmed output plausibility AND verified the gating data source (Nannies calendar) is populated (not in the degenerate "everything flags" mode), AND surfaced the exact calendar IDs the user must configure.
  3. **Degenerate "no data → flag everything" is a SAFE deferral** when the probe confirms the source is currently populated and the v1 branch is correct-not-wrong; filed as tracked #789, not a TODO.

## PROCESS EFFICIENCY
- **Automation opportunities:** none new — the value here was a human/agent understand pass + real-data probe, neither of which a linter or the adversarial checklist can substitute for.
- **Iteration:** efficient (1 round).
- **CI:** all passed (Vercel build SUCCESS; full server suite 2541 green locally).

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/process-patterns.md` (Planning Discipline): added 3 entries — UNDERSTAND-BEFORE-SCOPING (false-premise / inverse-feature catch), REAL-DATA validate-first double duty (output + gating-source-populated + config-id discovery), and the safe-to-defer degenerate-mode rule.
- `~/.claude/knowledge/testing-patterns.md` (Fixtures vs. Live Product Data): added the gating-source dimension of the #772 live-source probe rule — a probe for a feature that GATES on a second live source must assert that source is non-empty for the real window.
- `~/.claude/knowledge/metrics/post-mortem-metrics.json`: appended #791 (no dup).
- `~/.claude/knowledge/metrics/dashboard.html`: regenerated (420 PRs embedded).

## RECOMMENDATIONS
1. **Keep the understand-before-scoping pass as the standard opener for any "other half / inverse / extension of prior feature F" work.** It paid for itself here by catching that the premise (#678 gap-detection exists) was false and the shipped feature was the inverse. Cheapest place to catch a wrong-direction build.
2. **Bake the gating-source-populated check into validate-first probes for gate/filter features.** When a feature filters on a second live source, the probe must confirm that source is non-empty for the real window, else a degenerate "flag everything / nothing" mode ships silent noise behind a green unit suite. (Now captured in testing-patterns.md.)
3. **Land #789's no-shifts sentinel before the coverage calendar can plausibly go empty** (e.g., a week with no logged shifts) — the deferral is justified only while the probe-confirmed "populated" state holds.
