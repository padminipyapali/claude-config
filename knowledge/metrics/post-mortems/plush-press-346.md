# POST-MORTEM: plush-press PR #346 — Add the book style switcher (Stage 6b of Art Styles)

Branch: feat/style-switcher → main | Author: padminipyapali | ~33 min PR-to-merge (~121 min dev total)
Size: +753 -3 across 13 files, 1 squashed commit

## Local review (pre-push)
- CodeRabbit CLI: **3 findings, 3 fixed** (2 iterations) —
  1. Stability: `fetchStyles` failure silently dropped → inline error + `.catch` guard + test.
  2. Data integrity: non-string `styleId` coerced to `""` (a silent clear) → 400 on non-string/non-null + test.
  3. Data integrity: style-only update was a **blind whole-project write** → optimistic concurrency (`baseUpdatedAt` → `StaleWriteError` → 409 `conflict`, client reload + retry message, no auto-retry) + 3 tests.
- Adversarial (critic, fresh context): **0 findings** — did run the cached-async lens and traced the reload rebind window (no stale-read window; `project` goes null behind the loading gate). Valuable negative-space verification, but the blind-write class was not surfaced by the critic.
- Shift-left rate: 100% (0 post-push comments).

## The reversal — process data point (recorded on request)
On finding 3, CodeRabbit escalated the blind whole-project write to **MAJOR**. The orchestrator initially triaged it **accepted-as-documented**, then **REVERSED** and required optimistic-concurrency hardening before merge — the deciding argument: a lost concurrent art/placement update is the operator's most-burned failure class ("never lose a generated render"). This is the second consecutive PR (after #344) where an initial "accept" of a CodeRabbit data-integrity MAJOR was overturned in favor of default-to-fix. The lesson generalizes: **when a finding's blast radius includes the project's known most-burned asset class, accept-as-documented is not an available triage outcome.**
Counter-balance, also documented: the hardening pass itself merged **without a fresh CodeRabbit pass** — judgment call that it mirrors the proven whole-project PUT 409 contract byte-for-byte. Acceptable here (pattern-copy of a reviewed contract + 3 new tests + full gates), but it is a real gap in the loop; pattern-copies of reviewed code are where subtle divergences hide. Flagged, not condemned.

## Step compliance / timing
- All 9 steps run (4a folded, declared). Compliance 100%, skip assessment good.
- Plan ~20m · Implement ~30m · Tests ~15m · Gates ~6m · Critic ~5m · CodeRabbit ~15m · **Hardening pass ~25m** · Spec+PR ~5m · Total ~121m. Bottleneck: the reversal-driven hardening pass (time well spent).

## Adversarial review effectiveness
- adversarialCatchRate = **0/3 = 0.0** (all three findings from CodeRabbit). The blind-write / read-modify-write-without-concurrency-guard class is checklist-adjacent (caller safety / data integrity) — the critic traced read paths (rebind) thoroughly but not the **write** path's concurrency envelope. Suggested lens: for any new partial-update endpoint, ask "what does this clobber if a concurrent writer lands between read and save?"

## Fix-up metrics
- Post-merge fix rate: 0.0 (#347/#348 are next docket stages, not fixes to this PR).
- Pre-merge catches: 4c (CodeRabbit) 3. Iterations: 3 (critic pass → CodeRabbit fixes 1–2 → reversal/hardening for 3) — nominally high-friction, actually a quality save.
- Taxonomy: validation 1, defensive-coding 1, correctness 1.

## Planning quality
- Description complete (enablement rule verbatim from operator, byte-contract, fail-open, LOC split). Scope clean, same-day branch.

## Recommendations
1. Add the partial-update concurrency question to the critic's standing lens (write-path sibling of the cached-async read lens).
2. When triage flips to "fix" after an initial accept, always record the reversal (done here) — the flip conditions are the transferable knowledge.
3. Re-run CodeRabbit on hardening passes when they introduce a new contract; skipping is defensible only for byte-pattern copies of an already-reviewed contract, with tests.
