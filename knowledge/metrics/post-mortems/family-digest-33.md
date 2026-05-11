# POST-MORTEM: family-digest PR #33 — Dispatch Railway entry by DIGEST_ROLE env var

Branch: `fix/digest-cron-dispatcher` → `main` | Author: padminipyapali | 5 min wall time
Size: +40 -2 across 3 files, 1 commit

## Context

The `digest-cron` Railway service silently stopped honoring its per-instance `startCommand` dashboard override. Friday May 8's container booted `server.js` (the always-on Express webhook) instead of `send.js`, so no digest went out. Fix replaces the brittle dashboard override with a committed dispatcher (`scripts/entry.ts`) that reads `DIGEST_ROLE` and dynamically imports the right entry module.

## Local Review (pre-push)

Not tracked in PR body. Adversarial review WAS run via the project hook (it blocked the push until completed) but findings weren't recorded in `## Local Review` section. Critic agent (general-purpose) reviewed the implementer's work in fresh context and found 2 minor issues (Dockerfile CMD consistency, missing `.catch()` on `void main()`); both fixed before commit.

## Step Compliance

Not recorded. The work passed through plan → implementer agent → critic agent → critic-fix loop → commit → adversarial review → push → PR → self-merge.

## Review Friction (post-push)

- 0 reviews, 0 inline comments, 0 general comments.
- Self-merged 5 minutes after creation by author.
- No peer review (solo operator).

## Adversarial Review Effectiveness

Adversarial review ran pre-push and reported PASS with no findings. Critic (before push) found 2 minor issues already addressed. Net: pre-push gates caught everything; nothing escaped to post-merge.

## Fix-up Metrics

- **Post-merge fix rate:** 0% (0 follow-up fix commits).
- **Pre-merge catch rate by step:**
  - `4b` (internal review by critic agent): 1 fix cycle (2 minor issues batched into one fixup before commit).
- **Pre-merge iteration count:** 1 (healthy).
- **Fix-up taxonomy:** 1 style fix (CMD consistency + explicit error handler) — classified as `style` since both were quality-of-life improvements, not correctness fixes.

## Planning Quality

- Description: **complete** (Summary, Post-merge ops, Accepted risk, Test plan).
- Scope: **clean** — single concern (Railway dispatcher), single commit, 40 LOC.
- Branch lifetime: <30 minutes from worktree creation to merge.
- Planning checklist: N/A for infra fix. "Accepted risk" section explicitly documents the ops trap door the critic flagged (DIGEST_ROLE=cron-send on family-digest), satisfying the spirit of the entry-point enumeration requirement.

## Code Quality Signals

- No recurring patterns (single PR).
- One new pattern worth capturing: **shared-image role dispatcher** — when multiple Railway services share one Docker image, prefer a committed env-var dispatcher over per-service dashboard `startCommand` overrides. Dashboard overrides can silently drop on redeploy; the committed wrapper is version-controlled and reviewable.

## Process Efficiency

- **Iteration:** efficient (1 round, 0 churn).
- **Automation potential:** the underlying outage (cron silently running the wrong command for ~3 days) suggests an automation gap — there's no alerting if the Friday cron fails or produces an unexpected log signature. Worth: a tiny Railway → Slack/email webhook on cron failure, or a `[runDigest] sent` log-presence check Saturday morning.
- **CI status:** not applicable (no GitHub Actions configured on this repo).

## Knowledge Updates

Adding the dispatcher pattern to `~/.claude/knowledge/architecture-patterns.md` (under deployment/infra). No adversarial-review checklist additions — the dashboard-override-drift failure mode is too vendor-specific to generalize.

## Recommendations

1. **Add a cron success monitor.** Even a basic "did the Friday `[runDigest] sent —` log line appear?" check would have surfaced the failure within 24h instead of 3 days. Could be a separate Monday-morning Railway cron that queries Railway logs API or a Gmail filter checking for a "Family Digest" inbox match.
2. **Eliminate dashboard-only configuration.** Where possible, commit operational config (startCommand, env var role, etc.) to the repo so it's diff-reviewable. This PR is the example.
3. **Consider local review templating.** Two recent family-digest PRs lack `## Local Review` and `Steps skipped:` sections, leaving step compliance untrackable. A PR body template would help.
