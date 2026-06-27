# POST-MORTEM: second-brain PR #813 — feat(server): delegate todos — allowlisted partner adds to owner's list with undo

Branch: `feat/delegate-todo-add` → `main` | Author: padminipyapali | created→merged ~6 min 16 s (0.10 h)
Size: +1055 −11 across 20 files, 4 commits
Closes #810

## Summary

An allowlisted partner can add a TODO to the **owner's** list via a natural phrase ("add anniversary
flowers to Padmini's list"). The classifier emits `DELEGATE_TODO|<task>`, the task is created on the
owner's list, the asker gets an ack, and the owner gets a real-time DM with a one-tap **Remove** (undo)
button. The undo flips the todo to `WONT_FIX`, is idempotent (`confirmedAt`), never-throws, and is
`user_id`-scoped (owner-scoped lookup, not spoofable). `TELEGRAM_OWNER_NAME` became a comma-separated
alias list (first = display name, all recognized by the classifier).

## Local Review (pre-push)

- CodeRabbit: **not tracked** — the PR body has no `## Local Review` section.
- Adversarial: **not tracked** — the team flow (implementer → fresh-context critic → adversarial gate)
  ran, with 0 GitHub-review comments and 0 post-merge escapes, but the findings counts were not written
  into any captured artifact, so they cannot be quantified here.
- Shift-left rate: n/a (no recorded local-review tally).

## Step Compliance

- **Not tracked** — the PR body carries no `Steps skipped:` line. `stepCompliance` set to `null`.

## Step Timing

- **Not tracked** — the PR body carries no `## Step Timing` section. `stepTiming` set to `null`.

## Review Friction (post-push)

- Review rounds: **1** (0 `CHANGES_REQUESTED`; `reviewDecision` empty — no required reviewers).
- Comments: 0 inline, 0 general (the single general comment is from the `vercel` bot — excluded).
- Categories: all 0 (no substantive human review comments).
- Timeline: created 21:26:38Z → merged 21:32:54Z. No human review occurred.
- Self-merge: **yes** — `mergedBy == author` and 0 reviews. Per the solo-dev workflow, peer review is
  substituted by the local implementer→critic→adversarial-gate flow (see MEMORY: lightweight review for
  small PRs / merge-when-ready standing approval).

## Adversarial Review Effectiveness

- Pre-push catch potential: **unmeasured.** No GitHub review comments exist to classify as covered-but-
  missed vs not-covered, and the local critic/adversarial findings were not enumerated in the PR body.
- `adversarialCatchRate`: **null** (critic-ran-clean shade per process-patterns line 21) — NOT a
  fabricated 1.0. The gate ran and nothing escaped, but with no recorded numerator/denominator there is
  no evidence value to compute a rate from. Contrast #805 the same session, where the critic's 4 findings
  were enumerated and a 1.0 was evidence-backed.
- Covered but missed: none identified.
- Not covered (new categories): see Code Quality Signals (migration-renumber doc-staleness).

## Fix-up Metrics

- **Post-merge fix rate: 0.0%** — no follow-up PR merged after #813 touches the delegate-todo files
  (`delegate-todo-handler.ts`, `delegate-todo-callback.ts`, `delegate-todo-undo-reply.ts`, `classifier.ts`,
  `telegram.ts`). Quality escaped no gate. Ideal.
- **Pre-merge catch rate by step:** 4a 0 | 4b 0 | 4c 0 | 4d 0 | post-push 0. No `fix`-classified commits
  (none of the 4 commit messages contain fix/address/resolve/review/feedback/nit).
- **Pre-merge iteration count: 0** — no review-fix-review cycles (healthy; no CHANGES_REQUESTED, no fix
  commits). The team flow's internal critic round is not visible in git history.
- **Fix-up taxonomy:** `{ infrastructure: 1 }` — the lone housekeeping commit
  ("renumber delegate-todo-undo migration 028 → 029 (collision)"). Excluded from quality metrics. All
  other categories 0.
