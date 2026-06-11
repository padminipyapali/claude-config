# POST-MORTEM: plush-press PR #21 — Add Rami, the baby brother: locked hero sheet, text bible, and proven prompt.

Branch: feat/rami-character → main | Author: padminipyapali | open→merge ~1 min
Size: +100 -0 across 3 files (hero PNG, bible markdown, proven prompt), 1 commit
Merged: 2026-06-11T03:43:53Z (squash 3787dd9)

## Context

Fourth character through the photos-first workflow (#17), orchestrator-authored content lane. Notable as a **first-try Gemini lock** — zero rejected candidates — and as the first BABY variant of the human hero recipe: age-down guard, baby-valid pose whitelist (lying / tummy-time / side / propped) replacing the standing turnaround, reduced 6-expression set. The bible adds a "Pose rules" section and names his drift mode (age-UP drift: toddler proportions, teeth, unsupported sitting → instant reject).

## LOCAL REVIEW (pre-push)

- CodeRabbit: skipped (4b) — content-only.
- Adversarial: critic-style self-verification, 0 findings (YAML parses, paths/naming match convention, look[] mirrors prose, full-res 1664×2566 hero from Downloads).
- Shift-left rate: n/a (zero findings anywhere).

## STEP COMPLIANCE

- Steps run: 1, 2a, 2b, 4c, 5 (5/9)
- Steps skipped: 3, 4a, 4b (stated in PR body: "content-only; self-verification per the orchestrator-authored-content lane") + 4d (repo has no CI)
- Compliance rate: 56%
- Skip assessment: neutral — no post-push review data; measured at merge (PR is HEAD of main).

## STEP TIMING

Not tracked. Open→merge ~1 min (merged back-to-back with #20); authoring happened in-session pre-push.

## REVIEW FRICTION (post-push)

- Review rounds: 1 (0 CHANGES_REQUESTED; no reviews)
- Comments: 0 inline, 0 general
- Timeline: created 03:42:44 → merged 03:43:53 (0.02h). Self-merge, no peer review — expected under the solo orchestrator flow; user approved merge.

## ADVERSARIAL REVIEW EFFECTIVENESS

- Pre-push catch potential: n/a (zero post-push findings = no denominator). adversarialCatchRate recorded as "unmeasured" per the metric-integrity rule.
- Covered but missed: same collection-level gap as #20 — `character bible/README.md` roster does not list Rami (stale since PR #3). Captured once in the #20 report; counted as one systemic finding across the pair.
- Not covered: n/a beyond the #20 findings. Rami's own scale anchor is exemplary ("smallest — roughly 0.6× Mira... to be confirmed when the cast lineup regenerates") — it avoids superlative collision AND flags its own provisional status.

## FIX-UP METRICS

- Post-merge fix rate: 0% (0 post-merge fix commits; measured at merge — PR is HEAD of main)
- Pre-merge catch by step: 4a 0 | 4b 0 | 4c 0 | 4d 0 | post-push 0
- Pre-merge iteration count: 1 (healthy)
- Fix-up taxonomy: all zero. Legacy fix-up ratio: 0% (0 fix / 1 commit)

## PLANNING QUALITY

- Description: complete (Summary + Review provenance + Test plan + Steps-skipped line). Above-par: it names the drift mode, the structural novelty (first BABY recipe variant), and self-declares the seed-photo debt.
- Scope: clean — single concern, 3 files.
- Branch lifetime: ~1 min (squash-merged immediately after #20)
- Planning checklist: entry-point enumeration / perf-cost n/a for content-only

## CODE QUALITY SIGNALS

- Recurring issues: seed-photo backfill debt recurs — `inspiration_photos/` intentionally empty (seeds were attached in Gemini directly), flagged in the bible prose for backfill. Same gap #18 had and #20 paid down. Prose flags evaporate; should be an issue.
- New patterns captured: **knowledge compounding produced the first-try lock.** The #18 lesson (kinship/age words steer rendered age; image models drift toward the category prototype) was INVERTED proactively for the baby: explicit "true 4-month-old proportions" anchor, NO-teeth rule, positive pose whitelist, named instant-reject criteria — all encoded in the prompt BEFORE generation rather than discovered through rejects. Evidence that a per-model drift-mode catalog pays off measurably (4 characters: Rambabu needed age-cue rewrites; Rami locked first try).

## PROCESS EFFICIENCY

- Automation opportunities: same as #20 (roster-sync lint, duplicate-superlative grep). Additionally: an "empty required directory" check could flag `inspiration_photos/` absence/emptiness and demand either files or a tracked issue reference.
- Iteration: maximally efficient (1 round, 0 findings, 0 rejects at generation time, 0 post-merge fixes).
- CI status: no checks (repo has no CI).

## KNOWLEDGE UPDATES

- `~/.claude/knowledge/llm-integration.md` — generalized the #18 age-cue entry: age drift pulls toward the category prototype in both directions; pre-loading inverse guards (age anchor, NO-teeth, pose whitelist, instant-reject criteria) produced a first-try lock. <!-- plush-press #21 -->
- `~/.claude/knowledge/process-patterns.md` — covered by the #20-pair entry (additive blindness; backfill flags → issues).
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` + `dashboard.html` regenerated.

## RECOMMENDATIONS

1. File an issue for Rami's seed-photo backfill (the bible's prose flag is the third occurrence of this debt class; #18 showed prose flags only get paid when a later PR happens to touch the area).
2. When the cast lineup regenerates, confirm Rami's provisional 0.6× scale anchor and update the bible — the anchor self-documents this TODO; make sure it doesn't outlive the regeneration.
3. Treat the BABY recipe variant in `prompts/proven/rami-hero-original.md` as a reusable template: any future infant/toddler character should start from it (age-down guard + pose whitelist), not from the adult recipe.
4. Shared with #20: roster README update + issue #19 resolution in one docs PR.
