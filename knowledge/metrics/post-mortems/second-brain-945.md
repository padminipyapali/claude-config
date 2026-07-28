# Post-Mortem: PR #945 — Today's priorities, server half (PR-A of #942)

**Project:** second-brain
**Branch:** `feat/today-priorities-server` → `main`
**Author:** padminipyapali
**Merged:** 2026-07-28T00:06:07Z (3 commits; Refs #942, closed by PR-B)
**Size:** +1419 −33 across 24 files
**Time PR-open → merge:** ~3.1 h (merge-when-ready; all review done locally pre-push)

## Summary

Server half of "today's priorities": TODOs tagged `pinned-today` with a due date of today, surfaced on the `GET /today-card` payload, mutable through `POST`/`DELETE /entries/:id/pin-today`, applied automatically by the Morning Journal seal path, and listed by a new `/today` Telegram command. Adds `utils/local-date.ts` so the four places that ask "what day is it for the user" share one recipe. Living spec: `docs/TODAY_PRIORITIES_SPEC.md`.

Two bugs were fixed along the way and are recorded in `docs/BUGS.md`: **BUG-043** (a bare `UPDATE` that silently affected zero rows) and **BUG-044** (write-into-invisibility on two routes). The design reversal — a dedicated `pinned-today` tag rather than overloading `daily-intention` — is in `docs/DECISIONS.md` under 2026-07-27.

## The headline: the sibling sweep was skipped

BUG-044 is one bug class that occurred on **two** routes. A write satisfies part of a conjunctive definition (`pinned-today` tag AND `due_date` = today AND `status <> 'WONT_FIX'`), returns 200, and the row is then filtered out of every read — so the user gets success and sees nothing.

The pin route's instance was found and fixed by the human-style adversarial pass. The **identical** instance on the journal-seal route survived that same pass and was caught only by CodeRabbit.

The root cause is not inattention, it is sequencing. Tier 4 of the checklist already carries a **Pattern siblings** item ("grep entire codebase for same pattern"), and the sweep does get run — while the reviewer is still hunting. Once a finding is written up and patched, the fix reads as closure and the grep never happens. The sweep is filed under the hunt when it belongs to the fix.

This is captured in `~/.claude/knowledge/adversarial-review.md` (Tier 4, `Pattern siblings`, verified present and accurate as of this post-mortem). The recorded countermeasure is: make the sweep a step of the FIX; grep for the pattern's other instances **before** marking a finding resolved, and record the grep command plus every matched file and its disposition as evidence. A finding with no accompanying sibling-grep output is not finished.

**Is that countermeasure enforceable, or aspirational?** Honestly: partly aspirational as written, and the enforceable part is worth separating out.

- **Aspirational:** "remember to sweep at fix time" is the same class of instruction as "remember to sweep," which is what just failed. Re-stating a rule that was already in the checklist, in a slightly different position, does not change the incentive that caused the miss.
- **Enforceable:** the *evidence* requirement is. The project already mandates structured PASS/FAIL/SKIP evidence per checklist item (universal convention #10). Extending that to "each FAIL/fixed finding carries a `grep` invocation and a per-file disposition list" makes the omission **visible in the artifact** rather than invisible in the reviewer's head. The orchestrator can reject a review report that reports a fixed finding with no grep block, which is a real gate, not a reminder.
- **Also enforceable, and cheaper:** the corollary already recorded — treat a CodeRabbit finding that is a sibling of an already-fixed bug as a **signal that the sweep was skipped**, not as a bonus catch. That is a detector, and this PR is its first confirmed firing.

The realistic assessment is that the evidence-format change will catch the omission after the fact reliably, and will prevent it only to the extent that a reviewer who knows they must produce grep output runs the grep. That is still a meaningful improvement over the status quo, but it should not be recorded as "solved."

## Review-stage yield

| Stage | Defects accepted | When | Fix cost |
|---|---|---|---|
| Adversarial **plan** review | 10 | pre-implementation | edit a document |
| Fresh-context **diff** review (critic) | 3 | post-implementation | edit code + re-test |
| CodeRabbit CLI | 3 (of 4 raised) | post-implementation | edit code + re-test |
| Pre-PR adversarial checklist | 2 (1 fixed, 1 deferred → #944) | pre-push | edit code + re-test |
| GitHub review (post-push) | 0 | — | — |
| Post-merge | 0 | — | — |

**The plan review had by far the best yield per cost** — 10 defects at the lowest fix cost available, since nothing had been built. One of them was structural rather than local: the pin toggle had been designed onto `EntryCard`, a component only the feed renders, while the TODOs panel renders `LedgerCard`. Built as planned, the feature's primary control would have been absent from the surface it exists for, and the miss would have surfaced at manual-test time — after a full implementation pass, in the PR-B worktree, with tests written against the wrong component.

That argues for reweighting toward the plan stage, but the honest version of the argument is narrower than "shift everything left":

- The plan review caught the `EntryCard` error because "which component does this view actually render" is answerable from a plan plus a grep. Structural and entry-point defects are cheap to find at plan altitude.
- The two defects that mattered most in this PR were **not** findable at plan time. BUG-043 required reading the SQL body of an existing method (`updateTodoDueDate`) that the plan only named. BUG-044 required holding the write path and the read query side by side, which needs both to exist.

So the reweighting worth making is: **the plan review should be scoped deliberately at structure and entry points** — component/render graph, all entry points, data flow — rather than run as a generic once-over, and it should be treated as non-skippable because its findings are nearly free. It does not reduce the value of the diff-stage gates, which caught the bugs that would have shipped.

Precision note: CodeRabbit raised 4 and 3 were accepted; the rejected one was a misread of what the PR contained. 75% precision at effectively zero human cost keeps it clearly worth running, and it caught the one defect the human passes structurally missed.

## Where the latent bug was hiding

BUG-043 was pre-existing and had been live for months. `updateTodoDueDate` ran a bare `UPDATE todo_status SET due_date = ... WHERE entry_id = ...`, which matches nothing when a TODO has no `todo_status` row — a state that legitimately exists, because `createTodoEntry` downgrades a failed status insert to a warning. `pg` reports zero affected rows as success.

It was found only because a new feature made the write's success *observable*: the priorities query INNER JOINs `todo_status`, so a pin that silently no-op'd produced a 200 and an item on no surface.

The generalizable point: **latent bugs accumulate in write paths whose callers never assert the result.** Nothing downstream of `updateTodoDueDate` checked that a due date had landed; the only consumer was eventual display in a list the user does not cross-check against an expectation. There was no assertion pressure anywhere in the chain, so the failure had no way to become visible. Three sibling writers with the same shape were found and filed as **#944** — meaning the class was systemic, not a one-off.

This class is grep-detectable (`UPDATE` statements with no `rowCount` inspection), which makes it a Tier 0 automation candidate rather than a judgment call.

## Metrics

- **Review rounds:** 1 (0 CHANGES_REQUESTED; no GitHub reviews — merge-when-ready after local gates).
- **Comments:** 0 inline, 0 substantive general (only the Vercel bot comment).
- **`adversarialCatchRate`: 1.0 — measured, shift-left definition.** Numerator/denominator stated explicitly: 18 accepted defects total (10 plan review + 3 critic + 3 CodeRabbit accepted + 2 pre-PR checklist), 18 caught before push, 0 post-push review comments, 0 post-merge fix PRs. Nothing escaped the local gates, so the shift-left rate is 18/18.
- **Secondary, and the more informative number — adversarial *in-domain* catch rate: at most 0.923, and unmeasurable below that.** At least one defect (the seal-route instance of BUG-044) is explicitly covered by the checklist's Tier 4 `Pattern siblings` item and was missed by both adversarial passes; CodeRabbit caught it. That gives 12 in-domain catches out of 13 classifiable defects. The remaining 2 CodeRabbit-accepted findings **cannot be classified** as covered-or-not, because the CodeRabbit CLI output was not preserved in any artifact — only the accepted/rejected counts survived into the PR body. If both were also checklist-covered, the true rate is 12/15 = 0.80. The honest range is **[0.80, 0.923]**. This is a tooling gap worth closing: preserve the CodeRabbit CLI output alongside the PR so this metric is computable rather than bounded.
- **Post-merge fix rate: 0.0 within the observation window.** No PRs merged after #948. The window is only hours wide, so this is "nothing yet," not a settled figure.
- **Pre-merge catch by step:** plan-review 10, 4b (internal/critic) 3, 4c (CodeRabbit) 3, 4d (adversarial checklist) 2, post-push 0.
- **Pre-merge iteration count:** 4 (plan round, critic round, CodeRabbit round, pre-PR checklist round). Above the "2 = normal" band, but each round was a distinct gate rather than a re-litigation of the same finding, so this reads as pipeline depth, not friction.
- **Fix-up taxonomy:** correctness 2 (BUG-043 upsert, BUG-044 both routes), defensive-coding 1 (snoozed-item dead number), test-quality 1 (the `snoozed_until` string-absence assertion replaced with a WHERE-predicate assertion), documentation 1. Legacy fix-up ratio 0.33 (1 of 3 commits classifies as fix — the taxonomy counts defects fixed, not commits, since several were folded into the feature commit).
- **CI:** all checks SUCCESS. 3,503 server tests pass (up from 3,484 on `main` as review findings became tests); lint and `tsc` clean for server + shared.
- **Planning quality:** complete — living spec written before implementation, decisions recorded, follow-ups filed (#943, #944), explicit issue linkage.
- **Step compliance:** full loop (plan → adversarial plan review → implement → test → critic → CodeRabbit → adversarial checklist → CI → push); assessment good. **Step timing:** not tracked (no `## Step Timing` section in the PR body) — same gap as #911/#912.

## Recommendations

1. **Make sibling-sweep evidence a required field of a resolved finding, not a checklist line.** A review report that marks a finding fixed without a `grep` invocation and a per-file disposition list should be rejected by the orchestrator. This is the enforceable half of the countermeasure already recorded in `adversarial-review.md`; the "remember to sweep at fix time" half is not.
2. **Treat a CodeRabbit finding that is a sibling of an already-fixed bug as a process alarm.** It means the sweep was skipped. This PR is the detector's first confirmed firing; log future firings so the rate is trackable.
3. **Scope the adversarial plan review explicitly at structure and entry points.** Its 10 findings were the cheapest in the pipeline and included one (`EntryCard` vs `LedgerCard`) that would have wasted an implementation pass. Component/render-graph and entry-point questions are exactly what plan altitude answers well; keep it non-skippable and aimed there.
4. **Preserve CodeRabbit CLI output as a PR artifact.** Its absence is why this PR's in-domain catch rate is a range rather than a number.
5. **Promote "UPDATE with no `rowCount` check" to a Tier 0 automated grep.** BUG-043 was latent for months and had three siblings (#944) — the class is systemic and mechanically detectable, so it should not consume manual-review budget.