- Legacy fix-up ratio: **0.0%** (0 fix / 4 commits).

Commits:
1. `feat(server): delegate todos — allowlisted partner adds to owner's list…` (feature)
2. `feat(server): delegate todos — recognize multiple owner-name aliases.` (feature)
3. `Merge remote-tracking branch 'origin/main' into feat/delegate-todo-add` (merge)
4. `chore(server): renumber delegate-todo-undo migration 028 → 029 (collision)` (infrastructure)

## Planning Quality

- Description: **complete** — body has What/summary, Flow, Safety, Deploy steps, Test plan, and `Closes #810`.
- Scope: clean single concern (delegate-todo add + undo + aliases), but **+1066 LOC exceeds the 600-LOC
  guideline.** Cohesive (handler + callback + undo interceptor + classifier + tests land together because
  the feature isn't independently testable in slices), so this is an acceptable cohesion-over-cap case —
  but it was not declared as an exception in the body (cf. the "scaffolding exception must be declared"
  rule).
- Branch lifetime: < 48 h. No revert/redesign commits.
- Planning checklist: entry points are well enumerated (gate conditions, owner-self reroute, stray-"p"
  guard, single-vs-multi alias). **Gap:** no `Performance & Cost Impact` section (mandated by project
  CLAUDE.md) — though the feature adds no new LLM calls beyond the existing classifier, so cost impact is
  near-zero.

## Code Quality Signals

- Recurring issues: none (no review comments).
- New finding (captured): the migration was correctly renumbered 028 → 029 to dodge a numbering
  collision (the migration-number staleness race was caught — good), **but the PR body's `⚠️ Deploy steps`
  still instruct "Apply migration `028-delegate-todo-undo-response-type.sql` … ✅ already applied"** — a
  stale operator instruction naming a number the repo no longer contains (the file is `029-…`). Low blast
  radius here (already-applied, idempotent), but on a not-yet-applied migration an operator would `ls` for
  a 028 file that doesn't exist. Captured as a new process pattern (renumber = token-rename sweep, not
  file-rename).

## Process Efficiency

- Automation opportunities: a pre-push / PR-body lint that flags a migration-number mismatch between the
  committed `db/migrations/NNN-*.sql` files and the numbers cited in the PR body deploy steps would have
  caught the 028/029 drift.
- Iteration: efficient (1 round, 0 fix commits).
- CI status: all green — `None` check SUCCESS, `Vercel Preview Comments` SUCCESS (Vercel deployment
  ignored — server is deployed on Railway, not Vercel, per MEMORY).

## Knowledge Updates

- `process-patterns.md` (Process Compliance): added "migration renumber = token-rename sweep, not
  file-rename" — sweep PR body / deploy steps / docs for the OLD number when a renumber commit lands.
  <!-- Source: post-mortem, second-brain #813, 2026-06-27 -->
- `post-mortem-metrics.json`: appended #813 (423 PRs total).
- `dashboard.html`: regenerated `METRICS_DATA`.

## Recommendations

1. **Fix the stale deploy-step reference going forward via a body↔migration-number check.** The 028→029
   drift is benign this time but is the operator-doc half of the migration-number staleness race. The
   durable fix is a tiny pre-push check comparing migration filenames in the diff to numbers cited in the
   PR body. (Ranked #1 — it's the only concrete defect this PR surfaced.)
2. **Record the local-review lane in the PR body.** This PR ran the team flow but logged no
   `## Local Review` / `Steps skipped:` / `## Step Timing` sections, forcing three metric fields to null
   and making the critic-ran-clean signal invisible to the dashboard. Adding even a one-line
   `## Local Review` block (findings: N found/N fixed; Steps skipped: none) would let the shift-left and
   adversarialCatchRate metrics carry evidence instead of null. (Standing recommendation — recurs across
   second-brain self-merges.)
3. **Declare the >600-LOC cohesion exception in the body** when a feature legitimately can't be sliced,
   so the post-mortem can distinguish deliberate cohesion from scope creep.
