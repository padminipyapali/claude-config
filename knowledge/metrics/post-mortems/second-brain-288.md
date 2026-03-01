# Post-Mortem: second-brain PR #288 — Fix research display: show all states in thread panel, fix misleading badge

**Branch:** fix/research-display-states → main
**Author:** padminipyapali
**Merged:** 2026-02-28T19:07:00Z
**Size:** +469 -8 across 5 files, 5 commits (4 substantive + 1 merge)
**Time to merge:** ~29 minutes (created 18:37, merged 19:07 UTC) = 0.49 hours

## Summary

PR #288 enhances the research UI in ThreadPanel to display all research states (in-progress, failed with retry, completed) instead of only showing completed results. It also fixes a misleading "Researched" badge in EntryCard, changing it to "Research started" when no active task exists. The change includes 9 new ThreadPanel tests and CSS for research status UI.

Files changed:
- `packages/web/src/App.css` (+56 -0) — New CSS for research status, retry button, error states
- `packages/web/src/components/EntryCard.test.tsx` (+4 -4) — Updated badge text assertions
- `packages/web/src/components/EntryCard.tsx` (+2 -2) — Badge text change
- `packages/web/src/components/ThreadPanel.test.tsx` (+349 -0) — 9 new tests for all research states
- `packages/web/src/components/ThreadPanel.tsx` (+58 -2) — All research states rendering + retry logic

## Local Review (pre-push)

- **Steps skipped:** 3-Playwright (no dev server without external credentials)
- **Internal review findings:** 2 found, 2 fixed (activeTask priority guard, retry double-click protection)
- **CodeRabbit findings:** 1 nitpick (false positive, skipped)
- **Adversarial review findings:** 1 found, 1 fixed (focus-visible on retry button)
- **Playwright testing:** N/A (no dev server available without external service credentials)
- **CI status:** all passed (build, lint, 1149 tests)

**Total pre-push catches:** 3 (internal review: 2, adversarial review: 1)

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4c, 4d, 4e, 5 (9/9)
- **Steps skipped:** 3-Playwright (no dev server without external credentials)
- **Compliance rate:** 100% (Playwright skip is justified for credential-gated external services)
- **Skip assessment:** Playwright skip is the standard justification for this project. The change touches UI files, so a proper Playwright test would have been valuable, but external service credentials are genuinely required for the dev server.

## Step Timing

Not tracked (no `## Step Timing` section in PR body).

## Review Friction (post-push)

- **Review rounds:** 4 (3 CHANGES_REQUESTED + final round with 0 actionable comments)
- **Inline comments:** 6 (all from coderabbitai[bot])
- **Substantive non-bot comments:** 0
- **Comment categories:** { correctness: 4, testing: 1, style: 1 }
- **Timeline:**
  - Created → first review: ~3.3 minutes (18:37 → 18:41)
  - First review → merge: ~25.7 minutes (18:41 → 19:07)
  - Total: ~29 minutes
- **Self-merge check:** Self-merged with bot-only review (no human peer review)

### Post-push finding detail

**Round 1 (3 comments, committed at da46859 — but these came AFTER that commit):**

1. **Reset retry UI state on entry/task context changes** (correctness, potential-issue/minor)
   - File: `packages/web/src/components/ThreadPanel.tsx:28`
   - Issue: `retryError` and `retrying` state persists across `entryId` switches, so a previous entry's retry failure can appear on a different entry.
   - Addressed in commit `8024a21` — added useEffect to clear retryError and retrying state when entryId changes.

2. **Use status-derived badge class for active research** (correctness, potential-issue/minor)
   - File: `packages/web/src/components/ThreadPanel.tsx`
   - Issue: Hardcoded className "research-gathering" so SYNTHESIZING renders with the wrong visual state.
   - Addressed in commit `8024a21` — derived badge className from activeTask.status.

3. **Add regression test for retry error state scoping** (testing, nitpick/trivial)
   - File: `packages/web/src/components/ThreadPanel.test.tsx:275`
   - Issue: No test verifying retry errors clear when switching entries.
   - Addressed in commit `8024a21` — added regression test.

