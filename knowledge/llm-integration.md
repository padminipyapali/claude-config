# LLM Integration Patterns

Cross-project learnings for working with Claude API, OpenAI, and LLMs in general.

## Output Parsing

- **Always strip markdown code fences before `JSON.parse()`.** LLMs wrap JSON in ```json fences even when told not to. This is the common case, not an edge case.
  ```typescript
  const cleaned = text.replace(/^```(?:json)?\s*\n?/i, "").replace(/\n?```\s*$/i, "");
  const parsed = JSON.parse(cleaned);
  ```
- **Silent fallbacks hide real bugs.** `try { JSON.parse(output) } catch { return [content] }` makes parse failures invisible. Log before any fallback, at least during development.
- **Validate/filter LLM structured output against source of truth.** When an LLM returns structured data (evaluations, word lists), validate against the authoritative source (word bank, user data) server-side. Models may reference items not in the input set.
- **Defensive type checks on parsed fields.** Never use `event.text as string` on parsed LLM/SSE data. Guard with `typeof event.field === 'string'` before using.
- **AI summarization is lossy — preserve originals.** Never make AI-transformed content the only path to original data. Email summarization, content extraction, and paraphrasing all discard information (URLs, formatting, exact wording). Always store and expose the original alongside any AI-processed version. <!-- Source: BUG-W006, second-brain, 2026-02-14 -->

## Prompt Design

- **Few-shot examples must be internally consistent.** Re-read each example: (1) natural language input matches expected output, (2) template variables (`${today}`) resolve consistently, (3) relative date terms point to correct absolute dates.
- **Few-shot examples at decision boundaries beat abstract rules.** Show the LLM borderline cases rather than describing rules in the abstract.
- **Classifier prompts need explicit negative examples.** Day plans and schedules look like TODO lists — without explicit negative examples, classifiers miscategorize them.
- **Prompt rules can over-generalize.** A rule like `"buy milk and eggs" → single item` may cause the LLM to merge ALL grocery items. Test with diverse real inputs, not just prompt examples.
- **Classification intents designed for one input mode may not apply in another.** Intents for standalone messages may not make sense for thread replies. Verify each outcome per input context.
- **Custom persona constraints often reduce quality.** System prompts with heavy persona rules (e.g., "you are a pirate teacher") typically produce worse responses than the model's natural voice. Validate that persona customization actually improves task performance before shipping it — the constraint overhead often outweighs the benefit. <!-- Source: lexica personality removal decision, 2026-02-14 -->

## Safety & Prompt Injection

- **Escape XML delimiters in user content.** When interpolating user text into XML-tagged prompts, escape `<`/`>` with `&lt;`/`&gt;` to prevent tag injection.
- **Escape ALL user-sourced strings, including DB-stored values.** Word names, definitions, example sentences stored in DB are still user-provided. Escape when interpolating into prompts.
- **Separate user content from system instructions.** For Claude API: user content in the user message (inside XML tags), not the system prompt.

## Multi-Layer Pipeline Debugging

- **Multi-layer silent failures.** Search fails → no context → AI disclaims memory. Test each layer independently, not just the end-to-end result.
- **Fire-and-forget visibility.** When a fire-and-forget LLM operation does nothing (e.g., split returns 1 item), log at the decision point, not just the error path.
- **Test with real LLM calls, not just mocks.** Unit tests with mocked LLM responses can't catch issues like code fences in JSON output. Always do a live smoke test.

## Date/Time Extraction

- **Use user's timezone, not UTC.** `extractDueDate` must use the user's timezone. The `en-CA` locale trick produces YYYY-MM-DD format.
- **Server-timezone parsing is broken.** `new Date(someDate.toLocaleString("en-US", { timeZone: tz }))` — the `new Date()` constructor uses the server's timezone. Use `Intl.DateTimeFormat.formatToParts()` instead.
- **Strip URLs before date extraction.** When content has URLs appended (e.g., email-promoted TODOs), date-like URL paths (`/2024/01/article`, `?session=spring2026`) can produce incorrect due dates. Always pass the clean title text to date/time extraction, not the full content with URLs. <!-- Source: PR review, second-brain #97, 2026-02-15 -->

---
*Sources: second-brain, lexica*
