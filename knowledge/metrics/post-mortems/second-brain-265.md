# Post-Mortem: second-brain PR #265

## Metadata
- **PR:** #265 — Remove query cards from dashboard feed
- **Author:** padminipyapali
- **Branch:** fix/remove-query-cards-from-feed -> main
- **Created:** 2026-02-26T06:10:07Z
- **Merged:** 2026-02-26T06:29:46Z
- **Time to merge:** 0.33 hours (20 minutes)
- **Size:** 134 LOC (111 additions, 23 deletions), 7 files, 4 commits
- **Closes:** #223

## Summary

Excluded QUERY entries from the main dashboard feed (alongside TODOs that already have a dedicated panel), removed the QUERY filter chip from the feed header, and updated product/research agent specs. Query entries remain accessible via search and thread history.

## Commit Analysis

| # | SHA | Message | Type |
|---|-----|---------|------|
| 1 | d88977c | Remove query cards from dashboard feed, keep searchable. | feature |
| 2 | 7ffaafa | Update docs to reflect query cards removed from feed. | feature (docs) |
| 3 | be7fba0 | Address PR review: reconcile stale doc references to QUERY in feed. | fix |
| 4 | 688e88c | Add GitHub Actions workflow for auto-fixing PR review comments. | out-of-scope |

- **Feature commits:** 2 (d88977c, 7ffaafa)
- **Fix commits:** 1 (be7fba0 — addresses CodeRabbit review findings)
- **Out-of-scope commits:** 1 (688e88c — adds auto-review-fix workflow, unrelated to feed changes)
- **Fix-up ratio:** 50% (1 fix out of 2 substantive feature commits; excluding out-of-scope commit)

## Review Friction

- **Review rounds:** 2 (1 CHANGES_REQUESTED + 1 COMMENTED)
- **Human comments:** 0
- **Bot comments:** 4 (all CodeRabbit)
- **Comment classification:**
  - Documentation: 4 (stale doc inconsistencies, missing entry point test coverage in spec)
  - Correctness: 0
  - Security: 0
  - Architecture: 0
  - Style: 0
  - Performance: 0
  - Testing: 0
  - Other: 0
- **Timeline:** Created -> First review (4 min) -> Merge (16 min after review)

## Local Review Extraction

From PR body:
- **Steps skipped:** 3-Playwright (N/A, removal-only), 4a-4c (diff under 50 LOC, pure removal)
- **Internal review findings:** 0 issues
- **Adversarial review findings:** 1 note (stale docs), fixed in follow-up commit
- **Playwright testing:** N/A (removal-only change, no new UI)
- **CI status:** lint + build + tests all pass
- **CodeRabbit local:** not run (skipped as part of 4a-4c skip)

## Step Compliance

| Step | Status | Notes |
|------|--------|-------|
| 1 (plan) | skipped | Small removal, no plan documented |
| 2 (implement) | run | Code changes on feature branch |
| 3 (test) | run | lint + build + tests passed; Playwright N/A |
| 4a (simplification) | skipped | "diff under 50 LOC" |
| 4b (internal review) | run | 0 findings |
| 4c (CodeRabbit) | skipped | "diff under 50 LOC" |
| 4d (adversarial) | run | 1 note found and fixed |
| 5 (push + PR) | run | PR created with full Local Review section |

- **Steps run:** 2, 3, 4b, 4d, 5 (5 of 8)
- **Steps skipped:** 1, 4a, 4c (3 of 8)
- **Compliance rate:** 62.5%
- **Skip assessment:** acceptable — The actual code diff (excluding docs) was a clean removal under 50 LOC. The adversarial review was run, which is the most critical step. However, the total diff including docs was 134 LOC, which technically exceeds the 50 LOC threshold. The 4c skip was justified in practice — all 4 post-push findings were documentation inconsistencies, exactly the category that CodeRabbit local review would have caught.

## Adversarial Review Effectiveness

The adversarial review (step 4d) was run and found 1 issue (stale docs), which was fixed pre-push. However, CodeRabbit found 4 additional documentation inconsistencies post-push:

