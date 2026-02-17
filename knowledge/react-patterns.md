# React / React Native Patterns

Cross-project learnings for React and React Native development.

## Hooks

- **Surface hook error states in UI.** When a hook returns `{ data, loading, error }`, always destructure and render the error. Ignoring errors creates silent failures.
- **Memoize functions returned from custom hooks.** If a custom hook returns a function that consumers may use in `useEffect` dependency arrays, wrap it in `useCallback`. An inline `reload: () => { ... }` in a hook's return object creates a new reference every render, causing infinite effect loops. This applies to ANY function returned from a hook — `reload`, `refresh`, `reset`, etc. <!-- Source: PR review, second-brain #90, 2026-02-15 -->
- **Unmount guard on async fetches — two patterns.** (1) When async lives inside `useEffect`: use `let active = true` with cleanup `active = false`, check `if (active)` before state setters. (2) When async lives in `useCallback` called from `useEffect`: use `useRef(true)` (`isMountedRef`) with a separate cleanup effect, check `isMountedRef.current` before state setters. Pattern (2) is needed because the callback outlives any single effect invocation — a local `let` flag would be scoped wrong. When a hook already has a staleness guard (e.g., `currentKeyRef`), combine both checks: `if (currentKeyRef.current !== key || !isMountedRef.current) return;`. <!-- Source: PR review, second-brain #75, 2026-02-14; strengthened: second-brain #140, 2026-02-16 -->

## State Management

- **Optimistic UI revert must capture previous state.** Never invert (`!e.starred`) to revert — if multiple toggles race, the inverse is wrong. Capture the previous value BEFORE the optimistic update and restore it on failure.
- **Zustand + React: atomic state transitions.** Never create intermediate states that match auto-start effect triggers. If an effect watches `sessionId=null && isCreating=false` to auto-start, then `restartSession` must set BOTH fields in a single `set()` call. Separate calls create observable intermediate states.
- **When bypassing a re-entrancy guard, inline the logic.** If `restartSession` needs to call `startSession()` after atomically setting its guard flag, inline the body — don't call through the guard that will reject it.

## React Native Specific

- **FlatList `extraData` for external state.** FlatList memoizes `renderItem` aggressively. Any state used inside `renderItem` that isn't part of the `data` array MUST be passed via `extraData`. Common gotcha: async-loaded data (e.g., word bank via SSE) doesn't trigger re-render of existing items.
- **Unmount guards on ALL XHR handlers.** Every `onprogress`, `onload`, `onerror` handler must check `isMountedRef.current` as its first line — not just retry handlers, but initial request handlers too. Abort-on-unmount is insufficient because the abort races with handler invocation.
- **Abort in-flight XHR on session/context change.** When a session ID changes, abort active XHR before resetting state to prevent stale data leaking.

## UI Patterns

