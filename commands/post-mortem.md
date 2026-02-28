---
description: Analyze a merged PR's full development loop and extract process-level learnings
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
argument-hint: [PR number or "recent"]
---

Analyze the full development loop of a merged PR and extract process-level learnings. Updates the shared knowledge base and regenerates the self-improvement dashboard.

## Resolve the PR

1. If `$ARGUMENTS` is a number, use it as the PR number.
2. If `$ARGUMENTS` is "recent" or empty, run:
   ```bash
   gh pr list --state merged --limit 1 --json number --jq '.[0].number'
   ```
3. Validate the PR exists and is merged:
   ```bash
   gh pr view $PR --json state --jq '.state'
   ```
   If not `MERGED`, report the current state and stop.
4. Check `~/.claude/knowledge/metrics/post-mortem-metrics.json` — if this PR number + project combo already exists in the `prs` array, report "Already analyzed" and stop.

## Step 1: Gather PR Data

Fetch all data:

```bash
# Full PR metadata with commits, reviews, comments, and CI status
gh pr view $PR --json number,title,body,author,createdAt,mergedAt,mergedBy,headRefName,baseRefName,reviewDecision,additions,deletions,changedFiles,commits,reviews,comments,labels,state,statusCheckRollup

# Get repo name for API calls
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# Inline review comments (per-file, per-line)
gh api repos/$REPO/pulls/$PR/comments --paginate
```

Parse and organize:
- Group inline comments by `pull_request_review_id` to reconstruct review rounds.
- Sort all events chronologically to build a timeline.
- Determine the project name from the repo name or current directory.

## Step 2: Local Review Extraction

Parse the PR body for the `## Local Review` section (added by the code review loop). Extract:
- **CodeRabbit findings count**: total issues found locally, total fixed, number of review iterations.
- **Adversarial review findings count**: total issues found locally, total fixed.
- **CI status**: passed or failures fixed.

If the section is missing (older PRs or PRs created before the local review flow), set all local review fields to `null` — don't default to 0. Null means "not tracked," 0 means "tracked and none found."

## Step 2.5: Step Compliance Extraction

Parse the PR body for the `Steps skipped:` line in the `## Local Review` section. Extract step compliance data:

1. If the line says "none" → all 9 trackable steps ran (1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5). Set `complianceRate = 1.0`.
2. If the line lists specific steps → extract step numbers and reasons. Compute `complianceRate = stepsRun / 9`.
3. If the `Steps skipped:` line is missing → set `stepCompliance` to `null` (older PR, not tracked).

The 9 trackable steps are: 1 (plan), 2a (implement-functional), 2b (implement-hardening), 3 (test), 4a (simplification), 4b (CodeRabbit), 4c (adversarial), 4d (CI), 5 (push+PR). Steps 2a and 5 are always implicitly run if the PR exists.

Store the extracted data for use in Step 9 (metrics append).

## Step 2.7: Step Timing Extraction

Parse the PR body for the `## Step Timing` section. This section is added by the orchestrator and records per-step durations from the dev flow.

Expected format:
```
## Step Timing
| Step | Duration | Notes |
|------|----------|-------|
| 1a-1c Plan | ~15 min | 2 adversarial review rounds |
| 2a Implement (functional) | ~5 min | |
| 2b Implement (hardening) | ~3 min | |
| 3 Test | ~2 min | |
| 4a-4e Review | ~43 min | CodeRabbit was bottleneck |
| 5 Push/PR | ~2 min | |
| **Total** | **~67 min** | |
```

Extract:
- Per-step durations in minutes (parse "~N min", "~N hours", "Nh Mm" formats).
- Total duration.
- Notes (especially bottleneck identification).

If the section is missing (older PRs), set `stepTiming` to `null`.

Store the extracted data for use in Step 9 (metrics append).

## Step 3: Review Friction Analysis

