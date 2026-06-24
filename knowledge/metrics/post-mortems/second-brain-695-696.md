# POST-MORTEM: second-brain PRs #695 + #696 — calendar agenda-display feature (#694)

Analyzed as a combined 2-PR stack (split per the 600-LOC rule at a clean infra-vs-layer boundary).
Branch: feat/calendar-cal-metadata → main (#695); feat/calendar-agenda-display → main (#696)
Author: padminipyapali | self-merged solo dev, no peer review (expected)
Merged: 2026-06-24 (UTC)

## Sizes
- #695 (infra): +543 / -13, 12 files. Server suite 1916 pass.
- #696 (layer): +1144 / -13, 4 files, 2 commits. Server suite 1937 pass.
- Combined feature ~742 production + ~675 test LOC (~1417), over the 600 cap → SPLIT.

## Trigger
User testing: wanted the "what events tomorrow?" reply more readable and showing which
calendar each event is on. Via design Q&A the user chose a chronological + color-dot layout
with calendar names auto-resolved from Google.

## Combined loop
implementer → full-feature fresh-context critic → fix → critic re-verify (PASS) →
per-branch adversarial gates (both PASS) → stacked ship (merge PR1, rebase PR2 onto squashed
main, re-cert marker, gate, merge PR2). Rebase of #696 was conflict-free (consume-only seam).

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (light-lane per the small-PR review memory; team + adversarial gate run).
- Adversarial / fresh-context critic: #695 → 0 findings (clean). #696 → 2 SHOULD-FIX, both fixed.
- No GitHub review comments on either PR (Vercel status only).

## STEP COMPLIANCE
- Both PRs: steps 1, 2a, 2b, 3, 4a-4d, 5 run. Compliance 100%. Skip assessment: good.

## REVIEW FRICTION (post-push)
- Review rounds: 1 each. 0 inline, 0 general human comments. preMergeIterationCount = 1.
- Timeline: #695 created→merged 2.70h; #696 created→merged 0.25h.

## ADVERSARIAL REVIEW EFFECTIVENESS — adversarialCatchRate = 1.0 (MEASURED)
Computed from evidence, NOT hardcoded: the fresh-context critic caught 2 real SHOULD-FIX in the
agenda layer pre-merge that would otherwise have shipped, vs 0 post-merge escapes → 2/2 = 1.0.
The two caught issues (#696):
1. **correctness/validation** — out-of-order/duplicate LLM `days` mis-rendered the sequential
   day-blocks (the deterministic formatter assumed ascending + unique input). Fixed by sort +
   dedupe of in-range days before render (zero-padded YYYY-MM-DD sorts chronologically).
2. **test-quality** — module header claimed TZ-safety but the suite lacked far-east (UTC+14
   Kiritimati) and DST spring-forward/fall-back agenda tests. Added.
Both fixed in commit 2 (f2cacc0); critic re-verified PASS. PR1 was critic-clean.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (0 post-merge fix commits/PRs across the stack — ideal).
- Pre-merge catch by step: #696 4b (critic) = 2; all others 0.
- Pre-merge iteration count: 1 per PR (single critic round + re-verify).
- Fix-up taxonomy (#696): validation 1, correctness 1, test-quality 1.
- Legacy fix-up ratio: #695 0.0 (0/1); #696 0.5 (1 fix commit / 2).

## PLANNING QUALITY
Complete on both. Deterministic-formatter premise check (process-patterns line 70) applied at
plan time; stacked-PR split boundary declared up front. PR bodies enumerate scope + tests.

## RECURRING-THEME ANALYSIS (the two requested sub-questions)

(a) **Deterministic-formatter streak — premise check FIRED.** #694 is the FOURTH instance of the
second-brain "LLM doing computation it shouldn't" root cause (#681 date-math → #683 reintroduced
far-east off-by-one → #685 interval-math → #694 output FORMATTING) and the FIRST caught at DESIGN
time by the line-70 premise check rather than in post-merge manual testing. The LLM is scoped to
classify + pick day(s); code renders the whole layout. Result: 0 LLM-formatting bugs — the class
that bit the prior three in manual testing. This is evidence the line-70 recommendation LANDED
(reactive fix → proactive plan constraint). NEW relocation lesson: moving formatting into code
doesn't eliminate LLM-input risk, it RELOCATES it to "the model's extracted params violate the
renderer's unstated ordering/uniqueness assumptions" — hence finding #1 above. Pair the
deterministic-formatter premise check with "validate/normalize (sort/dedupe/bound/clamp) every
LLM-supplied param at the code boundary before the pure renderer consumes it."

(b) **Stacked split-at-clean-boundary + rebase-after-squash.** The split was cut at a consume-only
seam: #695 ships an exported capability (metadata resolver, dots util, sourceCalendarId plumbing)
with its own tests + a standalone user-visible win; #696 imports those exports without re-adding
them. So #696's post-squash `rebase --onto` was conflict-FREE — a clean contrast to #690/#693
(yesterday), whose add/add conflict came from both PRs adding the same files. Both stacks still
needed the marker re-cert after rebase (SHAs rewritten). The infra half carrying a standalone win
kept it from being a dead scaffold PR.

## KNOWLEDGE UPDATES
- process-patterns.md line 70 (LLM-computation streak): strengthened to FOUR-strike +
  premise-check-FIRED confirmation + the input-risk relocation lesson.
- process-patterns.md PR-Sizing: new "worked example of CHOOSING the split over the >600 exception
  — infra-then-layer / consume-only seam" entry.
- process-patterns.md rebase-after-squash (line 264): strengthened with the clean-boundary
  (conflict-free) contrast vs #690/#693's add/add.
- llm-integration.md (after delegate-computation): new "delegate output FORMATTING too + validate
  LLM params at the renderer boundary" entry.
- Checked for duplication first: the rebase mechanics (line 264) and three-strike streak (line 70)
  already existed; only incremental, non-duplicative context was added.

## RECOMMENDATIONS
1. The deterministic-formatter premise check is now demonstrably load-bearing AND proactive across
   4 instances — treat it as a standing plan-template line for any LLM-touching answer feature.
2. Always pair the premise check with explicit LLM-param normalization (sort/dedupe/bound/clamp)
   at the code↔renderer boundary; add a deliberately-malformed-params test. This is the new
   failure surface once computation/formatting move into code.
3. Prefer the consume-only split seam for >600-LOC features lacking a totality-forcing type — it
   makes the post-squash rebase conflict-free by construction.
