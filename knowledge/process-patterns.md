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
- **Plans for UI redesigns must enumerate every visible surface by name with a screenshot or mockup reference per surface.** When a feature touches both a card-grid and a lightbox (or any two related-but-distinct UI surfaces), the user's feedback like "X looks bad" cannot disambiguate which surface they mean. The fix: in the plan, list each surface as a row in a table -- name, file path, mockup variant, before/after screenshot URL. During iteration, ask the user to point at a row when reporting a defect. Without this artifact, the agent will lock onto the most recently-changed surface and misroute fixes (PR #83: 2 rounds of "lightbox looks bad" feedback were actually about the CARD GRID, costing 2 extra implementer rounds). **For small PRs (<5 files, single primary surface), a Notes-section paragraph naming each affected surface plus deliberately-untouched siblings is sufficient -- the formal table is the >2-surface threshold (PR #84 used the lightweight version successfully: zero scope creep, zero user-iteration rounds).** **PROMOTED from advisory to MANDATORY at >2 surfaces or >8 files (PR #86 evidence): the orchestrator must refuse to dispatch the implementer for any plan that implies these thresholds without the table. PR #86 touched 16 files / 6 surfaces without the table and the critic's top two findings (cross-surface cache-sync + sibling-feature parity) were exactly the failure modes the table is designed to prevent up-front.** <!-- Source: post-mortem, remodel-hq #83 + #84 + #86, 2026-05-15/16 -->
- **Stacked-PR coordination protocol.** When two features will touch the same hook/files in series, declare them as stacked branches via `gh pr create --update-base` up-front rather than allowing the second branch to absorb a mid-flight rebase against the first's merge. PR #86 had to rebase mid-critic-round because PR #85 merged into main between rounds; both PRs touched `useInspoLibrary` / `useInspoNotes` / `inspoActionIcons`. Stacked branches let the second PR auto-rebase when the first lands. Choose sequential-merges-only (and block work on the second feature until the first merges) when the two features are independent. **Add/add conflicts on NEW files are a foreseeable stacked-PR collision: baby-name-picker #78 and #80 both *created* `NameCard.test.tsx`, forcing a manual add/add merge-conflict resolution on #80's rebase. When two stacked PRs will each add the same new file (common for a per-component test file both touch), base the child's new file on the parent's version up front rather than letting both create it independently.** <!-- Source: post-mortem, remodel-hq #86, 2026-05-16; strengthened baby-name-picker #80, 2026-05-28 -->
- **Mid-flight rebase detection at orchestrator dispatch time.** Before dispatching the implementer on a feature whose files overlap with recent main commits, run `git log HEAD..origin/main -- <shared-files>` and `git log main..HEAD -- <shared-files>` to surface in-flight conflicts. 30-second smoke; would have flagged the #85/#86 overlap before #86's critic round. <!-- Source: post-mortem, remodel-hq #86, 2026-05-16 -->
- **Rebase a stale feature branch onto current origin/main BEFORE running review gates, and re-run tsc afterward — intervening main commits cause silent type-level integration breaks the original author never saw.** A feature branch based on an older main, reviewed in isolation, can be green; but if main advanced and a newer commit added a sibling that depends on the unchanged shape of a type you widened, the merged tree fails to compile. baby-name-picker name-family-tree: the feature added a non-optional `familyJson` field to the `Name` type; an intervening main commit (undo-on-selection) had added a new `Name` mock in `gameStore.undo.test.ts` that the original feature work could not have updated, so post-rebase tsc broke on the missing field. Fix protocol: (1) commit feature work, (2) `git rebase origin/main`, (3) resolve conflicts — for GENERATED artifacts (sqlite `.db`, generated `.sql`) take main's side then re-run the build script rather than hand-merging binaries, (4) sibling-sweep every constructor of the widened type (`grep -rln '<adjacent-required-field>' src | while read f; do grep -q '<new-field>' "$f" || echo "MISSING: $f"; done`), (5) re-run tsc/lint/jest. The PR diff (`git diff origin/main..HEAD`) must show ONLY the feature, never a reversal of intervening main commits — if it shows deletions of unrelated files, the branch base is wrong. **Confirmed downstream: this exact break landed on `main` undetected — `gameStore.perGender.test.ts`'s `makeName` fixture was missing the required `familyJson` field, leaving `tsc` and that jest suite RED on `origin/main`. The #73 post-mortem did not catch that main had gone red; the next feature (baby-name-picker #78, pronunciation) inherited the broken gate and had to carry a one-line `familyJson: null` fixture fix to make the mandated check pass. Lesson: a red main can persist silently with no CI; either configure required `tsc`/jest checks, or run them against `origin/main` itself (not just the feature branch) before declaring a gate green.** <!-- Source: baby-name-picker name-family-tree finisher, 2026-05-28; strengthened baby-name-picker #78, 2026-05-28 -->
- **Mockup-driven UI work needs an explicit "what the mockup covers vs what it does NOT" section in the plan.** The mockup at `docs/mockups/inspo-lightbox-comments/` showed the lightbox redesign but not the grid card layout. When user feedback drifted to the grid (vote pill placement, unicode glyphs), there was no plan artifact saying "grid is out of scope, file a separate issue" -- so the implementer absorbed scope creep into the same PR (3 fix commits for grid concerns). Plans referencing a mockup must declare mockup coverage boundaries. <!-- Source: post-mortem, remodel-hq #83, 2026-05-15 -->
- **Multi-PR feature sequences should include a "What's NOT in this PR" section.** When a feature is intentionally split across multiple PRs, enumerate the deferred items in the current PR body (e.g., "Gmail send (PR 2d), HTML email (PR 2d), launchd auto-trigger (PR 2d)..."). This makes scope boundaries reviewable, preempts "where's X?" review questions, and creates an explicit checklist for the follow-up PR. Generalizable to any feature that ships in multiple parts. <!-- Source: post-mortem, family-digest #12, 2026-04-22 -->

