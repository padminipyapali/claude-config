# POST-MORTEM: plush-press PR #325 — Fix the render-pill blob and restore the grouped scene toolbar

Branch: fix/render-pill-nowrap → main | Author: padminipyapali | created & merged 2026-07-19 (~13.6 min open)
Size: +167 −37 across 4 files, 4 commits (squash-merged as 189b5c6). Verified against merged origin/main.

This PR fixes a **real user-visible regression** shipped by PR #318 (the prior toolbar restructure, merged earlier the same session).

## WHAT SHIPPED (verified against 189b5c6)
- `scene.module.css`: `white-space: nowrap` (8 occurrences) + `flex-shrink: 0` (5) added across all `border-radius: 999px` pills in the row (`.render`/`.renderGo`, `.stagebar button`, `.toolbtn`, `.modesegBtn`, `.castsize`); `.stagebar` restored as a contained bordered `inline-flex` bar with borderless inner buttons and two fixed-height separators grouping `[ render ] | [ Tune Save ] | [ Reuse ]`. Confirmed the `.render` blob-guard comment and separator logic are live.
- `SceneCanvasToolbar.test.tsx`: +90 lines — grouped-bar structure tests, separator count, and the collapse edge cases (first child never a separator; reuse-only bar has no leading/trailing divider; minimal `render | Tune` bar has one separator). Confirmed present.
- `SceneCanvasRender.test.tsx`: the flaky `candidate-scroll-hint` race class wrapped in `await waitFor(...)`. Confirmed (`waitFor` import + assertions present).
- `SceneCanvas.tsx`: +17 lines wiring the grouped bar.

All four PR-body size/file claims match the merged diff exactly (+167 −37, 4 files).

## LOCAL REVIEW (pre-push)
- No structured `## Local Review` section in the body → CodeRabbit **not tracked** (null). Body's `## Verification` table records a fresh-context adversarial critic verdict **CLEAN** (0 blocking code findings), separator combinatorics traced across all 8 gate states, plus lint/typecheck/test/build green and live-app drive.
- Note (process, not code): during the run the fresh-context critic caught two **gate/process** defects — (1) the implementer reported "test PASS" while the suite was RED because `npm test | tail` returned tail's exit code, and (2) the branch needed two rebases because main moved twice under it (#323, #324 merging from another active session; both rebases were disjoint-file clean). These were fixed pre-merge but are process catches, not adversarial-checklist code-defect catches.

## STEP COMPLIANCE
- Not tracked — no `Steps skipped:` line. Narrative shows the full team flow ran (orchestrator → implementer in pre-created worktree → fresh-context critic → multi-width harness + live app).

## STEP TIMING
- Not tracked — no `## Step Timing` section. (Wall clock: ~13.6 min from create to merge.)

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED, 0 GitHub reviews — solo repo, all review local).
- Comments: 0 inline, 0 general.
- Timeline: created 19:38:35Z → merged 19:52:14Z (~13.6 min); no GitHub review events.

## ADVERSARIAL REVIEW EFFECTIVENESS
- **adversarialCatchRate: unmeasured.** Zero post-push comments and zero post-merge fixes → there is no set of escaped issues to form a catch-rate denominator. The critic's in-flight catches (masked red gate, stale branch) were process/gate issues, not adversarial-checklist code-defect catches, so no honest code catch-rate can be attributed. Marked "unmeasured" per the operator's metric-integrity rule — NOT fabricated.
- The honest escape story for the ORIGINAL defects: the blob regression and the missing grouped bar were both caught by the **operator visually**, NOT by #318's review process. #318's fix loop verified at one wide viewport and never held the result against the mockup — the two misses share one root (single-state, works-not-matches verification).
- Covered but missed: none new in #325.
- Not covered (new categories captured): (a) verify visual/responsive correctness across the state space (widths + gate combinations), not one sample; (b) never pipe a gate command through tail/head/grep (exit-code masking).

## FIX-UP METRICS
- Post-merge fix rate: 0.0% (no follow-up fix PRs; 0 is ideal). This PR IS itself the follow-up fix for #318.
- Pre-merge catch rate by step (attribution across squashed narrative): 4a self-review 1 (stale-comment corrections + edge-case tests), 4d fresh-context critic 1 (masked red gate + stale branch), post-push 0.
- Pre-merge iteration count: 2 (critic round forced a real test fix + two rebases; normal).
- Fix-up taxonomy: test-quality 1 (flaky waitFor fix), documentation 1 (stale comment corrections). The nowrap sweep + grouped bar are the PR's feature work, not fixups.
- Legacy fix-up ratio: 0.25 (1 keyword-"fix" commit of 4) — misleading here since the whole PR is a fix; reported for trend continuity only.

## PLANNING QUALITY
- Description: complete — three labeled problem sections (blob / grouped-bar / flaky test), `## Designs` (mockup linked + multi-width harness described), `## Verification` gate table, per-test enumeration.
- Scope: clean, single concern (toolbar fix) + one operator-requested flaky-test fold-in. 204 LOC, well under the 600 guideline.
- Branch lifetime: minutes. No redesign/revert indicators.
- Planning checklist: entry points covered (art vs staging mode, all 8 gate combinations). No Performance & Cost section — acceptable for a pure client-side CSS/layout fix (no new API calls).

## CODE QUALITY SIGNALS
- Recurring issue: the blob-bug CLASS recurred — #318 fixed the panel-stretch path, #325 fixed the label-text-wrap path. Same visual failure, second entry point. Sibling sweep (all pills) is the durable fix.
- New unrecorded patterns captured: state-space verification, pipe-tail exit-code masking, separator-combinatorics testing.

## PROCESS EFFICIENCY
- Automation opportunity: the pipe-tail exit-code masking is grep-able in transcripts (`npm (test|run …) | (tail|head|grep)`) — a candidate lint/hook for the team flow.
- Iteration: normal (1 internal critic round; the red-gate + stale-branch catches justified it).
- CI: studio check SUCCESS.

## KNOWLEDGE UPDATES
- process-patterns.md: +2 notes — (1) "Verifying a UI WORKS at one convenient state is not verifying it MATCHES INTENT across the state space" (drive widths + gate combos, render side-by-side with the mockup, sibling-sweep a bug class's multiple entry points); (2) "Never pipe a gate/CI command through tail/head/grep — pipeline exit code is the last command's, so a red suite reads PASS" (use pipefail / PIPESTATUS; quote the real summary line). Both cite plush-press #325.
- testing-patterns.md: +1 note — combinatorial enumeration for structure gated by N independent booleans (enumerate 2^K or at least each invariant boundary: first/last child, single-group collapse), extending the "each conditional UI branch needs a test" convention. Cites #325.
- plush-press docs/BUGS.md: BUG-014 added on branch docs/bug-014-render-pill-blob (symptom · root cause · fix · lesson, citing #318 + #325) — pending push/approval.
- metrics/post-mortem-metrics.json + dashboard.html: appended PR #325 (adversarialCatchRate = "unmeasured").

## RECOMMENDATIONS
1. For any responsive UI change, verify at multiple widths including the narrow/pressured end and render side-by-side with the approved mockup — the two checks that would have caught #318's regression before the operator did.
2. Never truncate a gate command's output with a pipe that swallows its exit code; run it bare and quote the real pass/fail summary line. Consider a transcript grep / hook to flag `npm … | tail`.
3. For conditional structure with N independent gates, enumerate the combinations (or every invariant boundary), not just the fully-populated happy path.
4. Add `Steps skipped:` and `## Step Timing` lines to team-flow PR bodies so compliance/timing stop reading as "not tracked."
