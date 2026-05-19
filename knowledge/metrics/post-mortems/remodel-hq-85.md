# POST-MORTEM: remodel-hq PR #85 — feat(atelier): delete inspiration images and notes

Branch: `feat/atelier-inspo-delete` → `main` | Author: padminipyapali | ~12 min PR open
Size: +1159 -50 across 7 files, 3 commits (squash-merged)
Merge commit: aa5602098909b93556cdfeea4f8758d5bd2a2e74

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` section in PR body — same gap as #83/#84).
- Adversarial: not tracked.
- Critic loop (inferred from commit 3 `fix(atelier): address critic feedback on inspo delete lightbox`): 1 critic round; 5 should-fix findings, all addressed in commit 3.
  1. ESC inside confirm dialog should close only the dialog, not the lightbox.
  2. Cancel button should receive focus when the confirm dialog opens.
  3. Stale per-note delete error must clear when navigating to a different image.
  4. Drop unreachable else branch in next-image computation after delete.
  5. `deleteImage` callback must capture snapshot via functional setter so identity stops churning on every list mutation.
- Shift-left rate: 100% qualitatively — all friction absorbed pre-PR via the critic; zero user-iteration rounds, zero post-push review comments.

## STEP COMPLIANCE
- Step compliance: not tracked (PR body has no `Steps skipped:` line). Three-PR streak of the same gap (#83, #84, #85) → templatize now.

## STEP TIMING
- Not tracked in PR body. PR-open-to-merge: 12 minutes; on-branch implementer + critic loop happened earlier in the session.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no `CHANGES_REQUESTED`; self-merge by author).
- Comments: 0 substantive (1 Vercel bot comment excluded).
- Categories: all zero.
- Timeline: created → merged in 12 minutes.

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: high for two findings, gap for three.
  1. **ESC-scoped dismissal inside a nested dialog** — react-patterns.md mentions modal-scoped keyboard handlers (added in #84). The "nested dialog must consume ESC before outer modal" case is adjacent. Currently in a checklist gap.
  2. **Initial focus on the safer choice (Cancel, not Destroy)** — a11y convention; not enforced by the adversarial review checklist. Gap.
  3. **Per-image error state must reset on navigation** — adjacent to react-patterns.md "per-image-id generation counter" pattern. Latent staleness on a transient error string. Checklist would have caught it if "reset transient error state on key change" were a Tier 1 sweep.
  4. **Dead/unreachable else branch after delete** — covered by `/simplify` (4a) but step was apparently not run pre-push.
  5. **Callback identity churn from including mutating list in deps** — already documented in react-patterns.md (functional setter for snapshot); the implementer initially missed it. **Covered but missed.**
- Covered but missed: 2 of 5 (ESC-nested-dialog adjacency, callback-identity-churn).
- Not covered (new categories):
  - **Confirm-dialog focus default = safer choice.** Add as Tier 1 a11y check.
  - **Transient per-row error state must reset on row-key change.** Add as Tier 1 sweep.
  - **Nested dialog ESC consumption: stop propagation before outer modal.** Strengthen modal-keyboard-handler contract.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no post-merge follow-ups for #85's surfaces; #86 is a separate feature).
- Pre-merge catch rate by step:
  - 4a (simplify): 0 (the unreachable-else would have been caught here)
  - 4b (internal/critic): **5** (all critic findings landed in commit 3)
  - 4c (CodeRabbit): 0 (not run / not tracked)
  - 4d (adversarial): 0
  - post-push: 0
- Pre-merge iteration count: **1** (one critic round). Healthy.
- Fix-up taxonomy: { a11y: 2 (ESC scoping + Cancel focus), correctness: 2 (stale-error reset + callback-identity), dead-code: 1 (else branch) }.
- Legacy fix-up ratio: 33% (1 fix / 3 total commits) — single critic-driven hardening pass.

## PLANNING QUALITY
- Description: complete (Summary + Notes + Test plan with 7 explicit scenarios including the offline-failure revert path).
- Scope: clean — two related surfaces (image delete + note delete), both in the lightbox, explicit "no grid-card hover trash" and "legacy /dashboard not touched" out-of-scope callouts.
- Branch lifetime: < 1 day.
- Planning checklist coverage:
  - Entry points enumerated: yes (lightbox delete, per-note delete, offline failure, last-remaining-image, multi-image-after-delete).
  - Performance/cost: implicit (no paid APIs added).
  - **Surfaces-touched declaration**: Notes section explicitly named the two surfaces (lightbox image delete / lightbox per-note delete) AND the two deliberately-untouched surfaces (grid-card hover trash, legacy `/dashboard`). Same lightweight pattern as #84 — works for ≤2 surfaces.

## CODE QUALITY SIGNALS
- Recurring issues across this run: callback-identity-churn (also flagged in earlier PRs; functional-setter snapshot is now standard).
- New unrecorded patterns:
  - **Confirm-dialog focus defaults to Cancel** for destructive actions.
  - **Transient per-row error state must key on row id** and reset on row change.
  - **Nested AlertDialog inside a modal must `stopPropagation` ESC** before the outer modal closes.

## PROCESS EFFICIENCY
- Automation opportunities:
  - Tier 1 grep for `<AlertDialog` / `<ConfirmDialog` siblings inside another portaled modal — flag for ESC scoping.
  - Tier 0 lint: forbid `setState((prev) => ...)` snapshot patterns from being replaced by raw closure reads of the same state.
  - Re-run `/simplify` (step 4a) before push — would have caught the unreachable else.
- Iteration: **efficient** (1 critic round, 0 user rounds).
- CI status: Vercel preview SUCCESS.

## POST-#83 / #84 PROCESS-IMPROVEMENT ASSESSMENT

**Surfaces-touched table.** Same lightweight-Notes treatment as #84. PR touched 2 surfaces (image-delete + note-delete) both in the lightbox; a formal table would have been over-engineering. The Notes section did the equivalent job (named the two in-scope surfaces, named the two out-of-scope surfaces). **Confirms the heuristic: full table only when >2 surfaces or cross-component coordination.**

**Optimistic-by-default for write paths.** PR #85 explicitly inherits the optimistic pattern from PR #83 (called out in the PR body: "uses the optimistic-update pattern from PR #83"). New hooks `deleteImage` and `deleteNote` were both implemented optimistically on the first pass — no retrofit. **The optimistic-default pattern has been adopted as a de-facto contract.** Strong evidence for promoting it from a knowledge pattern to a default expectation in adversarial-review.md.

## ORCHESTRATOR → IMPLEMENTER → CRITIC LOOP EFFECTIVENESS
- Fresh-context critic caught 5 should-fix findings on a 7-file PR — highest critic yield of the #83/#84/#85 streak.
- All 5 findings were a11y / correctness / dead-code edge cases the implementer missed because the happy path "worked on screen."
- All 5 fixed in a single commit; no third round needed.
- Zero user-iteration rounds confirms the critic absorbed the iteration debt.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/react-patterns.md`:
  - Added: "Destructive-action confirm dialogs default focus to Cancel, not the destructive button." (UI Patterns / a11y) <!-- Source: post-mortem, remodel-hq #85 -->
  - Added: "Nested AlertDialog inside a portaled modal must stopPropagation ESC so the outer modal does not close." (UI Patterns / modal-keyboard contract extension) <!-- Source: post-mortem, remodel-hq #85 -->
  - Added: "Transient per-row error state must key on the row id and reset on row change." (State Management) <!-- Source: post-mortem, remodel-hq #85 -->
