# Post-mortem: plush-press PR #15 — Studio text engine (MVP PR-1a)

`feat/studio-engine` → main | +8769 −4, 35 files, 4 commits | created 17:56Z → merged 23:29Z 2026-06-10 (~5.6h wall, ~87 min active)

## Size in context

7154 of 8769 additions are the generated `package-lock.json`; hand-written diff ≈ 1.6k LOC (engine libs ~726, tests ~483, config/docs/seeds the rest).

## Local review (100% shift-left)

- CodeRabbit: 3 findings — 1 fixed (reversed `candidates: 4-3` range normalized), 2 rejected with written evidence (false-positive `@/` alias; speculative optional-slot collapse).
- Fresh-context critic: PASS-WITH-FIXES — 2 findings fixed (wrong comment claim about blank-line collapse; missing divergent-plate-path regression test).
- Zero post-push findings, zero post-merge fixes.

## Metrics

- Post-merge fix rate: 0.0. Pre-merge catch by step: 4c:1, 4d:2, post-push:0. Iteration count: 1 (healthy).
- Taxonomy: {validation:1, test-quality:1, documentation:1}. Legacy ratio 50% (2 fix/4 commits — inflated by not squashing pre-push fixes).
- `adversarialCatchRate: unmeasured` (no post-push denominator). Critic and CodeRabbit caught disjoint finding classes — complements, not substitutes.

## Step compliance

Steps 1, 2a, 3 (39 vitest + lint + build green), 4c, 4d, 5 = 67%; skips (2b/4a/4b) assessed good. Step timing: plan 25m, implement 35m (bottleneck), critic 15m, CodeRabbit 10m, push 2m ≈ 87m total.

## Quality signals

- The plan's adversarial review found the missing §A1 photo-plate template gap pre-implementation.
- The strict parser surfaced two latent data bugs in existing repo files (`../`-prefixed attachment paths; invalid YAML in `story-page.md`).

## Recommendations

1. **Add CI now** — the repo crossed from docs to a tested codebase (39 vitest tests, no gate); the standing "no CI, acceptable for docs" justification expired with this PR (mirror baby-name-picker #150).
2. PR-template fix for the missing `Steps skipped:` line (4th violation).
3. Keep recording rejected CodeRabbit findings with evidence — makes "2 rejected" auditable rather than a silent skip.
