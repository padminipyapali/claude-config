# Post-mortem: plush-press PR #336 — Add the read-only Styles shelf (Stage 4 of Art Styles)

- Branch: feat/styles-shelf → main | Author: padminipyapali | Created 2026-07-20T14:56Z, merged 16:28Z (1.53h)
- Size: +1252 −7 across 17 files, 3 commits (1 feature + 2 fix)
- CI: studio check SUCCESS (~5 min). Self-merged, no GitHub reviews/comments (solo-dev; local gate is the review).

## Local review (pre-push)
- Fresh-context critic: SHIP after 3 MINOR, all fixed — (1) route book counts through canonical `resolveBookStyleId` (resolution order in one place, safe fallback keeps never-throw guarantee); (2) thread passed `repoRoot` into projects-dir + character-manifest resolution (no split-root reads); (3) record Stage-6a canonicalizer follow-up in `docs/ART_STYLES_SPEC.md`.
- CodeRabbit CLI: 3 minor, all fixed — 2× hermetic fixtures (pin/restore `PLUSH_PROJECTS_DIR` + `PLUSH_CHARACTERS_JSON` alongside `PLUSH_REPO_ROOT`), 1× empty specimen slot dashed border full square (`width/height:100%` + `border-box`). Single pass, no retry needed.
- Gates: typecheck, lint (0), test (2561 passing after rebase onto #335), build (exit 0) — all four green, re-run after the rebase and before CodeRabbit.

## adversarialCatchRate = 1.0 (MEASURED)
6 findings total in the PR lifecycle; 6 caught locally; 0 post-push comments; 0 post-merge fixes (48h window checked — #337 is an unrelated test-decoupling sibling sweep). 6/6 = 1.0.

## Fix-up metrics
- Post-merge fix rate: 0.0.
- Pre-merge catch by step: 4c (CodeRabbit) 3, 4d (critic/adversarial) 3, others 0.
- Pre-merge iterations: 2 (critic round → fix; CodeRabbit round → fix). Normal.
- Taxonomy: correctness 2, test-quality 2, documentation 1, style 1.
- Legacy fix-up ratio: 2/3 = 0.67 (inflated by the squash-free 3-commit style; both fix commits are pre-push).

## Step compliance
Run: 1, 2a, 3, 4b, 4c, 4d, 5 (7/9 = 78%). Skipped: 2b (retired for solo dev), 4a (folded into critic + CodeRabbit, declared in PR body). Skip assessment: **good** — zero post-push/post-merge escapes.

## Planning quality: complete
PR body has What & why, read-only guarantee, degradation path (op never throws on filesystem state), counting semantics with documented Stage-4→6a follow-up, Designs section with real-data screenshot, test inventory, LOC split. Scope clean: single concern (read-only shelf: page + 2 components + 1 op + 1 route), branch lifetime <2h.

## LOC cap
Nominal production 704 (520 TS/TSX + 184 CSS) over the 600 soft cap — declared with breakdown and single-concern justification; 184 is presentational CSS for one page. Consistent with the established "subtract non-logic bulk before judging size" rule (process-patterns line 19); zero escapes support the exception.

## Notable process wins
1. **Division of labor held — 4th consecutive plush-press data point** (#330, #333, #334, #336): critic caught semantic/consistency issues (canonical resolver reuse, split-root reads), CodeRabbit caught test-hermeticity + CSS robustness. Already an established regularity in process-patterns; no new entry needed.
2. **Rebase-then-re-gate discipline**: rebased onto green main (#335) mid-review and re-ran all four gates before CodeRabbit — exactly the process-patterns line-40 protocol.
3. **Tests-not-coupled-to-product-data rule honored proactively** (fixtures only), the same class #335/#337 were fixing reactively.

## Recommendations
1. None blocking. The declared-4a-folding pattern ("simplify folded into critic + CodeRabbit") is acceptable but keep declaring it explicitly, as done here — it keeps compliance honest at 78% rather than a silent skip.
2. When Stage 6a lands, verify the recorded canonicalizer follow-up (legacy `"watercolor"` → house style folding) actually happens — it is written in `docs/ART_STYLES_SPEC.md`.
