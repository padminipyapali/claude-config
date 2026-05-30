# POST-MORTEM: baby-name-picker PR #126 — Correct the Nandhini pronunciation to front-syllable stress

Branch: `fix/nandhini-pronunciation` → `main` | Author: padminipyapali | create→merge ~5.5m
Size: +16 -1 across 3 files (`scripts/seed-data.sql`, `assets/seed.db`, `src/db/__tests__/seed-corrections.test.ts`), 1 commit (squash `b1743de`)

## Context
User reported in-app that Nandhini's respelling `nahn-DHI-nee` (middle-syllable stress) was wrong. This is the exact data-correctness class that caused the #87 incident — so the response deliberately applied the #87 lesson.

## LOCAL REVIEW (pre-push)
- CodeRabbit (4b): not run (data-only; CodeRabbit reviews code, not pronunciation truth).
- Adversarial (4c): **SHIP first pass, 0 changes required** — but substantively: the critic INDEPENDENTLY re-fetched Wiktionary (`/ˈnɑn.dɪ.niː/`) to corroborate the front-stress claim, verified the final DB state, ran a parsed-`.dump` diff to confirm only id 1015's two pronunciation fields changed (rebuilt==committed), and confirmed the two-sided guard. It explicitly noted a dissenting aggregator snippet (second-syllable stress) and weighed the authoritative IPA over it — not a rubber stamp.
- Shift-left: the relevant risk (wrong value) was source-verified pre-merge; 0 escaped.

## STEP COMPLIANCE
- `Steps skipped: 4a /simplify, 4b CodeRabbit — reason: 3-line data-only change`. Ran 1, 2, 3, 4c, 5. complianceRate 0.56. **Skip assessment: good** — neither skipped step catches a wrong pronunciation; semantic verification (4c) was the correct gate and ran.

## STEP TIMING
- Not tracked.

## REVIEW FRICTION (post-push)
- Rounds: 1. Comments: 0/0. CI: none. Self-merged ~5.5m after creation (review pre-PR-creation).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch: the one risk (semantic correctness) was source-corroborated. 0 escaped.
- No covered-but-missed; the critic did exactly the semantic check the #87 post-mortem prescribed.

## FIX-UP METRICS
- Post-merge fix rate: 0.0. Pre-merge iterations: 1 (clean). Fix-up taxonomy: all 0 (the correction IS the feature; the guard test is part of it).

## PLANNING QUALITY
- Complete: Summary, Source grounding (with the dissent noted), Local Review, Test plan, Decision-ledger section.

## CODE QUALITY SIGNALS
- New patterns: none new — this is the textbook APPLICATION of existing lessons (source-grounded data fix, two-sided guard test #212, semantic-not-mechanical critic #87, decision-ledger #172). Strengthened the #87 entry with #126 as the confirmed-applied inverse.

## PROCESS EFFICIENCY
- Automation: the guard test serves as the decision-ledger row (id 1015 DO NOT REVERT + source), so a future audit batch can't silently re-introduce `nahn-DHI-nee`.
- Iteration: efficient. CI: still none (would have run the new guard test as a required check).

## KNOWLEDGE UPDATES
- `process-patterns.md`: strengthened the #87 mechanical-vs-semantic critic entry with #126 as the confirmed-applied inverse (semantic verification as the gate). Metrics + dashboard updated.

## RECOMMENDATIONS (ranked)
1. **This is the template for user-reported data errors** — source-ground, critic-verify semantics, two-sided guard, ledger entry. Reuse verbatim.
2. **Ship CI** so the new guard test (and the whole seed-corrections suite) gates merges automatically — still the standing gap.
3. When batch-2 pronunciation work happens, fold id 1015 into the ledger/regression set already established here.
