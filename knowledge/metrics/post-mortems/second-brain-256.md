# Post-Mortem: second-brain PR #256 — Add changelog from merged PRs to /brief and dashboard

**Branch:** feat/changelog -> main | **Author:** padminipyapali | **Duration:** 1.4h
**Size:** +842 -14 across 20 files, 6 commits
**Date merged:** 2026-02-26T00:29:00Z

## Summary

New GitHubService fetches recent merged PRs via GitHub GraphQL API with 30-minute in-memory cache and stale-on-error fallback. Dashboard gets a collapsible "build N" changelog row, /brief and morning brief Telegram messages gain a "What's New" section, and /sb command gains changelog context. Graceful degradation: everything works without GITHUB_TOKEN.

## Local Review (pre-push)

- **Code simplifier:** 2 actionable found, 2 fixed (redundant interface property, inconsistent import style)
- **Internal review:** 6 issues found, 5 fixed (1 already fixed by code simplifier)
- **CodeRabbit:** NOT RUN (no .coderabbit.yaml in this project)
- **Adversarial review:** Listed as "pending" at PR creation time
- **Playwright:** N/A (component returns null without live API data)
- **CI:** Build passes, 917 tests pass, lint clean for changed files

**Shift-left rate:** Internal review caught 8 issues locally. CodeRabbit caught 16 issues post-push. Local-only catch rate: 8 / (8 + 16) = 33%. This is significantly below the target of ~80%.

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4d, 5 (6/8)
- **Steps skipped:** 4b (CodeRabbit), 4c (adversarial review)
- **Skip reasons:** 4b: no .coderabbit.yaml in project; 4c: adversarial review listed as pending at PR creation
- **Compliance rate:** 75%
- **Skip assessment:** BAD — CodeRabbit found 16 comments across 3 CHANGES_REQUESTED rounds post-push. The adversarial checklist covers 75% of those findings. Both skipped steps would have caught significant issues.

## Review Friction (post-push)

- **Review rounds:** 4 (3 CHANGES_REQUESTED, 1 COMMENTED before merge)
- **Comments:** 16 inline comments, 0 human comments
- **Categories:** security: 3, correctness: 4, architecture: 2, style: 3, performance: 1, testing: 0, documentation: 2, other: 1
- **Timeline:** created -> first review: 0.1h | first review -> merge: 1.3h | total: 1.4h
- **Self-merge:** YES (mergedBy == author, no human reviews)

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 75% (12/16 findings covered by existing checklist items)
- **Covered but missed (12):**
  - XML escape in changelog context (Tier 2 + Tier 0 check 0.10)
  - Prompt injection risk x2 (Tier 2: escape user content in AI prompts)
  - Focus-visible keyboard accessibility gap (Tier 0 check 0.4 / a11y)
  - Guard relativeDate against NaN (Tier 0 check 0.6)
  - vi.restoreAllMocks in afterEach (Tier 3: test env isolation)
  - Missing error path test (Tier 3: error branch coverage)
  - Dead mock code (Tier 3: test mock target verification)
  - Hardcoded repo coordinates (Tier 3: env var validation)
  - JSDoc overstates scope (Tier 4: documentation sync)
  - Env override documentation (Tier 4: documentation sync)
  - TAG_PREFIXES type gap (Tier 3: new union member completeness)
- **Not covered (4):**
  - Unconditional computation of changelog instruction (performance micro-optimization)
  - Duplicate test setup (test DRY)
  - Inconsistent test description style (naming convention)
  - GraphQL API field ordering verification (external API contract)
- **Fix commits:** 3 of 6 total (50% fix-up ratio) — HIGH

## Planning Quality

- **Description:** COMPLETE (Summary, Test Plan, Local Review sections all present)
- **Scope:** Clean — single feature concern, no scope creep
- **Branch lifetime:** 1.4 hours
- **Redesign indicators:** None (no revert/undo commits)
- **Planning checklist:** Entry points enumerated, graceful degradation covered

## Code Quality Signals

- **Recurring issues:** Security (3 comments) — prompt injection was flagged across 3 rounds, indicating the initial fix was incomplete. The adversarial review's prompt injection checks need strengthening for LLM context injection (not just XML escape but also semantic prompt injection).
- **Fix-up ratio:** 50% (3 fix commits / 6 total) — HIGH
- **New unrecorded patterns:**
  1. **Prompt injection depth.** XML escaping is necessary but not sufficient for LLM context injection. PR titles in `<recent_changes>` blocks are treated as data by the XML parser but can still influence LLM behavior through adversarial phrasing. The checklist should distinguish XML-structural injection from semantic/prompt-level injection.
  2. **Focus-visible parity.** When adding a new interactive element to a CSS file that already has focus-visible styles on sibling elements, verify the new element has the same focus-visible treatment. This is a "pattern sibling" check specific to CSS.

## Process Efficiency

- **Automation opportunities:**
  - The `.coderabbit.yaml` file should be added to this project. Skipping CodeRabbit local review dropped the shift-left rate from ~80% to 33%.
  - Focus-visible CSS checks could be added to Tier 0 grep patterns.
- **Iteration:** HIGH FRICTION (4 rounds, 3 CHANGES_REQUESTED before merge)
- **CI status:** Vercel preview deployed successfully. No other CI checks configured.

## Recommendations

1. **CRITICAL: Add .coderabbit.yaml to second-brain project.** This PR skipped CodeRabbit local because the config file was missing. CodeRabbit found 16 issues post-push that local review would have caught. This is a recurring gap — the PR body itself notes "not run (no .coderabbit.yaml in this project)."

2. **CRITICAL: Complete adversarial review before PR creation.** The adversarial review was "pending" at PR time. 75% of post-push findings were covered by existing checklist items. Running the adversarial review pre-push would have shifted ~12 of 16 findings left.

3. **Strengthen prompt injection checks.** The checklist has "escape user content in AI prompts" but the current wording focuses on XML structural injection. Add a sub-item: "When injecting external data into LLM context, verify the system prompt treats it as read-only reference data, not as instructions to follow."

4. **Add focus-visible CSS sibling check.** When adding interactive elements to a CSS file, grep for existing `:focus-visible` rules and ensure the new element has matching treatment.
