# Post-Mortem: second-brain PR #361

**Title:** Deprioritize completed TODOs in search results
**Date merged:** 2026-03-04T13:09:45Z
**Author:** padminipyapali
**Branch:** fix/deprioritize-completed-todos-search -> main
**PR size:** 100 additions, 20 deletions (120 LOC)
**Files changed:** 2 (search.ts, search.test.ts)
**Time to merge:** 9 minutes (0.15 hours)
**Closes:** #360

---

## 1. PR Summary

This PR LEFT JOINs `todo_status` in both FTS and vector search SQL queries to retrieve TODO completion status, then applies a 0.1x multiplicative penalty to DONE/WONT_FIX TODOs in the RRF merge step. This pushes completed TODOs to the bottom of search results without excluding them entirely. Three tests were added covering DONE, WONT_FIX, and non-TODO entries.

## 2. Local Review Extraction

From the PR body `## Local Review` section:

- **Steps skipped:** 3-Playwright (backend-only, files: search.ts, search.test.ts)
- **Hardening pass:** N/A — no routes, no UI, no new async paths
- **Internal review findings:** 0 issues
- **CodeRabbit findings:** skipped (sub-100 LOC logic change)
- **Adversarial review depth:** Tier 0: 5/5 executed with grep output. Tier 1 (async-ts): 2/2 PASS. Tier 2 (db-sql): 3/3 PASS. Universal: pattern siblings checked.
- **Playwright testing:** N/A (backend-only)
- **CI status:** build passed, all 63 tests passed
- **Deferred items:** none

## 2.5. Step Compliance Extraction

**Steps skipped line:** "3-Playwright (backend-only, files: search.ts, search.test.ts)"

**Steps run:** 1, 2a, 2b, 3 (unit tests), 4a, 4b, 4d, 4e, 5
**Steps skipped:** 3-Playwright (justified — backend-only), 4c-CodeRabbit (claimed sub-100 LOC logic change)

**Compliance rate:** 8/10 = 80%

**Assessment:** Playwright skip is fully justified for a backend-only change (search.ts, search.test.ts). The CodeRabbit skip is debatable: while the PR body claims "sub-100 LOC logic change," the actual PR is 120 LOC (100 additions + 20 deletions). CodeRabbit's post-push review DID find 2 actionable issues (mock row completeness, test intent/setup mismatch), both of which led to a fix commit. This is evidence that the skip cost real value.

## 2.7. Step Timing Extraction

No `## Step Timing` section present in PR body.

## 3. Review Friction Analysis

### Review rounds
- **1 round** of CHANGES_REQUESTED (by CodeRabbit bot)

### Comment classification
| Category | Count | Details |
|----------|-------|---------|
| Testing | 2 | Mock row shape completeness (nitpick), test intent/setup mismatch (minor) |
| **Total** | **2** | |

### Timeline
| Event | Timestamp | Delta |
|-------|-----------|-------|
| PR created | 13:00:47 UTC | — |
| CodeRabbit review (CHANGES_REQUESTED) | 13:04:42 UTC | +4 min |
| Fix commit 76acaa6 | 13:07:43 UTC | +3 min |
| CodeRabbit re-review (no actionable comments) | ~13:08 UTC | +1 min |
| PR merged | 13:09:45 UTC | +1 min |

Total cycle time: 9 minutes. Single review round with fast turnaround.

## 4. Adversarial Review Effectiveness

### Local adversarial review claims
- Tier 0: 5/5 executed with grep output
- Tier 1 (async-ts): 2/2 PASS
- Tier 2 (db-sql): 3/3 PASS
- Universal: pattern siblings checked

### Post-push findings (CodeRabbit)
1. **Mock row shape completeness** (nitpick/trivial): `makeFtsRow` returns a partial row missing fields consumed by search.ts (`parent_entry_id`, `media_url`, `extracted_text`). Category: test-quality.
2. **Test intent/setup mismatch** (potential issue/minor): Non-TODO penalty test used null `todo_status` but claimed to test "regardless of todo_status." Fix: use explicit DONE/WONT_FIX statuses on THOUGHT entries. Category: test-quality.

### Catch rate analysis
- Post-push findings: 2
- Pre-push findings that would have caught them: 0 (the adversarial review focused on production code, not test quality)
- **Adversarial catch rate: 0.0** (0 of 2 post-push findings were covered by pre-push adversarial review)

Both findings are in the test-quality category, which is a known adversarial review blind spot (see process-patterns.md: "local review caught real bugs but is weak on test code quality").

## 5. Planning Quality Assessment

