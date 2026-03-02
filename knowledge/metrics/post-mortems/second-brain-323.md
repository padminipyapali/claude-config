# Post-Mortem: second-brain PR #323

**Title:** Enforce undefined CSS custom property detection via stylelint
**Author:** padminipyapali
**Branch:** `chore/stylelint-undefined-vars` -> `main`
**Created:** 2026-03-02T19:19:55Z
**Merged:** 2026-03-02T19:25:11Z
**Merged by:** padminipyapali (self-merge)
**Size:** 89 additions, 5 deletions, 4 changed files
**Commits:** 1

---

## Step 1: PR Data Summary

| Field | Value |
|-------|-------|
| PR Number | #323 |
| Review Decision | APPROVED |
| Review Rounds | 1 (CodeRabbit auto-approved) |
| Total Comments | 2 (Vercel bot, CodeRabbit summary) |
| Review Comments (inline) | 0 |
| Labels | none |
| Status Checks | CodeRabbit: SUCCESS, Vercel: SUCCESS |

### Changed Files
1. `.stylelintrc.json` — added plugin + rule configuration
2. `package.json` — added `stylelint-value-no-unknown-custom-properties` devDependency
3. `package-lock.json` — lockfile update (auto-generated)
4. `packages/web/src/App.css` — replaced 2x `var(--bg-secondary)` with `var(--surface)`

---

## Step 2: Local Review Extraction

The PR body includes a `## Local Review` section:

- **Steps skipped:** 2b (hardening) -- config-only, no business logic. 3 (Playwright) -- CSS change is dev menu only, visually verified via lint.
- **Internal review findings:** 0 issues found
- **Adversarial review depth:** Tier 0: 18/18 executed (14 SKIP no .ts files, 4 ran against CSS -- all PASS). Tier 1-4: 6/6 applicable checks with evidence.
- **CI status:** `npm run lint`, `npm run build`, `npm test` -- all passed.
- **Deferred items:** none

### Extracted Metrics
- CodeRabbit local findings: 0
- Adversarial local findings: 0
- Internal review findings: 0

---

## Step 2.5: Step Compliance

### Steps Tracked (9 trackable steps)

| Step | Status | Notes |
|------|--------|-------|
| 1 (Plan) | RAN | Summary in PR body |
| 2a (Implement functional) | RAN | Single commit |
| 2b (Implement hardening) | SKIPPED | Config-only, no business logic |
| 3 (Playwright testing) | SKIPPED | CSS change dev menu only, verified via lint |
| 4a (Code simplification) | RAN | Part of adversarial review |
| 4b (Internal review) | RAN | 0 issues found |
| 4c (CodeRabbit local) | NOT EXPLICITLY MENTIONED | PR body does not list 4c; only mentions adversarial review and internal review. Counted as not run. |
| 4d (Adversarial review) | RAN | Tier 0: 18/18, Tier 1-4: 6/6 |
| 4e (CI checks) | RAN | lint, build, test all passed |
| 5 (Push & PR) | RAN | PR created and merged |

**Steps run:** 1, 2a, 4a, 4b, 4d, 4e, 5 = 7
**Steps skipped:** 2b, 3 = 2
**Compliance rate:** 7/9 = 77.8%

### Skip Assessment: GOOD

Both skips are justified:
- **2b (hardening):** Config-only PR with no input validation, no async, no user-facing business logic. Hardening pass would produce an empty checklist.
- **3 (Playwright):** No UI rendering changes that would be visible in the browser. The CSS change fixes background color on dev-menu elements, verified functionally via the lint rule itself (stylelint catches undefined vars). No meaningful Playwright test could add value beyond what lint already validates.

---

## Step 2.7: Step Timing

No `## Step Timing` section present in the PR body.