## Follow-Up Discipline

- Post-push findings should become their own focused follow-up PR rather than being deferred to a tracker or bundled into the next feature.
- Multi-finding follow-up PRs work just as well as single-finding ones; fix all post-mortem findings atomically.
- Infrastructure gaps identified in post-mortems should be addressed in dedicated, same-day tooling PRs.
- **Recommendation drift across consecutive PRs is the dominant post-mortem failure mode.** When a post-mortem recommendation does not land before the next PR ships in the same project, escalate it from prose recommendation to a project artifact (PR template file at `.github/PULL_REQUEST_TEMPLATE.md`, CI workflow file, lint rule, hook). Two consecutive PRs that ignore the same recommendation indicate the recommendation lives in the wrong place — move it from a markdown file to a file the toolchain enforces. **Three consecutive PRs ignoring the same recommendation (confirmed in family-digest #1 → #3 → #4: PR template, CodeRabbit CLI, CI configuration) means the next post-mortem must DEMAND artifact conversion as the first recommendation rather than restating the prose recommendation a fourth time.** **Confirmed across four consecutive PRs in family-digest #1 → #3 → #4 → #12: prose recommendations alone never land — only committed artifacts (template files, workflows, hooks, lint rules) close the loop.** When the open-to-merge window is also short (PR #12: ~18 minutes), CI workflows must additionally be configured as required checks, otherwise a fast self-merge bypasses them even when they exist. <!-- Source: post-mortem, family-digest #3, 2026-04-22; strengthened family-digest #4, 2026-04-22; strengthened family-digest #12, 2026-04-22 -->
- **PRs that introduce or modify paid external API calls require a "Performance & Cost Impact" section** in the PR body, even when planning quality is otherwise complete. Cover: $/invocation, expected invocations per period, rate-limit posture, and failure mode (throw vs partial content vs cached fallback). The first PR adding a paid API is the one most likely to skip this, because the cost envelope feels small at single-user scale — capture it anyway as the baseline for future cost-regression detection. <!-- Source: post-mortem, family-digest #3, 2026-04-22 -->

## Scope Decisions

- For interface extractions under 10 lines that match established project conventions, include them in the original PR; reserve "scope creep" for behavioral additions.
- Never bundle tooling setup (lint configs, auto-fixes) with feature PRs; create a separate tooling PR.
- When identical logic exists in 2+ files and is under ~30 lines, extract to a shared utility instead of adding "keep-in-sync" comments.
- When a tangential automation idea surfaces during a focused PR, defer it to a separate PR.
- **Annotate `Steps skipped:` even on trivial fixes.** Single-line CSS or copy fixes (<=3 LOC, 1 file) often skip Local Review and adversarial review legitimately. Without an explicit `Steps skipped: <list> -- reason: <rationale>` line in the PR body, post-mortems can't distinguish intentional skips from process drift. Always include the line, even if the reason is 'trivial CSS leading fix, no logic paths.' <!-- Source: post-mortem, second-brain #603, 2026-05-06 -->

## Adversarial Review Gaps

### Critic Blind Spots
- **Test-discovery colocation bias.** Critic agents default to assuming Jest/Vitest colocated `*.test.ts` next to source files and report "no tests exist" when projects use the alternative `src/__tests__/<area>/foo.test.ts` mirror-tree, `tests/` directory, language-specific conventions (Go `*_test.go`, Rust `tests/`, pytest `tests/` dir), or any non-colocated layout. Before claiming any test gap, the critic must read the project's test-runner config (`vitest.config.*`, `jest.config.*`, `pyproject.toml`, etc.) AND `find . -type d \( -name __tests__ -o -name tests -o -name test -o -name spec \) -not -path '*/node_modules/*'` to enumerate the actual test layout. The orchestrator-protocol "Critic's Fresh Context" section now mandates this. <!-- Source: post-mortem, family-digest #4, 2026-04-22 -->
- **Critic false-negatives that survive only because the orchestrator has ground-truth project knowledge are a fragile gate.** When the orchestrator overrules a critic finding based on its own familiarity with the codebase (rather than the critic re-verifying), capture the missed check as an explicit critic-prompt requirement. Otherwise the same blind spot will recur the next time a less-familiar orchestrator inherits the team. <!-- Source: post-mortem, family-digest #4, 2026-04-22 -->

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
- **Scaffolding PRs that exceed 600 LOC must declare the exception in the PR body** (e.g. "scaffolding exception — 5 tightly-coupled modules + fixtures land together because tests require full surface"). Silent exceptions erode the size cap. <!-- Source: post-mortem, family-digest #1, 2026-04-24 -->
- **Solo-developer self-merge must still run CodeRabbit CLI locally before push.** Zero-peer-review + zero-CodeRabbit on a 5.4k-LOC PR leaves no independent second opinion even when adversarial review shift-left is 100%. **Recurs on small PRs too: baby-name-picker #73 (+671/-81, self-merged ~1.75h after creation) ran implementer + fresh-context critic + adversarial gate but skipped 4b CodeRabbit. The fresh-context critic substitutes for peer review on correctness, but CodeRabbit catches a different class (cross-file/library-idiom nits) — the orchestrator should run `coderabbit review --plain -t all --base main` in the worktree before push regardless of PR size, or explicitly record the skip reason.** **Now a 3rd baby-name-picker occurrence: #80 (+127/-9, self-merged ~8 min after creation) skipped 4b even though its sibling #78 — same session, same `NameCard.tsx` component — ran CodeRabbit clean. The skip correlates with the fastest self-merges. Prose has now been violated across #73 and #80; promote to an enforceable artifact — a pre-push hook that blocks push (or demands an explicit recorded skip reason in the PR body's `Steps skipped:` line) when 4b did not run.** <!-- Source: post-mortem, family-digest #1, 2026-04-24; strengthened baby-name-picker #73, 2026-05-28; strengthened baby-name-picker #80, 2026-05-28 -->
- **Squash adversarial fix commits into the commits they amend (or prefix with `review-fix:`).** Landing each adversarial-cycle fix as its own commit inflates the legacy fix-up ratio (41.7% with a healthy 1-iteration cycle) and breaks heuristic classifiers. <!-- Source: post-mortem, family-digest #1, 2026-04-24 -->
- **Configure CI before the first implementation PR.** A project with `statusCheckRollup: []` has no merge gate beyond the author's local machine. <!-- Source: post-mortem, family-digest #1, 2026-04-24 -->
- **PR body templates should include `## Local Review` and `## Step Timing` sections from PR #1.** Adding them later leaves early PRs with null compliance/timing data and no baseline for trend analysis. <!-- Source: post-mortem, family-digest #1, 2026-04-24 -->
- **Project PR-body template must enforce the project's own CLAUDE.md required sections.** baby-name-picker #33 shipped without the required `Performance & Cost Impact` section and without `Closes #N`, despite both being mandated in the project CLAUDE.md, because there is no template scaffold to default them in. Self-merge in 30 s gives the template no second chance. <!-- Source: post-mortem, baby-name-picker #33, 2026-05-14 -->
- **Unchecked manual test items must not survive merge.** When a PR fixes a user-visible bug, the manual verification of that exact scenario is the test plan -- merging with the boxes unchecked turns the test plan into a TODO list nobody returns to. <!-- Source: post-mortem, baby-name-picker #33, 2026-05-14 -->
- **Verify a quality gate actually EXECUTES before recording it as passed — a `[x] passed` claim with no captured output is unfalsifiable.** baby-name-picker #81's PR body claimed `npx expo lint — no new findings`, but eslint was never installed (`eslint` absent from both `dependencies` and `devDependencies`, no `node_modules/eslint`, no `node_modules/.bin/eslint`). The `lint` npm script is `expo lint`, which immediately errors `Cannot find module 'eslint'` and runs zero rules. The implementer reported the gate as passing; a fresh-context critic later proved it cannot run. This means the mandated `npx expo lint` gate has been silently unrunnable across EVERY worktree of this project — every prior PR that "passed lint" passed a no-op. Two systemic lessons: (1) **a gate that errors out is not the same as a gate that passes clean** — for lint/type/test gates, the orchestrator must require the implementer to paste the tool's actual output (exit code + summary line like "N problems" or "0 errors"), not a checkbox; an `Error: Cannot find module` in that output fails the gate. (2) **At project-setup time, smoke-test that each gate command in CLAUDE.md actually resolves its binary** (`npm run lint -- --version` or equivalent) — a CLAUDE.md that mandates `npx expo lint` while the toolchain can't run it is a phantom gate. Concrete remediation: add `eslint` + `eslint-config-expo` to `devDependencies` (an in-flight, incomplete setup already exists — untracked `eslint.config.js` requiring `eslint/config` + `eslint-config-expo/flat`, plus a modified `package.json` in the main checkout — but neither package is installed, so the config alone does not make the gate runnable). <!-- Source: post-mortem, baby-name-picker #81, 2026-05-28 -->
- **Sibling-sweep is working as designed — but a swept-in sibling bug should become a same-day follow-up PR, not just a tracker note.** baby-name-picker #81 fixed a `fontFamily`-omission bug in `NameDetailBody.tsx` (styles copied size/weight/spacing off the typography tokens but dropped `fontFamily`, silently falling back to system sans). The adversarial sibling-sweep correctly found the identical anti-pattern in `app/top-picks.tsx` (Top Picks title + ranked names rendering in system sans). #81 scoped the sibling fix out and the follow-up landed on its own branch (`fix/top-picks-serif-font`, commit "Render Top Picks display text in Cormorant Garamond serif." + a `topPicksFonts.test.tsx` regression test). This is the correct Follow-Up Discipline outcome: the sweep caught a real second instance, and it was fixed atomically in a focused PR rather than dying in a backlog. The capturable design-level fix is upstream: a style helper that derives a text style FROM a typography token must carry `fontFamily` by construction so no call site can drop it — the bug class only exists because each component hand-copies token fields. <!-- Source: post-mortem, baby-name-picker #81, 2026-05-28 -->


## Automation Opportunities

- **Guard fetch(variable) in server routes.** When server-side code fetches a DB- or user-provided path, the value may be relative (e.g. seeded /inspo/foo.png) and fetch() has no base URL — all requests silently 404. Either resolve against request.nextUrl.origin for public/ assets, or validate the path is absolute before fetch. Add a review/lint check that flags bare fetch(<variable>) in server routes. <!-- Source: post-mortem, remodel-hq #19, 2026-04-21 -->
- **Integration test with seeded data shape, not just uploaded data shape.** PR #18 shipped a zip-download feature that worked for absolute Supabase URLs (uploaded photos) but broke for 354 seeded photos with relative paths. The data shape that dominates the table was never tested. Gate: any feature reading from a table with both seeded and user-created rows must be tested against at least one of each. <!-- Source: post-mortem, remodel-hq #19, 2026-04-21 -->
- UTC suffix enforcement: use Tier 0 grep checks in the adversarial review (deferred CI-level lint).
- Run Biome lint before push to catch a11y issues like `noStaticElementInteractions`.
- Add Stylelint to local pre-PR checks for web projects; compose into the main `npm run lint` script.
- Pin devDependency versions consistently (all exact or all caret); mixed strategies generate review noise.
- A missing .coderabbit.yaml drops shift-left rate from ~80% to ~33%; add `profile: "assertive"` with project-specific `path_instructions`.
- **Adversarial review marker is keyed by `$CWD`, not git-root.** When the orchestrator writes the marker for the main-repo path but the push fires from inside a `.claude/worktrees/<name>` subdir, the hook re-hashes the worktree path and blocks the push. Fix when writing the marker manually: hash the same path you'll be in when `gh pr create` / `git push` runs. Better fix: update the hook to resolve `$CWD` to its canonical git worktree root before hashing. <!-- Source: post-mortem, second-brain #647, 2026-05-19 -->

## Iteration Velocity

- Full local review loop achieves 0% fix-up ratio for well-planned PRs under 600 LOC.
- **User-perceived-latency feedback is a process smell, not a feature request.** When the user reports "this feels slow" on a write path (vote, favorite, comment) and the fix is a one-line optimistic-update swap, the root cause is that the write-path hook (`useAtelierData`, `useInspoFavorites`, `useInspoNotes`) did not default to optimistic updates. PR #83: 1 fix commit ("optimistic vote/favorite updates") could have been preempted if the hook factory enforced optimistic-by-default with an explicit `pessimistic: true` opt-out. Treat repeated "feels slow" feedback across multiple write paths as a hook-factory design gap, not per-call optimization. <!-- Source: post-mortem, remodel-hq #83, 2026-05-15 -->
- **Surface-misidentification during iteration is an avoidable rework category.** When user feedback references a feature area ("the lightbox") but actually concerns a sibling surface (the card grid), each misidentified round costs ~1 implementer cycle. Mitigations: (1) plan-time surface table (see Planning Discipline), (2) ask the user "which screen -- card grid or lightbox?" before dispatching the implementer, (3) capture a screenshot in the feedback channel. PR #83 lost 2 implementer rounds to this. <!-- Source: post-mortem, remodel-hq #83, 2026-05-15 -->
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

## Process Rule Enforcement

- **Promote prose recommendations to enforceable artifacts after 3 consecutive violations.** When the same prose process rule is violated in 3+ PRs in a row (e.g., missing Local Review / Steps skipped / Perf & Cost annotations across #603, #606, #609), escalate from prose to artifact (PR template, lint rule, hook). Prose alone is insufficient at violation rate >2/window. <!-- Source: post-mortem, second-brain #614, 2026-05-06 -->

## Stale-Base Detection

- **Detect stale base before push, not at critic-time.** When `main` advances during the implementation window, the resulting spurious diff is currently caught only by the critic agent's review pass. Two occurrences in one session (#614 and prior) indicate the manual catch path is leaky. Add a Tier 0 pre-push check: `git fetch && [ "$(git merge-base HEAD origin/main)" = "$(git rev-parse origin/main)" ]`. <!-- Source: post-mortem, second-brain #614, 2026-05-06 -->

## Review Discipline

- Never merge immediately after CHANGES_REQUESTED; acknowledge findings before merging.
- For PRs over 300 lines, wait 10+ minutes for CodeRabbit before merging.
- Space out PR submissions by 10+ minutes to avoid rate limits.
- CodeRabbit monorepo sandbox produces false test failures; document or configure to skip.
- When a bot finding contradicts the linked issue, verify the issue text first.
- Expect 2 CodeRabbit rounds for 700+ LOC PRs, 3+ when local review is skipped or PR exceeds 1200 LOC.
- **Dev-server hangs on rapid file rewrites.** When an iteration cycle rewrites many files quickly (rapid critic-fix loops), the Next.js dev-server compiler worker can hang silently -- TCP stays open, requests accept, but the worker never responds. The page in the browser shows zero-styled HTML. Recovery: `lsof -ti:PORT | xargs kill -9` then restart. Add a quick "ping the server with curl" healthcheck after large file batches. <!-- Source: post-mortem, baby-name-picker #36, 2026-05-18 -->
- **Wall-clock vs active-time gap on design-iteration PRs.** Design-led PRs (rebrand, landing pages, icons) can have wall-clock 100x active-implementation time due to user-driven iteration. Don't infer "stuck" or "high friction" from wall-clock alone; track an explicit `designIterationRounds` metric separately. <!-- Source: post-mortem, baby-name-picker #36, 2026-05-18 -->

---
*Distilled from post-mortem analysis across all projects.*

- **Audit structured data on its structured representation, not a flattened projection.** A flattened/denormalized view of multi-valued data hides both directions of error: it makes legitimate multi-value entries look like conflations (false positives) and hides per-element mistakes (false negatives). Evidence: a baby-name audit on the joined `meaning` string produced 7 false positives, and a later pass on the per-language `meanings_json` found 18 errors the flat view missed (swapped pairs, wrong-language glosses). Always audit the canonical structured field. <!-- Source: post-mortem, baby-name-picker #43, 2026-05-27 -->
- **Verify the artifact that ships, not an intermediate build output.** A fix can pass all tests against a build output yet never reach users if the shipped artifact is generated/committed separately and has drifted. Trace what the app actually loads at runtime and validate that. Evidence: corrections were verified against `data/seed.db` while the app shipped a hand-edited `assets/seed.db` that had diverged (1249 vs 997 names). <!-- Source: post-mortem, baby-name-picker #41, 2026-05-27 -->
- **Stacked PR + squash-merge: rebase the child with `git rebase --onto <new-main> <old-parent-tip> <child-branch>`.** After the parent PR squash-merges (new SHA on main), this replays only the child's own commits and drops the now-redundant parent commit cleanly. <!-- Source: post-mortem, baby-name-picker #43, 2026-05-27 -->
