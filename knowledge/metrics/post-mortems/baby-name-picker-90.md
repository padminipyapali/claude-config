# POST-MORTEM: baby-name-picker PR #90 — Restore 6 more name etymologies regressed by audit batch 1 (#87)

Branch: `fix/seed-data-audit-regression-2` → `main` | Author / merged by: padminipyapali (self-merge)
Created: 2026-05-29T04:41:07Z | Merged: 2026-05-29T04:48:44Z (squash, commit `60eac86`; source commit `cdfe0b2`)
Duration: ~7.6 min wall-clock created→merge.
Size: +135 / -6 across 3 files, 1 commit — etymology-only restore in `scripts/seed-data.sql`, regenerated `assets/seed.db`, and extended `src/db/__tests__/seed-corrections.test.ts` (the +135 is mostly the new test coverage).

## Context — the re-audit, and HOW the extra regressions were found

Follow-up to #89. #89 fixed the 5 #87 regressions the test suite already caught; this PR re-audited the **17 other names #87 changed** (the untested set flagged in #89's follow-up section) and found **6 more genuine regressions** that had shipped silently because nothing covered them. Restored etymology fields only — #87's legitimate **pronunciation** corrections were preserved.

| Name | #87 regression | Restored (pre-#87) |
|---|---|---|
| Cyrus | dropped Greek origin + "lord" gloss | `[Persian, Greek]` — sun / lord |
| Kai | invented `Chinese:"victory"` + `Scandinavian:"keeper of the keys"` | `[Hawaiian, Japanese]` — sea / sea |
| Mira | spurious `Arabic:"provisions, supplies"` + `Hindi` | `[Latin, Sanskrit, Slavic]` — wonderful / ocean / peace |
| Meera | same spurious `Arabic:"provisions, supplies"` | `[Hindi, Sanskrit]` — ocean / devotee of Krishna |
| Soren | duplicate zero-info `Latin:"stern, severe"` | `[Danish, Scandinavian]` — stern / severe |
| Neil | `Sanskrit:"blue, dark"` (belongs to the distinct name *Neel*) | `[Irish, Gaelic]` — champion, cloud |

The Mira/Meera identical `Arabic:"provisions, supplies"` gloss — the same wrong value stamped on two spelling variants — was the clearest batch-error signature. Of the 17 examined: 6 regressed (fixed here), 3 judged legitimate (Neo, Asha, Cyrano), 8 plausible and kept by user decision (Caspian, Aria, Mina, Tobin, Ria, Anoushka, Kiara, Myra).

## KEY INCIDENT — test-coverage-as-prevention was deliberately EXTENDED (the durable fix)

The #87 regressions that #89 caught were caught *because* they had coverage; the 6 here shipped silently *because* they didn't. #90's durable response was to grow the seed-corrections suite to cover them, with **two paired assertions**:
- `RESTORATIONS` — the exact restored `origins_json`/`meanings_json`/`meaning`/`origin` for all 6 (the "correct value present" fence).
- `RESTORATION_REMOVED_GLOSSES` — the #87-injected contaminants must stay **absent** (Mira/Meera Arabic "provisions, supplies"; Kai Chinese/Scandinavian; Neil Sanskrit/"blue"; Soren Latin) AND Cyrus must **keep** Greek "lord" (the "specific bad value absent" fence).

The forbidden-value half is what makes the specific regression class un-reintroducible: a future audit batch can't silently re-inject the same homophone contamination without the suite going red. Captured as a knowledge pattern: a regression-guard test should be a two-sided fence (corrected value present + known-bad value absent).

## KEY INCIDENT — a subagent misdiagnosis was caught by the critic

During #90 an implementer reported a **258-row binary churn** in the regenerated `seed.db` and suspected build non-determinism — which, if believed, would have blocked the PR or launched a needless pipeline investigation. The fresh-context **critic independently re-derived the diff and proved it was a clean 6 rows** (exactly the intended edits), with `build-seed-db.py` confirmed deterministic (a rebuild produced an md5-identical *parsed* cell dump). The miscount came from diffing the raw SQLite binary, where page/key-order/layout churn inflates the apparent diff far beyond the logical change. Captured as: (1) don't act on a subagent-reported anomaly until a second independent pass reproduces it; (2) diff generated binary artifacts by comparing a canonical *parsed* representation (row-by-row JSON cell dump), never raw bytes.

## AUDIT-ON-FLATTENED-VIEW false positives (reinforces existing knowledge)

#87's flattened-view audit both **stripped real origins** (Cyrus's Greek "lord") and **injected homophone-contaminated glosses** (Neil ← *Neel*; Mira/Meera ← identical spurious Arabic). Reinforces `audit-structured-not-flattened` (#43), with the new twist that an identical gloss landing on two homophones/spelling-variants is a red flag for cross-name contamination.

