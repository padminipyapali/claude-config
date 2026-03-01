# Post-Mortem: second-brain PR #313

## PR Summary
- **Title:** Add WONT_FIX status for TODOs
- **Branch:** `feat/wont-fix-status` -> `main`
- **Author:** padminipyapali
- **Created:** 2026-03-01T22:35:13Z
- **Merged:** 2026-03-01T23:22:48Z
- **Time to merge:** 0.8 hours (47 minutes)
- **Size:** 145 LOC (101+/44-), 10 files changed, 2 commits
- **Closes:** #312

## What Changed
Added `WONT_FIX` as a new terminal TODO status alongside `DONE`, allowing users to dismiss TODOs that will not be actioned. Changes spanned the full stack: shared types, DB schema/triggers, API validation, SQL queries (12 filter updates), web hooks, UI components (TodoPanel, EntryCard), CSS styling, and tests.

## Metrics

| Metric | Value |
|--------|-------|
| PR Size | 145 LOC |
| Time to Merge | 0.8h |
| Review Rounds | 1 (CodeRabbit only) |
| Total Comments | 5 |
| Fixup Commit Ratio | 0.50 (1 fixup / 2 total) |
| Adversarial Catch Rate | 1.0 (checklist coverage) |
| Compliance Rate | 0.89 (8/9 steps) |
| Post-merge Fixes | 0 |

## Comment Breakdown

| Category | Count |
|----------|-------|
| Correctness | 1 |
| Style | 3 |
| Testing | 1 |
| Security | 0 |
| Architecture | 0 |
| Performance | 0 |

## Review Friction Analysis

### Timeline
- Created: 22:35 UTC
- CodeRabbit review (CHANGES_REQUESTED): 22:40 UTC (5 min after creation)
- Fixup commit addressing review: 22:53 UTC (13 min after review)
- CodeRabbit re-review: 22:53 UTC (no new actionable comments)
- Merged: 23:22 UTC

### Review Rounds
One round of automated review from CodeRabbit. No human reviewers. The review-to-fix cycle was fast (13 minutes).

### Post-Push Findings (CodeRabbit)
1. **schema.sql (correctness):** DONE<->WONT_FIX trigger transitions did not clear snooze fields (`snoozed_until`, `snoozed_at`), allowing stale snooze metadata on terminal items. **Addressed in fixup commit.**
2. **entry.test.ts (testing):** Suggested adding a runtime-filtering test beyond SQL structure assertion. **Not addressed** (nitpick).
3. **App.css (style):** Duplicate opacity rules for `.done` and `.wont-fix`. **Addressed in fixup commit** (combined selectors).
4. **EntryCard.tsx (style):** Nested ternary for CSS class suggested extraction to utility. **Not addressed** (nitpick).
5. **TodoPanel.tsx (style):** Duplicated terminal-status check could use existing `isTerminal` flag. **Addressed in fixup commit.**

## Adversarial Review Effectiveness

### Checklist Coverage
The local adversarial review reported 11/11 items with grep evidence (Tier 0: 3/3, Tier 1-4: 8/8). However, the one meaningful post-push correctness issue (snooze clearing on terminal transitions) **was covered by the checklist** under the db-sql tier's "derived field consistency" item.

### Execution Gap
The adversarial review's 100% self-reported completion masked an execution gap: the derived-field-consistency check should have flagged the snooze clearing omission in DONE<->WONT_FIX transitions. The checklist says to verify that when a status field changes, all derived/dependent fields are updated consistently. The snooze fields are such derived fields.

**Root cause of the gap:** The adversarial reviewer likely checked the new OPEN->WONT_FIX and IN_PROGRESS->WONT_FIX transitions (which correctly clear snooze) but did not verify the DONE<->WONT_FIX inter-terminal transitions. This is a coverage gap in the *execution* of the checklist item, not a gap in the checklist itself.

