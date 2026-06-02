# POST-MORTEM: baby-name-picker PR #150 — Add CI gate: typecheck + lint + tests on PRs

Branch: `chore/add-ci-pr-checks` → `main` | Author: padminipyapali | created→merged ~7 min
Size: +207 -0 across 4 files, 2 commits | Merged 2026-06-02T03:56:22Z

## Summary
Adds the repo's FIRST GitHub Actions workflow (`.github/workflows/ci.yml`): one job on
ubuntu-latest / Node 20, `npm ci` → `npm run typecheck` → `npm run lint` →
`jest --ci --watchAll=false`, on every PR to main and push to main. Supporting changes:
a new `typecheck` npm script (`tsc --noEmit`), `ts-node` added as an explicit devDependency,
and a tsconfig `web` exclude (the self-contained Next.js subproject was erroneously scanned
by the root tsc). Directly closes the standing "no CI gate / red main can persist silently"
recommendation that drifted across #87/#126/#141/#149 and the name-family-tree finisher.

## LOCAL REVIEW (pre-push)
  CodeRabbit: not tracked (no `## Local Review` section in PR body)
  Adversarial: not tracked
  Shift-left rate: n/a

## STEP COMPLIANCE
  Step compliance: not tracked (no `Steps skipped:` line in PR body)

## STEP TIMING
  not tracked (no `## Step Timing` section)

## REVIEW FRICTION (post-push)
  Review rounds: 1 (0 CHANGES_REQUESTED — self-merged infra PR, no human/bot review)
  Comments: 0 inline, 0 general
  Categories: all 0
  Timeline: created → merge: ~7 min total (no external review)

## ADVERSARIAL REVIEW EFFECTIVENESS
  Pre-push catch potential: n/a (no adversarial section). The defect that mattered here
  (clean-install transitive dep) is not a code-logic class the adversarial checklist targets;
  it is an environment-parity class only a clean `npm ci` (i.e. the CI gate itself) catches.

## FIX-UP METRICS
  Post-merge fix rate: 0% (0 post-merge fix commits — ideal)
  Pre-merge catch rate by step: postPush (CI gate): 1 fix | all local steps: 0
    — The CI gate caught its OWN failure on run 1; commit 2 fixed it; run 2 went green.
  Pre-merge iteration count: 2 (normal — one failure→fix cycle, caught pre-merge)
  Fix-up taxonomy: { infrastructure: 1 } (the ts-node devDependency fix; excluded from quality metrics)
  Legacy fix-up ratio: 50% (1 fix / 2 total commits)

## CI RUN HISTORY (evidence)
  Run 26797170866 (PR, 03:49:24Z): FAILURE —
    "Jest: 'ts-node' is required for the TypeScript configuration files ...
     Cannot find package 'ts-node' imported from .../jest-config/build/index.js"
  Run 26797273676 (PR, 03:52:33Z): SUCCESS — after commit 2 (`Add ts-node so CI can load
    the TypeScript jest.config.ts`).
  statusCheckRollup at merge: CI / "Typecheck, lint & test" = SUCCESS.

## PLANNING QUALITY
  Description: complete (Summary, What it does, Supporting changes, Verified green, Notes)
  Scope: clean — single concern (CI gate + its minimal supporting deps/config)
  Branch lifetime: ~7 min
  Planning checklist: appropriate for an infra PR; PR body even pre-flagged the node-20/ubuntu
    parity risk and the lint-warnings-non-blocking policy choice.

## CODE QUALITY SIGNALS
  Recurring issues: none in-PR.
  New unrecorded patterns captured (see below): clean-install verification; ts-node config-loader trap.

## PROCESS EFFICIENCY
  Automation opportunities: the gate IS the automation — it converted four post-mortems of prose
    into an enforced check. Remaining gap: the check is not yet a *required* status check in branch
    protection, so a fast self-merge (this PR merged ~7 min after creation) could still bypass a RED.
  Iteration: normal (2). The single failure→fix cycle was the gate doing its job.
  CI status: 1 failure (ts-node), fixed; final green.

## HEADLINE LEARNING
  "Verified locally" ≠ "verified on a clean install." `jest.config.ts` needs `ts-node`, which Jest
  treats as an optional peer. It was present transitively in the local dev `node_modules`, so local
  verification (even after `npm ci` on an accreted tree) passed — but a clean `npm ci` on CI did not
  install it, and the gate went RED. Fixed by declaring `ts-node` as an explicit devDependency and
  re-verifying against `rm -rf node_modules && npm ci`. The CI-gate PR was caught by its own gate:
  the strongest possible validation of the gate's value, since two rounds of local verification missed it.

## KNOWLEDGE UPDATES
  - process-patterns.md (Follow-Up Discipline): added the "no CI gate recommendation finally LANDED
    in #150 + gate validated itself" entry, and the "verified locally ≠ verified on a clean install"
    headline learning.
  - testing-patterns.md (Test Design): added the `jest.config.ts` requires explicit `ts-node`
    devDependency / clean-install-verification entry.
  - metrics/post-mortem-metrics.json: appended PR #150 entry.
  - metrics/dashboard.html: regenerated embedded METRICS_DATA.

## RECOMMENDATIONS (ranked)
  1. Make "CI / Typecheck, lint & test" a REQUIRED status check in branch protection on `main`.
     Without it, the ~7-min self-merge window can still land a RED (the family-digest #12 caveat,
     already noted in process-patterns line 37, now applies to this repo).
  2. Adopt `rm -rf node_modules && npm ci` as the standard pre-PR verification for any change that
     touches config-loader deps, lockfiles, or CI — not the accreted local tree.
  3. Consider a follow-up policy call on `--max-warnings 0` (4 pre-existing lint warnings are
     currently non-blocking); separate PR, would turn the gate red on existing warnings first.
