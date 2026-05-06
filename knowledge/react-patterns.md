# React / React Native Patterns -- Rules

Distilled rules from code reviews and post-mortems. For full incident history and evidence, see `react-patterns-evidence.md`.

## Hooks

- When a hook returns `{ data, loading, error }`, always destructure and render ALL three fields; missing `loading` causes layout flash, missing `error` creates silent failures.
- Stale-while-revalidate must block concurrent mutations with an `enhancing` flag (`useState` + `useRef`) on cache hit; use a monotonic token to prevent stale refreshes from clearing the flag.
- Memoize functions returned from custom hooks with `useCallback` -- inline functions create new references every render, causing infinite effect loops.
- IntersectionObserver effects must include `Boolean(error)` in the guard to prevent retry loops; always provide a manual retry button when blocked.
- Include visibility-toggle state (e.g., `showForm`) in dependency arrays of effects that read DOM measurements like `scrollHeight`.
- Unmount guard on async fetches: `let active = true` in effects, `useRef(false)` (strict-mode safe) in callbacks; add `requestIdRef` to guard against stale fetches when deps change.
- Auth transition races: use `AbortController` for mount-time session checks, abort in every auth action.
- Memoize derived config objects from context with `useMemo` using primitive deps.
- Hook `load()` must `setError(err)` in catch AND `setError(null)` in the success path.
- `new Date()` inside `useMemo` needs a day-granularity key in the dependency array or the memo goes stale past midnight.

## State Management

- Sync `useState` from async props with `useEffect` -- `useState(prop?.value ?? default)` only uses the initial value on mount.
- Inline editing "clear" guard: compare against previous value, not empty string, or clearing is blocked.
- New editing modes must join ALL existing edit-mode guards (click suppression, classes, role, tabIndex, onKeyDown).
- Optimistic UI revert: capture previous state before update (never invert), guard revert with staleness check, capture only single deleted items (not full list), and snapshot ALL cascade states with functional updaters.
- Don't optimistically clear auth state on failed network calls -- only clear `user` when `res.ok`.
- `setState` updaters must be pure -- no async calls, logging, or side effects inside the callback.
- All viewer state variants in multi-tab apps must carry navigation context (e.g., `returnTo`).
- Guard async results against stale entity IDs (not just unmounts) by tracking current entity ID in a ref.
- Zustand with selectors over Context for performance-sensitive shared state with many consumers.
- Reset local state on context change via `key` prop (preferred, catches future state) or targeted `useEffect`.
- Close popup state (date pickers, dropdowns) on mode transitions like entering edit mode.
- Reversal actions must clear ALL side-effect state: errors, prompts, loading indicators.
- Async undo callbacks must be idempotent -- guard with a `useRef` flag to prevent double-click issues.
- Sequential async saves: use local draft state as source of truth (not props); roll back on failure.
- Resolving optimistic entries: filter out both optimistic ID and real entry's ID to prevent duplicates.
- `pointer-events: none` only blocks mouse -- add handler-level guards and disable interactive controls too.
- Re-sort after optimistic state changes that affect display order.
- Track individual item IDs (not collection length) for detecting state transitions in collections.
- Local "submitted" flag prevents child-parent prop update flicker after async `onSubmit()`.
- Ref-based flags need no-op guards: bail early if the action is a no-op, or the flag gets stuck.
- Zustand + React: use atomic `set()` calls to avoid intermediate states that trigger auto-start effects.
- When bypassing a re-entrancy guard, inline the logic rather than calling through the guard.

## React Native Specific

- FlatList `extraData` must include any state used in `renderItem` that isn't part of the `data` array.
- Every XHR handler (`onprogress`, `onload`, `onerror`) must check `isMountedRef.current` as its first line.
- Abort in-flight XHR on session/context change before resetting state.
- Apply safe-area insets in ONE place per edge -- never in both container AND child.
- Don't preload data that depends on pending user configuration (e.g., before onboarding completes).
- Wrap every `JSON.parse` in render paths and `useMemo` with its own try/catch and sensible fallback.
- Accessibility labels must derive from the same computed data as the visual display.
- `overflow: "hidden"` clips iOS shadows -- split into outer (shadow) and inner (clipping) views.

## UI Patterns