- **Issue linked:** Yes (#360)
- **Description completeness:** Good — explains the LEFT JOIN approach, RRF penalty mechanism, and test coverage
- **Scope:** Well-scoped, focused on a single concern (search result ranking for completed TODOs)
- **Redesign indicators:** None — the fix commit addressed test quality, not a design change
- **Planning quality:** **complete**

## 6. Code Quality Signals

### Fix commit classification
| Commit | Attribution | Category | Description |
|--------|------------|----------|-------------|
| 76acaa6 | Post-push (CodeRabbit review) | test-quality | Complete mock row shape and strengthen non-TODO penalty test |

### Fix-up metrics
1. **Post-merge fix rate:** 0.0% (no post-merge fix commits)
2. **Pre-merge catch rate by step:** 4a: 0, 4b: 0, 4c: 0 (skipped), 4d: 0, post-push: 2
3. **Pre-merge iteration count:** 2 (initial + 1 fix round)
4. **Fix-up taxonomy:** test-quality: 2

### Fix-up commit ratio
1 fix commit / 2 total commits = 0.50 (50%)

### New patterns
No new unrecorded patterns. Both findings fall under the existing "adversarial review weak on test code quality" pattern documented in process-patterns.md.

## 7. Process Efficiency

### Automation potential
- The mock row shape completeness finding could be caught by a lint rule or test helper that validates mock shapes match the actual SQL SELECT columns. This is a pattern that recurs across test files.
- The test intent/setup mismatch is harder to automate but could be flagged by a review checklist item: "For each test title containing 'regardless' or 'any', verify the fixture data exercises the full range."

### Iteration count
- 2 iterations (initial push + CodeRabbit fix). This is normal for a PR with bot-only review.

### CI results
- Build: passed
- Tests: all 63 passed
- Vercel: ignored (backend-only)
- CodeRabbit status check: SUCCESS

### CodeRabbit skip cost
CodeRabbit was skipped locally ("sub-100 LOC logic change") but ran post-push and found 2 actionable issues. The skip created a post-push round-trip that could have been avoided. However, the 9-minute total merge time suggests the overhead was minimal for this PR.

## 8. Knowledge Updates

### Process patterns
No new patterns to add. The findings reinforce the existing "adversarial review weak on test code quality" pattern. The CodeRabbit skip at 120 LOC (borderline) is a minor data point but not a new pattern.

### Adversarial review gaps
No new gaps identified. Both findings are in the test-quality category, a known weak area.

## 9. Structured Metrics

```json
{
  "project": "my_mind_evolved",
  "prNumber": 361,
  "title": "Deprioritize completed TODOs in search results",
  "dateMerged": "2026-03-04T13:09:45Z",
  "reviewRounds": 1,
  "totalComments": 2,
  "commentCategories": {
    "security": 0,
    "correctness": 1,
    "architecture": 0,
    "style": 0,
    "performance": 0,
    "testing": 1,
    "documentation": 0,
    "other": 0,
    "a11y": 0
  },
  "localReview": {
    "coderabbitFindings": null,
    "coderabbitFixed": null,
    "coderabbitIterations": null,
    "adversarialFindings": 0,
    "adversarialFixed": 0
  },
  "adversarialCatchRate": 0.0,
  "fixupCommitRatio": 0.5,
  "fixupMetrics": {
    "postMergeFixRate": 0.0,
    "preMergeCatchRateByStep": {
      "4a": 0,
      "4b": 0,
      "4c": 0,
      "4d": 0,
      "postPush": 2
    },
    "preMergeIterationCount": 2,
    "fixupTaxonomy": {
      "validation": 0,
      "a11y": 0,
      "defensive-coding": 0,
      "correctness": 0,
      "dead-code": 0,
      "test-quality": 2,
      "documentation": 0,
      "style": 0,
      "infrastructure": 0
    }
  },
  "timeToMergeHours": 0.15,
  "planningQuality": "complete",
  "prSize": 120,
  "stepCompliance": {
    "stepsRun": ["1", "2a", "2b", "3", "4a", "4b", "4d", "4e", "5"],
    "stepsSkipped": ["3-Playwright", "4c"],
    "skipReasons": "3-Playwright: backend-only (search.ts, search.test.ts). 4c-CodeRabbit: skipped (sub-100 LOC logic change).",
    "complianceRate": 0.8,
    "skipAssessment": "Playwright skip justified (backend-only). CodeRabbit skip debatable -- 120 LOC is above stated threshold and CodeRabbit found 2 issues post-push."
  },
  "stepTiming": null
}
```

## 10. Key Takeaways

1. **Fast, well-scoped PR.** 120 LOC, 2 files, 9 minutes to merge. The scope was tight and the implementation was clean.
2. **CodeRabbit skip at borderline LOC cost 2 post-push findings.** The PR claimed "sub-100 LOC logic change" but was actually 120 LOC. CodeRabbit found 2 test-quality issues post-push. For this PR the cost was low (3 min fix), but the pattern of underestimating LOC to justify skips is worth noting.
3. **Test quality remains the adversarial review's blind spot.** Both findings were about test fixture completeness and test intent alignment — areas where the adversarial review consistently underperforms. This is the same pattern observed across multiple prior PRs.
4. **0% shift-left rate for post-push findings.** Neither finding was caught pre-push. All review value came from CodeRabbit's post-push automated review.
