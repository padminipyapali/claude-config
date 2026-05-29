# POST-MORTEM: baby-name-picker PR #88 — Gate the root navigator on DB init to fix the name-detail load race

Branch: `fix/*` → `main` | Author / merged by: padminipyapali (self-merge)
Created: 2026-05-29T03:55:54Z | Merged: 2026-05-29T04:00:27Z (squash, commit `5463784`)
Duration: ~4.6 min wall-clock created→merge (single commit `57e35be` authored ~4.5 min before PR creation).
Size: +190 / -1 across 2 files, 1 commit — the source fix is one effective line in `app/_layout.tsx` (+8/-1); the remaining +182 is a new 5-assertion test (`src/__tests__/rootLayoutInitGate.test.tsx`).

## Context — the bug, and HOW it was found

The root layout (`app/_layout.tsx`) rendered the Expo Router `<Stack>` as soon as
**fonts** loaded, *before* `initialize()` finished importing the seed/user SQLite
databases. A cold-start deep link (or push, or expo-router restoring the last route)
straight to `/name/[id]` could therefore mount the detail screen before the DB was
ready → `getNameById` → `getSeedDb()` throws `"Seed database not initialized"` → a
**sticky "Failed to load name."** that never retries.

The fix is a one-line gate: render the navigator only once the DB is ready, not just
fonts —

```tsx
- if (!fontsLoaded) return null;
+ if (!fontsLoaded || isInitializing) return null;
```

The splash (`preventAutoHideAsync`) stays up until init completes, so no DB-dependent
route can mount early. `initialize()` clears `isInitializing` on **both** success and
failure, so the gate always releases (a genuine init failure degrades to the route's
existing error UI rather than deadlocking the splash). `name/[id].tsx` was intentionally
left unchanged — the layout gate closes the race globally.

## KEY INCIDENT — bug found by exploratory on-device testing, NOT by tests