**Round 2 (2 comments):**

4. **Add test for disabled button state during retry** (testing, nitpick/trivial)
   - File: `packages/web/src/components/ThreadPanel.test.tsx:186`
   - Issue: No test verifying button is disabled and shows "Retrying..." while startResearch is pending.
   - Addressed in commit `e999104` — added test for button disabled state.

5. **Add unmount guard for async retry** (correctness, nitpick/trivial)
   - File: `packages/web/src/components/ThreadPanel.tsx:218`
   - Issue: Async onClick handler can update state after component unmounts.
   - Addressed in commit `e999104` — added isMountedRef guard.

**Round 3 (1 comment):**

6. **isMountedRef initialization stale on re-mount** (style, nitpick/trivial)
   - File: `packages/web/src/components/ThreadPanel.tsx:31`
   - Issue: isMountedRef initialized to true at declaration, vulnerable to React strict-mode double-invoke.
   - Not addressed in a separate commit — the final review round reported 0 actionable comments, indicating this was either already handled or deemed acceptable.

## Adversarial Review Effectiveness

### Mapping to checklist

| Post-push finding | Checklist item | Status |
|---|---|---|
| Retry state not reset on entry switch | Tier 1.5: Optimistic UI Revert Safety / State Reset on Navigation | **Covered but missed** — local internal review caught double-click and activeTask priority but missed the entry-switch state leaking pattern. |
| Hardcoded badge class vs status-derived | Tier 2: UI-React / Conditional styling completeness | **Covered but missed** — the adversarial review found focus-visible styling but missed the hardcoded class that should derive from status. |
| Missing unmount guard on async handler | Tier 1: async-ts / Fire-and-forget contract | **Covered but missed** — async state updates after unmount is a well-documented pattern. The local review focused on the retry flow correctness but did not check the unmount lifecycle. |
| isMountedRef strict-mode initialization | Tier 2: UI-React / React strict-mode compatibility | **Not covered** — no specific checklist item for strict-mode double-invoke on ref initialization patterns. |

- **Pre-push catch potential:** 75% (3 of 4 finding categories map to existing checklist tiers)
- **Actual pre-push catch rate:** 0% of post-push findings were caught (0/6 inline comments prevented locally)
- **Overall shift-left rate:** 33% (3 pre-push catches / (3 pre-push + 6 post-push) = 3/9)

### Fix commits

| Commit | Classification | Message |
|---|---|---|
| `32cc60a` | **feature** | "Show all research states in ThreadPanel and fix EntryCard badge text." |
| `da46859` | **fix (local)** | "Fix review findings: double-click guard, activeTask priority, focus-visible." |
| `8024a21` | **fix (post-push)** | "Address PR review: reset retry state on entry switch, derive badge class from status." |
| `e999104` | **fix (post-push)** | "Address PR review: add unmount guard on async retry, test button disabled state." |
| `3ee1ce3` | **merge** | "Merge main into fix/research-display-states, resolve ThreadPanel conflict." |

- **Fix-up ratio:** 2/4 = 0.50 (HIGH — 2 of 4 substantive commits are post-push fix-ups)

### Skip assessment

