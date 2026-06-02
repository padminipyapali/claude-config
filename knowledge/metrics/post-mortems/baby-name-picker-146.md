# Post-Mortem: baby-name-picker PR #146 — Add Euphony (opt-in invented names, unified ranking, tagged)

Branch: feat/euphony-invented-names → main | Author: padminipyapali | created→merged ~29 min (2026-06-02 00:03 → 00:32Z)
Size: +2715 -154 across 26 files, 2 commits (1 feature + 1 merge-conflict resolution; squashed to main as 464a58e)

## What this PR did
Opt-in, mid-flow (~28 comparisons) invitation surfaces 113 curated invented names that, once enabled, mix into the **same comparison deck and Elo** as real names (deliberate unified ranking). Invented cards show an `EUPHONY ✦` wordmark + pronunciation in place of meaning and never claim a culture/origin (intentional ethics call). Negative ids (-1…-113) keep them disjoint from seed.db's positive ids; a `DisplayName = Name | InventedName` discriminated union forces every consumer to handle the invented branch. Favorited/high-Elo invented names hydrate into Favorites, Rank, and Top Picks. 113 names bundled as a build-script-generated JSON asset, NOT added to seed.db (would violate that catalog's meaning/origin invariants).

## What went well
- **Adversarial critic earned its keep:** the independent critic caught 1 should-fix — favorited invented names vanishing (a hydration gap in Favorites/Top Picks) — fixed pre-push. This is exactly the bidirectional-state-coverage class the orchestrator protocol targets; author-reviewer separation surfaced it.
- **Type-driven safety:** the `DisplayName` union converted "did we handle the new case everywhere?" from a manual review burden into compiler errors. The large diff was safe largely because omissions were un-compilable.
- **Clean quality outcome:** 1 review round, 0 post-merge fix PRs in the feature area, 833/833 tests after the #145 merge. No GitHub review comments (solo, local-review-gated).
- **Complete PR description:** Summary, How-it-works, Data & safety, Testing, Deferred-TODOs, Notes. Design rationale (unified-ranking boundary debate, no-culture ethics) captured in the body.

## Notable / interesting
- **Offline-curation → in-app pipeline:** the judgment-heavy name curation happened offline (`euphony_final.json`); a deterministic `scripts/build-euphony-names.py` froze it into a minimal typed asset. The PR reviews as code while the curation lives in the build plan.
- **The boundary debate that flipped the design:** the meaningful product decision was choosing **unified ranking** (invented names compete head-to-head with real names in one Elo) over a segregated "made-up names" pool. Framed as "a real name's meaning legitimately winning is fine, not pollution."
- **Negative-id namespacing** kept two populations disjoint in shared user.db queries without a schema migration — traced through every id-dependent path for `id>0` assumptions.
- **Late merge conflict with parallel feature #145** (`spellings_json`): both touched `src/types/name.ts`, `src/db/queries.ts`, `src/db/__tests__/queries.test.ts`. #145 merged first; #146 resolved a 3-file conflict in its own merge commit, both features coexist.

## Process gaps
- **Size: ~2869 LOC, ~4.8x the 600-LOC cap.** Splitting was only partly feasible — the `DisplayName` union threads through deck/Elo/NameCard/favorites/top-picks/taste atomically; a half-landed union wouldn't compile. A defensible decomposition would have been: PR1 = asset + build script + types + queries (data layer, behind no UI), PR2 = opt-in invitation + deck/Elo wiring, PR3 = Favorites/Top-Picks hydration + tagging. That would have isolated the hydration bug the critic caught into a small PR. Verdict: large-but-cohesive exception is defensible here, but a 3-PR split was feasible and would have lowered review load.
- **CodeRabbit (4b) and /simplify (4a) not recorded.** No `## Local Review` or `Steps skipped:` section in the body, so it cannot be confirmed they ran. Per the integrity rule these are tracked as `null` (not-run-unknown), not 0. The adversarial step (4c) demonstrably ran (the critic finding).
- **No `## Step Timing` section** → timing untracked. The ~29-min created→merge wall-clock excludes the offline curation and implementer worktree time, so it understates true effort.
- **Test count discrepancy:** PR body claims 820/820; post-merge state is 833/833 (the +13 from absorbing #145's tests during conflict resolution). Body wasn't updated after the merge.

## Metrics (computed from evidence)
- adversarialCatchRate: 1.0 (1 finding, 1 fixed, by the adversarial critic)
- postMergeFixRate: 0.0 (no follow-up fix PRs in feature area)
- preMergeIterationCount: 1 (healthy)
- preMergeCatchRateByStep: 4d/adversarial = 1; all others 0
- fixupTaxonomy: { correctness: 1 } (the vanishing-favorite hydration fix)
- stepCompliance: 7/9 run; skipped 4a (/simplify), 4b (CodeRabbit) — assessment **neutral** (no post-merge review data to prove the skip caused an escape; 0 post-merge fixes is consistent with no harm)
- localReview: coderabbit null/null/null; adversarial 1 found / 1 fixed
- planningQuality: complete
- prSize: 2869

## Reusable learnings (added to knowledge base)
1. **Offline curation → in-app pipeline** (process-patterns / Data Quality): curate slow judgment work offline, freeze a validated artifact + deterministic build script, bundle it, and keep it OUT of stores whose invariants it can't satisfy (seed.db's meaning/origin NOT-NULL).
2. **Negative-id (sentinel-range) namespacing** (process-patterns / Data Quality): disjoint populations in a shared store without migration is safe only if you grep every id predicate/cast/join — the scheme is as safe as its least-traced consumer.
3. **Large-but-atomic PR exception** (process-patterns / PR Sizing): >600 LOC is defensible only when most bulk is data/generated AND a type makes new-case omissions un-compilable; otherwise split.
4. **Parallel features on shared schema/type/query files will conflict** (process-patterns / Stale-Base Detection): sequence them (rebase the second after the first merges) or budget for resolution + full-suite re-run; a Tier 0 pre-push stale-base check surfaces it before critic time.

## Recommendations (ranked)
1. Add the `## Local Review` + `Steps skipped:` section to the PR template/orchestrator output so 4a/4b are never untracked — this PR's biggest measurable gap is observability, not quality.
2. For the next comparably large feature, attempt the data-layer / wiring / hydration 3-PR split; it would have isolated the critic's hydration finding to a small PR.
3. Implement the Tier 0 pre-push stale-base check (`git merge-base HEAD origin/main` == `origin/main`); it would have flagged the #145 divergence before the merge commit.
4. Update PR bodies' test counts after conflict resolution (820 → 833) so the body matches shipped state.
