# POST-MORTEM: second-brain PR #837

**Title:** feat(calendar): add decline/RSVP + harden multi-delete error handling.
**Branch:** feat/calendar-write-decline-and-delete-hardening → main | **Author:** padminipyapali (self-merged, local-review-gate model)
**Merged:** 2026-07-01T05:57:21Z (squash `da43a26`, 2 commits `45c5e58` + `735eb09`) | **Closes:** #834, #835
**Size:** +496 / −27 across 8 files (~494 prod LOC + 17 tests), 2 commits (squashed)
**Open→merge wall-clock:** ~59 seconds (0.0164h) — the entire dev loop (two-fix triage, validate-first probes, two-round adversarial gate, full server suite) ran PRE-ADVANCE; the GitHub window only reflects the branch advance + merge.

Both bugs were surfaced by LIVE bot use — continuing the session-long theme that live-bot dogfooding is the highest-yield bug finder for the calendar-write feature.

## Bug #834 — no RSVP op; decline mis-routed to delete
The bot had create / update / delete but NO way to RSVP. "decline date night 7/16" was mis-treated as a **delete** and failed — because the user is an **attendee**, not the organizer, and can't delete someone else's event.

**Fix:** a decline/accept/tentative op branched on identity. Organizer → cancel (delete your own event). Attendee → a new optional `CalendarService.respondToEvent`, which reads the event, finds the SELF attendee (Google's `attendee.self === true` flag — no stored account email needed), sets only that entry's `responseStatus`, and patches it back via `events.patch`, **preserving every other attendee's RSVP**. Throws `NotAnAttendeeError` when the user isn't an attendee. The tool `kind` enum gained decline/accept/tentative (mapped to an internal `rsvp` op), with a prompt bullet distinguishing "decline an invite" from "delete."

## Bug #835 — opaque multi-delete failure on stale ids
"delete all shelo events" failed with a generic **"Something went wrong"** that HID the real Google error, across 12 recurring-instance events whose ids were STALE (gone between the proposal and the confirm-tap).

**Fix (three parts):**
1. **Surface the real reason** — new `describeWriteError()` walks the error's `cause` chain (Gaxios wraps status at `err.response.status`, survives a `{ cause }` wrap) and reports the real status/reason (e.g. "403 forbidden") in the user reply — never blind again.
2. **Stale-id tolerance** — a per-target 404/410 "already gone" counts as *deleted* in a multi-delete BATCH (an idempotent delete's success state IS "no longer exists"), making stale ids structurally impossible to fail a batch on. Single-delete stays conservative ("no longer exists, try again").
3. **410 Gone** handled alongside 404 for the single-op path too.

The fully-correct fix (re-resolve each recurring-instance id at commit time) is heavier and tracked as follow-up **#836** (OPEN); the batch tolerance is the safe shippable interim.

## Validate-first — under the ACTUAL failing identity
The load-bearing diagnostic: the owner could delete those events by hand from their OWN account — which is the trap, because it proves nothing about the BOT's ability (a different OAuth credential with different ACLs). The decisive probe used the **bot's own token** to create+delete a throwaway on BOTH the primary AND the secondary Nannies calendar; success there RULED OUT an ACL/scope config issue and confirmed a CODE cause (stale ids) — so the fix went into code, not calendar sharing. Real-model probes confirmed the routing: "decline date night 7/16" → `rsvp/declined` on the right event, "RSVP yes to standup" → accepted, "delete the dentist" → stays a delete.

## LOCAL REVIEW (pre-push)
- **CodeRabbit (4b):** not run (~494 prod LOC calendar-write bundle, lightweight-review lane) → not tracked (null).
- **Adversarial (4c):** 1 finding, 1 fixed — a **two-round** review. **This is a MEASURED found-and-fixed `adversarialCatchRate` of 1.0, not a fabricated value and not a critic-ran-clean null.**
  - **Round 1:** the implementer's OWN test gate reported 0 failures — but it had run a FILTERED subset, not the full suite. The independent fresh-context critic ran the FULL `npm test` and found **1 real failure**: a #835 CONTRACT change (batch-404: stale-id → success) had updated the commit-level test twin but left its interceptor-level SIBLING test asserting the OLD fail-the-batch contract. Verdict: FIX-THEN-SHIP, marker **WITHHELD** — shipping round 1 would have merged a RED main. The critic also surfaced a 404-vs-410 semantic judgment.
  - **Round 2:** the stale sibling test was updated to the new contract, full suite green → **SHIP**, marker granted.
  - So the gate caught a **would-be-broken merge** (a genuine escape prevented): 1 in-scope blocker caught / 0 escaped → 1/(1+0) = **1.0**. Same found-and-fixed shade as #828 (1/1), #831 (4/4), #833 (1/1); distinct from #830's critic-ran-clean (0/0 → null).
- **Data-safety, verified independently:** `respondToEvent` preserves co-attendees' RSVPs (exact 3-attendee patched-array assertion); an attendee-decline can NEVER fall into the delete branch (organizer→cancel vs attendee→rsvp).

## STEP COMPLIANCE
- Steps run: 1, 2, 3, 4a (folded into implement), 4c, 4d, 5 → **6/8 (0.75)**
- Steps skipped: **4b (CodeRabbit)** — lightweight-review lane (~494 LOC calendar-write bundle).
- Skip assessment: **good** — 0 post-merge escapes, and the one in-scope blocker (the stale sibling test) was caught by a step that ran (4c's full-suite run) — exactly the gap the full-suite discipline exists to close.
- Reconstructed from PR-body evidence (no explicit "Steps skipped:" line).

## STEP TIMING
Not tracked (no "## Step Timing" section). Open→merge wall-clock ~59s — the full loop ran pre-advance.

## REVIEW FRICTION (post-push)
- GitHub review rounds: **1** (0 CHANGES_REQUESTED; no GitHub reviewers — self-merged). The two-round friction was entirely PRE-PUSH (the adversarial gate).
- Comments: **0** substantive (only a Vercel bot deployment comment, excluded).
- Timeline: created 05:56:22Z → merged 05:57:21Z (~59s).

## FIX-UP METRICS
- **Post-merge fix rate: 0.0** — no follow-up fix PR in the calendar area since #837. #836 (the pre-commit re-fetch) is a PLANNED deferral tracked OPEN, not a post-merge escape.
- **Pre-merge catch rate by step:** 4c (adversarial) = 1 (the stale-test escape); all others 0.
- **Pre-merge iteration count: 2** (round-1 fix-then-ship → round-2 ship) — normal for a two-fix bundle.
- **Fix-up taxonomy:** test-quality = 1 (the stale interceptor-level sibling test). Nothing else.

## PLANNING QUALITY
**Complete.** The PR body documents both bugs with root cause, the validate-first probes (including the bot-token identity probe), the data-safety reasoning, the 404-vs-410 judgment, and the explicit deferral of the pre-commit re-fetch to #836. Scope: clean — two tightly-related calendar-write fixes, no redesign, no scope creep. Bundling two issues in one PR is acceptable here (same subsystem, ~494 LOC, under the split threshold).

## CODE QUALITY SIGNALS
- **Recurring pattern:** opaque generic error replies hiding the underlying provider error — BOTH bugs this session were undiagnosable for exactly this reason. Now captured as a durable learning.
- **New patterns captured (3):** full-suite gate vs filtered-subset + test-twin sweep on a contract change; surface the real provider error don't swallow it into a catch-all; validate-first under the actual failing identity.

## PROCESS EFFICIENCY
- **The escape that mattered:** the implementer's filtered test run reported 0-failed while the full suite had 1. Automation opportunity — the merge gate should always be the full workspace suite; a path-filtered run is not a gate. The independent critic's full run was the backstop that caught it.
- Iteration: normal (2 pre-merge rounds, driven by the real catch, not friction).
- CI: Vercel preview check SUCCESS (preview-only; actual deploy target is Railway).

## KNOWLEDGE UPDATES
- `process-patterns.md` (Review Discipline) — the pre-merge gate must be the FULL suite, not a filtered subset; the independent critic's full run is the backstop for a filtered-gate miss; a CONTRACT change obligates a sibling-sweep of every test twin at both levels.
- `process-patterns.md` (validate-first family) — validate-first must run under the ACTUAL failing identity/credential (the bot's token, not the developer's own auth), or you misdiagnose a code bug as a config/ACL one. Identity/credential axis of the #772/#825 family; sibling of #696 auth-under-production.
- `testing-patterns.md` (Test Design) — the test-twin sweep on a contract change + never trust a path-filtered run as the merge gate.
- `architecture-patterns.md` (Error Handling Strategy) — 3 entries: (1) surface the real provider error, don't reply generic "Something went wrong" that hides it; (2) per-target 404/410 "already gone" = success in a multi-delete BATCH, not a batch failure (single-delete stays conservative); (3) a self-attendee RSVP is distinct from delete and must preserve co-attendees' responseStatus.

## RECOMMENDATIONS
1. **Make the full workspace test suite the enforced pre-review gate.** The one escape this PR nearly shipped came from an implementer running a filtered subset that reported 0-failed. The independent critic's full run caught it — but the cheaper fix is to never let a filtered run stand in as the gate. Consider having the adversarial-gate hook (or the implementer's own step-3 checklist) require evidence of a FULL `npm test` run, not a path-scoped one.
2. **Treat "surface the real error" as a standing calendar-write (and external-service) rule.** Both bugs this session were opaque because of a generic catch-all. The `describeWriteError` pattern (walk the cause chain, surface status+reason safely) should be the default for any user-facing reply to an operation that calls Google/an external service — now captured, apply it proactively.
3. **When a bug is "the bot can't do X but I can," probe as the bot first.** The developer's own hands-on success is a false control. The bot-token probe distinguished a code bug from a config/ACL one before a line changed — make this the first step for any "automated actor can't do X" report.
4. **Close #836 to finish the stale-id story.** The batch 404-as-success is a safe reporting-only interim; the durable fix (re-resolve recurring-instance ids at commit time) removes the stale-id class entirely.
