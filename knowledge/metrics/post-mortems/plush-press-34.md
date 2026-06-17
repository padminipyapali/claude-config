# POST-MORTEM: plush-press PR #34 — Add the Characters data layer: list, create, update, and routes.

Branch: feat/characters-data → main | Author: padminipyapali | created 2026-06-16T23:23:54Z, merged 2026-06-17T00:06:36Z (~0.71h)
Size: +1038 -31 across 9 files, 1 commit (squash-merged 69ef4ce)

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (skipped per session preference — step 4b)
- Adversarial / fresh-context critic: 1 must-fix found and fixed pre-merge — the update path 404'd for `cat/berlioz` (dir slug ≠ filename, a real cast member), plus the test gap that hid it (all fixtures had dir==filename). Fix: resolve target file via the registry's true path; +2 regression tests pinning the slug≠filename case.
- Critic also verified: front-matter round-trip byte-for-byte, wipState caller safety (scene signatures + mutex unchanged), listCharacters filter, traversal/slug safety, error contract.

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9)
- Steps skipped: 4b (CodeRabbit) — reason: session preference
- Compliance rate: 88.9%
- Skip assessment: good (the must-fix was caught locally; 0 post-push findings)

## STEP TIMING
- Not tracked (no ## Step Timing section in PR body)

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED). No GitHub reviews/comments — review local via orchestrator team.
- Comments: 0 inline, 0 general
- Timeline: created → merge ~43 min; no GitHub review cycle.

## ADVERSARIAL REVIEW EFFECTIVENESS
- adversarialCatchRate: 1.0 (measured — 1 finding, caught locally by the critic, 0 escaped post-push)
- Covered but missed: none escaped. The dir≠filename write-path bug is a correctness/path-resolution class — now captured in process-patterns.md.
- Not covered (new categories): the "registry keys on content but files live under slug dir → write path must resolve true path + needs its own dir≠filename test" pattern.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no follow-up fix PRs reference #34 or its files)
- Pre-merge catch by step: 4a:0 4b:0 4c:1 4d:0 postPush:0 (the must-fix was caught by the fresh-context critic, fixed pre-merge inside the single squashed commit)
- Pre-merge iteration count: 1 (healthy — fixed in place before push)
- Fix-up taxonomy: correctness:1 (rest zero)
- Legacy fix-up ratio: 0% (squash-merged single commit)

## PLANNING QUALITY
- Description: complete (Summary + Review + Test plan + Steps skipped)
- Scope: clean — file-as-state data layer mirroring the proven scenes layer; wipState extended path-based WITHOUT changing existing (book,scene) signatures.
- Branch lifetime: ~0.71h
- Planning checklist: entry points covered (create/conflict/traversal, update front-matter-only vs bibleBody replace, dir≠filename, route integration). Caller-safety explicitly verified for wipState.

## CODE QUALITY SIGNALS
- Recurring issues: none
- New patterns captured: dir-slug≠filename write-path resolution + its test gap; parallel-agent WIP recovery after a transient rate-limit death.

## PROCESS EFFICIENCY
- Automation opportunities: a lint/test convention requiring a dir≠filename fixture wherever read-key and write-address differ.
- Iteration: efficient (1 round; must-fix resolved pre-push)
- CI status: typecheck/lint/build/vitest PASS (252 tests, +2 regression; existing scene/wipState suites green)

## KNOWLEDGE UPDATES
- process-patterns.md: added the content-keyed-registry write-path resolution + dir≠filename test pattern, and the parallel-agent transient-death WIP-recovery pattern.

## RECOMMENDATIONS
1. Whenever a registry's read path keys on content while the write path addresses by slug/dir, mandate a dir≠filename regression fixture — this is a structural test-gap class, not a one-off.
2. Codify the parallel-agent WIP-recovery step in the orchestrator protocol (inspect dead agent's worktree before restarting).
