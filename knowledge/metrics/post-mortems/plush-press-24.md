# Post-Mortem: plush-press PR #24 — Add the CI workflow: typecheck, lint, build, and tests on every PR.

Branch: chore/ci → main | Author: padminipyapali | Created 2026-06-11T05:32:04Z, merged 2026-06-11T05:37:46Z (~6 min)
Size: +31 -0 across 1 file, 1 commit. Squash-merged as d1de5db.

## Context

Config-only PR executing recommendation #2 of the plush-press #23 post-mortem — a recommendation that had drifted across three consecutive post-mortems (#15, #16, #23): the repo has 155 tests and self-merges within seconds, so local gates were the only gates. This PR closes the tracked "no CI" gap with a single workflow file (`.github/workflows/ci.yml`): one Ubuntu job scoped to `studio/`, `npm ci` → typecheck → lint → build → `npm test`, on every PR and pushes to main. Node 20 (matches `engines`), npm cache keyed on `studio/package-lock.json`, per-ref concurrency cancellation.

## Local Review (pre-push)

Not tracked — no `## Local Review` section in the PR body (all localReview fields null). The body does record skips inline: "Steps skipped: 3, 4a, 4b, 4c (config-only, single file, diff-verifiable)." Justification given for missing tests: the workflow itself is the test surface; YAML parse validated locally; first CI run on the PR proves it.

## Step Compliance

- Steps run: 1, 2a, 2b, 4d (CI — the workflow's own first run), 5 → 5/9, compliance rate ~56%.
- Steps skipped: 3, 4a, 4b, 4c — reason: "config-only, single file, diff-verifiable."
- Skip assessment: **good**. CI check "studio" passed SUCCESS on the PR's first run (60 s), zero review comments, zero post-merge fixes (main HEAD is still d1de5db at analysis time). No skipped step would have caught anything because nothing escaped.

## Step Timing

Not tracked (no `## Step Timing` section). This is the third consecutive plush-press PR where #23's recommendation #3 (add Step Timing to the PR template) has not landed.

## Review Friction (post-push)

- Review rounds: 1 (no CHANGES_REQUESTED, no reviews at all).
- Comments: 0 inline, 0 general. All categories zero.
- Timeline: created → merge: 0.1 h. Self-merge with no peer review (solo project norm).

## Adversarial Review Effectiveness

- adversarialCatchRate: **unmeasured** — adversarial review (4c) was skipped and there are zero post-push findings, so there is no denominator to compute a catch rate from. Per metric-integrity policy this is recorded as "unmeasured", not 0 or 1.
- Covered but missed: none (no findings). Not covered: none.

## Fix-Up Metrics

- Post-merge fix rate: 0% (0 post-merge fix commits; verified main HEAD unchanged since merge).
- Pre-merge catch rate by step: 4a: 0 | 4b: 0 | 4c: 0 | 4d: 0 | post-push: 0.
- Pre-merge iteration count: 1 (healthy). Notably better than baby-name-picker #150, the equivalent CI-gate PR, which needed 2 iterations after its own gate caught a missing `ts-node` devDependency. plush-press verified script names against `studio/package.json` before pushing and went green first try.
- Fix-up taxonomy: all zero. Legacy fix-up ratio: 0% (0/1 commits).

## Planning Quality

- Description: complete — Summary, Test plan with explicit skip justification, scope rationale citing the three post-mortems.
- Scope: clean. Single file, single concern, 31 lines. Branch lifetime ~6 minutes.
- Planning checklist: entry points / perf-cost sections n/a for a config-only workflow file. No gaps material to this PR class.

## Code Quality Signals

- Recurring issues: none.
- New unrecorded patterns: none new — this PR is the *resolution* of an already-recorded pattern (recommendation drift → artifact conversion, process-patterns.md "Follow-Up Discipline").

## Process Efficiency

- Automation opportunities: none in this PR; this PR *is* the automation (it converts three prose recommendations into a toolchain-enforced gate).
- Iteration: efficient (1 round, green first run).
- CI status: all passed — check "studio" SUCCESS in 60 s on the PR's first and only run.

## Knowledge Updates

- `~/.claude/knowledge/process-patterns.md` — strengthened the "no CI gate recommendation finally LANDED" entry (Follow-Up Discipline) with plush-press #24: drift count of 3 post-mortems before artifact conversion now confirmed in a second project (baby-name-picker took 4); green-on-first-run contrast with #150's red-first-run; residual required-check caveat restated.

## Recommendations (ranked)

1. **Mark the "studio" check required in branch protection.** The PR self-merged in under 6 minutes — exactly the window a required check exists to close. The workflow existing on `pull_request` does not block a fast self-merge of a RED (family-digest #12 caveat, repeated at baby-name-picker #150, repeated again here).
2. **Land #23's recommendation #3 — `## Step Timing` in a plush-press PR template** (`.github/PULL_REQUEST_TEMPLATE.md`). It has now drifted two PRs (#23 → #24). Per the line-37 escalation rule, convert to an artifact before it hits three.
3. **Cite the drift-count pattern at first occurrence.** Two projects now show the same 3-4 post-mortem drift before a CI recommendation lands. Future post-mortems that recommend infrastructure should reference the Follow-Up Discipline entry and demand a same-day artifact PR at drift #1, not #3.
