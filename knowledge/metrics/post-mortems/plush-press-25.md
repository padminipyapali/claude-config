# POST-MORTEM: plush-press PR #25 — Add the Scene studio UI: roster, generate grid, tune loop, lock, and angles (MVP PR-1d).

Branch: feat/studio-ui → main | Author: padminipyapali | PR open-to-merge: ~2 min (dev window ~8h, first commit 2026-06-11T20:27Z → merge 2026-06-12T04:24Z)
Size: +4149 -35 across 24 files, 2 commits. Squash-merged as d1477d2. CI (studio workflow): SUCCESS.

## Local Review (pre-push)

- CodeRabbit: skipped — excluded by user directive (recorded as `Steps skipped: 4b` in PR body). Tracked as null, not 0.
- Adversarial (fresh-context critic): 9 findings (0 must-fix, 5 should-fix, 4 nits), all 9 fixed pre-push in commit 8960902. Critic independently re-ran the verification gate. A dedicated paid-API audit confirmed every POST fires only from an explicit click.
- Shift-left rate: 100% — all 9 tracked issues caught and fixed locally; 0 post-push findings.
- adversarialCatchRate: **unmeasured** — no post-push review occurred (solo workflow, 0 GitHub comments), so there is no independent post-push denominator to compute a catch rate from. Recorded per metric-integrity rule, not hardcoded.

## Step Compliance

- Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9)
- Steps skipped: 4b (CodeRabbit) — user directive
- Compliance rate: 89%
- Skip assessment: **neutral** — no post-push review data exists to test whether CodeRabbit would have caught anything the critic missed; the skip was a deliberate user directive, not drift, and was correctly annotated in the PR body.

## Step Timing

Not tracked — PR body has no `## Step Timing` section. Narrative timing context (from orchestrator): the original implementer stalled twice on hung commands (600s watchdog kills) and was replaced by a fresh-context agent, so wall-clock (~8h) materially overstates active implementation time. The replacement-agent recovery is the dominant timing event; see Learnings.

## Review Friction (post-push)

- Review rounds: 1 (0 CHANGES_REQUESTED; no reviews at all)
- Comments: 0 inline, 0 general
- Timeline: created → merge: ~2 min. Self-merge with no peer review (expected for this solo workflow; the fresh-context critic is the review gate).

## Adversarial Review Effectiveness

- Pre-push catch potential: n/a upward — nothing escaped to post-push, so the checklist's residual miss rate is unmeasurable this PR.
- Covered but missed: none observable (0 post-push findings).
- Not covered (new categories): none from review comments. One process-level near-miss is notable: the Turbopack repo-root bug was invisible to the entire 175-test suite and was caught only by Step 3's live-dev-server drive — i.e., a *testing-method* gap, not a checklist gap. Captured in testing-patterns.md and typescript-patterns.md.

## Fix-up Metrics

- Post-merge fix rate: 0% (0 post-merge fix commits as of analysis; no open PRs, no follow-ups). 
- Pre-merge catch rate by step: 4a (simplify): 0 | 4b (internal): 0 | 4c (CodeRabbit): 0 | 4d (adversarial/critic): 1 fix commit (8960902, covering all 9 findings) | post-push: 0.
  - Attribution: commit 506ad96 = feature; commit 8960902 = "Apply the critic's review fixes" → 4d.
- Pre-merge iteration count: 1 (single critic round → single fix commit → push) — healthy.
- Fix-up taxonomy (per finding, 9 total in the one fix commit):
  - correctness: 5 — TunePanel keyed by working image (stale keep would lock the wrong file); resume only adopts last tune when its origin template is in the wide group (¾-tune was becoming the wide-lock source); junk-scenes front-matter filter in listScenes/getScene; GeneratePanel ignores in-flight round landing after an angle/template switch; re-prefill preserves operator-typed slot values.
  - validation: 1 — /api/file markdown allowlist restricted to exactly prompts/style.md.
  - a11y: 1 — lock confirm dialog Escape-to-cancel + focus on Cancel.
  - test-quality: 1 — TunePanel happy path previously untested (POST body, before/after render, both keep paths).
  - style: 1 — tune keep field clears after keep-after/keep-before.
