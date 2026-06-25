# Post-Mortem: PR #735 — fix(schedule-todos): refine loop honors natural-language corrections via an LLM edit-interpreter

**Date:** 2026-06-25
**PR:** [#735](https://github.com/padminipyapali/second-brain/pull/735) (Closes [#732](https://github.com/padminipyapali/second-brain/issues/732))
**Branch:** `feat/refine-edit-interpreter` → main (squash-merged as `f40e270`)
**Time to Merge:** ~5.9h on GitHub (created 17:51:53, merged 23:47:33 UTC) — the dev loop ran locally before push; the gap is wall-clock until merge, not active review
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +985 −330 across 9 files, 2 commits

## 1. What Shipped

The "schedule my todos" refine loop re-proposed but **silently dropped almost every natural-language correction**. Tested live, a reply correcting four things applied none of them — only a random duration "wobble" changed, the tell-tale sign the model re-analyzed from scratch and ignored the comments:

- "Already done buying Mira milk" — completion language, no `#N`, no skip verb → routed to the archetype table, never reached the LLM, no done/remove output existed → the todo stayed.
- "I can't do #3 before #7" — a dependency in indirect phrasing; the prompt only taught literal `#X depends on #Y` → not honored.
- "it'll take 5 mins" — duration not applied.
- "#5 along with #1" / "#8 today" — grouping / day-pin had no mechanism at all.

**Root cause:** a rigid parse (`parseSkipNumbers` matched only `skip|drop|remove #N`) plus re-running `analyzeTodos`-with-accumulated-comments from scratch each round (the wobble; ignored any phrasing the prompt didn't literally teach).

**Fix — LLM edit-interpreter.** On a refine reply the model now sees the **current numbered proposal** (each todo: #number, title, duration, day, existing deps) + the raw reply, and is forced to emit a structured edit-list `{ isRefinement, remove[], setDuration[], addDependency[] }`. Deterministic code resolves `#number → todoId` via the stored `numberMap` and **applies the diff to the persisted per-todo analysis** (now carried in the pending metadata), then re-packs and re-proposes. Because we diff the persisted analysis instead of re-calling `analyzeTodos`, unchanged todos keep their values — the no-wobble invariant is structurally enforced (the analyzer is no longer called on the refine path at all). `isRefinement=false` → `runRefine` returns null → falls through to normal classification; Yes/No is still handled before the interpreter so a confirm never spends an LLM call. Pre-#732 pendings (no persisted analysis) degrade gracefully.

**Scope (PR1):** removal (incl. completion language), duration, dependency edits, plus persisting the analysis map. **Day-pinning ("#8 today") and "along with" grouping are intentionally deferred to PR2** (#732 tracks it) — day-pinning needs a per-todo placement constraint in the packer.

**Behavior change noted in the PR:** explicit "skip #N" was previously deterministic; it is now interpreted by the model (which handles it trivially). A deterministic fast-path can be restored if it ever misfires.

## 2. Process

Built via the orchestrator **3-role team** (implementer → fresh-context critic → adversarial-review gate).

- **Implementer** wrote the interpreter + deterministic apply + persistence (commit 1, `3108d10`).
- **Fresh-context critic** found **0 blockers + 1 SHOULD-FIX**: the pending-reply interceptor JSDoc still described the **deleted** behavior (runRefine re-analyzes honoring accumulated comments) and the header's persisted-metadata description was stale (it described accumulated refine comments, not the per-todo analysis the new mechanism persists). **Fixed pre-merge** (commit 2, `13fe8ec`).
- **Adversarial-review gate** passed.

Validation green: `npm run build`, `npm run lint`, `npm test` — @second-brain/server suite **2201 passed, 48 skipped** (the broader 2201→2213 movement spans this and sibling PRs). Unit tests cover deterministic apply per edit type, the no-wobble invariant, null-fallthrough, pre-PR degrade, and that the persisted metadata carries the edited analysis (Z-suffixed dates, fixed tz).

No GitHub-side review activity (0 human reviews, 0 CodeRabbit GitHub review, 0 inline comments — 1 Vercel bot comment, excluded). Vercel: SUCCESS.

## 3. The load-bearing validation: a real-model probe as an explicit pre-merge gate

**The unit tests MOCK the interpreter.** They prove the deterministic apply logic is correct, but they prove **nothing** about whether the real model maps "can't do #3 before #7" to a dependency, or "already done buying Mira milk" to a removal. Green mocks would have stayed green even with a prompt that the live model interprets wrongly.

To close that gap, a committed dry-run probe (`npm --workspace @second-brain/server run dry-run:refine`, needs `ANTHROPIC_API_KEY`) was run by the user against the **real model** as a deliberate pre-merge gate. It confirmed, on the live failing reply:

- `remove: [2]` — completion language ("already done buying Mira milk") correctly mapped to a removal by title.
- `addDependency: { 3 → 7 }` — indirect dependency phrasing, **correct direction**.
- `setDuration: { 8: 5 }` — duration applied.
- **correctly ignored** the out-of-scope "along with" / "today" cues (no spurious edits for the deferred PR2 features).

This is the "mocks give false confidence" guard — the same lesson as the earlier calendar saga (fixes verified only against mocks 403'd in prod) — executed deliberately rather than learned again the hard way.

## 4. adversarialCatchRate

**1.0** — computed from evidence, all pre-merge.

- **N caught / M total = 1 / 1.**
- The single real issue surfaced by review (the stale interceptor JSDoc / persisted-metadata header describing the deleted re-analyze behavior — a documentation-sync defect the implementer missed) was caught by the **fresh-context critic** and fixed before merge (commit 2, `13fe8ec`).
- **0 post-merge escapes** (no follow-up fix PRs touching this feature area).

Rigorously computable from the commit record: commit 1 is the feature; commit 2 is the critic-attributed doc-sync fix. Attributed to step 4c (critic). Not fabricated against any baseline.

## 5. What Went Well / What to Improve

**Went well:**
- The architecture is the right shape for free-text → structured-state edits: the LLM only **translates** into a fixed vocabulary; deterministic code does the math and owns the invariants. The no-wobble guarantee is enforced *structurally* (the analyzer is not called on the refine path) rather than by a prompt plea.
- The real-model probe was treated as a first-class pre-merge gate, not an afterthought — directly addressing the one thing the mocked test suite cannot cover.
- Scope was narrowed honestly: day-pinning and grouping were documented as deferred to PR2 rather than half-shipped.

**To improve:**
- The fresh-context critic's only finding was a **documentation-sync** miss (stale JSDoc describing deleted behavior). When a mechanism is replaced wholesale, the implementer should grep the surrounding comments/headers for descriptions of the *old* behavior as part of the same change — a cheap sibling-sweep that would have pre-empted the critic round.
- "skip #N" moved from deterministic to model-interpreted. Low-risk, but worth a live spot-check post-deploy; the deterministic fast-path is the documented fallback if it misfires.

## 6. Follow-Ups

- **PR2 (#732):** day-pinning ("#8 today") via a per-todo placement constraint in the packer, and "along with" grouping. The interpreter correctly ignores these cues today, so PR2 is purely additive.
- **Action to confirm in prod:** live re-test the original four-correction reply after deploy — all of remove/dependency/duration should apply, and durations on untouched todos must not wobble.

## Metrics Summary

| Metric | Value |
|--------|-------|
| adversarialCatchRate | 1.0 (1 caught / 1 total, all pre-merge; critic-caught doc-sync defect) |
| Post-merge fix rate | 0.0 |
| Pre-merge iteration count | 1 (healthy) |
| Review rounds | 1 |
| GitHub comments | 0 (1 Vercel bot, excluded) |
| Planning quality | complete (Problem + Root cause + Fix + Scope + Behavior change + Validation + Designs N/A) |
| Fix-up taxonomy | documentation: 1 (stale interceptor JSDoc / header) |
| Notable validation | real-model `dry-run:refine` probe run as an explicit pre-merge gate (mocks can't catch prompt-quality regressions) |
| CI | Vercel SUCCESS; server suite 2201 pass / 48 skip |
