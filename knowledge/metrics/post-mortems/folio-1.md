# Post-Mortem: folio PR #1 -- Scaffold Folio: full MVP with auth, accounts, dashboard, activity, and realtime

**Branch:** feat/scaffolding -> main
**Author:** padminipyapali + Claude Opus 4.6
**Duration:** ~10.9 hours (created 2026-02-23T07:15:46Z, merged 2026-02-23T18:11:53Z)
**Size:** +17,990 -0 across 72 files, 14 commits

---

## LOCAL REVIEW (pre-push)

Extensive local review was performed across all applicable steps:

| Step | Findings | Fixed | Details |
|------|----------|-------|---------|
| 4a (Code Simplification) | 2 bugs + refactoring | All | Infinite re-render loop, duplicate hook call, -243 lines, shared form styles |
| 4b (Internal Review) | 13 issues | 13 | Auth listener leak, trigger INSERT-only, recompute grouping, household loading, useNetWorth error overwrite, useBalanceHistory loading stuck, SectionList extraData, save button offline, loadHousehold error, infinite re-render, duplicate hook |
| 4c (CodeRabbit) | 38 findings | 10 bugs fixed | Net-worth trend order, backfill guard, try/catch in hooks/screens, UTC date fix, archive error handling, empty name guard, filter null user, ownerMemberId validation, stale closure fix, segments type. 28 nitpicks deferred. |
| 4d (Adversarial Review) | 13 findings | 10 fixed | 1 CRITICAL (UPDATE RLS), 3 HIGH (createHousehold RPC, accounts store clear, date parsing), 6 MEDIUM (join-household try/catch, useAccounts selectors, useMemo, SET search_path, todayDateString, redundant index), 3 LOW deferred to V2 |

**Total local catches:** ~66 issues found locally, ~36 substantive fixes applied pre-push.

### Shift-Left Analysis

The local review loop was exceptionally thorough for this PR:
- **CodeRabbit local:** 38 findings total (10 bugs + 28 nitpicks)
- **Adversarial review:** 13 findings (10 fixed, 3 deferred)
- **Internal review:** 13 issues found and fixed
- **Code simplification:** 2 bugs + structural improvements

Post-push: Copilot review surfaced 2 inline comments + 8 suppressed (low-confidence). Of the 10 total:
- 2 surfaced: absolute path in settings.json (portability), TrendChart UTC date parsing (correctness)
- 8 suppressed: UPDATE RLS WITH CHECK (security x2), partial unique index + upsert mismatch (correctness), recorded_at in upsert (correctness), created_at overwritten on upsert (correctness), net_worth_snapshots Realtime missing (correctness), todayDateString duplication (style x2)

**Post-push findings addressed:** All 10 Copilot findings were addressed in commit 3381cf0 (the final fix commit). This includes the 8 "suppressed" low-confidence findings -- they were all legitimate.

**Shift-left rate:** ~86% (66 local / (66 + 10 post-push) = 86.8%). However, the 8 "suppressed" Copilot findings being legitimate means the local review missed some issues the adversarial checklist should have caught.

---

## STEP COMPLIANCE

| Step | Status | Notes |
|------|--------|-------|
| 1 (Plan) | Run | Full plan with product spec |
| 2 (Implement) | Run | 9 feature commits |
| 3 (Test locally) | Partial | TypeScript passed. Playwright skipped (no dev server). ESLint skipped (not configured). |
| 4a (Simplification) | Run | 2 bugs, -243 lines |
| 4b (Internal review) | Run | 13 issues found |
| 4c (CodeRabbit) | Run | 38 findings |
| 4d (Adversarial review) | Run | 13 findings, 2 rounds |
| 4e (CI/lint) | Partial | TypeScript only, ESLint not configured yet |
| 5 (Push + PR) | Run | PR created with full Local Review section |

**Steps skipped:** 3-Playwright (no dev server infrastructure), 4e-lint (ESLint not configured for scaffolding PR)
**Compliance rate:** 6 of 8 fully run = 75% (2 partially run due to infrastructure gaps, not negligence)
**Skip assessment:** neutral -- Playwright and ESLint infrastructure didn't exist yet for the scaffolding PR

