# Adversarial Review Checklist

Run by a DIFFERENT agent than the code author. Execute each step mechanically — do not glance and move on.

Full rationale and incident history: `adversarial-review-evidence.md`.

---

## Targeted Review — Classify First, Then Run Only What Applies

### Step 1: Classify changed files

Run `git diff main...HEAD --name-only` and classify:

| Category | File patterns |
|---|---|
| **async-ts** | `.ts`/`.js` with `async`, `await`, `.catch`, `.then`, `Promise` |
| **routes-api** | `routes/`, `commands/`, `controllers/`, HTTP/bot handlers |
| **db-sql** | SQL queries, schema, migrations, pg/Knex/Prisma |
| **ui-react** | `.tsx`/`.jsx`, React components, CSS/styled-components |
| **shell** | `.sh` files, or `.ts`/`.js` spawning child processes |
| **llm** | LLM API calls, prompt building, LLM output parsing |
| **config-env** | `.env*`, config modules reading `process.env` |
| **test-only** | `__tests__/`, `*.test.*`, `*.spec.*` only |

### Step 2: Semantic change classification

Grep `git diff main...HEAD` for these signals:

| Signal | Detection pattern | Tag |
|---|---|---|
| Introduces restriction | `includes(`, `has(`, `new Set(`, `VALID_`, `ALLOWED_` | `restriction-introduced` |
| Adds validation | `return res.status(400)`, `throw.*[Ii]nvalid` | `validation-added` |
| Changes enum/union | New literal in `type.*=.*\|`, `enum {` | `enum-changed` |
| Removes a value | Deleted enum/union members, removed Set/array items | `value-removed` |
| Changes error behavior | `throw` added where `return null`/`return []` existed | `error-behavior-changed` |
| Migration-gated change | Schema change + runtime filter, manual migration ref | `migration-gated` |

### Step 3: Pattern-triggered checklist injection

| Tag | Auto-injected items | Forced question |
|---|---|---|
| `restriction-introduced` | Tier 4: Migration-gated defensive filtering, Fallback path semantic parity | "What happens to existing data that doesn't match the new restriction?" |
| `validation-added` | Tier 3: Newly-throwing functions caller audit | "Which callers now receive errors they didn't before?" |
| `enum-changed` | Tier 3: New union member completeness | "List every switch/map/conditional that handles this type." |
| `value-removed` | Tier 4: Documentation sync, Type sync | "Where is the removed value still referenced?" |
| `error-behavior-changed` | Tier 3: Newly-throwing functions caller audit | "Trace every caller — do they handle the new error path?" |
| `migration-gated` | Tier 4: Migration-gated defensive filtering | "What query results include legacy data until migration runs?" |

Forced questions require specific evidence or justified N/A with grep output.

### Step 4: Run only matching sections

| Category | Sections |
|---|---|
| **async-ts** | Tier 0: 0.21. Tier 1: all (1.1-1.3). Tier 3: null guards, error message specificity |
| **routes-api** | Tier 2: all. Tier 4: business logic in service not routes |
| **db-sql** | Tier 2: user scoping. Tier 4: type sync, index coverage, FTS, reuse DB pools, guard after create->reload, trigger event scope, transaction client affinity |
| **ui-react** | Tier 0: 0.4, 0.4b, 0.5, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.20, 0.22, 0.24. Tier 1: 1.4, 1.5, 1.6, 1.7. Tier 3: SVG/a11y, button type audit, new union member completeness, conditional UI branch tests, hook error states, escape in edit-within-panel, stale closure, render-phase setState, instance-unique IDs, React key uniqueness, click propagation, key-based state reset, isMountedRef strict-mode safety, CSS token consistency, CSS property interaction audit, HTML semantic element content model, error guard requires recovery path |
| **shell** | Tier 2: shell command validation |
| **llm** | Tier 2: escape user content in AI prompts. Tier 3: LLM output parsing |
| **config-env** | Tier 3: env var validation, JSON.parse on external config |
| **test-only** | Tier 3: UTC suffix in test Date strings, test env isolation, error branch coverage, test mock target verification, full object shape assertions |

**Always run:** Tier 0 automated greps, Tier 4: pattern siblings + documentation sync + architecture self-review (100+ LOC). Learning Capture Gate.

**Always skip for code review:** Tier 5 (plans only).

### Checklist Item Cap: 15-20 per PR

Priority when >20 items: Tier 0 (always, uncapped) > semantic-triggered items > Tier 1-2 > Tier 3 > Tier 4. Record deferred items in PR body.

### Step 5: Structured evidence per item

Format: `PASS/FAIL/SKIP: [item name] — [verifiable evidence]`

Evidence requirements:
- Grep items: paste command AND output
- Caller tracing: list each caller by file:line
- Pattern siblings: grep command + files matched + disposition
- Test coverage: list test case names + what they cover

Banned: "looks fine", "appears correct", "no issues found", "checked and OK"

### Step 6: Default to fix

Fix every finding immediately. Only valid skip: requires changes outside the current diff (file an issue).

---

## Tier 0: Automated Grep Checks (Run FIRST)

**Use the script:** `~/.claude/tools/tier0-audit.sh --repo /path/to/repo --base main`

Exits 1 = findings. Review marker cannot be written until exit 0. Individual patterns below for reference.

