# Post-Mortem: PR #948 — Today's priorities, web half (PR-B of #942)

**Project:** second-brain
**Branch:** `feat/today-priorities-web-v2` → `main`
**Author:** padminipyapali
**Merged:** 2026-07-28T00:08:41Z (1 commit; Closes #942)
**Size:** +757 −19 across 10 files
**Time PR-open → merge:** ~31 seconds (merge-when-ready; all review done locally pre-push)

Companion to `POST_MORTEM_PR945.md` (server half). Session-level process findings that span both PRs are recorded here, since PR-B is the last of the pair.

## Summary

The web half: a "Today's priorities" section at the top of the Today card with a done-count, inline complete checkboxes and a per-row unpin control; a pin toggle on `LedgerCard` rows in the TODOs panel; and pinned items deduped out of the Due and Active lists. Introduces `useFeedRefreshEffect`, packaging a subscription pattern `useFeed` and `useTodayCard` were already duplicating.

The pin toggle landed on `LedgerCard` rather than `EntryCard` as originally planned — a correction made by PR-A's adversarial **plan** review, since `EntryCard` is rendered only by the feed and would have put the feature's primary control nowhere near the TODOs panel.

## The headline: a defect class diff-scoped review structurally cannot catch

PR-B's worst defect was that the feature's core loop was broken **in both directions**, and neither break appears anywhere in the diff.

- **Pin → card.** Pinning in the TODOs panel called the panel's own local `reload()`. The Today card refetches only when the shared feed-refresh signal changes or the window regains focus, so the card kept rendering the old priorities list, a stale done-count, and the pinned todo still sitting in the Due column — until the user tabbed away and back.
- **Unpin → panel.** Worse, because it rendered a false claim. Unpinning from the hero card *did* bump the shared signal, but the TODOs panel doesn't subscribe to it and stays mounted once the feed has loaded. Its rows kept rendering a lit, `aria-pressed="true"` pin labelled "Unpin from today's priorities" for a todo the server no longer considered pinned. Clicking it fired a second DELETE, which is idempotent, so it self-corrected — but the UI was lying until then.

**The bug lived in what the code did not call.** Diff review reads added and changed lines; a missing subscription is invisible in added lines by construction. No amount of care applied to the diff would surface it, because the diff is the wrong artifact. This is the same family as universal convention #8 (the plush-press `styleId` stripper, where the bug lived in *unchanged* writers) — absence bugs, where correctness depends on code that isn't in the changeset.

The reviewer found it by **tracing the refresh channel end-to-end** rather than by reading the diff: starting from each mutation, asking which components display data derived from what the mutation changed, and checking each one's refresh trigger.

**Should that go in the checklist?** Yes, and as a category-gated item rather than a universal convention, since the convention budget is full at 10/10 and this only fires on cross-component state changes. Proposed shape:

> **Mutation → refresh-channel trace (fires when a PR adds or changes a mutation whose result is displayed outside the mutating component).** For each mutation, enumerate every currently-mounted component that renders data derived from what the mutation changed, and state each one's refresh trigger by name. Trace both directions independently — A mutating and B displaying is a different path from B mutating and A displaying, and they fail separately. A component that stays mounted and does not subscribe to the shared invalidation signal is a defect, not an optimization.

Both directions being broken here is the load-bearing detail: a reviewer who checks only the direction the PR obviously implements finds one of two bugs. The bidirectional requirement matches the existing planning rule about bidirectional state coverage, so it is an extension of an accepted idea rather than a new one.

## Session-level process friction: orchestration reliability

Every subagent spawned in this session — the planner, both critics, both implementers, and the adversarial gate — **went idle without delivering its report**, requiring an explicit follow-up `SendMessage` each time. Six of six. That is not an outlier to be noted; at a 100% rate it is the expected behavior of the current protocol, and the orchestrator's per-agent cost should be budgeted as spawn + poll + relay rather than spawn + receive.

The compounding cost is that several reports also needed independent verification, and in one case the verification mattered. A critic's rationale, relayed by the orchestrator, claimed that an unstubbed mock would degrade silently to `[]` and let a test pass vacuously. That was wrong: the eager `Promise.allSettled` array throws synchronously and produces a 500, so the test fails loudly. The orchestrator caught it and had to issue corrections to both the user and the implementer — a wrong-rationale relay is more expensive than a missing report, because it propagates.

Assessment of "the protocol should require agents to deliver results as their final action":

- **Worth stating, but it is not a gate.** Whether an agent's last action is a report is a property of the agent's own behavior; the orchestrator cannot enforce it, only detect its absence. Writing the requirement into the protocol will help at the margin and will not take the 6/6 rate to 0/6.
- **What is actually actionable** is the accounting: stop treating the follow-up poll as an exception. If every agent needs one, the protocol should say so plainly, so the orchestrator budgets for it instead of waiting.
- **The verification finding is the sharper one.** A critic claim about *runtime* behavior (what a mock returns, whether a promise throws eagerly, what a test actually asserts) is a claim that can be checked by running the code, and this session produced a concrete instance where reading was not enough. The rule worth adding: **a critic's claim about runtime behavior is a hypothesis until executed** — the orchestrator should require the critic to cite the run, or run it before relaying.

Related friction: **PR #947 was auto-closed by GitHub** when its base branch was deleted on #945's merge, forcing a re-open as #948. Stacked PRs should either target `main` directly or have their base retargeted before the parent merges.

## Metrics

- **Review rounds:** 1 (0 CHANGES_REQUESTED; no GitHub reviews).
- **Comments:** 0 inline, 0 substantive general.
- **`adversarialCatchRate`: 1.0 — measured.** 4 defects found by the combined adversarial + code review pass (both refresh-channel breaks, a stale error message that persisted across refetches, and an undocumented browser-timezone assumption), all 4 fixed pre-push; 0 post-push review comments, 0 post-merge fix PRs. 4/4. Unlike PR-A there is no unmeasurable remainder here, because the single combined pass found everything that was found — no external tool contributed a defect this pass missed. Note the structural caveat: with one review stage, the catch rate cannot distinguish "the pass was thorough" from "only one pass looked," and a clean 1.0 is what both look like.
- **Post-merge fix rate: 0.0 within the observation window** (hours). Not a settled figure.
- **Pre-merge catch by step:** combined review 4; post-push 0. PR-A's plan review additionally prevented a PR-B structural defect (`EntryCard` → `LedgerCard`), credited to PR-A.
- **Pre-merge iteration count:** 1 (healthy) — the combined-review variant, legitimate for a follow-up PR whose plan was already fully reviewed at PR-A.
- **Fix-up taxonomy:** correctness 3 (two refresh-channel breaks, the complete control consulting optimistic-only state), defensive-coding 1 (stale error not cleared on refresh), documentation 1 (timezone assumption documented at the derivation). Squashed to 1 commit, so legacy fix-up ratio is 0.0 and uninformative.
- **CI:** all checks SUCCESS. 587 web tests pass; lint clean. TypeScript reports 65 errors in 13 files, **byte-identical to the base** and none in files this PR touches — pre-existing, verified by diffing against base output rather than asserted.
- **Test quality:** tests assert **displayed state** per the project rule — rendered labels, `aria-pressed`, `disabled`, visible text, and which section a todo's text appears in. The strongest flip on the two mutually exclusive accessible labels, which asserts the rendered label changed rather than that a boolean did. Two regression tests cover the refresh-channel breaks, one per direction.
- **Planning quality:** complete. Scope deliberately bounded: the pin toggle does not reach the Telegram mini-app triage view or `ProjectDetail`, both of which render todos independently — deferred to **#946** with the mini-app flagged as the higher-value half, because including them would have crossed the 600-LOC ceiling and mixed three concerns.
- **Step compliance:** collapsed follow-up loop (plan reviewed at PR-A → implement → test → combined adversarial + code review → CI → push); assessment good. **Step timing:** not tracked.

## Recommendations

1. **Add the mutation → refresh-channel trace as a category-gated checklist item** (web/React), phrased as above and explicitly bidirectional. This PR's worst defect is unreachable from the diff, and the reviewer only found it by leaving the diff — that method should be written down rather than left to whoever happens to try it.
2. **Require critics to cite an execution for any claim about runtime behavior.** This session produced a relayed critic rationale that was factually wrong about whether an unstubbed mock fails loudly or vacuously, and the error propagated to two recipients before correction. Reading is not evidence when the claim is about what happens at run time.
3. **Write the follow-up poll into the orchestrator protocol as expected cost, not exception handling.** Six of six agents idled without delivering. Requiring agents to report as their final action is worth stating but is not enforceable by the orchestrator; budgeting for the poll is.
4. **Retarget stacked PRs to `main` before the parent merges,** or open them against `main` from the start. #947 was auto-closed by branch deletion and had to be re-opened as #948.
5. **Adopt the structured PR-body sections** (`## Local Review`, `Steps skipped:`, `## Step Timing`). Both PRs in this feature had their compliance and timing data reconstructed by hand — the same recommendation made for #911 and #912, now unaddressed across four PRs.
