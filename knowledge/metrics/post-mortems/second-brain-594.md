# Post-Mortem: second-brain PR #594

**Title:** feat(projects): file/image/link resources with aggregated tab
**Branch:** feat/projects-resources → main
**Author:** padminipyapali (self-merged)
**Created:** 2026-05-06T05:38:47Z
**Merged:** 2026-05-06T05:41:49Z (~3 min on GitHub; work happened pre-push)
**Size:** +3893 / -55 across 30 files, 1 commit

## Local review
Not tracked — PR body has no `## Local Review` section. Body does describe a sibling sweep (LINK EntryType union) and cross-user safety on every path, suggesting hardening was performed even though it wasn't recorded in the structured form.

## Step compliance
Not tracked (no `Steps skipped:` line). Body implies steps 1-3 ran; nothing recorded for the step 4 review loop.

## Step timing
Not tracked.

## Review friction
- Reviews: 0. Inline comments: 0. Bot comments excluded (Vercel).
- Self-merge: mergedBy == author. **Flag: no peer review.**

## Adversarial review effectiveness
No post-push comments → `adversarialCatchRate` = unmeasured.

## Fix-up metrics
- Post-merge fix rate: 0.0 (PR #595 in same window is unrelated todo-panel).
- Pre-merge iteration count: 1.
- Fix-up taxonomy: all zero. Legacy ratio: 0/1.

## Planning quality
- Description: **complete** — Summary, Locked decisions, server/client implementation breakdown, Pre-existing failures called out, Test plan with 10 items.
- Scope: single concern (resources) but large.
- Planning checklist: entry points enumerated (paperclip, drag-drop, paste-URL, All Resources), cross-user attack tested, pagination tied-timestamp edge case tested. **Missing: Performance & Cost Impact section.**

## Process risks (specific to this PR)
1. **PR size dwarfs the 600 LOC budget** — 3,948 LOC, ~6.5× cap. CLAUDE.md says shift-left rate "degrades sharply above this." Splittable into ~3 PRs: (a) migration + EntryType union sweep + server routes, (b) Notes column upload UX, (c) All Resources tab + pagination.
2. **Self-merge with zero recorded review evidence.** No `## Local Review` block means future post-mortems can't tell whether step 4 (CodeRabbit / adversarial / simplification) ran or was skipped.
3. **3-minute GitHub lifetime on a 4k-LOC change.** All work pre-push, no recorded timing.
4. **No Performance & Cost section.** New POST/GET/DELETE endpoints, multer multipart parsing, 25MB cap, cursor pagination — none of this has latency / query-load / cost analysis.

## Knowledge updates
None. Patterns referenced in the PR (sibling sweep, cross-user scoping, tied-timestamp pagination) are already captured.

## Recommendations
1. Split feature PRs >600 LOC into 2-3 logical PRs. Each gets its own review cycle.
2. Always include `## Local Review` (even zero findings) so post-mortems distinguish "not tracked" from "tracked clean."
3. Always include `## Step Timing` so we can see where time goes when GitHub lifetime is misleading.
4. Add Performance & Cost Impact section for any PR introducing new endpoints/storage paths (CLAUDE.md Planning Requirements).
