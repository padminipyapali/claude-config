# LLM Integration Patterns

Cross-project learnings for working with Claude API, OpenAI, and LLMs in general.

## Output Parsing

- **Silent fallbacks hide real bugs.** `try { JSON.parse(output) } catch { return [content] }` makes parse failures invisible. Log before any fallback, at least during development.
- **Defensive type checks on parsed fields.** Never use `event.text as string` on parsed LLM/SSE data. Guard with `typeof event.field === 'string'` before using.
- **AI summarization is lossy — preserve originals.** Never make AI-transformed content the only path to original data. Email summarization, content extraction, and paraphrasing all discard information (URLs, formatting, exact wording). Always store and expose the original alongside any AI-processed version. <!-- Source: BUG-W006, second-brain, 2026-02-14 -->
- **Embedding content must match stored content.** When a pipeline cleans/transforms text before storage, generate embeddings from the CLEANED text, not the raw input. If stored content says "buy milk" but the embedding vector represents "todo: buy milk please", semantic search returns results whose text doesn't match the query context. Any transform-then-store pipeline must use the same text for both storage and embedding. <!-- Source: PR review, second-brain #109, 2026-02-15 -->

## Prompt Design

- **Prompt rules can over-generalize.** A rule like `"buy milk and eggs" → single item` may cause the LLM to merge ALL grocery items. Test with diverse real inputs, not just prompt examples.
- **Custom persona constraints often reduce quality.** System prompts with heavy persona rules (e.g., "you are a pirate teacher") typically produce worse responses than the model's natural voice. Validate that persona customization actually improves task performance before shipping it — the constraint overhead often outweighs the benefit. <!-- Source: lexica personality removal decision, 2026-02-14 -->
- **Anchoring bias on provided context values.** When an extraction prompt provides context like "Today's date is 2026-02-16", the model may anchor on that value and return it even for inputs with no matching reference. Counteract with: (1) an explicit "return NONE unless the input contains X" rule, (2) a base rate statement ("most inputs don't have X") to set expectation toward NONE, (3) multiple negative examples showing inputs without the target feature. One negative example is insufficient — the model needs several to generalize the boundary. <!-- Source: BUG-029, second-brain, 2026-02-16 -->
- **Let classifiers express uncertainty on ambiguous input.** When a classifier faces genuinely ambiguous input (e.g., "I need to file a bug" — thought or task?), don't force it to guess. Add an uncertainty output format (e.g., `THOUGHT?TODO`) so the classifier can signal ambiguity, then involve the user in disambiguation. Use the safe default for storage (no data loss) and prompt the user to reclassify if needed. <!-- Source: BUG-T018, second-brain, 2026-02-16 -->

## Safety & Prompt Injection

- **Escape XML delimiters in user content — all 5 entities.** When interpolating user text into XML-tagged prompts, escape all XML special characters: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&#39;`. This applies to both element content AND attribute values (e.g., `<doc source="...">`) — attribute values with unescaped quotes break the XML structure, and `&` in any position creates malformed entities. <!-- Strengthened: PR review, second-brain #237, 2026-02-24 -->
- **Escape ALL user-sourced strings, including DB-stored values.** Word names, definitions, example sentences stored in DB are still user-provided. Escape when interpolating into prompts.

## Handler-Level Error Wrapping

- **Wrap LLM generation calls in try/catch at the handler level.** When an intent handler calls an LLM to generate a user-facing response, wrap the call in its own try/catch and return a user-safe fallback message on failure (e.g., "I'm having trouble answering that right now. Please try again."). Don't let LLM API errors (rate limits, timeouts, malformed responses) propagate as unhandled exceptions — they crash the request and show raw error messages. The entry/storage side of the handler should still succeed even if response generation fails. <!-- Source: PR review, second-brain #237, 2026-02-24 -->

## Multi-Layer Pipeline Debugging

- **Multi-layer silent failures.** Search fails → no context → AI disclaims memory. Test each layer independently, not just the end-to-end result.

## LLM Output as Function Input

- **Treat LLM-extracted values as untrusted input at every call site.** When a function receives values extracted by an LLM (dates, times, categories, IDs), bad/impossible values are the expected case — not an edge case. If you add input validation to such a function (e.g., `buildRemindAt` throwing on invalid hour/minute), every caller must have try/catch, because the LLM WILL produce invalid values. The safe default on validation failure is to skip the feature gracefully (no reminder set) rather than crash the entire message processing pipeline. <!-- Source: PR review, second-brain #187, 2026-02-20 -->

## Date/Time Extraction

- **Use user's timezone, not UTC.** `extractDueDate` must use the user's timezone. The `en-CA` locale trick produces YYYY-MM-DD format.
- **Server-timezone parsing is broken.** `new Date(someDate.toLocaleString("en-US", { timeZone: tz }))` — the `new Date()` constructor uses the server's timezone. Use `Intl.DateTimeFormat.formatToParts()` instead.
- **Strip URLs before date extraction.** When content has URLs appended (e.g., email-promoted TODOs), date-like URL paths (`/2024/01/article`, `?session=spring2026`) can produce incorrect due dates. Always pass the clean title text to date/time extraction, not the full content with URLs. <!-- Source: PR review, second-brain #97, 2026-02-15 -->

---
*Sources: second-brain, lexica*
