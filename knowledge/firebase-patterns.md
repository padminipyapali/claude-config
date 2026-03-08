# Firebase / Firestore Patterns

Cross-project learnings for Firebase Authentication and Firestore.

## Security Rules

- **Wildcard rules hide permission gaps.** `{document=**}` rules can prevent legitimate cross-user operations (e.g., owner removing a member's reference). Use specific subcollection rules for fine-grained permissions.
- **Case-sensitive email in security rules.** Always use `.lower()` on `request.auth.token.email` — email addresses are case-insensitive but string comparison isn't.

## Auth Patterns

- **Chicken-and-egg auth.** Some account types (e.g., nannies) can't write to another user's data for self-linking. Solution: use indexed lookup collections that the linking account can write to.

## Document Mapping

- **Spread order in Firestore doc mapping: data first, then ID.** Always use `{ ...docSnap.data(), id: docSnap.id }` — never `{ id: docSnap.id, ...docSnap.data() }`. If the stored document has an `id` field, the spread overwrites the Firestore document ID with the stored value, causing downstream lookups and mutations to target the wrong document. Mechanical check: grep for `docSnap.id` in service files and verify the spread comes AFTER `data()`. <!-- Source: PR review, sleep-tracker #68, 2026-03-08 -->

## Data Access Patterns

- **Skip inaccessible collections by account type.** `loadAllData` must not attempt to read collections the current account type doesn't have permission for (e.g., nannies skip feedbackNotes).
- **Read-only account guards.** Read-only accounts should never write during initialization — check `isReadOnly` before any write operations.
- **Gate on data completeness, not just status.** When a status field doubles as a soft-delete marker (e.g., `cancelSleepEvent` stores `status: "completed"` with `durationMinutes: null`), downstream features gated on `status === "completed"` will incorrectly include cancelled records. Always add a data-completeness check (e.g., `durationMinutes != null`) alongside the status check. <!-- Source: PR review, sleep-tracker #58, 2026-03-07 -->
- **Use `runTransaction` for read-modify-write on arrays.** When multiple clients can concurrently modify an embedded array (e.g., awakePeriods), plain `getDoc` → `updateDoc` has a lost-update race condition. Wrap in `runTransaction` for atomic read-modify-write. <!-- Source: PR review, sleep-tracker #58, 2026-03-07 -->
- **Throw on no-op deletes from arrays.** When deleting an item from an embedded array by ID, verify the filtered array is shorter than the original. Silent no-ops on stale clients enable undo flows to resurrect already-deleted data. <!-- Source: PR review, sleep-tracker #58, 2026-03-07 -->

## Query Timing

- **Gate Firestore query hooks on auth resolution.** Don't pass a `familyId` (or any auth-derived ID) to a query hook until auth loading is complete and a user exists. Pattern: `const queryId = !authLoading && user ? familyId : null;` then pass `queryId` to the hook, which skips the query when `null`. Without this gate, the hook fires with `familyId` from a stale context (previous session, localStorage) before auth confirms the user, potentially querying wrong data or hitting permission errors. <!-- Source: PR review, sleep-tracker #68, 2026-03-08 -->

---
*Sources: nanny-management, sleep-tracker*
