# Adversarial Review Checklist

Shared mechanical review checklist for all projects. Run this before every PR.

**IMPORTANT: This review should be run by a DIFFERENT agent than the one that wrote the code.** The authoring agent has blind spots to its own mistakes — it wrote `catch { return [] }` and won't question it. A separate reviewer agent, whose sole job is this checklist, catches what the author misses. This was learned from multiple PRs where the same agent did both fix + review and missed the same issues across all rounds.

**IMPORTANT: Execute each step mechanically. The most common failure mode is reading a checklist item, glancing at the code, and moving on. Follow the verification steps literally.**

---

## Tier 1: Recurring Blindspots (ALWAYS verify mechanically)

These patterns have been missed on multiple PRs despite being in the checklist.

### 1.1 Fire-and-Forget Try/Catch Granularity

**Why we miss it:** We see `.catch()` at the call site and assume the method is safe.

**Mechanical verification:**
1. Find all `.catch()` call sites in changed files.
2. For each, identify the method being called.
3. Read that method's implementation.
4. Count every `await` inside.
5. Verify EACH await has its own try/catch.

### 1.2 Error Swallowing in Catch Blocks

**Why we miss it:** "Add error handling" → instinctively add `catch { return [] }`.

**Mechanical verification:**
1. Find all catch blocks in changed files.
2. For each, ask: (a) What error is EXPECTED? (b) What errors are UNEXPECTED?
3. Expected errors → safe default. Unexpected errors → rethrow or propagate.

### 1.3 Broad vs. Narrow Try/Catch Scope

**Mechanical verification:**
1. Find all try blocks in changed files.
2. Count `await` calls inside each.
3. If > 1 await: do they fail for the SAME reason? If no → split them.

### 1.4 Grammar in User-Facing Text

**Why we miss it:** Fix the noun but forget dependent words.

**Mechanical verification:**
1. Find template literals with count-dependent text.
2. Verify ALL dependent words: noun (entry/entries), pronoun (it/them), verb (is/are), determiner (this/these).

### 1.5 Optimistic UI Revert Safety

**Mechanical verification:**
1. Find optimistic update patterns.
2. In catch/error path, verify revert uses a CAPTURED snapshot, not an inverted value.

---

## Tier 2: Security & Data Isolation

- [ ] **User scoping on ALL DB queries.** Every SELECT/UPDATE/DELETE on user data includes `WHERE user_id = $X`. Also check correlated subqueries.
- [ ] **No raw user content in logs.** Log timing, counts, IDs, types — never message content. Use `error.name` not `error.message`.
- [ ] **Input validation at boundaries.** `typeof` guard before `.trim()` or string methods on request body fields.
- [ ] **Shell command validation.** Regex: no prefix injection bypass (`\b` not `^`); no suffix injection bypass (`(\s|$)` not `\b`); extracted variables validated non-empty.
- [ ] **Escape user content in AI prompts.** Escape `<`/`>` with `&lt;`/`&gt;` in XML-tagged prompts. This includes DB-stored values.
- [ ] **No token-like placeholders in UI.** Avoid `ghp_`, `sk-`, `Bearer ey...`, `xoxb-` prefixes in placeholder/mock/demo data — secret scanners (CI, GitHub) will flag them. Use generic bullets `"••••••••"` or `"(hidden)"`. <!-- Source: PR review, command-center #3, 2026-02-14 -->

---

## Tier 3: Robustness & Graceful Degradation

- [ ] **Null/undefined guards.** Walk every `!`, `[]`, `.` chain. Check if any intermediate value could be null.
- [ ] **LLM output parsing.** `JSON.parse()` on LLM output must strip code fences. Handle empty/malformed.
- [ ] **Error message specificity.** Edge cases get specific messages, not generic fallthrough.
- [ ] **SVG `<title>` for accessibility.** Buttons must be `<button>`, not `<div role="button">`.
- [ ] **Hook error states surfaced in UI.** `{ data, loading, error }` — error MUST be rendered.
- [ ] **Env var validation.** NaN check, valid range, fallback logging for numeric vars. Timezone vars validated via `Intl.DateTimeFormat`.
- [ ] **Guard after create → reload.** Check for null after DB insert + reload.
- [ ] **JSON.parse on external config.** `JSON.parse()` on env vars or external config must be in try/catch with a descriptive error (e.g., "Invalid JSON in GOOGLE_SERVICE_ACCOUNT_KEY").
- [ ] **Off-by-one in time boundaries.** When querying events/records for a date range, use start-of-next-day as exclusive upper bound (`< nextDay T00:00:00`), not `<= T23:59:59` which misses the final second.
- [ ] **Filter external API data before mapping.** External APIs can return malformed entries (missing fields, null values). Use `.filter()` to skip invalid entries before `.map()`, rather than producing `NaN`/`Invalid Date` downstream.
- [ ] **UTC suffix in test Date strings.** `new Date("2026-02-14T10:00:00")` parses in server-local timezone, making tests flaky on CI. Always append `Z` for UTC: `new Date("2026-02-14T10:00:00Z")`.

