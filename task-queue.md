# Task Queue

Tasks queued because the target repo had active work in progress. Check `[PENDING]` entries at session start.

---

## [PENDING] Decompose useCreateLook (1,600-line god-hook) by concern

- **Repo:** /Users/padminipyapali/dev/plush-press (`studio/src/hooks/useCreateLook.ts`)
- **Queued:** 2026-07-20 (operator-approved; blocked behind the create-look features PR — feat/builtin-add-look — landing first)
- **Context:** The hook is a deliberate line-for-line port of create-look.html's state
  machine (34 useState atoms) that has since accreted edit mode, Matte remask round-trip,
  story round-trips, catalog return, and the source-look anchor. Every new feature now pays
  a large reading tax and risks invariants it can't see all of.
- **Shape of the work:** Split by concern — seed lifecycle, propagation, edit mode, matte
  round-trip, navigation/return — each keeping the injected-dependencies pattern. The
  NO-LOSS-ON-FAILED-REGEN invariant tests are the safety net; behavior must be
  change-free (this is a refactor PR: no features mixed in, keep it under the PR size cap
  by splitting into 2-3 PRs if needed). Full 3-role team + all four gates (not fast-path).
- **Precondition:** feat/builtin-add-look PR merged + CI green.
