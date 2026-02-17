# Post-Mortem: second-brain PR #148 -- Display images in web dashboard via Supabase Storage

**Branch:** feat/display-images-dashboard -> main
**Author:** padminipyapali
**Duration:** 0.23 hours (13 minutes)
**Size:** +587 -14 across 23 files, 2 commits
**Date merged:** 2026-02-17T07:10:49Z

## Summary

Upload MEDIA entry images to Supabase Storage during enrichment for permanent, reliable hosting. Frontend renders images directly from Supabase CDN with native lazy loading. Add GET /entries/:id/media proxy endpoint for legacy Telegram file_path images. Fix pre-existing bug where extracted_text was missing from thread queries.

## Local Review (pre-push)

- **CodeRabbit local:** 3 nitpicks found, 1 fixed (case normalization in extFromContentType), 2 skipped (intentional design decisions). 1 iteration.
- **Adversarial review local:** 3 issues found, 2 fixed (bot token check ordering, 301->302 redirect), 1 accepted (CSS hardcoded color).
- **CI status:** all passed.
- **Shift-left rate:** 60% (6 local catches out of 10 total issues)

## Review Friction (post-push)

- **Review rounds:** 2 (both CHANGES_REQUESTED by CodeRabbit, no human review)
- **Inline comments:** 6 (all from coderabbitai[bot])
- **General comments:** 2 (Vercel deployment, CodeRabbit walkthrough)
- **Human comments:** 0
- **Self-merge:** Yes, no peer review

### Comment categories
| Category | Count | Details |
|----------|-------|---------|
| correctness | 2 | Legacy media URL fallback missing in `entryImageSrc` and `EntryMedia` |
| testing | 2 | Test env leakage, missing timeout/504 test coverage |
| style | 1 | `vi.restoreAllMocks()` should be in afterEach, not inline |
| documentation | 1 | TODO in SearchResults.tsx needs tracked follow-up issue |

### Timeline
- PR created -> first review: 0.09h (5.4 min)
- First review -> merge: 0.13h (7.8 min)
- Total: 0.23h (13.5 min)

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 25%
- **Covered but missed:** Documentation sync (Tier 4) -- SearchResults TODO could have been caught
- **Not covered (new categories):**
  - Test env variable isolation (process.env mutation without afterEach restore)
  - Mock cleanup in afterEach vs. inline (vi.restoreAllMocks)
  - Missing error branch test coverage (timeout/504, non-404/502 paths)
- **Design disagreements (not bugs):** 2 -- CodeRabbit suggested using proxy endpoint for legacy Telegram URLs, but PR explicitly chose to defer this to a backfill script as documented design decision

### Commit classification
| Commit | Headline | Classification |
|--------|----------|---------------|
| 225c18d | Display images in web dashboard via Supabase Storage. Closes #116. | FEATURE |
| 4d3eefa | Address PR review: fix test env leakage and track search TODO. | FIX |

**Fix-up ratio:** 0.50 (1 fix / 2 total)

## Planning Quality

- **Description:** Complete -- Summary with bullet points, key design decisions, files changed, test plan with checklist, local review section
- **Scope:** Clean -- 23 files is large but coherent (storage + enrichment + API + frontend + tests)
- **Branch lifetime:** 0.23 hours (very fast)
- **Redesign indicators:** None
- **Planning checklist:** Entry points covered (new upload flow, legacy fallback, thread panel), performance/cost section via design decisions (free tier, optional storage)

## Code Quality Signals

- **Recurring categories:** testing (2 comments) -- both about test isolation and coverage
- **Fix-up ratio:** 50% -- moderate; 1 of 2 commits was a review fix
- **New unrecorded patterns:**
  - Test env variable isolation (now added to adversarial checklist)
  - Error branch coverage verification (now added to adversarial checklist)

## Process Efficiency

- **Automation opportunities:**
  - Test env isolation check could be a grep pattern (Tier 0): find `delete process.env` without corresponding afterEach restore
  - Error branch coverage could be semi-automated: compare catch blocks in route handlers to test assertions
- **Iteration:** Normal (2 rounds, 1 fix commit addressing 2 of 4 actionable findings)
- **CI status:** All passed (Vercel, CodeRabbit status checks)
- **Unresolved findings at merge:** 2 (restoreAllMocks in afterEach, timeout/504 test coverage)

## Knowledge Updates

1. **adversarial-review.md:** Added 2 new Tier 3 items -- test env variable isolation, error branch test coverage. Updated test-only category mapping.
2. **process-patterns.md:** Added PR #148 to Adversarial Review Gaps (2 new gaps), Iteration Velocity (50% fix-up entry), Review Discipline (3rd instance of merge-with-outstanding-CHANGES_REQUESTED).

## Recommendations

1. **Address the recurring merge-with-CHANGES_REQUESTED pattern.** This is now the 3rd PR (after #136, #145) merged with outstanding bot review findings. Consider a self-imposed rule: dismiss CodeRabbit's CHANGES_REQUESTED with a reason comment before merging, even if the finding is intentionally deferred.

2. **Add test isolation to the adversarial review checklist.** The test-only category previously only checked UTC suffixes. Test env mutations and mock cleanup are common sources of flaky tests. Now added.

3. **Verify error branch coverage for new route handlers.** The timeout (504) and non-404 upstream error (502) paths had no tests. When adding a route with multiple error responses, the adversarial review should enumerate all error branches and verify each has a test case.

4. **Design disagreement handling.** CodeRabbit flagged the deliberate choice to not render legacy Telegram images as a "potential issue." The PR body explicitly documented this as a v1 design decision. Consider adding a CodeRabbit config to reduce noise on intentional design choices, or add inline `<!-- coderabbit:ignore -->` comments where the design decision is documented.