---

## REVIEW FRICTION (post-push)

- **Review rounds:** 1 (Copilot COMMENTED, no CHANGES_REQUESTED)
- **Comments:** 2 inline (Copilot), 0 general (no human review)
- **Suppressed comments:** 8 low-confidence findings from Copilot (all legitimate)
- **Categories:** { security: 2 (RLS WITH CHECK), correctness: 6 (UTC parsing, upsert mismatch, recorded_at, created_at, Realtime gap, date duplication), style: 1 (todayDateString duplication), other: 1 (absolute path) }
- **Timeline:**
  - Created -> first review: ~8.5 hours (Copilot reviewed against commit 1e4c666, before final fix)
  - First review -> merge: ~2.5 hours
  - Total: ~10.9 hours
- **Self-merge check:** Self-merged with Copilot COMMENTED review only. No human peer review.

---

## ADVERSARIAL REVIEW EFFECTIVENESS

**Pre-push catch potential:** High -- the adversarial review was very active (13 findings including 1 CRITICAL).

**Covered but missed (adversarial should have caught):**
1. **UPDATE RLS WITH CHECK clauses** -- The adversarial review caught the missing UPDATE RLS *policy* (CRITICAL) but didn't add WITH CHECK clauses. Copilot caught this. The adversarial checklist has RLS checks but not WITH CHECK specifically.
2. **Net worth Realtime subscription gap** -- The adversarial review didn't flag that `useRealtime` only subscribes to `accounts` and `balance_snapshots` but not `net_worth_snapshots`. This is a cross-file consistency issue (Tier 4 pattern siblings).
3. **Partial unique index vs. ON CONFLICT mismatch** -- Schema defines partial unique index (WHERE source = 'manual'), but client upsert targets `account_id,snapshot_date` which Postgres can't match. This is a DB correctness issue that the Tier 2 DB checks should cover.
4. **recorded_at not set in upsert** -- Same-day correction doesn't update the timestamp, making activity feed ordering wrong. Trigger behavior analysis gap.
5. **created_at overwritten in recompute_net_worth upsert** -- Loses original creation time. Semantic correctness gap.

**Not covered (new categories):**
1. **Absolute path in hook config** -- Portability concern for `.claude/settings.json`. Not a code correctness issue per se, but affects other developers. Could be a Tier 0 grep for absolute paths.
2. **Partial unique index + ON CONFLICT compatibility** -- New DB-specific gap: when using partial unique indexes, the adversarial checklist should verify ON CONFLICT targets can resolve against the index.

**Fix commits:** 5 of 14 total (35.7% fix-up ratio)
- Commit classification:
  - **Feature:** c09c98d (scaffold), 5a5c233 (schema), 2f87977 (auth), ae2eaf6 (accounts), 956efe7 (balance), 0b0a851 (dashboard), 27a9a8f (activity), fa0703d (realtime), b2684e0 (project setup) = 9
  - **Fix:** 18d0751 (steps 4a+4b), 3c2c256 (step 4c), 043adda (step 4d), 1e4c666 (step 4d additional), 3381cf0 (PR review) = 5

---

## PLANNING QUALITY

- **Description:** Complete -- Summary, Key Design Decisions, Local Review section, Test Plan all present.
- **Scope:** Massive (17,990 additions, 72 files) -- this is the full MVP scaffold. By nature, scaffolding PRs are large. No scope creep or redesign detected.
- **Branch lifetime:** ~20 hours (first implementation commit authored 2026-02-22T11:37:11, final fix commit 2026-02-23T08:04:07)
- **Redesign indicators:** None. All commits are additive or fix-oriented. No "revert" or "try different approach" messages.
- **Planning checklist:** Complete product spec in docs/PRODUCT_SPEC.md, key design decisions documented in docs/DECISIONS.md, entry points covered.

---

## CODE QUALITY SIGNALS

