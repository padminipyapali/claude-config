# Convention Violation Tracker

Tracks conventions that are violated across PRs. When a convention reaches 2+ violations, it needs **mechanical enforcement** (ESLint rule, pre-push hook, Tier 0 grep) because manual discipline has proven insufficient.

**How to use:**
- After each post-mortem, check if any findings map to a tracked convention. If so, increment the count and add the PR.
- If a new convention violation appears, add a row.
- When a convention gets mechanical enforcement, update its status and link to the enforcing PR.

---

## Escalation Rule

> **2+ violations of the same convention = needs mechanical enforcement.**
>
> Manual checklist items are not sufficient once a pattern recurs. Options for mechanical enforcement, in order of preference:
> 1. **ESLint/Biome rule** (catches at lint time, zero review cost)
> 2. **Tier 0 automated grep** in adversarial review (catches pre-push)
> 3. **Pre-push hook** (blocks push until fixed)
> 4. **CI check** (catches post-push but before merge)

---

## Violation Tracking Table

| Convention | Violations | PRs | Last Violated | Enforcement Status |
|---|---|---|---|---|
| **module-doc-header** — module-level doc headers on all top-level files | 3+ | second-brain #142 (api.ts header), #273 (module header fix) | 2026-02-26 | **None** — checklist item only. Needs Tier 0 grep for files without leading `/** ... */` or `// ...` block |
| **error-msg-specificity** — specific error messages, no generic fallthrough | 4+ | second-brain #205 (JWT logging), #209 (BadRequestError raw exposure), command-center #39 (non-JSON error responses, fire-and-forget without catch) | 2026-02-27 | **None** — adversarial review Tier 3 item exists but repeatedly missed. Needs mechanical grep |
| **fire-and-forget-catch** — every fire-and-forget async operation must have `.catch()` or try/catch | 4+ | second-brain #273, #275 (fallback-value-as-noop), command-center #39 (refresh without catch), second-brain #288 (unmount guard) | 2026-02-28 | **None** — adversarial review Tier 1 item exists. Grep for unhandled promises in fire-and-forget paths needed |
| **merge-with-CHANGES_REQUESTED** — do not merge with outstanding CHANGES_REQUESTED | 6+ | second-brain #136, #145, #148, #199, #205, #215, #256 | 2026-02-26 | **None** — process rule only. Needs pre-merge hook or GitHub branch protection rule requiring review dismissal |
| **review-loop-skip-on-50+-LOC** — review loop (4a-4e) mandatory for >= 50 LOC | 6+ | second-brain #153, #209 (632 LOC silent skip), #251, #259 (217 LOC claimed "under 50"), #260 (744 LOC "stacked PR"), #261 (353 LOC "stacked PR") | 2026-02-26 | **None** — CLAUDE.md rule exists but agents bypass it. Needs `git diff --stat` computed threshold check, not agent judgment |
| **catch-return-default-masking** — catch blocks should only return defaults for expected errors | 3+ | Documented in typescript-patterns.md, architecture-patterns.md; identified in adversarial review across multiple PRs | 2026-02-26 | **None** — knowledge file pattern. Needs Tier 0 grep for `catch.*return \[\]` and `catch.*return null` |
| **unmount-guard-on-async** — async state updates need isMountedRef guard | 3+ | second-brain #140 (sibling pattern not applied), #288 (unmount guard missing on async handler), documented in react-patterns.md | 2026-02-28 | **None** — react-patterns.md documents it. Needs grep for `set[A-Z].*` inside async callbacks in `.tsx` without preceding `isMountedRef` check |
| **stale-react-state** — stale closures, missing useEffect resets, optimistic revert races | 5+ | second-brain #189 (stale imageError), #215 (render-phase setState), #269 (optimistic revert staleness), #272 (stale async/session race), #287 (setTimeout vs await) | 2026-02-28 | **None** — adversarial review blind spot. Needs React-specific Tier 0 grep checks per process-patterns.md |
| **UTC-suffix-in-dates** — `new Date("...")` must include `Z` suffix to avoid timezone bugs | 3+ | second-brain #131 (checklist item present but missed), folio #1 (3 date findings), nanny-app #28 (silent normalization) | 2026-02-23 | **Tier 0 grep** exists in adversarial review. Execution gap, not coverage gap |
| **pattern-siblings** — when fixing a bug class, grep entire codebase for same pattern | 3+ | second-brain #185 (JSDoc audit scope), #198 (identified but not extracted), #206 (identified but not fixed), #265 (4 stale QUERY refs) | 2026-02-26 | **None** — adversarial review Tier 4 item. "Covered but not actioned" is the recurring failure mode |
| **JSDoc-on-exports** — exported functions/components need JSDoc | 3+ | nanny-app #35 (4 of 7 post-push findings), second-brain #185 (JSDoc audit scope miss), #142 (api.ts) | 2026-02-20 | **None** — needs Tier 0 grep for exported functions without preceding JSDoc in changed `.tsx`/`.ts` files |
| **LOC-threshold-miscounting** — agents estimate LOC instead of computing via `git diff --stat` | 3+ | second-brain #250 (81 LOC claimed "under 50"), #259 (217 LOC claimed "under 50 of logic"), command-center #41 (156 LOC claimed "sub-50") | 2026-02-27 | **None** — needs mechanical `git diff --stat` enforcement in the review-skip decision path |
| **CSS-var-undefined** — `var(--name)` referencing undefined custom properties | 2 | second-brain #164 (var(--border), var(--surface-hover) undefined) | 2026-02-20 | **None** — needs Tier 0 grep cross-referencing `var(--` against `--` definitions |

---

## Graduated (Mechanically Enforced — No Longer Tracked)

| Convention | Enforcement | Date |
|---|---|---|
| **button-has-type** — explicit `type` on every `<button>` | ESLint rule `react/button-has-type` | 2026-02-28 |
| **worktree-write-failure** — implementer writes to main repo instead of worktree | Orchestrator gate (startup checklist + post-impl diff check) | 2026-03-02 |

---

## Conventions At Risk (1 violation, monitoring)

These have been violated once. A second violation triggers the escalation rule.

| Convention | Violation | PR | Date |
|---|---|---|---|
| **inline-keyboard-cleanup** — clear Telegram inline keyboards after callback handling | 1 | second-brain #209 | 2026-02-23 |
| **devDependency-pin-consistency** — use consistent pinning strategy (exact or caret) | 1 | second-brain #228 | 2026-02-25 |
| **keep-in-sync-comments** — extract shared code instead of "keep in sync" comments | 1 | second-brain #198 | 2026-02-21 |
| **aria-attribute-pairing** — aria-expanded requires aria-controls | 1 | second-brain #164 | 2026-02-20 |

---

## How This Feeds Into Process

1. **Post-mortem step:** After each post-mortem, the author checks this file and updates violation counts.
2. **Escalation:** When a convention hits 2+ violations, file a GitHub issue for mechanical enforcement.
3. **Resolution:** When enforcement is added, update the Enforcement Status column and add a row to Enforcement Actions Taken.
4. **Audit:** Periodically review the table. Conventions with enforcement and 0 recent violations can be marked "resolved."
