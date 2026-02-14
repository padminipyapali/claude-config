# Architecture Learnings

## Dual identity layers: always pass both IDs
When a system resolves external IDs (Telegram chat ID) to internal IDs (DB UUID) at the boundary, outbound flows (notifications, follow-ups) still need the external ID. The TODO splitter hit this: `notifyUser` received the DB UUID and Telegram returned `400: chat not found`.

**Pattern:** Pass both IDs through the pipeline when a background process needs to call back to the channel. Either:
1. Pass both `userId` (DB) and `channelUserId` (external) as separate params.
2. Add a reverse lookup `getUserChannelId(userId, channel)` to EntryService.

Option 1 is simpler and avoids a DB round-trip. Use option 2 only if the outbound call happens far from where the channel ID is available.

## Fire-and-forget needs visibility
The fire-and-forget pattern (`.catch(err => console.error(...))`) is great for non-blocking operations but makes debugging hard. When a fire-and-forget operation does nothing (e.g. split returns 1 item), there's no way to tell if it ran, failed silently, or was never called.

**Rule:** Add a log line at the decision point, not just in the error path. E.g. `console.log("[split] returned N items")` so you can see whether the operation ran at all.

## Test with real services, not just mocks
Unit tests with mocked LLM responses will never catch issues like markdown code fences in JSON output. After getting unit tests green, always do a live smoke test with real API calls before considering a feature done. The TODO splitter passed all 70 unit tests but failed immediately in production.

## Async initialization ordering matters
When the app starts multiple services (`telegram.start()`, `reminderScheduler.start()`, etc.), the order and awaiting behavior matters. If service B can immediately fire work that depends on service A (e.g., scheduler fires a notification via Telegram), service A must be fully ready before service B starts.

**Anti-pattern:**
```typescript
telegram.start();       // not awaited
reminderScheduler.start(); // may fire before telegram is ready
```

**Correct:**
```typescript
await telegram.start();
reminderScheduler.start(); // now safe — telegram is connected
// OR:
telegram.start().then(() => reminderScheduler.start());
```

**Rule:** Draw the dependency graph of startup calls. Any service that produces work depending on another service must start after that dependency is confirmed ready.

## Timezone computation: avoid server-local parsing
`new Date(date.toLocaleString("en-US", { timeZone: tz }))` looks correct but the `new Date()` constructor parses the string using the server's local timezone, not the target timezone. It only works when the server is in UTC.

**Correct approach:** Use `Intl.DateTimeFormat("en-US", { timeZone: tz }).formatToParts(date)` to extract year/month/day/hour/minute components, then construct the date from those parts. This is deterministic regardless of server timezone.

### Variant: Date constructor without Z suffix (PR #59)
`new Date("2026-02-14T00:00:00")` (no Z) is also server-timezone-dependent — the JS engine parses it as local time. Adding `Z` forces UTC: `new Date("2026-02-14T00:00:00Z")`. This bit us in calendar.ts (day boundaries) and test helpers (flaky on CI).

### Corollary: resolve timezone once
When a handler needs both a timezone string and a "today" date string, derive the date FROM the timezone. Don't use two independent sources (e.g., `getLocalToday()` with its own default vs. `this.deps.userTimezone`). They can silently diverge, producing "today" in one timezone and event queries in another.

## Exclusive upper bounds for time ranges
When querying events/records for a date range, use start-of-next-day as the exclusive upper bound:
```
timeMin = "2026-02-14T00:00:00Z"   // inclusive
timeMax = "2026-02-15T00:00:00Z"   // exclusive
```
NOT `T23:59:59Z`, which misses the last second. This applies to Google Calendar API, SQL `BETWEEN`, and any time-bounded query.

## External API data defensiveness
External APIs (Google Calendar, etc.) can return malformed entries — missing required fields, null nested objects, unexpected types. Never trust the shape.
- Use `.filter()` before `.map()` to exclude entries missing required fields.
- Prefer optional chaining (`event.start?.dateTime`) over non-null assertions (`event.start!.dateTime`).
- Wrap `JSON.parse()` on external config/env vars in try/catch with descriptive errors.

## In-memory state doesn't survive restarts (BUG-T015)
Schedulers using in-memory dedup markers (e.g., `lastSentDate: string | null`) will re-trigger on every server restart. On deploy-on-push platforms (Railway, Vercel, Heroku), every deploy is a restart — multiple deploys in a session can cause spam.

**Options (increasing robustness):**
1. **Defensive initialization** (simple, no schema change): In the constructor, check if the scheduled time has already passed. If so, pre-set the marker. Trade-off: cold starts after the scheduled time skip that day's notification.
2. **DB-persisted marker** (robust): Store `(scheduler_name, last_run_date)` in a `scheduler_state` table. Survives restarts and distinguishes "first run today" from "restart after already sent."

We used option 1 for `MorningBriefScheduler` and `DailyReviewScheduler`. If we add more schedulers or need guaranteed first-run delivery, upgrade to option 2.
