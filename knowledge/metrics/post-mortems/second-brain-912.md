# Post-Mortem: PR #912 — Wire free-days search into the calendar-query path, PR-B of #907

**Project:** second-brain
**Branch:** `feat/free-days-wiring` → `main`
**Author:** padminipyapali
**Merged:** 2026-07-19T19:34:02Z (squash-merged to 1 commit `095d0af`; Closes #907)
**Size:** +953 −58 across 11 files
**Time PR-open → merge:** ~45 seconds (merge-when-ready; all review done locally pre-push)

## Summary

PR-B of #907 (free-days search): wires the pure module shipped in PR-A (#911) into the calendar-query path. "Find me 3–4 day windows this year when I'm not traveling" now returns a deterministic answer computed from the full fetched calendar. Closes #907.

- **`ooo-context.ts`** — `resolveOwnerOoo` now returns `{ ownerOut, classifierFailed }` so a classify throw is distinguishable from "no trips." On failure the free-days path degrades to over-marking (multi-day all-day blocks count as travel) with an explicit reduced-confidence disclosure, never a falsely-free answer. `schedule-todos-proposal` behavior unchanged.
- **`freeDays` tool section** in `calendar_answer` — `{ minDays (clamped [2,60]), maxDays?, range? }`; precedence `slots > freeDays > availability > agenda`; a FREE-DAYS RULE prompt restricting it to multi-day travel-gap intent (hourly / single-day questions stay on availability).
- **`answerFreeDays` render** — windows with bounding trip context, open-ended honesty (`Now –`, `N+ days — through the end of what I can see`), 12-window cap, oversized-window hint, softened empty-calendar answer, longest-gap zero-result messaging, coverage/clamp notes (#910 dedup applies).
- **Unified span walk** — `ownerOooDateSummaries` and `schedule-todos` now delegate to the module's `eventLocalDates`, capped at `MAX_QUERY_WINDOW_DAYS` (365) — a pure runaway guard that never truncates a real event within any query horizon.

## What went well (process signals)

1. **The collapsed review loop stayed safe because the final gate re-ran after the fix.** As a follow-up PR of an already plan-reviewed feature, #912 ran a collapsed loop (critic + a single final adversarial gate rather than a fresh full plan review). That is legitimate — the plan was reviewed at PR-A — and it worked precisely because the final adversarial gate ran on the post-fix HEAD, catching a bug the fix round had introduced.
2. **The final gate caught a fix-introduced regression the critic's fix created.** The critic's should-fix (an unbounded span-walk regression: the newly-shared `eventLocalDates` was less defensive than the inline code it replaced) was fixed by adding a cap — and that fix itself carried the donor caller's horizon assumption. Caught pre-merge, delta-note confirmed.
3. **Asymmetric-cost fail-direction held end-to-end.** The classifier-failure signal degrades to over-marking travel (conservative) rather than under-marking (falsely free) — the same fail-direction locked in PR-A's plan, now wired through the runtime path with an explicit reduced-confidence disclosure.
4. **Clean shift-left.** CodeRabbit CLI clean both rounds; 0 GitHub-review comments; 0 post-merge fix PRs (confirmed by searching merged PRs > 912). +24 tests including a new `ooo-context.test.ts` for classifier-failure semantics; full server suite 3320 passed; lint + typecheck clean.

## Process friction

- Two review sub-agent crashes on API errors mid-session; both resumed cleanly with no lost work. Infra noise, not a process defect.
- Minor: the PR body used the narrative `## Review` / `## Tests` format rather than the machine-readable `## Local Review` / `Steps skipped:` / `## Step Timing` sections, so step compliance and timing were reconstructed from the body + handoff. Squash-merge (1 commit) also hides discrete fix commits — step attribution comes from the `## Review` narrative, not `git log`. Same gap as PR-A (#911).

## The two pre-merge catches (root of the learnings)

1. **Critic (internal review):** the shared `eventLocalDates` helper dropped the defensiveness of the inline span-walks it replaced — an unbounded walk in a shipped path. Fix: add a cap.
2. **Final adversarial gate:** the fix's cap VALUE (60 days) was lifted from the DONOR caller (`schedule-todos`, whose proposal horizon is short) but the free-days path scans the whole YEAR — so a 60-day cap would treat days 61+ of a long absence as **falsely free**, the exact asymmetric-cost failure the feature exists to prevent. Fix: `MAX_QUERY_WINDOW_DAYS` (365), a pure runaway guard. One line; delta-note re-check.

Two reusable rules captured in `process-patterns.md`:
- **Correctness Gaps:** a hard-coded LIMIT in a newly-shared helper is only correct if it is the MAX over every caller's range (or each caller passes its own) — a value lifted from the donor call site is a landmine for the wider caller.
- **Review Discipline:** the FIX for a caught finding is unreviewed code; re-run the final gate on the post-fix HEAD, especially on a collapsed follow-up loop, because fixing X can introduce Y.

## Metrics

- **Review rounds:** 1 (0 CHANGES_REQUESTED; no GitHub reviews — merge-when-ready after local gates).
- **Comments:** 0 inline, 0 substantive general (only the Vercel bot comment).
- **Adversarial review:** measured catch rate **1.0** — 2 issues found by the local gates (critic span-walk regression; final-gate cap-horizon mismatch), both fixed pre-merge, both in-domain for the checklist (correctness / caller-safety / defensive coding); 0 post-push comments; 0 post-merge fix PRs.
- **CodeRabbit CLI:** clean both rounds, 0 findings (10 files).
- **Pre-merge iteration count:** 2 (normal) — the critic fix round, then the final-gate fix round; the second was created by the first.
- **Pre-merge catch by step:** 4b (internal/critic) 1, 4d (adversarial gate) 1; 4a/4c/post-push 0.
- **Fix-up taxonomy:** 2 correctness (span-walk regression, cap-horizon mismatch). Legacy fix-up ratio 0.0 — squashed to 1 clean feature commit.
- **CI:** all SUCCESS (Vercel + preview). Full server suite 3320 passed; lint + typecheck clean.
- **Planning quality:** complete — Summary, Changes, Review, Tests; explicit `Closes #907` and the remaining Stage-5 manual Telegram routing verification noted.
- **Step compliance:** full loop reconstructed (plan-reviewed at PR-A → implement → test → simplify/CodeRabbit/adversarial → CI → push), collapsed follow-up variant; assessment good (no post-merge issues). **Step timing:** not tracked (no `## Step Timing` section).

## Recommendations

1. **On any collapsed follow-up-PR review loop, the final adversarial gate MUST run on the post-fix HEAD.** #912 is the proof case: the fix for the critic's finding introduced a fresh false-free bug that only the post-fix gate caught. Never treat "critic said fix X, I fixed X" as done on a collapsed loop — the fix is exactly where a fresh regression hides. Captured in `process-patterns.md` → Review Discipline.
2. **When consolidating callers onto a shared helper, audit every hard-coded limit/constant for donor-caller bias.** Set the guard to the widest safe value over all callers, or have each caller pass its own bound. Captured in `process-patterns.md` → Correctness Gaps.
3. **Adopt the structured PR-body sections** (`## Local Review`, `Steps skipped:`, `## Step Timing`) so compliance and timing extraction are automatic — same recommendation as #911; both PRs in this feature reconstructed the data by hand.
