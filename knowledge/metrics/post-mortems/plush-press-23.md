# Post-Mortem: plush-press PR #23 — Add the studio API layer: scenes, render, generate, tune, lock (MVP PR-1c)

- **Branch:** feat/studio-routes → main | **Author:** padminipyapali | **Merged:** 2026-06-11T05:23:47Z (squash 8977316)
- **Size:** +2298 / -7 across 25 files, 2 commits (~1080 hand-written LOC; the rest tests/config — 60 new tests, suite at 155/155)
- **Open-to-merge:** 23 seconds (self-merge). Branch lifetime (first commit → merge): ~1.26 h.

## Local Review (pre-push)

- **CodeRabbit (4b):** ATTEMPTED — CLI hung 52 minutes with zero output and was killed. Re-attempt skipped by explicit user directive. Recorded in PR body (`Steps skipped:` line) with substitution noted. Findings: not tracked (null).
- **Adversarial / fresh-context critic (4c):** 9 findings — 0 must-fix, 3 should-fix, 6 nits — **all 9 fixed pre-push** in commit `6abd908`:
  - Paid-call pre-flight on typo'd book/scene (validation)
  - Typed error codes replacing message sniffing (defensive-coding)
  - ENOENT-only template 404 (correctness)
  - 6 nits (style)
  Critic explicitly verified: full path-traversal param sweep, front-matter byte-identity, chain.json concurrency via withChainLock, key hygiene (asserted in tests).
- **Shift-left:** 9/9 known findings caught and fixed locally; 0 post-push findings.

## Step Compliance

- **Steps run:** 1, 2a, 2b, 3, 4a, 4c, 5 (7/9 → 78%)
- **Steps skipped:** 4b (CodeRabbit — tool failure, recorded with reason and substitution); 4d (no CI configured: `statusCheckRollup: []`; typecheck/lint/build ran locally as step 3)
- **Skip assessment:** neutral — no post-push review or CI ran, so there is no independent detector to test the skips against. The 4b skip is the defensible "tool-failure with recorded substitution" shape (fourth bucket in the 4b-skip taxonomy).

## Step Timing

Not tracked — no `## Step Timing` section in the PR body. (Known anecdotally: ~52 min lost to the CodeRabbit hang; total wall-clock first-commit→merge ~75 min.)

## Review Friction (post-push)

- Review rounds: 1 (no reviews at all — self-merge 23 s after creation)
- Comments: 0 inline, 0 general. All categories 0.
- No peer review; the fresh-context critic was the independent gate, run pre-push.

## Adversarial Review Effectiveness

- **adversarialCatchRate: "unmeasured"** (metric integrity). All 9 known findings were caught by the local adversarial gate (9/9), but zero independent post-push detectors ran (no peer review, no CodeRabbit output, no CI), so an escape-rate denominator does not exist. Recording 100% would be a fabricated baseline.
- Covered-but-missed: n/a (no post-push findings to attribute).
- Post-merge fix rate: 0.0 as of this analysis (PR #23 is the newest merge; no follow-up fix PRs/commits exist).

## Fix-up Metrics

- Post-merge fix rate: 0% (0 post-merge fix commits)
- Pre-merge catch by step: 4a: 0 | 4b: 0 | 4c (CodeRabbit): 0 | 4d (adversarial): 9 | post-push: 0
- Pre-merge iteration count: 1 (single critic round → single fix commit) — healthy
- Fix-up taxonomy: validation 1, defensive-coding 1, correctness 1, style 6
- Legacy fix-up ratio: 50% (1 fix / 2 commits) — inflated by the unsquashed critic-fix commit; iteration count (1) is the honest signal.

## Planning Quality

- Description: **complete** — Summary, Test plan, Performance & Cost Impact, Review section, `Steps skipped:` line, entry points exhaustively enumerated (fresh launch, zero-scene book, half-tuned resume, angle-before-plate 409, missing file/key, partial candidate failure, duplicate scene, unknown template, bounds, typo'd ids before any paid call).
- Scope: clean single concern (API wiring layer), no redesign indicators, branch lifetime ~1.26 h.
- **600-LOC budget exceeded** (~1080 hand-written vs 600 target) — justified as an atomic 10-route surface with thin routes and logic concentrated in 3 services; declared and paid for with per-entry-point tests + typed `CodedError` spine + fresh-context critic. Captured as the "API-surface variant" of the >600-LOC exception in process-patterns.md.

## Code Quality Signals

- Recurring issue: none post-push. Critic's top finding class (message sniffing instead of typed error codes) maps to the existing "error message specificity / typed error" conventions — caught by the gate as designed.
- New patterns: CodeRabbit silent-hang failure mode; API-surface >600-LOC exception; tool-failure bucket for the 4b-skip taxonomy. All captured.

## Process Efficiency

- **Automation opportunities:** (1) wrap CodeRabbit CLI in `timeout 600` — the 52-min unbounded wait was pure loss; (2) repo still has no CI (`statusCheckRollup: []`) — recurring across plush-press; a GitHub Actions typecheck+lint+vitest workflow would make the local gates non-optional; (3) PR body lacks `## Step Timing` — timing remains untracked across all plush-press PRs.
- Iteration: efficient (1 round, all findings fixed in one commit).
- CI status: no checks configured.

## Knowledge Updates

1. `process-patterns.md` (Iteration Velocity): strengthened the CodeRabbit-timeout entry with the 52-min silent-hang mode and the `timeout 600` wrapper mandate.
2. `process-patterns.md` (PR Sizing): added the **API-surface variant** of the >600-LOC exception (thin routes + single typed-error spine + per-entry-point tests as the payment).
3. `process-patterns.md` (4b-skip taxonomy): added the **fourth bucket** — tool-failure skip with recorded substitution; reaffirmed the hook design should block only UNRECORDED skips.

## Recommendations (ranked)

1. **Wrap every CodeRabbit CLI invocation in `timeout 600 ...`** (then retry-with-backoff). The 52-minute hang is the single largest avoidable cost in this PR's loop; a wrapper caps it at 10 min. Candidate for a shell alias or the orchestrator protocol itself.
2. **Configure CI for plush-press** (typecheck + lint + vitest on PRs). Now several PRs in with `statusCheckRollup: []`; a 23-second self-merge means local gates are the only gates, and they are unenforced.
3. **Add `## Step Timing` to the plush-press PR template.** Timing is null on every plush-press PR; the CodeRabbit hang would have been visible as a flagged bottleneck instead of anecdote.
4. **Squash critic-fix commits (or prefix `review-fix:`)** to keep the legacy fix-up ratio meaningful (50% here despite a healthy 1-iteration loop).
