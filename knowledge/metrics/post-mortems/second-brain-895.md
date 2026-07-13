# Post-Mortem: second-brain PR #895 — feat(admin): read-only Config viewer panel

Branch: `feat/admin-config-panel` → `main` | Author: padminipyapali | Merged 2026-07-13T06:01:49Z (squash)
Size: +1153 −64 across 18 files, 2 commits | Closes #891; part of #881.
Batch note: second admin slice. Shared ground truth as in the #892 report.

## Local Review (pre-push)
- **Adversarial critic (fresh context): PASS with 5 hardening catches committed.** The critic did not just approve — it committed real hardening on top of the implementation: (1) threaded the **real** calendar-service init state into `assembleAdminConfig` so `COVERAGE_CHECK` reflects whether the scheduler actually started rather than mere env presence (server builds the calendar service in a try/catch — a construction failure previously misreported the feature as active); (2) added `API_TOKEN` to the secret-leak assertion; (3) added an invalid-bearer-token 401 test; (4) covered the disabled branch of the presence-only flags; (5) surfaced the missing search-boost weights (allTerms, caption, tag) the panel was silently dropping. Items 1 and 5 are correctness; 2–4 are test-coverage catches.
- **CodeRabbit CLI: 6 findings — 5 fixed, 1 rejected (1 iteration).** The rejected one was an in-flight model-id swap, out of scope, filed as follow-up **#894**. The 5 fixed categories are not individually enumerated in the PR body.
- **Shift-left:** all real findings caught locally (critic + CodeRabbit); nothing escaped.
- Gates at `33cb65f`: lint clean, build clean, server 3144 passed / 57 skipped, web 461 passed.

## Step Compliance
- Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (9/9). No skips. Compliance 100%.

## Step Timing (from PR body)
| Step | Duration | Notes |
|------|----------|-------|
| Implement + Test | ~35 min | model-id constant extraction (37 usages) inflated this |
| Rebase onto #892 | ~10 min | serial-merge; conflict mechanical |
| Local review | ~35 min | tie for bottleneck |
| Push + PR | ~2 min | |
| **Total** | **~82 min** | |

## Review Friction (post-push)
- 1 round, 0 CHANGES_REQUESTED, 0 human reviews, only `vercel[bot]`. Opened→merged ~41s. Self-merge; critic is the peer-review substitute.

## Adversarial Review Effectiveness
- **Pre-push catch rate: 5/10 by the adversarial gate (n=10).** This is the strongest adversarial showing of the seven: the critic caught the truthful-calendar-gating correctness bug (env presence ≠ scheduler actually started) that only a semantic reviewer would catch — CodeRabbit cannot know that a try/catch construction failure makes the env-derived flag lie. The secret-leak coverage hardening (API_TOKEN) is defense-in-depth on the PR's hard security rule (never serialize a secret value).
- Covered but missed by neither: n/a — this PR's split was genuinely complementary (critic on semantic correctness, CodeRabbit on the rest).
- Not covered (new categories): none.

## Fix-up Metrics
- Post-merge fix rate: **0%**.
- Pre-merge catch by step: 4c (CodeRabbit)=5, 4d (adversarial)=5.
- Pre-merge iteration count: **1**.
- Fix-up taxonomy: correctness=2, test-quality=3, defensive-coding=5 (the 5 CodeRabbit fixes are bucketed as defensive-coding — their specifics weren't enumerated in the PR body; treat that bucket as approximate).
- Legacy fix-up ratio: 0.5.

## Planning Quality
- Description: **complete** — Summary, model-id extraction rationale, secret-safety rule + test, gate results. Perf/Cost section absent (series-wide gap; benign for a read-only assembler).
- Scope: clean, single concern. The 37-usage model-id constant extraction is a defensible zero-drift refactor folded into the panel that consumes it (matches the "don't split data from its sole consumer" cap-breach guidance).
- PR size 1217 LOC over the 600 cap — driven by the constant extraction touching 18 files, not new logic. Acceptable; note the pattern.

## Code Quality Signals
- The model-id extraction surfaced a real latent inconsistency (the `/bug` handler uses an older Haiku id), rendered visibly and tracked as #894 rather than silently "fixed" — good out-of-diff-finding discipline.
- New unrecorded patterns: none code-level.

## Process Efficiency
- Automation opportunity: the "env presence ≠ feature actually initialized" trap is a recurring correctness class for config panels — a test that constructs the service and asserts the flag matches the *constructed* state (not env) would guard it.
- CI: Vercel SUCCESS. Iteration: efficient.

## Recommendations
1. When a panel reports feature state, always derive it from the constructed/initialized service instance, not raw env — the critic's #1 catch here should be a checklist item for admin/config surfaces.
2. Add Perf/Cost line (series-wide).