### 0.1 UTC suffix on Date strings
```bash
git diff main...HEAD --name-only -- '*.ts' '*.tsx' | xargs grep -nE 'new Date\("[^"]*T[0-9]{2}:[0-9]{2}:[0-9]{2}"\)' 2>/dev/null
```
Fix: append `Z`.

### 0.2 Fire-and-forget without .catch()
```bash
git diff main...HEAD -U0 -- '*.ts' '*.tsx' | grep -E '^\+.*\b(then|finally)\(' | grep -vE '\.catch\(' 2>/dev/null
```

### 0.3 Generic error swallowing
```bash
git diff main...HEAD -U3 -- '*.ts' '*.tsx' | grep -B3 -A1 'catch' | grep -E 'return \[\]|return null|return undefined' 2>/dev/null
```

### 0.4 Non-semantic interactive elements (a11y)
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -nE 'role=\{?.*"button"' 2>/dev/null
```
Fix: replace `<span/div role="button">` with `<button type="button">`. Exception: elements containing `<a>` children.

### 0.4b Form inputs without accessible labels
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -nE 'placeholder=' 2>/dev/null | while read line; do
  file=$(echo "$line" | cut -d: -f1); lineno=$(echo "$line" | cut -d: -f2)
  grep -A2 "$(sed -n "${lineno}p" "$file")" "$file" | grep -qE 'aria-label|htmlFor|aria-labelledby' || echo "MISSING LABEL: $line"
done
```
Also check icon-only buttons (text is only a symbol like "+", "x") for `aria-label`.

### 0.5 Escape handler only on textarea (not container)
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -lE 'onKeyDown.*Escape|Escape.*handleEdit' 2>/dev/null | while read f; do
  grep -L 'onKeyDownCapture' "$f" 2>/dev/null
done
```

### 0.6 Date comparison without validity check
```bash
git diff main...HEAD -U5 -- '*.ts' '*.tsx' | grep -B5 -E 'new Date\(' | grep -E '(>|<|>=|<=)\s*new Date' 2>/dev/null
```
Verify each has `Number.isFinite()` or `isNaN()` guard.

### 0.7 Infinite CSS animations without prefers-reduced-motion
```bash
git diff main...HEAD --name-only -- '*.css' '*.tsx' | xargs grep -l 'animation:.*infinite' 2>/dev/null | while read f; do
  if grep -A10 'animation:.*infinite' "$f" | grep -q '@media (prefers-reduced-motion: reduce)'; then true; else echo "MISSING REDUCE: $f"; fi
done
```
Fix: add `@media (prefers-reduced-motion: reduce) { animation: none !important; }`.

### 0.8 SVG `<title>` inside labeled buttons
```bash
git diff main...HEAD --name-only -- '*.tsx' | while read f; do
  grep -n '<svg' "$f" | while read svgline; do
    svglineno=$(echo "$svgline" | cut -d: -f1)
    if sed -n "${svglineno},$((svglineno+3))p" "$f" | grep -q '<title>'; then
      parentlines=$(sed -n "1,${svglineno}p" "$f" | tail -20)
      if echo "$parentlines" | grep -qE '<(button|a).*aria-label'; then
        echo "DUPLICATE A11Y: $f:$svglineno (SVG <title> with labeled parent)"
      fi
    fi
  done
