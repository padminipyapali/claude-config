# POST-MORTEM: plush-press PR #351 — Fix the style switcher select showing Default while options load.

Branch: feat/switcher-value-sync → main | Author: padminipyapali | 5 min created→merged
Size: +63 -4 across 3 files, 1 commit (8 code LOC; the rest is the regression test + BUGS.md entry)
Bug ledger: BUG-015 (controlled-`<select>` value-before-options race, read-side of the cached-async-state family)

## LOCAL REVIEW (pre-push)

- CodeRabbit: SKIPPED by agreement (small-change fast path — first ever use).
- Adversarial critic: SKIPPED by agreement (same fast path).
- Kept: root-cause analysis written to BUGS.md, regression test (mount pinned + unresolved
  `fetchStyles` → `select.value` equals the pin, never ""; styles resolve → named option takes over,
  temp option gone), all four gates (typecheck 0 / lint 0 / full vitest green / build 0).
- Shift-left rate: n/a — zero findings anywhere (no reviewers ran, none found post-push either).

## STEP COMPLIANCE

- Steps run: 1, 2a, 3, 4d(CI), 5 (5/9) — compliance 56%.
- Steps skipped: 2b, 4a (simplify), 4b (CodeRabbit), 4c (adversarial) — reason: pre-authorized
  small-change fast path (≤10 code LOC, display-only, root-caused, tested).
- **Skip assessment: GOOD.** Outcome evidence: 0 post-push review findings, 0 post-merge fix
  commits/PRs (checked all subsequent merges — #352 fixes an unrelated pre-existing bug, #353 is
  unrelated wide-scenes work; nothing later touches StyleSwitcher), CI green first try, merged in
  5 minutes. Every skipped step had nothing to catch.

## STEP TIMING

Not tracked (no Step Timing section). Wall clock branch→merge ≈ 10 min.

## REVIEW FRICTION (post-push)

- Review rounds: 1 (self-merge, no GitHub reviews, no comments — solo workflow norm).
- Categories: all zero.
- Timeline: created 22:10 → merged 22:15 (0.086 h).

## ADVERSARIAL REVIEW EFFECTIVENESS

- adversarialCatchRate: **unmeasured** — no denominator. Zero issues surfaced at any stage, and the
  adversarial step was deliberately skipped, so there is no evidence of either a catch or a miss.
  Per the metric-integrity rule this is recorded as "unmeasured", not 0 or 1.
- Fast-path justification assessment (the explicit question for this PR): **justified by outcome.**
  The load-bearing eligibility criteria were all present: tiny diff, display-only blast radius
  (on-disk state was already correct — the badge and PATCH were right), root cause understood and
  ledgered (not a symptomatic patch), fix carries its own regression test, mechanical gates intact.
  One clean first use is evidence, not proof — keep assessing per use.

## FIX-UP METRICS

- Post-merge fix rate: 0% (0 post-merge fix commits).
- Pre-merge catch by step: all 0 (no findings existed). Post-push: 0.
- Pre-merge iteration count: 1 (healthy). Fix-up taxonomy: all zero. Legacy fix-up ratio: 0% (0/1).

## PLANNING QUALITY

- Description: complete (What / Root cause / Fix / Local Review with test + gates).
- Scope: clean — single concern, 5-minute branch lifetime, no redesign indicators.

## CODE QUALITY SIGNALS

- The value-before-options race is a genuinely new UI class for the knowledge base: a controlled
  `<select value=X>` is only correct if an `<option value=X>` renders on the SAME render; React's
  controlled-select optimization won't re-sync when options arrive with an unchanged value. Lesson
  captured in BUGS.md BUG-015 (repo ledger) — the right home; not duplicated into global files.

## PROCESS EFFICIENCY

- Automation opportunities: none — the bug class needs a mounted-DOM assertion, which the new
  regression test now provides.
- Iteration: efficient. CI: passed.

## KNOWLEDGE UPDATES

- `process-patterns.md`: new entry — small-change fast path first use, eligibility criteria, and
  outcome validation (skip assessed GOOD).
- Metrics JSON + dashboard regenerated.

## RECOMMENDATIONS

1. Keep the fast path gated on ALL five criteria (tiny diff, display-only, root-caused + ledgered,
   test-carrying, gates green) — the root-cause writeup + test are the substitutes for the critic.
2. Continue per-use skip assessment in post-mortems; if a fast-path PR ever produces a post-merge
   fix, tighten or retire the path.
