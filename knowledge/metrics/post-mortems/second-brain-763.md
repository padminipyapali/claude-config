# Post-Mortem: PR #763 — fix(scheduler): refine revisions with bare numbers / natural phrasing

**Date:** 2026-06-26
**PR:** [#763](https://github.com/padminipyapali/second-brain/pull/763) (Closes [#761](https://github.com/padminipyapali/second-brain/issues/761))
**Branch:** `fix/refine-bare-number-revisions` → main (squash-merged as `8ec12f2`)
**Time to Merge:** ~4 min on GitHub (created 22:21:14, merged 22:25:24 UTC) — the dev loop ran locally before push; the gap is wall-clock until merge, not active review.
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +201 −38 across 4 files, 1 commit

## 1. What Shipped

Replying to a "schedule my todos" proposal with a natural revision was **silently saved as a THOUGHT instead of refining** — the revision was lost AND a junk thought was created:

- "don't schedule 1" → "Thought saved." (should remove item #1)
- "2 will take 10 minutes" → "Thought saved." (should set item #2's duration to 10 min)

**Root cause.** `looksLikeRefinement` — the deterministic gate that decides whether a reply enters the refine path — was too narrow for how the user actually phrased revisions:
- `extractRefNumbers` required a `#`/`number`/`task`/`item` prefix, so the **bare numbers** "1"/"2" never matched.
- The duration cues were `\b`-bounded singular words (`\bminute\b`), so they **did not match the plural "minutes"/"hours"**.
- "don't schedule" was not in the correction-word set.

So the gate returned `false` → fell through to normal classification → "Thought saved."

**Fix.** Broadened `looksLikeRefinement` to also fire on (a) a **bare standalone 1–3 digit number**, (b) a robust **duration regex** `\d+\s*(min|mins|minute|minutes|hour|hours|hr|hrs)` that catches plurals, and (c) **"don't / do not schedule"** phrasing — negative-guarded so "v2" / "covid19" / "1st" don't trip it. The interpreter prompt + tool schema were taught to treat a **bare number the same as `#N`**, map "don't schedule N"/"skip N" → `remove`, and "N will take X minutes"/"make N an hour" → `setDuration`.

**Why liberal detection is safe.** The interpreter (`interpretRefinement`) is the authority: it sees the numbered proposal and returns `isRefinement=false` for genuine non-refinements (→ falls through to normal classification). A real thought that merely mentions a number ("I have 3 meetings") is not hijacked — at worst it costs one extra LLM call. The gate widening trades a cheap, LLM-rejected false positive for never dropping a real revision.

## 2. Process

Shipped via the **lightweight orchestrator gate** — risk-graduated review, consistent with the recent refine-loop slices (#759 lightweight; #758 full critic for external side effects). This change is refine-internal: it only widens which replies reach the interpreter and adjusts prompt mappings; **no external side effects** (events are created later, only on confirm). So:

- Build / lint / test green: `@second-brain/server` **2368 passed, 48 skipped**.
- Deterministic detection tests added: `looksLikeRefinement` true for the bug phrasings + plural durations + negated scheduling, with the negative guards ("v2"/"covid19"/"1st" stay false); bare-number-derived edits apply (`remove [1]`, `setDuration {2→10}`); and a non-refinement that *trips* the gate → interpreter `isRefinement=false` → falls through (not saved as a refinement).
- **No separate fresh-context critic** ran (lightweight gate).
- **Real-model probe run by the user before merge** (the load-bearing validation — see §3).

No GitHub-side review activity: 0 human reviews, 0 CodeRabbit GitHub review, 0 inline comments (1 Vercel bot comment, excluded). Vercel: SUCCESS.

## 3. The load-bearing validation: a real-model probe as the pre-merge gate

The unit tests **mock the interpreter** — they prove the deterministic detection + apply logic, but prove nothing about whether the *real model* maps the bare-number reply correctly. Green mocks would stay green even with a prompt the live model interprets wrongly. This is the third time this guard has been needed in the refine loop (#735, #739, #761).

To close that gap, the committed dry-run probe (`npm --workspace @second-brain/server run dry-run:refine`) was extended with a **Scenario B** ("don't schedule 1 / 2 will take 10 minutes") and **run by the user against the real model before merge**. It confirmed the live model emits `remove` including `1` and `setDuration` including `{number: 2, minutes: 10}` for the bare-number reply — exactly the prompt-quality assertion the mocked suite cannot make. This was the explicit pre-merge gate in lieu of a fresh-context critic.

## 4. adversarialCatchRate

**Unmeasured (`null`) — critic-skipped shade.** No separate fresh-context critic ran (lightweight gate for this refine-internal, no-side-effect change), so `caught / (caught + escaped)` has **no numerator** — recorded as unmeasured per the metric-integrity rule, **not fabricated** against any baseline. This is the critic-SKIPPED shade (no adversarial signal at all), distinct from a full-critic-ran-clean shade.

The real validation gate was the **user-run real-model `dry-run:refine` probe** (§3), which is the right instrument for a prompt-quality change — a mocked critic round could not have asserted what the probe asserted. **0 post-merge escapes:** PR #763 is the newest merge; no follow-up fix touches `schedule-todos-refine.ts`.

## 5. The recurring class — and the lesson

This is the **third** natural-phrasing miss in the refine loop:
- **#732 / #735** — completion language and indirect dependency phrasing dropped (the gate / parser only matched literal `skip #N`).
- **#761 (this PR)** — bare numbers and plural durations dropped.

The recurring class: **the deterministic gate fronting the LLM interpreter is too narrow for how the user actually phrases revisions, so real revisions are silently lost.** Each fix so far has enumerated the specific phrasings that were missed.

**The generalizable lesson:** when a heuristic gate repeatedly misses natural language *and an LLM authority sits directly behind it that already rejects genuine non-matches*, **widen the gate toward the LLM** — accept cheap false positives the LLM will reject — rather than chasing each new phrasing. The cost of a false positive is one LLM call the interpreter discards (`isRefinement=false` → fall through); the cost of a false negative is a lost revision plus a junk thought. The asymmetry favors a liberal gate. And validate the prompt half with a **real-model probe**, not just mocked tests.

## 6. What Went Well / What to Improve

**Went well:**
- The fix widened the gate *toward* the LLM authority rather than adding a third bespoke phrasing branch — applying the recurring-class lesson rather than re-paying it.
- The real-model probe was treated as a first-class pre-merge gate (Scenario B added and run live), directly covering the one thing mocks can't.
- Negative guards ("v2"/"covid19"/"1st") were added with tests, so the liberal gate doesn't over-trigger on incidental digits.

**To improve:**
- The recurring class (heuristic gate too narrow for natural phrasing, three instances now) suggests the gate widening could be made more principled: a single "does this reply plausibly reference a numbered item or an edit verb?" check that defaults toward the interpreter, rather than an accreting list of regexes. Worth considering if a fourth instance appears.
- A live spot-check post-deploy on the exact bug replies confirms the end-to-end path beyond the dry-run probe.

## Metrics Summary

| Metric | Value |
|--------|-------|
| adversarialCatchRate | `null` — unmeasured (critic-skipped shade; lightweight gate, no critic ran). Real gate = user-run `dry-run:refine` probe. Not fabricated. |
| Post-merge fix rate | 0.0 (no follow-up fix; #763 is newest merge) |
| Pre-merge iteration count | 1 (healthy) |
| Review rounds | 1 |
| GitHub comments | 0 (1 Vercel bot, excluded) |
| Planning quality | complete (Bug + Root cause + Fix + safety rationale + Validation + real-model probe) |
| Fix-up taxonomy | none (1 commit, no fixup commits) |
| Notable validation | real-model `dry-run:refine` Scenario B run as the explicit pre-merge gate (third refine-loop instance of the mocks-can't-catch-prompt-quality guard) |
| CI | Vercel SUCCESS; server suite 2368 pass / 48 skip |