### Adversarial Catch Rate Computation
- Total post-push correctness/architecture issues: 1
- Issues covered by adversarial checklist: 1 (derived field consistency)
- **adversarialCatchRate = 1.0** (checklist coverage is complete; execution quality was the gap)

## Fix-Up Analysis

### Commit Classification
| Commit | Type | Description |
|--------|------|-------------|
| `7f4bc53` | Feature | Initial implementation: WONT_FIX across full stack |
| `56101ca` | Fix-up | Address CodeRabbit review: snooze clearing, CSS dedup, isTerminal reuse |

### Fix Attribution
| Step | Fixes |
|------|-------|
| 4a (simplify) | 0 |
| 4b (internal review) | 0 |
| 4c (CodeRabbit local) | 0 (skipped) |
| 4d (adversarial) | 0 |
| Post-push | 3 |

### Fix-Up Taxonomy
- correctness: 1 (snooze clearing)
- style-DRY: 2 (CSS dedup, isTerminal reuse)

## Process Compliance

### Steps Completed (8/9)
- [x] 1 - Plan
- [x] 2a - Implement (functional)
- [x] 2b - Implement (hardening)
- [x] 3 - Test (static verification; Supabase auth blocker documented)
- [x] 4a - Code simplification
- [x] 4b - Internal review (0 findings)
- [ ] 4c - CodeRabbit local (**SKIPPED**: "CLI not available")
- [x] 4d - Adversarial review (11/11 items)
- [x] 5 - Push & PR

### Compliance Issues
1. **4c skipped (CodeRabbit local):** Reason given was "CLI not available." This directly resulted in 3 findings only caught post-push by CodeRabbit remote. The snooze-clearing correctness issue would likely have been caught locally, saving a review round.

## Planning Quality: Complete
- Enumerated all status transitions (OPEN->WONT_FIX, IN_PROGRESS->WONT_FIX, DONE<->WONT_FIX, WONT_FIX->IN_PROGRESS).
- Documented intentional exclusions (weekly/daily summaries, Telegram, todo-buttons).
- DB migration documented with clear "run BEFORE deploying" instruction.
- The plan was thorough but the inter-terminal transitions were not fully validated for derived fields.

## Code Quality Signals
- **Good:** `isTerminal` variable introduced to avoid scattered status checks. Trigger covers all 6 transition paths. Intentional scoping decisions documented in "Not changed" section.
- **Weak:** Initial implementation missed snooze clearing on 2 of 6 transition paths — a common pattern when new status values are added to existing state machines. The DRY violations (duplicate CSS, duplicate terminal check) suggest the hardening pass could be more thorough on style consistency.

## Key Learnings

### 1. Inter-terminal transitions are a blind spot
When a state machine gets a new terminal state, the focus naturally falls on transitions FROM non-terminal states. Transitions BETWEEN terminal states (DONE<->WONT_FIX) are easily overlooked because they seem less important. But derived fields (snooze, timestamps) still need updating on these paths.

**Pattern:** When adding a new terminal state, enumerate not just "how do items enter this state" but also "how do items move between all terminal states" and verify each derived field is handled.

### 2. CodeRabbit local skip has measurable cost
Skipping Step 4c directly correlated with 3 post-push findings (1 correctness, 2 style). The "CLI not available" reason is a persistent infrastructure gap. The shift-left rate for this PR: 0/3 = 0% for the skipped step.

### 3. Self-reported adversarial depth can mask execution gaps
The review reported 11/11 items with grep evidence, yet a checklist-covered issue still escaped. This reinforces that depth metrics need to distinguish between "item executed" (grep ran) and "item effective" (all relevant code paths checked by that grep).

## Recommendations
1. Install CodeRabbit CLI to prevent recurring 4c skips.
2. Add an explicit sub-check to the db-sql derived-field-consistency item: "For new enum values, verify derived fields on ALL transition paths including inter-terminal."
3. Consider adding a Tier 0 automated grep for state machines: when a new status value is added, grep for all existing status checks and verify the new value is handled.
