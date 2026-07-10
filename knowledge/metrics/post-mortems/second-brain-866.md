# POST-MORTEM: second-brain PR #866 — feat(sources): data_sources registry table with env-var seeding and fallback (PR-A of #860)

Branch: feat/data-source-registry → main | Author: padminipyapali | merged 2026-07-10
Size: +596 -23 across 7 files, 2 commits | Part of #860 (PR-A of 2 — do not auto-close)

## Summary of the change
Migration `030-data-sources.sql` adds a `data_sources` registry table (kind UNIQUE, spreadsheet_id, enabled, description). New `DataSourceRegistry` service resolves a spreadsheet id per kind (enabled registry row → env-var fallback → null) with a 5-minute per-kind cache and a never-throw contract that tolerates the table not existing yet. Boot idempotently seeds env-configured sources (`ON CONFLICT (kind) DO NOTHING`, fire-and-forget with per-await error handling). `HouseholdSheetService` now resolves its id lazily via the registry, byte-identical when no row exists. Sets up Telegram-driven source connection in PR-B.

## Local review (pre-push)
- CodeRabbit: not tracked — CLI timed out server-side on both attempts (IDs 089da9d9, a2d47793). Skipped with justification.
- Adversarial (fresh-context critic): 1 blocking finding, 1 fixed. Verdict APPROVE.
  - Blocking: disabled-row semantics were untested and undocumented. A disabled registry row (`enabled = TRUE` filter) must fall through to the deliberately-lower env-var layer, not disconnect the source (disabling "household" while `GOOGLE_KIDS_SHEET_ID` is set must NOT disconnect it). Fix added an intent comment on the query plus two tests (disabled row with, and without, an env fallback).
  - 2 non-blocking findings deliberately deferred to PR-B and logged on #860: negative-cache TTL on transient errors; post-boot connect requiring a restart. These are scope decisions, not misses.
- Shift-left: 100% of in-scope findings caught locally, 0 post-merge escapes.

## Step compliance
Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9). Skipped: 4b (CodeRabbit) — server-side timeout. Compliance 88.9%. Skip assessment: good (adversarial + 17 targeted tests covered; no post-merge escapes).

## Step timing
Not tracked (no `## Step Timing` section).

## Review friction (post-push)
Review rounds: 1 (no CHANGES_REQUESTED; no GitHub reviews). Comments: 0 inline, 0 general (excluding Vercel bot). Self-merged under the local-review gate. Timeline: PR opened 07-09, merged 07-10 (~27.7h created→merged; branch dev started 07-09).

## Adversarial review effectiveness
The one blocking finding is an in-checklist class (untested branch of a conditional — the disabled-row arm — and error/degradation semantics). Caught pre-push, fixed, re-verified. adversarialCatchRate = 1.0 (evidence-backed). Critic-ran-with-findings shade, not null.

## Fix-up metrics
- Post-merge fix rate: 0.0% (0 post-merge fix commits — ideal).
- Pre-merge catch by step: 4d (adversarial) = 1; all others 0.
- Pre-merge iteration count: 1.
- Fix-up taxonomy: test-quality 1 (the fix added the missing tests + intent comment for the disabled-row semantic).
- Legacy fix-up ratio: 50% (1 fix / 2 commits) — the single pre-push critic fix.

## Planning quality
Complete. Body has Summary, Review, Tests, Deploy note (manual migration), and Performance & Cost Impact (one registry query per kind per 5 min, cached; no new LLM calls). Explicitly scoped as PR-A of 2 with "do not auto-close #860" and non-blocking findings pre-committed to PR-B — clean multi-PR discipline. No redesign/revert commits.

## Code quality signals
Strong process pattern: the service was designed with a never-throw contract that tolerates the migration not being applied yet ("until the table exists, every path falls back to env vars"), making the code safe to deploy in either order relative to the manual Supabase migration. This directly mitigates the project's known "manual migrations lag deploys" failure mode. New capturable pattern: ship a DB-backed feature ahead of its hand-applied migration by making the read path degrade to the prior source (env vars) when the table is absent.

## Recommendations
1. Adopt the "missing-table → fall back to prior source, never throw" contract as the default whenever a feature introduces a hand-applied migration — it decouples deploy order from migration order and removes the class of 500s the manual-migration lag causes.
2. Continue pre-registering non-blocking critic findings on the tracking issue for the next PR in a multi-PR sequence (done well here on #860) — keeps the current PR focused without losing the findings.
3. CodeRabbit CLI server-side double-timeouts recurred again (both attempts). Consider a shorter per-attempt budget before falling back rather than burning 60+ min twice.