**Inferred timing from Git/GitHub timestamps:**
- Authored: 2026-03-02T19:15:22Z
- PR created: 2026-03-02T19:19:55Z
- Committed (force push/amend): 2026-03-02T19:22:07Z
- CodeRabbit review: 2026-03-02T19:23:32Z
- Merged: 2026-03-02T19:25:11Z
- **Total elapsed:** ~10 minutes (author to merge)
- **Time to merge (PR created to merged):** 5 minutes 16 seconds

---

## Step 3: Review Friction Analysis

| Metric | Value |
|--------|-------|
| Review rounds | 1 |
| Human review comments | 0 |
| Bot review comments | 2 (Vercel deployment, CodeRabbit summary) |
| Inline review comments | 0 |
| CHANGES_REQUESTED | 0 |
| CodeRabbit verdict | APPROVED |
| Self-merged | Yes |
| Time to merge | 0.09 hours (5 min) |

**Friction assessment:** Zero friction. Single-commit, single-review-round PR with auto-approval from CodeRabbit. No human review requested or received. Self-merge is acceptable for a small config/tooling PR.

---

## Step 4: Adversarial Review Effectiveness

### Review Comment Cross-Reference

There were **0 inline review comments** (human or bot) on this PR. CodeRabbit auto-approved without findings. The only bot comment was the walkthrough summary.

### adversarialCatchRate Computation

**adversarialCatchRate: "unmeasured"**

Rationale: There were 0 post-push findings and 0 pre-push findings. With no findings to measure against, the catch rate cannot be computed. The adversarial review reported all items PASS/SKIP, and no review comments challenged any aspect of the code. There is no evidence to compute a ratio from.

### CodeRabbit Tool Warning

CodeRabbit's Stylelint tool failed because the new plugin was not installed in CodeRabbit's environment (`Could not find "stylelint-value-no-unknown-custom-properties"`). This is expected -- CodeRabbit runs its own stylelint installation, not the project's `node_modules`. This is informational, not a finding.

---

## Step 5: Planning Quality

| Dimension | Assessment |
|-----------|------------|
| PR description completeness | Good -- clear summary, motivation, files changed |
| Scope focus | Excellent -- single concern (stylelint plugin + fix) |
| Branch naming | Correct (`chore/stylelint-undefined-vars`) |
| Branch lifetime | ~10 minutes |
| Motivation stated | Yes -- "catches a bug class that escaped manual review in PRs #164, #317, and #320" |
| Entry points enumerated | N/A (config change, no user-facing entry points) |

**Planning quality: "minimal"** -- appropriate for a small, well-scoped tooling PR. The PR description adequately explains the "why" (closing a 3-occurrence gap) and the "what" (plugin + fix), without over-engineering the planning for a sub-100 LOC change.

---

## Step 6: Code Quality Signals (Fix-Up Metrics)

### 1. Post-Merge Fix Rate: 0.0%
No commits after merge touching the same files. The merge commit (db417ae) is the latest on `origin/main`. Clean.

### 2. Pre-Merge Catch Rate by Step
| Step | Catches |
|------|---------|
| 4a (simplification) | 0 |
| 4b (internal review) | 0 |
| 4c (CodeRabbit local) | 0 |
| 4d (adversarial) | 0 |
| Post-push | 0 |

**Total findings: 0.** No issues found at any stage. The code was correct on first write.

### 3. Pre-Merge Iteration Count: 1
Single commit, single review round. No review-fix-review cycles.

### 4. Fix-Up Taxonomy
All categories: 0. No fixes of any kind required.

### Legacy Fix-Up Commit Ratio: 0.0%
0 fix commits / 1 total commit = 0%.

---

## Step 7: Process Efficiency

### Automation Potential
This PR IS the automation. It promotes a manual adversarial review checklist item (Tier 0 check 0.18: CSS custom property validation) to automated lint-time enforcement. Future CSS PRs in this project will catch undefined `var()` references without any manual review step.

### Iteration Assessment
**Ideal outcome.** Single commit, zero findings, zero fix-ups, 5-minute merge. This is the target for small, focused tooling PRs.

