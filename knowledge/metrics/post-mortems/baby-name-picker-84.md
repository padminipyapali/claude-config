# POST-MORTEM: baby-name-picker PR #84 — Onboarding boy-card blue + compare-card meaning/Details spacing

Branch: fix/card-spacing-onboarding-accent → main | Author: padminipyapali | ~2.5 min open-to-merge
Size: +43 -2 across 3 files, 1 commit (squash, self-merged)

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (4b NOT run — recurring solo-self-merge skip).
- Adversarial / fresh-context critic: 1 finding, 1 fixed.
- Shift-left rate: 100% of substantive issues caught locally.

The PR bundled two unrelated UI-polish tweaks (deliberate, same-session, both trivial):
1. Onboarding "Boy names" card color green (`sageLight`/`sage`) → blue accent family, for per-gender theming consistency (girls rose, boys blue, all plum).
2. Compare card: open a gap between the meaning line and the absolutely-positioned Details CTA pill, crowded by the recently-added pronunciation row.

## STEP COMPLIANCE
- Steps run: 1, 2, 3, 4a, 4c, 5 (6/9).
- Steps skipped: 4b (CodeRabbit CLI). PR body has no explicit `Steps skipped:` line.
- Compliance rate: ~67%.
- Skip assessment: neutral — no post-merge review data to prove the skip cost anything, but it continues a known recurring pattern.

## STEP TIMING
Not tracked (no `## Step Timing` section in PR body).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; self-merged).
- Comments: 0 inline, 0 general.
- Categories: all zero.
- Timeline: created → merged ~2.5 min; no peer review, no CI (empty statusCheckRollup).

## ADVERSARIAL REVIEW EFFECTIVENESS
The fresh-context critic earned its keep. The FIRST spacing implementation used `paddingBottom` on the centered container. The critic determined this is INEFFECTIVE under RN 0.83.2 / Yoga 3.x: an absolutely-positioned child's `bottom` inset is measured from the parent's PADDING edge, so padding moves the pill up *with* the content and opens no gap. Verdict: DO-NOT-SHIP. The implementer switched to a deterministic conditional `marginBottom: 48` on the in-flow content block (which the absolute pill ignores). This is a strong pre-merge catch of a correctness bug that would otherwise have shipped a non-functional "fix."

- Pre-push catch potential: 1/1 (100%).
- Covered but missed: none.
- New category captured: RN/Yoga absolute-positioning + parent-padding gotcha (see react-patterns.md).

## FIX-UP METRICS
- Post-merge fix rate: 0% (0 post-merge fix commits referencing #84 — ideal).
- Pre-merge catch rate by step: 4a 0 | 4b 0 | 4c 1 | 4d 0 | post-push 0.
- Pre-merge iteration count: 1 (healthy). The critic's catch was folded into the single squashed commit, so it does not appear as a separate fix commit.
- Fix-up taxonomy: { correctness: 1 } (the Yoga/padding fix), all others 0.
- Legacy fix-up ratio: 0% (the single commit is a feature commit; the fix was pre-commit).

## PLANNING QUALITY
- Description: partial — has Summary, Local Review, Test plan; no Performance & Cost Impact section, no `Closes #N`.
- Scope: mild deviation — two unrelated concerns bundled (one-concern rule), deliberate for two trivial same-session tweaks. Branch lifetime minutes; 45 LOC; well under size caps.

## CODE QUALITY SIGNALS
- Recurring: 4b CodeRabbit skip (now 4th baby-name-picker occurrence: #73, #80, #84, plus family-digest origin).
- New pattern captured: Yoga 3.x absolute-child inset measured from padding edge → use margin on in-flow sibling, not parent padding.

## PROCESS EFFICIENCY
- Automation opportunity: a pre-push hook blocking push (or demanding a recorded skip reason) when 4b did not run — the prose recommendation has now been violated 4x and should be an enforceable artifact.
- Iteration: efficient.
- CI: none configured.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/react-patterns.md` — NEW entry under "React Native Specific": Yoga 3.x absolute-positioned child inset is measured from the parent's padding edge; use margin on an in-flow sibling to open a gap, not parent padding.
- `~/.claude/knowledge/process-patterns.md` — STRENGTHENED the existing solo-self-merge CodeRabbit-skip entry with #84 as a 4th data point (did not duplicate).

## RECOMMENDATIONS
1. Convert the recurring 4b-skip prose into an enforceable pre-push hook — it has now been ignored across 4 baby-name-picker PRs. Prose alone never lands.
2. Keep the one-concern rule but the bundling here was low-risk; no action needed beyond awareness.
3. On-device verification of the `marginBottom: 48` gap remains an open test-plan item the author flagged — confirm the visible gap reads correctly.