---

## Tier 4: Data Integrity & Architecture

- [ ] **Type sync between SQL and TypeScript.** CHECK constraints and unions match.
- [ ] **Index coverage for new queries.** New WHERE patterns covered by existing indexes.
- [ ] **FTS coverage.** New searchable text columns in the GIN index.
- [ ] **Pattern siblings.** Grep entire codebase for other instances of same pattern.
- [ ] **Business logic in service, not routes.** Route does more than extract → call → return? Refactor.
- [ ] **At-most-once dedup markers BEFORE the action.**
- [ ] **Async initialization ordering.** New services depend on others being ready? Await them.
- [ ] **Timezone consistency: resolve once, pass through.** When a codepath needs both a timezone and a today-string, derive them from a SINGLE source. If `getLocalToday()` uses one default and `this.deps.userTimezone` uses another, they can silently diverge. Resolve timezone first, then derive the date from it.
- [ ] **Reuse existing DB pools.** Don't create ad-hoc `pg.Pool` for a single query when a service already has a pool. Add the method to the service interface instead. Ad-hoc pools leak connections and bypass service abstractions.
- [ ] **In-memory state survives restarts?** If a scheduler or service uses in-memory state for dedup (e.g., `lastSentDate`), verify it handles server restarts. On deploy-on-push platforms, every deploy clears memory. Either persist to DB or initialize defensively (e.g., pre-set the marker if the scheduled time has passed).
- [ ] **Documentation sync.** JSDoc matches code. Step counts updated. Module headers mention new capabilities.

---

## Tier 5: Product Adversarial Review (Plans Only)

Run this on every non-trivial feature plan before implementation. Code-level adversarial review catches bugs; product adversarial review catches wasted effort.

- [ ] **Regex/pattern coverage.** List 10 realistic user phrasings. Do ALL match? List 5 non-promotion phrasings. Do NONE match? Flag false positives and false negatives.
- [ ] **Content quality after the action.** What does the user see? Is the resulting content (TODO text, converted entry, promoted item) useful as-is, or does it need user editing? Would the user be confused by what was created?
- [ ] **Missing entry points.** Does the feature work from ALL surfaces (Telegram, web dashboard, future channels)? If not, is the gap intentional and documented?
- [ ] **Missing modifiers.** Can the user customize the action? (custom title, due date, tags) If not, will they expect to?
- [ ] **Undo path.** Can the user reverse the action? If not, is the action low-risk enough that undo isn't needed?
- [ ] **Edge case phrasings.** Test the exact failing phrase from the bug report against the detection logic. Then test 5 more realistic variations.
- [ ] **Downstream effects.** After the action, do related features still work? (daily summary, search, /todos list, thread panel)

<!-- Source: second-brain planning review, 2026-02-14 -->

---

## Post-Review: Learning Capture Gate

After the review passes, before writing the marker file:

1. **Were any bugs fixed in this PR?** If yes, update `docs/BUGS.md` AND the relevant `~/.claude/knowledge/*.md` topic file.
2. **Were any architectural decisions made?** If yes, update `docs/DECISIONS.md` AND `~/.claude/knowledge/architecture-patterns.md` if the pattern is generalizable.
3. **Were any new defensive patterns discovered?** If yes, update the relevant knowledge topic file.
4. **Is there a pattern in this PR that would have prevented a bug in a sibling project?** If yes, capture it in the appropriate knowledge file.

Only after confirming learning capture, write the marker:
```bash
git rev-parse HEAD > .claude/.adversarial-review-passed
```

---
*Sources: second-brain (26 mechanical checks from PR #23-#59), lexica, command-center*