- Replace `role="button"` with native `<button type="button">`; exception: elements containing interactive children; for table rows, put the button inside a cell.
- `aria-label` is invalid on non-interactive, non-focusable generic elements (`<span>`, `<div>`, `<p>`).
- Nested interactive elements inside focusable containers need `stopPropagation` on keyboard events (Enter/Space).
- `:focus-visible` must mirror `:hover` on every interactive element for keyboard users.
- AbortController for both stale-request cancellation and timeouts: use a `didTimeout` flag to distinguish them.
- Respect `prefers-reduced-motion` for scroll behavior and animations; `autoFocus` pops virtual keyboard on mobile -- avoid on directly-loaded pages.
- Use native `disabled` for truly non-interactive controls; `aria-disabled` only for discoverable-but-not-activatable.
- Button `disabled` state must match form validation rules exactly.
- Hash-routing fallback: use `history.replaceState` (not `location.hash`), run on initial mount.
- Module-level caches must be invalidated on auth transitions -- always revalidate on mount.
- `aria-pressed` on toggle buttons (filter chips, star buttons, mute toggles).
- Dynamic `aria-label` on multi-state buttons that progress through a flow (not just on/off).
- Disable edit-trigger buttons during async saves to prevent stale-snapshot edits.
- Every inline `<svg>` must have a `<title>` child for screen readers.
- Visual progress bars need `role="progressbar"` with `aria-valuenow/min/max` and `aria-label`.
- Decorative indicators/SVG icons: `aria-hidden="true"` on visual-only elements; inside labeled buttons also add `focusable="false"` and remove `<title>`.
- UTC for date bucketing in multi-client dashboards -- use `getUTCFullYear()`/`getUTCMonth()`/`getUTCDate()`.
- ARIA live regions (`role="status"`, `aria-live="polite"`, `aria-busy`) for loading indicators; use `<div role="status">` not `<output>`.
- Collapsible sections: `aria-hidden={!expanded}` on container, `tabIndex={expanded ? 0 : -1}` on interactive children.
- Non-interactive elements inside clickable containers need `stopPropagation`; move it into child interactive handlers, never onto a non-interactive `<div>`.
- `stopPropagation()` for stacked dismissible layers; `onKeyDownCapture` on edit containers for Escape.
- `white-space: pre-wrap` for text containing `\n` line breaks.
- Grid headers need `grid-column: 1 / -1` to span all columns.
- Use CSS `columns` over JS masonry for height-balanced layouts; CSS grid `repeat(N)` must match actual data column count.
- Provide fallback text after content stripping (URL/markup removal) -- result can be empty.
- Image fade-in: use `useState` for loaded status, not inline `opacity: 0` + `onLoad` (re-renders reset it).
- Hover-only affordances need `:focus-within`, `@media (hover: none)`, `:focus-visible` fallbacks.
- Truncated text (`text-overflow: ellipsis`) needs a `title` attribute or tooltip.
- Scroll containers (`overflow-y: auto`) behind modals/overlays keep scrolling on touch/wheel events. Conditionally set `overflowY: 'hidden'` when a modal is open. <!-- Source: PR review, leaflet #43, 2026-03-15 -->
- Fallback rendering for unknown enum values from API: `statusLabels[entry.status] ?? entry.status`.
- Modal stacking: sibling overlay+dialog need independent `z-index` with explicit `position`.
- Conditional `className` stripping breaks layout -- render the wrapper conditionally instead.
- Pluralize user-facing counts: `{count} item{count === 1 ? "" : "s"}`.
- Abbreviated labels need `aria-label` (screen readers) and `title` (hover tooltip).
- Scroll preservation on DOM height changes: `useLayoutEffect` to capture/restore `scrollTop`.
- Mutual exclusion between overlapping panels occupying the same screen area.
- Never filter paginated results client-side -- push filtering to the server query.
- Global keyboard shortcuts must suppress in `INPUT`, `TEXTAREA`, `SELECT`, `contentEditable`; guard against modifier keys.
- iOS Safari auto-zoom: minimum 16px font-size on all form inputs.
- CSS custom properties: verify `var(--name)` exists in `:root`; tokenize all hardcoded hex/rgba into custom properties.
- Use instance-unique IDs (`useId()` or prop-based suffix) for `htmlFor`/`id`/`name` in reusable components.
- `placeholder` is not an accessible label -- add `aria-label` or `<label htmlFor>`; `aria-controls` must accompany `aria-expanded`.
- Infinite CSS animations need `@media (prefers-reduced-motion: reduce) { animation: none !important }`.
- Plan notification/indicator dismissal paths upfront -- define how every new indicator gets cleared.
- **All-caps text in flex rows needs `line-height: 1`.** When a flex container uses `align-items: center` to align an all-caps label next to a small indicator (status dot, badge), the inherited line-height (~1.5) leaves half-leading above the caps. The flex centers by line-box, so the indicator visually drifts above the caps' optical center. Set `line-height: 1` on the caps element to collapse leading and align optically. <!-- Source: post-mortem, second-brain #603, 2026-05-06 -->
- **Don't stack child horizontal padding on top of a layout-padding wrapper.** When a section sits inside a layout container that already provides horizontal gutter (e.g., `.app { padding: 0 40px }`), adding `padding: 0 16px` on the section itself stacks - the section's content edge ends up 56px from the viewport while sibling sections stay at 40px, producing a subtle horizontal misalignment. Audit every direct child of a gutter wrapper: the child should either inherit the wrapper's gutter (no horizontal padding) or push internal padding to a deeper element (e.g., a scroll-container) where it doesn't compete with the layout gutter. Consider tokenizing the wrapper gutter (`--app-gutter`) so the convention is enforceable by grep. <!-- Source: post-mortem, second-brain #608, 2026-05-06 -->

## General Web UI

- Use SVG icons, not Unicode characters -- rendering varies across platforms.
- Don't hard-truncate variable content -- make it expandable with "Show more".
- Use placeholder hints instead of default values for user-configurable settings.

## Data Flow & Derived State

- Aggregate counts must use unfiltered data when representing the total, not the filtered display list.
- Event status is source of truth over schedule-derived status for UI state; never disable editing on in-progress events.

## Dual Persistence (Local + Server)

- Server-first with local fallback: `.catch(() => getLocalData())` so transient failures don't blank UI.
- Merge local and server state (union of sets) for cross-device sync; don't short-circuit on non-empty local data.

## Component Design

- Extract shared conditional logic into a utility on first duplication -- never copy `if/else` across components.

## Testing React Components

- Case-insensitive dedup for display lists from AI-generated data: `Set<string>` with `.toLowerCase()`.
- Use scoped index keys for static lists with potential duplicate content: `` key={`${parentId}-pro-${index}`} ``.
- Deduplicate array data at every consumption point -- rendering AND logic paths independently.
