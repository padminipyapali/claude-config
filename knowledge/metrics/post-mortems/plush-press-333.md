# POST-MORTEM: plush-press PR #333 — Wire style specimens into the harmonize render path (Stage 3b of Art Styles)

Branch: feat/harmonize-specimen-wiring → main | Author: padminipyapali | 4.3 min created→merged
Size: +693 −57 across 16 files, 3 commits (~270 LOC production, ~340 tests, ~50 spec doc)

## Local review (pre-push)

- **Critic (fresh-context, orchestrator team):** SHIP + 2 MINORs, both fixed.
  1. Latent landmine — specimen image numbering/cap derived from a hardcoded `castRefCount` instead of the actual cast-ref array; re-enabling the parked champion-recipe refs would have silently broken the by-construction numbering invariant. Fixed via `planRenderSpecimens` deriving from the real array + tests asserting the numbers shift with a non-empty refs array.
  2. Stale comment filename (`harmonize.cap-parity.test.ts`).
- **CodeRabbit CLI (`--plain -t all --base main`):** ran clean on first try (no rate-limit retry needed), 2 findings, both fixed.
  1. MAJOR — two-snapshot `resolveStyleSpecimens` lookup: routing slots and file paths were resolved from separate reads; a file appearing/vanishing between reads could leave an enumerated slot without its path (also removed an `as string` cast). Fixed with a single-snapshot shared `slotsForSet` helper.
  2. Minor — a specimen whose JPEG downscale failed was skipped, so an enumerated image could vanish. Now keeps the original PNG bytes via `downscaleRef`; test added.
- **Adversarial pass:** full entry-point matrix (unbound/watercolor, bound-with/without specimen, at-cap, no-projectId, undecodable specimen, dangling style), null-chain walk on new fields, new-union-member sweep (`harmonize-page` pre-existed in `SLOT_FOR_CLASS`). No open findings.
- Shift-left rate: 100% (4/4 issues caught locally; 0 post-push, 0 post-merge).

## adversarialCatchRate = 0.5 (measured, n=4)

critic-caught / total local findings = 2/4. Second consecutive PR in the Art Styles series (#330, #333) where the critic caught the semantic latent landmine while CodeRabbit CLI alone caught the concurrency/consistency MAJOR (two-snapshot read here; partial-failure supersede gap on #330).

## Step compliance

- Steps run: 2a, 2b, 3, 4b, 4c, 4d, 5 (7/9 → 77.8%).
- Skipped: **1 (plan-first)** — spec-defined shape (Stage 3b of `docs/ART_STYLES_SPEC.md`) + Stage 2 threading pattern; the one design fork (mechanical client/server sync) was stated up front, resolved by the implementer, and documented in the PR body. **4a (/simplify)** — folded into critic + CodeRabbit passes; the `planRenderSpecimens`/`slotsForSet` extractions are the simplification outcomes.
- Skip assessment: **good** — zero post-push and zero post-merge findings; both skips documented with reasons.

## Step timing

Not tracked in minutes (qualitative section only). CodeRabbit CLI ~4 min; four gates re-run green after each fix round. `stepTiming = null` in metrics.

## Review friction (post-push)

0 reviews, 0 comments, 0 inline comments. Self-merged with no peer review (solo-dev norm; local orchestrator-team review is the gate). CI: `studio` check SUCCESS. Timeline: 4.3 min created→merged.

## Fix-up metrics

- Post-merge fix rate: 0.0 (no follow-up fix PRs/commits touching this area as of 2026-07-20).
- Pre-merge catch by step: 4c (CodeRabbit) 2, 4d (critic/adversarial) 2, others 0.
- Pre-merge iteration count: 2 (critic round → fix commit; CodeRabbit round → fix commit) — normal.
- Taxonomy: defensive-coding 2 (single-snapshot lookup, keep-PNG-on-downscale-failure), correctness 1 (castRefCount landmine), documentation 1 (stale comment).
- Legacy fix-up ratio: 2/3 commits = 0.667 (an artifact of unsquashed review-fix commits, not churn).

## Planning quality

Complete. PR body has What & why, load-bearing design rationale (mechanical-sync by construction: one slot list, specimens-attach-last, one explicit count), an enumeration-cannot-lie analysis, byte-identity no-regression proof, server-authoritative resolution (no client-spoofable style id/path), Local Review, Steps skipped, LOC split, spec status update, and all four gates. Scope clean; branch lifetime <1 h; no redesign indicators. Nominal 750 LOC sits above the 600 guideline but the body declares the production/test/doc split explicitly (~270 production).

## Process efficiency & signals

- Iteration: efficient (2 tight local rounds, 0 post-push).
- Automation opportunities: none new — the two-snapshot class is diff-local and CodeRabbit reliably catches it; keep CodeRabbit mandatory even on critic-SHIP PRs.
- Recurring signal: **critic/CodeRabbit division of labor** recurred (#330 → #333) — critic = semantic/latent-landmine lens, CodeRabbit = read-twice/TOCTOU-consistency lens. Strengthened the existing pattern in `process-patterns.md`.
- Design pattern worth reusing: client-prompt/server-attachment agreement **by construction** (single ordering source, append-last positioning, explicit count clamped to the cap with specimens dropped first) rather than by convention.

## Knowledge updates

- `~/.claude/knowledge/process-patterns.md` — STRENGTHENED the "fresh-context critic and CodeRabbit have a measurable division of labor" entry with the #330/#333 consecutive recurrence (CodeRabbit alone catches the concurrency MAJOR; critic catches the latent semantic landmine).
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` — appended PR #333 entry (472 PRs total).
- `~/.claude/knowledge/metrics/dashboard.html` — regenerated with embedded data.

## Recommendations

1. Keep CodeRabbit CLI mandatory even when the critic returns SHIP — twice in a row it was the only lens that caught the MAJOR (consistency/race class).
2. When a PR body claims a by-construction invariant, have the critic explicitly hunt for hardcoded mirrors of derivable values (the `castRefCount` landmine class) — that hunt paid off here.
3. Continue declaring the production/test/doc LOC split when nominal size crosses the 600-line guideline; it kept this PR reviewable without splitting.
