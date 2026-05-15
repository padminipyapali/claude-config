# Post-Mortem: second-brain PR #635

**Title:** feat(projects): add per-subtask notes/description on project detail
**Branch:** feat/subtask-notes -> main
**Author:** padminipyapali
**Created:** 2026-05-15T01:19:51Z
**Merged:** 2026-05-15T01:49:23Z
**Time to merge:** ~30 minutes (0.5 hours)
**Size:** +834 / -57 across 12 files, 1 commit
**Closes:** #634

## Summary

Adds expandable inline notes to each subtask row on the project detail view. Notes are project-scoped via `todo_status.description`, capped at 2000 chars (DB CHECK + server validation + textarea maxLength), saved on blur / collapse / Cmd+Enter, with optimistic updates and focus-aware rollback. Migration 017 adds the column. Preview surfaces (TodayCard, ProjectsStrip, DigestArchive, weekly review) are intentionally excluded from the payload.

## Local Review (pre-push)

- **`/simplify`**: 3 small cleanups (flattened nested ternary, removed redundant normalization, collapsed branch in service). Style category.
- **CodeRabbit CLI**: 2 in-scope findings, both fixed:
  1. `updateSubtaskDescription` restricted to project-linked rows (defensive coding -- user/scope guard).
  2. Focused-sync allows revert when prop diverges from `lastSavedRef` (defensive coding -- optimistic update correctness).
- **Adversarial review**: PASS on all 10 universal conventions + category-gated checks (SQL migration, server route, optimistic update, a11y). 0 findings.
- **Lint / build / tests**: pass (affected suites; unrelated pre-existing failures noted).

Step Timing section: not present in PR body (older format / not tracked for this PR).

## Step Compliance

The `Steps skipped:` line is absent from the Local Review section. Set `stepCompliance` to `null` (not tracked).

## Review Friction (post-push)

- **Review rounds**: 1 (no CHANGES_REQUESTED; self-merged 30 min after open).
- **Comments**: 0 substantive (1 Vercel bot comment, excluded).
- **Reviewers**: none (solo dev / self-merge, consistent with project norm).
- **Timeline**: created -> merged in 30 minutes.

No peer review (acceptable per solo-dev workflow for this repo). Local review is the gate.

## Adversarial Review Effectiveness

No post-push findings to back-test the checklist against. `adversarialCatchRate = "unmeasured"` per global CLAUDE.md rule -- never hardcode the rate from absence of evidence.

The local adversarial review reported PASS with 0 findings. Combined with 0 post-push findings, this is consistent with the checklist holding up, but the sample provides no signal either way on the rate.

## Fix-Up Metrics

- **Post-merge fix rate**: 0% (no follow-up fix PRs within 48h; checked `gh pr list --search "merged:>2026-05-15"`).
- **Pre-merge catch rate by step**:
  - 4a (simplify): 3 findings fixed.
  - 4b (internal): 0.
  - 4c (CodeRabbit): 2 findings fixed.
  - 4d (adversarial): 0.
  - post-push: 0.
- **Pre-merge iteration count**: 1 (healthy -- single commit, local review caught and fixed everything before push).
- **Fix-up taxonomy**: style: 3 (simplify cleanups), defensive-coding: 2 (CodeRabbit fixes -- user scoping + optimistic revert correctness).

All 5 fixes were caught **before** push. The shift-left rate is effectively 100% for this PR.

## Planning Quality

- **Description**: complete (Summary, Test plan, Perf & Cost, Local Review sections all present).
- **Scope**: clean -- single concern (per-subtask notes), single commit.
- **Branch lifetime**: ~30 min.
- **PR size**: 891 LOC total (+834/-57), approaches the 600-LOC soft cap by total but feature is cohesive and acceptable.
- **Planning checklist**: entry points enumerated (new subtask, existing, detach/reattach, DONE rows, standalone TODO, oversize input); Perf & Cost section present and specific.

## Code Quality Signals

- **Recurring issues**: none in this PR; CodeRabbit's two findings (user scoping on UPDATE, optimistic-update revert behavior) are already covered by global patterns:
  - User scoping: global CLAUDE.md Defensive Coding (`scope data access to the authenticated user`).
  - Optimistic update sync: `react-patterns.md` (focused-sync / lastSavedRef pattern).
- **New unrecorded patterns**: none. Existing knowledge files anticipated both findings.

## Process Efficiency

- **Automation opportunities**: none new. CodeRabbit caught the two issues that adversarial review missed -- consistent with their complementary roles (CodeRabbit catches per-file static issues; adversarial review catches cross-cutting conventions).
- **Iteration**: efficient (1 round).
- **CI status**: Vercel deployment ignored (server-only path). No failing checks.

## Knowledge Updates

No knowledge file updates required:
- All issues caught locally were instances of already-captured patterns.
- No new code patterns or process gaps surfaced.
- Adversarial review checklist remains adequate for this PR's domain.

Metrics file appended: `~/.claude/knowledge/metrics/post-mortem-metrics.json`.
Dashboard regenerated: `~/.claude/knowledge/metrics/dashboard.html`.

## Recommendations

1. **Add Step Timing to future PR bodies.** This PR was merged in 30 min -- a useful data point for the cycle-time series, but the per-step breakdown was not captured. The orchestrator should emit the `## Step Timing` table for every PR going forward so cycle-time bottleneck trends are visible in the dashboard.
2. **Add `Steps skipped:` line to Local Review.** Without it, step compliance defaults to `null` and the compliance trend gets noisy. Even a `Steps skipped: none` line resolves this.
3. **No process changes.** The 1-iteration / 0-post-push-finding outcome is the target state. Maintain.
