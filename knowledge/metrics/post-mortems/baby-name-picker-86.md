# POST-MORTEM: baby-name-picker PR #86 — Install ESLint and make the expo lint gate actually run

Branch: `chore/eslint-setup` → `main` | Author / merged by: padminipyapali (self-merge)
Created: 2026-05-28T22:12:42Z | Merged: 2026-05-29T02:23:54Z (squash, commit `ae34953`)
Duration: ~4.19h wall-clock (single commit `7cbf2c2` authored ~1.5 min before PR creation)
Size: +4593 / -1121 across 13 files, 1 commit — the additions are lockfile-dominated (`package-lock.json` install of eslint + its dependency tree); the hand-authored diff is small.

## Context — this PR CLOSES the phantom-lint-gate finding

The project CLAUDE.md mandates `npx expo lint` as a pre-PR gate and `package.json`
carried the `"lint": "expo lint"` script — but `eslint` and `eslint-config-expo` were
NEVER installed (absent from `devDependencies` AND `node_modules`). So `expo lint`
errored `Cannot find module 'eslint'` and ran ZERO rules across the project's ENTIRE
history. Every prior PR that "passed lint" passed a no-op.

This hole was surfaced and escalated by the #81 and #83 post-mortems:
- #81 recorded a phantom `[x] npx expo lint — no new findings` (a false pass).
- #83 (sibling, same session) hit the same unrunnable gate and honestly recorded it
  `[ ] could not run: eslint is not installed`.
- Both flagged that the install had not landed across #81→#83 and escalated it to a
  dedicated tooling PR per Follow-Up Discipline.

#86 is that dedicated tooling PR. The finding spanned #81→#83 unaddressed and is now
RESOLVED as of #86. The gate is REAL going forward.

## What the PR did

- Added `eslint ^9.39.4` + `eslint-config-expo ~55.0.1` (Expo SDK 55-compatible) to
  `devDependencies`, with lockfile.
- Added `eslint.config.js` — standard `eslint-config-expo/flat` setup with two scoped
  blocks:
  - `ignores: ["dist/*", ".expo/*", "web/*"]` — `web/` is a self-contained Next.js
    subproject with its own eslint/tsconfig/deps; `dist/`/`.expo/` are gitignored
    build output.
  - A tests-only override disabling `import/first` + `@typescript-eslint/no-require-imports`,
    because test files intentionally place imports after `jest.mock()` factory blocks.
- Fixes so `expo lint` exits 0: 4× `react/no-unescaped-entities` errors (escaped
  apostrophes in JSX copy — `gender.tsx`, `(tabs)/index.tsx`, `+not-found.tsx`,
  `EditScreenInfo.tsx`; no visible copy change), 3 dead imports removed
  (`typography` ×2, bare `View` in `UndoToast.tsx`), and `array-type` auto-fix
  (`Array<T>`→`T[]`) in 4 test files.

## KEY INCIDENT — autofix broke test hoisting (self-caught, reverted)

`eslint --fix` initially reordered imports past `jest.mock()` factory blocks in 14
test files, breaking 2 suites. Root cause: Jest hoists `jest.mock()` calls above
imports, and the factories reference variables declared below them — reordering real
imports above the mock factory changes evaluation order and the factories break. The
implementer self-caught this by re-running `npm test`, fully reverted the autofix, and
applied the correct fix instead: the tests-only config override (scope `import/first`
off test globs). This is the reusable linter-introduction lesson captured in
process-patterns.md (Automation Opportunities).

## LOCAL REVIEW (pre-push)

- CodeRabbit: NOT tracked (no `## Local Review` CodeRabbit line — not run). Recorded null.
- Adversarial review: Tier 0 greps clean; config `ignores` + tests-only override
  justified and verified. 0 findings.
- Fresh-context critic: SHIP — verified removed imports are truly unused (no crash
  risk), `array-type` changes are behavior-preserving, no leftover import-reorder
  damage, `devDependencies` placement + lockfile consistent, and traced
  `favoritedBeforeHide` to confirm it's harmless.
- Shift-left: n/a (no fixed-in-PR findings surfaced at any gate; the autofix breakage
  was self-caught during implementation, before review).

## STEP COMPLIANCE

Step compliance: NOT explicitly tracked — the PR body has a `## Local Review` section
but NO `Steps skipped:` line, so per the post-mortem rule `stepCompliance` is recorded
as null. Inferred from body content: Plan (1), Implement (2a), Test/tsc+jest (3),
Adversarial (4c), fresh-context critic, Push/PR (5) all ran; CodeRabbit (4b) and CI
(4d, repo has no CI) did not. The missing `Steps skipped:` line is a minor process-drift
signal — sibling PRs #78/#80/#81/#84/#85 carried it; #83 and now #86 did not. This is
the 6th occurrence in the series of 4b being skipped/untracked on a fast self-merge.

