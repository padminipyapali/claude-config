# Post-Mortem: second-brain PR #855 — AMPP OOO calendar (OOO Phase 1)

**Title:** feat(calendar): AMPP OOO calendar — reflect the owner's out-of-office in availability, slot-check, agenda, scheduling.
**Branch:** feat/ooo-calendar-phase1 → main | **Author:** padminipyapali (self-merged)
**Merged:** 2026-07-07T05:35:11Z | **Squash commit:** a64e88d (from feature commit b290aaf)
**Size:** +1635 / -26 across 18 files, 1 squash commit | **Closes #854**

---

## Feature summary

OOO Phase 1: add the **AMPP OOO** out-of-office calendar (config `GOOGLE_OOO_CALENDARS` + `OOO_OWNER_EMAIL` / `OOO_COPARENT_EMAIL`) and reflect the **owner's** out-of-town days everywhere the bot reasons about the owner's time.

- **Who's-out classifier** (`services/ooo.ts`): a single batched Claude (haiku) call reads each OOO event's title + attendees → `{ownerOut, coparentOut}`. **Title-authoritative** (a title naming one person wins over attendees); owner/co-parent identity is **config-derived**, never hardcoded — the config emails' local-parts supply the display names the prompt needs. Defensive parse: missing/malformed tool block → all-false, never throws.
- **Owner-OOO → distinct labeled hard-block** ("You're marked OOO on X (trip)") in availability / slot-check / agenda, which **OVERRIDES** the #846 transparent-all-day heads-up for the OOO calendar. Co-parent-only OOO leaves the owner unaffected. Schedule-todos excludes owner-OOO days.
- **OOO-aware dedup fix** ("Option B"): OOO trips also on the primary calendar with the same title were silently dropped by the shared `dedupeAndSort` (first-calendar-wins); dedup now prefers the OOO-tagged copy on a collision — bounded (never changes event count, byte-identical when unconfigured, opaque-Home keeps precedence).
- ~721 prod LOC / ~747 total, 18 files, 28 tests, 1 squash commit.

---

## LOCAL REVIEW (pre-push)

- **CodeRabbit (4b):** not run (skipped for this feature — see Step Compliance). `localReview.coderabbit* = null`.
- **Adversarial / critic (4c):** 1 finding, 1 fixed. Fresh-context critic, **TWO rounds**:
  - **Round 1 — FIX-THEN-SHIP, WITHHELD the marker** on a genuine should-fix: the new who's-out prompt interpolated the raw event **title** into the LLM prompt **without XML-escaping** → prompt-injection / delimiter-break (the #720 / #237 class), while the sibling calendar-prompt path already escaped. Fixed via `escapeHtml` on titles before the prompt.
  - **Round 2 — SHIP** after the escaping fix. The critic also verified the two highest-risk properties: (a) the new LLM call can't crash the availability hot path (two never-throw guard layers degrade to no-OOO; not called when the window has no OOO events — no #850/#853 crash-masking reintroduced); (b) the shared-dedup change is bounded (never changes event count, byte-identical unconfigured, opaque-Home keeps precedence).
- **Shift-left:** 100% of found defects caught locally (pre-push). 0 escaped to GitHub / post-merge.

## VALIDATE-FIRST (real calendar + real model) — caught 2 bugs the unit tests masked

- **who's-out 9/9** on the real AMPP OOO calendar (Padmini @ Hoffman → owner; Amitt @ Ambio → coparent; Burning Man → owner via attendee; Thanksgiving → both).
- **Bug A (masked by isolated batch probe):** the prompt never gave the model the owner/co-parent NAMES → a title-only event "Amitt @ Ambio" defaulted to owner-out. Invisible in the isolated batch probe; only the real e2e exposed it. Fixed by config-derived names + title-authoritative-over-attendees.
- **Bug B (feature silently inert on the common case):** `dedupeAndSort` (first-calendar-wins on summary+start+allDay) silently DROPPED the OOO-tagged copy of any trip also on the primary calendar with the same title ("Burning Man Week", "Padmini @ Hoffman"). The implementer initially "proved" e2e only on a NON-duplicated trip, sidestepping it. Fixed with Option B OOO-aware dedup; re-verified e2e on the previously-failing DUPLICATED trips ("am I free Sep 2 / Nov 10?" → "You're marked OOO"; coparent-only Dec 1 → free).

## STEP COMPLIANCE

