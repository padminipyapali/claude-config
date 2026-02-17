# Post-Mortem: second-brain PR #152

**Title:** Fix image display and proxy for legacy Telegram images
**Branch:** fix/image-display-and-proxy → main
**Author:** padminipyapali | **Merged:** 2026-02-17T07:43:58Z
**Size:** +10 -6 across 4 files, 4 commits

## Summary

Bug fix PR addressing "Image not available" on the dashboard. Root cause: `SUPABASE_SERVICE_ROLE_KEY` missing from `.env` meant images were never uploaded to Supabase Storage, and the frontend returned null for non-HTTPS media URLs. Fix: wire existing server proxy endpoint to frontend for legacy Telegram images, add query param auth for `<img src>` tags, and fix a React StrictMode `isMountedRef` bug that prevented entries from rendering in dev mode.

## Local Review (pre-push)

- CodeRabbit: Skipped (bug fix, 3 files changed)
- Adversarial review: Skipped (bug fix, minimal scope)
- CI: build and tests pass locally

## Review Friction (post-push)

- **Review rounds:** 2 (1 CHANGES_REQUESTED from CodeRabbit, then fixed)
- **Comments:** 1 inline (CodeRabbit)
- **Categories:** security: 1
- **Timeline:** created → first review: 7m | first review → merge: 3m | total: 10m

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% — the auth scope issue was not in the checklist at the time
- **Covered but missed:** None (not covered)
- **Not covered (new):** Auth fallback scoping — adding alternative auth mechanisms (query param) globally in middleware instead of scoping to specific routes
- **Fix commits:** 1 of 4 total (25% fix-up ratio)

## Key Finding

The auth middleware was modified to accept `?token=` query params globally on ALL routes, when it was only needed for the media proxy endpoint. CodeRabbit caught this as a security concern. The fix scoped the fallback to `GET /entries/:id/media` only.

**Why it happened:** When implementing a workaround for `<img src>` tags that can't send Bearer headers, the simplest approach was to add the fallback in shared middleware. The "quick and easy" path broadened the attack surface unnecessarily.

**Lesson:** Auth fallbacks should be scoped to the exact route that needs them, not applied globally for convenience.

## Planning Quality

- Description: Complete (Summary + Test Plan + Local Review section)
- Scope: Clean — focused bug fix
- Branch lifetime: 10 minutes
- Planning checklist: N/A (bug fix, not feature)

## Knowledge Updates

1. **architecture-patterns.md** — New "Auth & Security Boundaries" section added
2. **adversarial-review.md** — New Tier 2 check: "Auth fallbacks scoped to specific routes"

## Recommendations

1. **Don't skip local review for "small" PRs.** Even a 3-file bug fix can introduce a security issue (global auth fallback). The adversarial review would have caught this if it had been run.
2. **When adding auth workarounds, always ask: "What's the blast radius?"** The `?token=` query param was needed for one route but applied to all.