## STEP TIMING

Not tracked (no `## Step Timing` section). Wall-clock created→merged ~4.19h.

## REVIEW FRICTION (post-push)

Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general. No GitHub
reviews (solo flow; the fresh-context critic is the in-process reviewer). Self-merge by
author with no peer review. Timeline: created→merge ~4.19h total.

## ADVERSARIAL REVIEW EFFECTIVENESS

Pre-push catch potential: n/a — no issues escaped to post-merge; the only real defect
(the autofix-broke-tests breakage) was self-caught by the implementer pre-review via
the test suite, not by the critic or adversarial checklist.
Covered but missed: none. Not covered (new categories): the autofix-broke-test-hoisting
class is now captured as an Automation Opportunity (re-run tests after `--fix`; scope
import-ordering rules off test files).
adversarialCatchRate = unmeasured (no post-push reviews exist; no fixed-in-PR adversarial
finding to measure a catch rate against — the critic returned SHIP with nothing to
catch, and the one real defect was self-caught before the review gate).

## FIX-UP METRICS

- Post-merge fix rate: 0.0 — no follow-up PR fixes #86. (Residual debt is documented
  warnings, not regressions.)
- Pre-merge catch rate by step: all 0 — single squash commit, no fix commits. The
  autofix revert happened mid-implementation and was folded into the single commit, so
  it is not a separate fix-commit signal.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all 0 (single feature/chore commit; no separable fix commits).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## RESIDUAL DEBT — gate exits 0 but is NOT warning-free

4 lint warnings remain (documented in the PR body, gate still exits 0):
- 3× `react-hooks/exhaustive-deps` (`(tabs)/index.tsx:179,214`, `top-picks.tsx:206`) —
  adding deps risks changing effect/animation timing; needs author judgment, deferred.
- 1× `no-unused-vars` — `favoritedBeforeHide` (`gameStore.ts:938`, dead capture from
  #82). Investigated this PR and confirmed NON-FUNCTIONAL: the hideBoth-undo restore
  works because the UI computes its own identical favorites copy and routes it through
  the toast; the store-side capture is dead/misleading duplication. One-line cleanup
  candidate.

Next step to fully close: a follow-up that drives warnings to 0 (or `--max-warnings 0`
once they are) so the gate enforces clean, not merely non-erroring.

## PLANNING QUALITY

Description: complete (Summary, What changed, Remaining warnings, Test plan, Local
Review). Scope: clean — single-concern tooling PR, no scope creep, no redesign commits
(the autofix revert was contained within implementation). Branch lifetime: ~4.19h.

## PROCESS EFFICIENCY

Iteration: efficient (1 round). CI status: none configured (`statusCheckRollup` empty —
recurring across this project; the new eslint gate runs only on the author's local
machine until CI is added). Automation opportunities: (1) the autofix-broke-tests
lesson (re-run full suite after `--fix`; scope import-ordering off test files); (2) the
still-open 4b-skip pre-push hook; (3) wire the now-real `expo lint` gate into CI so it
gates merges, not just local runs; (4) `--max-warnings 0` follow-up to make the gate
enforce clean.

## KNOWLEDGE UPDATES

- `process-patterns.md` — Process Compliance: marked the phantom-lint-gate finding
  RESOLVED as of #86 (the install landed; gate exits 0 with real rule execution),
  documented the 4 residual warnings, and noted the gate is real going forward.
- `process-patterns.md` — Process Compliance (self-merge / 4b entry): noted the
  eslint-setup branch landed as #86, that it does NOT enforce 4b as predicted (6th
  occurrence of 4b skipped/untracked), and that the 4b-skip pre-push hook remains the
  standing open item.
- `process-patterns.md` — Automation Opportunities: NEW reusable lesson — auto-fixers
  can silently break test hoisting; always re-run the full test suite after `--fix`,
  and scope import-ordering rules off test files (generalizes to Prettier/Biome/isort).

## RECOMMENDATIONS (ranked)

1. Wire `npx expo lint` into CI now that it actually runs — otherwise the newly-real
   gate still only executes on the author's machine and can drift back toward phantom.
2. Land the `--max-warnings 0` follow-up (delete the dead `favoritedBeforeHide` capture;
   resolve or explicitly suppress the 3 exhaustive-deps warnings) so the gate enforces
   clean, not merely non-erroring.
3. Build the long-pending 4b-skip pre-push hook — #86 is the 6th self-merge in the
   series where CodeRabbit (4b) was skipped/untracked; prose has not stopped it.
4. Restore the `Steps skipped:` line in the PR-body template — #83 and #86 both dropped
   it, degrading step-compliance tracking to null.
