# POST-MORTEM (combined): baby-name-picker PRs #163, #165, #155 — 2026-06-02

Three orchestrator-team PRs (implementer → fresh-context adversarial critic → PR) merged on
2026-06-02 within ~6 minutes of each other (20:00 / 20:01 / 20:07 UTC). All three: self-merged
by author, CI green ("Typecheck, lint & test" SUCCESS), zero GitHub reviews and zero inline
comments — review happened locally pre-push (the team pattern), so GitHub friction is 0 by design
and the meaningful signal is the critic round count and the merge-coordination cost.

The PR bodies do NOT carry the structured `## Local Review`, `## Step Timing`, or `Steps skipped:`
sections, so `localReview.coderabbit*`, `stepCompliance`, and `stepTiming` are recorded as `null`
(not tracked) rather than 0. Adversarial findings ARE derivable (documented inline in each body +
the team-run evidence) and are recorded.

---

## PR #163 — Reveal Euphony at pool exhaustion (Option C)
Branch: `feat/euphony-pool-exhaustion-reveal` → `main` | created 2026-06-02T19:39:15Z, merged
2026-06-02T20:00:58Z (~0.36 h). Size: +409 / -33 across 5 files, 2 commits (1 feature + 1 merge-up).

Files: `app/(tabs)/index.tsx`, `src/components/EuphonyInvitation.tsx`, `src/stores/gameStore.ts`,
`src/stores/__tests__/gameStore.euphony.test.ts`, `src/stores/__tests__/gameStore.keepHide.test.ts`.

What it did: the deferred "Option C" entry point — when the real-name pool is exhausted for an
unseen/declined user and invented names exist, show the Euphony invitation (exhaustion copy) instead
of the dead-end "you've seen every name" state. Accept folds invented names into the pool; decline
drops to the normal exhausted state behind a session dismiss-guard. Exhaustion branch added
identically to the `PoolExhaustedError` catch of BOTH `advanceToNextPair` and `loadNextPair`.

- **Critic:** caught nothing blocking. Adversarial PASS on loop-safety, mid-flow (#146) intact +
  mutual exclusion, state-machine completeness, render ordering.
- **Notable (positive):** the implementer pre-empted an infinite-loop class (a decline re-exhausting
  → re-revealing in a cycle) with a `euphonyExhaustionDismissed` session dismiss-guard, and tested
  loop-guard suppression + clearing. This is the "trace each path end-to-end / bidirectional state
  coverage" planning requirement applied proactively — the failure mode was designed out before
  the critic, not patched after. +15 new tests (877 pass), incl. the full opt-in × exhaustion matrix.
- **Merge-coordination cost:** required a merge-up because its base was stale behind #161 (catalog
  PR) before it could PR — the second commit is that merge. Benign (no logic conflict) but it is the
  third instance of the seed/catalog stale-base collision (see headline).
- **Iteration count: 1** (one clean critic round). Post-merge fix rate: 0%.

## PR #165 — Cosmopolitan archetype: fire only above the exposure baseline
Branch: `feat/cosmopolitan-relative-threshold` → `main` | created 2026-06-02T19:47:14Z, merged
2026-06-02T20:01:22Z (~0.24 h). Size: +290 / -47 across 2 files, 2 commits (1 feature + 1 merge-up).

Files: `src/services/tasteArchetype.ts`, `src/services/__tests__/tasteArchetype.test.ts`.

What it did: replaced the Cosmopolitan trigger's absolute "4+ distinct cultural families" count
(cleared by exposure, not preference, in a deliberately multicultural catalog) with a *relative*
metric — `familyDiversityRatio = effectiveCount(winner families) / effectiveCount(seen families)`
using a sample-robust inverse-Simpson (Hill q=2) effective count, gated at > 1.15. Absolute family
floor + DATA_FLOOR retained as sparse-sample guards. `global` stays an independent trigger. Tell-copy
branches by which clause fired (the over-claim only made when literally true).

