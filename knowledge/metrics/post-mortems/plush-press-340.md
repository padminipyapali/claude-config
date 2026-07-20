# Post-Mortem: plush-press PR #340 — Add a tripwire meta-test forbidding live-repo reads in tests.

Branch: `fix/live-data-test-tripwire` → main | Author: padminipyapali | Created 2026-07-20T17:12:55Z, merged 17:18:08Z (~5 min open)
Size: +247 −0 across 13 files, 1 squashed commit. Test-only diff. CI (studio) GREEN on first run.

## Context

Third and final act of the live-data-coupling campaign, all same-day:
- **#335 (reactive)**: `recipeRefs.test.ts` fixture conversion after ~10h red main (operator added `shalu-pini`).
- **#337 (proactive)**: sibling sweep caught `rebuildRecoveredProjects.test.ts` BEFORE the in-flight page-add fired it.
- **#340 (structural)**: this PR — a Tier-0 guard making the class unrepresentable, directly landing #337's recommendation #3 ("periodic grep … candidate Tier-0 automated check") as a committed artifact per the convention-budget promotion rule.

## What shipped

`studio/src/lib/__tests__/noLiveDataInTests.test.ts`: dumb line-regex scanner (no AST) over every other `*.test.ts(x)` under `studio/src` for two mechanical shapes — (1) fs reads (`readFileSync`/`readdirSync`/`existsSync`/`statSync`/…) anchored at a real-root token in a ±3-line window, (2) known reader lib-calls (`listScenes`/`getCharacter`/`loadTemplate`/…) passed a real-root token. 12-file justified ALLOWLIST; each blessed file carries a literal `LIVE-REPO INVARIANTS ONLY` marker. Three self-checks: un-allowlisted hit fails with file+line+snippet+fixture idiom; deleted marker un-blesses; stale allowlist entry fails.

**Verification discipline (exemplary — the template for future guard PRs):**
- **Calibration proof**: pre-marker run flagged exactly the 12 intended files, nothing spurious.
- **Bite proof**: temporary un-allowlisted probe (`__tripwireprobe__.test.ts`) flagged at file:line with guidance, then removed.
- **Un-bless proof**: marker-presence assertion covers marker deletion.
- Full suite 2569 pass / 0 fail, zero behavior change to blessed tests.

**Residual gaps documented, not hidden**: file-level blessing (new live read inside a blessed file uncaught — reviewers must eyeball marker blocks), and a hypothetical fixture dir literally named `repoRoot` would false-positive (self-correcting via error message). `pageTuneOp` scoping rationale documented (regex can't distinguish it from safe `backdropExtractOp`; reads source-controlled template — intentionally unflagged).

## Local review (pre-push)

- **Critic** (fresh context; crashed mid-review — connection lost — and was resumed with cleanup orders): verdict OK-merge + 2 MINORs — (1) anchor `\bREPO_ROOT\b` word boundaries, (2) add the residual-gap header note. Both taken.
- **CodeRabbit CLI** (v0.6.5, 13 files): 1 MINOR — word-bound the real-root alternatives. **Same finding class as critic MINOR 1 — independent reviewer convergence.** Idea taken; literal patch **partially rejected with documented rationale**: dropping the `repoRoot` alternative (as proposed) would blind the scanner to frontmatter/renderer/templates reads AND trip the stale-entry self-check. Kept a bounded `\brepoRoot\b` instead.
- Post-push: 0 reviews, 0 comments, 0 post-merge fixes (verified: #340 is the latest merge; nothing after it). **Shift-left rate: 100%.**

## Metrics

- adversarialCatchRate: **1.0** (evidence-based: 2 distinct local finding classes — regex word-boundary, residual-gap note — both caught by the adversarial critic; CodeRabbit's 1 finding was the same class as critic finding 1; 0 issues escaped to post-push/post-merge).
- fixupCommitRatio 0.0; postMergeFixRate 0.0; preMergeIterationCount 1 (healthy).
- Pre-merge catch by step: 4c (CodeRabbit) 1, 4d (adversarial) 2, postPush 0. Taxonomy: correctness 1 (regex), documentation 1 (header note).
- Step compliance: 8/9 (~89%). Skipped: 4a (simplify, not evidenced) and the build sub-step of 3 (fresh worktree, no node_modules, Turbopack out-of-root; test-only diff + typecheck superset green — justified). Skip assessment: **good** (zero escaped issues; CI green first run).
- Step timing: Plan ~8m (delegated Explore live-read catalog sweep over ~24 candidates) | Implement ~10m | Test ~6m | Review ~7m | Push ~3m | **Total ~34m**. Bottleneck: implement (mild; no real friction).
- Planning quality: complete (entry points = whole test suite enumerated via delegated sweep; scoping rationale + residual risks written up; Performance & Cost n/a for a test-only guard — scanner cost is per-test-run regex over test files, negligible).

## Notable process data

1. **Reviewer convergence on a finding class** (critic + CodeRabbit → same regex weakness) correctly upgraded priority; **divergence-with-rationale** on the literal patch (partial rejection, documented in the PR body) is the healthy counterpart. → New Review Discipline entry.
2. **Three-act campaign closed same-day**: reactive → proactive → structural, with the structural guard shipping calibration + bite + un-bless proofs. → Strengthened the Follow-Up Discipline #335/#337 entry to CAMPAIGN COMPLETE.
3. **Critic crash resilience**: the critic connection dropped mid-review; resuming the same agent with cleanup orders (rather than respawning fresh) preserved review context and still produced a full verdict. Minor data point; not knowledge-filed (single occurrence).
4. Build-skip in fresh worktrees recurs (#335/#337/#340, same justification each time). If it recurs again, consider a worktree bootstrap step (`npm ci` or a shared pnpm-style store) or a standing "test-only diff ⇒ build skip is pre-justified" rule to stop re-litigating it per PR.

## Recommendations

1. **Done in-PR**: the campaign's terminal artifact shipped; no open recommendation from #337 remains.
2. Watch the file-level-blessing gap: any edit to the two tolerant smokes or `rebuildRecoveredProjects` must get its `LIVE-REPO INVARIANTS ONLY` block eyeballed in review (documented in the tripwire header; keep honoring it).
3. Worktree build-skip (point 4 above): promote to a standing rule or a bootstrap step rather than a per-PR justification if it appears a fourth time.
4. Export the guard pattern: other projects with mutable product data alongside tests (per the "tests must not couple to product data" cross-project memory) are candidates for the same tripwire shape — calibration/bite/un-bless proofs included.
