# POST-MORTEM: plush-press PR #12 — Archive six more proven prompts (ChatGPT adjustments, house plate, zoom).

Branch: chore/archive-gpt-adjustments → main | Author: padminipyapali | ~2 min open-to-merge
Size: +50 -2 across 5 files, 1 commit (squash 4fb80bb)
Merged: 2026-06-10T16:50:31Z (self-merge, no peer review — solo workflow, expected)

## What shipped
Verbatim archive of live prompt donations from book #1 production:
- `prompts/proven/chatgpt-adjustments-original.md` — four verified gpt-image-1 adjustment prompts, including the keep-list → fix-ONE-thing → nothing-else-changes precision pattern (the tune stage's provenance).
- `prompts/proven/house-plate-original.md` — the photo→watercolor repaint behind `house-wide.png`; proves the scene-plate template's photo-referenced variant.
- `prompts/proven/house-zoom-original.md` — landmark-anchored zoom that derived `house-medium.png`/`house-low.png`; a NEW proven variant for angle derivation (zoom beats re-imagined camera positions for staying on-model).
- Pointer lines added to `targeted-edit` and `scene-angle` templates.

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (n/a — docs-only transcription, no CodeRabbit run).
- Adversarial: 0 findings, 0 fixed — review bar was verbatim integrity (text checked against the user's original messages; one original typo preserved and annotated). No team; orchestrator transcribed directly per the no-logic-surface tier.
- Shift-left rate: n/a (zero issues at any gate).

## STEP COMPLIANCE
- Steps run: 2a (transcription), 4c-equivalent (verbatim-integrity verification), 5 (3/9 ≈ 33%).
- Steps skipped: 1, 2b, 3, 4a, 4b (n/a for docs-only transcription), 4d (no CI on repo).
- Skip assessment: neutral (no post-push review data to compare against; no post-merge issues observed).
- Gap: PR body has no explicit `Steps skipped:` line or `## Local Review` section — compliance reconstructed from the body's Tests note + session context (recurs from #11/#172 pattern).

## STEP TIMING
Not tracked (no `## Step Timing` section).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (zero CHANGES_REQUESTED). Comments: 0 inline, 0 general. Categories: all 0.
- Timeline: created 16:48:32Z → merged 16:50:31Z (~2 min). No reviews.

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: unmeasured — zero post-push findings means no denominator. Per metric-integrity rule, recorded as "unmeasured", not 100%.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (no follow-up fixes to this PR's files as of post-mortem).
- Pre-merge catch by step: all 0 (single clean commit). Iteration count: 1 (healthy). Taxonomy: all 0. Legacy ratio: 0% (0 fix / 1 commit).

## PLANNING QUALITY
- Description: complete (Summary + Tests, with the review bar stated explicitly).
- Scope: clean; branch lifetime ~2 min. Planning checklist (entry points, perf/cost): n/a for docs-only.

## DISCREPANCY FLAGGED
The session narrative described a second commit on this PR carrying the **two-image combine pattern, the hybrid combine+new-scene type, and pages 08/09**. The merged squash (4fb80bb) contains ONLY the six-prompts commit (fa1f451; 5 files, +50/-2). No combine-pattern file exists anywhere in the repo (grep `combine` over `prompts/` = empty; no branch carries it), and the zoo-bus page PNGs (incl. 08/09 + many `-alt` variants) sit **uncommitted in the main checkout's working tree**. Two donated proven generation types are therefore NOT yet archived.

## CODE QUALITY SIGNALS
- Recurring issues: none.
- New pattern captured: verbatim archiving of user-donated workflow artifacts is high-yield product research (two template-system upgrades came directly from donations) — and donations evaporate if not committed in-session (see discrepancy above).

## PROCESS EFFICIENCY
- Automation opportunities: none material for a transcription PR. CI status: no CI configured on repo (standing gap).
- Iteration: efficient (1 round).

## KNOWLEDGE UPDATES
- `process-patterns.md` › Data Quality / Audits: added "Archive user-donated workflow artifacts VERBATIM, promptly, in their own micro-PR — it is high-yield product research" (includes the archive-in-the-same-session corollary motivated by the missing combine commit).

## RECOMMENDATIONS
1. **Archive the donated combine + hybrid prompts now.** Two NEW proven generation types (two-image combine; combine+new-scene hybrid) were donated but never committed — they exist only in conversation history. Transcribe them into `prompts/proven/` in a follow-up micro-PR before the session context is lost, and commit the finished pages 08/09 PNGs (currently uncommitted working-tree changes on main).
2. Add the `Steps skipped:` line to PR bodies even on micro-PRs (3rd recurrence in this repo) — post-mortems keep reconstructing lane provenance by hand.
