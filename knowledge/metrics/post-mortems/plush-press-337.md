# Post-mortem: plush-press PR #337 — Decouple the recovered-book rebuild test from the live books

- Branch: fix/rebuildrecovered-test-coupling → main | Author: padminipyapali | Created 2026-07-20T15:00Z, merged 16:28Z (1.46h)
- Size: +197 −62, 1 file (`rebuildRecoveredProjects.test.ts`), 1 commit (all local-review fixes folded pre-push)
- CI: studio check SUCCESS (~5 min). Self-merged, no GitHub reviews/comments (solo-dev; local gate is the review).

## What this PR is in process terms
The **2nd instance of the ledgered tests-coupled-to-live-product-data class**, found by a **proactive sibling sweep** — #335's post-mortem recommendation ("sweep the suite for every remaining live-data assert") actioned **within the hour**. Unlike #335 (reactive fix after ~10h red main), this one was caught **before** it fired: the suite asserted `toHaveLength(12)` + per-page `existsSync` on two live books while the operator's in-flight Pint Size page-add would have grown *Let's Take Turns!* to 13 pages. The sweep reports this was the last assertion that would fire on that change.

## Local review (pre-push)
- Fresh-context critic: safe to ship; 1 optional MINOR (exercise the parser's mid-file flush branch) — **taken**. During this round the **implementer corrected the critic's premise about branch reachability**, and exercising the branch surfaced a **latent parser quirk** (a quote-less interior heading is silently overwritten by the next heading — impossible in well-formed 12-page `story.md`; documented in the PR body, correctly scoped OUT of a test-only PR).
- CodeRabbit CLI (v0.6.5): 1 MINOR fixed — cast assertion accepted a subset; tightened to the exact four `baseChar`s + count + order.
- Gates: typecheck green, lint green, full vitest 2544 pass (target file 25/25). Build declared-skipped in-worktree (no `node_modules`; symlink trips Turbopack's out-of-root check; test-only diff excluded from the production bundle; typecheck compiles the test file and is green).

## adversarialCatchRate = 1.0 (MEASURED)
2 findings total (critic 1 + CodeRabbit 1), both fixed pre-push; 0 post-push comments; 0 post-merge fixes. 2/2 = 1.0.

## Fix-up metrics
- Post-merge fix rate: 0.0. Legacy fix-up ratio: 0/1 = 0.0 (fixes folded into the single commit pre-push).
- Pre-merge catch by step: 4c (CodeRabbit) 1, 4d (critic) 1. Iterations: 2 (normal).
- Taxonomy: test-quality 2.

## Step compliance
Run: 1, 2a, 3, 4b, 4c, 4d, 5 (7/9 = 78%). Skipped: 2b (retired), 4a (single-file test-only), build sub-step declared-skipped with justification. Skip assessment: **good** — zero escapes.

## Planning quality: complete
Root cause named against the ledgered class, fixture grammar documented (byte-identical em-dash heading format), the one remaining live-repo check redesigned as invariants-only (contiguous numbering from 01, add-tolerant, gap-failing, absent-dir-skipping), latent quirk flagged for the record. Scope clean, test-only, <2h branch lifetime.

## Process incident: heredoc-mangled PR body
The PR body was passed inline via a shell heredoc and got mangled; fixing it required `gh pr edit`, and the churn **burned a duplicate CodeRabbit CLI run that rate-limited the free tier** — the scarcest resource in the local loop. New process-patterns entry: compose bodies with `gh pr create --body-file`, verify the rendered body (`gh pr view --json body`) BEFORE triggering anything that consumes review quota.

## Notable process wins
1. **Proactive sweep beats reactive fix**: #335 recommendation → actioned same hour → next instance neutralized pre-fire. Loop-closure recorded in the Follow-Up Discipline entry (process-patterns).
2. **Healthy critic dynamics**: the implementer pushed back on a wrong critic premise (branch reachability) instead of blindly complying, AND still took the critic's useful optional — exactly the intended adversarial dynamic. The extra coverage paid off by surfacing the latent parser quirk.
3. **Correct scope discipline**: the parser quirk was documented, not fixed, in a test-only PR.

## Recommendations
1. **Done (artifact-converted this post-mortem)**: `--body-file` + verify-before-review-spend rule added to process-patterns.
2. The latent parser quirk (quote-less interior heading dropped) is documented only in the PR body — if `parseStoryMd` ever accepts operator-authored story files (Auto-Book direction), promote it to a `docs/BUGS.md` entry or fix it; until then it is contract-unreachable.
3. Consider whether the sweep's "last remaining live-data assert" claim should be re-verified after future test additions — a periodic grep for `books/` paths under `studio/src/**/*.test.ts` would make the class structurally detectable (candidate Tier-0 automated check rather than a manual convention).