## LOCAL REVIEW (pre-push)

- CodeRabbit (4b): NOT tracked (no CodeRabbit line in `## Local Review`). Recorded null.
- Adversarial (4c): data + test change — no runtime code surface. 0 findings.
- Fresh-context critic: **SHIP** — verified all 6 edits are exact and etymology-only (pronunciation/other columns byte-identical), the new coverage genuinely guards the regression, and independently proved the binary diff is a clean 6 rows (debunking the implementer's 258-row miscount) with the pipeline confirmed deterministic.
- Shift-left: the critic's debunk of the 258-row anomaly prevented a false build-non-determinism investigation — verification value, not a fixed-in-PR code finding.

## STEP COMPLIANCE

Not explicitly tracked (no `Steps skipped:` line → `stepCompliance` recorded null, per rule). Inferred: Plan (1), Implement (2a), Test — tsc PASS (pre-existing web/* only) / lint PASS (4 known warnings) / jest 466/466 green (3), Adversarial (4c), fresh-context critic, Push/PR (5) all ran; CodeRabbit (4b) and CI (4d — none) did not. Missing `Steps skipped:` line — same drift as #83/#86/#88/#89.

## STEP TIMING

Not tracked (no `## Step Timing` section). Wall-clock created→merge ~7.6 min.

## REVIEW FRICTION (post-push)

Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general, 0 GitHub reviews (solo flow; fresh-context critic in-process). Self-merge by author. Timeline: created → merge ~7.6 min.

## ADVERSARIAL REVIEW EFFECTIVENESS

Pre-push catch potential: n/a — no issue escaped to post-merge. The critic's material contribution was verification + debunking the 258-row anomaly, not a fixed-in-PR adversarial finding.
Covered but missed: none. Not covered: "verify subagent-reported anomalies independently" + "diff parsed content not bytes" are process/knowledge additions, not adversarial-checklist tiers.
**adversarialCatchRate = unmeasured** — no post-push reviews and no fixed-in-PR adversarial finding to measure against (critic SHIP). Not fabricated.

## FIX-UP METRICS

- Post-merge fix rate: 0.0 — no follow-up fixes #90 itself.
- Pre-merge catch rate by step: all 0 — single squash commit, no fix commits. (The 258-row debunk happened pre-commit in-process; it is not a separable fix commit.)
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all 0 (single fix commit).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## PLANNING QUALITY

Description: **complete** — Summary, etymology-only-vs-pronunciation-preserved framing, wrong→restored table, an explicit "the durable fix" test-coverage section, a "8 others intentionally kept" disposition of all 17 names, and a Test plan including the parsed-JSON cell-by-cell binary verification (with the 258-row miscount debunked). Scope: clean — single concern (the 6 regressed names + their guard tests). Branch lifetime: ~7.6 min.

## PROCESS EFFICIENCY

Iteration: efficient (1 round). CI status: none configured (recurring; the enabler of the #87 incident). Automation opportunities: (1) **wire CI**; (2) a parsed-dump diff helper for `seed.db` regeneration so byte-level binary diffs never get misreported as churn; (3) the standing 4b-skip pre-push hook + `Steps skipped:` line.

## KNOWLEDGE UPDATES

- `process-patterns.md` — "Configure CI before the first implementation PR": ESCALATED (shared with #89) — #90 supplies the proof that the cost wasn't contained to the test-covered set (6 MORE untested regressions had shipped silently).
- `process-patterns.md` — NEW: two-sided regression-guard test (corrected value present AND specific bad value absent); #90's `RESTORATIONS` + `RESTORATION_REMOVED_GLOSSES` is the exemplar. Grow the verified-corrections suite when a batch regresses uncovered data.
- `process-patterns.md` — NEW: verify subagent-reported anomalies independently before acting; for build artifacts compare parsed content, not raw bytes (the 258-row miscount debunk).
- `process-patterns.md` — audit-structured-not-flattened note: reinforced with Neil←Neel and Mira/Meera identical-gloss homophone-contamination evidence (shared with #89).

## RECOMMENDATIONS (ranked)

1. **Ship a CI gate (tsc + jest + expo lint) now.** #90 is the proof the #87 damage exceeded the test-covered set — 6 untested regressions shipped silently. A gate that blocks red merges is the root fix; flagged across six post-mortems.
2. **Add a parsed-dump diff helper to the seed.db build pipeline** so regeneration diffs are reported on canonical content, preventing a repeat of the 258-row byte-diff miscount.
3. Build the 4b-skip pre-push hook and restore the `Steps skipped:` PR-body line.
