# Post-mortem: plush-press PR #6 — Add phased product spec (Phase 0 + MVP through Phase 4)

Branch: docs/product-spec → main · Author: padminipyapali · open→merge: 49 s (created 2026-06-10T05:34:22Z, merged by user on GitHub 05:35:11Z)
Size: +299 −0 across 1 file (docs/PRODUCT_SPEC.md), 1 commit (0479864, squash-merged as 2a4452d)

## What actually ran (docs-only — code-PR steps don't map 1:1)
- Product agent wrote the phased spec (Phase 0 → MVP → P1–P4, governing rule "every phase retires a real manual step").
- Independent adversarial agent (fresh context) reviewed the spec against repo ground truth. Verdict **SHIP-WITH-FIXES: 1 blocker + 3 majors + 4 minors** (8 findings).
  - **Blocker:** the spec's file premise was false — it assumed nine scene plates existed on disk; they never did. A file-by-file premise-vs-repo audit caught it. Phase 0 exists in the merged spec *because of* this finding.
  - Majors included the import path for book #1 images and per-template keeper routing; a new-book entry point was among the fixes; cost math verified ≈$3.20/book.
- Product agent revised; all 8 findings incorporated before the single commit. Orchestrator committed and opened the PR; user merged directly on GitHub 49 s later.
- Not run (recorded, all n/a or skipped for docs-only): 2b hardening, 3 build/lint/test, 4a /simplify, 4b CodeRabbit, 4d CI (none configured on repo).

## Local review (pre-push)
- CodeRabbit: not run (docs-only; null, not zero).
- Adversarial: 8 findings, 8 fixed, 1 round. Shift-left: 100% of known findings caught locally (0 post-push comments).

## Step compliance
- Steps run: 1, 2a, 4c, 5 (4/9) — compliance 44%. Skip assessment: neutral (no post-push review data; 49 s self-directed merge).
- Honest mapping: for a spec PR, "implementation" is the spec draft and "adversarial review" is the premise audit; the lint/test/simplify/CodeRabbit slots genuinely don't apply.

## Step timing
Not instrumented. Flow: draft → one adversarial round → revision → commit/PR. No `## Step Timing` section in body.

## Review friction (post-push)
1 round, 0 comments, 0 CHANGES_REQUESTED; merged by author (solo workflow).

## Adversarial review effectiveness
- Pre-push catch potential: **unmeasured** — 0 post-push findings, no denominator (computed from evidence, not hardcoded).
- The adversarial round caught a class pure spec-writing structurally misses: **false factual premises**. The product agent wrote a plan grounded in files it believed existed; only the fresh-context critic's file-by-file repo audit falsified the premise. This is the spec-PR analogue of the critic's boundary-fidelity catches on code PRs (#4/#5/#7).

## Fix-up metrics
- Post-merge fix rate: 0% — no defect fix-ups. Caveat: PR #8 reworked 157 of these 299 lines **25 minutes after merge**, but as a user-directed resequencing (scene tuning = worst pain → MVP), not a defect fix. See sequencing learning below.
- Pre-merge catch by step: 4a 0 · 4b 0 · 4c 0 · 4d (critic) 8 · post-push 0. Iterations: 1 (healthy).
- Taxonomy: correctness 1 (false file premise), documentation 7 (spec content/structure fixes). All folded into the single commit pre-push, so legacy fix-up ratio is 0% (no separate fix commits).

## Planning quality
Description complete (Summary + Tests sections; review process and verdict recorded in the body). Scope clean: single file, single concern, additive-only.

## Process notes
- **Premise-vs-repo audit is the load-bearing review for spec PRs.** Verification for a docs-only spec = adversarial audit of every factual claim (files exist, paths valid, cost math) against the repo. Captured in process-patterns.md.
- **Sequencing gap:** the adversarial round validated facts and internal consistency but not *priorities* — the user redirected the MVP 25 minutes after merge (PR #8) because the spec's phase order didn't lead with the user's worst pain (scene tuning). A spec review should also check phase ordering against the user's stated pain ranking before merge.

## Recommendations (ranked)
1. For future spec/plan PRs, keep the premise-vs-repo audit as a mandatory critic deliverable (now in process-patterns.md) — and add one question to the spec template: "which manual step hurts most today, and does the MVP retire it?" That single question would have made #8 unnecessary.
2. Record the adversarial round in a structured `## Local Review` section even on docs PRs (this PR described it in prose; counts had to be reconstructed).
3. Standing items: no CI on repo; no PR template committed (carried from #4/#5/#7).
