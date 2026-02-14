# Telegram Bot Patterns

Cross-project learnings for Telegram bots (grammY, Bot API).

## Identity Mapping

- **Dual identity layers: always pass both IDs.** When resolving external IDs (Telegram chat ID) to internal IDs (DB UUID) at the boundary, outbound flows (notifications, follow-ups) still need the external ID. Pass both `userId` (DB) and `channelUserId` (external) through the pipeline.
- **Reverse lookup as fallback.** If outbound calls happen far from where the channel ID is available, add `getUserChannelId(userId, channel)` — but passing both IDs is simpler when possible.

## Bot Architecture

- **Thin command dispatchers to services.** Bot command handlers should extract params and delegate to service methods. No business logic in handlers.
- **Interface-first design.** Put external dependencies (AgentRunner, TaskQueue) behind interfaces for testability and swappability.
- **Env-driven project paths.** Configure project directories via environment variables, not hardcoded paths.

## Webhook & Polling

- **Webhook latency: decouple processing from response.** Respond 200 to the webhook immediately, then process the message asynchronously. Long processing blocks subsequent updates.
- **Keepalive self-ping prevents cold starts.** On PaaS platforms, periodic self-pings keep the service warm.
- **Polling mode for development.** Use polling during development, webhooks in production.

## Message Handling

- **Entry-less responses break reply-to chains.** Response types that don't create DB entries (TODO_LIST, CHAT) have no entry to link replies to. Solution: use a lightweight `bot_responses` table to track outbound messages.
- **Store matched IDs in metadata, reuse directly.** When a search matches entries, store the IDs — don't re-search and risk discarding them.
- **Reply context takes precedence over content-based search.** When a user replies to a specific message, they are referring to that message's subject — not whatever a keyword search might return. Use the parent entry directly (e.g., `findByIds([parentEntry.id])`) instead of searching all items by keyword. Fall back to search only when no parent context exists.

---
*Sources: second-brain, command-center*
