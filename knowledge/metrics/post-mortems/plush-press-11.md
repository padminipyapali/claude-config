# Post-Mortem: plush-press PR #11 — Phase 0: normalize files to convention and archive the proven prompts.

Branch: `chore/phase-0` → `main` | Author: padminipyapali | Created 2026-06-10T16:32:39Z, merged 16:39:34Z (~7 min) | Squash: `4ed98d3`
Size: +168 −5 across 23 files, 6 commits. Files/docs-only (18 md + 4 png + 1 webp, two pure R100 renames, zero source files).
Team: orchestrator + implementer; critic tier = orchestrator self-eyeball (declared per protocol tier for no-logic-surface diffs). Session log: `~/.claude/orchestrator-logs/2026-06-10-phase-0.md`.

## Local review (pre-push)
- CodeRabbit: not run (files-only) → null.
- Critic review (orchestrator self-eyeball, recorded as 4c): PASS, 0 findings. Verified: R100 renames clean, verbatim proven-prompt anchors checked against the user's original messages, zero stale "softwash" strings after the naming amend, both spec edit markers present, backdrop naming convention exact.
- Shift-left rate: n/a (zero post-push findings to compare against).

## Step compliance
- Steps run: 1, 2a, 4c, 5 (4/9) — compliance 44%.
- Skipped: 2b, 3, 4a, 4b (files-only, justified in PR body "Why no tests / build"), 4d (no CI). Build/lint/test fields null, not 0 — files-only means "not applicable," not "ran clean."
- Skip assessment: **neutral** — no post-push review data exists to test the skips against; no post-merge issues either (main tip is still the squash commit, no follow-up fix PRs as of 2026-06-10).

## Step timing (from session log, not PR body — PR body had no Step Timing section)
| Step | Duration | Notes |
|------|----------|-------|
| 1 Plan | ~5 min | Team + worktree off origin/main 2b40194 (main had moved via #9 from another session — re-fetched, no stale-base incident) |
| 2a Implement | ~20 min | Bottleneck. Base scope + FOUR mid-flight user scope additions via SendMessage |
| 4c Review | ~2 min | Orchestrator self-eyeball, PASS |
| 5 Push/PR | ~2 min | PR 16:33 |
| Total | ~35 min | 16:05 team → 16:39 merge |

## Review friction (post-push)
- Review rounds: 1 (no reviews, no comments, no CI checks). Self-merged solo workflow — expected for this repo.
- Created → merge: ~0.12 h.

## Adversarial review effectiveness
- adversarialCatchRate: **unmeasured** — zero post-push findings means there is no denominator; per metric-integrity rule this is recorded as "unmeasured," not 1.0 or 0.0.
- Covered-but-missed / not-covered: n/a (no findings to classify).

## Fix-up metrics
- Post-merge fix rate: 0% (0 post-merge fix commits; main tip = squash).
- Pre-merge catch by step: all 0 — none of the 6 commits is a fix commit.
- Pre-merge iteration count: 1 (healthy).
- Taxonomy: all zeros. Notably, the Softwash→Soft Watercolor naming correction was **amended into the unpushed commit** rather than stacked, which is exactly the existing "squash fixes into the commits they amend" pattern — it kept the fix-up ratio honest at 0.
- Legacy fix-up ratio: 0% (0/6).

## Planning quality
- Description: complete (what changed by area, why-no-tests justification, verification evidence including link resolution and front-matter checks, explicit note that untracked user WIP was intentionally promoted into the PR).
- Scope: 4 mid-flight user additions absorbed cleanly — user-directed scope growth, not drift; branch lifetime ~35 min; no redesign indicators.
- Size 173 LOC-equivalent, well under the 600 cap.

## Process findings (the substance of this post-mortem)
1. **Message crossing at high scope-addition volume.** Four SendMessage scope additions repeatedly crossed with implementer progress reports — each side acting on a stale view of the other. Resolved with a single consolidated "outstanding checklist" ping; the implementer reconciled it against completed work (verified rather than re-built, and correctly no-op'd a duplicate task assignment). → strengthened the mid-flight-spec-changes pattern in `process-patterns.md` (plush-press #5 entry): after 2+ additions, stop piecemeal relays; send one consolidated checklist and get per-item DONE/PENDING back.
2. **Amend-in-place for corrections to unpushed work.** Naming correction folded into the unpushed commit instead of a stacked fix commit. Captured in the same pattern entry.
3. **Worktree near-miss, self-caught.** Implementer briefly wrote one file into the MAIN checkout, immediately moved it to the worktree and cleaned up. The failure mode (orchestrator-protocol "Worktree write failure", PR #324 incident) still occurs under context pressure; self-catch is good but the orchestrator's post-implementation diff + main-checkout `git status` sweep stays mandatory. → strengthened `orchestrator-protocol.md` Error Recovery section.
4. **Substance catch during implementation (not review):** `808Dolores.png` was misdescribed in scene-prompts.md as "the source photo" — it is the finished watercolor wide plate; the real source is the MLS photo (now `sources/house-808dolores-source.webp`). Corrected in-flight. Also: classifying the user's two WIP "zoom" images against scene-prompts.md angle definitions completed the house's 3-angle set, shrinking the MVP shakedown from 9 plates to 6.

## Recommendations
1. (Adopted into knowledge) Consolidated outstanding-checklist ping after 2+ mid-flight scope additions — make it the default orchestrator move rather than a recovery.
2. Keep the orchestrator main-checkout `git status` sweep after implementer "done" reports — the #11 near-miss shows leakage still happens even with the startup checklist.
3. When Phase 0-style PRs promote untracked user WIP into a PR, keep doing what #11 did: state it explicitly in the PR body ("intentionally included") so a future reviewer doesn't read it as accidental.
4. Next plush-press PRs enter MVP code territory — the files-only skip tier ends; full critic agent + build/lint/test gates resume.
