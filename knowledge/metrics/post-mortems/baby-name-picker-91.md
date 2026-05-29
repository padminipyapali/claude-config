# POST-MORTEM: baby-name-picker PR #91

**Title:** Fix Compare card overflow with progressive disclosure of name meanings.
**Branch:** `fix/compare-card-progressive-disclosure` → `main`
**Author:** padminipyapali (Claude Opus 4.8 co-author)
**Merged:** 2026-05-29T05:10:40Z (squash)
**Size:** +1498 / -150 across 13 files, 1 commit (squashed)
**Time to merge:** 0.35h (~21 min, created → merged)

---

## Summary

Bug fix: data-rich Compare cards (e.g. Kai — 4 origins, 3 per-language meanings,
siblings, last name) overflowed a fixed-height `overflow:hidden`,
`justifyContent:center` container, clipping the serif name at the top and colliding
the Details pill with the bottom meaning line. Fix: progressive disclosure — origins
collapse to a dotted small-caps caption, per-language meanings collapse to one
combined line on the card, full breakdown moves to the Details screen. Parsing/grouping
extracted to a shared `src/utils/meanings.ts` (single source of truth for card + detail).

Built via orchestrator → implementer → critic. Critic (fresh context) returned
FIX-THEN-SHIP with one finding (a `.trim()` + `typeof` type guard in
`groupMeaningsByValue` so a whitespace-only meaning cannot produce a phantom group),
which was applied before push.

---

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (null) — CLI not run / not recorded in body.
- Adversarial review (Step 4c): PASS. Tier-0 automated audit = 20 pass; 3 heuristic
  flags all dispositioned as non-issues:
  1. `catch → null` is a sanctioned expected-error JSON fallback.
  2. `if (!meanings)` is an object null-check, not a string guard (real string guard
     uses `!m.trim()` + type check).
  3. `if (isTappable)` is pre-existing family-form code outside this diff.
- Critic (fresh context): FIX-THEN-SHIP → 1 finding (`.trim()`/type guard) applied.
- Shift-left: 1/1 issues caught locally (pre-push). 100%.

## STEP COMPLIANCE
- Not tracked — no `Steps skipped:` line in the PR body (predates / omitted step-compliance tracking).

## STEP TIMING
- Not tracked — no `## Step Timing` section in the PR body.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; no GitHub reviews — local-review-gated flow).
- Comments: 0 inline, 0 general (bot or human).
- Categories: all zero (no post-push comments).
- Timeline: created → merged = ~21 min. No external review phase (solo, local-gated).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: the single real issue found in the loop (whitespace-only
  string producing a phantom meaning group) IS covered by the adversarial checklist —
  item **0.9 "Truthiness guard on string input (missing .trim())"** plus the Tier-0
  automated grep, and the **Input validation at boundaries** checklist item (`typeof`
  guard before `.trim()`).
- Covered AND caught pre-push: 1/1. The critic surfaced it; the implementer's own
  report/tests did not pre-catch it. It was fixed before push. No issue escaped to merge.
- Covered but missed: none.
- Not covered (new categories): none.
- adversarialCatchRate = **1.0** — evidence-grounded (1 issue, in checklist scope,
  caught before merge), NOT hardcoded. Matches the scoring convention used for PR #85
  (1 finding, caught locally → 1.0).

## FIX-UP METRICS
- Post-merge fix rate: 0.0% — no follow-up fix PRs reference #91 or its files
  (`gh pr list --state merged --search fix` returned no PRs numbered > 91 touching these files).
- Pre-merge catch rate by step: 4a=0, 4b=0, 4c(critic)=1, 4d(adversarial)=0, post-push=0.
  (PR squashed to one commit; the lone finding was caught by the critic and folded in,
  attributed to the internal-critic review step.)
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: { validation: 1 } (the `.trim()`/type guard). All others 0.
- Legacy fix-up ratio: 0.0% (squashed single commit).

## PLANNING QUALITY
- Description: complete — Summary, Designs, What changed, Local Review,
  Performance & Cost Impact, Test plan all present.
- Scope: clean. Single concern (overflow fix via progressive disclosure). Branch
  lifetime ~21 min. No revert/redesign commits.
- PR size 1648 LOC total churn — exceeds the 600 LOC soft cap, but ~1340 of that is
  docs/mockups (3 mockup HTML files + README + PNG render) and new tests; the
  production source delta (NameCard, NameDetailBody, meanings.ts, theme.ts) is modest.
- Planning checklist: Performance & Cost section present ("None — pure synchronous
  parsing, reduces rendered nodes"). Entry points (worst-case Kai, single-origin Vesper)
  enumerated and tested.

## CODE QUALITY SIGNALS
- Recurring issues: none (single PR, single finding).
- New unrecorded patterns: none. The root-cause class (centered content in a
  fixed-height `overflow:hidden` container has no safe overflow direction) was ALREADY
  captured in `~/.claude/knowledge/react-patterns.md` line 61 during this work
  (sourced "baby-name-picker, compare-card progressive disclosure, 2026-05-28").
- Good practices observed: shared-util extraction to prevent card/detail drift (DRY,
  single source of truth); defensive parsing of malformed JSON; data-loss check
  (full breakdown verified reachable in Details + asserted by tests); 4 new test cases
  covering parse fallbacks, grouping order/dedup, whitespace skip, combined-line fallback.

## PROCESS EFFICIENCY
- Automation opportunities: the `.trim()`/type-guard finding is already grep-detectable
  via the Tier-0 automated audit (checklist item 0.9). The critic caught it, but the
  Tier-0 grep should have surfaced it first — worth confirming the automated grep ran
  against the new `meanings.ts` and didn't miss it because the guard pattern differed
  from the regex (`if (!var)` vs `if (typeof m !== "string" || !m.trim())`).
- Iteration: efficient (1 round, fixed pre-push).
- CI status: no CI checks configured on this repo (statusCheckRollup empty).

## KNOWLEDGE UPDATES
- No new entries needed. react-patterns.md line 61 already captures the overflow-clip
  root-cause pattern (added during this PR's development). adversarial-review.md already
  covers the trim/typeof finding (items 0.9 + Input validation at boundaries). No
  duplicates added.
- Metrics: appended PR #91 entry to post-mortem-metrics.json (now 322 PRs);
  dashboard.html regenerated with embedded data.

## RECOMMENDATIONS
1. **Tighten the Tier-0 whitespace-guard grep.** The critic — not the automated audit —
   caught the missing trim guard, because the code used
   `if (typeof m !== "string" || !m.trim())` originally lacked the trim portion and the
   grep regex (`if\s*\(\s*!(\w+)\s*\)`) only matches the simple `if (!x)` shape. Broaden
   the grep to flag string-derived values entering a `Map`/grouping key without a
   `.trim()`. This moves the catch from human-judgment (critic) to automation.
2. **Add `## Step Timing` and `Steps skipped:` lines to the PR body** for this project's
   PRs — both were absent here, so compliance and timing are unmeasured. Cheap to add,
   improves the metrics signal.
3. **Keep mockup/doc artifacts in scope but note the LOC split.** The 1648-LOC total is
   dominated by mockups/tests, not production code; the body could state the
   production-vs-docs LOC split so the size cap isn't misread as a scope-creep signal.

---
*Generated by /post-mortem. adversarialCatchRate computed from evidence (1/1 issues in
checklist scope caught pre-push), not hardcoded.*
