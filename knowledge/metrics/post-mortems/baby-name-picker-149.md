# POST-MORTEM: baby-name-picker PR #149 — Add 17 more Euphony-discovered real names to the seed catalog

Branch: `feat/seed-fantasy-derived-names` → `main` | Author: padminipyapali | created 2026-06-02 01:58:33Z, merged 2026-06-02 03:33:44Z (~1.6 h wall, but the PR commit itself was a single clean commit; elapsed includes the branch's earlier pronunciation work).
Size: +41 −6 across 6 files, 1 commit. Self-merged (squash). No reviews, no inline/general comments, `statusCheckRollup: []` (no CI gate). Built via orchestrator team (implementer → adversarial critic, verdict PASS, no blockers).

## What this PR was
The SECOND harvest of the "generate → screen → salvage the reals → enrich" pipeline first run in #141. During Euphony invented-name generation, 24 candidates surfaced as genuinely-attested real names; 7 (Soraya, Rosalind, Naia, Soren, Theron, Alaric, Emeric) were dropped as already in the catalog, and 17 were enriched (accurate meaning, true origin, gender, pronunciation, category, syllables, length, meaning_depth) and added. Catalog grows 1290 → 1307 (ids 1302–1318). Files: `scripts/seed-data.sql` (17 INSERTs + per-id meaning_depth UPDATEs + sqlite_sequence bump to 1318), `assets/seed.db` (deterministically rebuilt, 1307 names, meaning_depth avg 3.33 in-band), `src/services/originFamily.ts` (+1 line: Anglo-Saxon→English rollup, for Caedmon), and the seed test-count constants + originFamily test (1290→1307; test loop extended to assert Anglo-Saxon maps to English).

## LOCAL REVIEW (pre-push)
- CodeRabbit (4b): not tracked / skipped — consistent with #141's recorded rationale ("low-signal for a data-only change"; CodeRabbit reviews code idioms, not catalog data values).
- Simplify (4a): skipped (same reason).
- Adversarial critic (4c): run. Verified schema shape, source-JSON↔SQL consistency, data integrity vs source, real-name/meaning accuracy spot-checks, originFamily, regressions — all PASS, 0 blockers.
- Shift-left: n/a (no findings surfaced to fix).

## STEP COMPLIANCE
- Steps run: 1, 2, 3, 4c, 5.
- Steps skipped: 4a (/simplify), 4b (CodeRabbit) — reason: pure data addition; those steps review code structure, not data values.
- Compliance rate: 0.56 (5/9).
- Skip assessment: **good** — no post-merge issues; the skipped steps target code idiom/structure, but this PR changed almost no logic (1 origin-map line), and the real risk class (attestation/meaning/origin accuracy) was covered by the 4c critic.

## STEP TIMING
- Not tracked (no `## Step Timing` section in body).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general.
- Self-merged with no peer review (consistent solo-dev pattern; the 4c critic substitutes for a human reviewer).

## ADVERSARIAL REVIEW EFFECTIVENESS
- The engineering of note is upstream of the diff: the repeatable generate → screen → salvage → enrich pipeline. #149 ran it a SECOND time with the same shape as #141 — high-recall surface of generator byproducts, per-candidate verification of genuine attestation + accurate sourced meaning + TRUE origin, and a hard drop for anything that fails (here, 7 dropped as already-cataloged — the dedupe analogue of #141's attestation drop-gate).
- Covered but missed: none. Not covered (new categories): none new.
- Notable sub-decision (the origin-vocabulary expansion): when Caedmon's true origin "Anglo-Saxon" was a synonym/ancestor of an existing family root, the fix was to EXPAND the `originFamily` rollup (Anglo-Saxon→English) rather than mislabel the data to fit the existing vocabulary; and Occitan/Catalan were deliberately left standalone rather than forced into a Romance grouping the module doesn't model. Data drives the vocabulary, not vice-versa. Safe because origin is free-text with identity fallback, so a new rollup is purely additive.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no follow-up fix PRs after merge). Ideal — matches #141.
- Pre-merge catch rate by step: all zero (single clean commit, no fix commits).
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all zero.
- Legacy fix-up ratio: 0% (0 fix / 1 total commit).

## PLANNING QUALITY
- Description: complete (Summary, Changes, Testing). Documents the screened-but-skipped 7, the origin-family decision and the deliberate Occitan/Catalan non-grouping, and test results (843 pass / 51 suites, tsc 0, lint 0).
- Scope: clean. Single concern (data + the minimal origin-map/test updates the data forces). 1 commit.
- Planning checklist: appropriate for a data PR; no Performance/Cost section needed (17 static rows, +1 map entry, no new code path).

## CODE QUALITY SIGNALS
- Recurring (positive) patterns confirmed: data-quality-first, source-grounded, adversarially-verified, drift-guard tests extended alongside data, data-drives-vocabulary for origin rollups.
- New unrecorded patterns: none — all behavior is captured in process-patterns.md (semantic-critic mandate, generate→screen→salvage template, justified-and-recorded 4b skip).

## PROCESS EFFICIENCY
- Automation opportunity: the standing CI-gate gap (`statusCheckRollup: []`) remains — a server-side `tsc + jest + lint` gate would make the local 843-test run non-optional and guard against a silently-drifted count constant. Also standing: a pre-push hook that blocks UNRECORDED 4b skips (this PR's body records its skip rationale, modeling the right behavior).
- Iteration: efficient (1 round). CI status: no checks configured.

## RECOMMENDATIONS (ranked)
1. Adopt the generate→screen→salvage→enrich pipeline as the official reusable template for catalog growth. Two independent runs (#141: 50 names, #149: 17 names) now both produced a 0% post-merge-fix rate — it is proven, not anecdotal. Document the drop-gate variants (unattested-drop in #141, already-cataloged-drop in #149) so future harvests dedupe and verify the same way.
2. Codify the origin-vocabulary expansion rule: when a verified true origin is a synonym/ancestor of an existing family root, extend the `originFamily` rollup map rather than relabel the data; leave genuinely-distinct origins standalone. Data drives the vocabulary.
3. Ship the GitHub Actions PR gate (`tsc --noEmit` + `jest` + `expo lint`) — the highest-leverage standing item across this project's data PRs (#87/#126/#141/#149). A PR that bumps test-count constants is exactly the kind a server gate should guard.
4. Land the 4b-skip pre-push hook in recorded-skip form (block only UNRECORDED skips; accept a `Steps skipped:` line with reason). #126/#141/#149 all model the line content to accept.

## KNOWLEDGE UPDATES
- Strengthened `process-patterns.md` semantic-critic / generate-screen-salvage entry: added #149 as "repeatability-proven" (second independent run, 0% post-merge fix across both), and recorded the origin-vocabulary-expansion sub-decision (data drives vocabulary; expand rollup vs. mislabel; leave distinct origins standalone).
- Appended metrics entry + regenerated dashboard.
