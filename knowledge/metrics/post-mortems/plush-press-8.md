# Post-mortem: plush-press PR #8 — Resequence product spec: scene studio + tuning loop becomes the MVP

Branch: docs/product-spec → main · Author: padminipyapali · open→merge: 82 s (created 2026-06-10T05:59:15Z, merged by user 06:00:37Z); ~25 min after PR #6 merged
Size: +167 −157 across 1 file (docs/PRODUCT_SPEC.md), 1 commit (fd770b1, squash-merged as 252402d)

## What actually ran (docs-only — code-PR steps don't map 1:1)
- **User directive:** scene creation and Gemini/ChatGPT tuning is the most painful manual step — automate it first. MVP becomes the Scene studio + two-model tuning loop; Compose easel moves to Phase 1; OpenAI org verification moves into Phase 0.
- The **same product agent** (resumed via SendMessage, context intact) resequenced the spec.
- The **same adversarial agent** (also resumed) ran a **delta review** — verdict **SHIP-WITH-FIXES, "strictly better than v1": 2 majors + 3 minors** (5 findings).
  - Majors: a vapor fallback surface (spec referenced a render surface that didn't exist — fixed with the render-any-template fallback form) and photo-referenced plates missing from the MVP.
  - Minors: import-to-shelf moved to Phase 1, locked-hero overwrite guard, shared-scenes normalization.
  - The critic also **ruled against its own prior severity**: the two-key-MVP risk it had flagged was overstated in our favor. A resumed critic can retract as well as add — fresh context isn't the only honest configuration.
- All 5 findings incorporated; **`git rebase --onto main` required mid-revision** because PR #6 had been squash-merged while this branch (same `docs/product-spec` branch, continued) still based on the pre-squash tip — stacked-on-squash again (3rd plush-press-area occurrence; see knowledge update).
- Not run (docs-only): 2b, 3, 4a, 4b, 4d (no CI on repo).

## Local review (pre-push)
- CodeRabbit: not run (docs-only; null, not zero).
- Adversarial: 5 findings, 5 fixed, 1 delta round (2nd round overall for this spec; 13 findings across both rounds). Shift-left: 100% of known findings caught locally (0 post-push comments).

## Step compliance
- Steps run: 1, 2a, 4c, 5 (4/9) — compliance 44%. Skip assessment: neutral (no post-push review data).

## Step timing
Not instrumented. Flow: directive → resequence → delta review → fixes → rebase --onto → commit/PR. Whole cycle fit inside ~25 min wall clock (PR #6 merged 05:35, #8 merged 06:00).

## Review friction (post-push)
1 round, 0 comments, 0 CHANGES_REQUESTED; merged by author (solo workflow).

## Adversarial review effectiveness
- Pre-push catch potential: **unmeasured** — 0 post-push findings, no denominator (computed from evidence, not hardcoded).
- The delta review caught the same class as #6's blocker at smaller scale: a vapor surface (referenced UI that doesn't exist in the plan). Premise auditing held value even on a resequence-only diff.

## Fix-up metrics
- Post-merge fix rate: 0% (252402d is HEAD of main; no follow-ups).
- Pre-merge catch by step: 4a 0 · 4b 0 · 4c 0 · 4d (critic) 5 · post-push 0. Iterations: 1 (healthy).
- Taxonomy: correctness 1 (vapor fallback surface), documentation 4. All folded into the single commit; legacy fix-up ratio 0%.

## Planning quality
Description complete (Summary with directive provenance + Tests sections; delta verdict and all 5 fixes enumerated). Scope clean: single file, single concern (resequencing).

## Process notes
- **Persistent agent-pair + delta review worked well.** Resuming the same product agent and same critic across rounds via SendMessage gave a cheap, targeted delta review ("strictly better than v1") instead of a full re-review, and the retained context let the critic downgrade its own earlier two-key risk call. Captured in process-patterns.md as a complement to (not replacement for) the fresh-context first round.
- **Mid-flight base merges are a recurring coordination hazard.** The user squash-merged #6 on GitHub while the same branch was mid-revision for #8 — the orchestrator only discovered it at push time. This is the unplanned-stack variant of the known stacked-on-squash pattern: when the user can merge from the GitHub UI at any moment, check `git log HEAD..origin/main` before continuing work on a just-PR'd branch, and reuse `rebase --onto <new-main> <old-tip> <branch>` as the standard fix. Strengthened in process-patterns.md.

## Recommendations (ranked)
1. After opening any PR, treat the branch as merge-at-any-moment: re-fetch and stale-base-check before each subsequent push on that branch (extends the existing Stale-Base Detection pattern to solo-user GitHub-UI merges).
2. Start follow-on spec revisions on a fresh branch off the open PR's head rather than continuing the same branch — the squash-merge then can't strand local history.
3. Keep the resumed-pair delta review for revision rounds; reserve fresh-context critics for first reviews of new artifacts.
4. Standing items: structured `## Local Review` section on docs PRs; no CI; no PR template.