- `~/.claude/knowledge/adversarial-review.md`:
  - Strengthened section 1.5 (Optimistic UI Revert Safety) with a note that optimistic-by-default is now the **default expectation** for any new write-path hook in Atelier — pessimistic implementations require justification. <!-- Source: post-mortems, remodel-hq #83/#85/#86 -->
- `~/.claude/knowledge/process-patterns.md`:
  - Reaffirmed "surfaces-Notes paragraph sufficient for ≤2 surfaces" with PR #85 evidence (the third confirming PR).
- `~/.claude/knowledge/metrics/post-mortem-metrics.json`: appended entry.
- `~/.claude/knowledge/metrics/dashboard.html`: METRICS_DATA refresh queued for end of batch.

## RECOMMENDATIONS (ranked)

1. **Promote optimistic-by-default from knowledge pattern to default expectation in adversarial-review.md.** Three consecutive PRs (#83, #85, #86) have either retrofitted or natively implemented optimistic updates for new write paths — vote, favorite, notes, delete-image, delete-note, pin, updateImageCategory. The pattern is no longer aspirational; it is house style. Make the adversarial-review.md entry an explicit Tier 1 check: "Any new write-path hook (`use*` exposing `add`/`update`/`delete`/`toggle`) MUST be optimistic-by-default. Pessimistic implementation requires a one-line justification in the PR body."
2. **Add `## Local Review` and `## Step Timing` to the Atelier PR body template.** Now a three-PR streak of missing sections (#83, #84, #85). Without them we can't tell "ran step 4a, found nothing" from "skipped step 4a." Templatize this round.
3. **Run `/simplify` (step 4a) before push.** The unreachable-else branch (commit 3, item 4) is exactly what step 4a catches. Adding this as a step 4a smoke would have shifted that fix one round earlier.
4. **Add the three new react-patterns to a runnable Tier 1 sweep.** Confirm-Cancel focus default, nested-dialog ESC scoping, per-row error reset — all three are greppable patterns that the critic caught manually. Promote to automated checklist.
5. **Sweep existing destructive-action confirm dialogs for Cancel-focus default.** One-time sibling sweep across Atelier; the lesson generalizes beyond `inspo` delete.
