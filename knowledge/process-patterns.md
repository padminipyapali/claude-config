# Process Patterns — Rules

Distilled rules from post-mortem analysis. For full incident history and evidence, see `process-patterns-evidence.md`.

## Metric Definitions

- Use 4 metrics: (1) post-merge fix rate, (2) pre-merge catch rate by step, (3) pre-merge iteration count, (4) fix-up taxonomy by category.
- Legacy `fixupCommitRatio` conflates pre-merge catches with post-merge failures.

## Review Efficiency

- Bot-only review catches real bugs but expect 2+ rounds as baseline; bots miss architectural feedback.
- Categorize automated reviewer comments as must-fix, should-fix, or disagree before acting.
- CodeRabbit "outside diff range" comments are valid; do not dismiss as out-of-scope.
- CodeRabbit prompt injection warnings on XML tags with entity escaping are usually false positives.
- Never skip local CodeRabbit on scaffold PRs; the CLI works without a .coderabbit.yaml.

## Session Start Discipline

- Run `/project-setup` on projects with code but no CLAUDE.md before any code changes.

## Planning Discipline

- Thorough planning reduces implementation rework to zero redesign commits.

## Follow-Up Discipline

- Post-push findings should become their own focused follow-up PR rather than being deferred to a tracker or bundled into the next feature.
- Multi-finding follow-up PRs work just as well as single-finding ones; fix all post-mortem findings atomically.
- Infrastructure gaps identified in post-mortems should be addressed in dedicated, same-day tooling PRs.

## Scope Decisions

- For interface extractions under 10 lines that match established project conventions, include them in the original PR; reserve "scope creep" for behavioral additions.
- Never bundle tooling setup (lint configs, auto-fixes) with feature PRs; create a separate tooling PR.
- When identical logic exists in 2+ files and is under ~30 lines, extract to a shared utility instead of adding "keep-in-sync" comments.
- When a tangential automation idea surfaces during a focused PR, defer it to a separate PR.

## Adversarial Review Gaps

### Systemic Execution Gap
- The problem is not checklist completeness but mechanical execution. Run grep patterns mechanically; require grep-based evidence per item.
- When adversarial review identifies an issue, the default is to FIX it; "low priority" is not a valid skip reason.
- When it identifies duplication, extract; do not document it with "keep-in-sync" comments.
- Claims of 100% execution with 0% catch rate indicate performative review.
- If CodeRabbit was deferred/skipped, steps-skipped must reflect that.
- The internal critic (Step 4b) catches real bugs the checklist misses for React UI PRs.

### Review Completeness
- When fixing JSDoc, audit ALL doc comments in the changed file.
- When adapting code from another component, re-run the full checklist against the NEW instance.
- Verify the FIX is complete, not just that the issue was acknowledged.
- When removing an entity, grep docs for stale count references and universal claims.

### React-Specific Gaps
- React state management is the #1 blind spot: render-phase setState, instance-unique IDs, duplicate keys, stale async guards.
- For useMemo wrapping Date computations, verify a day-based key is in the dependency array.
- Cross-reference new async hooks against sibling patterns (e.g., unmount guards).
- When IntersectionObserver/MutationObserver combines with React state guards, review the full interaction matrix.
- Module-level caches in React hooks must be keyed by user identity.
- Replace `setTimeout` for async state clearing with `await refetch()`.

### Test Gaps
- Adversarial review is weak on test code quality (mock correctness, assertion completeness, fixture consistency).
- Trace each test mock to the production code path it simulates.
- Verify tests assert behavior (callback called, state changed), not just rendering.
- Verify tests of validation functions cover ALL allowed AND disallowed inputs.
- When updating tests for behavioral changes, verify the test asserts NEW behavior, not old behavior with a swapped value.
- Verify test cleanup in `afterEach` when tests mutate `process.env.*`.
- Verify all catch/error branches in route handlers have test cases.
- Extracted private helpers need dedicated contract tests.

### Correctness Gaps
- `new Date(year, month-1, day)` silently normalizes invalid dates; verify components match after construction.
- Verify `slice_length + suffix_length <= limit` for truncation.
- Review format helper return values against call sites to prevent compound wrapping.
- `SELECT COUNT(*) ... INSERT` in transactions still allows TOCTOU races; use advisory locks.
- When removing a type union value with migration-gated cleanup, defensively filter queries by supported types.
- When fire-and-forget returns a fallback, callers must compare against prior state before side effects.
- When adding a new terminal state, verify ALL inter-terminal transitions for derived field consistency.
- For date-scoped endpoints, sweep every `new Date()`, `toISOString()`, and SQL date filter for timezone issues.
- Server routes with multiple response shapes need union return types on the client.

