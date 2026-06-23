# POST-MORTEM: second-brain PR #688 — fix: restore green build/test/lint on main (a11y lint + two stale tests)

Branch: `fix/main-ci-green` → `main` | Author: padminipyapali | created→merged ~58 min (self-merged)
Size: +23 -2 across 4 files, 2 commits (1 fix + 1 docs)
Merged: 2026-06-23T03:20:10Z | Closes #684

## Summary

Issue #684 asked to "restore green build/test/lint on main," which had been reported
as a broad pre-existing break. The dominant finding of the investigation was that
**most of the reported break was a LOCAL STALE-BUILD ARTIFACT, not a real defect.**

## Headline finding: a false "main is broken" premise propagated for 3 PRs

- The reported failures — phantom `hasAiResponse does not exist on ApiFeedEntry`
  TS errors and a `VITE_*` env build error — were **local-only**. `packages/shared/dist/`
  is gitignored, so a dependent package's local `tsc` compiled against a STALE `dist/`,
  while CI (which rebuilds `shared` fresh) was always green.
- This false premise had been **re-reported across PRs #683 and #687** by successive
  agents reading it from continuation summaries instead of verifying — a textbook
  violation of the global rule "Do NOT trust continuation summaries about repo state —
  verify it yourself."
- Concrete fix to the process: before trusting any local `tsc`/build failure in a
  monorepo dependent, **rebuild the gitignored workspace dep** and **check whether CI
  actually shows the failure**. Only failures that survive a clean rebuild AND appear
  in CI are real.

## The 3 real, small CI-affecting fixes

1. **Lightbox a11y** — `biome a11y/useKeyWithClickEvents` on the backdrop click. A
   narrowly-targeted `biome-ignore` (one line, one rule) with justification: Escape-close
   via a global keydown listener and a dedicated close button already exist, so the
   backdrop click is pointer-only convenience.
2. **Stale test mock** — `entry.test.ts` fed `getRelatedEntries` a mock row missing the
   `starred` column → `starred: undefined` vs expected `false`. Production SQL/mapper
   were correct; the mock was fixed to mirror the real DB row.
3. **Date-rot test** — `message-processor.test.ts` reminder test used a hardcoded
   `2026-03-15` due date that rotted past now; `createReminder` (gated on `remindAt > now`)
   never fired. Moved to the `2099-12-31` sentinel used by sibling reminder tests.

## Newly unmasked (correctly deferred)

Fixing the biome error revealed **82 stylelint errors in App.css** — the root lint
script `biome lint . && npm run lint:css` had been short-circuiting on the biome failure
for many PRs, hiding an entire linter's output. **11 are REAL** undefined custom
properties (`--coral-rgb`/`--text-tertiary`, introduced in PR #594) — a latent visual
bug rendering coral accents wrong. Deferred to **issue #689** with proper bug framing
rather than dismissed as cosmetic. Lesson: chained `&&` quality gates mask downstream
failures; audit each step independently.

## Process metrics

- **Review friction:** 0 human reviews (only a vercel bot comment), 0 inline comments,
  1 round. Self-merged.
- **Step compliance:** ran 1, 2a, 3, 4c (fresh-context critic PASS), 5; 4a/4b not
  recorded in PR body. Per MEMORY.md lightweight-review policy, a +23/-2 / 3-fix PR
  under ~100 LOC may skip critic-heavy gates. Compliance 7/9 ≈ 0.78. Skip assessment:
  **good** (no post-merge issues; the skipped CodeRabbit/simplify steps would not have
  changed the outcome on a 3-line-class fix).
- **adversarialCatchRate: UNMEASURED.** The 3 fixes were author-found during
  investigation; the fresh-context critic + adversarial gate VALIDATED the claims (PASS)
  but there is no evidence they independently caught an *escaped* issue, so the catch
  denominator is ill-defined. Marked unmeasured per the post-mortem-integrity rule
  rather than hardcoded.
- **Post-merge fix rate: 0.0** (688 is the latest merged PR; no follow-ups). Iteration
  count: 1 (healthy).
- **Planning quality:** complete (clear What/Why, Verification, and an explicit
  "Out of scope (deferred)" section pointing to #689).

## Knowledge updates

- `process-patterns.md` → Session Start Discipline: new rule — verify a "main is broken"
  claim against CI reality before acting; rebuild gitignored workspace deps first;
  distinguish local-artifact failures from real ones. Notes the 3-PR false-premise
  propagation. (Source: #688)
- `process-patterns.md` → Automation Opportunities: new rule — chained `&&` lint/CI gates
  mask downstream steps; audit each step independently; newly-unmasked real findings get
  a tracked issue (#689). (Source: #688)
- `testing-patterns.md` (already present, sourced #688): hardcoded near-future dates rot
  past `> new Date()` gates — freeze the clock or use a far-future sentinel.
- `docs/BUGS.md` BUG-034 (in-repo, added by the PR): date-rot, stale dist, chained-lint
  short-circuit.

## Recommendations

1. **Promote the stale-dist verification step into the project's session-start / "main
   is red" runbook.** The single highest-leverage fix: a one-liner that rebuilds
   `@second-brain/shared` before any local `tsc` of a dependent, so phantom errors never
   start a false-premise cascade.
2. **De-chain the lint script.** Change `biome lint . && npm run lint:css` so both
   linters always run (e.g. run them as separate npm scripts the CI invokes
   independently, or use a runner that doesn't short-circuit), so one linter's failure
   can't hide another's findings.
3. **Close issue #689** (the 11 real undefined custom properties) promptly — it is a
   real visual regression latent since PR #594, not cosmetic.
