# POST-MORTEM: second-brain PR #911 — feat(calendar): free-days search module — travel-day derivation + gap scan (PR-A of #907)

**Branch:** feat/free-days-module → main | **Author:** padminipyapali | **Merged:** 2026-07-19 (squash `b07ee2f`)
**Size:** +714 −0 across 4 files, 1 commit (squashed)

## Summary

PR-A of issue #907 (free-days search): a **pure computation module** (`packages/server/src/services/free-days.ts`) + 19 unit tests + a living spec (`docs/FREE_DAYS_SPEC.md`), plus a one-line CLAUDE.md pointer. Zero behavior change — nothing imports the module at runtime yet; PR-B wires it into the calendar-query path and will carry `Closes #907`. Clean split: the reviewable pure engine lands first, the integration lands second.

## Local Review (pre-push)
- **CodeRabbit CLI:** clean, 0 findings.
- **Adversarial checklist (Tier 0):** 11 PASS / 0 FAIL.
- **Critic (fresh context):** APPROVE with 1 should-fix — trip/travel stemming asymmetry (a *false-free* direction) — found and fixed pre-PR; nits fixed. Hand-traced the regex adversarial set; DST-crossing fixture verified.
- **Shift-left:** 100% — every issue (1 should-fix + nits) caught pre-push; 0 escaped to post-push or post-merge.

## Step Compliance
- Steps run: 1 (plan, incl. adversarial plan review), 2a/2b (implement), 3 (test), 4a/4b/4c (simplify + CodeRabbit + adversarial), 4d (CI), 5 (push/PR) — full loop (9/9).
- Steps skipped: none. Compliance 100%. Skip assessment: **good** (no post-merge issues).
- Note: PR body used the narrative `## Review`/`## Tests` format rather than the machine-readable `## Local Review`/`Steps skipped:` lines; compliance reconstructed from the body + team-lead handoff. `## Step Timing` section absent → `stepTiming: null`.

## Planning Quality
- **Description:** complete — Summary, per-function behavior breakdown, Docs, Tests (test plan), explicit "do not close #907 on merge" multi-PR note.
- **Scope:** clean. Single-concern (pure module + spec), zero runtime wiring, PR-B deferred. Branch lifetime < 1 hour.
- **Adversarial PLAN review** returned REVISE-PLAN with **5 findings LOCKED before implementation**: (1) OOO-classifier-failure safety signal (degraded mode over-marks), (2) keyword narrowing, (3) minDays floor, (4) PR split (A/B), (5) boundary honesty (`openStart`/`openEnd` → render "N+ days"). Recorded in `docs/FREE_DAYS_SPEC.md` as locked decisions.

## Review Friction (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 human general (1 Vercel bot comment excluded).
- Self-merged 62s after PR open — the local review gate (critic + CodeRabbit + adversarial) was the review; consistent with the project's lightweight self-merge flow.
- Timeline: created → merged ≈ 1 min (all review pre-push).

## Fix-up Metrics
- **Post-merge fix rate: 0.0** — no follow-up fix PRs touch `free-days.*` (searched merged PRs > 911 and `free-days in:title`). Quality held through all gates.
- **Pre-merge catch by step:** the 1 should-fix (stemming asymmetry) caught by the critic code review (4b/internal). Squash-merge hides discrete fix commits → attribution reconstructed from the `## Review` narrative, not `git log`.
- **Pre-merge iteration count: 1** (healthy) — plus a distinct plan-stage REVISE cycle (5 findings) that cost zero code churn.
- **Fix-up taxonomy:** correctness ×1 (the false-free stemming asymmetry). Legacy fixupCommitRatio 0.0 (squashed to 1 feature commit — a positive example of the squash-discipline rule).

## CI
- All checks SUCCESS (Vercel preview + status rollup). Full server suite 3292 passed; lint + typecheck clean.

## Adversarial Review Effectiveness
- Pre-push catch potential: 100% for what was caught (checklist 11/11 PASS; critic caught the one substantive should-fix; CodeRabbit clean).
- No "covered but missed" — nothing escaped to post-push/post-merge.
- adversarialCatchRate = **1.0**, computed from evidence (all issues caught locally, 0 escaped).

## Knowledge Updates
- **process-patterns.md → Planning Discipline:** NEW pattern — *for asymmetric-cost classification features, the adversarial PLAN review must force an explicit LOCKED fail-direction decision (degrade toward the conservative side) recorded in the living spec before implementation.* Sourced to #911; framed as the fail-direction complement to the degenerate-mode family (#791/#846).
- **process-patterns.md → Process Compliance:** strengthened the "squash adversarial fix commits" rule with #911 as a positive confirmation (should-fix amended into the single feature commit; fixupCommitRatio 0.0), noting the tradeoff that post-squash step-attribution must be recovered from the PR-body `## Review` narrative.

## Recommendations
1. **Keep the plan-stage fail-direction lock as standard practice for classification features.** The 5 plan findings (esp. the OOO-failure safety signal) were the highest-leverage catches in this PR — fixed at the cheapest possible stage, zero code churn. Generalize: whenever a feature classifies real-world state with unequal misclassification costs (free/busy, covered/gap, safe/unsafe), name the asymmetry and lock the degraded-branch direction in the spec.
2. **Adopt the pure-module-first PR split as the default for compute-heavy features.** PR-A (pure engine + tests + spec, zero runtime importers) is trivially reviewable and mergeable; PR-B carries the wiring + `Closes`. This kept a 714-line change single-concern and low-risk.
3. **Minor process gap:** the PR body used the narrative `## Review` format instead of the machine-readable `## Local Review` / `Steps skipped:` / `## Step Timing` sections. Metrics were fully reconstructable here, but adding those structured sections (per the existing "PR body templates" rule) would make step-timing and compliance extraction automatic rather than inferred.
