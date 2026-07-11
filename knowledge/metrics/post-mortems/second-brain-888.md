# Post-Mortem: PR #888 — Shared pg pool error handling for scripts + client-level listener in the exporter

**Project:** second-brain
**Branch:** `fix/pg-error-listeners` → `main`
**Author:** padminipyapali
**Merged:** 2026-07-10T23:57:21Z (closes #863, #867)
**Size:** +475 −239 across 15 files, squash-merged to 1 commit
**Time PR-open → merge:** ~26 seconds (merge-when-ready; all review done locally pre-push)

## Summary

Closed the last two pg error-handling gaps from the #857 incident family:

- **#863** — unprotected `pg.Pool` instances in one-off scripts. Introduced a shared helper `utils/pg-pool.ts` exposing `installPoolErrorHandler` (moved from `export-data.ts`) and `createScriptPool(config)`, which attaches the absorbing error listener and pins `search_path=public` via the same startup-option mechanism the production shared pool uses. Applied to all eight scripts and `export-data.ts`; four scripts that never called `pool.end()` now do so in a `finally`.
- **#867** — client-level `error` events and a missing failure marker. The nightly backup crashed on an `error` emitted on the checked-out client (socket died as the Mac woke without network); the pool-level listener from #862 didn't cover that. The exporter now attaches a listener to the checked-out client for the transaction lifetime and removes it before release. The missing `BACKUP_FAILED.txt` root cause: `pool.connect()` sat above the `try`, so a clean connect failure threw before the marker-writing catch could run (and the `finally` then threw releasing an undefined client). The acquire now lives inside the `try` with guarded rollback/release.

Added BUG-041 to `docs/BUGS.md`.

## What went well (process signals)

1. **Critic approved first pass, zero change requests.** The highest-risk item — pooler compatibility of the startup-option `search_path` pin — was pre-verified against the production `db-pool.ts` mechanism from #851/#852 before the critic reviewed. Pre-verifying the single riskiest design decision collapsed the review to a clean APPROVE.
2. **Sibling sweep caught drift between issue-filing and implementation.** The adversarial review's sibling sweep found an *eighth* unprotected script (`retag-entries-backfill.ts`) that merged to `main` (via #885) *after* issue #863 was filed. The issue enumerated seven scripts; the sweep grepped the live tree and found the eighth. This is the sweep working exactly as intended — an issue's file list is a snapshot, not ground truth.
3. **Root cause on #867 found by the implementer**, not deferred to review: `pool.connect()` above the `try` block skipped the failure-marker catch. The fix restructured acquire/try/finally rather than papering over the symptom.

## Process friction

- **Reviewer agent crashed twice on API errors mid-review.** The orchestrator recovered by verifying the reviewer's completed on-disk work (amended commit, `BUGS.md` BUG-041, knowledge capture) and running the final gates (build, lint, test) itself. Agent-crash recovery worked but depended on the orchestrator manually checking what the crashed agent had already committed. Worth a reusable recovery checklist: on reviewer crash, diff the working tree + last commit against the reviewer's stated deliverables before re-running.

## Metrics

- **Review rounds:** 1 (0 CHANGES_REQUESTED; no GitHub reviews — merge-when-ready after local gates).
- **Comments:** 0 inline, 0 substantive general (only the Vercel bot comment).
- **Adversarial review:** measured catch rate 1.0 — found 1 issue (the eighth script), fixed pre-merge; 0 post-push comments; 0 post-merge fix PRs (this is the latest merged PR as of the post-mortem).
- **CodeRabbit:** not evidenced (null) — PR body has a `## Review` section (critic + adversarial) but no formal `## Local Review` header with CodeRabbit counts.
- **Pre-merge iteration count:** 1 (healthy).
- **Fix-up taxonomy:** 1 defensive-coding (the eighth-script error-handler addition, caught by adversarial sweep).
- **CI:** all SUCCESS. Server suite 3108 passed / 57 skipped; lint clean; tsc clean.
- **Planning quality:** complete — Summary, Review, Testing, and Performance & Cost Impact sections all present; both closed issues referenced.
- **Step compliance / step timing:** not tracked (PR body lacks `Steps skipped:` line and `## Step Timing` section).

## Recommendations

1. **Codify "pre-verify the single riskiest design decision before critic review."** This PR's clean first-pass approval traces directly to verifying the pooler `search_path` mechanism up front. Add to process-patterns as a review-friction reducer.
2. **Add a reviewer-crash recovery checklist** to the orchestrator protocol: on agent crash mid-review, reconcile the working tree and last commit against the agent's declared deliverables before re-running gates or re-spawning.
3. **The sibling-sweep-vs-issue-snapshot lesson is worth a knowledge entry:** an issue's enumerated file list is a point-in-time snapshot; always grep the live tree for the pattern rather than trusting the issue's list. This caught real drift here.