Compute these metrics:
- **Review rounds**: Count distinct `CHANGES_REQUESTED` events. Rounds = N changes_requested + 1 (or 1 if only APPROVED/COMMENTED).
- **Comment volume**: Total inline comments + general comments. Exclude bot comments (author login containing `[bot]`).
- **Comment categories**: Classify each substantive comment as one of: `security`, `correctness`, `architecture`, `style`, `performance`, `testing`, `documentation`, `other`. Use keyword matching on the comment body:
  - security: "security", "injection", "user scoping", "auth", "permission", "XSS", "CSRF"
  - correctness: "null", "undefined", "crash", "race", "bug", "error", "wrong", "incorrect", "missing check"
  - architecture: "extract", "service", "route", "thin", "layer", "refactor", "abstraction", "separation"
  - style: "naming", "convention", "format", "readability", "DRY", "simplify", "cleanup"
  - performance: "performance", "slow", "cache", "optimize", "N+1", "query", "index"
  - testing: "test", "coverage", "assertion", "mock", "fixture"
  - documentation: "doc", "comment", "README", "description", "JSDoc"
  - other: anything that doesn't match above
- **Timeline**: Time from PR created to first review, first review to merge, total elapsed.
- **Self-merge check**: If `mergedBy == author` and no reviews exist, flag as "no peer review."

## Step 4: Adversarial Review Effectiveness

1. Read `~/.claude/knowledge/adversarial-review.md` to load the checklist.
2. For each review comment that requested a concrete change:
   - Does this issue class appear in the adversarial review checklist? If yes → "covered but missed" (the adversarial review should have caught this).
   - Is this issue class absent from the checklist? If yes → "not covered" (a potential addition).
3. Calculate pre-push catch rate: what percentage of issues the checklist could have caught.
4. Look for "Address PR review" or "review" fix commits. Count fix commits vs. feature commits to measure iteration overhead.
5. **Skip assessment** (uses Step 2.5 data): Cross-reference skipped steps against post-push review findings to classify each skip:
   - **bad**: Post-merge review found issues that a skipped step would have caught. Mapping:
     - Skipped lint/test (step 3) + review found a11y/style/correctness issue → bad
     - Skipped adversarial (step 4c) + review found issue in adversarial checklist → bad
     - Skipped CodeRabbit (step 4b) + CodeRabbit found issues post-push → bad
   - **good**: No post-merge issues related to any skipped step.
   - **neutral**: Can't determine (e.g., no review happened, CodeRabbit rate-limited, no review data).

## Step 5: Planning Quality Assessment

Analyze:
- **PR description completeness**: Does the body contain: Summary, Test Plan sections?
- **Scope creep**: Branch lifetime > 48 hours? More than 500 lines changed? Commits with divergent themes?
- **Redesign indicators**: Commit messages with "revert", "undo", "redesign", "try different approach".
- **Planning checklist coverage** (from CLAUDE.md Planning Requirements): entry points enumerated? Performance/cost section?

## Step 6: Code Quality Signals

- **Recurring comment categories**: Any category with 2+ comments is a recurring pattern.
- **Fix-up metrics** (CRITICAL — compute all 4 accurately):

  **Metric 1: Post-merge fix rate** — the true quality failure rate.
  1. After this PR merges, check for follow-up commits/PRs in the same feature area that fix issues introduced by this PR. Use: `gh pr list --state merged --search "fix" --json number,title,mergedAt` and filter for PRs merged within 48h that reference this PR or the same files.
  2. Compute: `postMergeFixRate = post_merge_fix_commits / total_commits` (0.0–1.0). 0.0 is ideal.
  3. If > 0.0, flag: "Post-merge fixes needed — quality escaped all review gates."

  **Metric 2: Pre-merge catch rate by step** — which review step caught each issue.
  1. Get all commits: `gh pr view $PR --json commits --jq '.commits[].messageHeadline'`
  2. Classify each commit as **fix** if message contains "fix", "address", "resolve", "review", "feedback", "nit" (case-insensitive); **feature** otherwise.
  3. For each fix commit, attribute to the step that caught it:
     - `4a` (simplification) — if fix addresses code simplification
     - `4b` (internal review) — if fix addresses cross-file consistency, interface compliance, caller safety
     - `4c` (CodeRabbit) — if fix addresses CodeRabbit finding
     - `4d` (adversarial) — if fix addresses adversarial review finding
     - `post-push` — if fix was made after PR creation in response to GitHub review
  4. Compute per-step: `stepCatchRate = fixes_caught_by_step / total_fix_commits`.
  5. **Report the attribution** so the user can verify.

  **Metric 3: Pre-merge iteration count** — review-fix-review round trips.
  1. Count the number of review-fix-review cycles before the PR was merged. Each cycle = a CHANGES_REQUESTED event followed by fix commits.
  2. Include both local review iterations (pre-push) and GitHub review iterations (post-push).
  3. Interpret: 1 = healthy, 2 = normal for large PRs, 3+ = high friction or mental model mismatch.

  **Metric 4: Fix-up taxonomy** — classify each fix by category.
  1. For each fix commit (from Metric 2), classify the fix into one of: `validation`, `a11y`, `defensive-coding`, `correctness`, `dead-code`, `test-quality`, `documentation`, `style`, `infrastructure` (marker commits, gitignore, etc.).
  2. Report the distribution. Recurring categories across PRs indicate systemic gaps.
  3. Exclude `infrastructure` fixes from quality metrics — they inflate ratios without reflecting code quality.
