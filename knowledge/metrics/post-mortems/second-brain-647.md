# Post-mortem: second-brain PR #647 — subtask comment thread

**Merged:** 2026-05-19T01:28:32Z (~34 min after creation) by self.
**Size:** +1543 / -14 across 10 files, 2 commits.
**Closes:** #645.

## Local review (pre-push)
- **Adversarial:** 1 critic round; 3 actionable findings (M1 silent no-op in `handleEditCommit`, M2 stale-closure rollback in edit + delete, N3 missing char counter); 6 NITs/MINORs explicitly accepted. All 3 actionable findings fixed in commit 2 (`fix(web): harden comment rollback against concurrent mutations`).
- **CodeRabbit:** not run.
- **Lint/build/test:** all targeted suites green pre-push (118 server, 36 web). Did not run full `npm run lint` because pre-existing `Lightbox.tsx` a11y error would block.

## Step compliance
- Ran: 1 (plan via Q&A), 2a (implement), 3 (targeted tests), 4c (adversarial), 5 (push+PR).
- Skipped: 2b (folded into 2a + adversarial), 4a (simplify), 4b (CodeRabbit), 4d (CI verify).
- Compliance: 5/9 ≈ 56%. Skip assessment: **neutral** — no post-push review activity to evaluate against; all 3 adversarial findings caught locally.

## Review friction
- 0 reviews, 0 inline comments (only vercel bot). Self-merged at user's explicit request ("just merge it and I'll test in prod").

## Adversarial review effectiveness
- Pre-push catch rate: 100% of recorded issues (3/3).
- Critic correctly attributed M2 to a real concurrent-mutation correctness bug, not a stylistic concern. Functional-updater pattern is now baked into the shipped code.
- Covered well by existing checklist: optimistic-revert correctness, default-collapsed invariant, auth scoping walk, cascade direction, sibling-sweep on trim discipline.

## Fix-up metrics
- Post-merge fix rate: 0.0 (no follow-up).
- Pre-merge: 1 feature commit + 1 fix commit caught by 4c (adversarial).
- Iteration count: 1 (healthy).
- Taxonomy: 1 × defensive-coding (the rollback fix).

## Planning quality
- Description: complete (Summary / Architecture / Tests / Migration / Follow-ups / Test plan).
- Scope: clean — single PR for the full feature, ~1.5K LOC but largely tests + new file.
- Lifetime: 34 min from PR creation to merge.

## Process observations & recommendations

1. **Worktree-cwd marker mismatch.** The `require-adversarial-review.sh` hook computes its marker key from `$CWD`, but the orchestrator initially wrote the marker for the main-repo path. The push from inside the worktree used a different cwd → different hash → push blocked. Had to write the marker twice. **Recommendation:** when working in a `.claude/worktrees/<name>` subdir, write the marker for the worktree path, not the main repo path. (Or fix the hook to always resolve to the canonical git worktree root.)
2. **Two commits, one critic round.** Working flow: implementer ships a complete first cut → critic flags issues → implementer fixes in a separate commit. This kept the diff readable in code-review and gave a clean attribution for what the adversarial review caught. Worth keeping as a pattern for orchestrator-team PRs.
3. **Stale-closure rollback in optimistic UI** is a recurring class. Captured into `react-patterns.md` as a defensive pattern.

## Knowledge updates
- Added stale-closure rollback pattern to `~/.claude/knowledge/react-patterns.md`.
- Added worktree-cwd marker note to `~/.claude/knowledge/process-patterns.md`.
