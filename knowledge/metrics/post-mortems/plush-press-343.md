# POST-MORTEM: plush-press PR #343 — The base dropdown is the character; the source look pins the render style.

Branch: `fix/style-follows-source-look` → `main` | Author: padminipyapali | created→merged ~6.4 min (2026-07-20T18:55:11Z → 19:01:32Z)
Size: +158 -16 across 4 files, 1 commit (self-merged; `studio` CI check SUCCESS)

## What shipped
The same-day follow-up to #342. #342 shipped the "Start from look" seed picker but left the render-style pin on the BASE; on first real use, picking botanical Mira as the source still rendered watercolor. #343 re-homes the render-style pin entirely onto the selected source look, per the operator's principle supplied mid-fix: **the base dropdown represents the character, not the style — style lives on looks.**
- Base dropdown labels drop the `· <style>` suffix (just "Mira (1 plate)").
- A styled source look pins AND locks the render style to itself (seed renders and saves in that style — verified through whiteRef/buildPrompt/saveLook). Default source pins to the character's default look's style; a built-in whose default carries no style leaves the selector free.
- Lock hint: "This look pins its render style." Untouched sessions byte-identical; `LookBase.style` now vestigial for consumers (cleanup earmarked for the queued useCreateLook decomposition).

Files: `CreateLook.tsx` (+5/-2), `useCreateLook.ts` (+40/-14), plus `CreateLook.test.tsx` (+30) and `useCreateLook.test.ts` (+83). 2 of 4 files are tests; +113 test LOC vs +45 source LOC.

## Process context — slim lane, data point #2
Second plush-press PR under the operator's formally slimmed flow (see #342): single implementer + orchestrator eyeballing the diff (no separate critic/adversarial agent); merge gate = vitest 2613/2613 + typecheck + lint locally, build via CI. Recorded in the PR body ("Slim process (single implementer + orchestrator diff review)"). One pre-push orchestrator-eyeball catch (base-label `· <style>` suffix initially still present, inconsistent with the new "base = character" model) resolved via AMEND before push — the single reviewer doing exactly the cross-file-consistency job it exists for.

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (dropped under slim lane) → null
- Adversarial: not tracked (folded into orchestrator diff review) → null
- Shift-left rate: n/a — the shift-left framework doesn't apply to the slim lane

## STEP COMPLIANCE
- Steps run (new lane): 1 (plan/eyeball), 2a (implement), 3 (test+typecheck+lint), 5 (push/PR)
- Steps folded/dropped by design: 2b, 4a (simplify), 4b (CodeRabbit), 4c (adversarial)
- Compliance vs the NEW lane: compliant (1.0). Grading against the legacy 9-step flow would falsely read ~4/9.
- Skip assessment: good — 0 post-push comments, 0 post-merge fix PRs, strong test coverage, and the one internal catch was resolved pre-push.

## STEP TIMING
Not tracked (no `## Step Timing` section). Total wall-clock created→merged ~6.4 min.

## REVIEW FRICTION (post-push)
- Review rounds: 0 CHANGES_REQUESTED (self-merged, no peer review — expected under slim lane)
- Comments: 0 inline, 0 general
- Categories: all zero
- Timeline: created → merge ~6.4 min total; no reviews in between

## ADVERSARIAL REVIEW EFFECTIVENESS
- No adversarial gate ran and 0 defects surfaced through any gate → `adversarialCatchRate: unmeasured` (0/0 denominator).
- Covered but missed: none observable.
- Not covered: n/a.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 — #344 (merged ~1 min later) is a different feature area (book-style coherence), not a fix to #343.
- Pre-merge catch rate by step: all 0 fix COMMITS (single feature commit). The one internal catch (base-label suffix) was amended, not committed separately — a 4b-class cross-file-consistency catch by the orchestrator eyeball, not commit-counted.
- Pre-merge iteration count: 1 (one orchestrator diff-review catch resolved via amend before push).
- Fix-up taxonomy: all 0 (no fix commits).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## PLANNING QUALITY
- Description: partial — strong Summary enumerating all three source cases (styled source pins+locks; default source pins to default look's style; built-in-with-no-style leaves selector free) plus a Gates line with test/typecheck/lint evidence. No explicit Test Plan header and no Performance & Cost section.
- Scope: clean — single concept (re-home the style pin from base to source look), 174 LOC, 1 commit, no scope creep, no redesign commits.
- Branch lifetime: ~6 min.
- Planning checklist: entry points effectively enumerated in prose (the three source-selection cases + edit-mode/untouched-session byte-identity); no Performance/Cost section.

## CODE QUALITY SIGNALS
- Recurring issues: none.
- New unrecorded patterns at code level: none. The load-bearing signal is process-level (flagged-gap → same-day rework; slim-lane data point #2), captured in process-patterns.md.

## PROCESS EFFICIENCY
- Automation opportunities: unchanged from #342 — CodeRabbit remains the cheapest re-introducible gate for the cross-file/library-idiom class if a LOC/complexity threshold is later defined. This PR was well below any reasonable threshold.
- Iteration: efficient (single pass + one pre-push amend, no post-push friction).
- CI status: `studio` check SUCCESS.

## KNOWLEDGE UPDATES
- process-patterns.md → Follow-Up Discipline: NEW entry — "a flagged-and-accepted design tension converts to same-day rework at high probability when the operator is the imminent next user, and that rework is a product-iteration loop, NOT a review-gate escape (does not count against adversarialCatchRate or the slim lane)." Includes the two reusable rules (resolve-before-merge when the flagged axis touches the operator's next workflow; a same-day reversal of a knowingly-accepted decision is not a quality escape) and the tell that separates it from a real escape (the reversed behavior was named as known/deferred in the prior PR's body).
- process-patterns.md → Process Compliance: STRENGTHENED the #342 slim-lane entry with slim-lane data point #2 — #343 validates the "watch for the first post-merge escape" concern in the right direction (it's an accepted-gap follow-up, not an escape), shows the orchestrator-eyeball catching the base-label suffix via amend, and updates the count to two clean slim-lane PRs (still not proof; the trigger remains the first genuine unflagged escape).

## RECOMMENDATIONS (ranked)
1. When an implementer flags a design tension at ship time AND the flagged axis is the operator's very next workflow, resolve it before merge rather than accept-and-ship — first real use will find it within hours (as it did here), and the pre-merge fix is cheaper than a second PR.
2. Keep recording the slim-process banner in every PR body (as #343 did) — it remains the only signal distinguishing deliberate lane calibration from discipline drift.
3. Hold the standing slim-lane trigger: re-introduce CodeRabbit above a LOC/complexity threshold on the first genuine post-merge ESCAPE (an unflagged wrong behavior). Neither #342 nor #343 is one; two clean data points is not proof the lane holds on a logic-heavy or multi-surface diff.
4. Minor: add a Test Plan header (and ideally a `## Step Timing` section) to PR bodies even under the slim lane, so coverage and timing are legible to the metric pipeline without reading the diff.