### CI Results
- Vercel: SUCCESS (deployment skipped -- not a server change)
- CodeRabbit: SUCCESS (approved)

### Historical Gap Closure
This PR resolves a bug class documented in 3 prior post-mortems:
- PR #164: `var(--border)`, `var(--surface-hover)` undefined
- PR #317: `var(--bg-secondary)` undefined in dev menu
- PR #320: `var(--font-sans)` undefined (should be `--font-body`)

The pattern was first identified in PR #164 (2026-02-20), confirmed as a repeat in PR #317 (2026-03-02), and resolved 7 hours later in PR #323. The full lifecycle: identification -> checklist item -> lint automation took 10 days.

---

## Step 8: Knowledge Updates

### Process Patterns Updated
1. **Adversarial Review Gaps (line 68):** Updated CSS custom property validation entry from "New gap" to "RESOLVED" with attribution to PR #323.
2. **Automation Opportunities (line 112):** Added partial resolution note for stylelint custom property plugin.
3. **Iteration Velocity:** Added new entry documenting PR #323 as the ideal "gap closure" PR pattern.

### New Patterns Identified
- **Gap closure PR pattern:** When a post-mortem finding recurs 3+ times, the ideal resolution is a focused, standalone tooling PR that promotes the manual check to automated enforcement. PR #323 exemplifies this: 89 LOC, 5-minute merge, 0% fix-up ratio, and permanently eliminates the finding category for future PRs. This contrasts with bundling the fix into a feature PR (PR #228 anti-pattern).

---

## Metrics Summary

```json
{
  "project": "second-brain",
  "prNumber": 323,
  "title": "Enforce undefined CSS custom property detection via stylelint",
  "dateMerged": "2026-03-02T19:25:11Z",
  "reviewRounds": 1,
  "totalComments": 2,
  "commentCategories": {
    "security": 0, "correctness": 0, "architecture": 0,
    "style": 0, "performance": 0, "testing": 0,
    "documentation": 0, "other": 2
  },
  "localReview": {
    "coderabbitFindings": 0, "coderabbitFixed": 0,
    "coderabbitIterations": 0, "adversarialFindings": 0,
    "adversarialFixed": 0
  },
  "adversarialCatchRate": "unmeasured",
  "fixupCommitRatio": 0.0,
  "fixupMetrics": {
    "postMergeFixRate": 0.0,
    "preMergeCatchRateByStep": {
      "4a": 0, "4b": 0, "4c": 0, "4d": 0, "postPush": 0
    },
    "preMergeIterationCount": 1,
    "fixupTaxonomy": {
      "validation": 0, "a11y": 0, "defensive-coding": 0,
      "correctness": 0, "dead-code": 0, "test-quality": 0,
      "documentation": 0, "style": 0, "infrastructure": 0
    }
  },
  "timeToMergeHours": 0.09,
  "planningQuality": "minimal",
  "prSize": 89,
  "stepCompliance": {
    "stepsRun": ["1", "2a", "4a", "4b", "4d", "4e", "5"],
    "stepsSkipped": ["2b", "3"],
    "skipReasons": "2b (hardening) — config-only, no business logic. 3 (Playwright) — CSS change is dev menu only, visually verified via lint.",
    "complianceRate": 0.78,
    "skipAssessment": "good"
  },
  "stepTiming": null
}
```

---

## Verdict

**Exemplary gap-closure PR.** PR #323 is the ideal outcome for the post-mortem feedback loop: a repeated finding (3 occurrences over 10 days) is permanently resolved by a focused tooling PR that promotes manual review to automated enforcement. Zero friction, zero findings, zero fix-ups, 5-minute lifecycle. The step skips (2b hardening, 3 Playwright) are well-justified for a config-only change.

The only process note: CodeRabbit local (step 4c) was not explicitly mentioned in the Local Review section. For tooling PRs this is low-risk, but recording "4c: N/A -- config-only" would be more precise than omitting it.
