# Post-mortem: plush-press PR #338 — Enforce book-style coherence in the cast picker (Stage 6a PR1 of Art Styles)

Branch: feat/style-coherence → main | Author: padminipyapali (self-merged, solo repo) | Created 2026-07-20T15:04 → merged 16:54 (1.84h)
Size: +647 −15 across 11 files, 1 squash commit. Source ~320 / tests ~279 / docs +49 (declared LOC split in body).

## Context

Operator-principle-driven feature ("we can't have a watercolor character on a pencil background"). Plan-first with **5 recorded operator-approved decisions**, including one orchestrator amendment mid-plan (minimal write-stamping pulled out of PR1 into PR2). Canonicalization decision (null/""/"watercolor"/"soft-watercolor" → one default class) is what keeps legacy books byte-identical. One intended behavior change (legacy pencil/collage look ghosts in a watercolor book) called out explicitly in the body with the escape-hatch mitigation.

## Local review (pre-push)

- **Critic (fresh context): SHIP + 1 MINOR** — a lone-built-in-look card renders no look strip, so on "Show other styles" reveal it un-ghosted with NO amber mismatch indicator → a silent mixed-style pick. Fixed with a card-header `StyleMismatchTag` on `coherenceOn && !matches(target)` (covers the no-strip case generically) + a dedicated reveal-path test. The critic also traced the **fail-open safety property** end-to-end: `useResolvedStyle` degrades to `null` on ANY resolve failure → picker stays ungated; coherence can only ghost when the style is known, never trap the operator.
- **CodeRabbit CLI: rate-limited, orchestrator chose to WAIT for the free-tier window reset rather than skip.** The completed run caught **4 minors, all fixed**:
  1. (Functional, MOST substantive) `useResolvedStyle` reported `loading: false` before the first resolution settled — conflating "still resolving" with "resolved-to-null". Fixed with a `settled` flag + initial-loading assertion. **This is the predicted cached-async-state hook-contract class — 4th consecutive PR where CodeRabbit's finding was in that family (#330 partial-failure supersede, #333 two-snapshot read, #334 stale-key rebind, #338 loading-before-settled).**
  2. (Functional) escape hatch scanned already-cast looks → a toggle could appear that unlocks nothing; now filters to addable off-style looks.
  3. (Test) strengthened initial-loading assertion (catches finding 1's class).
  4. (Docs) misleading test comment corrected.
- **Gates after every fix:** typecheck 0 · lint 0 (only pre-existing warning) · full vitest green · build 0. One mid-flight rebase onto origin/main (#335).

## adversarialCatchRate = 1.0 (MEASURED)

5 findings total across the PR lifecycle (critic 1 + CodeRabbit 4); all 5 fixed pre-push; 0 post-push comments; 0 post-merge fix PRs (checked — #338 is the last merge, nothing follows). 5/5 caught locally = 1.0 shift-left. Critic share = 1/5 (0.2): the findings on this slice were CodeRabbit-flavored, consistent with the series — the cached-async family is CodeRabbit's beat, semantic-UI corners + safety-property tracing are the critic's.

## Fix-up metrics

- Post-merge fix rate: **0.0**.
- Pre-merge catch by step: 4c (CodeRabbit) 4, 4d (critic/adversarial) 1, others 0, post-push 0.
- Pre-merge iterations: 2 (critic round → fix; CodeRabbit round → 4 fixes). Normal.
- Taxonomy: correctness 3 (silent-mismatch corner, loading-contract, dead escape-hatch toggle), test-quality 1, documentation 1.
- Legacy fix-up ratio 0.67 (2 fix rounds / 3 total rounds, single-squash convention as #336).

## Review friction (post-push)

0 review rounds beyond merge, 0 comments, no peer review (solo-repo norm; layered local gate is the substitute). Final-SHA branch CI success; post-merge main CI success. Note: merge landed ~74s after the final branch CI run started (post-rebase SHA) — the run did conclude success and main stayed green, but this is tight against the "CI green before merge" gate; the earlier pre-rebase SHA was fully green.

## Step compliance / timing

- **`Steps skipped:` line absent** from the PR body → `stepCompliance = null`. This is a REGRESSION from #336, which declared its skips (2b retired, 4a folded) and scored 78%. The recurring line-92 pattern in process-patterns.md strikes again.
- `## Step Timing` present but qualitative only (no durations) → minutes null; bottleneck = CodeRabbit rate-limit wait.

## Planning quality: complete

Summary, decisions, intended-behavior-change callout, no-regression + fail-open proof, Designs section (references approved mockup), LOC split, PR2 scoping. No paid-API changes → no Performance & Cost section needed. Scope clean; branch lifetime <2h; PR2 split decision kept this under-cap-adjacent (662 total incl. tests/docs).

## Process data points

1. **Wait-vs-skip on a rate-limited CodeRabbit run PAID OFF (2nd time).** #330's retry caught a MAJOR; #338's waited-out run caught 4 findings incl. the predicted-class functional bug. A throttled run is a skipped gate; waiting is cheap. → strengthened the process-patterns rate-limit entry.
2. **4th consecutive cached-async-state CodeRabbit catch** → the class is now a named adversarial-review checklist item ("Cached-async hook loading contract"), so the critic can pre-empt CodeRabbit's beat on this specific shape.
3. **Prediction-then-confirmation**: the orchestrator predicted the finding class before the run; the run confirmed it. That is exactly the trigger for promoting a regularity into the checklist rather than continuing to rely on the second gate.

## Knowledge updates

- `~/.claude/knowledge/adversarial-review.md` — NEW ui-react Tier 3 item: **Cached-async hook loading contract** (`loading` stays true until first resolution settles; require a `settled` flag + initial-loading test). Source: #338.
- `~/.claude/knowledge/process-patterns.md` — strengthened the rate-limited-CodeRabbit entry (wait-beats-skip, 2 paid-off data points) and the critic/CodeRabbit division-of-labor entry (4th consecutive cached-async data point; class promoted to checklist).
- Metrics JSON + dashboard regenerated.

## Recommendations (ranked)

1. **Restore the `Steps skipped:` line** — #336 had it, #338 dropped it; stepCompliance went null. One line keeps the metric pipeline sighted. (Recurring; consider hardcoding into the PR-body template.)
2. **Add durations to `## Step Timing`** — still qualitative-only across the series; stepTiming has been null for every recent plush-press PR.
3. **Wait for the final-SHA CI run to conclude before merging after a rebase** — it succeeded here, but the ~74s gap suggests the merge didn't watch the post-rebase run; `gh pr checks --watch` per the merge-gate rule.
4. **Exercise the new checklist item on PR2** (scene/backdrop picker + write-stamping): it will touch the same resolved-style plumbing — the critic should run the cached-async hook-contract check explicitly and try to catch the class before CodeRabbit does (a 5th CodeRabbit-only catch would mean the checklist promotion didn't land).