Playwright testing was skipped due to external service credentials. This is a recurring justification for this project. Given that ALL 6 post-push findings were in UI component files (ThreadPanel.tsx and its tests), Playwright testing might not have caught these specific issues (they are state management and React lifecycle issues, not visual regressions). However, integration testing of the retry flow in a browser would have exposed the state-leaking-across-entries bug (finding #1). Assessment: **justified but with caveats** — a test harness approach (page.setContent with mocked data) could have been used.

## Planning Quality

- **Description:** Complete (Summary + Test Plan + Local Review section + CodeRabbit release notes)
- **Scope:** Clean — 477 LOC across 5 files, all directly related to research display states
- **Branch lifetime:** ~29 minutes (fast iteration cycle despite 4 review rounds)
- **Redesign indicators:** None
- **Planning checklist:** All entry points covered (in-progress, failed, completed, no-research states)

**Verdict:** complete

## Code Quality Signals

- **Recurring categories:** State management (retry state leaking, unmount guard) — these are React lifecycle patterns that have appeared in prior PRs.
- **Fix-up ratio:** 0.50 — at the warning threshold. Two post-push fix-up commits addressing legitimate correctness issues.
- **New unrecorded patterns:**
  1. Entry-switch state reset for retry/error UI — when component stays mounted but context (entryId) changes, local state must be explicitly cleared.
  2. isMountedRef strict-mode initialization — initialize ref to false and set true inside useEffect, not at declaration.

## Process Efficiency

- **Iteration assessment:** Heavy iteration (4 review rounds, 3 rounds of CHANGES_REQUESTED). Each round surfaced legitimate issues that local review should have caught. The pattern is: CodeRabbit performed deeper lifecycle analysis than the local adversarial review.
- **Automation potential:** The entry-switch state reset pattern could be partially caught by a grep:
  ```bash
  git diff main...HEAD -- '*.tsx' | grep -E 'useState.*Error|useState.*retrying' && git diff main...HEAD -- '*.tsx' | grep -E 'useEffect.*entryId'
  ```
  If useState for error/retry state exists but no useEffect resetting on entryId change, flag it. However, false positives are likely. Better as a Tier 1.5 sub-item.
- **CI status:** All passed (CodeRabbit reviewed, Vercel deployment skipped)

## Gap Analysis

The core gap is that the local review (Steps 4a-4d) caught 3 issues but missed 6 that CodeRabbit found. The missed findings cluster around two themes:

1. **React component lifecycle management** (3 findings: state reset on context change, unmount guard, strict-mode ref initialization). These are well-documented patterns but require systematic lifecycle analysis that the adversarial review did not perform deeply enough.

2. **Test completeness for stateful UI** (2 findings: regression test for state scoping, test for disabled button state). The initial 9 tests covered the rendering branches but not the state transition edge cases.

### Pattern: "State leaks across context changes in mounted components"

When a component stays mounted but its context changes (e.g., entryId prop changes), local state (error messages, loading flags, retry counters) from the previous context persists. This is a variant of the "optimistic UI revert safety" pattern but applied to error/retry state rather than optimistic data. The adversarial checklist's Tier 1.5 covers optimistic UI but should explicitly call out error/retry state reset on context change.

## Knowledge Updates

1. **adversarial-review.md** — Should add sub-item under Tier 1.5 (Optimistic UI Revert Safety): "When a component's identity prop changes (e.g., entryId, threadId), verify ALL local state (error, loading, retry) is reset via useEffect cleanup."
2. **adversarial-review.md** — Should add sub-item under Tier 2 (UI-React): "For useRef(true) + useEffect cleanup patterns, verify ref is initialized to false and set to true inside useEffect body (React strict-mode compatibility)."

## Recommendations

1. **Strengthen Tier 1.5 execution for stateful UI components.** The local review caught interaction-level issues (double-click, priority guards) but missed lifecycle-level issues (state reset on context change, unmount guards). The adversarial checklist should include a mandatory "lifecycle audit" step for any component with local state and changing identity props.

2. **Consider Playwright with mocked data for retry flows.** Even without the full dev server, a test harness approach using `page.setContent()` with mocked API responses could have caught the state-leaking bug. The retry button is a user-facing interaction that benefits from integration testing.

3. **The 50% fix-up ratio signals that the review loop needs calibration for UI state management PRs.** Two of four substantive commits were post-push fixes for patterns that the existing checklist covers. The issue is execution depth, not checklist coverage.

4. **Despite 4 review rounds, merge was fast (29 min).** The CodeRabbit feedback loop is working efficiently — each round surfaced targeted, actionable findings and fixes were applied quickly. The friction is in the right place (catching real bugs) even if the shift-left rate is lower than target.
