# React / React Native Patterns

Cross-project learnings for React and React Native development.

## Hooks

- **Always place hooks before early returns.** `useMemo`, `useCallback`, `useEffect`, `useState` must be called unconditionally at the top of the component, before any `if (...) return` guards. React requires hooks in the same order on every render.
- **Surface hook error states in UI.** When a hook returns `{ data, loading, error }`, always destructure and render the error. Ignoring errors creates silent failures.
- **Consolidate related effects sharing dependencies.** When two `useEffect` hooks depend on the same value and one must run before the other, merge into a single effect. Implicit ordering between separate effects is fragile.
- **Unmount guard on useEffect async fetches.** When a `useEffect` fires an async call (fetch, API call), use a `let active = true` flag with a cleanup that sets `active = false`. Check `if (active)` before calling any state setter. Prevents React state-after-unmount warnings and stale updates. <!-- Source: PR review, second-brain #75, 2026-02-14 -->

## State Management

- **Optimistic UI revert must capture previous state.** Never invert (`!e.starred`) to revert — if multiple toggles race, the inverse is wrong. Capture the previous value BEFORE the optimistic update and restore it on failure.
- **Zustand + React: atomic state transitions.** Never create intermediate states that match auto-start effect triggers. If an effect watches `sessionId=null && isCreating=false` to auto-start, then `restartSession` must set BOTH fields in a single `set()` call. Separate calls create observable intermediate states.
- **When bypassing a re-entrancy guard, inline the logic.** If `restartSession` needs to call `startSession()` after atomically setting its guard flag, inline the body — don't call through the guard that will reject it.

## React Native Specific

- **FlatList `extraData` for external state.** FlatList memoizes `renderItem` aggressively. Any state used inside `renderItem` that isn't part of the `data` array MUST be passed via `extraData`. Common gotcha: async-loaded data (e.g., word bank via SSE) doesn't trigger re-render of existing items.
- **Unmount guards on ALL XHR handlers.** Every `onprogress`, `onload`, `onerror` handler must check `isMountedRef.current` as its first line — not just retry handlers, but initial request handlers too. Abort-on-unmount is insufficient because the abort races with handler invocation.
- **Abort in-flight XHR on session/context change.** When a session ID changes, abort active XHR before resetting state to prevent stale data leaking.
- **Explicit logout on auth failure.** When a token refresh fails or a retry returns 401, call `logout()` — don't just surface an error. Stale auth state leaves the app stuck.
- **Accessibility on interactive components.** `Pressable` needs `accessibilityRole="button"` and `accessibilityLabel`.

## UI Patterns

- **Explicit `type` on every `<button>`.** `type="button"` (default) or `type="submit"` (forms only). Prevents accidental form submission.
- **Use semantic `<button>` not `<div role="button">`.** Native buttons provide keyboard handling (Enter/Space activation, tab focus) for free. This is the #1 most common a11y review finding in web dashboards — every clickable `<div>` must become a `<button>`. Also add `aria-current="page"` on active nav items and `aria-label` on icon-only buttons. <!-- Strengthened: PR review, command-center #3, 2026-02-14 -->
- **Don't hardcode line limits on variable-length content.** Avoid `numberOfLines` truncation — use expandable content instead.
- **SVG `<title>` for accessibility.** Every inline `<svg>` must have a `<title>` child for screen readers.
- **`aria-hidden` on decorative indicators + `aria-label` for state.** Visual-only elements (notification dots, status icons) need `aria-hidden="true"` to avoid screen reader noise. Communicate the state via `aria-label` on the parent interactive element instead (e.g., `aria-label="Inbox, unread items"`). <!-- Source: PR review, second-brain #75, 2026-02-14 -->
- **Decorative SVG icons: `aria-hidden="true"` + `focusable="false"`.** When SVGs are inside labeled buttons/links, mark them decorative so screen readers don't announce them separately. Only add `<title>` to standalone meaningful SVGs. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- **Don't rely on Unicode for icons.** Use SVG for consistent sizing across platforms.
- **CSS viewport units don't account for virtual keyboards.** Use `visualViewport` API for panels with fixed-position input fields.
- **CSS modern color notation.** Use `rgb(R G B / alpha%)` not `rgba(R, G, B, decimal)`.
- **Use placeholder hints, not default values** for user-configurable settings.

## Testing React Components

- **Extract guard logic into testable helpers.** Don't duplicate inline route logic in tests.
- **Full object assertions, not `objectContaining`.** Partial matching hides unexpected fields.
- **Case-insensitive dedup for display lists.** When building UI lists from AI-generated data, use `Set<string>` with `.toLowerCase()`.

---
*Sources: lexica, nanny-management, second-brain*