- **New patterns**: Cross-reference review comments against `~/.claude/knowledge/INDEX.md` topic files. Are there patterns not already captured?

## Step 7: Process Efficiency

- **Automation potential**: Could any feedback have been caught by the adversarial review, a linter, or a CI check?
- **Iteration assessment**: 1 round = efficient, 2 rounds = normal, 3+ rounds = high friction.
- **CI check results**: Were there failed CI checks during the PR lifecycle?

## Step 8: Update Knowledge

1. **Read** `~/.claude/knowledge/process-patterns.md`.
2. For each finding from Steps 2-7:
   - New process pattern? → Add to `process-patterns.md` under the matching section.
   - Adversarial review gap? → Add to `~/.claude/knowledge/adversarial-review.md` with source comment.
   - New code pattern not already in a topic file? → Add to the relevant `~/.claude/knowledge/*.md` file.
   - Check for duplicates before adding. If a pattern already exists, strengthen it with new context.
3. Use format: `- **Pattern name.** Description. <!-- Source: post-mortem, [project] #[PR], [date] -->`

## Step 9: Append Metrics & Regenerate Dashboard

1. Read `~/.claude/knowledge/metrics/post-mortem-metrics.json`.
2. Append a new entry to the `prs` array:
   ```json
   {
     "project": "<project-name>",
     "prNumber": <number>,
     "title": "<PR title>",
     "dateMerged": "<ISO 8601>",
     "reviewRounds": <count>,
     "totalComments": <count>,
     "commentCategories": {
       "security": <n>, "correctness": <n>, "architecture": <n>,
       "style": <n>, "performance": <n>, "testing": <n>,
       "documentation": <n>, "other": <n>
     },
     "localReview": {
       "coderabbitFindings": <n or null>,
       "coderabbitFixed": <n or null>,
       "coderabbitIterations": <n or null>,
       "adversarialFindings": <n or null>,
       "adversarialFixed": <n or null>
     },
     "adversarialCatchRate": <0-1 float>,
     "fixupCommitRatio": <0-1 float>,
     "fixupMetrics": {
       "postMergeFixRate": <0-1 float>,
       "preMergeCatchRateByStep": {
         "4a": <n>,
         "4b": <n>,
         "4c": <n>,
         "4d": <n>,
         "postPush": <n>
       },
       "preMergeIterationCount": <n>,
       "fixupTaxonomy": {
         "validation": <n>, "a11y": <n>, "defensive-coding": <n>,
         "correctness": <n>, "dead-code": <n>, "test-quality": <n>,
         "documentation": <n>, "style": <n>, "infrastructure": <n>
       }
     },
     "timeToMergeHours": <number>,
     "planningQuality": "<complete|partial|missing>",
     "prSize": <additions + deletions>,
     "stepCompliance": {
       "stepsRun": ["1", "2", "3", "4a", "4b", "4c", "4d", "5"],
       "stepsSkipped": [],
       "skipReasons": "",
       "complianceRate": <0-1 float>,
       "skipAssessment": "<good|bad|neutral|null>"
     },
     "stepTiming": {
       "planMinutes": <number or null>,
       "implementMinutes": <number or null>,
       "testMinutes": <number or null>,
       "reviewMinutes": <number or null>,
       "pushMinutes": <number or null>,
       "totalMinutes": <number or null>,
       "bottleneck": "<step name or null>",
       "notes": "<free text or null>"
     }
   }
   ```
   Note: `localReview` fields are `null` for PRs created before the local review flow was added. This distinguishes "not tracked" from "tracked, zero findings." The `stepCompliance` object is `null` for older PRs that predate step compliance tracking. The `stepTiming` object is `null` for older PRs that predate timing tracking. The `fixupMetrics` object is `null` for older PRs that predate the 4-metric framework. The legacy `fixupCommitRatio` field is retained for backward compatibility with existing dashboard charts.
