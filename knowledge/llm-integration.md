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

## Safety & Prompt Injection

- **Escape XML delimiters in user content.** When interpolating user text into XML-tagged prompts, escape `<`/`>` with `&lt;`/`&gt;` to prevent tag injection.
- **Escape ALL user-sourced strings, including DB-stored values.** Word names, definitions, example sentences stored in DB are still user-provided. Escape when interpolating into prompts.

## Multi-Layer Pipeline Debugging

- **Multi-layer silent failures.** Search fails → no context → AI disclaims memory. Test each layer independently, not just the end-to-end result.

## Date/Time Extraction

- **Use user's timezone, not UTC.** `extractDueDate` must use the user's timezone. The `en-CA` locale trick produces YYYY-MM-DD format.
- **Server-timezone parsing is broken.** `new Date(someDate.toLocaleString("en-US", { timeZone: tz }))` — the `new Date()` constructor uses the server's timezone. Use `Intl.DateTimeFormat.formatToParts()` instead.
- **Strip URLs before date extraction.** When content has URLs appended (e.g., email-promoted TODOs), date-like URL paths (`/2024/01/article`, `?session=spring2026`) can produce incorrect due dates. Always pass the clean title text to date/time extraction, not the full content with URLs. <!-- Source: PR review, second-brain #97, 2026-02-15 -->

---
*Sources: second-brain, lexica*
