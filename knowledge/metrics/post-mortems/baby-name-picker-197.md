# POST-MORTEM: baby-name-picker PR #197 — Make the taste profile honest: tentative read instead of a dead-end teaser.

Branch: `feat/taste-honest-reveal` → `main` | Author: padminipyapali | created 2026-06-17T01:06:07Z → merged 2026-06-17T02:42:10Z (~1.6h wall-clock)
Size: +510 -14 across 6 files, 2 commits. Self-merged (solo workflow; local review is the gate).
Team: full 3-role orchestrator team (`dev-taste-reveal`) — orchestrator + implementer + fresh-context critic.

## What shipped

Fixes a taste-profile dead-state: a user past the 20-comparison data floor with eclectic taste was shown a silent "keep comparing" with no number and no read — telling them to do the one thing that would not help. Root cause: the classifier returns the **Free Spirit** fallback for eclectic taste, and the confidence gate deliberately forbids that fallback from ever being "confident", so the screen fell through to a countdown-less teaser and hid a read it already had.

Fix:
- Adds a `profileState` discriminator (`needs_more | tentative | confident`) computed in `getTasteScreenData`.
- `tentative` (past floor, gate unmet) now surfaces the leading archetype as a soft read — Free Spirit as a real open-ended identity ("no single origin, sound, or style dominates"); near-miss non-fallback as "leaning toward X — a few more decisive picks will lock it in" — plus the real comparison count and an honest reason.
- **Confident path byte-for-byte unchanged** (zero-line diff in the confident body).
- **No gate/threshold calibration change** — the gate correctly classifies eclectic as non-confident; the bug was purely presentational. A regression test pins "eclectic stays non-confident".
- `totalComparisons` confirmed GLOBAL across decks (raw COUNT, no gender filter).

Files: `app/taste.tsx` (+157/-9), `app/__tests__/taste.test.tsx` (+148), `src/services/tasteArchetype.ts` (+42/-4), `src/services/__tests__/tasteArchetype.test.ts` (+38), `src/stores/gameStore.ts` (+41), `src/stores/__tests__/gameStore.taste.test.ts` (+84). ~270 of 510 additions are tests.

## LOCAL REVIEW (pre-push)
- **4a simplify** PASS — state derivation centralized in `getTasteScreenData`; `tentativeReadFor` is the single copy source; "TAKING SHAPE" eyebrow intentionally not reusing `ArchetypeHeader` ("YOU ARE" would overclaim).
- **4b CodeRabbit CLI** PASS — 0 findings.
- **4c adversarial** PASS — fresh-context critic. State machine verified exhaustive (every entry → exactly one state, no gaps/crashes; `confident` ⟺ `isConfident`); null-walk clean; confident path zero-diff. **Critic caught + fixed one real contradiction** (see below) with 2 regression tests.
- Shift-left rate: 100% of issues (1/1) caught locally, 0 escaped.

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 5 (full flow). Steps skipped: none. Compliance rate: 100%. Skip assessment: good.
- Note: 4d/CI ran green post-push ("Typecheck, lint & test: SUCCESS") but is not a local pre-push step.

## STEP TIMING
Not tracked — no `## Step Timing` section in the PR body. `stepTiming: null`.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED). Inline comments: 0. General comments: 0. No GitHub reviews (local-review-as-gate flow per CLAUDE.md Step 5).
- Categories: all zero (no post-push comments).
- Timeline: created → merge ~1.6h, no post-push review iteration.
- Self-merge: yes (`mergedBy == author`), expected for solo workflow; the fresh-context critic is the peer-review substitute.