- **Critic:** found **2 SHOULD-FIX** in round 1 → fixed → merged on round 2.
  1. Global-path copy *over-claimed* (asserted "a wider cultural range than you were even shown" on a
     path where that isn't established) → copy split to branch by trigger; global path now says only
     "drawn to names that travel well." → classified `correctness` (a truth-claim error in user-facing
     copy, not a typo).
  2. Sparse-data documentation gap → documented the DATA_FLOOR / absolute-floor rationale in code.
     → classified `documentation`.
- **Iteration count: 2** (the only multi-round PR of the three — appropriate; the critic did real work).
- **Merge-coordination:** a merge-up commit, but `tasteArchetype.*` does not collide with catalog
  files, so this was clean.
- Post-merge fix rate: 0%. adversarialCatchRate = 1.0 (both findings caught + fixed pre-merge).

## PR #155 — Add three requested names: Manon, Aurelie, Aurelia
Branch: `feat/seed-add-requested-names` → `main` | created 2026-06-02T05:01:11Z, merged
2026-06-02T20:06:57Z (~15.1 h open). Size: +34 / -7 across 6 files, 2 commits (1 feature + 1
merge-conflict-resolution merge).

Files: `assets/seed.db`, `scripts/seed-data.sql`, `docs/research/seed-coverage-baseline.json`,
`docs/research/name-pronunciations.json`, `src/db/__tests__/seed-meaning-depth.test.ts`,
`src/db/__tests__/seed-popularity.test.ts`.

What it did: added 3 feminine names (Manon · French; Aurelie · French; Aurelia · Latin), each with
native + distinct anglicized dual pronunciations. Catalog 1307 → 1310 in the body, but the names were
ultimately renumbered to **ids 1320-1322** on resolution.

- **Critic:** PASS — schema/pipeline, seed.db integrity (zero regression to existing prons), data
  quality. (This is the semantically-grounded catalog gate proven across #126/#141/#149.)
- **Merge conflict (the story of this PR):** it sat open ~15 h while parallel catalog PRs (#160-162
  and #166/Anavi) advanced main, so it conflicted on the entire catalog hotspot set —
  `assets/seed.db`, `scripts/seed-data.sql`, `docs/research/seed-coverage-baseline.json`, and the
  count-constant test fixtures (`seed-meaning-depth.test.ts`, `seed-popularity.test.ts`). Resolved by
  merge-up + seed.db rebuild + id renumber (1320-1322), then merged. The merge commit's body lists
  exactly these conflicted paths.
- **Iteration count: 1** (one critic round; the second commit is conflict resolution, NOT a review fix).
- The single conflict-resolution commit is classified `infrastructure` in the fix-up taxonomy (it
  reflects merge mechanics, not a code-quality defect), so it does not count against quality metrics.
- Post-merge fix rate: 0%.

---

## Cross-cutting findings

### HEADLINE: catalog/seed PRs are a recurring serial-collision hotspot
seed.db is a rebuilt binary, paired with `scripts/seed-data.sql`, count-constants baked into test
fixtures, and a coverage-baseline JSON. That set is identical for ANY catalog change, so two open
catalog PRs collide deterministically. This has now recurred across **#149, #155, and the #163/#161
stale-base note** (and earlier #146-vs-#145, #149). #155's 15 h open window is precisely when 3 sibling
catalog PRs landed — open-window length is the dominant risk factor.

Mitigation captured in `process-patterns.md` (priority order): (1) **serialize catalog PRs** — treat the
catalog as a single-writer resource, open the next only after the prior merges; (2) if parallel is
unavoidable, **merge catalog PRs promptly** to shrink the collision window; (3) **standard resolution
recipe** — merge-up → take-main's-side for generated artifacts (never hand-merge the `.db` binary) →
re-run the deterministic build script → renumber new ids past main's new max → recompute count-constants
→ re-run tsc/lint/jest. Orchestrator should run a pre-dispatch stale-base check
(`git log HEAD..origin/main -- assets/seed.db scripts/seed-data.sql`) before starting any catalog
implementer and sequence catalog work in the task queue.

### Product pairing: relative-Cosmopolitan ↔ deferred phonetic-texture signal
#165 tightens the *residual* archetype (priority #9) so it fires only for genuine over-diversifiers.
Its complement, the deferred phonetic-texture signal, gives soft/sound-based tastes a home earlier in
the priority order so they never fall through to this residual. Sequence texture next (or ship together)
to fully drain the false-Cosmopolitan bucket; tightening the residual alone leaves soft-taste users
archetype-less until texture lands. Captured in `strategic-decisions.md`. The general rule also captured:
a derived "user is into X" signal over a curated feed must measure the kept distribution *relative to the
shown distribution*, never against an absolute count the feed's own composition can satisfy.

### Process health
- 3/3 zero post-merge fixes; 3/3 CI green. The orchestrator team pattern held.
- Critic effectiveness confirmed asymmetric and appropriate: #163 nothing blocking + a proactively
  designed-out loop, #155 a clean data-gate PASS, #165 two real SHOULD-FIX caught (incl. a user-facing
  truth-claim over-statement that a structural-only review would miss — consistent with the
  "verify the change is RIGHT, copy included" discipline).
- Tracking gap: none of the three PR bodies carried `## Local Review` / `## Step Timing` /
  `Steps skipped:` sections, so step-compliance, step-timing, and the CodeRabbit-vs-adversarial
  shift-left split are unmeasured for this batch. Recommendation below.

## Recommendations (ranked)
1. **Serialize catalog/seed PRs** (or merge them promptly). Highest leverage — this collision class has
   now cost merge-ups/rebuilds on #146, #149, #155, #163. Single-writer the catalog; pre-dispatch
   stale-base check on `assets/seed.db` + `scripts/seed-data.sql` before any catalog implementer.
2. **Ship/sequence the phonetic-texture signal next** so #165's residual tightening doesn't strand
   soft-taste users without an archetype.
3. **Add the `## Local Review` / `## Step Timing` / `Steps skipped:` sections to the PR-body template**
   for orchestrator PRs so shift-left split, step compliance, and timing become measurable instead of
   `null`. The data exists in-session; it just isn't persisted to the PR body.
