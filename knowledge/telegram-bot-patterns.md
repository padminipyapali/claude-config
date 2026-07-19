# Telegram Bot Patterns

Cross-project learnings for Telegram bots (grammY, Bot API).

## Identity Mapping

- **Dual identity layers: always pass both IDs.** When resolving external IDs (Telegram chat ID) to internal IDs (DB UUID) at the boundary, outbound flows (notifications, follow-ups) still need the external ID. Pass both `userId` (DB) and `channelUserId` (external) through the pipeline.
- **Reverse lookup as fallback.** If outbound calls happen far from where the channel ID is available, add `getUserChannelId(userId, channel)` — but passing both IDs is simpler when possible.

## Bot Architecture

- **Thin command dispatchers to services.** Bot command handlers should extract params and delegate to service methods. No business logic in handlers.
- **Env-driven project paths.** Configure project directories via environment variables, not hardcoded paths.

## Webhook & Polling

- **Webhook latency: decouple processing from response.** Respond 200 to the webhook immediately, then process the message asynchronously. Long processing blocks subsequent updates.
- **Keepalive self-ping prevents cold starts.** On PaaS platforms, periodic self-pings keep the service warm.
- **`bot.start()` is fire-and-forget — add `.catch()`.** grammY's `bot.start()` returns a Promise but is typically called without `await` (polling runs indefinitely). While polling loop errors route to `bot.catch()`, an immediate rejection from `bot.start()` itself (e.g., network failure before polling begins) would be unhandled. Always append `.catch()`. <!-- Source: PR review, command-center #40, 2026-02-27 -->
- **Single-consumer constraint on `getUpdates`: only one process per bot token can poll.** When two services (e.g., a "second-brain" bot and a separate notification sender) need to use the same Telegram bot, only one may call `getUpdates` — the other must be send-only (`sendMessage` / `editMessageText` only). Document the ownership boundary explicitly in the send-only service ("Path A — send-only via shared bot token; second-brain owns getUpdates"). Otherwise updates are silently distributed across both pollers and message handlers see only ~half their traffic. Generalizable to any bot ecosystem with single-consumer update streams. <!-- Source: post-mortem, family-digest #12, 2026-04-22 -->

## HTML-Mode Safety

