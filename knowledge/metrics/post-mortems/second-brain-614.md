# Post-Mortem: second-brain PR #614

**Title:** chore(meta): add PR template enforcing Local Review and Perf & Cost sections
**Branch:** chore/pr-template -> main | **Author:** padminipyapali
**Merged:** 2026-05-06T14:21:22Z (3.8 min after open)
**Size:** +32 -0 across 1 file, 1 commit

## Context

Triggered by family-digest #12 escalation rule: PRs #603, #606, #609 all merged
without Local Review / Steps skipped / Perf & Cost annotations. This PR promotes
the recommendation from prose ("please add these sections") into an enforceable
artifact (`.github/PULL_REQUEST_TEMPLATE.md`).

The PR body itself uses the new template as a self-test — every section is filled
including a single-line `Steps skipped:` annotation. This is a meta-correct
demonstration: the artifact is validated against itself before it ships.

## Local Review (pre-push)

- **/simplify (4a):** N/A — single static markdown file.
- **CodeRabbit CLI (4b):** skipped — non-code change.
- **Adversarial (4c):** PASS — six required sections present in correct order;
  `Steps skipped:` rendered as a single grep-able line at column 0 (not buried
  inside an HTML comment); file path uses correct case `.github/PULL_REQUEST_TEMPLATE.md`.

Shift-left rate: n/a (no findings to attribute).

## Step Compliance

- **Run:** 1, 2a, 3, 4c, 5  (5/9)
- **Skipped:** 4a, 4b — reason: pure markdown template, no code to simplify or
  static-analyze. 2b implicitly skipped (no hardening pass for a static doc).
  4d (CI) implicitly satisfied — Vercel preview SUCCESS.
- **Compliance rate:** 5/9 = 0.556
- **Skip assessment:** good — no post-merge issues; skipped steps were genuinely
  inapplicable to a static markdown artifact.

## Step Timing

Not tracked in PR body (no `## Step Timing` section). PR lifecycle = 3.8 minutes
end-to-end, suggesting a tight implement→adversarial→push loop. Critic-time
rebase against #610 (noted by orchestrator) consumed un-recorded pre-push minutes.

## Review Friction (post-push)

- Review rounds: 1 (no CHANGES_REQUESTED, no human reviews — self-merged).
- Comments: 0 inline, 1 general (vercel bot — excluded).
- Categories: all zero.
- Timeline: created -> merge: 3.8 minutes. No external reviewer involved.

## Adversarial Review Effectiveness

Pre-push catch potential: n/a — zero findings reported and zero post-merge
issues. The adversarial pass on a 32-line markdown template is essentially a
formatting/section-ordering check, which is appropriately lightweight.

The orchestrator flagged the second occurrence in one session of "stale base
caught only at critic time" (PR #610 had merged into main during implementation).
This is a genuine adversarial-review effectiveness data point: the critic agent
catches stale-base issues that the implementer's local checks miss. Suggests a
Tier 0 automated check ("compare branch base SHA against origin/main HEAD before
push") would shift this left.

## Fix-up Metrics

- **Post-merge fix rate:** 0% (no follow-up fix PRs in same area within 48h, n=0/1).
- **Pre-merge catch rate by step:** all zero — 1 commit, classified as feature
  (no "fix", "address", "review" keywords).
- **Pre-merge iteration count:** 1 (healthy).
- **Fix-up taxonomy:** all zero.
- **Legacy fix-up ratio:** 0/1 = 0.0.

## Planning Quality

- Description: complete (Summary + Test plan + Local Review + Steps skipped + Perf & Cost + Closes #613).
- Scope: clean — single-file addition, single concern.
- Branch lifetime: ~minutes (well under 48h).
- Planning checklist: covered. Perf & Cost section present (correctly N/A).

## Code Quality Signals

- Recurring issues: none.
- New unrecorded patterns: **stale-base detection at critic-time recurrence** —
  worth promoting to a process pattern. See "Knowledge Updates" below.

## Process Efficiency

- Automation opportunity: pre-push hook to verify branch is rebased on
  `origin/main` HEAD. Two occurrences in one session strongly suggest the
  manual catch path is leaky.
- Iteration: efficient (1 round, no rework).
- CI status: all passed (Vercel preview SUCCESS).

## Knowledge Updates

- `process-patterns.md`: add **Stale-base detection belongs pre-push, not at
  critic-time** pattern. Two PRs in one session (#614 plus prior) had unrelated
  diffs from a base-branch advance during implementation; only the critic
  caught them. Recommend a Tier 0 git check before push.
- `process-patterns.md`: strengthen **Promote prose recommendations to
  enforceable artifacts** — three escalations (#603, #606, #609) of the same
  prose rule justified converting it to a template file. Pattern: when a
  process rule is violated 3x consecutively, escalate from prose to artifact.

## Recommendations

1. **Add Tier 0 stale-base check** to push step: fail-fast if
   `git merge-base HEAD origin/main` != `git rev-parse origin/main` after
   `git fetch`. Blocks the "critic catches stale base" pattern.
2. **Backfill metrics for #611-#613** — current dashboard is missing entries,
   and #614 was triggered by a pattern that should be visible in trend data.
3. **Track timing for trivial PRs too** — even 4-minute PRs benefit from a
   `## Step Timing` row to validate that meta-changes don't accidentally
   become heavyweight.
