# Database / PostgreSQL Patterns

Cross-project learnings for SQL schema design, indexing, and the node-postgres driver.

## Schema Design

- **Enforce invariants at DB level with triggers, not application code.** Multiple code paths create inconsistency.
- **Bidirectional invariant enforcement.** If a child only makes sense for a specific parent type: (1) trigger on CHILD INSERT/UPDATE verifies parent type, (2) trigger on PARENT UPDATE blocks type change while child exists. Missing either creates orphaned rows.
- **Auto-manage derived fields via triggers.** `completed_at` depends on `status`? Set it via trigger: DONE → `now()`, OPEN → `NULL`.
- **Timestamp propagation.** Child changes should touch parent `updated_at` for recency-sorted feeds. Implement via BEFORE INSERT/UPDATE trigger on child.
- **SQL ↔ TypeScript type sync.** CHECK constraints and TypeScript unions must match. Document which is source of truth. Add SQL comments referencing the TS type.
- **Partial unique indexes for nullable columns.** `CREATE UNIQUE INDEX ... WHERE col IS NOT NULL` enforces uniqueness only for non-null values.
- **Schema changes need migration reminders.** Schema files are documentation, not deployment, without an automated runner.

## Index Design

- **Leading columns must match WHERE clause.** If queries filter by `user_id, channel, col`, the index must lead with `user_id`.
- **Composite PK (A, B) only indexes queries by A.** If you ever query by B alone, add a standalone index.
- **OR defeats indexes.** `WHERE a = $1 OR b = $1` can't use an index on (a) or (b). Split into two queries.
- **Consolidate redundant indexes.** A unique index on (a, b, c) serves as both uniqueness constraint and query index.
- **FTS indexes must cover ALL searchable text columns.** Use `coalesce()` to handle NULLs in the GIN index expression.

## Query Patterns

- **Scope all DB lookups by user_id.** Channel-local IDs (e.g., Telegram message_id) are NOT globally unique. Without user scoping, user A's data can match user B's query.
- **User scoping on correlated subqueries.** Always include `AND c.user_id = e.user_id` even if the data model guarantees it — defense in depth.
- **Never use OR in WHERE clauses that defeat index usage.** Split into two separate queries.
- **Filter by authoritative state, not cross-referencing result sets.** When two queries feed separate display sections and can overlap.
- **FTS + vector search are complementary, not alternatives.** FTS excels at exact/stemmed word matching but fails on conceptual similarity ("colors" won't find "yellow", "blue"). Use FTS as primary with vector similarity fallback when FTS returns 0 results. This avoids the cost of embedding every query while catching semantic matches.

## node-postgres (pg) Driver

- **pg returns DATE as JS Date, TIMESTAMPTZ as Date, JSONB as object.** TypeScript generic params on `pool.query<T>()` don't enforce runtime types. Mock-based tests using strings will pass but production breaks.
- **Always verify pg's actual JS return type for new columns.** When adding a DB column, check what pg returns at runtime.
- **(PostgreSQL) `AT TIME ZONE`: cast to `::timestamp` first.** `date` implicitly casts to `timestamptz` which reverses the conversion.

## Data Integrity

- **Guard after create → reload.** After creating a resource and reloading from DB, check for null. Fire-and-forget patterns, replication lag, or race conditions can cause the reload to fail.
- **At-most-once dedup markers: set BEFORE the action.** If the action fails (timeout), the marker prevents retry spam. Accept at-most-once over at-least-once-with-spam.
- **Store computed results alongside display text.** Don't re-derive what you already know from a previous computation.

---
*Sources: second-brain, lexica*
