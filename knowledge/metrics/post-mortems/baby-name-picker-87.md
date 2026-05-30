# POST-MORTEM: baby-name-picker PR #87 — Correct name pronunciations and origins (audit batch 1)

Branch: `fix/name-data-audit-batch1` → `main` | Author: padminipyapali | created→merged ~4h 12m
Size: +274 -185 across 3 files, 2 commits

> Analyzed late (PR merged 2026-05-29; post-mortem run 2026-05-29 same day, after the remediation PRs had already landed). This is the root-cause PR of the #87→#89/#90/#92 data-regression incident, which the knowledge base already documents extensively (CI gap, flattened-view audit, two-sided guard tests). This post-mortem adds the missing metrics row and one new critic-blind-spot lesson; it deliberately does NOT duplicate the already-captured lessons.

## LOCAL REVIEW (pre-push)
- CodeRabbit (4b): NOT run (null).
- Adversarial (4c, fresh-context critic): verified MECHANICAL integrity only — rebuilt `seed.db` byte-faithful to SQL, 0 null `origins_json`, 0 invalid JSON, no field-shift, Indic sweep didn't over-correct long vowels. Flagged 2 judgment items (Iniya, Zhi), both resolved (Iniya → commit 2). **Did NOT verify semantic correctness of the new etymologies.**
- Shift-left: 2 issues caught locally; **11 semantic regressions escaped** to post-merge.

## STEP COMPLIANCE
- No `Steps skipped:` line → recorded null. Actual: ran 1, 2, 3, 4c; skipped 4b (CodeRabbit).

## STEP TIMING
- Not tracked (no section).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no CHANGES_REQUESTED). Comments: 0/0. CI: none configured (`statusCheckRollup: []`).
- Self-merged by author, no peer review. Timeline: created → merged ≈ 4.2h.

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch rate ≈ 15% (2 caught / 13 total issues; 11 escaped).
- Covered but missed: **data semantic correctness** — the critic checked structure, not truth. This is the new lesson (added to Critic Blind Spots).
- The escaped class: stripped legitimate origins (Cyrus Greek, Uma Hebrew, Milan/Rhea/Xara collapsed) + injected homophone glosses (Neel→Neil, identical Arabic gloss on Mira AND Meera).

## FIX-UP METRICS
- **Post-merge fix rate: 1.0 (capped)** — quality escaped ALL gates and shipped wrong data. THREE remediation PRs: #89 (restore 5 test-caught names), #90 (restore 6 untested-but-regressed names), #92 (Esha). The formula (post_merge_fix_commits/total_commits = 3/2) exceeds 1; capped at 1.0 — this is the worst-case escape in the dataset.
- Pre-merge catch by step: 4d (adversarial) 1 (Iniya correction), others 0.
- Pre-merge iteration count: 1.
- Fix-up taxonomy: correctness 1 (the Iniya pre-merge fix). Legacy fix-up ratio: 50% (1 fix / 2 commits).

## PLANNING QUALITY
- Description: complete (Summary, How, Test plan, Deferred, Local Review). No Performance section (data-only — n/a).
- Scope: clean and well-scoped as a batch; the failure was correctness, not scope.

## CODE QUALITY SIGNALS
- Recurring issue: data correctness on bulk-edit PRs (the central incident).
- New unrecorded pattern: **critic verified mechanical integrity but not semantics** → added to process-patterns Critic Blind Spots.
- Already-captured (NOT re-added): CI gap escalation (line ~129), flattened-view audit lesson (line ~209), two-sided guard tests (line ~212), verify-shipped-artifact (line ~210), the corrective data-audit harness with per-change adversarial semantic verification (Data Quality section).

## PROCESS EFFICIENCY
- Automation opportunities: (1) CI (tsc+jest+expo lint as required checks) — would have blocked the red merge; the single highest-leverage gap. (2) the data-audit harness (source-grounded + per-change skeptic + human gate) now exists as the corrective for future batches.
- Iteration: efficient within the PR (1 round) — but that efficiency was illusory because the review gate measured the wrong thing.
- CI: none. The corrections turned the jest suite RED and nothing blocked merge.

## KNOWLEDGE UPDATES
- `process-patterns.md` → NEW Critic Blind Spots entry: mechanical-integrity verification ≠ correctness verification; data/content PRs require semantic spot-checks against sources.
- Metrics + dashboard updated (this row was previously missing).

## RECOMMENDATIONS (ranked)
1. **Ship CI as required PR checks** (tsc + jest + expo lint). This is the dominant lesson of the whole #87/#89/#90 incident: a correct local run would have caught the red suite; a server-side gate would have made that run non-optional. Highest leverage, repeatedly deferred.
2. **For data/content PRs, the critic mandate must be "verify the changes are RIGHT," with a per-source semantic spot-check** — never let a clean mechanical-integrity pass stand in as the correctness gate.
3. **Adopt the data-audit harness for every future bulk-data batch** (source-grounded, per-change adversarial verification, `uncertain` flag, human gate, parsed-diff critic). It already exists post-#92; make it the default path.
4. Add the `Steps skipped:` line to the PR-body template so 4b skips are at least tracked.
