# POST-MORTEM: second-brain PR #699 — fix(calendar): resolve calendar names via calendars.get for service-account reads

Branch: fix/calendar-metadata-service-account → main | Author: padminipyapali
Created → merged: 2026-06-24 03:50:47Z → 03:54:00Z (~7 min, self-merged solo dev, no peer review — expected)
Size: +238 / -22 across 4 files, 2 commits. Closes #697. Server suite 1943 pass. Vercel SUCCESS.

## HEADLINE: this is a POST-MERGE ESCAPE from #696

The agenda-display feature (#695/#696) shipped a fresh-context-critic-clean, adversarial-gated
feature that then FAILED in production on the user's very first real test. PR #699 is the fix.

**The bug.** In production every event rendered with the ⬛ unknown dot and a single "Other"
legend entry. `getCalendarMetadata` resolved calendar names/colors via `calendarList.list()` —
which is EMPTY for the production READ service account. A service account reads shared calendars
BY ID but has no calendar *subscriptions*, so its `calendarList` is empty. The metadata map was
therefore empty and every event fell to the unknown fallback.

**Why it escaped #696's gates (the real finding).** Two compounding causes:
1. **The pre-merge debug/verification script ran under OAUTH**, where `calendarList` IS populated.
   So the harness exercised a DIFFERENT auth model than production's service account, and the
   empty-list failure was invisible to the critic AND the adversarial gate. A real integration
   assumption — *which auth model production actually uses* — was never tested under that auth
   model. This is a genuine adversarialCatchRate MISS for the #696 loop.
2. **The #696 critic HAD flagged the exact risk** — "calendar absent from list → degrades to
   UNKNOWN" — but rated it graceful-degradation, not a blocker. The fallback (→ UNKNOWN/Other) is
   precisely what HID the bug: it turned a total production failure into a "looks fine, just
   unlabeled" render. Nothing crashed, nothing flagged. The fallback fired on EVERY row in
   production — it was the COMMON case, not the edge case the critic assumed.

## The #699 fix loop itself was CLEAN (1 round)

`getCalendarMetadata` now: (1) tries `calendarList.list()` first (OAuth path — name + color),
(2) for every configured id still unresolved, calls `calendars.get(id)` per-id via
`Promise.allSettled` (service-account path — name only, each individually error-handled so one
lost-permission id never drops the others), (3) falls back to stable distinct dots via
`calendar-dots.ts` when color is absent. Never-throws contract + 1h cache preserved.

Loop: implementer → fresh-context critic → adversarial gate, all PASS, 1 round. The critic THIS
time rigorously verified the load-bearing SCOPE question — that `calendars.get` actually works
under the existing `calendar.readonly` scope for a service account with no new permissions —
precisely BECAUSE the prior attempt's failure class was "looked fine but wrong in prod." The
escape reshaped the next critic's priorities toward the production-auth integration premise.

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (light-lane per the small-PR review memory; team + adversarial gate run).
- Adversarial / fresh-context critic: 0 findings on the fix (clean) — but the clean pass is
  credible here because the critic verified the production-auth SCOPE premise, the exact thing
  #696's verification skipped.
- No GitHub review comments (Vercel status only).

## STEP COMPLIANCE
Steps 1, 2a, 2b, 3, 4a–4d, 5 run. Compliance 100%. Skip assessment: good.

## REVIEW FRICTION (post-push)
Review rounds: 1. 0 inline, 0 general human comments. preMergeIterationCount = 1.
Timeline: created → merged ~3 min (0.055h).

## ADVERSARIAL REVIEW EFFECTIVENESS
- **#699 fix loop:** adversarialCatchRate = 1.0 (its own loop — 0 post-merge escapes from #699).
- **#696 RETRO-CORRECTED by this escape:** its metric entry originally recorded
  adversarialCatchRate=1.0 / postMergeFixRate=0.0. Corrected to adversarialCatchRate=0.667 (2 of
  3 real issues caught pre-merge; 1 escaped to prod) and postMergeFixRate=0.333 (1 escape / 3
  real-issue units). The escape is accounted against #696, not #699 — #699 is the clean fix.

## FIX-UP METRICS (#699)
- Post-merge fix rate: 0.0 (no follow-up fixes to #699 itself).
- Pre-merge catch by step: all 0 (the fix was correct first pass; the critic VERIFIED rather than
  corrected).
- Pre-merge iteration count: 1.
- Legacy fix-up ratio: 0.0 (commit 1 = fix, commit 2 = bug-doc; no review-fix commits).

## PLANNING QUALITY
Complete. PR body enumerates root cause, both auth models, the fix under each, and a full test
matrix (service-account empty-list + per-id get; OAuth colors; mixed; one get rejects → graceful;
cache no-refetch; blank-summary → id fallback). The lesson was captured IN the PR body and a
docs commit, not just the post-mortem.

## KNOWLEDGE UPDATES
- process-patterns.md → Adversarial Review Gaps / Critic Blind Spots: NEW entry — "Verify
  integration code under the SAME auth model / environment production uses; and when a critic
  flags 'degrades to X', ask whether X is the COMMON case, not just the edge case." Checked for
  existing coverage first (no integrations/google/calendar knowledge file exists; the adjacent
  #685 false-confidence entry covers "empty/unknown read as a positive result" but NOT the
  auth-model-harness-mismatch nor the degradation-masks-missing-data framing — so this is
  additive, not duplicative).
- metrics JSON: appended #699; retro-corrected #696's adversarialCatchRate and postMergeFixRate
  with an inline amendment note.
- dashboard.html regenerated with the updated metrics.

## RECOMMENDATIONS
1. **Add to the integration-verification checklist / critic prompt:** any verification harness for
   an auth/role/scope/tenant-bound integration MUST run under production's actual identity. A run
   under OAuth/admin/local proves nothing about a service-account/RLS/deployed path and hides
   auth-shaped failures. For this project specifically: the read path is a service account —
   `calendarList` is empty for it, so never verify calendar-list-dependent behavior under OAuth.
2. **Reframe how critics triage graceful-degradation fallbacks:** "is X a safe degradation?" is the
   wrong question; "under production data/auth conditions, does X fire on the COMMON case or a rare
   edge?" is the right one. A fallback that fires on every row in prod is a shipped bug in a
   degradation costume — and worse than a crash, because a crash would have been caught.
3. The #699 critic's behavior (verify the SCOPE premise because the prior failure was "looked fine
   but wrong in prod") is the model: after a production escape, the next loop's critic should
   explicitly re-verify the integration premise the escape exposed, under the production identity.
