# Post-Mortem: second-brain PR #186 — Add inline due date editing for TODOs

**Branch:** feat/edit-todo-due-dates -> main
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Duration:** 0.76 hours (created 05:14 UTC, merged 06:00 UTC)
**Size:** +1551 -14 across 16 files, 4 commits

## Summary

Full-stack feature adding inline due date editing for TODOs via a custom noir-themed DatePicker component rendered via React portal. Extends PATCH /entries/:id/todo to accept dueDate alongside status. Wires optimistic updates in both EntryCard (feed) and TodoPanel (sidebar).

## Local Review (pre-push)

- **CodeRabbit:** CLI not available. 0 local findings.
- **Adversarial review:** 2 issues found, 2 fixed (unhandled promise rejections in onChange callbacks, lint a11y roles on DatePicker).
- **CI:** All passed (793 tests, build clean, lint clean).
- **Steps skipped:** none (100% compliance).

## Post-Push Review Findings

### Copilot Review (COMMENTED, 4 inline comments)

1. **Date parsing without Z suffix** (DatePicker.tsx): `new Date(value + "T00:00:00")` without Z suffix parses in local timezone, inconsistent with `formatDueDate` which uses UTC. Can show wrong month for users ahead of UTC. **Category: correctness.** **Adversarial coverage: covered (Tier 0 grep 0.1 checks for this exact pattern) but missed.**
2. **Popover position doesn't reposition on scroll/resize** (DatePicker.tsx): Position computed once on mount, becomes disconnected from trigger on scroll. **Category: correctness.** **Adversarial coverage: not covered (new gap, now added as Tier 1.6).**
3. **Silent error revert on failure** (EntryCard.tsx): Optimistic update reverts without user feedback. **Category: correctness.** **Adversarial coverage: partially covered (Tier 1.5 checks revert safety but not user feedback — now strengthened).**
4. **Silent error revert on failure** (TodoPanel.tsx): Same issue as #3. **Category: correctness.** Duplicate.

### CodeRabbit Reviews (3 rounds of CHANGES_REQUESTED, 8 inline comments)

**Round 1 (review 3830088765, 4 comments):**
5. **Fake timers for date-dependent tests** (DatePicker.test.tsx): Tests using `new Date()` can flake around midnight. **Category: testing.** **Adversarial coverage: covered (Tier 0 grep 0.1) — test file-specific concern.**
6. **Clamp left to minimum on narrow viewports** (DatePicker.tsx): `maxLeft` can go negative. **Category: correctness.** **Adversarial coverage: not covered (now part of Tier 1.6).**
7. **Close picker when entering edit mode** (EntryCard.tsx): showDatePicker stays true during edit mode. **Category: correctness.** **Adversarial coverage: not covered (now added as Tier 1.7).**
8. **Close picker when entering edit mode** (TodoPanel.tsx): Same issue as #7. **Category: correctness.** Duplicate.

Non-inline (in review body):
- vite.config.ts: Use Vitest's defineConfig. **Category: style.** Nitpick.
- api.ts: Make status + dueDate updates atomic. **Category: architecture.** Major.

**Round 2 (review 3830113447, 3 comments):**
9. **Add outside-click dismissal test** (DatePicker.test.tsx): Missing test coverage. **Category: testing.** Nitpick.
10. **View state doesn't sync when value prop changes** (DatePicker.tsx): viewYear/viewMonth stale after external update. **Category: correctness.**
11. **Popover position on scroll/resize** (DatePicker.tsx): Duplicate of Copilot #2.

**Round 3 (review 3830124756, 1 comment):**
12. **Consolidate renders into single tree** (DatePicker.test.tsx): Double render() call creates separate React roots. **Category: style.** Nitpick.

## Commit Classification

| # | Message | Classification |
|---|---------|---------------|
| 1 | Add inline due date editing for TODOs from the web dashboard. | **feature** |
| 2 | Fix date picker viewport clipping when opened from TODO panel. | **fix** |
| 3 | Address PR review: close picker on edit, clamp left position, fake ti... | **fix** |
| 4 | Add outside-click dismissal test for DatePicker. | **fix** |

**Fix-up ratio: 3/4 = 75%**