- Legacy fix-up ratio: 50% (1 fix / 2 commits) — inflated by the squash-into-two-commits structure; not a quality signal here.

## Planning Quality

- Description: complete — Summary, Designs (with committed screenshots), Review, Test plan, Steps skipped line. Note: review data lives under `## Review`, not the canonical `## Local Review` header the metrics parser expects.
- Scope: large (+4149) but deliberate — an MVP UI slice. Two scope additions were explicitly adjudicated: the repo-root fix (blocking — the UI literally couldn't serve images without it) and the junk-scenes fix (critic ruled it IN because the new roster made the latent PR-1c bug user-reachable and paid-API-triggerable). Both documented in the PR body with rationale. No redesign indicators.
- Branch lifetime: ~8h wall-clock (inflated by the stalled-implementer episode).
- Exceeds the 600-LOC guideline substantially; mitigations present (181 tests, fresh-context critic, live-server drive), but future studio tabs should be sliced per-panel where feasible.

## Code Quality Signals

- Recurring issue this PR: wrong-image/wrong-file routing under stale component state (2 of the 5 should-fixes: stale TunePanel keep, resume adopting a ¾-tune as wide source). For a tool whose entire job is locking the *right* image, "which file does this action actually operate on after N state transitions" is the PR's dominant bug class — the critic's targeted strength.
- New patterns captured (see Knowledge Updates): bundler-relocation path resolution, live-server smoke gate, stalled-implementer replacement, latent-bug-made-reachable scope rule.

## Process Efficiency

- Automation opportunities: a CI/dev smoke that boots `next dev` and curls one filesystem-backed route would mechanize the Turbopack-class catch (unit tests are structurally blind to it). Candidate for the studio CI workflow.
- Iteration: efficient — 1 critic round, all findings fixed in one commit, CI green first try, ~2 min open-to-merge.
- CI: all passed (single `studio` check, 69s).

## Learnings (headline)

1. **Agent recovery is a disk-state property.** The implementer stalled twice on hung commands (600s watchdog). Replacing it with a fresh-context agent worked *because the WIP lived on disk in the worktree*, not in the dead transcript. Replace, don't resuscitate; brief implementers to write to disk incrementally and to background long-running commands. → orchestrator-protocol.md (Error Recovery).
2. **File-injected tests masked a real runtime bug.** Turbopack relocates modules into `.next/`, so `__dirname` two-levels-up root resolution 404'd every route — all 175 tests green. Only driving the live dev server exposed it. Path-resolution code in bundled apps needs a real-server smoke; resolve roots by marker-directory walk-up. → testing-patterns.md, typescript-patterns.md.
3. **Critic scope adjudication.** The junk-scenes fix (merged PR-1c code) was ruled INTO the PR over single-concern purity because the new UI made the latent bug user-reachable (clickable, paid-generatable non-scenes). Test: does this PR turn the sibling bug from latent into user-facing? → process-patterns.md (Scope Decisions).

## Knowledge Updates

- `orchestrator-protocol.md` → Error Recovery: stalled-implementer replacement via on-disk WIP.
- `testing-patterns.md` → Mocking Pitfalls: real-dev-server smoke for module-relative path resolution.
- `typescript-patterns.md` → ESM / Module Patterns: marker-directory walk-up instead of `__dirname` arithmetic.
- `process-patterns.md` → Scope Decisions: latent-bug-made-reachable ride-along rule.
- Metrics appended (373rd PR); dashboard regenerated.

## Recommendations

1. Add a dev-server smoke step (boot `next dev`, curl one `/api/file` route) to the studio CI workflow so the Turbopack bug class is caught mechanically, not by ad-hoc driving.
2. Use the canonical `## Local Review` header and add a `## Step Timing` table in future PR bodies — #25's review data parsed only via its prose `## Review` section, and timing is untracked.
3. Spawn briefs for implementers should include the hung-command hygiene rule (background long-running processes) — two watchdog kills were spent before the replacement strategy was applied.
4. Keep slicing studio tabs into sub-600-LOC PRs where panels allow; #25's size was survivable only because the critic + live-drive gates were strong.
