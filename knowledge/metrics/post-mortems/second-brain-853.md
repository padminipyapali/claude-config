# POST-MORTEM: second-brain PR #853 — fix(db): pin search_path=public on the shared pool so writes stop crashing.

Branch: `fix/...` → `main` | Author: padminipyapali (self-merged) | ~56s open→merge
Size: +77 -8 across 3 files, 1 commit (squash `2495b6e`, merged as `334ec12`)
Closes #851. Severity: **P0** — every DB write was crashing in production.

## Incident summary

Every message that writes to the DB crashed — the user's notes, a reflection, and an
earlier "comment" all silently failed with the generic **"Sorry, something went wrong."**
Reproducing the write path with the real thrown error logged revealed Postgres
`42P01 relation "users" does not exist` at the FIRST DB write (`findOrCreateUser`),
BEFORE `createEntry` is reached — so no row was ever written (a crash, **not data loss**).

**Root cause:** `DATABASE_URL` uses the Supabase TRANSACTION pooler (pgbouncer, :6543),
which does not apply the role's default `search_path=public` per session → empty
search_path → unqualified queries can't resolve to `public.*`. Tables + 1077 entries +
4 users were all intact in `public`. Purely a connection setting.

## Fix

Pin `search_path` via the libpq STARTUP param `options: "-c search_path=public"` on the
shared pool, extracted into a testable pure `buildPoolConfig` (`db-pool.ts`). The startup
param travels in the pgbouncer startup packet and is applied per *physical* connection, so
it survives transaction-mode pooling — unlike a per-transaction `SET search_path`, which
pgbouncer resets between checkouts. 3 files: `server.ts` (+2/-8 delegates to the builder),
`db-pool.ts` (+32 new builder), `db-pool.test.ts` (+43, 5 tests).

## LOCAL REVIEW (pre-push)

- CodeRabbit (4b): **not run**.
- Adversarial (4c): fresh-context critic RAN and returned **SHIP**, 0 in-scope blockers.
  Field-by-field confirmed the pool-config extraction dropped NO prior setting
  (ssl/rejectUnauthorized-by-isProduction, keepAlive, connectionTimeoutMillis,
  idleTimeoutMillis, min all verbatim); the only delta was the added startup param +
  connectionString passthrough.
- Shift-left: n/a (no post-merge escapes).

## STEP COMPLIANCE

- Steps run: 1, 2, 3, 4c, 5 — Steps skipped: 4b (CodeRabbit). complianceRate 0.8889 (8/9).
- skipAssessment: **neutral** (no post-merge escape related to the skip; the fresh-context
  critic + real-pooler multi-connection validate-first were the gate).

## STEP TIMING

Not tracked (no Step Timing section in the PR body). Open→merge wall-clock ~56s; the whole
local loop ran pre-push (branch advance + self-merge only on GitHub).

## ADVERSARIAL / VALIDATE-FIRST EFFECTIVENESS

- adversarialCatchRate = **null (critic-ran-clean)** — NOT a fabricated/measured 1.0. The
  critic ran clean (0 in-scope blockers caught, 0 escaped), so caught/(caught+escaped) is
  undefined → null (same shade as #830/#841/#848/#850). This is honest: the fix was correct
  on first implementation; reporting 1.0 would manufacture catch-effectiveness the gate
  never demonstrated.
- **Validate-first was the standout gate.** The fix was PROVEN against the REAL transaction
  pooler with **8 concurrent physical connections**, all reporting `search_path=public`,
  unqualified `SELECT count(*) FROM users` → 4 / `FROM entries` → 1077, and the previously-
  failing `findOrCreateUser` succeeding with no dup — proving the startup param persists per
  physical connection through pgbouncer (the subtle risk a single-connection test masks).

## FIX-UP METRICS

- postMergeFixRate: **0.0** — no later PR fixes this PR's files; #853 landed in one feature
  commit (0 discrete fix commits). Follow-up #852 (route maintenance scripts through
  `buildPoolConfig`) is a SEPARATE hardening task, not a fix of a #853 defect.
- preMergeIterationCount: 1 (healthy). Legacy fixupCommitRatio: 0.0.

## PLANNING QUALITY

Complete. A read-only diagnostic trace FIRST ruled out the calendar/Google-token path (the
user correctly pushed back that a journal note shouldn't touch Google) and pinned the crash
to the unguarded `findOrCreateUser`/`createEntry` DB call — persist is correctly first and
enrichment is fire-and-forget, so the crash was the DB call itself, not lost-after-enrichment.

## KNOWLEDGE UPDATES

- `database-patterns.md` (Connection Management): (1) Supabase transaction pooler drops
  the role default search_path → pin with the libpq startup param, not a per-txn SET;
  (2) validate a pooler/connection-setting fix against the real pooler with multiple
  concurrent connections.
- `process-patterns.md` (Correctness Gaps): (3) STRENGTHENED the crash-masking entry —
  a repro that LOGS the real thrown error is the fast path under a masking generic catch;
  (4) NEW — when a "save" silently fails, check persist ORDER + whether the persist call is
  guarded before suspecting data loss.

## RECOMMENDATIONS

1. Ship follow-up #852 so every `pg.Pool` (maintenance scripts included) goes through
   `buildPoolConfig` — otherwise the same 42P01 recurs on any script that connects directly.
2. Consider logging the real thrown error (not just the generic reply) at the channel
   adapter's catch, so the next masked crash is diagnosable from logs without a repro.
3. The masking generic-catch pattern is now a 6-PR recurrence (#828/#835/#840/#849/#850/#855
   + #853) — the standing lesson (don't mask; log the real error) should be enforced, not
   just documented.
