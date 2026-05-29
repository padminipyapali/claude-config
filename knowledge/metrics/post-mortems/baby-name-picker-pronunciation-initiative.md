# POST-MORTEM (INITIATIVE RETRO): baby-name-picker — Native Pronunciation

**Initiative:** Correct, enrich, and surface native vs. anglicized name pronunciations.
**Arc:** PRs #92 → #95 → #98 → #110 → #111 → #113 (all merged to `main` 2026-05-29).
**Author / merger:** padminipyapali (Claude Opus 4.8 co-author; orchestrator + implementer + fresh-context critic per role).
**Span:** ~16.5 h wall-clock (#92 merged 05:13Z → #113 merged 21:34Z, same day).
**Net source/data delta across the arc:** +1 schema column (`pronunciation_anglicized`), ~110 native corrections applied as native+anglicized pairs, 1 deliberate exclusion (Esha), 1 new detail-view layout (Layout B). Total churn ≈ +950 / -27 across the six PRs (large fraction is the audit/review HTML tooling + tests + mockups, not production source).

---

## Why this is one initiative, not six PRs

A single user-reported defect (Esha on a Compare card) exposed a systemic gap — the original bulk import (#41) never pronunciation-verified per name, and there was zero test coverage on the `pronunciation` field — and the response grew into a full data-quality program: a reusable web-grounded, adversarially-verified audit harness; an interactive human-in-the-loop review tool; incremental per-batch applies; a product pivot that turned "wrong" values into a feature; and the UI payoff. The PRs are tightly coupled (each builds on the prior's schema/data/tooling) and only make sense read together, so this is written as an initiative retro with per-PR metrics rows appended to `post-mortem-metrics.json`.

---

## The arc

| PR | What | Size | Merged (Z) |
|----|------|------|-----------|
| **#92** | Fix Esha `AY-shuh` → `EE-shah` (was the pronunciation of the *distinct* name Ayesha). | +1/-1, 2 files | 05:13 |
| **#95** | Interactive HTML review tool for the 50-name pilot (approve/reject/keep/change + comments + JSON export). | +298/-0, 1 file | 14:01 |
| **#98** | Apply the pilot's 11 approved corrections (`pronunciation` only). | +72/-11, 3 files | 13:58 |
| **#110** | Add `pronunciation_anglicized` column; apply 77 native corrections (batches 1–3) as native+anglicized pairs; back-fill the anglicized originals for the 11 from #98. | +214/-2, 18 files | 15:34 |
| **#111** | Apply batch-4's 22 corrections; **exclude Esha**; add an id-based regression guard. | +83/-6, 3 files | 16:18 |
| **#113** | Layout-B detail UI (two-row NATIVE / ANGLICIZED in `NameDetailBody`). | +282/-7, 3 files | 21:34 |

The audit harness itself (the multi-agent, web-grounded workflow) was not a PR — it produced the corrections that #95/#98/#110/#111 consumed. Pilot (50 names) + 4 batches ≈ 465 names researched, ~110 corrections found.

---

## KEY LEARNING 1 — Multi-agent, web-grounded, adversarially-verified audit is a reusable data-quality-at-scale pattern

The harness that produced the corrections is the most reusable artifact of the whole initiative. Its design:

- **Source-grounded, never model-opinion.** Every proposed change is backed by an external authority — Wiktionary IPA, Behind the Name, Forvo, Wikipedia — not the model's prior. A pronunciation with no citable source is not "corrected," it is left alone.
- **Adversarial verification per change.** Each proposed change is handed to an *independent skeptic* agent whose job is to refute it. Only changes the skeptic cannot refute survive as "confirmed corrections."
- **Conservative "uncertain" flag when sources disagree.** Where authorities conflict (e.g. Soraya stress), the harness does NOT guess — it flags the name `uncertain` and routes it to a human (the review tool in #95). Pilot output: 10 confirmed corrections, 11 flagged uncertain (not guessed), 29 confirmed correct.
- **Human-in-the-loop gate (#95).** The interactive review tool turns the audit into approve/reject/keep/change decisions with an apply-ready JSON export, so a human ratifies before anything touches `seed-data.sql`.

This is the **direct antidote to the #87 failure** (audit run on a *flattened view* shipped wrong etymology data to users, undetected because there was no test coverage and no CI gate — see baby-name-picker-88/89/90 post-mortems). #87 trusted a derived view + model judgment and shipped silently; this harness trusts only cited sources, makes a skeptic try to break each change, defers on conflict, and gates on a human + a critic's parsed-diff verification. **Captured as a knowledge pattern** (see Knowledge Updates → Data Quality).

---

## KEY LEARNING 2 (THE BIG ONE) — A standing "merge it" is NOT a license to apply a change that contradicts an earlier explicit fix

The user pre-authorized "merge batch 4 when done." Batch 4's audit, run mechanically, proposed reverting **Esha `EE-shah` → `AY-shah`** — i.e. re-introducing **the exact bug the user had reported on a card and that #92 had fixed earlier that same day.** The audit wasn't "wrong" by its own rules (some source supported the anglicized form); it simply had no memory of the human decision in #92.

What went right: the orchestrator **recognized the name from session history**, excluded the correction from #111, left Esha `EE-shah` with no alternate, and added an **id-based regression test (id 1197)** so any future batch that re-proposes it fails the suite. The critic then verified Esha was byte-identical to `main`.

The process lesson is high-value and general: **even verified, source-grounded, human-pre-approved automated changes must be checked against the set of known prior decisions before they are applied.** A blanket "merge it" authorizes the *mechanism*, not any specific change the mechanism happens to emit — and an automated pipeline does not know what the human decided in a prior, unrelated session. Pre-authorization must be scoped: "apply the batch *except where it contradicts a recorded decision*." The safety check that saved this was human memory; it should not depend on the same agent happening to have the prior session in context.

Concrete mitigation (recommendation below): maintain a machine-readable **decision ledger** of explicit human pronunciation calls (id + value + "do not revert" + PR ref), and have any apply step diff its proposed changes against the ledger and hard-fail on a contradiction — turning the human-memory catch into an automated gate, and turning the id-1197 regression test into the first row of that ledger.

---

## KEY LEARNING 3 — Turn corrections into data; don't discard the "wrong" value

The naive correction model is destructive: overwrite `AY-shuh` with the native form and throw the old value away. The user instead decided to **keep both** — the audit's `(current = anglicized, proposed = native)` pairs were not a before/after to be collapsed, they were *two legitimate facts about the name*. That insight became a free product feature: #110 added a `pronunciation_anglicized` column to preserve the originals (and back-filled the 11 from #98 that had been overwritten), and #113 shipped Layout B (NATIVE canonical + ANGLICIZED as "the form parents will usually hear it"). The data that looked like an error to delete was product value to surface. **Lesson:** when an audit produces (old, new) pairs and *both* values are meaningful to a user, model the correction as an enrichment (add a column / link), not a mutation.

---

## KEY LEARNING 4 — Incremental shipping over big-bang for data sweeps

The sweep landed as: schema column + batches 1–3 (#110), then batch 4 (#111), then the UI (#113) — "slowly fixing them, going into the build" rather than one 110-row mega-PR. Each PR was independently reviewable, kept the critic's parsed-diff verification tractable (exactly N rows changed, every other column byte-identical, row count 1240 throughout), and meant the Esha contradiction surfaced in an isolated batch-4 PR where it was easy to spot and exclude rather than buried in a 110-row diff. **Lesson:** sequence data-sweep applies as additive per-batch PRs; it preserves review tractability and isolates policy/contradiction calls.

---

## KEY LEARNING 5 — Recurring on-device verification blocker (environment gap)

#113's PR body recorded the visual check as `[⚠️]`: the iOS simulator repeatedly wedged onto **Expo Router's fallback screen** when deep-linking to `/name/[id]`, so a fresh screenshot of Layout B couldn't be captured. The fallback was the 4 render-branch unit tests + the fresh-context critic. This is the **same deep-link routing flakiness** noted in baby-name-picker-88 (the cold-start DB-init race was found by manual poking *because* the deep-link path is fragile). The blocker is an environment gap: there is no reliable tap/deep-link tooling installed (`idb` or equivalent) to drive the simulator to a specific name-detail route. **Lesson / recommendation:** install `idb` (or Maestro) so on-device verification of detail-route UI is reliable and scripted, rather than degrading to "tests + critic" every time a routed screen changes.

---

## KEY LEARNING 6 — `pronunciation` is now a guarded field (gap from #41 closed)

The root cause #92 named — "#41's bulk import never pronunciation-verified per name; no test coverage for the pronunciation field" — is now closed. The `seed-corrections` test fixtures assert pronunciation values directly: #98 added `PRONUNCIATION_CORRECTIONS` (11 values), #110 added native-primary + anglicized-column + NULL-guard fixtures, #111 added batch-4 native/anglicized assertions **and the id-1197 Esha regression guard**, #113 added 4 `NameDetailBody` render-branch cases. Test counts climbed 466 → 505 → 548 → 575 → 579 across the arc. The field that silently shipped wrong for the entire life of the app is now regression-guarded at both the data layer and the render layer.

---

## LOCAL REVIEW (pre-push) — across the arc

- **Fresh-context critic on every data/UI PR:** #98, #110, #111, #113 each ran a fresh-context critic returning SHIP, and in each case the critic's material contribution was **parsed-diff verification of the seed artifact** — "exactly N `pronunciation` rows changed (matching the N ids), exactly M non-null `pronunciation_anglicized` (no overlap), every other column + `family_json` byte-identical, row count 1240." This parsed-artifact verification is itself the #87/#86 lesson applied ("audit the structured artifact, not a flattened view; verify the shipped artifact"). #110 additionally flagged aggressive native-primary policy calls (the Greek mythology cluster, Nisha, Layla) in the PR body for explicit user sign-off.
- **CodeRabbit (4b):** not recorded in any of the six PR bodies → tracked null. This is the **7th–Nth occurrence of the standing 4b-skip on this project** (already flagged across #73/#80/#84/#85/#86); the dedicated 4b-skip pre-push hook remains the standing open item.
- **Adversarial review (4c):** the data PRs are pattern-replication / additive-fixture changes (the safest skip class per Process Compliance) over the `family_json` precedent; #113 is a single-component conditional-render change. No Tier-0 patterns (no `new Date`, no fire-and-forget, no color/interactive) introduced. The substantive gate on the data PRs was the critic's parsed-diff verification, which is stronger than a grep for this change class.
- **Shift-left:** no post-push review findings on any PR (solo, local-gated). The one *near-miss* (Esha re-revert) was caught **pre-apply by orchestrator session-memory**, not by a checklist — which is precisely why Learning 2 recommends promoting it to an automated ledger gate.

## STEP COMPLIANCE & TIMING

Not tracked per PR (no `Steps skipped:` / `## Step Timing` lines — the same minor drift noted across #83/#86/#88/#91). Inferred: Plan → Implement → Test (tsc / lint / jest all recorded with honest pre-existing-baseline notes: "only pre-existing `web/*` tsc errors", "the 4 known pre-existing lint warnings") → critic → Push/PR ran on each; 4b CodeRabbit and CI (repo has none) did not.

## ADVERSARIAL REVIEW EFFECTIVENESS

- **adversarialCatchRate = unmeasured** for every PR in the arc. There were **zero fixed-in-PR adversarial-checklist findings** to measure a catch rate against — the critic returned SHIP on each (its role was verification, not finding-catching), and no issue escaped to post-merge. Per the project rule, this is recorded as `unmeasured`, NOT fabricated and NOT defaulted to 1.0. (Contrast #91, where 1 in-scope finding was caught pre-push → 1.0; here there is no finding, so there is nothing to rate.)
- The **highest-value catch of the entire initiative** (the Esha re-revert) is *not* an adversarial-checklist category — it is a "contradicts-a-prior-human-decision" class that no Tier check targets. Captured below as a new knowledge entry + recommended automated gate.

## FIX-UP METRICS

- Post-merge fix rate: **0.0** across the arc — no PR fixes a prior PR in the initiative; each is a forward increment. (#110 *recovers* the 11 anglicized originals overwritten by #98, but that was the planned enrichment, not a defect fix.)
- Pre-merge iteration count: **1** per PR (healthy; single squash commit each).
- Fix-up taxonomy: all 0 (no separable fix-up commits; the Esha exclusion was a scope decision applied in the single commit, not a fix-up round).
- Legacy fix-up ratio: **0.0** (each PR is one commit).

## PLANNING QUALITY

- Descriptions: **complete** — every PR carries Summary + Root cause / How + Test plan; #98/#110/#111/#113 carry `## Local Review`; #113 carries `## Designs` (mockup link, Option B chosen, A/B/C reviewed). #110 added an explicit `⚠️ Review these before merge` policy-call section — good practice for surfacing aggressive automated changes for human sign-off.
- Scope: clean and well-sequenced — schema, data batches, and UI are separate single-concern PRs; the Esha contradiction was isolated and excluded rather than smuggled.
- Sizing: every PR well under the 600-LOC cap; the largest (#95, +298) is self-contained review tooling.

## CODE QUALITY SIGNALS

- **Good practices:** parsed-artifact diff verification by the critic (not a flattened view); additive-only fixture edits; `SELECT *` + `rowToName` carrying the new column with no premature rendering (#110 ships data, #113 ships UI — clean separation); trim-guarded equal-after-trim collapse in Layout B (#113) so empty/identical alternates don't render a duplicate row; the `family_json` precedent reused for the new column (consistent schema-evolution pattern).
- **Recurring environment issue:** the Expo Router deep-link / simulator-fallback flakiness (Learning 5) — now its 2nd+ appearance (#88, #113).

## KNOWLEDGE UPDATES

- **`process-patterns.md` → NEW "Data Quality / Audits" section:** (1) the multi-agent web-grounded + adversarially-verified + conservative-on-conflict audit harness as the reusable data-quality-at-scale pattern and the antidote to #87's flattened-view failure; (2) **the standing-"merge it" safety check** — pre-authorization scopes the mechanism, not specific emitted changes; automated applies must diff against a decision ledger of prior human calls and hard-fail on contradiction (the Esha re-revert near-miss); (3) corrections that yield meaningful (old,new) pairs should be modeled as enrichment, not mutation; (4) sequence data sweeps as additive per-batch PRs.
- **`process-patterns.md` → Review Discipline / environment:** install `idb` (or Maestro) to make Expo Router deep-link / name-detail on-device verification reliable — 2nd+ occurrence of the simulator-fallback blocker.
- **No duplicate** of the 4b-skip entry (already comprehensively tracked); this arc is noted as further recurrence in that existing entry's spirit.
- **Metrics:** appended six rows (#92, #95, #98, #110, #111, #113) to `post-mortem-metrics.json`.

## RECOMMENDATIONS (ranked)

1. **Build the decision-ledger gate (Learning 2).** A machine-readable list of explicit human pronunciation decisions (id, value, do-not-revert, PR ref); any audit-apply step diffs proposed changes against it and hard-fails on contradiction. Seed it with Esha (id 1197). This converts the highest-value catch of the initiative from human memory to automation, and generalizes to any pre-authorized automated-apply pipeline.
2. **Ship a CI gate (tsc + jest + expo lint).** Standing highest-leverage open item across #81/#83/#86/#88 and the direct enabler of the #87 shipped-wrong-data incident this initiative was, in part, cleaning up after. A data-correction initiative on a "data is the product" app especially must not be able to merge red.
3. **Install `idb`/Maestro for reliable deep-link on-device verification (Learning 5).** Stop degrading routed-screen UI checks to "tests + critic" every time the simulator wedges on Expo Router's fallback.
4. **Build the 4b-skip pre-push hook** (carried over from #73/#80/#84/#85/#86) so CodeRabbit either runs or the skip is recorded in a `Steps skipped:` line; restore `## Step Timing` to the PR template.
5. **Resolve the remaining ~70 `uncertain` names and the 725 names with no pronunciation at all** (the next data frontier #113 names) — and consider Layout C (tap-to-hear pills) once pronunciation audio exists.

---
*Generated by /post-mortem as an initiative retro. adversarialCatchRate recorded `unmeasured` for all six PRs — zero fixed-in-PR adversarial findings to rate; NOT fabricated, NOT defaulted to 1.0.*