This defect was **discovered during live simulator exploration while verifying an
unrelated, already-merged feature** (the name-family-tree / Across Cultures work from
#72). Manually poking the app on-device — cold deep-linking to `babynamepicker://name/12`
mid-init — surfaced the "Failed to load name" stickiness; the same link after init
completed loaded correctly. The unit suite had zero coverage of the cold-start /
DB-not-ready ordering, so no automated gate would have caught it.

Reusable lesson: **verifying one thing on-device surfaces adjacent bugs.** Exploratory
device testing has value beyond the targeted check — a real cold-start race fell out of
a verification pass aimed at a different (already-shipped) feature. This is the second
recent instance in this project where manual device poking found a defect the suite
missed; it argues for budgeting exploratory device sessions, not only scripted checks.

## KEY INCIDENT — knowingly merged with `npm test` RED (correct pre-existing-baseline handling)

`npm test` was red at merge time: **6 failures in `src/db/__tests__/seed-corrections.test.ts`
and `seed-corrections-perlanguage.test.ts`**. These were **pre-existing on `main`**,
introduced by **#87 (the name-data audit batch)** as a source/artifact drift between
`scripts/seed-data.sql` and the shipped `assets/seed.db`, and had **zero dependency** on
the two files #88 touched.

This was handled correctly, which is the point worth recording:
- The implementer **independently verified** the failures reproduce on pristine
  `origin/main` (stashed the change, re-ran — identical 6 failures), establishing the
  red baseline as not-introduced-here.
- The fresh-context **critic independently re-confirmed** the 6 failures are pre-existing
  on `main` before returning SHIP.
- The PR body **documents the failures in a table** (test → expected vs shipped drift),
  states the new `rootLayoutInitGate` suite passes **5/5**, and flags the drift so
  reviewers don't mistake the red suite for a regression.

This is the correct pattern for a **pre-existing-red baseline**: prove the red is not
yours (reproduce on clean main), keep your own added tests green, document the delta
explicitly — vs. the failure mode of either (a) falsely claiming green, or (b) blocking a
correct unrelated fix on someone else's regression. Merging green-on-delta over a
documented red baseline is acceptable; silently merging red is not.

## CROSS-REFERENCE — the #87 regression spawned follow-up PR #89

The #87 data regression surfaced during #88's review was escalated to its own follow-up:
**PR #89 "Restore 5 name etymologies regressed by audit batch 1 (#87)"** (created
2026-05-29T04:10:56Z, ~10 min after #88 merged; OPEN at post-mortem time). #89 restores
the verified data for the 5 names (Tala, Uma, Milan, Rhea, Xara) in `seed-data.sql`,
regenerates `assets/seed.db`, and reports the full suite green again (454/454). This is
correct Follow-Up Discipline — the unrelated regression became a separate single-concern
PR rather than being smuggled into the gate fix.

## ROOT CAUSE — no CI gate (the systemic enabler)

The reason #87 could merge **red and ship wrong data** in the first place is that **no
CI gate exists** on this repo — `tsc --noEmit`, `jest`, and `expo lint` are run only on
the author's local machine and are **not enforced server-side** (`statusCheckRollup`
empty across the project's history). A correct local-test run on #87 would have caught
the seed drift; without a server-side gate, a red suite shipped to `main` and then sat
red as the baseline that #88 had to merge over.

This CI-gate gap is now flagged across **#81, #83, #86, and #88** post-mortems. #86 made
`expo lint` real (installed eslint) but still only runs locally. The standing
recommendation is escalated: **wire tsc + jest + expo lint into CI** so a red suite
blocks merge automatically. The cost of the missing gate is no longer hypothetical — it
directly caused the shipped-wrong-data incident (#87) and the red baseline #88 had to
work around.

## LOCAL REVIEW (pre-push)

- CodeRabbit (4b): NOT tracked (no CodeRabbit line in `## Local Review`). Recorded null.
- Adversarial review (4c): **Tier 0 clean** — gate-only change; no new Date / interactive
  / color / fire-and-forget patterns. 0 findings.
- Fresh-context critic: **SHIP** — verified the gate closes the race (`<Stack>` is the
  only gated render; no DB-dependent sibling renders before it), no splash deadlock
  (`initialize()` clears `isInitializing` on success *and* in the catch before re-throw),
  onboarding redirect intact with no new flash, and the test is faithful +
  regression-catching. Independently confirmed the 6 seed-corrections failures are
  pre-existing on `main`.
- Shift-left: n/a — no fixed-in-PR findings surfaced at any review gate (critic returned
  SHIP with nothing to catch; the defect itself was caught pre-PR by device exploration).

## STEP COMPLIANCE

Not explicitly tracked (no `Steps skipped:` line in the PR body → `stepCompliance`
recorded null, per rule). Inferred from body: Plan (1), Implement (2a), Test —
tsc PASS / lint PASS / jest documented-red-baseline (3), Adversarial (4c), fresh-context
critic, Push/PR (5) all ran; CodeRabbit (4b) and CI (4d — repo has none) did not. The
missing `Steps skipped:` line is the same minor drift noted in #83/#86.

## STEP TIMING

Not tracked (no `## Step Timing` section). Wall-clock created→merge ~4.6 min — a fast
self-merge of a one-line fix + its regression test.

## REVIEW FRICTION (post-push)

Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general, 0 GitHub reviews
(solo flow; the fresh-context critic is the in-process reviewer). Self-merge by author.

## ADVERSARIAL REVIEW EFFECTIVENESS

Pre-push catch potential: n/a — no issue escaped to post-merge from this PR. The defect
#88 fixes was caught **pre-PR by exploratory device testing**, not by the adversarial
checklist or the critic. The critic's material contribution here was *verification*
(confirming the gate closes the race, the splash can't deadlock, and the red baseline is
not-ours), not catching a new finding.
Covered but missed: none. Not covered (new categories): the cold-start / DB-not-ready
route-ordering race is a class no Tier check targets — captured below as a knowledge add.
**adversarialCatchRate = unmeasured** — no post-push reviews exist and there was no
fixed-in-PR adversarial finding to measure a catch rate against (critic SHIP, nothing to
catch). Not fabricated.

## FIX-UP METRICS

- Post-merge fix rate: 0.0 — no follow-up PR fixes #88 itself. (#89 fixes #87's data, not
  #88's gate.)
- Pre-merge catch rate by step: all 0 — single squash commit, no fix commits.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all 0 (single fix commit; no separable fix-up commits).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## PLANNING QUALITY

Description: **complete** — Summary, root-cause trace, the fix (with diff), explicit
splash-deadlock + redirect analysis, a thorough Test plan including the documented red
baseline, and Local Review. Scope: clean — single-concern one-line gate + its test; the
discovered #87 regression was correctly spun off to #89 rather than mixed in. Branch
lifetime: ~4.6 min.

## PROCESS EFFICIENCY

Iteration: efficient (1 round). CI status: none configured (recurring; the systemic
enabler of the #87 incident — see Root Cause). Automation opportunities: (1) **wire CI**
(tsc + jest + expo lint) so red suites block merge — now demonstrably load-bearing, not
theoretical; (2) add a cold-start / deep-link integration test class so the
DB-not-ready route race is covered by automation, not only by manual device poking;
(3) the standing 4b-skip pre-push hook; (4) restore the `Steps skipped:` PR-body line.

## KNOWLEDGE UPDATES

- `process-patterns.md` — Testing/QA: NEW lesson — **exploratory on-device testing
  surfaces adjacent bugs.** Verifying one feature on-device (#72 family section) found an
  unrelated cold-start DB-init race (#88) the unit suite never covered; budget
  exploratory device sessions, not only scripted verification.
- `process-patterns.md` — Process Compliance: NEW lesson — **pre-existing-red baseline
  handling.** When `npm test` is red from a *prior* merge, the correct move is: reproduce
  on pristine `origin/main` to prove the red is not yours, keep your own added tests
  green, and document the delta in the PR body (table of failing tests). Merging
  green-on-delta over a documented red baseline is acceptable; falsely claiming green, or
  blocking a correct unrelated fix on someone else's regression, is not.
- `process-patterns.md` — CI Gate: ESCALATED — the missing server-side CI gate is now
  flagged across #81/#83/#86/#88 and is the **direct enabler** of the #87 shipped-wrong-
  data incident and the red baseline #88 merged over. Recommendation raised from
  "recurring observation" to "ship a CI gate next."
- `react-patterns.md` (RN section) — NEW: **gate the root navigator on async
  initialization, not just fonts.** A render gated only on `fontsLoaded` lets the router
  mount (and deep-link-restore) DB-dependent routes before async DB init finishes; gate
  on `fontsLoaded && !isInitializing` and keep the splash up until init resolves. Ensure
  the init flag clears on both success and failure so the gate can't deadlock the splash.

## RECOMMENDATIONS (ranked)

1. **Ship a CI gate (tsc + jest + expo lint) now.** #88's red-baseline workaround and the
   #87 shipped-wrong-data incident are both downstream of having no server-side gate.
   This is the highest-leverage item and is now flagged across four post-mortems
   (#81/#83/#86/#88).
2. **Merge #89** (restore the 5 regressed etymologies) to return `main` to green and
   clear the documented red baseline.
3. **Add cold-start / deep-link integration coverage** so the DB-not-ready route race is
   automated, not dependent on manual device exploration to catch the next regression.
4. Build the 4b-skip pre-push hook and restore the `Steps skipped:` PR-body line (carried
   over from #83/#86).
