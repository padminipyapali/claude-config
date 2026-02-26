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
| **db-sql** | Tier 2: user scoping. Tier 4: type sync, index coverage, FTS, reuse DB pools, guard after create→reload, trigger event scope (INSERT vs UPDATE vs both), transaction client affinity |
| **ui-react** | Tier 0: 0.4 (semantic elements), 0.4b (form input labels), 0.5 (escape handler), 0.13 (focus-visible parity), 0.14 (iOS auto-zoom). Tier 1: 1.4 (grammar), 1.5 (optimistic UI), 1.6 (portal/popover positioning), 1.7 (interactive mode state cleanup). Tier 3: SVG/a11y, button type audit, new union member completeness, conditional UI branch tests, hook error states, escape in edit-within-panel, stale closure in background refresh, render-phase setState, instance-unique IDs, React key uniqueness, click propagation on interactive→non-interactive refactors, key-based state reset for context-dependent children |
| **shell** | Tier 2: shell command validation |
| **llm** | Tier 2: escape user content in AI prompts. Tier 3: LLM output parsing |
| **config-env** | Tier 3: env var validation, JSON.parse on external config |
| **test-only** | Tier 3: UTC suffix in test Date strings, test env isolation, error branch coverage, test mock target verification, full object shape assertions. No other tiers needed. |

**Always run:** Tier 0 automated grep checks (every review). Tier 4: pattern siblings, documentation sync, architecture self-review (100+ LOC). Learning Capture Gate.

**Always skip for code review:** Tier 5 (plans only).

If no categories match (e.g., docs-only change), skip directly to the Learning Capture Gate.

### Step 3: Structured evidence per checklist item

For every checklist item in the matched sections, record an explicit verdict with **specific, verifiable evidence**. Do not skip items or assess by "glancing at the code."

Format per item:
- **PASS: [item name]** — [verifiable evidence: grep command + output, specific file:line references visited, list of callers/implementations checked]
- **FAIL: [item name]** — [description of finding + file:line]
- **SKIP: [item name]** — [reason, e.g. "no SQL in diff"]

**Evidence requirements by item type:**
- **Items with grep patterns (Tier 0):** Paste the grep command AND its output (even if "0 matches"). Do not summarize.
- **Items requiring caller/implementation tracing:** List EACH caller or implementation by file:line. "All callers handle it" without listing them is not evidence.
- **Items checking for pattern siblings:** Show the grep command, the files matched, and the disposition of each match.
- **Items checking test coverage:** List each test case by name and what branch/path it covers.

**Banned evidence phrases** (these indicate judgment, not mechanical verification):
- "looks fine", "appears correct", "no issues found", "code looks clean"
- "checked and OK", "verified", "confirmed" (without specifics)
- Any single-word verdict without a file:line reference or grep output

