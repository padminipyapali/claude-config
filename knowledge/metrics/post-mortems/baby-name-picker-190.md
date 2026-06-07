# POST-MORTEM: baby-name-picker PR #190 — Unify the name details card on a slide-up sheet presentation.

Branch: feat/detail-slide-up → main | Author: padminipyapali | created 2026-06-07T00:23Z, merged 2026-06-07T02:08Z (~1.75h elapsed)
Size: +307 -719 (net −412 LOC) across 8 files, 4 commits

## Context
Part of the 3-PR orchestrator batch (dev-name-picker-batch, 2026-06-06), full 3-role team
pattern: dedicated implementer + fresh-context critic, parallel worktree off origin/main @ 2b1e2e6.
Critic outcome: PASS, 3 findings fixed pre-push (route-contract test gap + 2 stale comments).
CodeRabbit CLI (free): clean. No CI failures, no post-push review comments. No merge conflict
despite touching app/(tabs)/index.tsx in a region disjoint from #191.

## Local Review (pre-push)
- 4a /simplify: removed the entire duplicated overlay surface; pruned dead helpers from
  src/utils/crossfade.ts (kept only the two swipe-gesture helpers the route still uses).
- 4b CodeRabbit CLI (free): no findings.
- 4c Adversarial/critic: PASS with 3 findings, all fixed in 5bfe50c —
  (1) route-contract test gap → extracted sheet options into exported NAME_DETAIL_SCREEN_OPTIONS
      with a regression test asserting formSheet + slide_from_bottom + 0.92 detent + grabber;
  (2)+(3) two stale comments referencing the removed overlay / top-left back arrow.
- Haptic adjudication: route-entry hapticSelect() on the Compare CTA aligns with the convention
  already used at Favorites/Top Picks; the silent overlay was the outlier.
- Shift-left: 100% (3/3 issues caught locally, 0 escaped to post-push).

## Step Compliance
Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (all). Skipped: none. Compliance: 100%. Skip assessment: n/a.

## Review Friction (post-push)
Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general (no bot comments).
Categories: all zero. Timeline: created → merge ~1.75h; CI green.

## Adversarial Review Effectiveness
Pre-push catch potential: 100% — all 3 findings caught by the critic/adversarial gate (Step 4c)
before push. Covered classes: extracted-helper-needs-contract-test (an established adversarial
checklist item: "Extracted private helpers need dedicated contract tests") and stale-comment /
dead-reference cleanup after entity removal ("When removing an entity, grep docs for stale
references"). No new uncovered categories. The contract-test fix is a textbook application of the
existing checklist item — the critic both flagged the gap AND the fix hardened it into a
revert-proof regression test (presentation reverts to a side-sliding modal now fail CI).

## Fix-up Metrics
Post-merge fix rate: 0% (0 post-merge fix commits; #190 is the latest detail-surface PR).
Pre-merge catch by step: 4c=1 fix commit (the 5bfe50c critic-fix bundling all 3 findings).
  4a=0, 4b=0, 4d=0, postPush=0.
Pre-merge iteration count: 1 (healthy — one critic round, fixed, shipped).
Fix-up taxonomy: test-quality 1, documentation 1 (the single fix commit spanned both classes:
  one route-contract test + two stale-comment corrections). No correctness/validation/a11y fixes.
Legacy fix-up ratio: 25% (1 fix / 4 total commits) — inflated by per-finding commit granularity;
  the underlying cycle was a healthy single iteration.

## Planning Quality
Description: complete (Summary, per-entry-point coverage table, Designs with visual delta, Local
Review, Test plan, Step Timing). Entry-point enumeration is exemplary — all 7 navigation paths to
/name/[id] tabulated before/after.
Scope: clean for a refactor — net −412 LOC consolidating 3 detail surfaces onto one route; no
redesign/revert commits. Branch lifetime: ~1.75h.
Planning checklist: entry points enumerated (strong); no Performance/Cost section, but this is a
pure UI/navigation refactor with no new API calls, so n/a.

## Code Quality Signals
Recurring issues: none. New unrecorded patterns: none new — the extracted-constant +
presentation-contract-test pattern is already captured (adversarial-review: extracted helpers need
contract tests; UI presentation regression tests). One documented benign follow-up: native
formSheet swipe-to-dismiss overlaps the custom useSwipeDownDismiss hook (idempotent, guarded by
dismissedRef; custom hook retained for its dismiss haptic) — a candidate cleanup, not a defect.

## Process Efficiency
Automation opportunities: none new. Iteration: efficient (1 round). CI: passed.

## Recommendations
None blocking. The benign formSheet/custom-gesture overlap is a tracked cleanup candidate — drop
the custom useSwipeDownDismiss once a dismiss haptic can be attached to the native sheet. Worth
noting as a strong positive exemplar: a navigation/surface-consolidation refactor that REMOVED a
duplicated UI surface (−412 LOC), enumerated every entry point up front, and locked the new
presentation behind a revert-proof contract test — the ideal shape for "unify N bespoke surfaces
onto one shared route."
