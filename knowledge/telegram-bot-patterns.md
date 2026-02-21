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

## HTML-Mode Safety

- **Escape user content in HTML-mode replies.** When using `parse_mode: "HTML"`, always escape `<`, `>`, `&` in user-provided strings (`task`, `displayName`, any input). This is the Telegram equivalent of XSS — Telegram will reject malformed HTML or render it incorrectly. <!-- Source: PR review, command-center #3, 2026-02-14 -->
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

## Feature Removal with Persistent UI

- **Legacy button redirect for removed inline keyboards.** When removing a feature that had inline keyboard buttons in Telegram, old messages retain those buttons indefinitely (Telegram does not allow editing buttons on delivered messages without storing the message ID). Always add a graceful redirect handler for removed button actions that replies with a toast guiding users to the new location. Pattern: `if (action.startsWith("removed_feature")) { await ctx.answerCallbackQuery({ text: "Feature moved to X." }); return; }`. Without this, users tapping old buttons get a confusing "Unknown action" error. <!-- Source: second-brain, remove-telegram-snooze, 2026-02-19 -->

---
*Sources: second-brain, command-center*