This is non-negotiable. Four consecutive PRs (#206, #208, #209, #211) had post-push findings that mapped to existing checklist items but were missed because the reviewer assessed them judgmentally instead of mechanically. Requiring verifiable evidence per item is the structural fix.

Also state which categories were detected and which checklist sections were skipped, so the author can verify coverage.

### Step 4: Default to fix — no deferrals

When the review identifies ANY finding — regardless of severity — **fix it immediately**. Do not classify findings as "low", "acceptable", "non-blocking", or "deferred."

**Why:** PRs #198, #206, and #213 all show the same anti-pattern: the adversarial review identified an issue, labeled it low-severity, and chose not to fix it. CodeRabbit then flagged the exact same issue post-push, costing 15+ minutes of round-trip (re-review + fix commit + wait for re-review). The 5-minute local fix is always cheaper than the post-push cycle.

**The only valid skip reasons:**
- The finding requires changes to files NOT in the current diff (create a follow-up issue instead).
- The finding is a false positive (explain why with specific evidence).

"Low priority", "non-blocking", "acceptable for now", and "will address in follow-up" are NOT valid skip reasons. If you can identify it, you can fix it.

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

### 0.4b Form inputs without accessible labels
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -nE 'placeholder=' 2>/dev/null | while read line; do
  file=$(echo "$line" | cut -d: -f1); lineno=$(echo "$line" | cut -d: -f2)
  grep -A2 "$(sed -n "${lineno}p" "$file")" "$file" | grep -qE 'aria-label|htmlFor|aria-labelledby' || echo "MISSING LABEL: $line"
done
```
Catches: `<input placeholder="...">` or `<textarea placeholder="...">` without `aria-label`, `<label htmlFor>`, or `aria-labelledby`. Also check icon-only `<button>` elements (text is only a symbol like "+", "×") — they need `aria-label` too. <!-- Source: post-mortem, command-center #33, 2026-02-20 -->

### 0.5 Escape handler only on textarea (not container)
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -lE 'onKeyDown.*Escape|Escape.*handleEdit' 2>/dev/null | while read f; do
  grep -L 'onKeyDownCapture' "$f" 2>/dev/null
done
```
Heuristic — if a file handles Escape on a textarea/input but has no `onKeyDownCapture`, the Escape handler may not fire when focus is on sibling buttons. Flag for review.

### 0.6 Date comparison without validity check
```bash
git diff main...HEAD -U5 -- '*.ts' '*.tsx' | grep -B5 -E 'new Date\(' | grep -E '(>|<|>=|<=)\s*new Date' 2>/dev/null
```
Heuristic — flags date comparisons near `new Date()` construction. `new Date("bad") > new Date()` is always `false` (NaN comparison), silently taking the wrong branch. Verify each match has a `Number.isFinite()` or `isNaN()` guard. <!-- Source: PR review, second-brain #187, 2026-02-20 -->

### 0.7 Infinite CSS animations without prefers-reduced-motion
```bash
git diff main...HEAD --name-only -- '*.css' '*.tsx' | xargs grep -l 'animation:.*infinite' 2>/dev/null | while read f; do
  if grep -A10 'animation:.*infinite' "$f" | grep -q '@media (prefers-reduced-motion: reduce)'; then true; else echo "MISSING REDUCE: $f"; fi
done
```
Catches: `animation: name ... infinite;` without a `@media (prefers-reduced-motion: reduce)` override. WCAG 2.1 Level AA requirement. Fix: add `@media (prefers-reduced-motion: reduce) { animation: none !important; }` for each infinite animation (use `!important` to prevent cascade shadowing). <!-- Source: CodeRabbit review, second-brain #213, 2026-02-23 -->

### 0.8 SVG `<title>` inside labeled buttons
```bash
git diff main...HEAD --name-only -- '*.tsx' | while read f; do
  # Find lines with <svg><title> inside buttons with aria-label
  grep -n '<svg' "$f" | while read svgline; do
    svglineno=$(echo "$svgline" | cut -d: -f1)
    # Check if <title> exists in next 3 lines
    if sed -n "${svglineno},$((svglineno+3))p" "$f" | grep -q '<title>'; then
      # Check if parent is a button or link with aria-label
      parentlines=$(sed -n "1,${svglineno}p" "$f" | tail -20)
      if echo "$parentlines" | grep -qE '<(button|a).*aria-label'; then
        echo "DUPLICATE A11Y: $f:$svglineno (SVG <title> with labeled parent)"
      fi
    fi
  done
done
```
Catches: SVGs with `<title>` elements inside buttons/links that have `aria-label`. Screen readers announce both, creating duplicate labels. Fix: remove `<title>` and add `aria-hidden="true" focusable="false"` to the `<svg>`. <!-- Source: CodeRabbit review, second-brain #213, 2026-02-23 -->

### 0.9 Truthiness guard on string input (missing .trim())
```bash
git diff main...HEAD -U0 -- '*.ts' '*.tsx' | grep -E '^\+' | grep -E 'if\s*\(\s*!(\w+)\s*\)' | grep -vE '\.trim\(\)' 2>/dev/null
```
Heuristic — flags `if (!variable)` guards on string inputs that don't call `.trim()`. Whitespace-only strings like `"   "` are truthy in JS and bypass these guards. Verify each match: if the variable holds user/command input, it needs `!variable?.trim()` or the variable should be trimmed at assignment. Not all matches are bugs — boolean/number guards are fine. <!-- Source: post-mortem, second-brain #237, 2026-02-25 -->

### 0.10 Raw interpolation in XML/HTML template strings
```bash
git diff main...HEAD -U3 -- '*.ts' '*.tsx' | grep -E '^\+.*`<\w+[^>]*\$\{' 2>/dev/null
```
Catches: template literals building XML/HTML tags with `${variable}` interpolation. Any match needs verification that the interpolated values are escaped (attribute values with `escapeXml`/`escapeHtml`, element content if user-sourced). Common miss: escaping attributes but not body content, or escaping `<`/`>` but missing `&`/`"`/`'`. <!-- Source: post-mortem, second-brain #237, 2026-02-25 -->

### 0.11 DELETE + INSERT loop without transaction
```bash
git diff main...HEAD --name-only -- '*.ts' | xargs grep -lE 'delete|DELETE FROM' 2>/dev/null | while read f; do
  if grep -q 'DELETE FROM' "$f" && grep -q 'INSERT INTO' "$f" && ! grep -qE 'BEGIN|transaction|COMMIT' "$f"; then
    echo "NO TRANSACTION: $f (has DELETE + INSERT without BEGIN/COMMIT)"
  fi
done
```
Catches: files that do both DELETE and INSERT on the same table without a transaction. A failure between delete and insert leaves data partially removed. Fix: wrap in `BEGIN`/`COMMIT`/`ROLLBACK` using `pool.connect()` + explicit transaction. Heuristic — some patterns are safe (e.g., delete and insert on different tables). Flag for review. <!-- Source: post-mortem, second-brain #237, 2026-02-25 -->

### 0.12 Brittle error type detection via string matching
```bash
git diff main...HEAD --name-only -- '*.ts' '*.tsx' | xargs grep -nE '\.message\.(includes|startsWith|match)\(' 2>/dev/null
```
Catches: `err.message.includes("not found")` or similar string matching on error messages. Fix: use `instanceof` against typed error classes (e.g., `NotFoundError`). If no typed error class exists, create one. String matching is brittle — messages change, and unrelated errors can contain the substring. <!-- Source: PR review, second-brain #248, 2026-02-25 -->

### 0.13 Focus-visible parity for new interactive elements
```bash
git diff main...HEAD --name-only -- '*.css' | while read f; do
  new_selectors=$(git diff main...HEAD -- "$f" | grep -E '^\+.*\{' | grep -vE '^\+\+\+' | sed 's/+//' | tr -d '{ ')
  if [ -n "$new_selectors" ]; then
    existing_focus=$(grep -c ':focus-visible' "$f" 2>/dev/null || echo 0)
    if [ "$existing_focus" -gt 0 ]; then
      for sel in $new_selectors; do
        clean=$(echo "$sel" | sed 's/[.#]//g' | tr -d '[:space:]')
        if [ -n "$clean" ] && ! grep -q "${clean}.*:focus-visible" "$f" 2>/dev/null; then
          echo "MISSING FOCUS-VISIBLE: $f selector '$sel' (file has $existing_focus existing :focus-visible rules)"
        fi
      done
    fi
  fi
done
```
Heuristic -- flags new CSS selectors in files that already have `:focus-visible` rules on sibling selectors. When a file has an established focus-visible pattern and a new interactive element is added, the new element should have matching focus-visible treatment. <!-- Source: post-mortem, second-brain #256, 2026-02-26 -->

### 0.14 iOS auto-zoom on small font-size inputs
```bash
git diff main...HEAD --name-only -- '*.css' | xargs grep -nE '(input|textarea|\.chat-input|\.text-input).*font-size:\s*(0\.\d+rem|1[0-5]px|0\.[0-8]\d*em)' 2>/dev/null
```
Catches: `<input>` or `<textarea>` elements styled with `font-size` below 16px (1rem). iOS Safari auto-zooms the viewport on focus when input font-size is under 16px, disrupting mobile UX. Fix: use `font-size: 1rem` (16px) or larger on all form inputs. Heuristic -- not all matches are actual inputs; verify the selector targets a form element. <!-- Source: CodeRabbit review, second-brain #272, 2026-02-26 -->

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
3. **Staleness guard on revert:** In the catch block, verify the revert only applies if the item's current value still matches the optimistic value set by THIS call (`e.status === newStatus`). Without this guard, a slow-failing request reverts over a later successful update when the user rapidly triggers the same action. <!-- Source: post-mortem, second-brain #269, 2026-02-26 -->
4. After revert, verify there is **user-visible error feedback** (toast, inline error, temporary message). Silent revert without feedback confuses users — they see a change, then it disappears with no explanation. <!-- Source: post-mortem, second-brain #186, 2026-02-20 -->

### 1.6 Portal/Popover Positioning

**Mechanical verification:**
1. Find portal-rendered or absolutely-positioned popovers/dropdowns.
2. Verify position is **recalculated** on scroll and window resize (via event listeners), or that the popover **closes** on scroll/resize. Static one-time positioning disconnects the popover from its trigger on user interaction.
3. Verify `left` and `top` values are clamped to avoid off-screen positioning on narrow viewports (e.g., `Math.max(8, Math.min(rect.left, maxLeft))`).
<!-- Source: post-mortem, second-brain #186, 2026-02-20 -->

### 1.7 Interactive Mode State Cleanup

**Mechanical verification:**
1. Find components with multiple interactive states (e.g., editing, date-picker-open, dropdown-open).
2. When entering one interactive mode, verify all competing mode states are reset. Example: entering edit mode should set `showDatePicker = false`.
3. Check: "If mode A is active and user triggers mode B, does mode A's state get cleaned up?"
<!-- Source: post-mortem, second-brain #186, 2026-02-20 -->

---

## Tier 2: Security & Data Isolation

- [ ] **User scoping on ALL DB queries.** Every SELECT/UPDATE/DELETE on user data includes `WHERE user_id = $X`. Also check correlated subqueries.
- [ ] **No raw user content in logs.** Log timing, counts, IDs, types — never message content. Use `error.name` not `error.message`.
- [ ] **Input validation at boundaries.** `typeof` guard before `.trim()` or string methods on request body fields.
- [ ] **Shell command validation.** Regex: no prefix injection bypass (`\b` not `^`); no suffix injection bypass (`(\s|$)` not `\b`); extracted variables validated non-empty. Guard ordering: verify early-exit blocks don't make later exception paths unreachable or create bypass holes for non-matching branches. <!-- Strengthened: nanny-app #31, 2026-02-19 -->
- [ ] **Escape user content in AI prompts.** Escape `<`/`>` with `&lt;`/`&gt;` in XML-tagged prompts. This includes DB-stored values. When injecting external data (e.g., GitHub PR titles, user emails, RSS feeds) into LLM context blocks, verify BOTH: (1) XML-structural escape (`<`, `>`, `&`, `"`, `'`) and (2) the system prompt treats the data as read-only reference, not as instructions to follow. XML escaping prevents structural corruption; prompt-level framing prevents adversarial content from influencing LLM behavior. <!-- Strengthened: post-mortem, second-brain #256, 2026-02-26 -->
- [ ] **RLS UPDATE policies have WITH CHECK.** For every RLS UPDATE policy in migration files, verify both `USING` and `WITH CHECK` clauses are present. `USING` alone gates which rows can be read for update, but allows writing unauthorized values (e.g., changing `household_id` to another tenant). `WITH CHECK` should mirror the tenant-scoping predicate. <!-- Source: PR review, folio #1, 2026-02-23 -->
- [ ] **No token-like placeholders in UI.** Avoid `ghp_`, `sk-`, `Bearer ey...`, `xoxb-` prefixes in placeholder/mock/demo data — secret scanners (CI, GitHub) will flag them. Use generic bullets `"••••••••"` or `"(hidden)"`. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- [ ] **Auth fallbacks scoped to specific routes.** When adding alternative auth (query param token, cookie), verify it only applies to the exact route that needs it — not globally in shared middleware. Check: does the middleware gate the fallback on `req.method` + `req.path`? <!-- Source: PR review, second-brain #152, 2026-02-17 -->
- [ ] **Content-Type enforcement on mutation endpoints.** POST/PUT handlers that parse `req.body` as JSON should verify `Content-Type: application/json` (or return 415). Express `json()` middleware parses valid JSON regardless of content-type header, but missing/wrong content-type often means the client sent an empty or malformed body. Guard before validation logic. <!-- Source: post-mortem, command-center #39, 2026-02-26 -->
- [ ] **Cross-platform path traversal validation.** When validating relative paths, reject not only `/`-prefixed paths but also Windows absolute paths (`C:\`, `D:\`), UNC paths (`\\server\share`), and any `path.isAbsolute()` match. Unix-only guards leave Windows-style absolute paths unblocked. <!-- Source: post-mortem, command-center #39, 2026-02-26 -->

---

## Tier 3: Robustness & Graceful Degradation

- [ ] **Null/undefined guards.** Walk every `!`, `[]`, `.` chain. Check if any intermediate value could be null.
- [ ] **LLM output parsing.** `JSON.parse()` on LLM output must strip code fences. Handle empty/malformed.
- [ ] **Error message specificity.** Edge cases get specific messages, not generic fallthrough.
- [ ] **Semantic elements.** Grep changed `.tsx` files for `role="button"` — every match on a non-`<button>` element (`<span>`, `<div>`, `<a>`) must be replaced with `<button type="button">`. Also: every `<svg>` needs a `<title>` child.
- [ ] **Button type audit.** When modifying a `.tsx` file, grep it for `<button` without `type=`. Every `<button>` must have explicit `type="button"` (interactive) or `type="submit"` (form). Missing types default to `submit` and cause accidental form submissions. Audit the *entire file*, not just the diff — pre-existing violations in touched files should be fixed. <!-- Source: CodeRabbit review, nanny-app #26, 2026-02-19 -->
- [ ] **New union member completeness.** When adding a value to a TypeScript union type (e.g., `'unpaid_off'` to `SpecialDay['type']`), grep the entire codebase for every switch/conditional that maps that type to a style class, label, color, or behavior. Each one needs explicit handling for the new value — fallthrough to a default case often produces wrong results (e.g., unpaid days getting sick-day styling). Also check **validation Sets** used for gating: a single `VALID_TYPES` Set reused for multiple code paths (filtering vs action-triggering) may over-include the new type in paths that shouldn't handle it. Split shared validation constants per purpose when semantics diverge (e.g., `VALID_ENTRY_TYPES` for filtering vs `VALID_PROMOTABLE_ENTRY_TYPES` for creation). <!-- Strengthened: PR review, second-brain #262, 2026-02-26; original: nanny-app #26, 2026-02-19 -->
- [ ] **Conditional UI branch test coverage.** When a component renders different UI based on a boolean flag (e.g., `isNightNurse`), verify test cases exist for each branch — not just the default path. At minimum: one test asserting the alternate UI renders, one asserting the default UI elements are hidden. <!-- Source: CodeRabbit review, nanny-app #26, 2026-02-19 -->
- [ ] **Escape in edit-within-panel.** If an inline edit mode lives inside a dismissible panel/modal, verify Escape is caught via `onKeyDownCapture` on the edit container — not just `onKeyDown` on the textarea. Focus can move to Save/Cancel buttons where textarea handlers don't fire. Also: guard `if (saving) return` so Escape during an in-flight save doesn't discard the error state.
- [ ] **Hook error states surfaced in UI.** `{ data, loading, error }` — error MUST be rendered. Also check the hook's internal implementation: `load()` catch blocks must call `setError(err)` (not silently swallow), and the success path must call `setError(null)` to clear stale errors. <!-- Strengthened: PR review, second-brain #248, 2026-02-25 -->
- [ ] **Env var validation.** NaN check, valid range, fallback logging for numeric vars. Timezone vars validated via `Intl.DateTimeFormat`.
- [ ] **Guard after create → reload.** Check for null after DB insert + reload.
- [ ] **JSON.parse on external config.** `JSON.parse()` on env vars or external config must be in try/catch with a descriptive error (e.g., "Invalid JSON in GOOGLE_SERVICE_ACCOUNT_KEY").
- [ ] **Off-by-one in time boundaries.** When querying events/records for a date range, use start-of-next-day as exclusive upper bound (`< nextDay T00:00:00`), not `<= T23:59:59` which misses the final second.
- [ ] **Off-by-one in threshold comparisons.** When code splits, groups, or gates on a threshold (time gaps, count limits, window sizes), verify the comparison operator matches the spec: `>` means "split only when strictly greater," `>=` means "split at the threshold itself." The distinction matters: a 30-minute session gap threshold should use `>= 30` not `> 30`, or a gap of exactly 30 minutes is silently placed in the wrong session. Mechanical check: find all comparisons against threshold/limit/max constants in changed files and ask "should equality trigger the branch or not?" <!-- Source: PR review, command-center #23, 2026-02-19 -->
- [ ] **Newly-throwing functions: caller audit.** When a function gains `throw` validation that it didn't have before (e.g., converting a silent `return null` to `throw new Error("invalid")`), grep ALL callers and verify each has error handling. Especially dangerous when inputs come from LLM extraction or user input — bad data is the common case. <!-- Source: PR review, second-brain #187, 2026-02-20 -->
- [ ] **Filter external API data before mapping.** External APIs can return malformed entries (missing fields, null values). Use `.filter()` to skip invalid entries before `.map()`, rather than producing `NaN`/`Invalid Date` downstream.
- [ ] **UTC suffix in test Date strings.** `new Date("2026-02-14T10:00:00")` parses in server-local timezone, making tests flaky on CI. Always append `Z` for UTC: `new Date("2026-02-14T10:00:00Z")`. **Enforcement:** Covered by Tier 0 check 0.1.
- [ ] **Test env variable isolation.** When tests mutate `process.env.*` (set in `beforeEach`, deleted in a test), verify cleanup in `afterEach` that captures and restores the original value. Without restore, env mutations leak across test files. Also: `vi.restoreAllMocks()` / `vi.resetAllMocks()` should be in `afterEach`, not inline — inline cleanup is skipped if the test fails before reaching it. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->
- [ ] **Error branch test coverage.** When a route has distinct error paths (e.g., timeout -> 504, upstream error -> 502, not found -> 404), verify each branch has a dedicated test case. List all `catch` blocks and conditional error responses in new handlers, then check for corresponding test assertions. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->
- [ ] **String truncation arithmetic.** When slicing a string to fit a max length and appending a suffix, verify `slice_length + suffix_length <= limit`. Pattern: `str.slice(0, limit - suffix.length) + suffix`. For HTML-formatted strings, truncate at line boundaries (`lastIndexOf("\n")`) to avoid splitting paired tags (`<a>...</a>`, `<b>...</b>`), then strip partial tags/entities as fallback. <!-- Source: post-mortem, second-brain #131, 2026-02-16; strengthened PR review #155, 2026-02-17 -->
- [ ] **Compound text decoration.** When a format helper returns decorated text (e.g., parentheses, brackets), check all call sites — callers adding their own decoration can compound: `((all day))`. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- [ ] **Stale closure in background refresh.** When a React hook fires a background fetch (cache-then-refresh pattern), the `.then()` closure captures the filter/key at call time. If the user switches tabs before the fetch resolves, `setEntries`/`setCursor` updates shared state with stale data. Guard with a `currentKeyRef` that tracks the active filter, and skip state updates when `currentKeyRef.current !== capturedKey`. Cache updates are safe; only setState calls need the guard. <!-- Source: post-mortem, second-brain #136, 2026-02-17 -->
- [ ] **Test mock target verification.** For each `vi.spyOn()` or `vi.fn()` mock in new/changed test files, trace the mock target to the production code path under test. Verify the mocked method is the one actually called in the code path being tested, not a similar-sounding sibling method. Common failure: mocking `findForDate` when the code uses `findAllOpen`. <!-- Source: post-mortem, second-brain #159, 2026-02-19 -->
- [ ] **Full object shape assertions on structured output.** When tests assert inline buttons, API response objects, or structured UI data, verify assertions cover the full object shape (text, labels, IDs) — not just callback data or IDs. Partial assertions miss label regressions. <!-- Source: post-mortem, second-brain #159, 2026-02-19 -->
- [ ] **Boundary value test coverage for threshold logic.** When any function compares against a threshold constant (gap duration, item count, rate limit), verify tests cover: (1) exactly at the threshold, (2) one unit below, (3) clearly above. Tests covering only "above" and "below" leave the boundary operator (`>` vs `>=`) untested — the most common off-by-one site. <!-- Source: PR review, command-center #23, 2026-02-19 -->
- [ ] **Side-effect ordering around fallible operations.** When a fire-and-forget side effect (e.g., `markResearchInitiated`, `flagAsProcessed`) sits near a fallible `await`, verify: does the side effect assume success? If yes, move it AFTER the await's success path. State flags set before a fallible operation leave the system in an inconsistent state on failure (entry flagged as researched but no research task exists). Distinct from Tier 4 "dedup markers BEFORE action" (which is about idempotency). **Also check fallback-value-as-noop:** when a function returns a fallback value on failure (e.g., returning the existing summary when LLM generation fails), callers must compare the returned value against the previous value before triggering side effects (counter resets, DB writes). Treating a fallback as a successful result causes phantom state resets. <!-- Strengthened: post-mortem, second-brain #275, 2026-02-26; original: #211, 2026-02-23 -->
- [ ] **HTML entity completeness in custom escape helpers.** When a file defines a custom HTML escape function (e.g., `escHtml`, `escapeHtml`, `sanitizeHtml`), verify it covers all 5 standard entities: `&` -> `&amp;`, `<` -> `&lt;`, `>` -> `&gt;`, `"` -> `&quot;`, `'` -> `&#39;`. Missing quote escaping causes confusing output when escaped text appears inside HTML attributes or quoted contexts. <!-- Source: post-mortem, second-brain #211, 2026-02-23 -->
- [ ] **Enum/union validation on request body fields.** When a route handler validates a string field that should be one of a closed set (feedback type, status, reason), validate against the shared enum/constant — not just `typeof === "string" && value.trim()`. Accepting any non-empty string bypasses the type system and persists unexpected values. <!-- Source: post-mortem, second-brain #211, 2026-02-23 -->
- [ ] **Render-phase setState detection.** Grep changed `.tsx` files for `if (...) set[A-Z]` patterns in the component function body (outside `useEffect`, `useCallback`, or event handlers). Calling `setState` during render violates React's "render must be pure" rule — it works in some cases but triggers lint errors (`useExhaustiveDependencies`) and is harder to reason about. Fix: move to `useEffect(() => { ... }, [trigger])`. Mechanical check: `grep -nE 'if\s*\(.*\)\s*\{?\s*set[A-Z]' *.tsx` then verify each match is inside an effect/handler, not the render body. <!-- Source: post-mortem, second-brain #215, 2026-02-24 -->
- [ ] **Instance-unique element IDs in reusable components.** Grep changed `.tsx` files for hardcoded `id="..."` and `name="..."` attributes. If the component can render multiple times on a page, static IDs collide — breaking `<label htmlFor>` associations, radio button grouping, and accessibility. Fix: suffix with a unique prop (e.g., `id={\`refine-textarea-${item.id}\`}`) or use React's `useId()`. Mechanical check: `grep -nE '(id|name|htmlFor)="[^"]*"' *.tsx` in changed files, verify each is unique per instance. <!-- Source: post-mortem, second-brain #215, 2026-02-24 -->
- [ ] **React key uniqueness for data-derived values.** When `key={value}` in `.map()` uses a data-derived value (not an ID), verify the value is unique within the list. Duplicate keys cause React to skip re-renders or mount/unmount incorrectly. Common trap: `key={item.name}` when names repeat. Fix: use a unique ID, or a composite key like `key={\`${index}-${item.name}\`}` when no stable ID exists. Mechanical check: find `key={` in changed `.tsx` files, trace the value source, ask "can two items in this array have the same value?" <!-- Source: post-mortem, second-brain #215, 2026-02-24 -->

---

## Tier 4: Data Integrity & Architecture

- [ ] **Type sync between SQL and TypeScript.** CHECK constraints and unions match. Verify "source of truth" comments agree on directionality — if both files claim to be canonical, they'll diverge. Pick one (usually the TypeScript type) and have the other reference it. <!-- Strengthened: PR review, second-brain #191, 2026-02-20 -->
- [ ] **Migration-gated defensive filtering.** When removing a value from a type union/CHECK constraint AND gating the DB cleanup on a manual migration, all queries that return rows of the affected type must defensively filter by supported types (`type IN ('A','B','C')` or `type <> 'REMOVED'`) until the migration is confirmed run. Without this guard, legacy rows surface at runtime and crash downstream code that no longer handles them. <!-- Source: post-mortem, second-brain #191, 2026-02-20 -->
- [ ] **Trigger event scope.** For triggers that auto-manage derived timestamps (e.g., `completed_at`), verify they fire on `INSERT OR UPDATE`, not just `UPDATE`. UPDATE-only triggers silently skip direct INSERTs with terminal status (test data, manual migrations). Compare with sibling state-machine triggers in the same schema for consistency. <!-- Source: PR review, second-brain #206, 2026-02-22 -->
- [ ] **Partial unique index + ON CONFLICT compatibility.** When the schema uses a partial unique index (`CREATE UNIQUE INDEX ... WHERE condition`), verify that any client-side upsert's `onConflict` target can actually match it. PostgREST / Supabase `onConflict: 'col1,col2'` maps to `ON CONFLICT (col1, col2)` without a WHERE clause, which Postgres cannot resolve against a partial index. Fix: use a full (non-partial) unique index and include the discriminator column in `onConflict`. <!-- Source: PR review, folio #1, 2026-02-23 -->
- [ ] **Realtime subscription coverage.** When tables are published to Supabase Realtime (`ALTER PUBLICATION ... ADD TABLE`), verify the client subscribes to ALL published tables. Derived tables recomputed via RPC are easy to miss. <!-- Source: PR review, folio #1, 2026-02-23 -->
- [ ] **Index coverage for new queries.** New WHERE patterns covered by existing indexes.
- [ ] **FTS coverage.** New searchable text columns in the GIN index.
- [ ] **Pattern siblings.** Grep entire codebase for other instances of same pattern.
- [ ] **Fallback path semantic parity.** When a new primary code path coexists with a legacy fallback (e.g., `if (newService) { ... } else { /* old path */ }`), verify the fallback matches the new path's semantics for every parameter -- especially `null` vs `undefined` vs empty-string distinctions. All 3 post-push findings on PR #197 were fallback divergence issues that the local review missed. <!-- Source: post-mortem, second-brain #197, 2026-02-20 -->
- [ ] **Business logic in service, not routes.** Route does more than extract → call → return? Refactor.
- [ ] **At-most-once dedup markers BEFORE the action.**
- [ ] **Async initialization ordering.** New services depend on others being ready? Await them.
- [ ] **Timezone consistency: resolve once, pass through.** When a codepath needs both a timezone and a today-string, derive them from a SINGLE source. If `getLocalToday()` uses one default and `this.deps.userTimezone` uses another, they can silently diverge. Resolve timezone first, then derive the date from it.
- [ ] **Reuse existing DB pools.** Don't create ad-hoc `pg.Pool` for a single query when a service already has a pool. Add the method to the service interface instead. Ad-hoc pools leak connections and bypass service abstractions.
- [ ] **Transaction client affinity.** When a method acquires a `pool.connect()` client and runs `BEGIN` + `SELECT ... FOR UPDATE`, ALL subsequent queries on locked rows MUST use the same client — not `pool.query()`. `pool.query()` checks out a different connection, which blocks on the row lock held by the first connection, causing deadlock. Mechanical check: for each `pool.connect()` / `BEGIN` block, trace every `await` inside the transaction and verify none call `this.pool.query()` or any method that does. Accept methods that take a `txClient` parameter are safe; methods that use their own `this.pool` reference are not. <!-- Source: PR review, second-brain #250, 2026-02-25 -->
- [ ] **In-memory state survives restarts?** If a scheduler or service uses in-memory state for dedup (e.g., `lastSentDate`), verify it handles server restarts. On deploy-on-push platforms, every deploy clears memory. Either persist to DB or initialize defensively (e.g., pre-set the marker if the scheduled time has passed).
- [ ] **Documentation sync.** JSDoc matches code. Step counts updated. Module headers mention new capabilities. **On removal PRs:** grep docs for numeric counts and universal claims (e.g., "seven intents", "all entry types", "every channel") that reference the removed entity — these silently go stale. **On docs-only PRs with cross-references:** verify every section reference in the diff (e.g., "Section 3.3.1", "see Section 7") points to an existing section in the target document; verify removal annotations (strikethrough, UPDATE notes) are applied consistently to ALL instances of the removed entity across the spec, not just the first occurrence. <!-- Strengthened: post-mortem, second-brain #191, 2026-02-20; second-brain #232, 2026-02-25 -->
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

1. **Were any bugs fixed in this PR?** If yes, update `docs/features/_cross-cutting/bugs.md` (or the relevant feature's `bugs.md`) AND the relevant `~/.claude/knowledge/*.md` topic file.
2. **Were any architectural decisions made?** If yes, update `docs/features/_cross-cutting/decisions.md` (or the relevant feature's `decisions.md`) AND `~/.claude/knowledge/architecture-patterns.md` if the pattern is generalizable.
3. **Were any new defensive patterns discovered?** If yes, update the relevant knowledge topic file.
4. **Is there a pattern in this PR that would have prevented a bug in a sibling project?** If yes, capture it in the appropriate knowledge file.

Only after confirming learning capture, write the marker **outside the repo** to avoid git tracking conflicts:
```bash
PROJECT_HASH=$(echo -n "$PWD" | md5 -q 2>/dev/null || echo -n "$PWD" | md5sum 2>/dev/null | cut -d' ' -f1)
mkdir -p "$HOME/.claude/review-markers"
git rev-parse HEAD > "$HOME/.claude/review-markers/$PROJECT_HASH"
```

---
*Sources: second-brain (26 mechanical checks from PR #23-#59), lexica, command-center*
