# Post-Mortem: second-brain PR #745 — feat(search): make search tag-aware so #tag entries surface in queries

**Branch:** `feat/tag-aware-search` → main | **Author:** padminipyapali | **Merged:** 2026-06-26T02:35:09Z (self-merge)
**Size:** +937 −154 across 21 files, 1 squashed commit | **Closes:** #740
**Time to merge:** ~1h 53m on GitHub (local dev loop ran before push)

---

## LOCAL REVIEW (pre-push)
- **CodeRabbit:** not tracked (PR body has no `## Local Review` section).
- **Adversarial gate:** PASS, 0 must-fix blockers.
- **Fresh-context critic:** APPROVE-WITH-FIXES, 2 should-fixes (both applied pre-merge):
  1. (correctness/recall) `tagCandidates` must also match the literal stored form, not only canonical.
  2. (defensive-coding/sibling-sweep) `EntryComposerSheet` accept handler must `clearSearchCache` like editor add/remove.
- **Shift-left:** 2/2 issues caught locally; 0 escaped post-merge.

## STEP COMPLIANCE
- Not tracked (PR body has no `Steps skipped:` line) → `stepCompliance: null`.

## STEP TIMING
- Not tracked (PR body has no `## Step Timing` section) → `stepTiming: null`.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no CHANGES_REQUESTED; local gate was the review).
- Comments: 0 substantive (1 Vercel bot comment, excluded).
- Categories: all zero.
- Timeline: created 00:42:28Z → merged 02:35:09Z (~1.88h total; no GitHub review events).
- Self-merge: yes (author == mergedBy), no GitHub peer review — expected for solo dev under the layered local gate.

## ADVERSARIAL REVIEW EFFECTIVENESS
- **adversarialCatchRate = 1.0** — evidence-based, not hardcoded.
  - Caught pre-merge: 2 (critic should-fixes).
  - Escaped post-merge: 0 (745 is the latest merged PR; no follow-up fix PRs touch the tag-search area; planned PR 2 is net-new work, not a fix).
  - 2 / (2 + 0) = 1.0.
- Covered by existing adversarial checklist: the recall-completeness gap (new signal not wired into retrieval) and the cache-mutation-site sibling-sweep are both already-known classes (database-patterns.md, react-patterns.md, sibling-sweep convention #1).
- Not covered (new categories): none.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (0 post-merge fix commits/PRs — ideal).
- Pre-merge catch rate by step: 4a=0, 4b=0, 4c=2, 4d=0, postPush=0 (both caught by fresh-context critic; single squashed commit so no discrete fix commits).
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: { correctness: 1, defensive-coding: 1 } (the two critic catches).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit — squashed feature commit).

## PLANNING QUALITY
- Description: complete (What & why, How, Designs, Testing, Notes; explicitly marked PR 1 of 2).
- Scope: clean — cohesive single feature lane wired end-to-end. Size (1091 LOC) exceeds the ~600 soft cap but is one concern; the web cache/chip wiring is the natural split seam if needed.
- Branch lifetime: short (rebased onto current origin/main #735 before review).
- Planning checklist: entry points enumerated (FTS first-paint vs full hybrid vs vector-only grounding; cache hit vs short-query clear; all three tag-mutation sites). No explicit Performance & Cost section, but the design notes the per-lane `.catch` degradation and the boost scaling — performance reasoning is present inline.

## CODE QUALITY SIGNALS
- Recurring issues: cache-invalidation completeness across mutation sites (caught pre-merge here; was a post-merge escape in remodel-hq #86).
- New unrecorded patterns: none — all learnings were already captured before this post-mortem.

## PROCESS EFFICIENCY
- Automation opportunities: a Tier-0-style grep when introducing a new derived/search cache, to enumerate every entity-mutation site that must invalidate it (add/remove/accept/import/bulk-edit). Currently a manual sibling-sweep.
- Iteration: efficient (1 round, 0 escapes).
- CI: all passed (Vercel SUCCESS; server 2252 / web 340 tests).

## KNOWLEDGE UPDATES
- **Strengthened** `~/.claude/knowledge/react-patterns.md` "Cross-surface cache notifier coverage" with the #745 pre-merge confirmation (composer-accept as a third `clearSearchCache` site) — the corrected shape of the remodel-hq #86 escape.
- **NOT duplicated** (already captured before this post-mortem):
  - Retrieval-silo, seed-before-boost RRF, canonical-vs-literal exact-match → `database-patterns.md` lines 30–32 + `docs/BUGS.md` BUG-037.
- Appended metrics entry to `post-mortem-metrics.json` (now 401 PRs) and regenerated `dashboard.html`.

## RECOMMENDATIONS
1. **Add `## Local Review` + `Steps skipped:` (+ optional `## Step Timing`) to PR bodies.** Three consecutive second-brain PRs (#743/#744/#745) recorded null compliance/timing purely because the body lacked these sections — the single highest-leverage fix for metric fidelity.
2. **Split feature-lane PRs at the server/web seam past ~600 LOC** when both halves are independently testable (here: server retrieval lane vs. web cache/chip wiring).
3. **On PR 2 (write-time canonicalization), collapse dual canonical+literal candidates to canonical-only + add a backfill migration** per BUG-037, so the dual-form logic isn't permanent tech debt.
