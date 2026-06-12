# Post-Mortem: baby-name-picker PR #193 — Add 80 unique-list girl and boy names to the catalog.

- **Branch:** feat/add-unique-list-names → main | **Author:** padminipyapali | created 2026-06-12T04:12Z, merged 2026-06-12T04:19Z (7 min open-to-merge; total session wall-clock ~8h from plan ~13:20 PT to merge ~21:19 PT, dominated by the critic window and user-approval latency, not implementation)
- **Size:** +1118/-16 across 10 files, 1 commit (670e0ef; rebased onto main after #192's squash-merge, union merge on research JSONs, counts recomputed to 1536)
- **Process:** Full 3-role team (orchestrator / implementer / fresh-context critic). Catalog grew 1413 → 1493 on this branch (1536 after both PRs).

## Local Review (pre-push)
- CodeRabbit CLI: 0 findings, 1 iteration (~3 min, no timeout).
- Adversarial review (fresh-context critic): **1 finding, 1 fixed pre-push** — Elodie's "foreign riches" origin was labeled Greek but is etymologically Germanic (Alodia/Visigothic *alōd*); fixed in origins_json + meanings_json per default-to-fix, amended before push. Critic web-verified 18+ meanings/origins including all 10 author-flagged uncertain names and the gender-neutrality calls.
- Shift-left rate: **100%** — the only issue found anywhere in this PR's lifecycle was caught locally, pre-push.

## Step Compliance
- Steps run: 1, 2, 3, 4a, 4b, 4c, 5 — all steps of the current 6-step flow. Compliance: 100%.
- Skips: Playwright sub-step of Step 3 (data-only change, Skip tier). Assessment: **good** — zero post-merge issues.
- No literal `Steps skipped:` line and no `## Step Timing` section in the body; compliance reconstructed from the `## Local Review` section + orchestrator log.

## Step Timing
- Not tracked in PR body → recorded as null in metrics. From the orchestrator log: plan ~13:20-13:30 PT, implement done ~13:55 (commit 0a728db, 80 names, 1019 tests green), critic 14:00 → 21:10 PASS (window inflated by the parallel mythology work and the id-collision tangle, not by review effort), PR 21:10, rebase + re-verify + merge 21:19.

## Review Friction (post-push)
- 0 reviews, 0 inline comments, 0 general comments. Self-merged with no peer review (solo repo; fresh-context critic is the gate).
- Review rounds: 1. Note: the critic issued one transient BLOCK mid-session, but it was triggered by observing the id-collision/renumber mess across the two branches (an orchestration sequencing issue), not by any code finding; once the branch stabilized at 0a728db the actual review was a single round.

## Adversarial Review Effectiveness
- **adversarialCatchRate: 1.0 — computed from evidence:** total known issues across the PR lifecycle = 1 (Elodie origin label); caught by the adversarial critic pre-push = 1; CodeRabbit 0; post-push review comments 0; post-merge fix commits 0 (as of this post-mortem). 1/1 = 100%. Attribution is verifiable in the PR body's Local Review section and the orchestrator log (~21:10 entry).
- Covered but missed: none. Not covered: none — data-correctness/etymology verification is already the critic's core checklist for catalog PRs (web-grounded verification pattern, process-patterns.md Data Quality).

## Fix-Up Metrics
- Post-merge fix rate: 0.0.
- Pre-merge catch rate by step (schema keys: 4d = adversarial): 4a 0 | 4b 0 | 4c (CodeRabbit) 0 | 4d (adversarial) 1 | post-push 0. The fix was amended into the single commit pre-push, so commit history shows 0 fix commits.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: correctness 1, all else 0. Legacy fix-up ratio: 0% (0 fix / 1 commit).

## Planning Quality
- Description: **complete** — Summary, Local Review, Known gaps, Sequencing note, Test plan. (No Step Timing section — the one body-template gap vs #192.)
- Scope: clean, single theme, zero redesign indicators.
- **PR size 1134 LOC exceeds the 600 cap** — but qualifies for the established data-bulk exception: the diff is almost entirely seed rows (`scripts/seed-data.sql`), research JSONs, and the rebuilt `assets/seed.db`; hand-written logic is limited to test-constant bumps. Payment was made: deterministic idempotent build, fresh-rebuild integrity checks, web-grounded critic verification.
- Known gap honestly declared: SSA popularity backfill blocked (ssa.gov 403 Akamai); 80 names ship NULL `popularity_rank` with the backfill command documented.

## Code Quality Signals
- Recurring issues: none. One correctness finding (origin mislabel) is consistent with the known risk profile of LLM-researched seed data — exactly what the web-grounded fresh-context critic exists to catch, and it did.
- The author proactively flagged 10 uncertain names for the critic — good uncertainty-surfacing practice worth repeating in catalog PR briefs.

## Process Efficiency
- The session's friction was entirely the parallel-branch id collision (see #192 post-mortem and orchestrator-protocol.md Communication Flow #8): two collisions caused by mid-flight reservation messages, one `reset --hard` recovery, one transient critic block.
- The post-#192 merge conflict resolved per the standard catalog recipe (rebase, union merge, recompute counts, orchestrator independently re-verified the rebuilt DB: 1536 rows, 80+43 intact, 0 missing fields, 13/13 seed suites / 286 tests) in ~4 minutes — evidence the documented recipe works.
- CI: no failures reported.

## Knowledge Updates
(Shared with #192 — written once for the session.)
- `orchestrator-protocol.md` (Communication Flow #8): spawn-brief reservation rule.
- `process-patterns.md`: catalog-collision entry strengthened (id-allocation-space dimension); stale-worktree resumption pattern; blocked-enrichment NULL+backfill pattern.

## Recommendations
1. **Serialize catalog PRs or partition id ranges in spawn briefs** — third+ recurrence of the catalog-collision pattern; the spawn-brief rule is now in orchestrator-protocol.md, cite it at dispatch time.
2. **SSA backfill follow-up** (shared with #192): 123 names have NULL `popularity_rank`; retry the build script when ssa.gov is reachable or use `--names-zip` with a manual download. Convert to a tracked issue so the prose flag doesn't rot.
3. **Add `## Step Timing` and a literal `Steps skipped:` line to every catalog PR body** — #192 had timing, #193 didn't; the metrics pipeline records null where the orchestrator log clearly had the data.
4. Keep the "author flags uncertain names for the critic" practice — it focused the critic's web verification and produced the session's only catch.
