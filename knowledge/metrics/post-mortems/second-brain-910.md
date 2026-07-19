# Post-Mortem: PR #910 — Compact date ranges + max_tokens truncation handling for multi-month calendar queries

**Project:** second-brain
**Branch:** `fix/calendar-query-range-days` → `main`
**Author:** padminipyapali
**Merged:** 2026-07-19T17:52:42Z (squash-merged as `cac3e8a`, closes #906)
**Size:** +594 −26 across 5 files, squash-merged to 1 commit
**Time PR-open → merge:** ~1.8 minutes (merge-when-ready; all review done locally pre-push)

## Summary

Fixed a silent failure on multi-month calendar queries ("check September through December" → generic "I couldn't generate a clear answer about your calendar"). The forced `calendar_answer` tool call ran at `max_tokens: 500` while the tool schema forced the model to enumerate every `YYYY-MM-DD` in `availability.days` / `agenda.days`; a ~122-day span overflowed the budget, the tool JSON truncated mid-array, parsing degraded to the generic malformed fallback, and nothing signalled truncation.

The fix has three independent parts, each addressing a distinct link in the failure chain:

- **Compact `range: {start, end}`** added to the availability and agenda schema sections; `expandDateRange` expands it deterministically (pure UTC string arithmetic via `addDaysToDateString`), clamped at `MAX_QUERY_WINDOW_DAYS` (365) with a `clamped` flag, and `mergeDayLists` unions it with any explicit `days` (sorted, deduped). Malformed/inverted ranges are ignored, never thrown.
- **`max_tokens` 500 → 1500** for headroom against the worst-case legitimate payload.
- **`stop_reason === "max_tokens"` detection:** a truncated-and-malformed reply now returns an actionable "narrow the date range" message instead of the generic fallback, and logs `{ queryLength, mode }` — metadata only, no query text.

BUG-031 was documented in `docs/features/_cross-cutting/bugs.md` (forced-tool + low-max_tokens silent-truncation bug class), and the sibling sweep (other forced-tool calls sharing the truncation risk) was filed as #909.

## What went well (process signals)

1. **The fix addressed the whole failure chain, not just the reported symptom.** The naive fix is "raise max_tokens." That alone leaves the array-enumeration schema as a latent bomb (any wider span re-truncates) and still fails silently when it does. Instead the PR removed the need to enumerate (compact range), gave budget headroom, AND made the residual truncation loud (stop_reason detection). Three orthogonal mitigations for one bug class — the pattern already captured in `llm-integration.md`.

2. **CodeRabbit caught two load-bearing MAJORs past a critic APPROVE.** Gate order was critic (APPROVE, 3 nits, 2 fixed) → CodeRabbit CLI → full adversarial checklist → delta re-verify. CodeRabbit found the two issues the critic's APPROVE had passed over: a **silent range clamp** (the 365-day cap dropped requested days with no user-facing signal) and **PII in logs** (the max_tokens warning logged the query text). Both were fixed before the adversarial checklist ran — which is exactly why that checklist scored 11 PASS / 0 FAIL. The clean checklist is evidence an earlier gate did the catching, not that the PR arrived clean.

3. **The clamp fix reasoned about truncation direction.** The clamp note is PREPENDED, not appended, "because `capTelegramText` truncates from the tail" — a trailing note would be dropped exactly when a clamp occurred. This is the same output-budget-arithmetic discipline that caught the #833 append-past-the-cap crash: think about which end of a length-bounded output gets cut.

4. **Co-fire caveat handling was tested explicitly.** The planner's independent "~12 months" fetch-cap note is suppressed when the expansion clamp note is already present, and there is a dedicated test asserting exactly one caveat fires — a real double-caveat UX bug pre-empted with an assertion.

## Process friction

- **None material.** No GitHub review rounds, no post-push comments, no CI failures, no post-merge fixes. The one signal worth naming is that the two substantive findings (silent clamp, PII-in-logs) came from CodeRabbit rather than the critic — both are recurring CodeRabbit-vs-critic classes (a cap/clamp applied without surfacing it; PII in a new log line) that a structural code critic routinely under-rates. This is why the post-critic CodeRabbit pass is not redundant.

## Metrics

- **Review rounds:** 1 (0 CHANGES_REQUESTED; no GitHub reviews — merge-when-ready after local gates).
- **Comments:** 0 inline, 0 substantive general (only the Vercel bot comment).
- **CodeRabbit:** 2 findings, 2 fixed, 1 iteration — both MAJOR (silent clamp, PII in logs).
- **Adversarial checklist:** 0 findings (11 PASS / 0 FAIL) — because CodeRabbit had already cleared the two issues before it ran. Critic (separate role) found 3 nits, 2 fixed.
- **Measured `adversarialCatchRate`: 1.0** — 4 substantive findings (2 CodeRabbit MAJORs + 2 critic nits fixed) all caught and fixed pre-merge; 0 post-push comments; 0 post-merge fix PRs (this is the latest merged PR as of the post-mortem). Evidence-based, not hardcoded.
- **Pre-merge catch by step:** 4b (critic/internal) 2 fixes, 4c (CodeRabbit) 2 fixes, 4a/4d/post-push 0.
- **Pre-merge iteration count:** 1 (healthy) — a single linear local gate pass, no review-fix-review loop.
- **Fix-up taxonomy:** correctness 1 (silent clamp), defensive-coding 1 (PII in logs), style 2 (critic nits — specifics not captured; estimated as minor/style).
- **CI:** all SUCCESS (Vercel + Vercel Preview Comments). Server suite 3273 passed / 57 skipped; `response.calendar-query.test.ts` 61 pass, `calendar-query-handler.test.ts` 25 pass; lint + typecheck clean.
- **Planning quality:** complete — Summary, Changes, Behavior note, Review, Tests sections all present, with an explicit root-cause narrative. Minor gap: no formal "Performance & Cost Impact" header despite the `max_tokens` 500→1500 change (a per-call cost increase); the change is discussed but not sectioned.
- **Step compliance / step timing:** not tracked (PR body lacks a `Steps skipped:` line and a `## Step Timing` section). The `## Review` section documents that critic + CodeRabbit + adversarial + delta re-verify all ran; recorded as `null` per the "missing formal line → null" rule rather than inferred.

## Recommendations

1. **When a critic returns APPROVE/SHIP, still run CodeRabbit — the two classes it reliably out-catches are (a) a cap/clamp/truncation applied without surfacing it to the user, and (b) PII/query-text in a new log line.** Both appeared here and both are things a structural critic under-rates. Captured under process-patterns → Critic Blind Spots (#779 entry, confirmed #910).
2. **Add a "Performance & Cost Impact" header even to bug-fix PRs that change an LLM call's `max_tokens` or model.** A 3× token-budget increase on a per-query forced tool call is a real recurring cost, and the planning-checklist section is the place it should be surfaced, not buried in prose.
3. **Track the #909 sibling sweep to closure.** The forced-tool + low-`max_tokens` truncation class is confirmed to exist in other calls; the audit trigger (`grep 'tool_choice: { type: "tool"'` and inspect each `max_tokens` against worst-case output) is already recorded in `llm-integration.md`. Close the loop by auditing the siblings before another multi-month-style span trips one of them.
