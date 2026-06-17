# POST-MORTEM: plush-press PR #35 — Wire generate, tune, and lock to characters (Characters studio Wave 2).

Branch: feat/character-ops → main | Author: padminipyapali | self-merged ~7 min after creation
Size: +1102 -8 across 10 files, 2 commits

## Summary
Wave 2 of the Characters studio: the generate → pick → tune → lock loop wired to characters, reusing the scene ops' exported helpers, the merged (#34) character data layer, and the wip-path primitives. Adds `characterGenerateOp`/`characterTuneOp`/`characterLockOp` and `/api/character-{generate,tune,lock}` routes. Wrong-template guard (human → character-hero-human, plush → character-hero) rejects mismatches with a 400 before any paid call. Lock walks chain provenance, routes the keeper to the hero path, writes the sidecar, sets `hero_image` + `status: hero-locked`.

## Commits
1. `674bf08` — Wire the generate/tune/lock loop to character heroes (feature, +functional).
2. `6d1258` — Lock the recorded hero in place when its filename stem differs from the slug (the critic must-fix + the hero-locked manual-write nit).

Both commits authored (00:14, 00:30) BEFORE PR creation (00:31) → both pre-push. The fix commit was produced by the fresh-context critic loop (step 4c).

## Local review (pre-push)
- CodeRabbit: not tracked (skipped per session preference — step 4b).
- Adversarial / fresh-context critic: 2 findings, 2 fixed.
  - MUST-FIX: `characterLockOp` defaulted the hero filename stem to the dir slug. For the real `cat/berlioz` shape (dir `cat`, bible `berlioz.md`, recorded `hero_image: berlioz_hero.png`), a re-lock wrote a NEW `cat_hero.png`, orphaned the curated `berlioz_hero.png`, and silently skipped the overwrite-confirm because `cat_hero.png` didn't pre-exist. THIRD occurrence of the dir-slug≠filename class (#34 read/update path was #1 and #2; this is the lock/write path). Symmetric fixtures masked it. Fixed: derive stem from `basename(hero_image)` minus `_hero.png`, slug fallback only for first-ever lock, explicit override allowed. Regression test mirrors cat/berlioz, asserts re-lock targets `berlioz_hero.png`, fires the 409 confirm, backs up to `berlioz_hero_old_1.png` — verified red-before/green-after.
  - SHOULD-FIX nit: `hero-locked` excluded from `MANUAL_CHARACTER_STATUSES` so manual create/PATCH can't hand-set a hero that was never placed (lock-op is the sole writer). Fixed.
- typecheck/lint/build PASS; vitest 287 tests PASS (incl. the dir≠filename lock regression).

## Step compliance
- Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9).
- Skipped: 4b (CodeRabbit per session preference).
- Compliance: 88.9%. Skip assessment: good — no post-merge issues; the critic (4c) caught both findings that 4b might have, and CI green.

## Review friction (post-push)
- 0 inline comments, 0 GitHub reviews, 1 round. Self-merged. CI (studio) SUCCESS.
- Timeline: created → merged ≈ 7 min.

## Fix-up metrics
- Post-merge fix rate: 0.0 (both findings fixed pre-push).
- Pre-merge catch rate by step: 4c (critic) caught 1 fix commit covering both findings; all others 0.
- Pre-merge iteration count: 1 (healthy — one critic round before push).
- Fix-up taxonomy: { correctness: 1 } (the dir≠filename orphan; the manual-write nit rode the same commit).
- Legacy fix-up ratio: 0.5 (1 fix / 2 total commits).
- adversarialCatchRate: 1.0 — both issues caught by the adversarial/critic gate, zero escaped to post-merge.

## Planning quality
- Complete: Summary, Review (with critic verdict + the must-fix narrative), Test plan, explicit Steps-skipped line. Clean single-concept scope despite size (1110 LOC) — all character-ops + routes + tests, no unrelated changes.

## Code quality signals
- Recurring issue: dir-slug≠filename path-resolution (now 3rd occurrence). Escalated from prose to a standing-fixture + implementer-checklist requirement.
- The PR correctly reused scene-ops helpers rather than duplicating (good DRY posture).

## Knowledge updates
- process-patterns.md → strengthened the existing #34 "registry keys on content but files live under slug-named dir" entry with the #35 THIRD occurrence and a line-37-style escalation: make the dir≠filename fixture a STANDING fixture every new path-resolving op must exercise; implementer checklist for any new write/move/delete op on this registry must ask "does this re-derive the path from the slug? resolve from the registry instead." Cite at occurrence #1 in sibling registries (scenes, books) before writing path logic.

## Recommendations
1. (Top — escalation) Convert the dir≠filename rule from prose to a toolchain/fixture artifact: a shared cat/berlioz-shaped fixture in the characters/scenes test layer that every path-resolving op (read, update, lock, future move/delete) is required to exercise. Three occurrences means re-discovery per-path is the failure mode; the next sibling registry (books) should cite this BEFORE writing path logic.
2. Keep the fresh-context critic mandatory on these data-layer PRs — it is the gate that caught both findings here and the regression in #31 it would have caught. Two consecutive plush-press PRs (#34, #35) had the critic catch the lone-but-serious must-fix; it is paying for itself.
3. Consider a lint/grep check for path construction that interpolates a slug directly into a hero/asset filename within these op modules, flagging it for "resolve from registry" review.