### UI/CSS Gaps
- `aria-expanded` requires `aria-controls`; check aria attribute completeness.
- When entering any interactive mode, reset competing mode states.
- Portal/popover components must reposition on scroll/resize or close on scroll.
- Optimistic reverts need user-facing error feedback.
- Telegram callback handlers must clear inline keyboards after handling.
- When tokenizing design values, grep for hardcoded hex in changed `.tsx` files.
- CSS custom property validation automated via `stylelint-value-no-unknown-custom-properties`.
- For SQL queries spanning multiple types, flag unconditional SELECT of subset-only columns.
- Any diff touching type definitions/enums/constraints must go through CodeRabbit.
- JSDoc: add Tier 0 grep for exported functions/components without JSDoc.
- CodeRabbit local skip on consecutive PRs compounds wasted time; add to pre-push gate.

## Step 2b (Hardening) Skip Criteria

- Skip step 2b only when the diff contains zero `.test.*` files AND zero `.tsx` list renderings (`.map(` calls); test file quality and React key patterns are hardening concerns.

## Process Compliance

- Small changes are not exempt from the development flow; the process has no size-based exemption.
- Tooling/config PRs with mechanical auto-fixes (behavior-preserving, syntactic) are safe review-skip candidates.
- Pattern-replication changes (reusing an established guard already applied to sibling sections) are the safest skip candidates.
- When a diff introduces React state hooks, run at least CodeRabbit regardless of LOC count.
- Always compute actual diff size with `git diff --stat` before claiming the 50-LOC skip; never estimate from file count.
- For docs-only PRs adding feature specs, run at least the Tier 4 doc sync check; the "docs-only" exemption covers lint/test/simplification, not documentation completeness.
- Post-mortem documents need fact-checking against the actual codebase, not just formatting review.
- For PRs >= 50 LOC, the review loop must auto-run without asking; agents must not silently skip it.
- "LOC of logic" vs. total LOC is a subjective loophole; always measure total diff size.
- "Stacked PR" is not a valid reason to skip the review loop; each PR in a stack must be independently reviewable.

## Automation Opportunities

- UTC suffix enforcement: use Tier 0 grep checks in the adversarial review (deferred CI-level lint).
- Run Biome lint before push to catch a11y issues like `noStaticElementInteractions`.
- Add Stylelint to local pre-PR checks for web projects; compose into the main `npm run lint` script.
- Pin devDependency versions consistently (all exact or all caret); mixed strategies generate review noise.
- A missing .coderabbit.yaml drops shift-left rate from ~80% to ~33%; add `profile: "assertive"` with project-specific `path_instructions`.

## Iteration Velocity

- Full local review loop achieves 0% fix-up ratio for well-planned PRs under 600 LOC.
- 0% fix-up ratio can mask ignored CHANGES_REQUESTED findings; always verify they were addressed.
- Copy-and-adapt is higher-risk for review quality than greenfield.
- Marker/infrastructure commits inflate fix-up ratio; exclude from calculations.
- Net-deletion refactor PRs have lowest review friction; custom UI with portals has highest.
- Scaffolding PRs benefit from sequential additive commits for high shift-left rates.
- Copilot "suppressed low-confidence" findings can be 100% legitimate; always read them.
- Fix commits touching React state cause cascading reviews; budget extra time.
- Test LOC should be factored into PR sizing at ~1.5x feature LOC.
- CSS theme PRs need automated WCAG contrast checks, not manual "verified" claims.
- When CodeRabbit CLI times out, retry with backoff (3 attempts, 2-min wait); add hard timeout (`timeout 600`).

## Multi-PR Feature Coordination

- Grep sibling packages for endpoint paths during internal review; unit tests won't catch contract mismatches.

## PR Sizing

- Shift-left effectiveness degrades above ~600 LOC (67-100% under, 14-59% over); split into 2-3 PRs.
- PRs over 1200 LOC need 3+ review rounds regardless of local review quality.

## Documentation Review Noise

- Run markdownlint locally before push to eliminate mechanical findings.

## Review Discipline

- Never merge immediately after CHANGES_REQUESTED; acknowledge findings before merging.
- For PRs over 300 lines, wait 10+ minutes for CodeRabbit before merging.
- Space out PR submissions by 10+ minutes to avoid rate limits.
- CodeRabbit monorepo sandbox produces false test failures; document or configure to skip.
- When a bot finding contradicts the linked issue, verify the issue text first.
- Expect 2 CodeRabbit rounds for 700+ LOC PRs, 3+ when local review is skipped or PR exceeds 1200 LOC.

---
*Distilled from post-mortem analysis across all projects.*
