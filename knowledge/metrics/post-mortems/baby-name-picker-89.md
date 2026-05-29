# POST-MORTEM: baby-name-picker PR #89 — Restore 5 name etymologies regressed by audit batch 1 (#87)

Branch: `fix/seed-data-audit-regression` → `main` | Author / merged by: padminipyapali (self-merge)
Created: 2026-05-29T04:10:56Z | Merged: 2026-05-29T04:20:21Z (squash, commit `8048229`; source commit `4cd2cf1`)
Duration: ~9.4 min wall-clock created→merge.
Size: +5 / -5 across 2 files, 1 commit — surgical etymology restore in `scripts/seed-data.sql` + regenerated `assets/seed.db`.

## Context — the bug, and HOW it was found

PR #87 ("audit batch 1," squash `69b8a54`) was a name-data audit run on the **flattened** `meaning` view. It regressed 5 etymologies that prior verified audits (#43/#55) had already corrected, and — critically — shipped that wrong data in the bundled `assets/seed.db`. On a project whose thesis is "data is the product," this is a product-breaking regression, not a nit. The 5 names were the ones the **seed-corrections test suite already covered**, so #87 also left that suite **red on `main`** (the 6 failing assertions documented at #88's merge time).

The five regressions #89 restored (each made internally consistent across `origin` / flattened `meaning` / `origins_json` / `meanings_json`):

| Name | #87 shipped (wrong) | Restored (verified) |
|---|---|---|
| Tala | `[Filipino, Native American, Arabic, Persian]` + spurious `"gold"` | `[Filipino, Native American]` — star, morning star / stalking wolf |
| Uma | `[Sanskrit]` (Hebrew stripped) | `[Sanskrit, Hebrew]` — splendor, light / nation |
| Milan | `[Slavic]` | `[Slavic, Sanskrit]` — gracious / union |
| Rhea | `[Greek]` | `[Greek, Sanskrit]` — flowing stream / singer, graceful |
| Xara | `[Greek]` | `[Greek, Arabic]` — joy / flower |

Regression source confirmed via `git log -S'"Arabic": "gold"' -- scripts/seed-data.sql` → #87 (`69b8a54`). `assets/seed.db` regenerated via `python3 scripts/build-seed-db.py`.

## KEY INCIDENT — the concrete cost of having NO CI gate

This is the capstone instance of the long-flagged CI-gate gap. #87 could merge **red and ship wrong data** only because no server-side gate exists — `tsc`/`jest`/`expo lint` run on the author's machine only (`statusCheckRollup` empty across the project's history). A correct local run on #87 would have caught the seed-corrections red; a CI gate would have made that run non-optional. The cost is no longer hypothetical: it directly produced shipped-wrong name data AND the red baseline #88 had to merge over, and spawned this PR plus #90 as the cleanup. The gap is now flagged across #81/#83/#86/#88 and is the **direct root cause of #87/#89/#90** — six post-mortems. Standing recommendation, now top-priority: wire `tsc --noEmit` + `jest` + `expo lint` into a GitHub Actions workflow so a red suite blocks merge.

## KEY INCIDENT — test-coverage-as-prevention worked (the 5 caught here = the test-covered set)

The only reason these 5 regressions were caught at all is the seed-corrections suite from #43/#55: #87's edits broke its assertions, turning the suite red, which surfaced the regression. The 5 fixed here are exactly the suite's covered set; the other regressions #87 introduced had no coverage and shipped silently (those become #90). This is the empirical argument for the verified-corrections suite as a regression fence — and for extending it whenever a batch operation regresses uncovered data (done in #90).

## AUDIT-ON-FLATTENED-VIEW false positives (reinforces existing knowledge)

#87 ran on the joined `meaning` string and both **stripped real origins** (Uma's Hebrew; Milan/Rhea/Xara collapsed to one origin) and **injected contaminated glosses** (Tala's spurious Arabic/Persian `"gold"`). Reinforces the existing `audit-structured-not-flattened` note (#43): audit the per-language `meanings_json`/`origins_json`, never the flattened projection.

## LOCAL REVIEW (pre-push)

