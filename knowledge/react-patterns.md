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
- **Hydration-seeded local state needs a one-shot ref guard.** When a screen-local filter/toggle should initialize from a persisted store value but stay user-controlled afterwards, seed it inside an effect that fires when the store's `isInitializing` flips false and gate the seed with a `useRef(false)` flipped to true on first run -- otherwise rehydrations or store updates silently clobber user changes. <!-- Source: post-mortem, baby-name-picker #33, 2026-05-14 -->
- Inline editing "clear" guard: compare against previous value, not empty string, or clearing is blocked.
- New editing modes must join ALL existing edit-mode guards (click suppression, classes, role, tabIndex, onKeyDown).
- Optimistic UI revert: capture previous state before update (never invert), guard revert with staleness check, capture only single deleted items (not full list), and snapshot ALL cascade states with functional updaters. **Revert MUST be per-id, not whole-array**: `setState(prev)` on failure clobbers any concurrent successful mutation that landed between the optimistic write and the error — use `setState(cur => cur.map/filter/splice by id)` instead. For deletes, capture both the row and its index, then splice back in on failure (guard against double-revert by checking the id isn't already present). <!-- Source: post-mortem, second-brain #647, 2026-05-19 -->
- **Default custom data hooks (`useFoo`/`useFooData`) to optimistic writes; require an explicit `pessimistic: true` opt-out.** When a hook exposes `update`/`toggle`/`vote`/`favorite`/`postNote` style mutations for sub-100ms-perceived UI, the absence of optimistic update is a latent bug -- the user will eventually report "feels slow." PR #83 caught this only via user feedback for vote/favorite pills. Building optimistic-by-default into the hook factory means each new write path inherits the right behavior rather than awaiting per-call retrofitting. **Confirmed as house style across 7 write-path hooks (vote, favorite, note-add, note-delete, image-delete, pin, updateImageCategory) over PRs #83/#85/#86 — promoted from knowledge pattern to default expectation in adversarial-review.md section 1.5.** <!-- Source: post-mortems, remodel-hq #83/#85/#86, 2026-05-15/16 -->
- **Callback identity churn: do NOT include a mutating list (`images`, `notes`, `items`) in `useCallback` deps.** Three repeat occurrences (PRs #83/#85/#86) of the same bug: a destructive/mutating callback closes over the parent list state and lists it in `useCallback` deps, so the callback identity rebuilds on every list mutation and downstream `React.memo` / `useEffect` re-fires. Fix: snapshot via `useRef(currentList)` updated in an effect, or use a functional setter to read inside the body — then drop the list from deps. Greppable: `useCallback\([^,]*, \[[^\]]*\b(images|items|list|notes)\b[^\]]*\])`. Tier 0 candidate. <!-- Source: post-mortems, remodel-hq #83/#85/#86, 2026-05-15/16 -->
- **Destructive-action confirm dialogs default focus to Cancel, not the destructive button.** AlertDialog/ConfirmDialog initial focus should land on the safer choice; the destructive button is reached via Tab. Generalizes from PR #85's lightbox image-delete confirm. <!-- Source: post-mortem, remodel-hq #85, 2026-05-16 -->
- **Nested AlertDialog inside a portaled modal must stopPropagation on ESC.** Otherwise pressing ESC inside the inner confirm dismisses the outer modal too, surprising the user. PR #85: the inspo lightbox confirm-delete dialog was scoped to consume ESC before the outer lightbox could. <!-- Source: post-mortem, remodel-hq #85, 2026-05-16 -->
- **Transient per-row error state must key on the row id and reset on row change.** When a list-of-rows surface (lightbox per-note errors, grid per-card errors) holds an error string in parent state, switching the active row must clear it — otherwise a stale error from row A leaks into row B. PR #85 surfaced this for per-note delete errors. <!-- Source: post-mortem, remodel-hq #85, 2026-05-16 -->
- **Cross-surface cache notifier coverage.** When a derived cache (e.g., a `noteCounts: Map<id, number>` aggregate) is mutated on Surface A, every other surface that can mutate the same underlying entity must wire the same notifier (`onNoteAdded`/`onNoteDeleted`/etc.). Audit all mutation sites whenever a new surface is added that lists the entity. PR #86: `/atelier/review` was added without wiring notifiers, leaving the "With notes" filter chip stale after every inline mutation. <!-- Source: post-mortem, remodel-hq #86, 2026-05-16 -->
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
- **Cache-busting query params (`?_t=Date.now()`) DO NOT refresh the canonical URL's browser cache slot — they create a separate slot.** Subsequent natural fetches to the canonical URL still hit the stale entry. When the server sets `Cache-Control: max-age=N, stale-while-revalidate=M` on a GET endpoint, the right primitive for "force a refresh AND repopulate the canonical slot" is `fetch(url, { cache: 'reload' })`, not `fetch(url + '?_t=' + Date.now())`. Pair this with explicit invalidation calls from every mutation path (create/delete/edit/star/etc.) that affects the cached query. <!-- Source: PR review, second-brain #651, 2026-05-19 -->
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
- **Modal-scoped keyboard handlers must call `preventDefault()` before any early-return guard.** If a modal binds ArrowLeft/Right (or any browser-default-having key) and returns early when `canNavigate` is false (e.g., filtered list collapsed to one item), the key bubbles to the document and scrolls the page. The fix: `preventDefault()` runs unconditionally as the first line after the key match; navigation guards come after. Test the single-item / no-op state explicitly. <!-- Source: post-mortem, remodel-hq #84, 2026-05-15 -->
- **Hover-affordance overlays on images (chevrons, drag handles, action pills) need a breakpoint gate** like `hidden md:flex`. On narrow viewports they occlude content and lack a hover state to fade them out. Touch users fall back to swipe or keyboard. <!-- Source: post-mortem, remodel-hq #84, 2026-05-15 -->
- **Modal arrow-key navigation pattern:** parent component owns the `keydown` listener (it knows the list); the modal/lightbox stays controlled and only renders chevron affordances when `onPrev`/`onNext` callbacks are supplied (auto-hides for single-item lists). Listener checks `event.target` against `INPUT`/`TEXTAREA`/`SELECT`/`contentEditable` and bails so the focused field keeps native cursor movement and option cycling. `preventDefault()` fires unconditionally on ArrowLeft/Right match. Consider extracting as `useModalArrowKeys({ onPrev, onNext, enabled })` once a second modal needs it. <!-- Source: post-mortem, remodel-hq #84, 2026-05-15 -->
- iOS Safari auto-zoom: minimum 16px font-size on all form inputs.
- CSS custom properties: verify `var(--name)` exists in `:root`; tokenize all hardcoded hex/rgba into custom properties.
- Use instance-unique IDs (`useId()` or prop-based suffix) for `htmlFor`/`id`/`name` in reusable components.
- `placeholder` is not an accessible label -- add `aria-label` or `<label htmlFor>`; `aria-controls` must accompany `aria-expanded`.
- Infinite CSS animations need `@media (prefers-reduced-motion: reduce) { animation: none !important }`.
- Plan notification/indicator dismissal paths upfront -- define how every new indicator gets cleared.
- **All-caps text in flex rows needs `line-height: 1`.** When a flex container uses `align-items: center` to align an all-caps label next to a small indicator (status dot, badge), the inherited line-height (~1.5) leaves half-leading above the caps. The flex centers by line-box, so the indicator visually drifts above the caps' optical center. Set `line-height: 1` on the caps element to collapse leading and align optically. <!-- Source: post-mortem, second-brain #603, 2026-05-06 -->
- **Don't stack child horizontal padding on top of a layout-padding wrapper.** When a section sits inside a layout container that already provides horizontal gutter (e.g., `.app { padding: 0 40px }`), adding `padding: 0 16px` on the section itself stacks - the section's content edge ends up 56px from the viewport while sibling sections stay at 40px, producing a subtle horizontal misalignment. Audit every direct child of a gutter wrapper: the child should either inherit the wrapper's gutter (no horizontal padding) or push internal padding to a deeper element (e.g., a scroll-container) where it doesn't compete with the layout gutter. Consider tokenizing the wrapper gutter (`--app-gutter`) so the convention is enforceable by grep. <!-- Source: post-mortem, second-brain #608, 2026-05-06 -->

## General Web UI

- Use SVG icons, not Unicode characters -- rendering varies across platforms. **Recurring antipattern: ad-hoc Unicode glyphs (★ ♥ ✕ ↑ ↓ ●) inserted as buttons' visible content render inconsistently across fonts/OSes and produce uneven baselines next to text labels. PR #83 hit this in 3+ Atelier files (lightbox toolbar, grid vote pills, action row). The fix is always two-part: (1) swap to a project-wide inline `<svg>` icon set with `aria-hidden="true"` plus `focusable="false"` and a sibling `aria-label`/`<title>` on the parent button; (2) sibling-sweep every file in the same feature area on the SAME PR -- don't fix only the surface the user pointed at. Add a Tier 0 grep for `>[★♥✕↑↓●♡♠♣◆▲▼◀▶]<` in `.tsx` files to catch new occurrences pre-merge.** <!-- Source: post-mortem, remodel-hq #83, 2026-05-15 -->
- Don't hard-truncate variable content -- make it expandable with "Show more".
- Use placeholder hints instead of default values for user-configurable settings.
- **For not-yet-shipped store-badge CTAs, render non-interactive `role="img"` wrappers instead of disabled buttons.** `<button disabled>` with click-prevent handlers creates accessibility ambiguity (screen reader announces "button" but the user can't activate it) and visual ambiguity ("Coming soon" pills overlap official badge artwork). Cleanest pattern: render the official store badges inside `<div role="img" aria-label="Available on the App Store, coming soon">` with `pointer-events: none`, accompanied by a single caption underneath: "Coming soon to iOS and Android." <!-- Source: post-mortem, baby-name-picker #36, 2026-05-18 -->

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

- **Do not `.limit()` a list that is filtered client-side downstream.** A global cap on an over-fetched list silently hides data when the filter narrows to a subset that did not make the cap. Either fetch per-filter-key, or paginate with explicit UI affordance. <!-- Source: post-mortem, remodel-hq #47, 2026-05-13 -->

- **Don't re-derive a "recent"/ordered view from an in-memory array's index — preserve the source query's `ORDER BY`.** An array built by appending during a session is newest-last, but the SAME array reloaded from the DB on launch is in the query's order (e.g. `created_at DESC` = newest-FIRST). Sorting by array index then silently reverses after a restart — the default view shows oldest-first for every returning user, and an in-session-only test passes anyway. Make ordered views preserve the load order (a query-ordered list is already correct; don't re-sort it), and test the **post-restart load order**, not just the in-session append order. <!-- Source: baby-name-picker favorites Elo-demotion #N, 2026-05-28 -->

- **A "paused"/modal/overlay state must disable EVERY control that can mutate the data it derives from — including controls rendered OUTSIDE the gated container.** Gating the obvious region (the cards, via `pointerEvents:none` + `disabled`) missed a filter control rendered in the header; tapping it swapped the underlying record, the overlay's derived content resolved to `null` and unmounted, but the overlay's own state stayed open → a blank, frozen, non-interactive screen. Enumerate every state-mutating affordance on the screen, not just the ones inside the locked area, and gate them all on the paused flag. **Plus defense-in-depth:** add an invariant effect that force-closes the overlay if the data it depends on disappears/changes (`shouldForceClose(isOpen, selectedId, currentIds)`), so no missed control can ever strand it. Extract that predicate as a pure, unit-tested function. <!-- Source: baby-name-picker compare-card detail overlay #N, 2026-05-28 -->
