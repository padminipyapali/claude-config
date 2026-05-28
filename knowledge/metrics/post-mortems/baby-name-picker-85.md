# Post-Mortem: baby-name-picker PR #85 — Make keep-both/hide-both divider controls obvious and tappable

**Branch:** feature branch → `main`
**Author / merged by:** padminipyapali (self-merge, squash, commit `c26a7f0`)
**Created:** 2026-05-28T22:07:21Z | **Merged:** 2026-05-28T22:08:34Z
**Duration:** ~73 s wall-clock (0.0203h) — fastest self-merge in this project's series
**Size:** +87 / −191 (278 total) across 5 files, 1 squashed commit

## What the PR did

Restyled the keep-both / hide-both controls on the divider between the two compare cards:
- **Restyled (Option C):** bolder sans labels with leading icons (✓ keep, ✕ hide), replacing faint italic text.
- **Added pressed-state feedback** (previously NONE): touch-down tint via `Pressable`'s `({ pressed })` — sage for keep, rose for hide.
- **Preserved** the hide-both tap-to-confirm armed state (rose highlight + "hide both?").
- **Dropped the redundant caption** ("love both? keep both. hate both? hide both.") and added breathing room.
- **Removed the now-dead caption backing code** — store flag `keepHideCaptionSeen` + `markKeepHideCaptionSeen`, the `shouldShowKeepHideCaption` util, and their tests.

Files: `app/(tabs)/index.tsx` (+79/−70), `src/stores/gameStore.ts` (+1/−37), `src/stores/__tests__/gameStore.keepHide.test.ts` (−25), `src/utils/keepHideControls.ts` (+6/−34), `src/utils/__tests__/keepHideControls.test.ts` (+1/−25).

## Design process

Visual treatment (Option C) chosen by the product owner from an HTML mockup (`docs/mockups/keep-hide-controls/index.html`, with an in-context before/after). An "EEK" reaction to the live cramped/redundant caption drove the declutter. This is the recurring mockup-first design-iteration loop — already captured as a user-preference memory, so NOT duplicated to a knowledge file here.

## Local Review (pre-push)

- **Orchestrator team pattern:** implementer + fresh-context critic.
- **Critic verdict (step 4c): SHIP-AFTER-FIXES.** Verified pressed-state correctness, armed+pressed coexistence, disabled-safety (RN suppresses `pressed` while disabled), and that caption removal dropped no load-bearing logic. **Caught 1 substantive issue:** the first pass left the caption's backing stack as orphaned tested-but-unused dead code (a half-finished removal violating the "delete unused code completely" rule). Fully removed and re-verified grep-empty repo-wide.
- **CodeRabbit (4b):** NOT run (solo self-merge). localReview CodeRabbit fields = null.
- `npx tsc --noEmit`: clean for `src/`/`app/` (separate uninstalled `web/` subproject errors remain).
- `npm test`: 27 suites, 449 tests pass (−6 removed caption tests).
- Lint: eslint not installed in the worktree — could not run (honest non-execution, matching #83's pattern).

## Step Compliance

- **Steps run:** 1, 2a, 2b, 3, 4a, 4c, 5 (7/9, ~78%)
- **Steps skipped:** 4b (CodeRabbit — solo self-merge), 4d (CI — none configured, `statusCheckRollup` empty).
- **Skip assessment:** neutral (no post-merge issues; the critic substituted for 4b on correctness/dead-code, though 4b's distinct cross-file class went unchecked).

## adversarialCatchRate derivation (NOT hardcoded)

- Substantive issues caught by adversarial/critic review pre-merge: **1** (orphaned dead-code stack).
- Substantive issues escaped to post-merge: **0** (no follow-up fix PR touches these files; `gh pr list --search` shows only #82 the original feature and #85 itself).
- adversarialCatchRate = caught / (caught + escaped) = 1 / (1 + 0) = **1.0**.

## Fix-up Metrics

- **Post-merge fix rate:** 0.0 (no post-merge fixes).
- **Pre-merge catch rate by step:** 4c = 1 (the critic's dead-code finding), all others 0.
- **Pre-merge iteration count:** 2 — initial implementer pass + 1 critic round (the `62fae17 Address review findings` commit was the critic-round fix, squashed away into the single final commit `c26a7f0`; confirmed not an ancestor).
- **Fix-up taxonomy:** dead-code = 1, all others 0.
- **Legacy fix-up ratio:** 0.0 (1 squashed commit; no separate fix commits survive).

## Planning Quality

- Description: **complete** (Summary, Designs with mockup, Local Review with critic verdict, Test plan, Note on `feat/name-family-tree` file overlap).
- Scope: clean, single concern (control affordance + declutter + dead-code removal).
- Branch lifetime: ~73 s visible.

## Verification notes

- Dead-code removal confirmed grep-empty in the merged tree `c26a7f0` (`git grep shouldShowKeepHideCaption c26a7f0 -- src app` → empty). The symbols still appear in the local working checkout only because this checkout's `main` HEAD (`bedd19f`, #83) is stale/behind #85's merge — not a regression.

## Process Efficiency

- Iteration: efficient (1 critic round folded into squash).
- CI status: none configured (recurring across this project).
- **5th consecutive baby-name-picker 4b CodeRabbit skip** (#73, #80, #84, now #85), correlating with the fastest self-merges. An `eslint-setup` branch is now in flight (closes the phantom-lint-gate hole from #81/#83) but does NOT enforce 4b — the 4b-skip pre-push hook remains the only durable fix.

## Knowledge Updates

- `process-patterns.md` → **strengthened** the existing "Solo-developer self-merge must still run CodeRabbit CLI" entry with the #85 data point (5th occurrence; critic-substitutes-for-4b-on-dead-code observation; eslint-setup-in-flight note). No new/duplicate entries (mockup-first loop already in memory; phantom-lint-gate already covered).
- `metrics/post-mortem-metrics.json` → appended PR #85 (317 total).
- `metrics/dashboard.html` → regenerated with embedded data.

## Recommendations (ranked)

1. **Land the 4b-skip pre-push hook.** Five consecutive skips; prose enforcement has failed. Block push (or demand a recorded `Steps skipped:` reason) when `coderabbit review` did not run.
2. **Finish the in-flight `eslint-setup` branch** (install `eslint` + `eslint-config-expo`) to retire the phantom-lint gate flagged across #81/#83.
3. **Add a minimal CI gate** (tsc + jest). `statusCheckRollup: []` means a ~73 s self-merge had no independent gate.
4. **Keep using the fresh-context critic for dead-code/correctness** — it earned its keep here by catching the orphaned caption stack a self-review would likely have missed.
