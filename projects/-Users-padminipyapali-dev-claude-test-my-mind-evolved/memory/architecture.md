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
