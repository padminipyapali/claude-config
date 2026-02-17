# Adversarial Review Checklist

Shared mechanical review checklist for all projects. Run this before every PR.

**IMPORTANT: This review should be run by a DIFFERENT agent than the one that wrote the code.** The authoring agent has blind spots to its own mistakes — it wrote `catch { return [] }` and won't question it. A separate reviewer agent, whose sole job is this checklist, catches what the author misses. This was learned from multiple PRs where the same agent did both fix + review and missed the same issues across all rounds.

**IMPORTANT: Execute each step mechanically. The most common failure mode is reading a checklist item, glancing at the code, and moving on. Follow the verification steps literally.**

---

## Targeted Review — Classify First, Then Run Only What Applies

Do NOT run the full 30+ item checklist on every PR. Classify the changed files first, then run only the sections relevant to those categories. Running database checks on a CSS-only change is waste that blocks the PR with no value.

### Step 1: Classify changed files

Run `git diff main...HEAD --name-only` and classify each file:

| Category | File patterns |
|---|---|
| **async-ts** | `.ts`/`.js` files containing `async`, `await`, `.catch`, `.then`, `Promise` |
| **routes-api** | Files in `routes/`, `commands/`, `controllers/`, or HTTP/bot request handlers |
| **db-sql** | Files with SQL queries, schema files, migration files, pg/Knex/Prisma usage |
| **ui-react** | `.tsx`/`.jsx` files, React components, CSS/styled-components |
| **shell** | `.sh` files, or `.ts`/`.js` that spawn child processes / run shell commands |
| **llm** | Files that call LLM APIs, build prompts, or parse LLM output |
| **config-env** | `.env*` files, config modules that read `process.env` |
| **test-only** | Files only in `__tests__/`, `*.test.*`, `*.spec.*` |

A file can belong to multiple categories.

### Step 2: Run only matching sections

| Category | Checklist sections to run |
|---|---|
| **async-ts** | Tier 1: all (1.1–1.3). Tier 3: null guards, error message specificity |
| **routes-api** | Tier 2: all. Tier 4: business logic in service not routes |
| **db-sql** | Tier 2: user scoping. Tier 4: type sync, index coverage, FTS, reuse DB pools, guard after create→reload |
| **ui-react** | Tier 0: 0.4 (semantic elements), 0.5 (escape handler). Tier 1: 1.4 (grammar), 1.5 (optimistic UI). Tier 3: SVG/a11y, hook error states, escape in edit-within-panel, stale closure in background refresh |
| **shell** | Tier 2: shell command validation |
| **llm** | Tier 2: escape user content in AI prompts. Tier 3: LLM output parsing |
| **config-env** | Tier 3: env var validation, JSON.parse on external config |
| **test-only** | Tier 3: UTC suffix in test Date strings, test env isolation, error branch coverage. No other tiers needed. |

**Always run:** Tier 0 automated grep checks (every review). Tier 4: pattern siblings, documentation sync, architecture self-review (100+ LOC). Learning Capture Gate.

**Always skip for code review:** Tier 5 (plans only).

If no categories match (e.g., docs-only change), skip directly to the Learning Capture Gate.

### Step 3: Report transparency

In the review output, state which categories were detected and which checklist sections were skipped, so the author can verify coverage.

---

## Tier 0: Automated Grep Checks (Run FIRST on every review)

Before manual review, run these grep patterns against changed files. Any match is a finding — fix before proceeding.

### 0.1 UTC suffix on Date strings
```bash
git diff main...HEAD --name-only -- '*.ts' '*.tsx' | xargs grep -nE 'new Date\("[^"]*T[0-9]{2}:[0-9]{2}:[0-9]{2}"\)' 2>/dev/null
```
Catches: `new Date("2026-02-14T10:00:00")` without `Z`. Fix: append `Z`.

### 0.2 Fire-and-forget without .catch()
```bash
git diff main...HEAD -U0 -- '*.ts' '*.tsx' | grep -E '^\+.*\b(then|finally)\(' | grep -vE '\.catch\(' 2>/dev/null
```
Heuristic — `.catch()` may be on another line. Flag for manual review.

### 0.3 Generic error swallowing
```bash
git diff main...HEAD -U3 -- '*.ts' '*.tsx' | grep -B3 -A1 'catch' | grep -E 'return \[\]|return null|return undefined' 2>/dev/null
```
Heuristic — some defaults are legitimate. Flag for review.

### 0.4 Non-semantic interactive elements (a11y)
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -nE 'role=\{?.*"button"' 2>/dev/null
```
Catches: `<span role="button">`, `<div role="button">`. Fix: replace with `<button type="button">`.
Exception: elements containing `<a>` children (HTML content model violation).

### 0.5 Escape handler only on textarea (not container)
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -lE 'onKeyDown.*Escape|Escape.*handleEdit' 2>/dev/null | while read f; do
  grep -L 'onKeyDownCapture' "$f" 2>/dev/null
done
```
Heuristic — if a file handles Escape on a textarea/input but has no `onKeyDownCapture`, the Escape handler may not fire when focus is on sibling buttons. Flag for review.