## Adversarial Review Effectiveness

**Pre-push catch potential: 15%** (2 of ~13 substantive findings were caught locally)

### Covered but missed:
- **UTC date parsing (Tier 0, grep 0.1):** The `new Date(value + "T00:00:00")` without Z suffix is exactly what Tier 0 grep 0.1 checks for. The adversarial review should have run this grep on DatePicker.tsx. This is a repeat of the execution discipline gap documented in process-patterns.md.

### Not covered (new categories — now added):
- **Portal/popover repositioning on scroll/resize** — Added as Tier 1.6.
- **Interactive mode state cleanup** (close picker on edit mode) — Added as Tier 1.7.
- **Silent error revert in optimistic UI** — Tier 1.5 strengthened to require user feedback after revert.

## Planning Quality

- **Description:** Complete. Has Summary, Local Review, and Test Plan sections.
- **Scope:** Clean. All 4 commits are thematically coherent (due date editing feature + fixes).
- **Branch lifetime:** 0.76 hours — well within 48h threshold.
- **Redesign indicators:** None. No "revert" or "try different approach" commits.
- **Planning checklist:** Test plan covers entry points (feed view, panel view, clear, today, navigate, escape, outside click, network failure revert). No explicit Performance/Cost section, but the feature is lightweight (no new API calls beyond the existing PATCH extension).

## Review Friction Analysis

- **Review rounds:** 3 (3 CHANGES_REQUESTED from CodeRabbit before merge).
- **Comments:** 12 inline (4 Copilot, 8 CodeRabbit) + 2 general (Vercel, CodeRabbit summary). All bot reviewers.
- **Timeline:** Created -> first review: 0.14h | First review -> merge: 0.62h | Total: 0.76h.
- **Self-merge:** Yes. No human review. Bot-only reviewers (Copilot + CodeRabbit).

## Comment Category Distribution

| Category | Count |
|----------|-------|
| correctness | 8 |
| testing | 2 |
| style | 2 |
| architecture | 1 |

Correctness dominates (62%), consistent with custom UI component PRs where positioning, state management, and interaction edge cases are the primary review surface.

## Process Efficiency

- **Automation opportunities:**
  - The UTC date parsing finding (Copilot #1) is literally covered by Tier 0 grep 0.1. Running the grep mechanically would have caught it.
  - Test flakiness from `new Date()` could be caught by a lint rule requiring fake timers in test files that use Date.
- **Iteration:** High friction (3 rounds). Expected for 1500+ LOC greenfield UI component.
- **CI status:** All passed.

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4c, 4d, 5 (8/8 = 100%)
- **Skip assessment: bad** — Despite 100% compliance, 3 fix commits out of 4 total. The adversarial review ran but missed the majority of post-push findings. Key miss: Tier 0 grep for UTC date parsing was either not run or not applied to all changed files.

## Knowledge Updates

1. **adversarial-review.md:** Added Tier 1.6 (portal/popover positioning), Tier 1.7 (interactive mode state cleanup), strengthened Tier 1.5 (optimistic UI revert must include user feedback). Updated ui-react category mapping.
2. **process-patterns.md:** Added iteration velocity entry for PR #186 (75% fix-up on greenfield UI despite 100% compliance). Added 3 new adversarial review gap entries (popover state cleanup, popover repositioning, silent error revert).

## Recommendations

1. **Execute Tier 0 grep checks mechanically on ALL changed .tsx files.** The UTC date parsing issue was covered by the checklist but not caught. This is the 3rd time this execution discipline gap has been documented.
2. **Add portal/popover review as standard practice for ui-react category.** New Tier 1.6 and 1.7 items should catch the positioning and state cleanup issues that dominated this PR's review findings.
3. **Custom DatePicker components are high-risk for review findings.** Calendar/date picker components involve date parsing, viewport positioning, keyboard interaction, and multi-mode state — all of which produce high comment density. Consider using a lightweight library for future date picker needs, or budget extra review time.
4. **Optimistic UI pattern needs error feedback standard.** Establish a project-wide pattern for error feedback after optimistic revert (toast, inline message, etc.). This is the first time this gap was identified.
