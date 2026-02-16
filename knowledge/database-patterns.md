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
- **FTS: use OR semantics for personal knowledge retrieval.** `plainto_tsquery` (AND) fails when users search with metadata terms — proper nouns, category labels, or concept names that don't appear verbatim in the stored text (e.g., "Bene Gesserit fear mantra" for an entry containing only the Litany text). Use `websearch_to_tsquery` with OR-joined terms so entries matching ANY term surface, ranked by `ts_rank_cd`. AND semantics is only appropriate when false positives are dangerous (e.g., matching TODOs for completion).

## Data Integrity

- **Guard after create → reload.** After creating a resource and reloading from DB, check for null. Fire-and-forget patterns, replication lag, or race conditions can cause the reload to fail.
- **Dedup-check-then-insert must be in a transaction.** When checking for duplicates before inserting, both the SELECT and INSERT must be inside a `BEGIN`/`COMMIT` block. Without a transaction, a concurrent request can pass the dedup check after the first request's SELECT but before its INSERT, creating duplicates. Use `pool.connect()` + explicit transaction, not `pool.query()`. <!-- Source: PR review, second-brain #102, 2026-02-15 -->

---
*Sources: second-brain, lexica*
