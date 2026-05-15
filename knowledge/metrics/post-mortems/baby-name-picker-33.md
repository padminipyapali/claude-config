# Post-Mortem: baby-name-picker PR #33

**Title:** Show all favorites with a screen-local gender filter
**Branch:** feat/favorites-gender-filter -> main
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Created:** 2026-05-14T19:39:27Z | **Merged:** 2026-05-14T19:39:57Z | **Duration:** 30 seconds
**Size:** +487 -48 across 5 files, 1 commit
**Closes:** (no `Closes #N` reference in body)

## Summary
Decouples the Favorites screen from the global `genderPreference` setting so previously-saved names of the "other" gender are no longer silently hidden. Adds a screen-local filter pill row (All / Girls / Boys / Unisex) seeded from the persisted preference but never writing back to it. Each row gets a small gender glyph and the header surfaces a "{visible} of {total} saved hidden by filter" hint when narrowed.

Implementation:
- `getFavoriteNames` in `src/stores/gameStore.ts` drops the gender narrowing.
- Pure filter helpers extracted to `src/utils/favoritesFilter.ts` for node-env Jest testability.
- Local filter seeds once from `genderPreference` after store hydration, guarded by a ref so user-driven changes are not overwritten.

## Local Review (pre-push)
- `/simplify` (4a): RUN - "pure helpers extracted, no dead code."
- CodeRabbit CLI (4b): SKIPPED - not mentioned in body.
- Adversarial review (4c): RUN via fresh-context critic - 0 blockers, 3 should-fix items (staging, hydration desync, isolation tests) all addressed.
- Build / test (3): `npx tsc --noEmit` clean; `npm test` - 9 suites, 163 tests pass.

## Step Compliance
- `Steps skipped:` line not present in PR body.
- stepCompliance: **null** (untracked in this PR).
- Inferred from body: 1, 2a, 3, 4a, 4c, 5 run; 2b, 4b, 4d not evidenced.

## Step Timing
Not tracked in PR body. stepTiming: **null**.

## Review Friction (post-push)
- Review rounds: 1 (self-merged 30 seconds after creation).
- Inline comments: 0 | Substantive general comments: 0 | Bot comments: 0.
- Comment categories: all zero.
- Self-merge with no peer review (consistent with solo-dev pattern).

## Adversarial Review Effectiveness
- No post-push feedback; no comments to grade against.
- Pre-push adversarial review produced 3 should-fix findings (staging, hydration desync, filter-isolation tests), all addressed before push.
- adversarialCatchRate: **unmeasured**.
- Catches that mattered: hydration desync is the kind of state-init bug that would have shipped silently - exactly the entry-point sweep that the planning checklist demands.

## Fix-up Metrics
- Post-merge fix rate: 0.0 (no follow-up PRs within 48 h - none expected at horizon).
- Pre-merge iteration count: 1 (single commit, healthy).
- Legacy fix-up commit ratio: 0%.
- preMergeCatchRateByStep: all zero - single commit pre-merge, so no attributable fix-up commits.
- fixupTaxonomy: all zero.

## Planning Quality
- Description quality: **partial**. Has Summary, Design, Implementation notes, Local Review, Test plan. **Missing**: explicit "Performance & Cost Impact" section required by project CLAUDE.md, and no `Closes #N` reference.
- Scope: clean - one focused concern (favorites screen filter decoupling). No scope creep.
- Branch lifetime: 30 seconds (effectively zero - pushed and merged together).
- Manual test items left unchecked in the body: 2 (both manual verifications).

## Code Quality Signals
### Notable craft details
- **Hydration-seeded local state with a ref guard** is the correct pattern for "use persisted preference as initial value, then leave under user control." Worth keeping in `react-patterns.md` as the canonical pattern for screen-local-but-preference-seeded UI state.
- **Extraction of pure filter helpers** to a separate module so they can be unit-tested under node-env Jest (avoiding RN module shimming) - a small but recurring "data is the product" win.
- **View-only filter, no write-back** is the right architectural choice: it preserves the global `genderPreference` invariant used by Compare/Explore/matchmaker and limits the relaxation to the user's own data view.

### Risk points
- `+487 -48` for what reads as a single screen change is on the larger side. Most of the additions are likely the new helper + tests; would not block but worth confirming the diff is mostly test code.
- No automated coverage for the **hydration-seed effect** itself (the ref-guarded one-shot seeding). Body lists "isolation tests" as a should-fix item that was addressed - good, but the seeding effect is the subtle bit.

## Process Efficiency
- Automation: none applicable - this is a screen-level UX decoupling.
- Iteration: very efficient (1 commit, 30 s to merge).
- CI: no statusCheckRollup entries (project has no CI checks wired, or none ran in window).

## Knowledge Updates
Captured one new react-patterns entry below; no adversarial-review.md additions (no post-push feedback to learn from). The hydration-seeded ref-guard pattern is generalizable across projects and worth promoting. Also captured a process-patterns note about partial PR-body compliance with project template.

## Recommendations
1. **Add `Performance & Cost Impact` and `Closes #N` to project PR template** - both are required by `baby-name-picker/CLAUDE.md` but were missing here. A template scaffold would make compliance the default rather than an afterthought.
2. **Start tracking `Steps skipped:` and `## Step Timing`** in this project's PR bodies. With zero data on either, post-mortems cannot measure step compliance for baby-name-picker yet. Other projects already emit these; this one should too.
3. **Manual test items should not ship unchecked**, even on self-merged PRs. The two unchecked items (settings-switch flow, filter-pill non-mutation) are the exact scenarios the PR was written to fix - they should be verified before merging, not left as a TODO on a merged PR.
