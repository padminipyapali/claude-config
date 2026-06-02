# Post-Mortem: baby-name-picker #169 + #170 — Phonetic-texture taste signal (data-then-logic A/B split)

Combined narrative for two stacked PRs that shipped a derived phonetic-softness taste signal. Per-PR metrics appended individually to `post-mortem-metrics.json`.

## Overview

| | #169 (PR A) | #170 (PR B) |
|---|---|---|
| Title | Add phonetic softness score + `sound_softness` column | Recognize soft phonetic taste as The Lyric Romantic |
| Branch | `feat/phonetic-softness-scorer` → main | `feat/lyric-romantic-softness-path` → main |
| Size | +1929 / -1 across 8 files | +272 / -9 across 7 files |
| Commits | 2 (1 feature + 1 merge of origin/main) | 1 |
| Created → Merged | 20:30 → 20:34 UTC (~4 min) | 20:46 → 20:53 UTC (~7 min) |
| Author / Merged by | padminipyapali (self) | padminipyapali (self) |
| GitHub reviews / comments | 0 / 0 | 0 / 0 |
| CI | "Typecheck, lint & test" SUCCESS (first run) | SUCCESS (first run) |
| Tests | jest 902 pass, 56 suites | jest 925 pass |

Both built via the orchestrator team (implementer → critic). Review happened entirely locally (adversarial review via the critic), so GitHub shows zero review rounds/comments — this is expected for the team pattern, not a missing-review gap.

## What shipped

- **#169 (data):** stdlib-only Python scorer `scripts/build-phonetics.py` producing a deterministic 0–1 softness score (sonorant/soft-consonant fraction, vowel openness, soft-ending bonus, hard-cluster penalty; named/tunable constants). Populated `sound_softness REAL` for all 1311 names, wired idempotently into `build-all.py` (after pronunciation, before DB build; build-twice → byte-identical). Touched zero classifier code. Validation by band separation (HIGH ~0.93 > MID ~0.72 > LOW ~0.22), not brittle ordering.
- **#170 (logic):** wired the column into `getTasteProfile` as `softnessPreference {winnerAvg, loserAvg}` (mirrors meaningDepth/syllable aggregation, null-skip), added `softnessDelta`/`winnerSoftnessAvg` to `deriveMetrics`, and widened The Lyric Romantic (#7) to fire on EITHER the existing length path OR a softness path (`softnessDelta >= 0.12 && winnerSoftnessAvg >= 0.75`), priority unchanged above Cosmopolitan (#9). Thresholds calibrated to the real shipped distribution: `SOFT_FLOOR=0.75` between catalog median 0.66 and p75 0.82; `SOFT_DELTA_FLOOR=0.12`.

## Critic findings (pre-push, adversarial review)

- **#169:** 1 minor should-fix — add a 30s subprocess timeout to the `python3` shell-out. Applied. Critic specifically pressure-tested CI-parity (a jest test shells `python3`) and cleared it on three grounds: 4 existing tests already shell `python3`; `ubuntu-latest` ships `python3`; the script is stdlib-only.
- **#170:** runtime-safety of the new REQUIRED `TasteProfile.softnessPreference` field verified (single transient constructor, never persisted). Critic caught/confirmed a latent crash in an UNTYPED test fixture (`makeProfile()`) that silently omitted the new required field — fixed. Deferred nice-to-have: annotate the fixtures `: TasteProfile` so future required-field additions fail at compile time.

## Metrics summary

| Metric | #169 | #170 |
|---|---|---|
| Review rounds (GitHub) | 1 (none requested) | 1 |
| Post-merge fix rate | 0.0 | 0.0 |
| Pre-merge iteration count | 1 (healthy) | 1 (healthy) |
| Adversarial findings / fixed | 1 / 1 | 1 / 1 |
| Adversarial catch rate | 1.0 | 1.0 |
| Planning quality | complete | complete |
| Step compliance | 8/9 (4b CodeRabbit not recorded) | 8/9 |
| Time to merge | 0.069h | 0.112h |

No post-merge fix PRs exist in this feature area (170 is the planned follow-up, not a fix). CodeRabbit (4b) is not recorded in either PR body; adversarial review (4c) and CI (4d) both ran and passed, so skip assessment is **neutral**.

## Durable learnings captured

1. **Data-then-logic split for a derived-signal feature** (process-patterns.md → Scope Decisions). Ship the new score/column first, then the logic that consumes it — so logic thresholds calibrate against the real shipped distribution. Each PR independently passes CI.
2. **CI-parity generalized beyond `ts-node` to any subprocess interpreter** (testing-patterns.md). A test that shells `python3`/`ruby`/`go` passes locally but can fail on a runner lacking the interpreter. Checklist: runner ships it? prior green tests shell the same interpreter? script is stdlib-only? subprocess has a timeout? #169 cleared all four.
3. **Annotate untyped test fixture factories with their target type** (testing-patterns.md). Untyped `makeX()` fixtures are a silent exemption from the "grep every constructor of a widened type" sibling-sweep; a new required field surfaces as a runtime crash, not a `tsc` error. When widening a type, grep for untyped factories producing it and annotate them.
4. **Calibrate heuristic thresholds against the real distribution, not a guess** (process-patterns.md → Scope Decisions). `SOFT_FLOOR=0.75` anchored between median 0.66 and p75 0.82.

## Taste-archetype thread status

This completes the taste-archetype work: relative-Cosmopolitan (#165) + phonetic-texture (#169/#170). A soft-but-short taste now classifies as The Lyric Romantic instead of falling through to the Cosmopolitan catch-all — the classifier previously had syllable length as its only sound axis.

## Recommendations

1. Record `4b` (CodeRabbit) explicitly in PR bodies (run-or-skip + reason) so step compliance isn't ambiguous — both PRs omitted it.
2. Land the deferred fixture-typing nice-to-have from #170 (annotate `makeProfile()` and sibling `makeX()` fixtures `: TasteProfile`) as a tiny follow-up; it converts the #170 latent-crash class into a compile-time guarantee.
