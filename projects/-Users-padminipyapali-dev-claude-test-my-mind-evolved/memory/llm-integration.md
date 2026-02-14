# LLM Integration Learnings

## Always strip markdown code fences from LLM JSON output
LLMs (including Haiku) wrap JSON in ```json code fences even when the prompt explicitly says "Return ONLY the JSON array, no explanation." This is not an edge case — it's the common case.

**Pattern:**
```typescript
const cleaned = text.replace(/^```(?:json)?\s*\n?/i, "").replace(/\n?```\s*$/i, "");
const parsed = JSON.parse(cleaned);
```

**Why it matters:** If the catch block falls back silently (e.g. `return [content]`), the failure is completely invisible. The feature appears to work in tests (where you mock the response) but fails in production (where the real LLM adds code fences). This was discovered during live testing of the TODO splitter — Haiku correctly identified 3 items but the parse silently failed.

**Rule:** Any `JSON.parse()` on LLM output must strip code fences first. Add this as a preprocessing step, not a defensive measure.

## Silent fallbacks hide real bugs
When parsing LLM output, `try/catch` with a silent fallback is dangerous during development. The TODO splitter had `catch { return [content]; }` which made the code fence bug completely invisible — no errors, no logs, just a feature that silently didn't work. Add logging before the fallback, at least during development.

## Prompt rules can backfire
The TODO splitter prompt included `"buy milk and eggs" → single item (one shopping task)`. This rule was too aggressive — Haiku generalized it to treat all grocery items ("buy milk, buy eggs, buy berries") as a single shopping task, even when listed separately. Test with real user messages, not just the examples in the prompt.

## Few-shot examples must be internally consistent
In PR #23, a date extraction prompt had an example that said "tomorrow" but used `${today}` as the date value. The LLM can learn the wrong date mapping from contradictory examples.

**Rule:** After writing a prompt with few-shot examples, re-read each example and verify: (1) the natural language input matches the expected output, (2) any template variables (`${today}`, `${now}`) resolve to values consistent with the example narrative, (3) relative date terms ("tomorrow", "next week") point to the correct absolute date in the example output.
