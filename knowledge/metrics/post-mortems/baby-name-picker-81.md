# Post-Mortem: baby-name-picker PR #81 — Fix the compare-flow detail overlay styling

**Branch:** `fix/compare-detail-overlay` → `main`
**Author / merged by:** padminipyapali (self-merge)
**Created:** 2026-05-28T20:04:15Z | **Merged:** 2026-05-28T21:29:07Z (squash, commit `832eefe`)
**Duration:** ~1.41h wall-clock (implementation commit predates PR creation by ~17 min)
**Size:** +232 / -13 across 5 files, 3 commits (1 feature, 1 design-artifacts, 1 merge)

## What the PR did

Presentational fix to the in-place detail overlay on the Compare screen:
- **Fonts (root cause):** `NameDetailBody.tsx` styles for name / last name / meaning-origin / pronunciation / syllables copied `fontSize`/`fontWeight`/`letterSpacing` off the typography tokens but **omitted `fontFamily`**, silently falling back to system sans instead of Cormorant Garamond serif. Fix added `fontFamily`.
- **Border:** removed the rose outline on the overlay card (soft shadow now provides separation).
- **Box sizing:** swapped `flex: 1` for `maxHeight: "100%"` + `flexShrink: 1` on the inner ScrollView so the card hugs its content (no tall empty box) while long content still scrolls.
- 3 new `NameDetailBody` tests assert the resolved serif `fontFamily` on name / last name / metadata values (regression guard).

`NameDetailBody` is shared, so the full-screen name-detail route (`app/name/[id].tsx`) also gained serif consistency.

## Local Review (pre-push)
- **CodeRabbit CLI** (`--plain -t all --base main`): 0 findings on this diff (6 reported were pre-existing out-of-diff files swept in by a stale local main ref).
- **Adversarial review:** Tier 0 greps PASS; ui-react a11y / token-consistency / animation checks PASS; 3 tests added. **Sibling-sweep surfaced 1 real finding** — the same `fontFamily`-omission anti-pattern in `app/top-picks.tsx` — scoped OUT of this PR.

## Step Compliance
- **Steps run:** 1, 2a, 2b, 3, 4a, 4b, 4c, 5 (8/9, ~89%)
- **Steps skipped:** 4d (CI) — no CI checks configured (`statusCheckRollup` empty).
- **Skip assessment:** neutral (no post-push review to compare against; no post-merge fixes).

## KEY FINDING: phantom lint gate
The PR body claims `[x] npx expo lint — no new findings`. **This is a misrepresentation — eslint is not installed in the project:**
- Absent from both `dependencies` and `devDependencies`.
- No `node_modules/eslint`, no `node_modules/.bin/eslint`.
- The `lint` npm script is `expo lint`; running it errors `Error: Cannot find module 'eslint'` and executes **zero rules** (verified during this post-mortem: `npx expo lint` → `Cannot find module 'eslint'`).

The implementer reported the gate as passing; a fresh-context critic later proved it cannot run. The mandated `npx expo lint` gate in the project CLAUDE.md has therefore been **silently unrunnable across every worktree** — every prior PR that "passed lint" passed a no-op.

There is an **in-flight, incomplete eslint setup** in the main checkout: untracked `eslint.config.js` (requires `eslint/config` + `eslint-config-expo/flat`, neither installed) and a modified `package.json`. The config alone does not make the gate runnable.

**Action item:** add `eslint` + `eslint-config-expo` to `devDependencies` and finish the in-flight setup; until then the lint gate is phantom. tsc + jest (378 passing, incl. 3 new) DID run and are real.

## Sibling-sweep worked
The adversarial sibling-sweep caught the identical `fontFamily`-omission bug in `app/top-picks.tsx` (Top Picks title + ranked names rendering in system sans). It was correctly scoped out of #81 and fixed same-day in a focused follow-up branch `fix/top-picks-serif-font` (commit `ee9670a` "Render Top Picks display text in Cormorant Garamond serif." + `src/__tests__/topPicksFonts.test.tsx`). Correct Follow-Up Discipline outcome.

## Fix-up Metrics
- **Post-merge fix rate:** 0.0 (no post-merge fixes to #81 itself).
- **Pre-merge catch rate by step:** all 0 — no fix commits; the only adversarial finding was scoped to a follow-up, not fixed in-PR.
- **Pre-merge iteration count:** 1 (healthy).
- **Fix-up taxonomy:** all 0 (the 2 non-feature commits are infrastructure: design artifacts + a merge commit).
- **adversarialCatchRate:** `unmeasured` (no post-push reviews exist; the sibling-sweep catch was real but pre-push and deliberately out-of-scope — not a fixed-in-PR signal).

## Planning Quality
- Description: **complete** (Summary, Designs with on-device capture + mockup, Test plan, Local Review).
- Scope: clean, no scope creep, no redesign commits.
- Branch lifetime: ~1.4h.

## Process Efficiency
- Iteration: efficient (1 round).
- CI status: none configured (no merge gate beyond author's local machine — recurring across this project).
- Automation opportunities: (1) gate-tool execution verification — require pasted tool output, not checkboxes; (2) project-setup smoke-test that each CLAUDE.md gate binary resolves; (3) a style helper that derives text styles FROM typography tokens carrying `fontFamily` by construction, so no call site can drop it (eliminates the bug class).

## Knowledge Updates
- `process-patterns.md` → Process Compliance: added "Verify a quality gate actually EXECUTES before recording it as passed" (eslint phantom-gate evidence) + "Sibling-sweep is working as designed — swept-in sibling bug → same-day follow-up PR."
- `adversarial-review.md` → new "Gate-Tool Execution Verification" section before the Learning Capture Gate.
- `metrics/post-mortem-metrics.json` → appended PR #81 entry (314 total).
- `metrics/dashboard.html` → regenerated with embedded data.

## Recommendations (ranked)
1. **Install `eslint` + `eslint-config-expo` as devDependencies** and finish the in-flight `eslint.config.js` setup. Until then, stop recording `npx expo lint` as a passing gate — it is a no-op. (Highest priority: a phantom gate has been masking lint failures across the whole project history.)
2. **Require pasted gate output, not checkboxes.** The orchestrator should reject a lint/type/test gate marked passed without the tool's real summary line; an `Error: Cannot find module` is a FAIL.
3. **Add a CI merge gate** (tsc + jest at minimum). `statusCheckRollup: []` means self-merge in ~1.4h with no independent gate — recurring finding for this project.
4. **Eliminate the `fontFamily`-drop bug class at the source** with a token→text-style helper that always carries `fontFamily`.