- CodeRabbit (4b): NOT tracked (no CodeRabbit line in `## Local Review`). Recorded null.
- Adversarial (4c): data-only change — no code/Date/interactive/fire-and-forget surface. 0 findings.
- Fresh-context critic: **SHIP** — byte-level verification that the regenerated `seed.db` differs from the prior one in **exactly these 5 rows**; the other 1235 names and all 64 `family_json` rows are byte-identical; row count unchanged (1240). Critic also confirmed the 17-name follow-up finding is real (→ #90).
- Shift-left: n/a — critic returned SHIP with nothing to fix; the regression itself was caught pre-PR by the test suite going red.

## STEP COMPLIANCE

Not explicitly tracked (no `Steps skipped:` line → `stepCompliance` recorded null, per rule). Inferred from body: Plan (1), Implement (2a), Test — tsc PASS (pre-existing web/* only) / lint PASS (4 known warnings) / jest 454/454 green (3), Adversarial (4c), fresh-context critic, Push/PR (5) all ran; CodeRabbit (4b) and CI (4d — repo has none) did not. Missing `Steps skipped:` line is the same minor drift noted in #83/#86/#88.

## STEP TIMING

Not tracked (no `## Step Timing` section). Wall-clock created→merge ~9.4 min.

## REVIEW FRICTION (post-push)

Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general, 0 GitHub reviews (solo flow; fresh-context critic is the in-process reviewer). Self-merge by author. Timeline: created → merge ~9.4 min; no external review phase.

## ADVERSARIAL REVIEW EFFECTIVENESS

Pre-push catch potential: n/a — no issue escaped to post-merge from this PR. The critic's contribution was *verification* (byte-level row-diff, confirming only-5-rows-changed and the follow-up finding), not catching a new fixed-in-PR finding.
Covered but missed: none. Not covered: a data-regression-via-batch-audit class is not an adversarial-checklist target; it is a CI-gate + test-coverage problem (captured in knowledge).
**adversarialCatchRate = unmeasured** — no post-push reviews and no fixed-in-PR adversarial finding to measure against (critic SHIP, nothing to catch). Not fabricated.

## FIX-UP METRICS

- Post-merge fix rate: 0.0 — no follow-up fixes #89 itself. (#90 fixes *additional* #87 regressions, not #89's work.)
- Pre-merge catch rate by step: all 0 — single squash commit, no fix commits.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all 0 (single fix commit).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## PLANNING QUALITY

Description: **complete** — Summary, regression-source trace (`git log -S`), wrong→fixed table, thorough Test plan (incl. byte-level regeneration-integrity check), Local Review, and a correctly-scoped-out follow-up section flagging the 17 untested #87 changes for re-audit (→ #90). Scope: clean — single concern (the 5 test-covered names); surgically kept the 17 untested ones out. Branch lifetime: ~9.4 min.

## PROCESS EFFICIENCY

Iteration: efficient (1 round). CI status: none configured (recurring; the systemic enabler — see Key Incident). Automation opportunities: (1) **wire CI** (tsc + jest + expo lint) so red suites block merge — now demonstrably load-bearing; (2) the standing 4b-skip pre-push hook; (3) restore the `Steps skipped:` PR-body line.

## KNOWLEDGE UPDATES

- `process-patterns.md` — "Configure CI before the first implementation PR": ESCALATED with the #87→#89/#90 shipped-wrong-data cost; raised to the single highest-leverage open item across #81/#83/#86/#88 + #87/#89/#90.
- `process-patterns.md` — audit-structured-not-flattened note (#43): reinforced with #87's strip-real-origins + inject-contaminated-glosses evidence.
- `process-patterns.md` — NEW: two-sided regression-guard test (assert corrected value present AND specific bad value absent); grow the verified-corrections suite when a batch regresses uncovered data. (Caught the 5 here; extended in #90.)

## RECOMMENDATIONS (ranked)

1. **Ship a CI gate (tsc + jest + expo lint) now.** #87 shipping wrong data — and #89/#90 being needed to clean it up — are direct downstream effects of having no server-side gate. Highest-leverage, now flagged across six post-mortems.
2. **Merge #90** (the re-audit of the other 17 #87 names — 6 more regressions found) to fully reverse the bad batch.
3. Build the 4b-skip pre-push hook and restore the `Steps skipped:` PR-body line (carried over from #83/#86/#88).
