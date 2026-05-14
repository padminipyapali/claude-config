# Post-mortem: remodel-hq PR #47

**Title:** perf(dashboard): lazy-load tabs, parallelize inspo fetches, size grid imgs
**Branch:** perf/batch-1-low-hanging -> main
**Author / Merged by:** padminipyapali (self-merged)
**Size:** +23 / -14 across 2 files, 1 commit (squashed)
**Time to merge:** ~4 min PR-open-to-merge (~30 min total dev including audit, implement, critic, fixes)

## Context

Originated from an Explore-agent perf audit kicked off after the user said "I want to work on making the app faster too." Audit produced a punch list of 7 wins ranked by impact/effort. This PR shipped the 3 low-effort wins as a batch:

1. Dynamic imports for 5 non-default dashboard tabs + 3 conditionally-rendered modals (was: all 6 tab components loaded statically at first paint).
2. Consolidated 4 parallel `useEffect`-fetches on InspirationPage's `selectedRoomId` change into a single `Promise.all` with `.catch`.
3. Added `width/height/decoding="async"` to inspiration grid `<img>` tags and `decoding="async"` to the lightbox.

A 4th audit item (#7 — `.limit(20)` on `fetchAllSessions`) was implemented but then reverted before merge after the critic caught a correctness regression.

## What changed in the PR

- `src/app/dashboard/page.tsx` — 5 tabs + 3 modals → `next/dynamic` with `ssr: false`. Default tab (KanbanBoard/vendors) stays static.
- `src/components/InspirationPage.tsx` — 4 effects collapsed to 1 `Promise.all([...]).catch(...)`. Image grid sized.

## Process

Same orchestrator / implementer / critic team. One review-fix cycle:

1. Implementer first pass — applied all 4 audit items (including #7 `.limit(20)`).
2. Critic adversarial review — 4 findings: 1 BLOCKING (limit causes data loss), 1 SHOULD FIX (Promise.all needs .catch), 2 NIT (skeleton styling, modal loading state).
3. Implementer reverted #7 entirely, added `.catch`. Skipped NITs.

User validated on worktree dev server before merge.

## Quality signals

- No GitHub reviews / comments (self-authored, self-merged). QA via local critic.
- 0 fix commits in commit history (squashed).
- **Notable:** the audit itself proposed a flawed optimization. The `.limit(20)` win failed because `fetchAllSessions` data is filtered client-side per-room — a global limit silently hides older sessions in less-recently-touched rooms. The audit didn't surface this constraint; the critic did.
- All 142 tests still pass; no behavior tests for the changes (these are runtime perf wins, not testable at the unit level).

## Patterns / learnings

- **Audit recommendations are inputs, not gospel.** An external perf audit identified 7 wins; on close inspection 1 of them (`.limit()` on globally-fetched data filtered client-side) was a correctness regression. Always read the call sites of the audited code before applying the fix — perf wins that work on the data path often break on the access pattern.
- **Client-side filtering of a globally-fetched list is fragile.** If you `.limit()` such a list at the source, you don't truncate "what shows up" — you truncate "what's accessible." Either fetch per-filter-key, or paginate with UI affordance, or skip the limit. Don't `.limit()` a list that's filtered downstream.
- **Default-tab-stays-static is the right pattern for `next/dynamic` migrations.** Dynamic-importing every tab pushes a chunk fetch onto the first paint of the default tab, which is the opposite of what you want. Keep the default-render path synchronous.
- **`Promise.all` without `.catch` silently swallows results.** One failure aborts all four. Always pair `Promise.all` with `.catch` or use `Promise.allSettled` when you want partial results.

## Knowledge updates

Adding to `~/.claude/knowledge/react-patterns.md`:
- **Don't `.limit()` a list that's filtered client-side downstream.** A global cap on an over-fetched list silently hides data when the filter narrows to a subset that didn't make the cap. Either fetch per-filter-key, or paginate with explicit UI affordance ("load more"). <!-- Source: post-mortem, remodel-hq #47, 2026-05-13 -->

Adding to `~/.claude/knowledge/typescript-patterns.md`:
- **`Promise.all` needs `.catch` for fire-and-forget.** One rejection aborts the rest and silently swallows all results. Always pair `Promise.all([...]).catch(handler)` or use `Promise.allSettled` if you want partial results. <!-- Source: post-mortem, remodel-hq #47, 2026-05-13 -->