- **Grep for `role="button"` — replace with `<button>`.** Any `<span>`, `<div>`, or `<a>` with `role="button"` must become `<button type="button">`. Mechanical check: `grep -rn 'role=.*button' --include='*.tsx'` on changed files, inspect every match. Native `<button>` gives keyboard handling (Enter/Space, tab focus) for free and satisfies Biome `noStaticElementInteractions`. **Exception:** elements containing interactive children (`<a>` links) must stay as `<span role="button" tabIndex={0}>` with `onKeyDown`, because `<a>` inside `<button>` violates HTML content model. <!-- Strengthened: PR review, second-brain #143, 2026-02-17 -->
- **`aria-pressed` on toggle buttons.** Any button that toggles between on/off states (filter chips, star buttons, mute toggles) must have `aria-pressed={isActive}`. Without it, screen readers announce the button but not its current state. Easy to miss because the visual styling (active class) communicates state to sighted users but is invisible to assistive technology. <!-- Source: PR review, second-brain #125, 2026-02-16 -->
- **SVG `<title>` for accessibility.** Every inline `<svg>` must have a `<title>` child for screen readers.
- **`aria-hidden` on decorative indicators + `aria-label` for state.** Visual-only elements (notification dots, status icons) need `aria-hidden="true"` to avoid screen reader noise. Communicate the state via `aria-label` on the parent interactive element instead (e.g., `aria-label="Inbox, unread items"`). <!-- Source: PR review, second-brain #75, 2026-02-14 -->
- **Decorative SVG icons: `aria-hidden="true"` + `focusable="false"`.** When SVGs are inside labeled buttons/links, mark them decorative so screen readers don't announce them separately. Only add `<title>` to standalone meaningful SVGs. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- **UTC for date bucketing in multi-client dashboards.** When grouping items by day ("Today", "Yesterday", etc.) in a web dashboard, use UTC dates for comparison — not local timezone. Local timezone creates inconsistent grouping across clients. Compare using `getUTCFullYear()`/`getUTCMonth()`/`getUTCDate()` and pass `timeZone: "UTC"` to `toLocaleDateString`. Also hoist reference dates (today, yesterday) outside loops. <!-- Source: PR review, command-center #12, 2026-02-15 -->
- **stopPropagation() for stacked dismissible layers.** When a modal sits over a panel, or a drawer over an overlay, keyboard events (Escape) and click-outside handlers fire on ALL layers simultaneously. Call `e.stopPropagation()` in the topmost layer's handler to prevent cascading dismissals. **For inline edit modes inside dismissible panels:** use `onKeyDownCapture` on the edit container, not `onKeyDown` on the textarea alone — if focus moves to Save/Cancel buttons, textarea-only handlers won't fire and Escape closes the panel instead of cancelling the edit. <!-- Strengthened: PR review, second-brain #143, 2026-02-17 -->
- **`white-space: pre-wrap` for newline-formatted text.** Any container rendering user-facing text with `\n` line breaks needs `white-space: pre-wrap`. HTML collapses newlines by default. Easy to miss because text appears correct in channels that preserve newlines natively (Telegram, terminal). <!-- Source: BUG-W003, second-brain -->
- **Grid headers need `grid-column: 1 / -1`.** When a non-card element (header, label) lives inside a CSS grid container, it must explicitly span all columns or it consumes a grid cell and creates a visual gap. <!-- Source: BUG-W004, second-brain -->
- **Truncated text needs `title` attribute.** When using `text-overflow: ellipsis`, always pair with a `title` attribute or tooltip so users can access the full value on hover. Especially important for URLs. <!-- Source: BUG-020, second-brain -->
- **Modal stacking: sibling overlay+dialog need independent `z-index`.** When overlay and dialog are siblings (not parent-child), both need `position` and explicit `z-index`. Flex centering only works if the dialog is a child of the overlay. <!-- Source: BUG-019, second-brain -->
- **Scroll preservation on DOM height changes.** When injected content changes height (skeleton → real text, lazy-loaded section), use `useLayoutEffect` to capture `scrollTop` before the change and restore it via `requestAnimationFrame` after DOM settles. Prevents jarring scroll jumps. <!-- Source: second-brain DECISIONS -->
- **Mutual exclusion between overlapping panels.** When two panels can occupy the same screen area (thread detail + sidebar), keep them mutually exclusive: opening one closes the other. Prevents visual clutter and simplifies state management. <!-- Source: second-brain DECISIONS -->
- **Never filter paginated results client-side.** If the server returns N items per page and the client filters some out, the visible count is unpredictable — a page of all-filtered items shows "No entries found" despite data existing. Push filtering to the server SQL query so pagination operates on the final result set. <!-- Source: BUG-021, second-brain #100, 2026-02-15 -->
- **iOS Safari auto-zoom: minimum 16px font-size on form inputs.** Any `<input>`, `<textarea>`, or `<select>` on a mobile-facing web page must have a computed font-size of at least 16px (1rem at default root size) to prevent iOS Safari's auto-zoom behavior. When fixing one input, grep for pattern siblings — all focusable form elements in the stylesheet need the same minimum. <!-- Source: BUG-W008, second-brain, 2026-02-16 -->

## Testing React Components

- **Case-insensitive dedup for display lists.** When building UI lists from AI-generated data, use `Set<string>` with `.toLowerCase()`.

---
*Sources: lexica, nanny-management, second-brain*
