# Post-Mortem: second-brain PR #850 — surface an actionable message when the Google OAuth token is expired

**Date:** 2026-07-04
**PR:** [#850](https://github.com/padminipyapali/second-brain/pull/850) — Closes [#849](https://github.com/padminipyapali/second-brain/issues/849).
**Branch:** `feat/…oauth-token-expired` → main (squash-merged, 1 commit `1d0b3e7`; feature commit `eb6cabb4`)
**Time to Merge:** ~8 min GitHub wall-clock (created 2026-07-05T05:14:47Z, merged 05:23:08Z). The full dev loop (diagnose → reproduce-under-real-identity → implement → test → fresh-context adversarial review) ran PRE-PUSH; the GitHub window is push-to-merge only.
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +481 −12 across 12 files, 1 commit. Core: `services/calendar.ts` (+77, `isAuthExpiry`), `processor/utils/calendar-query.ts` (+21, `CALENDAR_AUTH_EXPIRED_REPLY` + `fetchCalendarWindow` branch), `intent-handlers/calendar-handler.ts` (+8, weekly view), `schedule-todos-handler.ts` (+22) & `schedule-todos-refine.ts` (+7), `services/coverage-scheduler.ts` (+15, background job). 18 new tests across `calendar.test.ts` (+84), `coverage-scheduler.test.ts` (+42), and the four handler test files.

## 1. What Shipped

A narrow auth-expiry detector plus an actionable reply, swept across every calendar-fetch surface, so a dead Google OAuth token stops presenting as a generic transient blip.

- **`isAuthExpiry(err)` (`calendar.ts`).** Walks the thrown error's cause chain — including the ARRAY cause `getEventsForRange` produces (`{ calendarId, reason }[]`) and each reason's nested GaxiosError — bounded to 6 levels (`AUTH_EXPIRY_MAX_DEPTH`), cycle-safe. Matches ONLY the real signature: the structured `response.data.error === "invalid_grant"` field (checked FIRST, the authoritative signal) or the message text `invalid_grant` / "expired or revoked". Deliberately does NOT match a bare 400 / `invalid_request` / 500, so a transient can never masquerade as auth-expiry (verified by negative tests for 500, plain 400, `invalid_request`, null/string, and a 20-deep clean chain).
- **`CALENDAR_AUTH_EXPIRED_REPLY` + exhaustive sibling sweep.** "⚠️ I can't reach your calendar right now — the Google connection has expired and needs to be reauthorized. Calendar features are paused until it's reconnected." Branched into EVERY calendar-fetch catch: the shared `fetchCalendarWindow` (Q&A / agenda / availability / slot + the CALENDAR_WRITE grounding fetch), the weekly CALENDAR view, the SCHEDULE_TODOS handler AND its refine loop (non-auth errors keep their prior behavior — re-throw / generic refine-failed reply), and the nightly coverage-scheduler, which has no user to reply to and instead logs a distinct greppable `[coverage] Google auth expired — calendar sync paused, reauthorize needed`. Non-auth paths are byte-identical.

## 2. Development Loop

Pipeline: **DIAGNOSE** (the live bot returned "Something went wrong fetching your calendar" for "what do I have next Monday") → **REPRODUCE UNDER TWO IDENTITIES** (MCP under the developer's own Google access = calendar fine; a probe under the BOT'S OWN `.env` token = `invalid_grant` "Token has been expired or revoked" — confirming a token/auth failure, not a code bug and not a #846 regression) → single-pass implement on a feature branch → gates (build + biome lint + full server suite green, 18 new tests) → **fresh-context adversarial review → SHIP** + marker written → self-merge. No GitHub reviews or inline comments (solo workflow; all review pre-push). **CodeRabbit was NOT run.**

The load-bearing diagnostic move: the generic reply had MASKED the real cause, so the failure was invisible from the bot's output and had to be reproduced with a probe. Crucially, the FIRST reproduction (the developer's own Google/Calendar access via a separate claude.ai session) worked fine — which is the identity trap: "my calendar loads" feels like proof the integration is healthy, but the bot authenticates with a DIFFERENT OAuth refresh token. Only the probe run under the bot's actual token separated a code bug from a dead credential.

## 3. Adversarial / Review Effectiveness — adversarialCatchRate = null (CRITIC-RAN-CLEAN)

**adversarialCatchRate is `null` — the critic-ran-clean shade (same as #830/#841), NOT a fabricated/hardcoded value and NOT the MEASURED found-and-fixed 1.0 of #846/#837.** The distinction: a review activity ran and found NO in-scope would-be-wrong behavior to fix within this PR, and 0 escaped.

- **The critic verified, and cleared, the two risks specific to this diff:** (a) `isAuthExpiry` has no false-positive — it checks the structured `response.data.error === "invalid_grant"` field first and matches only the `invalid_grant` / "expired or revoked" signature, never a bare 400/`invalid_request`/500, so a transient failure cannot be mislabeled auth-expiry (a false-positive here would wrongly tell the user their calendar is disconnected during an ordinary blip); (b) the sibling sweep is EXHAUSTIVE — the `isAuthExpiry → CALENDAR_AUTH_EXPIRED_REPLY` branch reaches all five calendar-fetch surfaces plus the background coverage-scheduler job. → SHIP, marker written.
- **No defect was caught-and-fixed by a review activity** (unlike #846's validate-first probe catching the transparency over-block, or #837's critic catching the RED-main stale test twin), and **no defect escaped** (0 post-merge fixes). That combination is exactly the critic-ran-clean `null`, not `1.0`.
- **Minor future nicety, correctly NOT counted as a miss:** the Today-Card and morning-brief already OMIT the calendar section on failure, so they degrade gracefully without showing a wrong message — noted, not a gap.

## 4. Process Learnings (captured to knowledge base)

Four learnings, all recurring-theme reinforcements at a new axis:

1. **Don't MASK the real failure behind a generic reply — detect the specific failure CLASS and name the remedy.** The generic "Something went wrong fetching your calendar" cost a debugging session, exactly as #837 (calendar-write) and BUG-035/036 (auth-model failures) did. The fix generalizes #837's `describeWriteError` (surface the provider status) one class further: when a failure implies a distinct USER remedy — especially a terminal one no retry fixes (expired/revoked credential) — detect that class narrowly (match the authoritative structured field, never a broad status) and return a message naming the remedy ("reconnect your calendar"), turning a silent recurring outage self-diagnosing. → `architecture-patterns.md` → Error Handling Strategy (recurs at the auth-expiry axis).
2. **To distinguish a token/auth failure from a code bug, reproduce under the ACTUAL failing identity — the developer's own access proves nothing.** The bot's OAuth refresh token was dead while the developer's separate Google access was live; only the probe under the bot's own token confirmed `invalid_grant`. Sharpens the #837/#846 identity axis: the "I can do X but the actor can't" trap has two shapes — an ACL/scope gap (#837) AND a credential-liveness gap (#850) — and both are invisible to a probe run under the developer's identity. → `process-patterns.md` → Planning Discipline (validate-first family, credential-expiry variant).
3. **Sibling-sweep a new error-CLASSIFICATION branch across EVERY catch site of the operation, not just the reported surface.** The auth-expiry branch had to reach all five calendar-fetch surfaces plus the nightly background job (which has no reply path and logs a greppable line instead) — the reported symptom was only one surface (Q&A). Background/scheduled jobs are the easiest sweep target to forget because they don't match a "user message" grep. → `process-patterns.md` → Review Discipline (error-handling-branch axis of the sibling-sweep family, alongside #846 semantic-concept and #837 contract-twin).
4. **REFERENCE/OPERATIONAL: a Google OAuth app in "Testing" publishing status force-expires refresh tokens every 7 days.** The OPERATIONAL root cause (not code): the consent screen is in Testing mode → a total calendar outage recurring weekly. Immediate remedy = re-authorize (`google:oauth-setup` script → Railway env → redeploy); durable fix = publish the consent screen to "In production." Recorded so it's not re-diagnosed from scratch. → `architecture-patterns.md` → Deployment & Vendor Config, and project `docs/BUGS.md` BUG-037.

## 5. Planning Quality

**Complete.** PR body has a Problem section naming the real incident and that it cost real debugging (the token was dead, not a code bug), a Fix section describing `isAuthExpiry`'s narrowness (structured field checked first, explicitly NOT a bare 400/500) and the sibling sweep across every surface (naming what stays unchanged — non-auth paths byte-identical), Tests (18, itemized by positive/negative + the full-suite green count), a Review section (SHIP + the false-positive-cleared + exhaustive-sweep verification, and the Today-Card/morning-brief graceful-degrade as a noted non-miss), and Closes #849. No explicit Performance & Cost section — acceptable: `isAuthExpiry` is a bounded (≤6-hop) in-memory cause-chain walk that runs ONLY on the already-failed catch path, adding no external round-trips, no DB load, and no cost to the success path. Scope is clean: one squash commit, no revert/redesign churn, all changes in the calendar/processor/services layers.

## 6. Metrics Summary

| Field | Value |
|-------|-------|
| Review rounds | 1 |
| Total comments (non-bot) | 0 |
| localReview.coderabbit | null (CodeRabbit NOT run) |
| localReview.adversarial | 0 found / 0 fixed (critic ran clean; verified no false-positive + exhaustive sweep) |
| adversarialCatchRate | **null** (CRITIC-RAN-CLEAN — no in-scope blocker found, 0 escaped; NOT a fabricated 1.0, NOT the #846 measured found-and-fixed shade) |
| postMergeFixRate | 0.0 (0 escapes; most recent merged PR, no later PR touches its files) |
| preMergeIterationCount | 1 (single implementation pass) |
| Fix-up taxonomy | all zero (0 discrete fix commits) |
| Step compliance | steps 1 + 2 + 3 + 4c + 5 ran; 4b (CodeRabbit) NOT run → skip assessment: neutral (full adversarial gate + real-identity reproduction + 18 tests + green suite; no post-merge signal CodeRabbit would have caught anything) |
| Planning quality | complete |
| PR size | 493 (481 add / 12 del) |
| Time to merge | ~8 min GitHub wall-clock (full loop ran pre-push) |

## 7. Recommendations

1. **Publish the OAuth consent screen to "In production" (durable fix, in progress).** The code change makes the weekly outage self-diagnosing, but the OUTAGE itself only stops when the app leaves Google "Testing" mode. Until then, the bot will keep losing calendar access every 7 days and the actionable reply will keep firing. This is the actual close of the incident; the code fix is the diagnosability net.
2. **When a whole external integration dies at once (every call `invalid_grant`, not a per-call 403/404), suspect the shared credential FIRST and probe under the SERVICE'S own identity before touching code.** #850 was diagnosed correctly, but the first (developer-identity) reproduction was a false control that could have mis-sent the fix into logic. Make "reproduce under the actor's credential" the first diagnostic step for any integration-wide outage. (Now reinforced in `process-patterns.md`.)
3. **Add auth-expiry / terminal-failure-class detection as a standing pattern for any external-service catch.** The `isAuthExpiry → actionable reply` shape generalizes to rate-limit, quota-exhausted, and disabled-account classes on any provider (Google/Stripe/Twilio/LLM). When a caught error implies a distinct user remedy, detect it narrowly and name the remedy — don't dump a status or a generic string. (Now in `architecture-patterns.md` → Error Handling Strategy.)
4. **Record the review lane explicitly in the PR body.** A one-line `Steps skipped: 4b (CodeRabbit) — reason: <full adversarial gate + real-identity reproduction + 18 tests + green suite>` would make the metric pipeline self-describing instead of reconstructed from evidence (recurring recommendation across recent PRs).
5. **The null here is honest and correct** — the critic ran and cleared the two real risks (false-positive, sweep completeness) with no blocker to fix and nothing escaping. Do not collapse it into the #846/#837 measured 1.0 (a review activity catching-and-fixing a genuine would-be-wrong behavior); those are distinct shades.
