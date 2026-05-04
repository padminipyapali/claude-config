# POST-MORTEM: remodel-hq PR #19 — Fix mutual-zip download for seeded relative-path images

- Branch: fix/inspo-zip-local-files -> main
- Author: padminipyapali (self-merged)
- Created: 2026-04-21T05:27:22Z | Merged: 2026-04-21T05:27:33Z (11s)
- Size: +13 -5 across 1 file, 1 commit
- Review decision: none (self-merged instantly, no reviews)

## Summary

Follow-up bug fix to PR #18. The mutual-favorites zip route called fetch(image_path) with relative paths like /inspo/foo.png, which has no base URL and failed for all 354 seeded inspiration photos. Fix resolves non-http(s) paths against request.nextUrl.origin before fetching, leaving absolute Supabase Storage URLs untouched.

The PR body justifies the choice of origin-based fetch over fs.readFile (Vercel serverless functions do not have public/ on the filesystem).

## Local Review

Not tracked — no Local Review section in PR body. Merged 11s after creation; full local review flow almost certainly skipped.

## Step Compliance

Not tracked — Steps skipped line missing. Inferred: steps 1, 2a, 5 ran; 2b/3/4a-4d skipped given the 11-second merge window.

## Review Friction

- Review rounds: 1 (no CHANGES_REQUESTED, no reviews)
- Comments: 0 substantive (only Vercel bot)
- Timeline: created -> merged in 11 seconds, self-merged

## Adversarial Review Effectiveness

Cannot measure — no review comments to cross-reference. Second consecutive PR (after #18) self-merged with zero review.

## Fix-Up Metrics

- Post-merge fix rate: unknown (no subsequent PRs observed yet)
- Pre-merge iteration count: 1 (healthy on surface)
- Fix-up taxonomy: the entire PR is a correctness fix for PR #18. The zip feature shipped in #18 was broken for 100% of seeded photos because the relative-path case was never exercised before merge. Effectively a post-merge fix for PR #18.

## Planning Quality

- Description: complete (Summary, rationale, Test plan all present and thoughtful)
- Scope: clean (single-file, single-concern fix)
- Branch lifetime: seconds
- Planning checklist: narrow fix; not strongly applicable

## Code Quality Signals

- Recurring issue: self-merge with zero review — same pattern as PR #18 (same author, same day, same feature area).
- Bug class: feature shipped untested for the common data shape. Seeded data was 354 rows — the dominant case — yet the test plan in PR #18 was never executed against real data.

## Process Efficiency

- Automation opportunities:
  - An integration test that downloads the zip and asserts entry byte counts (vs HTML 404 fallback) would have caught this before PR #18 merged. PR #19 test plan explicitly calls this out but the checkboxes are unchecked in the merged body.
  - Lint/review rule: fetch(<variable>) where variable can be a relative path should flag in server-side routes.
- Iteration: efficient on the fix itself; the arc (ship #18 -> ship #19 to fix #18 within 90 minutes) is the post-merge fix rate anti-pattern.
- CI: Vercel preview ignored; no CI gates ran.

## Recommendations

1. Treat feature PR merged, follow-up fix PR within hours as a trigger to reinstate Step 3 (local test with seeded data) on the feature PR. 11-second merges indicate flow bypass.
2. For any server route doing fetch(userOrDbProvidedPath), add a preflight test asserting response Content-Type matches expectation. HTML-404-wrapped-as-zip-entry is a silent failure.
3. Minimum gate for bug-fix PRs touching I/O boundaries: pnpm build + one curl against the route before merge.