3. Write back the JSON file.
4. **Regenerate the dashboard**: Read `~/.claude/knowledge/metrics/dashboard.html`, find the `const METRICS_DATA = ` line, replace the entire JSON object with the updated metrics data. This embeds the fresh data into the HTML file so opening it shows all PRs.

## Step 10: Save Raw Report & Generate Report

**Save the report to disk:**
1. Create `~/.claude/knowledge/metrics/post-mortems/` if it doesn't exist.
2. Write the full report to `~/.claude/knowledge/metrics/post-mortems/{project}-{prNumber}.md`.
3. This preserves the narrative analysis (which issues were covered but missed, recommendations, etc.) for future pattern analysis across PRs.

**Print a structured report to the conversation:**

```
POST-MORTEM: [project] PR #[number] — [title]
Branch: [head] → [base] | Author: [author] | [duration]
Size: +[additions] -[deletions] across [changedFiles] files, [N] commits

LOCAL REVIEW (pre-push)
  CodeRabbit: N findings, N fixed (N iterations) [or "not tracked"]
  Adversarial: N findings, N fixed [or "not tracked"]
  Shift-left rate: X% of total issues caught locally [or "n/a"]

STEP COMPLIANCE
  Steps run: 1, 2, 3, 4a, 4b, 4c, 4d, 5 (8/8)
  Steps skipped: none
  Compliance rate: 100%
  Skip assessment: n/a
  [or when steps are skipped:]
  Steps run: 1, 2, 5 (3/8)
  Steps skipped: 3 (lint+test), 4a-4d (code review loop) — reason: "minimal change"
  Compliance rate: 37.5%
  Skip assessment: neutral (no review data to compare against)
  [or when not tracked:]
  Step compliance: not tracked (pre-dates tracking)

STEP TIMING
  | Step | Duration | Notes |
  |------|----------|-------|
  | Plan | ~Xm | ... |
  | Implement | ~Xm | ... |
  | Test | ~Xm | ... |
  | Review (4a-4e) | ~Xm | bottleneck: ... |
  | Push/PR | ~Xm | ... |
  | Total | ~Xm | ... |
  [or "not tracked" for older PRs]

REVIEW FRICTION (post-push)
  Review rounds: N (M CHANGES_REQUESTED before APPROVED)
  Comments: N inline, M general
  Categories: { security: N, correctness: N, architecture: N, ... }
  Timeline: created → first review: Xh | first review → merge: Yh | total: Zh

ADVERSARIAL REVIEW EFFECTIVENESS
  Pre-push catch potential: X%
  Covered but missed: [list with tier references]
  Not covered (new categories): [list]

FIX-UP METRICS
  Post-merge fix rate: X% (N post-merge fix commits — 0% is ideal)
  Pre-merge catch rate by step:
    4a (simplify): N fixes | 4b (internal): N fixes | 4c (CodeRabbit): N fixes
    4d (adversarial): N fixes | post-push: N fixes
  Pre-merge iteration count: N (1=healthy, 2=normal, 3+=high friction)
  Fix-up taxonomy: { validation: N, a11y: N, defensive-coding: N, correctness: N,
    dead-code: N, test-quality: N, documentation: N, style: N, infrastructure: N }
  Legacy fix-up ratio: X% (N fix / M total commits — retained for trend comparison)

PLANNING QUALITY
  Description: [complete / partial / missing]
  Scope: [clean / scope creep / redesign detected]
  Branch lifetime: X hours
  Planning checklist: [covered / gaps: list]

CODE QUALITY SIGNALS
  Recurring issues: [list]
  New unrecorded patterns: [list or "none"]

PROCESS EFFICIENCY
  Automation opportunities: [list or "none"]
  Iteration: [efficient / normal / high friction]
  CI status: [all passed / failures: list]

KNOWLEDGE UPDATES
  [Files updated and entries added/strengthened]

RECOMMENDATIONS
  [Ranked, actionable process improvements based on findings]
```

## Step 11: Auto-Commit

The `~/.claude/` directory changes (metrics JSON, dashboard HTML, knowledge files) will be auto-committed per the Config Repo Auto-Sync rule in CLAUDE.md. No special handling needed here.
