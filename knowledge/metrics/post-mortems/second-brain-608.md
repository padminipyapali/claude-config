# Post-Mortem: second-brain PR #608

**Title:** fix(web): align Active Projects strip with sibling sections
**Branch:** fix/projects-strip-align -> main
**Author:** padminipyapali (self-merged)
**Created:** 2026-05-06T13:45:04Z
**Merged:** 2026-05-06T14:04:56Z
**Duration:** ~19.9 minutes (0.33 h)
**Size:** +0 / -1 across 1 file, 1 commit
**Closes:** #604

## Summary

A one-line CSS fix removing the redundant `padding: 0 16px` from `.projects-strip`. The strip already lived inside `.app`, which provides `padding: 0 40px`, so the inner padding stacked on top and pushed the ACTIVE PROJECTS header and its first project card ~16px right of the TodayCard above and the Recent Entries below. `.projects-strip-scroll` already owns its internal breathing room (`padding: 4px 36px 12px 4px`) for scroll momentum and the right-edge fade overlay, so no compensating change was needed.

## Local Review (pre-push)

- CodeRabbit: not tracked
- Adversarial: not tracked
- Shift-left rate: n/a (no Local Review section in PR body)

## Step Compliance

Not tracked - PR body has no 'Steps skipped:' line. The dev flow steps were not formally annotated for this micro-fix.

## Step Timing

Not tracked - PR body has no Step Timing section. End-to-end wall-clock from PR creation to merge was ~20 minutes.

## Review Friction (post-push)

- Review rounds: 1 (no CHANGES_REQUESTED, no APPROVED - self-merge)
- Comments: 0 inline, 0 human general (1 Vercel bot comment, excluded)
- Categories: all zero
- Timeline: created -> merged in ~20 minutes. No external human review window; the gap was likely waiting on Vercel preview and manual visual verification of the alignment.
- Self-merge: yes - author == mergedBy, no peer/bot code review beyond Vercel preview status check.

## Adversarial Review Effectiveness

- Pre-push catch potential: n/a - no comments to attribute.
- Covered but missed: none.
- Not covered (new categories): none.
- The change is a deletion of a single CSS declaration with no logic paths, no entry points, and no unions - adversarial checklist items are largely inapplicable. The relevant question (does removing inner padding break the right-edge fade or scroll overflow?) was already addressed by the PR body's note that `.projects-strip-scroll` owns the internal breathing room.

## Fix-Up Metrics

- Post-merge fix rate: 0% (0 follow-up fixes, ideal)
- Pre-merge catch rate by step: 4a 0 / 4b 0 / 4c 0 / 4d 0 / post-push 0
- Pre-merge iteration count: 1 (healthy)
- Fix-up taxonomy: all zero
- Legacy fix-up ratio: 0/1 = 0%

## Planning Quality

- Description: complete (Summary explains both *what* changed and *why* the previous padding was redundant; Test plan enumerates default-zoom alignment, horizontal-scroll fade, and mobile gutter; Closes #604)
- Scope: clean - single-purpose, single-line removal, branch lifetime ~20 minutes
- Branch lifetime: ~20 minutes
- Planning checklist gaps: 'Performance & Cost Impact' not enumerated; reasonable to omit on a 1-line CSS deletion. Entry points trivially singular (the dashboard projects strip).

## Code Quality Signals

- Recurring issues: none in this PR alone, but in this session this is the second dashboard alignment fix (after #603 line-height). Pattern: alignment-fragile composition.
- New unrecorded patterns: redundant inner-container padding stacking on top of an outer layout container's padding is a recurring CSS alignment bug class in this dashboard. Worth capturing as a CSS-layout review heuristic: when adding a child container inside a layout-padding wrapper, audit whether the child needs its own horizontal padding or should inherit the wrapper's gutter.

## Process Efficiency

- Automation opportunities: a visual regression test (Percy/Chromatic-style screenshot diff on the dashboard) would catch this class of horizontal-misalignment bug. ROI remains low for a solo-developer dashboard, but the *second* alignment bug in the same session (after #603) suggests the dashboard composition is alignment-fragile and could benefit from a single source-of-truth gutter token.
- Iteration: efficient (1 round, single commit, single-line diff).
- CI status: all passed (Vercel preview: SUCCESS; Vercel Preview Comments: SUCCESS).

## Knowledge Updates

- Added redundant-inner-padding pattern note to ~/.claude/knowledge/react-patterns.md under UI Patterns (paired with the all-caps line-height pattern from #603 - both are dashboard alignment bug classes).

## Recommendations

1. For trivial sub-LOC CSS fixes, accept the absence of Local Review and Step Timing sections, but add a one-line `Steps skipped: 4a-4d - reason: 1-line CSS deletion, alignment-only` annotation so the metrics pipeline can distinguish "skipped intentionally" from "tracking pre-dates feature."
2. Two alignment bugs in the same session (#603 line-height, #608 padding stack) suggests the dashboard layout has implicit gutter assumptions that get re-broken. Consider extracting `.app`'s 40px / mobile 20px gutter into a `--app-gutter` CSS custom property and documenting that direct children must NOT add their own horizontal padding.
3. Continue writing the *why* into both PR Summary and commit body - that single sentence makes this PR self-documenting and a useful reference for future "why is this misaligned" debugging sessions.
