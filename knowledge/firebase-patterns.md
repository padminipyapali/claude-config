# Firebase / Firestore Patterns

Cross-project learnings for Firebase Authentication and Firestore.

## Security Rules

- **Wildcard rules hide permission gaps.** `{document=**}` rules can prevent legitimate cross-user operations (e.g., owner removing a member's reference). Use specific subcollection rules for fine-grained permissions.
- **Case-sensitive email in security rules.** Always use `.lower()` on `request.auth.token.email` — email addresses are case-insensitive but string comparison isn't.
- **Test security rule changes across every role/account type.** Don't just test the happy path for the primary user type.

## Auth Patterns

- **Chicken-and-egg auth.** Some account types (e.g., nannies) can't write to another user's data for self-linking. Solution: use indexed lookup collections that the linking account can write to.
- **Explicit logout on auth failure.** When token refresh fails or a request returns 401, call `logout()` — don't just surface an error.

## Data Access Patterns

- **Skip inaccessible collections by account type.** `loadAllData` must not attempt to read collections the current account type doesn't have permission for (e.g., nannies skip feedbackNotes).
- **Read-only account guards.** Read-only accounts should never write during initialization — check `isReadOnly` before any write operations.
- **Indexed lookups over full-collection scans.** Use subcollection references for permission checks instead of scanning entire collections.

---
*Sources: nanny-management*
