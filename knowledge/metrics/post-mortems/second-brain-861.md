# POST-MORTEM: second-brain PR #861

**Title:** fix: treat recycled Telegram message ids as collisions, not duplicates — zero data loss on save
**Branch:** fix/prompt-reply-duplicate-masking → main | **Author:** padminipyapali | **Merged:** 2026-07-09T06:40:21Z
**Size:** +363 −1 across 9 files, 1 commit (squash) | **Closes #856**

## Summary of the change
Telegram message ids are per-chat sequences. Recreating the bot chat (2026-06-27) reset the sequence, so new messages collided with 5-month-old rows on the unique index `idx_entries_channel_message`. The prompt-reply interceptors turned the 23505 into a user-facing "save failed" (data lost unless resent); the main pipeline's adapter-level catch treated EVERY 23505 as a webhook retry and silently dropped the note. Fix at the service layer (`PostgresEntryService.createEntry`/`createTodoEntry`): on a unique violation whose `err.constraint === "idx_entries_channel_message"`, fetch the existing row — identical content → genuine webhook redelivery → rethrow (adapter dedup swallows silently); different content → recycled-id collision → re-insert once with `channel_message_id` NULL (partial index is `WHERE NOT NULL`, so no re-collision), warn-log, return success (zero data loss); no matching row / other constraint → rethrow. Adds `pg-errors.ts:isUniqueViolation`, BUG-039.

## Local review (pre-push)
- CodeRabbit: not tracked (no `## Local Review` / CodeRabbit section in the PR body; project convention omits CodeRabbit for a focused bugfix of this size).
- Critic (fresh context): APPROVE after withholding on **2 should-fix items**, both fixed pre-merge:
  1. Gate recovery on the SPECIFIC constraint name (`err.constraint === "idx_entries_channel_message"`) so unrelated unique indexes still propagate untouched. (defensive-coding)
  2. Add the missing `createTodoEntry` test branches (stale-recovery + rethrow paths). (test-quality)
- Adversarial review: PASS, full checklist, 0 findings — including a caller trace of the newly-throwing interceptor path down to the adapter catch.
- Shift-left: 2/2 review-surfaced issues caught and fixed locally before push (100%).

## Step compliance
Not tracked in parseable form — the PR body uses a narrative `## Review` section rather than a `Steps skipped:` line. Narrative confirms critic + adversarial ran; recorded as `null`.

## Step timing
Not tracked (no `## Step Timing` section). Recorded as `null`.

## Review friction (post-push)
- Review rounds: 1 (no CHANGES_REQUESTED; self-merged 45s after creation).
- Comments: 0 inline, 0 general (only a Vercel bot deploy comment, excluded).
- Categories: all 0.
- Timeline: created → merged = ~45 seconds. Self-merged (mergedBy == author, no GitHub reviews) — "no peer review" at the GitHub layer, but the pre-push critic + adversarial gate is this project's substitute per the solo-dev review pattern.
- CI: Vercel + Vercel Preview Comments both SUCCESS.

## Adversarial review effectiveness
- Adversarial checklist PASSED clean (0 findings). The 2 real pre-merge catches came from the CRITIC (internal review), not the mechanical adversarial checklist.
- `adversarialCatchRate = 1.0` MEASURED: caught 2 (critic), escaped 0 post-merge → 2/(2+0). This is the found-and-fixed shade (cf. #855/#846/#837), NOT a fabricated value and NOT the null critic-ran-clean shade (#853/#850).
- Covered but missed: none.
- Not covered (candidate new category): the DIAGNOSIS error (webhook-retry vs recycled-id) is not an adversarial-checklist class — it's a planning/diagnosis discipline gap, addressed in the knowledge update below.

## Fix-up metrics
- Post-merge fix rate: 0% (no follow-up fix PR touches this area; `gh pr list` shows no PR > 861 in the feature area).
- Pre-merge catch rate by step: 4a=0, 4b (internal review/critic)=2, 4c=0, 4d=0, post-push=0. (Both critic catches folded into the single squash commit — no separate fix commits exist to attribute.)
- Pre-merge iteration count: 1 (one local critic round) — healthy.
- Fix-up taxonomy: defensive-coding=1 (constraint-name gate), test-quality=1 (TODO-path test branches).
- Legacy fix-up ratio: 0% (0 fix commits / 1 commit — squash merge).

## Planning quality
- Description: complete — Summary, Fix, Testing, Performance & Cost Impact, Review sections all present; multiple entry points enumerated (createEntry, createTodoEntry, interceptors, adapter).
- Scope: clean — single concern, single commit, +363/−1.
- Branch lifetime: minutes (squash-merged same session).
- **Notable process fact:** the initial root-cause diagnosis (webhook retry) was WRONG. It was corrected only after querying production data and finding the "duplicate" row held different, months-old content. The fix design (rethrow vs recover; whether data was being lost) inverted on that evidence. Also: the fix design changed mid-implementation via a course-correction message. This is a diagnosis-discipline signal, not a code-quality defect — the code shipped clean.

## Code quality signals
- Recurring issue class: this PR is the FIX for the masking-generic-swallow class the knowledge base has tracked across #828/#840/#853/#855 — the adapter's blanket "every 23505 is a webhook retry" swallow is exactly that anti-pattern, and it shipped and cost real data loss until now.
- New unrecorded pattern: an error CODE is not a diagnosis — a SQLSTATE with more than one semantic cause must be disambiguated against the actual production row before the fix is designed. Captured in process-patterns.md.

## Process efficiency
- Automation opportunities: none new. The diagnosis error would not have been caught by a linter/CI — it required production-data inspection, which the process did do (just after an initial wrong hypothesis).
- Iteration: efficient (1 local round, 0 post-merge).
- CI: all passed.

## Knowledge updates
- `process-patterns.md` → Correctness Gaps: new pattern "An error CODE is not a diagnosis — verify the interpretation against the actual production row before designing the fix" (source: #861). Pairs with the #853 repro-that-logs-the-error rule.
- `database-patterns.md` → Data Integrity: strengthened the existing #856 "unique violation is not proof of a retry" entry with the #861 merge ref and the diagnosis-history caveat (misread as retry, corrected via prod-data query).

## Recommendations
1. **Add a diagnosis-verification gate for data-shaped bugs.** When a fix hinges on the semantic meaning of a status/error code that has more than one cause, require an inspection of the actual production row (or a logged repro) as a plan-approval artifact before implementation. This PR did it — but only after an initial wrong hypothesis; making it a required step catches the wrong hypothesis earlier.
2. **No change to the review gate.** The critic + adversarial pattern performed correctly (2 real catches, 0 escapes). Keep the lightweight-review posture for focused bugfixes of this size.
