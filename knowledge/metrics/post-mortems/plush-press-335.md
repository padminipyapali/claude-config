# Post-mortem: plush-press #335 — Decouple the face-crop integrity test from the live catalog.

- **Branch:** fix/reciperefs-test-coupling → main | **Author/merger:** padminipyapali (self-merge, no peer review — solo workflow)
- **Merged:** 2026-07-20T14:41:54Z | PR-open-to-merge ~8 min (created 14:34:16); commit-to-merge ~12 min
- **Size:** +71 / −42 across 1 file (`studio/src/lib/scene/__tests__/recipeRefs.test.ts`), 1 commit. Test-only.
- **Origin:** URGENT CI UNBLOCK. Main's `CI / studio` check went red ~04:53 (operator autosave/graduation data commits added the human `shalu-pini` with no face-crop asset) and stayed red ~10 hours. The failing assert — `recipeRefs.test.ts:204` `expect(orphans).toEqual([])` against the LIVE `cast-kind.json` + `assets/facecrops/` — is the recurring **tests-must-not-couple-to-product-data** class (ledgered 2026-06-16; memory note; `docs/BUGS.md`). #334 had been merged over this pre-existing red; its post-mortem's recommendation #1 was exactly this fix. #335 shipped it ~20 minutes later.

## The fix

Converted the `face-crop asset integrity` suite to a constructed fixture: `mkdtempSync` facecrops dir (`beforeAll`/`afterAll` cleanup) + in-memory `FIXTURE_CAST` covering a crop-bearing human, a hyphenated-crop human, an animal (never flagged), a documented-unseeded human (tolerated), and a deliberately-orphaned newly-added human (flagged as the SOLE orphan). All live-repo reads (`readFileSync`/`fileURLToPath`/`REPO_ROOT`) removed; the `DOCUMENTED_UNSEEDED` per-character allowlist treadmill removed with them. The `cropOrphans()` helper is parameterized on data (dir + allowlist) but calls the REAL `faceCropSlug` production function — verified both by the critic (an explicit check item) and by diff inspection in this post-mortem (line: `existsSync(join(cropDir, `${faceCropSlug(k)}.png`))`). The suite now passes regardless of live catalog state; grep confirms zero live-catalog paths remain.

## Local review (pre-push)

- **Fresh-context critic:** OK-ship, **0 findings** — including verifying the fixture exercises the real `faceCropSlug` rather than a re-implementation (the classic fixture-tests-a-copy trap).
- **CodeRabbit CLI** (v0.6.5, single clean run): **0 findings**, 1 file reviewed.
- **Gates:** typecheck GREEN, lint GREEN, full vitest 2540 pass / 0 fail (target file 21/21). **Build declared-skipped in-worktree** — worktree had no `node_modules` and a symlink tripped Turbopack's out-of-root check; justified because the diff is test-only, `*.test.ts` is excluded from the production bundle, and typecheck (a superset that compiles the test file) is green. Skip assessment: **good** — CI (which does build) ran green on the PR, 0 escapes.

## adversarialCatchRate = unmeasured

Zero findings from every lens (critic 0, CodeRabbit 0, 0 post-push comments, 0 post-merge fixes) → no denominator exists. Recorded as `"unmeasured"` per the integrity rule (never fabricate). Note this is the clean-sheet flavor of unmeasured, not the not-tracked flavor: both reviewers ran and returned structured zero.

## Metrics summary

- Review rounds 1; comments 0; CI check `studio` SUCCESS pre-merge (main un-reddened by this merge).
- postMergeFixRate 0.0 — #335 is HEAD of main at analysis time; no follow-up PRs touch the file.
- Pre-merge catch by step: all 0 (single feature commit, no fix commits). Iterations: 1 (healthy). Taxonomy: all zeros.
- Legacy fix-up ratio: 0% (0 fix / 1 commit).
- Planning quality: **complete** — root-cause narrative with the exact failing assert, fixture design rationale, decoupling proof, Local Review + Steps skipped + Step Timing sections. No Performance & Cost section needed (test-only; no runtime surface, no API calls). Parked-module context noted (recipeRefs has no production callers since the 2026-07-14 revert — the test's job is module honesty, not catalog policing).
- Step compliance: 7/9 (~0.78). Run: 1, 2a, 3, 4b (CodeRabbit), 4c (adversarial critic), 4d (CI), 5. Skipped: 2b (retired from flow), 4a (/simplify — not evidenced; defensible for an urgent single-file test-only fix). Skip assessment: **good**.
- Step timing: qualitative only (no durations) — recorded in notes; total wall-clock branch-to-merge ~12 min.

## Process notes

- **This PR is a recommendation-loop success story.** #334's post-mortem (same day) listed "Fix `recipeRefs.test.ts` orphan assert" as recommendation #1; #335 landed it ~20 min later as a focused micro-PR, simultaneously resolving recommendation #2's tension (no more merging over red — this merge restored green). Counterexample to the "recommendation drift" failure mode documented in `process-patterns.md`.
- **But it is also the class's SECOND firing.** The 2026-06-16 ledger entry did not prevent `recipeRefs.test.ts` from shipping the same live-snapshot pattern later. A ledger entry alone is prose; the durable fix is structural (fixtures) — and per the sibling-sweep convention, the second occurrence is the trigger to sweep the whole suite, not just the file that fired (see recommendation 1).
- **Latency cost of the class:** the operator's ordinary content work reddened main for ~10h and forced one merge-over-red judgment call. That is exactly the blast radius the ledger entry predicted.
- Team pattern held under urgency: orchestrator + implementer + fresh-context fast critic, worktree isolation, all four declared gate outcomes in the PR body including an explicit, justified build skip — urgency did not degrade evidence discipline.

## Recommendations (ranked)

1. **Sibling sweep the suite for remaining live-data asserts.** #335 closes the class "for this file" (its own words). Grep `studio/src` tests for `REPO_ROOT`/live-path reads paired with exact `toEqual`/count asserts (e.g., any other catalog-integrity blocks) and convert survivors to invariants-or-fixtures in one micro-PR — the second firing proves the class outlives single-file fixes.
2. **Consider a lint/CI tripwire for the pattern** (e.g., forbid `fileURLToPath(import.meta.url)`-derived repo-root reads inside `__tests__` except in explicitly-marked invariant blocks) so the third occurrence is caught at authoring time, not on a red main.
3. Keep the "declared build skip" shape used here as the template for test-only urgent fixes: name the gate, the environmental blocker, and the superset gate that covers it.

## Knowledge updates

- `~/.claude/knowledge/testing-patterns.md` — live-product-data entry marked RESOLVED for `recipeRefs.test.ts` by #335, with two reusable hygiene points (fixture helper must call the real production function; test-only build-skip justification shape).
- `~/.claude/knowledge/process-patterns.md` — new Follow-Up Discipline entry: a ledgered recurring class firing again is a stop-the-line micro-PR + full sibling sweep, not another ledger entry.
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` — entry appended (474 total); dashboard regenerated.
