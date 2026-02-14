# Schema Design Patterns

Lessons learned from second-brain Phase 0 schema reviews.

## Bidirectional Invariant Enforcement
When a child table only makes sense for a specific parent type:
1. Trigger on CHILD (BEFORE INSERT/UPDATE): verify parent has correct type
2. Trigger on PARENT (BEFORE UPDATE): block type change while child exists
Both are needed. Missing either creates orphaned rows.

## Index Coverage for Join Tables
- PK on (entry_id, tag_id) only helps "tags for entry"
- "Entries for tag" needs standalone index on tag_id
- Rule: if you ever query by the non-leading column, add an index

## Timestamp Propagation
- Child changes (e.g. marking TODO done) should touch parent updated_at
- Without this, parent rows don't surface correctly in recency-sorted feeds
- Implement via BEFORE INSERT/UPDATE trigger on child that UPDATEs parent

## Derived Field Consistency
- If field B depends on field A (completed_at depends on status), enforce via trigger
- On status → DONE: set completed_at = now()
- On status → OPEN: clear completed_at = NULL
- Never rely on app code alone — multiple code paths can create inconsistency

## Full-Text Search Coverage
- Index EVERY user-facing text column that should be searchable
- For second-brain: content + extracted_text + ai_response
- Use coalesce() to handle NULLs in the GIN index expression

## SQL ↔ TypeScript Type Sync
- CHECK constraints duplicate TypeScript union types
- Document which is source of truth (TypeScript union in @second-brain/shared)
- Add comments in SQL pointing to the TypeScript type
- When adding new values, both must be updated
