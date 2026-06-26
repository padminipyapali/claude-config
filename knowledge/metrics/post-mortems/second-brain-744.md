# POST-MORTEM: second-brain PR #744 — fix(calendar): route cancel/update to the event's own calendar (thread sourceCalendarId).

Branch: `fix/cancel-source-calendar` → `main` | Author: padminipyapali | Squash-merged as `fc04e56` | ~2 min PR-open-to-merge (pre-prepared branch, solo)
Size: +286 / -27 across 7 files, 1 squashed commit | Closes #741

## Bug
"Could you cancel shelo's shift on 7/3?" → "That event no longer exists — it may have been already changed or deleted," twice, while the event still existed. Shelo's shift is a recurring daily nanny-coverage event on a **dedicated** calendar (not primary).

## Root cause
`WritableGoogleCalendarService.deleteEvent` targeted a hardcoded `this.writeCalendarId` (the default write calendar). The event lives on the nanny calendar, so Google returned 404 → mapped to `status: "stale"` → `EVENT_GONE_REPLY`. The event's `sourceCalendarId` was known at resolution time but dropped before reaching the delete. A 404 from querying the WRONG calendar is indistinguishable, at the call site, from "the event was actually deleted."

## Fix
Thread the resolved event's `sourceCalendarId` end-to-end so delete/update operate on the calendar the event actually lives on:
- `parseCalendarWriteToolUse` (response.ts) captures the matched grounding event's `sourceCalendarId` (keyed by the picked `googleEventId`) onto the delete/update intent (defensive: non-empty string only).
- Persists in `CALENDAR_WRITE_PENDING` metadata (no whitelist), read back by `parseStoredOp` (drops non-strings).
- `commitOp` passes it to `deleteEvent(id, calendarId?)` / `updateEvent({calendarId})`, which use `calendarId ?? writeCalendarId` — exact back-compat when absent.
- Recurring single-instance deletion confirmed already correct: candidate fetch uses `singleEvents: true`, so recurrences expand to dated instance ids (`<master>_<instanceStart>`) that thread untouched. Cancelling 7/3 deletes only that day's instance.

## Process (3-role team)
Full orchestrator → implementer → fresh-context critic → adversarial gate. CI: Vercel SUCCESS; @second-brain/server 2237 pass, 48 skipped.

## STEP COMPLIANCE
Not tracked in PR body (no `Steps skipped:` line). Recorded `null`. Narrative confirms steps 1–5 ran (plan, implement, test, local review incl. critic + adversarial gate, push/PR).

## STEP TIMING
Not tracked (no `## Step Timing` section). Recorded `null`.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; self-merged, no GitHub peer review — expected for solo orchestrator/critic workflow).
- Comments: 0 inline, 0 substantive general (only Vercel bot).
- Timeline: created → merged ≈ 2 min (branch fully prepared + reviewed locally before PR open).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Fresh-context critic executed the full thread chain (response.ts → metadata → parseStoredOp → commitOp → client). Found **0 blockers, 0 SHOULD-FIX, 2 NITs**:
  1. No direct multi-event-different-calendar capture test (each event mapped to its own calendar in one batch).
  2. Pre-existing dedup-by-(summary, start, allDay) — out of scope for this fix.
- adversarialCatchRate: **unmeasured-clean / null.** 0 actionable findings → catch rate is undefined (0/0), not 0% and not 100%. Recording 1.0 would falsely imply it caught a population of defects; recording 0.0 would falsely imply misses. The critic ran fully and the NITs were correctly judged non-blocking. **0 post-merge escapes** corroborates the clean review.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (PR #743 merged 2s later is unrelated todo-scheduling, not a follow-up fix).
- Pre-merge catch rate by step: all 0 (single squashed commit; no fix commits — issues were fixed in-place during the single implement pass before squash).
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all 0 (no separate fix commits in history).
- Legacy fix-up ratio: 0.0 (0 fix / 1 commit).

## PLANNING QUALITY
- Description: **complete** — Bug, Root cause, Fix (with end-to-end thread map), explicit recurring-instance reasoning, a residual-risk Note, Validation, Designs (N/A). Closes #741 present (issue-first rule satisfied).
- Scope: clean. 313 LOC total change, single concern (calendar targeting), well under the 600-LOC cap.
- Branch lifetime: short; no revert/redesign commits.

## RESIDUAL RISK (carried in PR body)
Delete uses the OAuth user's write credential. If that account has only READ access to the nanny calendar, Google still returns 403/404 → same `EVENT_GONE_REPLY` (a permission error mislabeled as "event deleted"). Routing to the right calendar is necessary but not sufficient. **Follow-up candidate:** distinguish 403 (permission) from 404 (truly gone) and surface a permission-specific message. Note: the Gaxios-status-walk pattern needed to classify this already exists (architecture-patterns.md, from calendar-write PR3) — the missing piece is mapping 403 to a distinct user reply.

## CODE QUALITY SIGNALS
- Recurring issues: none.
- New unrecorded pattern: yes — "write/delete on multi-calendar setups must target the event's own `sourceCalendarId`, not a default write calendar, and a 404 from the wrong calendar masquerades as 'already deleted'." The existing #694 entry covers plumbing `sourceCalendarId` past the dedupe boundary for READ/display; it does NOT cover the WRITE-target + misleading-404 failure mode. Captured separately.

## KNOWLEDGE UPDATES
- Added to `architecture-patterns.md` (Error/provider-status area): the multi-calendar write-target + masquerading-404 learning.

## RECOMMENDATIONS
1. **Add the missing capture test** the critic flagged (NIT 1): one batch with two events on two different calendars, asserting each delete/update threads its own `sourceCalendarId`. Cheap regression guard against a future re-introduction of a single shared calendarId.
2. **403 vs 404 follow-up** (residual risk): map permission errors to a distinct reply so a read-only-calendar event doesn't read as "deleted." Reuse the existing Gaxios `response.status` walk.
3. **Adopt `Steps skipped:` and `## Step Timing` lines in PR bodies** so step-compliance and timing stop landing as `null` for this project's post-mortems.
