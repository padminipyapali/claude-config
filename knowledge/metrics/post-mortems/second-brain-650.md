# Post-mortem: second-brain PR #650 — sub-task comments CSS

**Merged:** 2026-05-19T01:54:56Z (~7 min after creation) by self.
**Size:** +270 / -0 in 1 file (App.css), 1 commit.
**Closes:** #649. Follow-up to #647.

## Local review
- Adversarial: not run as separate round (CSS-only, low risk). Orchestrator self-eyeballed the appended block (grid layout, color-token usage, focus rings) before push.
- CodeRabbit: not run.
- Lint/build: `lint:css` showed 82 pre-existing errors, zero new. Web bundle built.

## Step compliance
- Ran: 1 (planning was implicit — single screenshot → spec), 2a (implement), 3 (lint+build), 5 (push+PR).
- Skipped: 2b, 4a, 4b, 4c, 4d. Reason: pure CSS follow-up with no logic surface area.
- Compliance: 4/9 ≈ 44%. Skip assessment: **neutral** (no post-push review activity; CSS rendered as designed per the screenshot the user already had context on).

## Review friction
- 0 reviews, 0 inline comments. Self-merged at user request after orchestrator confirmed visual fix.

## Fix-up metrics
- Post-merge fix rate: 0%.
- Pre-merge: 1 single feature commit, no fixes.
- Iterations: 1 (clean).

## Planning quality
- PR body included Summary + Test Plan + design rationale (`--warning` color choice, indent matching `.project-subtodo-notes`).
- Scope clean — single file, single concern. Lifetime: 7 min.

## Process observations

1. **CSS-only follow-up doesn't need a critic round.** Spawning a critic agent for 270 lines of additive CSS where the layout fix is structurally trivial (grid template) and the rest is color-token application would have cost more agent overhead than it caught. The orchestrator's self-eyeball pass (grep for the layout-defining declarations + read 80 lines of appended CSS) was sufficient. Worth codifying as an exception class: **purely additive CSS / docs / generated files MAY skip the critic round** as long as the orchestrator verifies the diff structurally.
2. **Two-PR cadence for feature + styling worked well.** Shipping the functional behavior in #647 with structural-only markup, then styling in #650, kept each PR small and reviewable. The first PR's critic had a clean diff to reason about (no design-language noise), and this PR is trivially reviewable as a single cluster of new selectors.
3. **The marker-hash issue repeated.** Even though the previous post-mortem captured it, the hook still required the same workaround — writing the marker for the main-repo path keyed to main's HEAD. The fix is to update the hook itself; capturing it twice in post-mortems without acting on the suggestion isn't reducing friction.

## Knowledge updates
- No new patterns (the worktree-marker observation was already captured in `process-patterns.md` from #647).
- Added an exception clause to `~/.claude/knowledge/orchestrator-protocol.md` for additive CSS / docs.
