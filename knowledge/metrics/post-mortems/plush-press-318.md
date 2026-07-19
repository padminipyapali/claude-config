# POST-MORTEM: plush-press PR #318 — Regroup the scene editor toolbar around what its buttons do

Branch: feat/scene-toolbar → main | Author: padminipyapali | ~65.4h open (created 2026-07-17, merged 2026-07-19)
Size: +851 −243 across 11 files, 1 commit (squash-merged)

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` section; body shows no CodeRabbit run)
- Adversarial: tracked — fresh-context critic verdict CLEAN, 0 blocking findings
- Shift-left rate: n/a (no post-push issues to compare against)

## STEP COMPLIANCE
- Not tracked — PR body has no `Steps skipped:` line. Narrative evidence shows the full team flow ran (orchestrator → implementer in pre-created worktree → fresh-context critic → live browser verification), plus lint/typecheck/test/build gates.

## STEP TIMING
- Not tracked — PR body has no `## Step Timing` section.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; 0 GitHub reviews)
- Comments: 0 inline, 0 general (all review was local; solo repo, no peer review)
- Categories: all zero
- Timeline: no GitHub review events; merged ~65.4h after creation (branch sat; solo cadence, not friction)

## ADVERSARIAL REVIEW EFFECTIVENESS
- adversarialCatchRate: **unmeasured**. There were zero post-push comments and zero post-merge fixes, so there is no set of escaped issues to form a catch-rate denominator. The PR's most significant defect — the wrong Reuse-hide premise — was caught by (a) inspecting real project data, (b) the implementer flagging it unprompted, (c) reading the actual Gemini extract prompt. That is NOT an adversarial-checklist catch, so no honest catch-rate can be attributed. Marked "unmeasured" per the operator's metric-integrity rule (never fabricate a baseline).
- Covered but missed: none observed.
- Not covered (new category): "approved-mockup false-premise / UI depicting an unreachable state" — a design-artifact premise error that green tests cannot catch. Captured to process-patterns.md.

## FIX-UP METRICS
- Post-merge fix rate: 0.0% (no follow-up fix PRs at time of analysis; 0 is ideal)
- Pre-merge catch rate by step: unattributable — squash-merged to 1 commit, so intermediate fix commits (including the premise correction) are not individually visible in history.
- Pre-merge iteration count: 1 observable in history (the wrong-premise correction happened pre-merge but was squashed away; true internal iteration was ≥2 per the narrative).
- Fix-up taxonomy: all zero visible (squashed).
- Legacy fix-up ratio: 0.0% (0 fix / 1 total commit).

## PLANNING QUALITY
- Description: complete — rich Summary, "The Reuse rule, and a corrected premise" narrative, Persistence, Designs (mockups linked), Verification table, and per-test enumeration.
- Scope: clean intent (single concern: the action bar), but +1094 LOC exceeds the 600-LOC guideline. ~397 lines are the new toolbar test file; net non-test source is smaller. One squashed commit keeps history tidy.
- Branch lifetime: ~65h (solo cadence; not scope creep — one coherent commit).
- Planning checklist: entry points enumerated (picked-backdrop pages, free scenes, legacy scenes without `sourcePageId`, backward compat). No explicit Performance & Cost section — acceptable for a pure client-side UI restructure (no new API calls; Reuse's Gemini call semantics unchanged).

## CODE QUALITY SIGNALS — verified against merged origin/main
- `canReuse = hasArt && !alreadyReused` shipped (SceneCanvas.tsx:1314); the corrected (not the wrong `!freeScene && !!sceneBase`) rule is live.
- `sourcePageId` round-trips: present in Zod `SceneRefSchema` (project.ts:88, `z.string().optional()`) and re-added field-by-field in `normalizeProject` under an `isPageId` guard (project.ts:487), so legacy scenes serialize byte-identically. Persistence survives both rebuilders as claimed.
- Known limitation recorded in-code (comment at SceneCanvas.tsx:1303–1311): after re-render/tune, `sourcePageId` still matches so Reuse stays hidden even though a fresh extract would differ — provenance match, not art-hash. Accepted tradeoff, documented not hidden.
- CI: studio check SUCCESS.

## KNOWLEDGE UPDATES
- process-patterns.md: added "An APPROVED mockup can encode a false BEHAVIORAL premise…" — extends verify-premise-before-building to design artifacts; covers the unreachable-UI-state tell (Save+Reuse coexisting was the logical complement of the wrong hide-rule) and green-tests-prove-only-mockup-consistency.
- metrics/post-mortem-metrics.json + dashboard.html: appended PR #318 (adversarialCatchRate = "unmeasured").
- No plush-press repo ledger entry: nothing shipped broken (the premise was caught pre-merge), so no BUGS.md entry; the design decision is already narrated in the PR body and the cross-project learning is the durable artifact.

## RECOMMENDATIONS
1. When a hide/show/enable gate is lifted from a mockup, write one sentence stating what the gated feature does at RUNTIME and confirm it against the real prompt/handler before coding — the cheapest place to catch a false premise.
2. For any two controls a mockup shows together, check that the gating predicates actually permit that combination; an unreachable depicted state means the mockup or a predicate is wrong.
3. Consider adding the `## Step Timing` and `Steps skipped:` lines to the PR body even for team-flow PRs so compliance/timing stop reading as "not tracked."
4. Squash-merge erases per-step fix attribution; if fix-up-by-step metrics matter, capture the pre-squash iteration count in the PR body.