done
```
Fix: remove `<title>`, add `aria-hidden="true" focusable="false"` to `<svg>`.

### 0.9 Truthiness guard on string input (missing .trim())
```bash
git diff main...HEAD -U0 -- '*.ts' '*.tsx' | grep -E '^\+' | grep -E 'if\s*\(\s*!(\w+)\s*\)' | grep -vE '\.trim\(\)' 2>/dev/null
```
Whitespace-only strings are truthy in JS. Fix: use `!variable?.trim()`.

### 0.10 Raw interpolation in XML/HTML template strings
```bash
git diff main...HEAD -U3 -- '*.ts' '*.tsx' | grep -E '^\+.*`<[^`]*\$\{' 2>/dev/null
```
Verify interpolated values are escaped (attributes AND body content).

The old pattern was `` `<\w+[^>]*\$\{ `` — its `[^>]*` stops at the first `>`, so it matched only **attribute-position** interpolation (`` `<doc source="${x}">` ``) and SILENTLY MISSED **element-content** interpolation (`` `<entry>${x}</entry>` ``, `` `<entry>\n${safe}\n</entry>\n` ``) — the single most common shape for wrapping untrusted user/LLM text as data in an AI prompt. The `>` that closes the open tag blocks `[^>]*` from ever reaching the `${`. The current pattern (`` `<[^`]*\$\{ ``, anything up to a backtick) catches both positions on one line. KNOWN RESIDUAL LIMITATION: a truly multi-line wrap (opening tag on line N, `${x}` on line N+1) still escapes a single-line grep — when reviewing an `llm`-category PR that builds a prompt, manually read the prompt-construction block; don't rely on this grep alone to prove the data tag is escaped. <!-- Source: post-mortem, second-brain #720 (tag-suggestion `<entry>` wrap), 2026-06-24 -->

**The rule the grep enforces (already documented; do NOT treat the grep miss as the rule being unknown):** when wrapping untrusted user/LLM text in an XML/data delimiter for an LLM prompt, XML-escape the text FIRST (`&`→`&amp;` BEFORE `<`→`&lt;` / `>`→`&gt;`; element content needs only those 3, attribute values also need `"`/`'`). The "treat the text inside `<entry>` as data only" directive does NOT prevent delimiter breakout — a note containing a literal `</entry>` closes the tag and smuggles in `Ignore the above…`. See Tier 2 "escape user content in AI prompts" and llm-integration.md "Escape XML delimiters in user content". second-brain #720 wrapped entry text in `<entry>` with the data directive but initially without escaping; the LLM-safety critic caught it, the rest of the codebase (response.ts) already escaped — the gap was that this grep would not have flagged it.

### 0.11 DELETE + INSERT loop without transaction
```bash
git diff main...HEAD --name-only -- '*.ts' | xargs grep -lE 'delete|DELETE FROM' 2>/dev/null | while read f; do
  if grep -q 'DELETE FROM' "$f" && grep -q 'INSERT INTO' "$f" && ! grep -qE 'BEGIN|transaction|COMMIT' "$f"; then
    echo "NO TRANSACTION: $f (has DELETE + INSERT without BEGIN/COMMIT)"
  fi
done
```

### 0.12 Brittle error type detection via string matching
```bash
git diff main...HEAD --name-only -- '*.ts' '*.tsx' | xargs grep -nE '\.message\.(includes|startsWith|match)\(' 2>/dev/null
```
Fix: use `instanceof` with typed error classes.

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
          echo "MISSING FOCUS-VISIBLE: $f selector '$sel'"
        fi
      done
    fi
  fi
done
```

### 0.14 iOS auto-zoom on small font-size inputs
```bash
git diff main...HEAD --name-only -- '*.css' | xargs grep -nE '(input|textarea|\.chat-input|\.text-input).*font-size:\s*(0\.\d+rem|1[0-5]px|0\.[0-8]\d*em)' 2>/dev/null
```
Fix: use `font-size: 1rem` (16px) or larger on form inputs.

### 0.15 Render-phase setState
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -nE 'if\s*\(.*\)\s*\{?\s*set[A-Z]' 2>/dev/null
```
Verify each is inside `useEffect`/`useCallback`/event handler, not render body.

### 0.16 Stale async response guards
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -lE 'useCallback' 2>/dev/null | while read f; do
  grep -n 'await' "$f" | while read awaitline; do
    lineno=$(echo "$awaitline" | cut -d: -f1)
    tail_lines=$(sed -n "${lineno},\$p" "$f" | head -10)
    if echo "$tail_lines" | grep -qE 'set[A-Z]'; then
      if ! grep -qE 'isMountedRef|currentKeyRef|abortController|signal' "$f"; then
        echo "STALE ASYNC: $f:$lineno (setState after await without mount/key guard)"
      fi
    fi
  done
done
```

### 0.17 Conditional UI branch completeness
```bash
git diff main...HEAD --name-only -- '*.tsx' | xargs grep -nE 'if\s*\(\s*(is|has|show|hide|can)[A-Z]' 2>/dev/null
```
Verify test file has cases for BOTH true and false branches.

### 0.18 Undefined CSS custom properties
```bash
for f in $(git diff main...HEAD --name-only -- '*.css'); do
  used=$(git diff main...HEAD -- "$f" | grep '^+' | grep -v '^+++' | grep -oE 'var\(--[a-zA-Z0-9_-]+' | sed 's/var(//g' | sort -u)
  defined=$(grep -oE -- '--[a-zA-Z0-9_-]+:' "$f" | sed 's/:$//' | sort -u)
  for var in $used; do
    echo "$defined" | grep -Fxq -- "$var" || echo "UNDEFINED CSS VAR: $f uses $var"
  done
done
```
False positives: variables set via JS `style.setProperty`. CI-enforced in projects with `stylelint-value-no-unknown-custom-properties`.

### 0.19 white-space pre-wrap + line-clamp co-occurrence
```bash
for f in $(git diff main...HEAD --name-only -- '*.css' '*.tsx' '*.jsx'); do
  has_prewrap=$(grep -lE 'white-space:\s*(pre-wrap|pre-line)' "$f" 2>/dev/null)
  has_clamp=$(grep -lE '(-webkit-)?line-clamp' "$f" 2>/dev/null)
  if [ -n "$has_prewrap" ] && [ -n "$has_clamp" ]; then
    echo "CONFLICT: $f has both white-space:pre-wrap/pre-line AND line-clamp"
    grep -nE 'white-space:\s*(pre-wrap|pre-line)|(-webkit-)?line-clamp' "$f"
  fi
done
```

### 0.20 Animation without prefers-reduced-motion
```bash
for f in $(git diff main...HEAD --name-only -- '*.css' '*.tsx' '*.jsx'); do
  has_animation=$(grep -lE '^\s*animation\s*:' "$f" 2>/dev/null)
  has_reduced_motion=$(grep -lE 'prefers-reduced-motion' "$f" 2>/dev/null)
  if [ -n "$has_animation" ] && [ -z "$has_reduced_motion" ]; then
    echo "MISSING reduced-motion: $f has animation: but no prefers-reduced-motion query"
    grep -nE '^\s*animation\s*:' "$f"
  fi
done
```

### 0.21 `hour12: false` in Intl.DateTimeFormat
```bash
git diff main...HEAD -- '*.ts' '*.tsx' '*.js' '*.jsx' | grep -n 'hour12:\s*false' || echo "PASS: no hour12: false"
```
Fix: replace with `hourCycle: "h23"`. Do NOT set both.

### 0.22 autoFocus attribute (a11y)
```bash
git diff main...HEAD -- '*.tsx' '*.jsx' '*.html' | grep -n 'autoFocus\|autofocus' || echo "PASS: no autoFocus"
```
Fix: remove autoFocus, manage focus programmatically on user action.

### 0.23 Express JSON body parser without size limit
```bash
git diff main...HEAD -- '*.ts' '*.js' | grep -n 'express\.json()' | grep -v 'limit' || echo "PASS: all express.json() have limit"
```
Fix: set `limit` to minimum needed (e.g., `'8kb'`).

### 0.24 Nested interactive elements (a11y)
```bash
git diff main...HEAD --name-only -- '*.tsx' '*.jsx' | while read f; do
  awk '/<button|role=.*"button"/{if(depth>0){print "NESTED INTERACTIVE: "FILENAME":"NR" — <button> inside interactive parent (line "parent_line")"; found=1} depth++; parent_line=NR} /<\/button>|<\/div>/{if(depth>0) depth--} END{if(!found) exit 1}' "$f" 2>/dev/null
done
```
Browsers silently strip nested `<button>` elements — the inner button won't render or be clickable. Fix: change the outer element to `<div role="button" tabIndex={0}>` with `onKeyDown` for Enter/Space. <!-- Source: post-mortem, second-brain #499, 2026-03-28 -->

### 0.25 Unicode glyph icons in buttons (a11y + cross-platform)
```bash
git diff main...HEAD --name-only -- '*.tsx' '*.jsx' | xargs grep -nE '>[★♥✕↑↓●♡♠♣◆▲▼◀▶✓✗✕×]<' 2>/dev/null
```
Ad-hoc Unicode glyphs inside buttons/spans render inconsistently across fonts/OSes and produce uneven baselines next to text labels. Fix: replace with inline `<svg aria-hidden="true" focusable="false">` icons; ensure parent has `aria-label`/`<title>`. When fixing, sibling-sweep the entire feature area in the same PR. <!-- Source: post-mortem, remodel-hq #83, 2026-05-15 -->

### 0.26 User/LLM content interpolated into Markdown without escaping
```bash
git diff main...HEAD -- '*.ts' '*.js' | grep -nE '`(#{1,6} |[-*] |\[).*\$\{' || echo "PASS: no raw interpolation into Markdown structural prefixes"
```
Any user- or LLM-generated string written into a Markdown heading (`## ${title}`), bullet (`- ${content}`), or link label (`[${label}]`) can forge document structure: an embedded newline + `## ` injects a sibling heading, a newline + `- ` injects a list item, and a `]` closes a link span early. This is the Markdown analogue of the XML/HTML raw-interpolation check (0.10), and is HIGHEST risk for LLM-emitted fields (summaries, captions) written into a trusted/exported document a human or downstream AI will read. Fix: route every dynamic value through an `inlineText` helper (collapse newlines to spaces so it stays on its structural line) or an `inlineCode` helper (backtick-fenced + CommonMark padding so embedded backticks can't break the span); escape `[`/`]` in link labels. When you fix ONE site, sibling-sweep every other place dynamic content lands in Markdown (second-brain #693 found 6 more sites after the first fix, including an LLM-generated inbox summary). <!-- Source: post-mortem, second-brain #693, 2026-06-23 -->

### 0.27 Secret/connection-string passed as a subprocess argv
```bash
git diff main...HEAD -- '*.ts' '*.js' | grep -nE '(execFile|spawn|exec|execSync)\(' -A3 | grep -nE '(DATABASE_URL|connectionString|password|PG(PASS|PASSWORD)|token|secret|api[_-]?key)' || echo "PASS: no secrets on subprocess argv"
```
A secret or DB connection-string (with password) passed as a command-line argument to a child process is visible to ANY local user via `ps`/`/proc/<pid>/cmdline` for the process's whole lifetime. second-brain #693: `pg_dump <connstring-with-password>` leaked the DB password on argv. Fix: pass secrets through the child's ENVIRONMENT (for libpq tools, parse the URL into `PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD`/`PGDATABASE`/`PGSSLMODE` env vars), never as an argv element; prefer `execFile` with an `env:` option over a shell string. Manual-confirm hits (the grep flags proximity, not proof). <!-- Source: post-mortem, second-brain #693, 2026-06-23 -->

### 0.28 Size cap enforced AFTER fully buffering a remote body
```bash
git diff main...HEAD -- '*.ts' '*.js' | grep -nE '\.(arrayBuffer|buffer|text|blob)\(\)' -A4 | grep -nE '(length|size|byteLength|maxBytes|cap|limit) *[<>]=?' && echo "REVIEW: size check appears AFTER full-body buffering — verify it streams" || echo "PASS"
```
A `maxBytes`/size check applied to the result of `response.arrayBuffer()`/`.buffer()`/`.text()` runs too late — the entire body is already in memory, so a misbehaving or hostile server (especially when redirects are followed) can OOM the process before the cap is ever evaluated; concurrency multiplies it. second-brain #693: the 25MB media cap was checked only after `arrayBuffer()` buffered the whole download, at x5 concurrency. Fix: reject early on an oversized `Content-Length`, then read `response.body` as a STREAM and abort the moment the running byte total exceeds the cap (fall back to a still-capped buffered read only when no stream is available); cancel the response body on every early-return path so the socket is reclaimed. Memory must be bounded regardless of a dishonest or absent Content-Length. <!-- Source: post-mortem, second-brain #693, 2026-06-23 -->

### 0.29 Changed source file git classifies as binary (NUL byte / control char in source)
```bash
git diff main...HEAD --name-only -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.json' '*.css' '*.md' '*.sql' | while read f; do
  [ -f "$f" ] || continue
  if LC_ALL=C grep -qP '\x00' "$f" 2>/dev/null; then echo "BINARY/NUL IN SOURCE: $f (contains a NUL byte — git will treat it as binary)"; fi
done
git diff main...HEAD --numstat -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.json' '*.css' '*.md' '*.sql' | awk '$1=="-" && $2=="-" {print "BINARY DIFF: "$3" (git shows - - / \"Bin\" — diff is unreviewable as text)"}'
```
A literal NUL (`\x00`) — or other control bytes — embedded in a text source file (e.g. `` `${a}\0${b}` `` used as a delimiter, a stray paste artifact) makes git classify the file as **binary**: `git show`/the GitHub PR diff render `Bin 0 -> N bytes` / `- -` numstat instead of a text diff, so the change is **unreviewable as text** and blame/diff are permanently degraded. CRITICAL: this class defeats EVERY other gate — Biome/ESLint, `tsc`, and the test run all pass (the byte is valid in a JS string and the code runs), and ALL text-based greps (including the rest of Tier 0) emit ZERO `+` lines for a binary blob, so they silently scan nothing. It also slips human/LLM review because the NUL renders invisibly (as a space). Fix: replace the control byte with an ordinary delimiter that is provably absent from both halves (for a `(uuid, canonical-name)` composite key a single space works — UUIDs have none and a canonical name that folds `[\s_]+`→`-` can't contain whitespace). Then re-verify `git show` renders a real text diff. <!-- Source: adversarial review, second-brain #748, 2026-06-26 — NUL delimiter in a TS grouping key passed lint/tsc/2300 tests + a 3-lens code review; only git's binary classification surfaced it -->

### Adding new patterns
Add when a bug class is caught 2+ times. Requirements: regex on changed lines, <20% false-positive rate.

---

## Tier 1: Recurring Blindspots

### 1.1 Fire-and-Forget Try/Catch Granularity
1. Find all `.catch()` call sites in changed files.
2. Read the called method's implementation.
3. Verify EACH `await` inside has its own try/catch.

### 1.2 Error Swallowing in Catch Blocks
1. Find all catch blocks in changed files.
2. For each: what error is EXPECTED (safe default) vs UNEXPECTED (must rethrow)?

### 1.3 Broad vs. Narrow Try/Catch Scope
1. Find all try blocks. Count `await` calls inside each.
2. If >1 await with different failure reasons, split them.

### 1.4 Grammar in User-Facing Text
1. Find template literals with count-dependent text.
2. Verify ALL dependent words: noun, pronoun, verb, determiner.

### 1.5 Optimistic UI Revert Safety
1. Find optimistic update patterns.
2. Catch/error path uses CAPTURED snapshot, not inverted value.
3. Staleness guard: revert only if current value matches optimistic value from THIS call.
4. User-visible error feedback after revert (toast, inline error).
5. Await async completion, not setTimeout heuristics.
6. Reset ALL local state (errors, loading, form inputs) on identity prop changes via `useEffect`.
7. **Optimistic-by-default is the default expectation for new write-path hooks.** Any new `use*` hook that exposes `add`/`update`/`delete`/`toggle`/`vote`/`favorite`/`pin`/`postNote`-style mutations for sub-100ms-perceived UI MUST be optimistic-by-default. Pessimistic implementations require a one-line justification in the PR body. Repeated adoption across vote, favorite, note-add, note-delete, image-delete, pin, updateImageCategory (PRs #83/#85/#86) confirms this is house style, not aspiration. <!-- Source: post-mortems, remodel-hq #83/#85/#86, 2026-05-15/16 -->
8. **Cross-surface cache notifier coverage.** When a derived cache (e.g., `noteCounts` Map) is mutated on Surface A, every other surface that can mutate the same underlying entity MUST wire the same notifier. Sibling-sweep across all UI surfaces that list the item before approving. <!-- Source: post-mortem, remodel-hq #86, 2026-05-16 -->
9. **Callback identity churn from mutating list in deps.** `useCallback((...) => { /* reads images */ }, [..., images])` re-creates the callback on every list mutation, defeating downstream memo. Use a fresh `ref` or functional setter to snapshot inside the body and drop the list from deps. Three repeat occurrences across PRs #83/#85/#86 — Tier 0 grep candidate: `useCallback\([^,]*, \[[^\]]*\b(images|items|list|notes)\b[^\]]*\])`. <!-- Source: post-mortems, remodel-hq #83/#85/#86 -->

### 1.6 Portal/Popover Positioning
1. Position recalculated on scroll/resize (or popover closes on scroll/resize).
2. Left/top clamped to avoid off-screen positioning.

### 1.7 Interactive Mode State Cleanup
1. When entering one interactive mode, all competing modes are reset.
2. Check: "If mode A is active and user triggers mode B, does A get cleaned up?"
3. **New message-trigger gate on a shared input path must narrow its match AND persist input on every non-completing branch.** When a PR adds a detector/interceptor to a shared message handler (URL detector, command prefix, keyword gate), verify two things: (a) the trigger is narrow enough not to capture unrelated messages — a "message *contains* X" match will hijack a longer sentence that merely mentions X; require "message *is essentially* X" (or an explicit command form) so normal capture still falls through; (b) EVERY branch that doesn't complete the flow (cancel/decline, unreadable/invalid target, reserved/duplicate, stale/expired) still persists the user's original input as a normal entry and says so — a confirm gate that drops the pasted content on cancel is silent data loss. Enumerate the non-completing branches explicitly and give each a persistence test. <!-- Source: post-mortem, second-brain #873, 2026-07-10 — critic caught a Sheets-URL connect gate that hijacked any message containing a URL and dropped it on cancel -->

---

## Tier 2: Security & Data Isolation

- [ ] **User scoping on ALL DB queries.** Every SELECT/UPDATE/DELETE includes `WHERE user_id = $X`. Check correlated subqueries.
- [ ] **No raw user content in logs.** Log timing, counts, IDs — never message content.
- [ ] **Input validation at boundaries.** `typeof` guard before `.trim()`. For numeric params: `Number.isNaN()` explicitly, not `parseInt(...) || default` (treats `0` as falsy).
- [ ] **Shell command validation.** Regex: `\b` not `^` (no prefix bypass), `(\s|$)` not `\b` (no suffix bypass). Guard ordering: early-exit blocks don't make later paths unreachable.
- [ ] **Escape user content in AI prompts.** Escape `<`/`>` with `&lt;`/`&gt;` in XML prompts. Verify both XML-structural escape AND prompt-level framing treating data as read-only.
- [ ] **RLS UPDATE policies have WITH CHECK.** `USING` alone allows writing unauthorized values. `WITH CHECK` must mirror tenant-scoping.
- [ ] **No token-like placeholders in UI.** No `ghp_`, `sk-`, `Bearer ey...`, `xoxb-` in placeholder/mock data. Use `"........"` or `"(hidden)"`.
- [ ] **Auth fallbacks scoped to specific routes.** Query param/cookie auth gated on `req.method` + `req.path`, not global middleware.
- [ ] **Content-Type enforcement on mutation endpoints.** POST/PUT handlers verify `Content-Type: application/json` (or return 415).
- [ ] **Cross-platform path traversal validation.** Reject `/`-prefixed, `C:\`, `\\server\share`, and `path.isAbsolute()`.

---

## Tier 3: Robustness & Graceful Degradation

- [ ] **Null/undefined guards.** Walk every `!`, `[]`, `.` chain for null intermediates.
- [ ] **LLM output parsing.** `JSON.parse()` strips code fences. Handle empty/malformed.
- [ ] **LLM output rendered into HTML requires adversarial-input test.** If the PR adds a code path that renders LLM-generated text into HTML (e.g., a new section in an email or web view sourced from a model response), require at least one test that feeds the renderer adversarial output — `<script>`, `<img onerror=`, malformed markdown bold/italic, partial tags — and asserts escape. System-prompt framing and code-fence stripping are NOT sufficient; the renderer is the last line of defense and must be proven independently. <!-- Source: post-mortem, family-digest #34, 2026-05-14 -->
- [ ] **User/LLM content rendered into a Markdown/text DOCUMENT can forge structure — fence or single-line EVERY field, not just the obvious ones.** When the PR builds a `.md`/text artifact (export, digest, report) from user- or LLM-authored fields, audit every interpolation: a value with `\n## ` or `\n- ` injects a real heading/list item; a multi-line value on a `- ${x}` bullet escapes the bullet; a backtick breaks an inline-code span; a `]` breaks a `[label](url)`. Free-form bodies need a fence whose backtick run is longer than any inside the text (`max(3, longestRun+1)`); short fields on a bullet/heading/inline-span need newline-collapse (`replace(/\s+/g," ").trim()`) and, for inline code, a backtick-safe delimiter + CommonMark padding when the value starts/ends with a backtick; link labels need `[`/`]` escaped. Grep `lines.push(\`...\${...}\`)` for every content field and classify each — the LLM/user fields most easily missed are the ones rendered OUTSIDE the fenced helper (an AI summary line, a reflection bullet, a tag chip). Require an adversarial test per render context. <!-- Source: adversarial review, second-brain #690 (data export Markdown), 2026-06-23 -->

- [ ] **Error message specificity.** Edge cases get specific messages, not generic fallthrough.
- [ ] **Cross-field relational validation.** Multiple fields forming a sequence (start/end, date ranges) validated for relationship, not just format.
- [ ] **CSS grid column count sync.** `repeat(N, ...)` N matches actual data column count in the rendering component.
- [ ] **Semantic elements.** `role="button"` on non-button elements -> replace with `<button type="button">`. SVGs need `<title>`.
- [ ] **Button type audit.** Every `<button` needs explicit `type="button"` or `type="submit"`. Audit entire file, not just diff.
- [ ] **CSS token consistency.** Hardcoded hex/rgb that should use tokens. Duplicated color constants (2+ occurrences -> extract). Hex appending for opacity incompatible with CSS variables (use `color-mix`). Semantic role mismatch: `--*-text` only for `color`/`fill`, not `background`/`border`.
- [ ] **CSS property interaction: white-space + truncation.** `pre-wrap`/`pre-line` with `line-clamp`/`text-overflow` on same element. Content with `\n` defeats clamping.
- [ ] **CSS property interaction: prefers-reduced-motion completeness.** Override specificity matches base. Covers BOTH `animation` AND `transition`.
- [ ] **CSS property interaction: conditional class visual permutations.** All permutations of conditional classes render correctly. Base without conditional classes has acceptable styling.
- [ ] **CSS property interaction: sticky/fixed positioning ancestors.** Check for `overflow: hidden/auto/scroll` (breaks sticky), `transform`/`perspective`/`filter` (breaks fixed), `z-index` context.
- [ ] **CSS property interaction: overflow hidden child clipping.** Children with `box-shadow`, `:focus-visible` ring, or `transform: scale/translate` clipped by `overflow: hidden`. Fix: `overflow: clip` or padding.
- [ ] **CSS property interaction: transition/animation reduced-motion coverage.** All `transition:` and `animation:` in changed CSS have reduced-motion overrides.
- [ ] **New union member completeness.** Grep entire codebase for every switch/map/conditional on that type. Check validation Sets — split shared constants per purpose when semantics diverge.
- [ ] **Conditional UI branch test coverage.** Boolean-gated UI: tests for both true and false branches.
- [ ] **Escape in edit-within-panel.** Escape via `onKeyDownCapture` on edit container. Guard `if (saving) return`.
- [ ] **Hook error states surfaced in UI.** `{ data, loading, error }` — error rendered. Internal `load()` catch calls `setError(err)`. Success path calls `setError(null)`.
- [ ] **Env var validation.** NaN check, valid range, fallback logging. Timezone vars via `Intl.DateTimeFormat`.
- [ ] **Guard after create -> reload.** Check for null after DB insert + reload.
- [ ] **JSON.parse on external config.** Must be in try/catch with descriptive error.
- [ ] **Off-by-one in time boundaries.** Use `< nextDay T00:00:00` not `<= T23:59:59`.
- [ ] **Off-by-one in threshold comparisons.** `>` vs `>=` — does equality trigger the branch? Verify against spec.
- [ ] **Newly-throwing functions: caller audit.** When function gains `throw`, grep ALL callers and verify error handling.
- [ ] **Filter external API data before mapping.** `.filter()` before `.map()` for potentially malformed entries.
- [ ] **UTC suffix in test Date strings.** Append `Z`. Enforced by Tier 0 check 0.1.
- [ ] **Test env variable isolation.** `afterEach` captures/restores original `process.env` values. `vi.restoreAllMocks()` in `afterEach`, not inline.
- [ ] **Error branch test coverage.** Each distinct error path (timeout->504, upstream->502, not found->404) has a dedicated test.
- [ ] **String truncation arithmetic.** `slice_length + suffix_length <= limit`. HTML: truncate at line boundaries, strip partial tags.
- [ ] **Compound text decoration.** Format helpers returning decorated text — callers adding own decoration cause compounding: `((all day))`.
- [ ] **Stale closure in background refresh.** Cache-then-refresh `.then()` captures filter/key at call time. Guard with `currentKeyRef`. For racing refreshes, use monotonic token ref.
- [ ] **HTML semantic element content model.** `<output>` only permits phrasing content. `<details>` requires `<summary>` first child. Verify children are permitted.
- [ ] **Error guard requires recovery path.** `if (error) return` before retry logic needs manual recovery mechanism (retry button). Otherwise: permanent stuck state.
- [ ] **Test mock target verification.** Trace `vi.spyOn`/`vi.fn` to the actual production code path. Common failure: mocking wrong sibling method.
- [ ] **Full object shape assertions.** Assertions cover full shape (text, labels, IDs), not just callback data.
- [ ] **Exact-value assertions over format-only assertions for derived keys.** When tests assert a derived key (e.g., ISO `weekKey`, dedupe key, hash output), assert the exact expected value, not just the format/regex shape. Format-only assertions (`/^\d{4}-W\d{2}$/`) miss off-by-one errors at boundary days (ISO year boundaries, month-end, DST transitions). Pin the literal value alongside the format check. <!-- Source: post-mortem, family-digest #12, 2026-04-22 -->
- [ ] **Error-path coverage per new entry point.** Every newly-added entry point (CLI subcommand, route handler, message handler, scheduler trigger) needs at least one error-path test in addition to the happy path. Test the dispatcher itself: unknown subcommand, missing required arg, wrong arg type. <!-- Source: post-mortem, family-digest #12, 2026-04-22 -->
- [ ] **Boundary value test coverage.** Threshold logic: test at threshold, one below, clearly above.
- [ ] **Side-effect ordering around fallible operations.** Side effects assuming success must go AFTER the await. Fallback-value-as-noop: compare returned value against previous before triggering side effects.
- [ ] **HTML entity completeness in custom escape helpers.** Must cover: `&`->`&amp;`, `<`->`&lt;`, `>`->`&gt;`, `"`->`&quot;`, `'`->`&#39;`.
- [ ] **Enum/union validation on request body fields.** Validate against shared enum/constant, not just `typeof === "string"`.
- [ ] **Render-phase setState detection.** `if (...) set[A-Z]` in component body outside effects/handlers -> move to `useEffect`.
- [ ] **Instance-unique element IDs.** Hardcoded `id`/`name` in reusable components -> suffix with unique prop or use `useId()`.
- [ ] **React key uniqueness.** `key={value}` in `.map()` — can two items have the same value? Use unique ID or composite key.
- [ ] **isMountedRef strict-mode safety.** Init to `false`, set `true` inside `useEffect` body. Never `useRef(true)`.

---

## Tier 4: Data Integrity & Architecture

- [ ] **Type sync between SQL and TypeScript.** CHECK constraints and unions match. Single source of truth documented.
- [ ] **Migration-gated defensive filtering.** Removed type values: all queries filter by supported types until migration confirmed.
- [ ] **Trigger event scope.** Auto-managed timestamps fire on `INSERT OR UPDATE`, not just `UPDATE`. Inter-terminal transitions: enumerate ALL terminal-to-terminal paths.
- [ ] **Partial unique index + ON CONFLICT compatibility.** `onConflict` without WHERE can't resolve partial indexes. Use full unique index.
- [ ] **Realtime subscription coverage.** All tables in `ALTER PUBLICATION` have client subscriptions. Check derived tables via RPC.
- [ ] **Index coverage for new queries.** New WHERE patterns covered by existing indexes.
- [ ] **FTS coverage.** New searchable text columns in GIN index.
- [ ] **Pattern siblings.** Grep entire codebase for same pattern. Same-file: fix now. Cross-module: file issue with `outside-diff` label.
- [ ] **Fallback path semantic parity.** Legacy fallback matches new path's semantics for every parameter (null vs undefined vs empty-string).
- [ ] **Business logic in service, not routes.** Route does more than extract -> call -> return? Refactor.
- [ ] **At-most-once dedup markers BEFORE the action.**
- [ ] **Async initialization ordering.** New services await dependencies before use.
- [ ] **Timezone consistency.** Resolve timezone once, derive date from it. No dual-source divergence.
- [ ] **Reuse existing DB pools.** No ad-hoc `pg.Pool` when service already has one.
- [ ] **Transaction client affinity.** After `pool.connect()` + `BEGIN`, ALL queries use same client. `pool.query()` inside transaction = deadlock.
- [ ] **In-memory state survives restarts?** Dedup state in memory lost on deploy. Persist to DB or initialize defensively.
- [ ] **Documentation sync.** JSDoc matches code. On removal PRs: grep docs for numeric counts and universal claims referencing removed entity. On docs PRs: verify section cross-references exist. On content-add PRs (new item joins a collection: character, prompt, dataset entry): update every index/roster/README that enumerates the collection, and grep sibling items for exclusive claims (superlatives like "tallest", "the only", reference anchors) the new item contradicts. <!-- Source: post-mortem, plush-press #20/#21, 2026-06-10 — 3 consecutive character PRs left the roster table stale -->
- [ ] **Cross-channel output regression.** Shared data consumed by multiple channels (web, Telegram, email, API) — all still render correctly.
- [ ] **Rendering-context font fallback.** Assets that render BEFORE the page's Google Fonts load (favicons, OG images, email templates) must include system-safe font fallbacks. `next/font` only loads in-page; the OS-level favicon preview will fall back to whatever the browser picks (often Times New Roman) and look meaningfully different from the in-page render. Either outline text to SVG paths in the favicon, or use a system serif like Georgia. <!-- Source: post-mortem, baby-name-picker #36, 2026-05-18 -->
- [ ] **Architecture self-review (100+ LOC or 3+ directories).** Right location? Right abstraction? Right boundary? Right scope? Understandable in 30 days?

---

## Tier 5: Product Adversarial Review (Plans Only)

- [ ] **Regex/pattern coverage.** 10 realistic user phrasings all match. 5 non-target phrasings none match.
- [ ] **Content quality after action.** Is resulting content useful as-is or needs editing?
- [ ] **Missing entry points.** Works from ALL surfaces (Telegram, web, future channels)?
- [ ] **Missing modifiers.** Can user customize (title, date, tags)? Will they expect to?
- [ ] **Undo path.** Can user reverse? If not, is action low-risk enough?
- [ ] **Edge case phrasings.** Exact failing phrase from bug report + 5 variations.
- [ ] **Downstream effects.** Related features still work after action?

---

## Gate-Tool Execution Verification

Before recording any lint/type/test gate as "passed," confirm the tool actually RAN — an error-exit is a fail, not a pass. A checkbox without captured output is unfalsifiable.

```bash
# The mandated lint binary must resolve. An "Cannot find module" / "command not found" is a FAIL.
npm run lint -- --version 2>&1 | grep -qiE 'error|cannot find|not found' && echo "GATE BROKEN: lint binary missing" || echo "lint resolvable"
```
Require the implementer to paste the gate's real summary line (`0 errors`, `N problems`, jest `Tests: N passed`), not a `[x]`. baby-name-picker #81 claimed `npx expo lint — no new findings` while `eslint` was absent from the project entirely (`expo lint` errored `Cannot find module 'eslint'` and ran zero rules) — a phantom gate that had silently passed on every prior PR.

## Post-Review: Learning Capture Gate

Before writing the marker file:

1. Bugs fixed? Update `docs/features/.../bugs.md` AND `~/.claude/knowledge/*.md`.
2. Architectural decisions? Update `decisions.md` AND `architecture-patterns.md`.
3. New defensive patterns? Update relevant knowledge topic file.
4. Pattern applicable to sibling project? Capture in knowledge file.

Write marker:
```bash
PROJECT_HASH=$(echo -n "$PWD" | md5 -q 2>/dev/null || echo -n "$PWD" | md5sum 2>/dev/null | cut -d' ' -f1)
mkdir -p "$HOME/.claude/review-markers"
git rev-parse HEAD > "$HOME/.claude/review-markers/$PROJECT_HASH"
```