**Recurring categories:**
- **Date/timezone correctness** (3 findings): UTC midnight parsing in TrendChart, local date vs UTC in accounts service, todayDateString duplication. This is the single most recurring bug class across all projects.
- **RLS security completeness** (2 findings): UPDATE policy missing, WITH CHECK clauses missing. Security reviews need to be mechanical, not judgmental.
- **Upsert semantics** (2 findings): Partial index incompatibility, recorded_at not refreshed on update.

**Fix-up ratio:** 35.7% (5 fix / 14 total)
- This is BELOW the 50% threshold -- a good result for a PR this size (17,990 LOC).
- Only 1 of 5 fix commits was post-push review driven (3381cf0). The other 4 were local review fixes.
- **Local fix-up ratio:** 4/14 = 28.6% (fixes from internal review loop)
- **Post-push fix-up ratio:** 1/14 = 7.1% (fixes from GitHub review)

**New patterns not already captured:**
1. **Partial unique index + ON CONFLICT compatibility** -- Postgres cannot infer a partial unique index from ON CONFLICT target. Need full unique index or different upsert strategy.
2. **WITH CHECK clauses on UPDATE RLS policies** -- USING filters which rows can be updated, but without WITH CHECK, the new values aren't constrained.
3. **Scaffolding PRs should set up ESLint and Playwright infrastructure** -- Deferring lint/test infrastructure to "later" means the first real PR also lacks it.

---

## PROCESS EFFICIENCY

**Automation potential:**
- ESLint with Supabase-aware rules would catch some DB pattern issues.
- A Tier 0 grep for absolute paths in config files would catch the settings.json issue.
- A Tier 2 DB check for "partial unique index + ON CONFLICT target compatibility" would catch the upsert gap.

**Iteration assessment:** Efficient -- 1 Copilot review round (COMMENTED, not CHANGES_REQUESTED). All substantive fixes were pre-push. The single post-push fix commit addressed review findings comprehensively.

**CI status:** TypeScript passed. ESLint not configured. No test suite yet.

---

## KNOWLEDGE UPDATES

1. **database-patterns.md:** Added partial unique index + ON CONFLICT compatibility pattern.
2. **database-patterns.md:** Added WITH CHECK clause requirement for UPDATE RLS policies.
3. **process-patterns.md:** Added scaffolding PR observations.
4. **adversarial-review.md:** Flagged new gaps (partial index, WITH CHECK, absolute paths).

---

## RECOMMENDATIONS

1. **Add WITH CHECK to the adversarial review DB checklist.** UPDATE RLS policies without WITH CHECK allow value mutation to unauthorized households. This is a security-tier check that should be mechanical (Tier 2).

2. **Add partial unique index vs. ON CONFLICT verification to the adversarial review DB checklist.** When a schema uses partial unique indexes, verify that client-side upsert ON CONFLICT targets can actually match the index.

3. **For scaffolding PRs, set up lint + test infrastructure early.** Steps 3 and 4e were partially skipped because the infrastructure didn't exist. Including ESLint setup in the scaffolding PR ensures all subsequent PRs have the full review loop available.

4. **The 86% shift-left rate on a 17,990 LOC PR is excellent.** The local review loop (4a through 4d) caught 66 issues before push. This validates the process for large greenfield PRs. The remaining 10 post-push findings were edge cases that the adversarial checklist didn't fully cover.

5. **Date/timezone correctness remains the #1 recurring bug class.** Despite being well-documented in knowledge files and the adversarial checklist, it still produced 3 findings. The Tier 0 grep catches `new Date()` without `Z` but doesn't catch local-midnight vs UTC-midnight semantic issues in date string construction.

6. **Consider splitting future scaffold PRs.** 17,990 LOC in one PR is the largest analyzed to date. While the process handled it well (35.7% fix-up, 86% shift-left), smaller PRs historically achieve better shift-left rates. Even splitting into "schema + backend" and "frontend" would improve reviewability.

---

*Generated: 2026-02-23 | Source: post-mortem, folio #1*