### Adding new patterns
When a bug class is caught 2+ times across PRs, add a grep pattern here.
Requirements: expressible as regex on changed lines, low false-positive rate (<20%).

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
- [ ] **Auth fallbacks scoped to specific routes.** When adding alternative auth (query param token, cookie), verify it only applies to the exact route that needs it — not globally in shared middleware. Check: does the middleware gate the fallback on `req.method` + `req.path`? <!-- Source: PR review, second-brain #152, 2026-02-17 -->

---

## Tier 3: Robustness & Graceful Degradation

- [ ] **Null/undefined guards.** Walk every `!`, `[]`, `.` chain. Check if any intermediate value could be null.
- [ ] **LLM output parsing.** `JSON.parse()` on LLM output must strip code fences. Handle empty/malformed.
- [ ] **Error message specificity.** Edge cases get specific messages, not generic fallthrough.
- [ ] **Semantic elements.** Grep changed `.tsx` files for `role="button"` — every match on a non-`<button>` element (`<span>`, `<div>`, `<a>`) must be replaced with `<button type="button">`. Also: every `<svg>` needs a `<title>` child.
- [ ] **Escape in edit-within-panel.** If an inline edit mode lives inside a dismissible panel/modal, verify Escape is caught via `onKeyDownCapture` on the edit container — not just `onKeyDown` on the textarea. Focus can move to Save/Cancel buttons where textarea handlers don't fire. Also: guard `if (saving) return` so Escape during an in-flight save doesn't discard the error state.
- [ ] **Hook error states surfaced in UI.** `{ data, loading, error }` — error MUST be rendered.
- [ ] **Env var validation.** NaN check, valid range, fallback logging for numeric vars. Timezone vars validated via `Intl.DateTimeFormat`.
- [ ] **Guard after create → reload.** Check for null after DB insert + reload.
- [ ] **JSON.parse on external config.** `JSON.parse()` on env vars or external config must be in try/catch with a descriptive error (e.g., "Invalid JSON in GOOGLE_SERVICE_ACCOUNT_KEY").
- [ ] **Off-by-one in time boundaries.** When querying events/records for a date range, use start-of-next-day as exclusive upper bound (`< nextDay T00:00:00`), not `<= T23:59:59` which misses the final second.
- [ ] **Filter external API data before mapping.** External APIs can return malformed entries (missing fields, null values). Use `.filter()` to skip invalid entries before `.map()`, rather than producing `NaN`/`Invalid Date` downstream.
- [ ] **UTC suffix in test Date strings.** `new Date("2026-02-14T10:00:00")` parses in server-local timezone, making tests flaky on CI. Always append `Z` for UTC: `new Date("2026-02-14T10:00:00Z")`. **Enforcement:** Covered by Tier 0 check 0.1.
- [ ] **Test env variable isolation.** When tests mutate `process.env.*` (set in `beforeEach`, deleted in a test), verify cleanup in `afterEach` that captures and restores the original value. Without restore, env mutations leak across test files. Also: `vi.restoreAllMocks()` / `vi.resetAllMocks()` should be in `afterEach`, not inline — inline cleanup is skipped if the test fails before reaching it. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->
- [ ] **Error branch test coverage.** When a route has distinct error paths (e.g., timeout -> 504, upstream error -> 502, not found -> 404), verify each branch has a dedicated test case. List all `catch` blocks and conditional error responses in new handlers, then check for corresponding test assertions. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->
- [ ] **String truncation arithmetic.** When slicing a string to fit a max length and appending a suffix, verify `slice_length + suffix_length <= limit`. Pattern: `str.slice(0, limit - suffix.length) + suffix`. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- [ ] **Compound text decoration.** When a format helper returns decorated text (e.g., parentheses, brackets), check all call sites — callers adding their own decoration can compound: `((all day))`. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- [ ] **Stale closure in background refresh.** When a React hook fires a background fetch (cache-then-refresh pattern), the `.then()` closure captures the filter/key at call time. If the user switches tabs before the fetch resolves, `setEntries`/`setCursor` updates shared state with stale data. Guard with a `currentKeyRef` that tracks the active filter, and skip state updates when `currentKeyRef.current !== capturedKey`. Cache updates are safe; only setState calls need the guard. <!-- Source: post-mortem, second-brain #136, 2026-02-17 -->

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
- [ ] **Cross-channel output regression.** If changed code touches shared data consumed by multiple output channels (web, Telegram, email, API), verify all channels still render correctly. Same data, different display constraints (HTML vs 4096-char text vs JSON). <!-- Source: BUG-022, second-brain #101, 2026-02-15 -->
- [ ] **Architecture self-review (100+ LOC or 3+ directories changed).**
  1. **Right location?** Would a new contributor find each new file/function by grepping for the feature name?
  2. **Right abstraction?** Would you still extract this helper if the feature were never extended?
  3. **Right boundary?** Does any layer reach into non-adjacent layers? (UI→DB, service→Telegram format)
  4. **Right scope?** Could this PR be split into independent concerns?
  5. **Understand in 30 days?** Read the diff cold — is intent clear from code + comments?

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