- **Escape user content in ALL HTML-mode messages.** When using `parse_mode: "HTML"`, always escape `<`, `>`, `&` in user-provided strings — in bot replies, notifications, scheduler messages, and any other outbound channel. This applies to any field derived from user input (topic, title, displayName, task content). This is the Telegram equivalent of XSS — Telegram will reject malformed HTML or render it incorrectly. Easy to miss in notification methods that don't feel like "replies." <!-- Source: PR review, command-center #3, 2026-02-14; PR review, second-brain #208, 2026-02-22 -->
- **Escape quotes in HTML attributes too.** When `escHtml` output is placed inside a quoted HTML attribute (e.g., `"${escHtml(topic)}"`), `"` must be escaped to `&quot;` — otherwise a quote in the topic text breaks the attribute boundary. Always include `.replace(/"/g, "&quot;")` in the `escHtml` chain. This is easy to miss because `&`, `<`, `>` feel sufficient until someone enters a topic with quotes. <!-- Source: PR review, second-brain #211, 2026-02-23 -->
- **Truncate raw text BEFORE escaping, not after.** `slice()` after `escapeHtml()` can break entities mid-sequence (e.g., `&amp;` becomes `&am`). Always: (1) truncate raw string, (2) escape, (3) verify total length fits. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- **Truncate HTML messages at line boundaries, not character offsets.** When enforcing Telegram's 4096-char limit on HTML-formatted messages, `slice(0, N)` can split between `<a>` and `</a>`, leaving unclosed tags that cause `Bad Request: can't parse entities`. Truncate at `lastIndexOf("\n")` first (each line should contain balanced tags), then fall back to stripping partial tags (`/<[^>]*$/`) and entities (`/&[a-z]*$/i`). <!-- Source: PR review, second-brain #155, 2026-02-17 -->

## Command Matching

- **Account for `@botname` suffix in group chats.** Telegram appends `@botname` to slash commands in group chats (e.g., `/todos@my_bot`). Don't use bare `startsWith("/cmd")` (matches `/cmdxyz`) or strict `=== "/cmd"` (misses group suffix). Use explicit three-way matching: `text === "/cmd" || text.startsWith("/cmd ") || text.startsWith("/cmd@")`. For argument extraction, normalize with a `stripBotMention(text, command)` utility: `/command@botname args` → `/command args`. <!-- Source: BUG-024, second-brain, 2026-02-15 -->

## Command Parameter Parsing

- **Reject lone optional parameter as the required argument.** When a command accepts `[optional_project] <required_description>` (e.g., `/session [project] <description>`), and the user provides a single word that matches the optional parameter but no required text follows, show a usage message — don't silently treat the project name as the description. Pattern: after resolving `maybeSlug`, check `if (maybeSlug && parts.length === 1)` → reply with usage hint. <!-- Source: PR review, command-center #34, 2026-02-21 -->

## Message Handling

- **Entry-less responses break reply-to chains.** Response types that don't create DB entries (TODO_LIST, CHAT) have no entry to link replies to. Solution: use a lightweight `bot_responses` table to track outbound messages.
- **Store matched IDs in metadata, reuse directly.** When a search matches entries, store the IDs — don't re-search and risk discarding them.
- **Reply context takes precedence over content-based search.** When a user replies to a specific message, they are referring to that message's subject — not whatever a keyword search might return. Use the parent entry directly (e.g., `findByIds([parentEntry.id])`) instead of searching all items by keyword. Fall back to search only when no parent context exists.

## Inline Keyboard Lifecycle

- **Clear inline keyboards after terminal actions.** When `editMessageText` is called without `reply_markup`, Telegram preserves the original inline keyboard buttons. After any terminal action (confirm, cancel, error), always pass `reply_markup: { inline_keyboard: [] }` to remove the buttons and prevent users from re-triggering callbacks. Only omit this when re-rendering the keyboard with updated state (e.g., refreshing a TODO list with new button states). <!-- Source: PR review, second-brain #209, 2026-02-22 -->
- **Don't remove buttons BEFORE async operations — keep them until success.** When a button triggers an async operation (LLM call, API request), don't eagerly remove the inline keyboard before the operation completes. If the operation fails, the user has no retry path — the button is gone. Pattern: show a toast ("Processing...") immediately, but only remove/replace the keyboard inside the success branch. For double-tap prevention, use a server-side idempotency guard or debounce, not premature UI removal. <!-- Source: PR review, second-brain #305, 2026-03-01 -->

## Multi-Turn Conversation State via bot_response

- **Persist a typed bot_response as conversation state, resume via a reply interceptor.** To make a bot exchange multi-turn (e.g. a clarifying question that the user answers), persist a typed `bot_response` row carrying the context needed to resume (the original query) and link it to the sent channel message ID. When the user replies, a `ReplyInterceptor` keyed on that `responseType` resolves the parent, reads the metadata, and resumes — instead of treating the reply as a brand-new message. The interceptor MUST return `null` for every other parent type so sibling interceptors / classification still win. Round-trip wiring: handler returns `botResponseId` → channel adapter callback → `updateBotResponseChannelId` (stores channel message id) → later `findBotResponse(userId, channel, replyTo)` resolves it. A failed persist must be non-fatal (still send the question; the reply just won't resume). <!-- Source: second-brain #656, 2026-06-17 -->
- **Bound multi-turn loops with a round counter in metadata.** A clarify→clarify→clarify chain can loop forever. Store a `round` counter in the bot_response metadata; cap it (e.g. MAX=2). Once reached, send the question as a terminal reply WITHOUT persisting a new state row. Accumulate context across rounds (each round's `originalQuery` = the prior enriched query) so later turns retain full history. <!-- Source: second-brain #656, 2026-06-17 -->
- **Extract the shared resolve path when a fresh-intent handler and a resume interceptor run the same logic.** When both the initial handler and the reply interceptor must run identical window/fetch/LLM logic, extract one helper (`resolveCalendarQuery`) returning a discriminated outcome (`terminal` guard reply vs `result` structured output). Both callers stay thin and cannot diverge. The helper owns the "never throws — degrade to a user-facing reply" contract. <!-- Source: second-brain #656, 2026-06-17 -->
- **An NL reply-interceptor that catches CORRECTIONS to a pending op must FALL THROUGH (return null) on ambiguous input — trigger only on STRONG, op-specific signals.** When a reply interceptor adds a free-text "refine the proposal" path (beyond strict yes/no), the trigger predicate decides whether the reply refines the pending op or is an unrelated new message. Trigger on strong, unambiguous signals only: an explicit reference like `#N` (or "task N"/"item N"), or refine-specific verbs (`skip`, `drop`, `depends`, `swap`, `reschedule`, `shorter`). Do NOT trigger on weak words that recur in unrelated intents — `later`, `move`, `make`, `push`, `earlier` belong to reminders / calendar-write / capture, so a stale pending would silently swallow "remind me later", "move the dentist appt", "make a note to call mom". The interceptor only fires while a pending of that type exists, so a too-broad predicate hijacks normal messages exactly when the user has an open proposal. Cover both directions in tests: each strong signal refines; each weak/plain message returns null and falls through to classification. <!-- Source: adversarial review, second-brain #724 schedule-todos refine, 2026-06-24 -->

## Feature Removal with Persistent UI

- **Legacy button redirect for removed inline keyboards.** When removing a feature that had inline keyboard buttons in Telegram, old messages retain those buttons indefinitely (Telegram does not allow editing buttons on delivered messages without storing the message ID). Always add a graceful redirect handler for removed button actions that replies with a toast guiding users to the new location. Pattern: `if (action.startsWith("removed_feature")) { await ctx.answerCallbackQuery({ text: "Feature moved to X." }); return; }`. Without this, users tapping old buttons get a confusing "Unknown action" error. <!-- Source: second-brain, remove-telegram-snooze, 2026-02-19 -->

---
*Sources: second-brain, command-center*

## Prepend caveats when output can be tail-truncated (second-brain #906, 2026-07-19)

Telegram replies are capped (4096 chars) by truncating from the TAIL. Any caveat/note appended to a long rendered answer (clamp notices, "results limited to..." notes) is dropped exactly when the answer is long enough to need it. Rule: inside answer builders that run BEFORE the cap, PREPEND caveats; appending is only safe when the note is added AFTER the cap has already run. Generalizes to any channel with tail truncation.
