# POST-MORTEM: second-brain PR #874 — Generic reference lookup + classifier routing (PR-B2, closes #860)

Branch: `feat/source-generic-lookup` → `main` | Author: padminipyapali | created→merged in ~22s (self-squash of a fully-locally-reviewed, rebased-on-#873 branch)
Size: +934 −61 across 12 files, 3 commits (1 feature + 2 pre-push fix commits)

## LOCAL REVIEW (pre-push)
- CodeRabbit: 9 findings / 3 fixed pre-merge, across 4 attempts (3 timed out server-side, the 4th completed). Of the 9: 3 fixed, 1 refuted (a `vi.hoisted` claim contradicted by the green suites), 4 residual triaged as non-blocking and filed as issue #875 (column misalignment + caps + channel capability gate) with a fix branch in progress.
- Adversarial (fresh-context critic): 4 findings / 4 fixed — approve-with-concerns across three cycles (initial review, critic fixes, CodeRabbit-finding fixes). Concerns: negative-cache TTL on transient errors, source-agnostic empty-state copy, MAX-2-sources cap test, classifier-line name/description length capping.
- Shift-left: all issues surfaced pre-merge; 0 user-caught escapes. Caveat: 4 CodeRabbit findings were caught-and-DEFERRED to #875 rather than fixed inline — pre-merge FIX rate on non-refuted CodeRabbit findings was 3/8 (~38%).

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (9/9)
- Steps skipped: none — CodeRabbit (4b) completed on the 4th attempt after 3 timeouts.
- Compliance rate: 100%
- Skip assessment: neutral (nothing skipped; the deferral was a triage decision, not a skipped gate).

## STEP TIMING
Not tracked (no `## Step Timing` section in PR body).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; solo self-merge, all review pre-push).
- Comments: 0 inline, 0 general human (1 Vercel bot comment excluded).
- Timeline: created → merged ≈ 22s (branch reviewed + rebased on #873 before PR creation).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: 100% — every issue was surfaced before merge.
- Covered but missed: none escaped to users. But note the caught-and-deferred gap below.
- Not covered (new categories): none new for this PR (the trigger-gate/save-on-decline item added from #873 already covers the connect-flow class).

## FIX-UP METRICS
- Post-merge fix rate: 0% (0 merged post-merge fix PRs; #875 is OPEN with a fix branch in progress — deferred findings, not user-caught escapes).
- Pre-merge catch rate by step: 4c (CodeRabbit) 1 fix (redact googleapis errors + short-cache) | 4d (adversarial/critic) 1 fix (source-agnostic copy + negative-cache TTL) | 4a/4b/postPush 0.
- Pre-merge iteration count: 2 (initial review + critic fixes, then a CodeRabbit-finding fix round — normal for a mid-size PR).
- Fix-up taxonomy: defensive-coding 2 (both fix commits centered on error-handling resilience: negative-cache TTL to avoid black-holing a source on a transient failure, plus log-token redaction and failed-read short-cache).
- Legacy fix-up ratio: 66.7% (2 fix / 3 total commits — both pre-push, not escapes).

## PLANNING QUALITY
- Description: complete (Summary, Review, Tests, Deploy note, Performance & Cost Impact).
- Scope: clean — the planned PR-B2 completing #860; route-then-retrieve cost design honored (at most 2 cached grid reads per answer, one capped classifier line per source, flat cost as sources grow).
- Branch lifetime: short (solo flow), rebased on #873's squash-merge and verified byte-identical to the reviewed tree.
- Planning checklist: covered — entry points and empty-registry byte-identity enumerated; Performance & Cost section present with per-message/per-answer/connect-time cost breakdown.

## CODE QUALITY SIGNALS
- Recurring issue across the stack: CodeRabbit CLI server-side timeout recurred on BOTH #873 (3/3 timed out) and #874 (3/4 timed out) — same failure class as plush-press #23. On #874 the one completed run produced enough findings (9) that 4 were deferred to an issue.
- New patterns captured this stack: shippable-unit floor and the trigger-gate/save-on-decline checklist item (both from #873).

## PROCESS EFFICIENCY
- Automation opportunities: the CodeRabbit CLI timeout is now a reliable recurrence on this repo's larger PRs — the `timeout 600` wrapper caps the wait, and the critic + adversarial checklist is the working substitute. When CodeRabbit finally completes late, its finding volume can exceed same-session fix capacity → triage-and-defer to an issue.
- Iteration: normal (2 rounds).
- CI status: all passed (Vercel preview success).

## KNOWLEDGE UPDATES
- No new knowledge entry unique to #874 (the stack's lessons were captured under #873). Metrics appended; dashboard regenerated (448 PRs embedded).

## RECOMMENDATIONS
1. Follow up on #875 promptly — its "column misalignment" finding could be a real grid-read/row-alignment correctness bug in the generic reader; confirm severity before it lingers. Caught-and-deferred is acceptable only if the deferred items are verified non-blocking.
2. When CodeRabbit completes late (after multiple timeouts) on a large PR and returns many findings, budget explicit fix time or split the fixes into a fast follow-up PR rather than merging with a large deferred set — 4/8 non-refuted findings deferred is at the upper edge of acceptable.
3. Keep the `timeout 600` wrapper on the CodeRabbit CLI standard for this repo; treat 3-of-4 timeouts as the expected baseline, not an anomaly.
