# Post-Mortem: second-brain PR #848 (lightweight)

**Title:** fix(web): wrap EntryCard tags so they don't push the header icons off. Closes #847.
**Merged:** 2026-07-03T06:21:01Z (squash `e419e49`)
**Size:** +63 / -22 across 3 files — lightweight small-PR lane.
**Lane:** lightweight (under ~100 source LOC): fresh-context critic ran; no in-loop CodeRabbit; build/lint/test + adversarial gate kept.

## Bug

The dashboard EntryCard header (`.entry-header`, hand-written CSS in `App.css`) was a flat,
non-wrapping flex row where the tag chips AND the action icons all had `flex-shrink: 0`. With
2–3+ tags, nothing shrank or wrapped, so the trailing icons (star / reformat / delete) overflowed
off the card's right edge — the star was clipped. Reported from a user screenshot (issue #847).

## Fix (3 files)

- `App.css` (+12/-1): new `.entry-tag-group` (`flex-wrap: wrap; min-width: 0; flex: 1 1 auto`)
  wrapping the tag chips + "+N" badge; `.entry-header` `align-items: center → flex-start` so the
  timestamp + icons pin top-right when tags wrap. Icons keep `flex-shrink: 0`.
- `EntryCard.tsx` (+23/-21): render the capped-3 chips + "+N" inside the new `.entry-tag-group`.
- `EntryCard.test.tsx` (+28): 2 tests — group holds the capped chips + "+N"; empty wrapper
  renders with 0 tags.

One fix covers the SHARED header, so it lands for both the normal card and the AI-response wide
(`span-2`) card at once.

## Process

- **Explore** mapped the header / `App.css` structure and the shared header's consumers.
- **Implement** — a fresh general-purpose implementer wrote the fix and VERIFIED VISUALLY via
  Playwright: it stood up a THROWAWAY Vite harness mounting the REAL `<EntryCard>` + real `App.css`
  with mock entries (no backend/DB) and captured before/after screenshots (star clipped → all icons
  visible, tags wrapped, robust at 300px).
- **Critic** (lightweight fresh-context, small-PR lane, no CodeRabbit): SHIP — verified no
  regression to the shared header (EntryCard / SkeletonCard / SearchResults + wide card), the
  empty-tag-group case, and confirmed the screenshots. 0 in-scope blockers.
- **Gates:** build + biome/stylelint + full web suite 449 passed / 0 failures.

## adversarialCatchRate

**null (critic-ran-clean)** — like #830 and #841, NOT a fabricated 1.0. The critic returned SHIP
with 0 in-scope defects and 0 escaped post-merge, so `caught/(caught+escaped) = 0/(0+0)` is
undefined → null. The visual overflow bug WAS caught pre-merge, but by the implementer's Playwright
before/after screenshots, NOT by the critic (which reviewed an already-verified fix). Reporting 1.0
here would manufacture catch-effectiveness the gate never demonstrated.

## Step compliance

Steps 1, 2, 3, 4c, 5 run; 4a (/simplify) and 4b (in-loop CodeRabbit) skipped in the small-PR
lightweight lane. complianceRate 1.0 for the lane, skipAssessment good (0 post-merge escapes; a
3-file CSS/JSX layout fix with real-component Playwright verification doesn't need the full stack).

## Learnings captured

1. **Web layout** → `react-patterns.md` (UI Patterns): a flat flex row where every child is
   `flex-shrink: 0` overflows; wrap the growable sub-group in its own `flex-wrap` + `min-width: 0`
   (+ `flex: 1 1 auto`) container while the pinned group keeps `flex-shrink: 0`, and switch the
   parent to `align-items: flex-start` so pinned items top-align when the group wraps.
2. **Lightweight visual verification** → `testing-patterns.md` (Visual Verification of UI Fixes):
   Playwright-verify a component-level UI fix by mounting the REAL component + real stylesheet in a
   throwaway Vite harness with mock props and screenshotting before/after — no backend/DB needed.
