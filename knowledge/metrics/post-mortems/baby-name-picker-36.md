# Post-Mortem: baby-name-picker PR #36 — Add /web landing page branded as Alma with stacked-blocks icon

**Branch:** feat/landing-page -> main | **Author:** padminipyapali | **Duration:** 67.8h wall-clock (~30 min active)
**Size:** +7379 -0 (7379 LOC) across 25 files, 3 commits
**Date merged:** 2026-05-18T23:00:11Z

---

## Summary

Stands up a Next.js landing page under `/web` for the mobile app, branded as **Alma** with a stacked-blocks icon. Adds App Store + Google Play CTAs (rendered as non-interactive "coming soon" affordances), brand palette tokens, and the icon explorations under `docs/mockups/alma-icon-explorations/`. No app/runtime changes — pure marketing surface.

Three shipped commits:
1. "Add /web landing page with App Store + Play Store CTAs."
2. "Brand landing page as Alma with stacked-blocks icon."
3. "Address critic findings: contrast, palette tokens, a11y, brand constants."

## Local Review (pre-push)

| Tool | Findings | Fixed |
|------|----------|-------|
| `/simplify` (4a) | n/a | n/a |
| CodeRabbit CLI (4b) | SKIPPED | — |
| Adversarial review (4c) | 10 (4 blockers + 6 should-fix) | 10 |
| CI (4d) | SKIPPED | — |
| **Total pre-push** | **10** | **10** |

All 10 critic findings landed in the third commit. Skipped steps:
- **4b CodeRabbit CLI** — `web/` has no CI pipeline wired yet; tool wasn't run.
- **4d CI** — same reason.

## Step Compliance

- **Steps run:** 1, 2a, 2b, 3, 4a, 4c, 5 (7/9)
- **Steps skipped:** 4b, 4d
- **Skip reason:** `web/` has no CI pipeline yet (no lint/build/test job configured).
- **Compliance rate:** 77.8%
- **Skip assessment:** neutral — skips are infrastructure-bounded, not discipline-bounded.

## Step Timing

| Step | Minutes |
|------|---------|
| Plan (1) | 5 |
| Implement (2a/2b) | 15 |
| Test (3) | 1 |
| Review (4a/4c) | 7 |
| Push (5) | 2 |
| **Total active** | **30** |

**Bottleneck:** iterative design discussion (wall-clock ~67h).
**Note:** Active implementation time ~30 min; long wall-clock driven by user-driven naming/icon iteration before implementation began (see "Process Efficiency").

## Review Friction (post-push)

- **Review rounds:** 1 (self-merge baseline; 0 CHANGES_REQUESTED)
- **Inline comments:** 0 | **Bot comments:** 0
- **Comment categories:** all zero.
- **Timeline:** all friction was pre-push (10 internal critic findings); zero post-push signal.

## Adversarial Review Effectiveness

- adversarialCatchRate: **unmeasured** — no post-push feedback to grade against.
- The internal critic produced 10 findings on the first review pass and all were fixed in the same commit. With no peer/bot reviewers post-push, this PR provides no calibration signal for the pre-push checklist's recall.

## Fix-up Metrics

- **Post-merge fix rate:** 0.0 (no follow-up "fix" commits to `web/` since merge as of 2026-05-18).
- **Pre-merge iteration count:** 4 (user-driven naming + icon design rounds before implementation; 3 implementation commits).
- **Legacy fix-up commit ratio:** ~0.67 (commit 3 of 3 was a pure fix-up commit addressing critic findings).
- **preMergeCatchRateByStep:** all 10 catches attributable to step 4c (internal critic).
- **fixupTaxonomy:** a11y: 4, correctness: 2, style: 2, documentation: 1, infrastructure: 1.

## Planning Quality

- **Description:** complete.
- **Scope:** clean — single concern (web landing surface). No app-runtime mixing.
- **Branch lifetime:** 67.8h, mostly driven by pre-implementation design iteration, not stuck-state friction.
- **Pre-implementation iteration:** 4 rounds of name/icon discussion (20+ name candidates, 4 icon mockup files in `docs/mockups/alma-icon-explorations/`).

## Code Quality Signals

### Notable craft details
- **Brand palette + brand constants extracted** as part of the critic-fix pass — the third commit promoted ad-hoc hex values to tokens, which is the right pattern for a brand surface that will see iteration.
- **Disabled-button approach for unshipped CTAs was scrapped** in favor of `<div role="img" aria-label="...">` with `pointer-events: none`. Cleaner accessibility story (see react-patterns capture below).
- **Switched to official Apple + Google Play badge SVG assets** in a separate iteration — initial badge implementation used a hand-rolled approximation.

### Risk points
- **Alma name has 2 direct parenting-app collisions on the App Store** (Alma: AI Parenting Guide, Alma — Pregnancy Companion). Decision documented to ship anyway; revisit if SEO/store-search bleed materializes.
- **Two dev-server-hang incidents** during the rapid critic-fix loop where the Next.js Tailwind compile worker hung silently — TCP stayed open, requests accepted, but the worker stopped responding and the browser saw zero-styled HTML. Resolved by killing the worker and restarting (see process-patterns capture).
- **Favicon font rendering** — `next/font` doesn't load in the OS favicon preview context, so the favicon previewed with a generic system serif (Times-like) instead of the in-page brand font. Logged as an adversarial-review pattern for asset rendering contexts (see adversarial-review capture).

## Process Efficiency

### Wall-clock vs active-time gap
- 67.8h wall-clock against ~30 min active implementation = ~135x ratio.
- Driver: 4-round design discussion (naming + icon) preceding any code. This is healthy for a brand-defining surface but creates noisy "time to merge" telemetry. Recommend a separate `designIterationRounds` metric for design-led PRs.

### Iteration assessment
- 3 shipped commits; clean fix-up pattern (commit 3 = pure critic-fix).
- Skipped 4b/4d is infrastructure-bounded, not discipline-bounded.

### CI status
- No CI configured for `web/` (root of skipped 4b/4d).

## Recommendations

1. **Wire minimal CI for `web/`** before the next landing-page PR — at minimum `npm run build` + lint. Unblocks steps 4b and 4d for this surface and gives future post-mortems calibration data.

2. **Add `designIterationRounds` to fix-up metrics for design-led PRs.** Wall-clock telemetry doesn't separate "user iterating on the brand" from "agent stuck." This PR's 67h would otherwise read as friction.

3. **Add a healthcheck ping after rapid file-rewrite batches** when a dev server is in the loop. Two silent dev-server-hang incidents this PR — a one-line `curl -s -o /dev/null -w '%{http_code}' localhost:PORT` between batches would catch this immediately.

4. **Asset-rendering-context font fallback.** Favicons, OG images, and email templates render outside the page's font loader. Either outline brand text to SVG paths in static assets, or specify a system-safe fallback. Captured in adversarial-review.md.

5. **For unshipped store-badge CTAs, default to `<div role="img">` not `<button disabled>`.** Cleaner a11y + visual story. Captured in react-patterns.md.

## Knowledge Updates

- New entry in `~/.claude/knowledge/metrics/post-mortem-metrics.json` (#36)
- Process patterns: dev-server-hang on rapid file rewrites; wall-clock vs active-time gap on design-iteration PRs
- Adversarial review: rendering-context font fallback
- React patterns: non-interactive `role="img"` wrapper for not-yet-shipped store-badge CTAs