- **Steps run:** 1 (plan), 2 (implement), 3 (test + validate-first), 4c (adversarial, 2 rounds), 5 (push+PR).
- **Steps skipped:** 4a (/simplify), 4b (in-loop CodeRabbit).
- **Compliance rate:** 1.0 (steps run completed fully).
- **Skip assessment: good** — the 2-round fresh-context critic + real-data validate-first were the gate; 0 post-merge escapes (no follow-up fix PR; #855 is the latest merged PR).

## STEP TIMING

Not tracked (no Step Timing section in the PR body). Open→merge wall-clock ~57s (created 05:34:14Z → merged 05:35:11Z) — the entire local loop ran pre-push, so the GitHub window reflects branch advance + self-merge only.

## REVIEW FRICTION (post-push)

- **Review rounds:** 0 GitHub reviews (self-merged; local review is the gate) → recorded as 1 baseline. 2 LOCAL critic rounds (see above).
- **Comments:** 0 substantive (only the Vercel preview bot). 0 inline review comments.
- **Timeline:** created → merged: ~57s (all review pre-push).
- **Self-merge:** yes — by design (local-review-is-the-gate flow), NOT an un-reviewed merge; the fresh-context critic + validate-first ran pre-push.

## ADVERSARIAL REVIEW EFFECTIVENESS

- **adversarialCatchRate = 1.0, MEASURED found-and-fixed** — the critic caught a would-be-broken-merge blocker (the missing prompt escape) pre-merge: caught/(caught+escaped) = 1/(1+0). Honest, not a fabricated default.
- **Covered by the checklist:** the prompt-injection/escape class is in the adversarial checklist (Tier 0 escape rules) and the never-throw-on-hot-path + bounded-change checks — the critic exercised them.
- **Separately:** validate-first caught 2 MORE real bugs pre-review (names-in-prompt, dedup-drop). Total 3 real defects caught pre-merge (2 validate-first + 1 critic).

## FIX-UP METRICS

- **Post-merge fix rate:** 0.0 (no follow-up fix PR; #855 is the latest merged PR).
- **Pre-merge catch rate by step:** 4c (adversarial) = 1; all others 0. (The 2 validate-first catches are in Step 3, pre-review, not counted as fixup commits — the PR shipped as 1 squash commit.)
- **Pre-merge iteration count:** 2 (two critic rounds).
- **Fix-up taxonomy:** all zero in the commit taxonomy — the fixes landed within the single squash commit, not as separate fixup commits.
- **Legacy fix-up ratio:** 0.0 (0 fix commits / 1 total).

## PLANNING QUALITY

- **Description:** complete — Behavior, Dedup fix, Safety, Validate-first, Tests + Review sections.
- **Scope:** clean atomic feature (OOO Phase 1); ~721 prod LOC / +1635 total is over the 600 guideline but a single cohesive JSDoc/prompt-heavy unit — flagged and justified in the body. PR2/PR3 correctly deferred.
- **Branch lifetime:** short (created and merged same day).
- **Planning checklist:** entry points (4 consumer surfaces + the #846 override interaction) enumerated; safety (never-throw, escaping) and the dedup interaction called out up-front.

## CODE QUALITY SIGNALS

- **Recurring issue:** prompt-escaping omission on a NEW LLM call (recurs #720 / #237) — captured as a knowledge rule.
- **New patterns captured:** validate-first-on-real-model, gates-green-but-inert, escape-on-new-LLM-call, never-throw+short-circuit-on-hot-path, tagged-copy-dedup-tie-break (5 total, see below).

## PROCESS EFFICIENCY

- **Iteration:** normal (2 critic rounds for a large feature).
- **Automation opportunity:** the missing-escape-on-a-new-prompt-site could be a Tier 0 grep (new prompt-building call that interpolates a variable without going through the escape helper) — noted; the sibling-escape pattern already existed and was simply not reused.
- **CI:** Vercel preview succeeded; no failing checks.

## KNOWLEDGE UPDATES

1. `process-patterns.md` → Test Gaps: **validate LLM-classification features against the REAL model + REAL data e2e** — isolated unit/batch tests mask prompt bugs (the names-in-prompt bug).
2. `process-patterns.md` → Test Gaps: **a gates-green feature can be silently INERT on the real common case** — validate e2e behavior on the real common input; distrust an implementer "proof" on a cherry-picked easy input (the dedup-drop bug).
3. `llm-integration.md` → Safety & Prompt Injection: **a NEW LLM call must follow the codebase's existing escape pattern** — grep the sibling prompt path and reuse its escape helper; event titles are user-controlled (recurs #720/#237).
4. `llm-integration.md` → Handler-Level Error Wrapping: **an LLM call on a critical/hot path needs BOTH a never-throw guard that degrades to the correct pre-feature answer AND a short-circuit when there's nothing to classify** — free when idle, invisible when it errors; distinct from a `catch { return [] }` outage mask because the base path is independently correct.
5. `architecture-patterns.md` → Pipeline Design: **a shared dedup keyed on other fields can silently drop a newly-tagged copy** — make the tag win the collision, bounded to tie-breaking only (same cardinality, no-op unconfigured, higher-precedence signal preserved); prove with a 4-case test.

## RECOMMENDATIONS

1. **Adopt validate-first-on-real-model as a required Step 3 sub-step for any LLM-classification feature.** Two of the three real bugs here were invisible to a green mocked-unit suite and only the real e2e exposed them.
2. **When an implementer reports an e2e success, verify WHICH input it ran on.** A success on an atypical easy input (the non-duplicated trip) is not evidence for the typical case; require the demonstration on the production-common input.
3. **Promote "new prompt site without the sibling escape helper" to a Tier 0 grep.** The escape omission is a recurrence (#720/#237/#855) — a mechanical check would catch it before the critic has to.
4. **Keep the never-throw + short-circuit pair as the standard shape for any LLM call added to a hot path** (availability, slot-check) — codified in llm-integration.md.
