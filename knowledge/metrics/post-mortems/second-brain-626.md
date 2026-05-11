# Post-Mortem: second-brain PR #626

**Title:** fix(digest): collapse theme gap, format forgotten thoughts, add email digest links
**Branch:** fix/digest-rendering-625 -> main
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Created:** 2026-05-11T19:16:39Z | **Merged:** 2026-05-11T19:27:29Z | **Duration:** ~11 minutes
**Size:** +51 -3 across 4 files, 1 commit
**Closes:** #625

## Summary
Three targeted digest rendering fixes bundled into one PR:
1. CSS gap below collapsed themes — added `overflow: hidden` + `grid-auto-rows: 0fr`.
2. Forgotten thoughts on digest detail now render via existing `<FormattedContent inline>`.
3. Weekly email gains two new "View this digest on innershelf" deep-links. Gated on `includeArchiveLink && safeArchiveUrl` and (Themes) parsed-theme presence.

## Local Review (pre-push)
- /simplify: SKIPPED ("3 tiny localized changes")
- CodeRabbit CLI: SKIPPED
- Adversarial review: PASS via fresh-context critic, 0 findings
- Advisory: DigestArchive has no unit tests on main; pre-existing.

## Step Compliance
- Steps run: 1, 2a, 2b, 3, 4c, 4d, 5 (7/9)
- Steps skipped: 4a, 4b
- Compliance rate: 77.8%
- Skip assessment: **neutral** — no post-merge review data to compare against.

## Step Timing
Not tracked.

## Review Friction (post-push)
- Review rounds: 1 (self-merged 11 min after creation)
- Inline comments: 0 | Substantive general comments: 0
- Self-merge with no peer review (consistent with solo-dev pattern).

## Adversarial Review Effectiveness
- No post-push feedback; catch-rate unmeasured.
- Pre-push adversarial review produced 0 findings.
- adversarialCatchRate: **unmeasured**.

## Fix-up Metrics
- Post-merge fix rate: 0.0
- Pre-merge iteration count: 1 (healthy)
- Legacy fix-up commit ratio: 0%

## Planning Quality
- Description: **complete** (Summary, Test plan, Local Review, Perf & Cost, Closes #N)
- Scope: clean — three closely-related digest-rendering fixes from one issue
- Branch lifetime: 11 minutes
- Performance & Cost section: present and substantive

## Code Quality Signals
### Notable craft details
- **CSS grid collapse trap.** `grid-template-rows: 0fr` alone doesn't collapse when implicit rows exist; needs `overflow: hidden` + `grid-auto-rows: 0fr`. Worth capturing if it recurs.
- **Email link gating** properly preserves test-send behavior.
- **Reused existing FormattedContent** rather than re-implementing markdown.

## Process Efficiency
- Automation: visual regression test could have caught the CSS gap bug.
- Iteration: efficient (1 commit, 11 min).
- CI: SUCCESS.

## Knowledge Updates
No process-patterns.md or adversarial-review.md updates — single-commit, self-merged. CSS grid-collapse pattern noted but deferred (single data point).

## Recommendations
1. **Don't normalize the 4a+4b skip pair.** Heuristic: skip 4a only for diffs < 30 lines; skip 4b only when diff is purely CSS/copy. This PR was CSS + TSX + email template — arguably worth CodeRabbit.
2. **No tests added** despite three behavioral changes. The email-link gating logic (includeArchiveLink + parsed-theme guard) is the highest-value testable surface.
3. **Visual regression for digest rendering** (Playwright snapshot) would catch both visual bugs in this PR.