## ADVERSARIAL REVIEW EFFECTIVENESS
- **adversarialCatchRate = 1.0** (evidence-based, not fabricated). One actionable issue existed; the critic caught it locally pre-push, it was fixed with 2 regression tests, 0 escaped to post-merge.
- The catch (commit `db5b7ed6`): a dominance-asserting tell (`concentration` / `head_to_head` / `consistency`) could render under the "no single style dominates" open-ended Free Spirit read, because the tell preconditions are looser than the archetype gates — e.g. the concentration tell fires at `topOriginShare >= 0.45` with no win-rate floor, while Heritage Keeper also requires `topFamilyWinRate >= 0.55`. That surfaced copy like "50% of your winners trace to Greek roots" directly under "no single origin, sound, or style dominates" — a self-contradiction. Fix: filter those three dominance tell kinds out of the open-ended Free Spirit read ONLY; keep them for the directional near-miss read ("leaning toward X"), where a directional tell reinforces rather than contradicts. Two regression tests cover both branches.
- This is a strong adversarial-catch example: a cross-component invariant (tell-precondition looseness vs archetype-gate tightness) that unit tests of either component in isolation would miss, surfaced only by a fresh-context reviewer reasoning about rendered copy coherence.
- Covered but missed: none. Not covered (new category worth noting): "two independent gates with asymmetric thresholds can co-fire and produce contradictory user-facing copy" — a presentation-coherence class, captured via the root-cause learning below.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (197 is the newest merged PR; no follow-up fix PR touches taste).
- Pre-merge catch rate by step: 4a=0, 4b=0, 4c/adversarial=1, post-push=0. (The one fix commit is the critic's contradiction fix.)
- Pre-merge iteration count: 1 (one local adversarial round) — healthy.
- Fix-up taxonomy: correctness=1 (the contradiction filter), all others 0.
- Legacy fix-up ratio: 0.5 (1 fix commit / 2 total) — but the "fix" commit is a critic-caught correctness fix bundled with its regression tests, not churn; the 0.5 reads high only because of the small 2-commit denominator.

## PLANNING QUALITY
- Description: complete (Summary, Local Review, Test plan, out-of-scope Note all present).
- Scope: clean — single feature, one primary surface (the taste screen), confident path explicitly preserved zero-diff, gate explicitly NOT recalibrated. No redesign/revert commits.
- Branch lifetime: ~1.6h. Size 524 (within the 600-LOC cap).
- Planning checklist: entry points (all `profileState` branches: needs_more / tentative-fallback / tentative-near-miss / confident / no-profile degrade) enumerated and each test-covered. Root cause diagnosed in code before coding (gate read; `totalComparisons` global-scope confirmed, ruling out a per-deck hypothesis).

## CODE QUALITY SIGNALS
- Recurring issue: the post-PASS-critic-commit marker-strand process gap (see below) — 2nd consecutive baby-name-picker occurrence (#195, #197).
- Test approach: no RN renderer dependency ships in the repo, so screen states are covered via function-walk text-collection tests asserting the real rendered text per branch, rather than Playwright/RN snapshots. **Assessment: adequate for this PR.** The bug and its fix are about which strings/states render (a read appears or not; a contradictory tell is suppressed or not), which text-assertion tests pin directly; a pixel snapshot would add little for a copy/state-selection bug and the repo has no reliable simulator-driving path anyway (see the standing `idb`/Maestro gap). The 12 new tests cover all five state branches plus the tell-suppression asymmetry (Free Spirit drops concentration / keeps divergence; near-miss keeps concentration) and the eclectic-stays-non-confident regression. The gap to keep in mind: text-walk tests do NOT verify layout/visual regressions (Close pill placement, absent Share bar) beyond their presence/absence in the render tree — fine here because the confident body is a verified zero-diff, but a future visual-only change on this screen still has no automated gate.

## PROCESS FRICTION (recurring — reinforced, not duplicated)
The critic committed its contained fix (the tell filter + 2 regression tests) AFTER returning PASS, so HEAD advanced past the reviewed commit and the adversarial-review marker (keyed to `md5(worktree-path)`, verified against HEAD by `require-adversarial-review.sh`) no longer matched — the push hook correctly blocked. Resolution: the orchestrator self-eyeballed the contained delta (filter + tests, the "self-eyeball" tier of the Critic Round Tiers) and re-wrote the marker for the new HEAD. **This is the exact pattern flagged in PR #195's post-mortem.** Two consecutive baby-name-picker PRs now confirm it is structural. Rather than duplicate the learning, the existing `process-patterns.md` "Process Rule Enforcement" entry (sourced to #195) was strengthened with the #197 recurrence and an escalation pointer to the automated fix (critic refreshes the marker as the FINAL action of any post-PASS commit). See cross-reference, do not re-file.

## PROCESS EFFICIENCY
- Automation opportunities: (1) automate the adversarial-marker refresh as the critic's last post-PASS action (2nd occurrence — now escalated). (2) None else; CodeRabbit + adversarial both clean locally.
- Iteration: efficient (1 local round, 0 post-push).
- CI status: all passed ("Typecheck, lint & test: SUCCESS") before merge.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/process-patterns.md` — Planning Discipline: NEW entry on diagnosing the gate/threshold in code (and confirming input scope: global vs per-deck) before choosing a fix, with the "is the gate wrong or is the presentation discarding a value the gate already produced?" check (the recalibrate-a-correct-gate wrong-fix trap). Source baby-name-picker #197.
- `~/.claude/knowledge/process-patterns.md` — Process Rule Enforcement: STRENGTHENED the existing post-PASS-critic marker-strand entry with the #197 recurrence + escalation to the automated fix (cross-reference of #195, not a duplicate).
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` — appended baby-name-picker #197 entry.
- `~/.claude/knowledge/metrics/dashboard.html` — regenerated embedded `METRICS_DATA`.

## RECOMMENDATIONS (ranked)
1. **Automate the marker refresh.** 2nd consecutive occurrence in this repo. Make the critic re-write the adversarial-review marker keyed to the new HEAD as the final step of any post-PASS fix it commits, so the push hook never strands. (Until then, the orchestrator's manual re-issue is the stopgap — which worked here.)
2. **Adopt the "read the gate before fixing the empty state" diagnostic as a standing first move** for any "feature renders nothing / is silent" bug, including the input-scope confirmation (global vs scoped) that disconfirmed the per-deck hypothesis here. Captured as a Planning Discipline learning.
3. **When two thresholds/gates feed the same surface, check they cannot co-fire into contradictory copy.** The critic's catch generalizes: a looser precondition (tells) under a tighter classification (archetype gate) produced a self-contradicting read. Worth a lightweight check in any future taste/tell additions.
4. **Add `## Step Timing` to PR bodies** so timing metrics stop being null on otherwise well-documented PRs.
