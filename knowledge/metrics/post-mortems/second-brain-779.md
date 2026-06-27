# POST-MORTEM: second-brain PR #779 — feat(reference): REFERENCE_LOOKUP intent for household master-sheet lookups.

Branch: `feat/reference-lookup` → `main` | Author: padminipyapali | Merged 2026-06-27T07:12:52Z (squash → main as f49a43c)
Size: +766 −42 across 12 files, 4 commits | Closes #776

## Scope

New `REFERENCE_LOOKUP` message intent so the bot answers household-reference questions from the master Google Sheet (read service shipped in #772): "who's Mira's doctor?", "give me the nanny list", "what's Rami's schedule?". LLM-grounded, mirroring `CALENDAR_QUERY` — a thin handler + a `resolveReferenceLookup` resolver that loads small cached reference data, grounds Claude on it as delimited/escaped data (prompt-injection-safe), and answers in natural language.

Also re-pointed the household schedule tabs to the real per-child live tabs: `getRamiSchedule()` → new `Rami's Daily Schedule` tab (apostrophe-escaped A1 range `'Rami''s Daily Schedule'!A:C`), dropped the defunct school tab from `TAB_RANGES`. Fixed a real schedule-routing ambiguity: "what's the schedule?" routes to `REFERENCE_LOOKUP` only when a household qualifier is present (child name / "the kids" / a routine word); a bare "what's the schedule?" stays `CALENDAR_QUERY`.

## Local review (pre-push) — the only gate (self-merged, 0 GitHub reviews)

- **Fresh-context adversarial critic:** SHIP. 2 nits, both fixed. Verified union-member completeness, sibling sweep, prompt-injection delimited+escaped, never-throws on every path.
- **CodeRabbit CLI:** 5 findings — 4 applied, 1 rejected with rationale.
  - Applied (a) MAJOR classifier-routing collision (REFERENCE_LOOKUP examples stealing "what's the schedule?" traffic from CALENDAR_QUERY) → correctness.
  - Applied (b) test mock hoist → test-quality.
  - Applied (c) processor-level `disablePreview` regression test → test-quality.
  - Applied (d) potty continuation-merge correctness bug (potty notes dropped on schedule continuation rows) → correctness.
  - Rejected (correctly): CodeRabbit misread JSDoc tab titles vs internal enum keys (JSDoc names the real live tab titles, not the enum keys).
- **Shift-left:** 100% — all 6 real findings caught and fixed locally before push; 0 post-merge escapes.

## Validate-first (against live sheet + real models)

- Real-sheet getter probe: Rami 6 rows, Mira 10, doctors 3, hired nannies 3 (apostrophe-escaped range proven against the live sheet).
- Real-Sonnet resolver probe: all sample questions answered correctly, incl. the Mira default for "the kids' schedule".
- Real classifier routing probe: 7/7 — bare schedule → CALENDAR_QUERY; child-qualified → REFERENCE_LOOKUP.

## Two latent bugs fixed (BUG-038 in docs/BUGS.md)

1. `disablePreview` silently dropped when flattening the handler result to `ProcessResult` at `message-processor.ts:377` — affected CALENDAR_QUERY's `disablePreview: true` since #705 (never reached Telegram). One-line pass-through fix + processor-level regression test.
2. Potty notes dropped on schedule continuation rows (blank-Time rows appended activities/food-naps to the prior row but dropped Potty). Now merged, with a test.

Sibling `media` drop on the same flatten line is dormant (no producer) — tracked in #778 (OPEN).

## Step compliance

- Steps run: 1 (plan), 2 (implement), 3 (test — build/lint/test green: server 2488 / web 337), 4b (CodeRabbit), 4c (adversarial critic), 5 (push+PR).
- Step 4a (`/simplify`) not separately recorded; the critic + CodeRabbit served as the review gate. Compliance ≈ 8/9.
- Skip assessment: **good** — no post-merge issues; the substituted gates (critic + CodeRabbit + real-model probes) caught everything.

## Review friction (post-push)

- Review rounds: 1 (no CHANGES_REQUESTED — self-merged 2m13s after PR open; all iteration happened pre-push on the branch).
- Comments: 0 substantive (1 general comment from `vercel` bot, excluded). 0 inline.
- Self-merge: mergedBy == author, 0 peer reviews — no peer review, consistent with the solo-dev local-review-as-gate model.
- Timeline: PR open → merge 0.04h. Branch lifetime (first commit → merge) ~0.47h (~28 min).

## Fix-up metrics

- **Post-merge fix rate: 0.0** — #779 is the most recent merged PR; no follow-up fix PR touches these files. (Sibling media-drop pre-tracked in #778, not a regression introduced here.) 0% is ideal.
- **Pre-merge catch rate by step:** 4c/CodeRabbit = 4 fixes (classifier routing, mock hoist, processor regression test, potty merge); 4d/adversarial = 2 fixes (the 2 critic nits); post-push = 0. All fixes caught pre-merge.
- **Pre-merge iteration count: 1** — healthy. One review-fix pass folded both gates' findings into 2 "address review" commits.
- **Fix-up taxonomy:** correctness 2 (classifier routing, potty merge), test-quality 2 (mock hoist, processor regression test). The 4th commit is docs (BUG-038), excluded from fix metrics.
- **Legacy fix-up ratio:** 0.5 (2 fix / 4 total commits — inflated by the small commit count; the docs commit is not a code fix).

## adversarialCatchRate: 1.0 (measured, not null)

A fresh-context critic AND CodeRabbit AND real-model probes all ran. 6 real findings (2 critic + 4 CodeRabbit) all fixed pre-merge; 0 known post-merge escapes. The 1 rejected CodeRabbit finding was a genuine misread (correctly rationalized), so it is not a missed issue. This is honestly measured — distinct from #772, where a probe (not a critic) was the gate and the rate was recorded null/unmeasured.

## Planning quality

- Description: **complete** — What & why, schedule-routing rationale, tab-correctness, latent-bug section, validation (validate-first matrix), testing, review. Closes #776.
- Scope: clean. Branch lifetime ~28 min, 808 LOC changed, all commits on-theme (1 feature + 2 review-fix + 1 docs). No revert/redesign signals.
- Issue-first rule honored (Closes #776). Performance/cost: reference data is small and cached, resolver mirrors the existing CALENDAR_QUERY cost profile.

## Knowledge updates

- `process-patterns.md` → Critic Blind Spots: added two entries — (1) a SHIP critic verifies a new intent's internal structure but is structurally blind to whether it steals routing traffic from a shipped sibling; that gap belongs to a real-model routing probe + CodeRabbit (routing cousin of the #772 probe-vs-critic lesson). (2) The post-critic CodeRabbit pass is necessary-not-redundant — it caught the load-bearing MAJOR finding here after a clean critic SHIP.
- `typescript-patterns.md:156` (silent field-drop on result flattening) and `llm-integration.md:53` (new-intent utterances stealing traffic — validate routing against the real model) were already captured by the critic during the PR; referenced, not duplicated.
- Metrics JSON appended (PR 415) + dashboard.html regenerated.

## Recommendations (ranked)

1. **Make "shared-classifier addition" an explicit critic-prompt premise.** Whenever a PR adds an intent/tool/route to a prompt that already serves siblings, the critic must ask "could any new example phrasing already belong to a shipped sibling?" and, if it can't answer from code alone, require a real-model routing probe as the gate rather than treating structural cleanliness as SHIP. (Captured.)
2. **Keep the post-critic CodeRabbit pass for LLM-routing/external-data PRs.** It earned its place here by catching the MAJOR routing collision past a clean critic SHIP — evidence the second gate is not redundant for this PR class.
3. **Promote the flatten-result field-drop check to a grep-resistant review item.** The `disablePreview` drop survived from #705 to #779 because manual field-by-field re-assembly of an optional-field result type compiles cleanly; the durable fix (spread instead of re-list) is in `typescript-patterns.md` — apply it at the `message-processor.ts` flatten site and audit `media` (#778) the same way.
