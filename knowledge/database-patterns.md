# Database / PostgreSQL Patterns

Cross-project learnings for SQL schema design, indexing, and the node-postgres driver.

## Schema Design

- **Bidirectional invariant enforcement.** If a child only makes sense for a specific parent type: (1) trigger on CHILD INSERT/UPDATE verifies parent type, (2) trigger on PARENT UPDATE blocks type change while child exists. Missing either creates orphaned rows.
- **Canonicalized bidirectional links.** For bidirectional links between entities, store with `CHECK (source_id < target_id)` constraint. This prevents duplicate pairs (A→B and B→A) without application-level dedup. The service always sorts the two IDs before inserting. <!-- Source: my_mind_evolved-slip-box DECISIONS -->
- **Metadata JSONB for type-specific context.** When storing type-specific data (response metadata, bot context, channel-specific fields), use a JSONB column rather than type-specific columns. Avoids schema bloat and is extensible to future types. Trade-off: weaker DB-level type safety, but the TypeScript layer enforces shape. <!-- Source: second-brain DECISIONS -->

## Query Patterns

- **Scope all DB lookups by user_id.** Channel-local IDs (e.g., Telegram message_id) are NOT globally unique. Without user scoping, user A's data can match user B's query.
- **User scoping on correlated subqueries.** Always include `AND c.user_id = e.user_id` even if the data model guarantees it — defense in depth.
- **FTS + vector search are complementary, not alternatives.** FTS excels at exact/stemmed word matching but fails on conceptual similarity ("colors" won't find "yellow", "blue"). Use FTS as primary with vector similarity fallback when FTS returns 0 results. This avoids the cost of embedding every query while catching semantic matches.
- **Conditional SELECT for type-specific columns in cross-type queries.** When a column is only meaningful for one entry type (e.g., `extracted_text` for MEDIA), use `CASE WHEN type = 'MEDIA' THEN extracted_text ELSE NULL END` in cross-type result sets (search, related entries). This avoids transferring large unused text for non-matching types. Single-entry display queries can still select unconditionally. <!-- Source: PR review, second-brain #162, 2026-02-19 -->
- **FTS: use OR semantics for personal knowledge retrieval.** `plainto_tsquery` (AND) fails when users search with metadata terms — proper nouns, category labels, or concept names that don't appear verbatim in the stored text (e.g., "Bene Gesserit fear mantra" for an entry containing only the Litany text). Use `websearch_to_tsquery` with OR-joined terms so entries matching ANY term surface, ranked by `ts_rank_cd`. AND semantics is only appropriate when false positives are dangerous (e.g., matching TODOs for completion).

## Connection Management

- **Set `connectionTimeoutMillis` on every pg.Pool.** The default of `0` means connection attempts wait indefinitely. A single slow connection (transient network issue, cold start after idle) makes the entire service appear dead with no error logged. Use `connectionTimeoutMillis: 5_000` (5s) — normal connections establish in 50-200ms, so 5s has no impact on healthy operations but ensures hung attempts fail fast. <!-- Source: BUG-023, second-brain, 2026-02-15 -->

## Triggers & State Machines

- **Auto-timestamp triggers must fire on INSERT OR UPDATE, not UPDATE only.** If a trigger auto-manages a timestamp (e.g., `completed_at = now()` when status = 'DONE'), make it fire `BEFORE INSERT OR UPDATE` — not just `BEFORE UPDATE`. UPDATE-only triggers silently skip direct INSERTs with terminal status (test data seeding, manual migrations, data repairs). The function body handles INSERT safely when using `OLD IS NULL OR OLD.status IS DISTINCT FROM 'DONE'` — `OLD IS NULL` is true for INSERTs, so `IS DISTINCT FROM` already works. <!-- Source: PR review, second-brain #206, 2026-02-22 -->

- **Enumerate ALL transition paths when expanding a state machine.** When adding a new status to a DB-managed state machine with triggers, enumerate every possible transition (N states = N*(N-1) directional transitions). It's easy to handle forward paths (OPEN→IN_PROGRESS→DONE) and forget reversal paths (DONE→IN_PROGRESS). Missing a transition branch leaves derived timestamps in an inconsistent state (e.g., `completed_at` stays set when moving a DONE item back to IN_PROGRESS). <!-- Source: adversarial review, second-brain #156, 2026-02-19 -->

## SQLite-Specific

- **Use PRAGMA table_info for idempotent migrations, not blanket try/catch.** SQLite's `ALTER TABLE ADD COLUMN` throws if the column exists, but catching all errors hides real failures (disk full, permissions, corrupt DB). Instead: `const cols = db.pragma("table_info(table_name)"); if (!cols.some(c => c.name === "col")) { db.exec("ALTER TABLE ..."); }`. This is precise and doesn't mask unexpected errors. <!-- Source: PR review, command-center #34, 2026-02-21 -->

## Supabase / RLS Patterns

- **RLS UPDATE policies need both USING and WITH CHECK.** `USING` controls which existing rows the user can modify, but without `WITH CHECK`, the UPDATE can write *any* new values — including changing `household_id` to move data to another tenant. Always add `WITH CHECK (is_household_member(household_id))` (or equivalent) mirroring the USING clause on UPDATE policies. INSERT policies already require WITH CHECK by syntax. <!-- Source: PR review, folio #1, 2026-02-23 -->
- **Supabase upsert can't target partial unique indexes.** PostgREST maps `onConflict: 'col1,col2'` to `ON CONFLICT (col1, col2)` without a WHERE clause, so Postgres can't match a partial unique index (`WHERE source = 'manual'`). Fix: use a full (non-partial) unique index and include the discriminator column in `onConflict` (e.g., `onConflict: 'account_id,snapshot_date,source'`). This preserves per-source uniqueness without the partial index limitation. <!-- Source: PR review, folio #1, 2026-02-23 -->
- **Include mutable timestamps in upsert payloads.** On an upsert UPDATE, columns not in the payload keep their old values. If a trigger copies `recorded_at` to a parent table (`balance_updated_at`), the old timestamp propagates, making "last updated" stale after same-day corrections. Always include time-sensitive columns like `recorded_at: new Date().toISOString()` in the upsert payload. <!-- Source: PR review, folio #1, 2026-02-23 -->
- **Never overwrite created_at in ON CONFLICT DO UPDATE.** `created_at = now()` in a DO UPDATE SET clause destroys the original creation time. Immutable audit columns (`created_at`) should never appear in DO UPDATE SET. If you need an update timestamp, add a separate `updated_at` column. <!-- Source: PR review, folio #1, 2026-02-23 -->
- **Realtime subscription must cover all published tables.** When `ALTER PUBLICATION supabase_realtime ADD TABLE X` publishes a table, verify the client subscribes to it. Derived tables (e.g., `net_worth_snapshots` recomputed via RPC) need subscriptions too — cross-partner sync breaks silently if only the directly-written tables are subscribed. <!-- Source: PR review, folio #1, 2026-02-23 -->

## Data Integrity

- **Guard after create → reload.** After creating a resource and reloading from DB, check for null. Fire-and-forget patterns, replication lag, or race conditions can cause the reload to fail.
- **Dedup-check-then-insert must be in a transaction.** When checking for duplicates before inserting, both the SELECT and INSERT must be inside a `BEGIN`/`COMMIT` block. Without a transaction, a concurrent request can pass the dedup check after the first request's SELECT but before its INSERT, creating duplicates. Use `pool.connect()` + explicit transaction, not `pool.query()`. <!-- Source: PR review, second-brain #102, 2026-02-15 -->
- **Advisory locks for count-based limits in transactions.** A transaction alone doesn't prevent TOCTOU races on `SELECT COUNT(*) ... INSERT` patterns — concurrent transactions both observe the same count before either commits, exceeding the limit. Add `SELECT pg_advisory_xact_lock(hashtext($1))` with the scoping key (e.g., userId) after `BEGIN` to serialize the critical section. Unique partial indexes handle dedup but can't enforce count limits. <!-- Source: PR review, second-brain #208, 2026-02-22 -->
- **Source of truth directionality for type/CHECK pairs.** When a TypeScript union and a SQL CHECK constraint mirror each other, designate ONE as canonical (usually the TS type — it has compile-time checking) and have the other reference it. If both files say "I'm the source of truth," they'll diverge when one is updated without the other. <!-- Source: PR review, second-brain #191, 2026-02-20 -->

---
*Sources: second-brain, lexica*
