# Post-Mortem: second-brain PR #841 — reminder override, keyboard-nav a11y, completed-today dimming + state mirroring

**Date:** 2026-07-01
**PR:** [#841](https://github.com/padminipyapali/second-brain/pull/841) — Closes [#839](https://github.com/padminipyapali/second-brain/issues/839).
**Branch:** `fix/web-todo-thread-panel-bugs` → main (squash-merged, 1 commit `d69d732`)
**Time to Merge:** ~0.56h wall-clock (created 2026-07-01T20:26:28Z, merged 21:00:08Z ≈ 34 min). Lightweight-review lane ran pre-push; the window is wall-clock until merge, not active GitHub review.
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +147 −9 across 7 files, 1 commit (~40 net source LOC; the rest is added tests in `TodoPanel.test.tsx`, `ThreadPanel.test.tsx`, `hooks.test.ts`)

## 1. What Shipped

Four verified web-frontend bugs, all surfaced by a CodeRabbit run and confirmed against `origin/main`:

- **B1 (correctness).** In `TodoPanel`, a manual due-date override wins for the due date, but the reminder parsed from the same free-text was still armed — scheduling a reminder for a time the user had discarded. Fix: derive `reminderISO = formDueDate ? null : (detection?.reminderISO ?? null)` and gate arming on it. The due date and the non-override path are unchanged.
- **B2 (a11y correctness).** A related-entry card is `role="button"` with an `onKeyDown` that navigated on Enter/Space even when a child star/dismiss button was the key target (those children only `stopPropagation` on click, not keydown), so keyboard-activating them also navigated the card. Fix: `if (e.target !== e.currentTarget) return;` as the first line of the card's `onKeyDown` — only key events originating on the card itself navigate. Card Enter/Space and click nav preserved.
- **B3 (a11y/style).** `.todo-bucket-group--completed-today { opacity: 0.72 }` dimmed the whole card subtree including focus rings. Fix: move the dimming onto the bucket header (`.todo-bucket-group--completed-today .bucket`) so cards and focus rings are full-opacity.
- **B4 (correctness/state).** `completedTodayTodos` is a distinct query, not a slice of `completedTodos`; the entry mutators never updated it, so editing a completed-today item stayed stale until a full reload. Fix: add `completedTodayTodosRef` and mirror `completedTodayTodos` in the optimistic + revert paths of `updateEntry`, `updateDueDate`, `setReminderForTodo`, and `reformatEntry`, matching the existing `completedTodos` pattern exactly.

## 2. Development Loop

Pipeline: CodeRabbit-surfaced bug batch → triage (verify each against `origin/main`) → single-pass implement (one squash commit) → lightweight local-review lane (adversarial review 4c only; critic + in-loop CodeRabbit 4b intentionally skipped per the <~100 LOC lightweight-review rule) → SHIP → adversarial gate PASS → self-merge. **Gates:** lint clean, web build/tsc clean, full web suite **447 passed / 0 failures**, Vercel Preview CI SUCCESS. No GitHub reviews or inline comments (solo workflow; all review pre-push; the only PR comment is the Vercel bot).

This is a textbook small-fix lane: 4 tightly-scoped, independently-verifiable frontend fixes at ~40 source LOC, each landed with a matching regression test (including a deliberate B2 over-correction guard — "card Enter/Space still navigates").

## 3. Adversarial / Review Effectiveness — adversarialCatchRate = null (critic-ran-clean shade)

**adversarialCatchRate is `null`, NOT 1.0.** The adversarial review (4c) ran on this diff and returned **SHIP** with only minor, non-blocking test-coverage-gap notes — it caught **0 in-scope defects** and **0 escaped** post-merge. With a 0/0 numerator/denominator there is no rate to report: `caught / (caught + escaped) = 0 / (0 + 0)` is undefined, so it is recorded as the **critic-ran-clean null shade** (same as #830), explicitly distinct from the **measured found-and-fixed 1.0** shade of #828 (1/1), #831 (4/4), #833 (1/1), and #837 (1/1) where a review step caught a genuine would-be-broken-merge blocker.

Why this is honest and not a fabricated 1.0: a 1.0 asserts "a gate caught a real defect that would otherwise have merged." Nothing here did — the four fixes were correct on first implementation and the gate found nothing to fix. Reporting 1.0 would manufacture catch-effectiveness the review never demonstrated. `null` correctly says "the gate ran and was clean; there is no catch-rate signal from this PR."

- **Numerator (defects caught by a review step): 0.**
- **Denominator (caught + escaped): 0** — post-merge escapes = 0 (no follow-up PR touches `TodoPanel.tsx`, `ThreadPanel.tsx`, `hooks.ts`, or `App.css`).
- **preMergeCatchRateByStep:** all zero (single implementation pass, 0 fix commits).

Note the provenance distinction: CodeRabbit *did* surface these four bugs — but that was a **pre-work discovery run against existing `main` code**, i.e. it authored the issue (#839), not an in-loop 4b review of this PR's *new* code. The in-loop review that graded this PR's own diff was the adversarial gate, and it ran clean.

## 4. Process Learning — CodeRabbit against a stale local `main`, triaged by provenance into three buckets

The CodeRabbit run that seeded this work was executed against a **stale local `main`**, so its raw finding set was polluted — the same stale-base failure mode documented in #831 (see `process-patterns.md` → Stale-Base Detection). What makes #841 a useful reinforcement is that the triage step **separated the findings by provenance into three distinct buckets** instead of acting on the raw list:

1. **Real, in-scope bugs on current `main`** → verified against `origin/main` and became this PR (B1–B4 / #839).
2. **A false positive** → a `fetchRelatedEntries` response-envelope finding that did not reproduce against current source; correctly dropped, not "fixed."
3. **In-flight code owned by a different branch/issue** → todo-scheduling correctness findings that belong to `feat/schedule-todos-propose`, filed as **#842 (OPEN)** rather than pulled into this unrelated fix PR.

Only bucket 1 was actioned here; bucket 2 was discarded with evidence; bucket 3 was routed to its owning feature. This is the correct discipline for a stale-base / mixed-surface CodeRabbit run: **classify each finding by provenance (this PR's diff vs. false positive vs. another feature's in-flight code) before fixing anything** — acting on the raw list would have either "fixed" a non-bug or dragged unrelated in-flight todo-scheduling code into a 40-LOC frontend fix, blowing scope. Captured as a strengthening of the existing stale-base CodeRabbit entry in `process-patterns.md`.

## 5. Planning Quality

PR body is **complete** for a small fix: Problem (B1–B4 each named with the root cause), Fix (per-bug, noting what stays unchanged — the due date, the non-override path, card nav), Tests (per-file, with the full-suite count 447/0), Designs ("no new UI surface"), Closes #839. No explicit Performance & Cost section — acceptable here: pure client-side behavior/state/CSS fixes with no new API calls, no added query load, and one extra `useRef` (negligible). Scope is clean: one squash commit, no revert/redesign churn, branch lifetime ~34 min.

## 6. Metrics Summary

| Field | Value |
|-------|-------|
| Review rounds | 1 |
| Total comments (non-bot) | 0 |
| localReview.coderabbit | null (no `## Local Review` section; the seeding CodeRabbit run was pre-work discovery, not in-loop 4b) |
| localReview.adversarial | 0 found / 0 fixed (gate ran clean, SHIP) |
| adversarialCatchRate | **null** (critic-ran-clean 0/0 — NOT a fabricated 1.0) |
| postMergeFixRate | 0.0 (0 escapes; #842 is separate in-flight work, not a fix of this PR) |
| preMergeIterationCount | 1 (single implementation pass) |
| Fix-up taxonomy | all zero (0 fix commits) |
| Step compliance | 8/9 (89%) — 4b (in-loop CodeRabbit) skipped per lightweight lane; 4a folded into single-pass implement; assessment: good |
| Planning quality | complete |
| PR size | 156 (147 add / 9 del) |
| Time to merge | ~0.56h wall-clock (loop ran pre-push) |

## 7. Recommendations

1. **Keep classifying stale-base CodeRabbit findings by provenance before touching code** — this PR's three-bucket split (real / false-positive / other-feature) is the model; it prevented both a false "fix" and a scope blowout. (Now in `process-patterns.md`.)
2. **Record the review lane explicitly.** No `## Local Review` / `Steps skipped:` line meant the lane had to be reconstructed from evidence. A one-line `Steps skipped: 4b (in-loop CodeRabbit) — reason: <~100 LOC lightweight lane; findings pre-sourced from a CodeRabbit discovery run` would make the metric pipeline self-describing (recurring recommendation across recent small-fix PRs).
3. **The null-shade discipline is working** — do not let a clean adversarial gate be coded as 1.0. `null` here is the honest signal.