1. **Spec inconsistency: exclusion mechanism vs research_initiated flag** — The async-research-agent spec had contradictory text about how QUERY exclusion works (global type exclusion vs row-level flag). This is a documentation-sync issue. **Covered by adversarial checklist?** Yes — Tier 4 "Documentation sync" item covers this. **Verdict: covered but missed.**

2. **Missing entry point coverage in test plan** — The test plan only validated Telegram-created QUERY exclusion, not web compose/reply paths. **Covered by adversarial checklist?** Partially — Tier 5 "enumerate ALL entry points" is a planning check, not code review. **Verdict: not covered (spec-level, not code-level).**

3. **Contradictory feed rules in PRODUCT_SPEC.md** — Line 393 said QUERY excluded, but Line 462 still listed QUERY as part of feed focus. **Covered by adversarial checklist?** Yes — Tier 4 "Documentation sync" and "doc count/state consistency on removal PRs" gap. **Verdict: covered but missed.**

4. **Same as #3 in product-spec.md** — Duplicate file with same inconsistency. **Verdict: covered but missed (same class as #3).**

- **Pre-push catch rate:** 25% (1 of 4 total documentation findings caught by adversarial review)
- **Adversarial review gap:** The adversarial review found 1 stale doc reference but did not perform a comprehensive grep for all QUERY references in docs. A mechanical "grep for removed entity in all docs" step would have caught all 4 findings.

## Planning Quality

- **Summary:** Present and clear (4 bullet points)
- **Test plan:** Present and thorough (6 manual test items)
- **Scope creep:** Yes — commit 4 (688e88c) adds an unrelated GitHub Actions workflow for auto-fixing PR review comments. This is out-of-scope for the stated PR purpose.
- **Redesign indicators:** None — the implementation matches the stated goal cleanly.
- **Planning quality:** partial — No formal plan step documented (step 1 skipped), but the scope was clear and well-defined. The out-of-scope commit is the only planning gap.

## Code Quality Signals

- **Net deletion PR:** This is primarily a removal PR (removing QUERY from feed filters and CSS), with documentation updates. Clean, focused changes.
- **Recurring patterns:** Documentation inconsistency on removal PRs is a known pattern (see PR #191 post-mortem: "Doc count/state consistency on removal PRs"). This PR exhibits the same pattern.
- **Out-of-scope commit:** The auto-review-fix workflow (commit 4) should have been in a separate PR.

## Process Efficiency

- **Total time:** 20 minutes from creation to merge
- **Review cycle:** Very efficient — 4 min to first review, 16 min to address and merge
- **Automation potential:** A pre-push grep for the removed entity name across all docs would have caught all 4 post-push findings
- **CI results:** All passed

## Key Findings

1. **Documentation sync on removal PRs is a systemic gap (3rd occurrence).** PRs #191, #265, and likely others show the same pattern: when removing a type/entity from the system, docs that reference it in other contexts don't get updated comprehensively. The adversarial review catches some but not all instances.

2. **Out-of-scope commits bundled into focused PRs.** Commit 4 (688e88c, auto-review-fix workflow) is completely unrelated to removing QUERY cards from the feed. This inflates the diff and muddies the PR's purpose.

3. **"Under 50 LOC" skip was borderline.** The code-only diff was under 50 LOC, but total diff was 134 LOC. The distinction between "code LOC" and "total LOC" is a recurring ambiguity in skip justifications (see also PR #259 post-mortem).

4. **Pre-push catch rate for docs-only findings is consistently low.** When post-push findings are exclusively documentation-related, the shift-left rate drops because most local review steps focus on code correctness, not documentation completeness.

## Recommendations

1. **Mechanical grep for removed entities in docs.** When a PR removes a type/entity, run: `grep -rn "QUERY" docs/ --include="*.md"` and review each match. This takes <2 minutes and would have caught all 4 findings.

2. **Keep out-of-scope changes in separate PRs.** The GitHub Actions workflow should have been its own PR. One concern per PR.

3. **Clarify LOC threshold:** "Under 50 LOC" should measure total diff (additions + deletions), not a subjective subset. This is already noted in process-patterns.md from PR #250.
