# Post-Mortem: second-brain PR #209 — Add Telegram research integration (Issue #130, PR 3/8)

**Branch:** feat/research-telegram -> main
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Duration:** 5.4 hours (created 2026-02-23T01:48 -> merged 2026-02-23T07:15)
**Size:** +625 -7 across 11 files, 3 commits

## Summary

PR 3 of the async research agent feature (Issue #130). Implements standalone `research [topic]` keyword detection in MessageProcessor, reply-to `research this` interceptor with Yes/No inline keyboard confirmation, `research:y`/`research:n` callback dispatch in TelegramAdapter, failure notifications in ResearchService, and `markResearchInitiated()` on EntryService for feed exclusion. 19 new tests (8 interceptor, 8 keyword detection, 3 failure notification).

## Local Review (pre-push)

- CodeRabbit: N/A (skipped)
- Adversarial: N/A (skipped)
- Steps 4a-4e (entire code review loop) skipped per user request
- Shift-left rate: 0% (no local review issues caught)

## Step Compliance

- Steps run: 1 (plan), 2 (implement), 3 (test), 5 (push+PR) -- 4/8
- Steps skipped: 4a (simplification), 4b (internal review), 4c (CodeRabbit), 4d (adversarial), 4e (CI checks) -- skipped per user request
- Compliance rate: 50%
- Skip assessment: **bad** -- both substantive post-push findings (inline keyboard cleanup, BadRequestError exposure) map to existing adversarial checklist items

## Review Friction (post-push)

- Review rounds: 2 (2 CHANGES_REQUESTED from CodeRabbit bot, no human review)
- Comments: 3 inline, 0 general (excluding bot summary/deployment comments)
- Categories: { security: 1, correctness: 1, style: 1 }
- Timeline: created -> first review: 0.1h | first review -> merge: 5.4h | total: 5.4h
- Self-merge: yes, no human peer review

### Review Round 1 (2026-02-23T01:52, CHANGES_REQUESTED)
1. **Correctness:** Inline keyboard not cleared after research confirm/cancel/error in `handleResearchCallback`. `editMessageText` without `reply_markup` keeps the old keyboard, allowing users to re-trigger callbacks after the action was already processed. **Fixed in commit 8313c39.**

### Review Round 2 (2026-02-23T07:05, CHANGES_REQUESTED)
2. **Style (nitpick):** `escHtml` helper defined inline within try block. Suggestion to extract to module scope for reuse and testability. **Not addressed (nitpick).**
3. **Security:** `BadRequestError` branch exposes raw `err.message` to users, potentially leaking internal implementation details. Suggestion to sanitize or use generic fallback. **Fixed in commit 25767c9 (CodeRabbit committable suggestion applied).**

## Adversarial Review Effectiveness

- Pre-push catch potential: 50% (1 of 2 substantive findings covered by checklist)
- Covered but missed (would have been caught if review loop ran):
  - BadRequestError message exposure -> Tier 3: Error message specificity
  - Inline keyboard not cleared -> partially related to Tier 1 state cleanup, but no exact match
- Not covered (new category):
  - Telegram inline keyboard cleanup after callback handling (new gap)
  - `escHtml` module-scope extraction (style, not a checklist concern)
- Fix commits: 2 of 3 total (67% fix-up ratio)

### Commit Classification
1. **FEATURE:** "Add Telegram research integration: keyword detection, reply flow, and..." (566a74e)
2. **FIX:** "Address PR review: clear inline keyboard after research confirm/cance..." (8313c39)
3. **FIX:** "Update packages/server/src/channels/telegram.ts" (25767c9, CodeRabbit committable suggestion for BadRequestError sanitization)

## Planning Quality

- **Description:** Partial -- has Summary, Local Review, Test Plan sections but lacks Performance/Cost Impact section
- **Scope:** Clean -- single concern (Telegram research integration), no scope creep or redesign
- **Branch lifetime:** 5.4 hours
- **Planning checklist:** Entry points listed in summary (standalone, reply-to, bare keyword). Missing: Performance/Cost Impact section

## Code Quality Signals

- **Recurring issues:** None (no category with 2+ comments)
- **Fix-up ratio:** 67% (2 fix commits / 3 total)
- **New unrecorded patterns:** Telegram inline keyboard cleanup after callback handling

## Process Efficiency

- **Automation opportunities:** Both substantive findings could have been caught by the adversarial review checklist (step 4d) if it had been run. Running `npm run lint` (step 3) wouldn't have caught these -- they're semantic/behavioral issues, not lint violations.
- **Iteration assessment:** 2 rounds -- normal for bot-only review, but preventable with local review
- **CI status:** Vercel deployment success, CodeRabbit PENDING at merge time

## Knowledge Updates

1. **process-patterns.md:** Added entry under "Iteration Velocity" documenting 67% fix-up ratio with 0% shift-left rate when review loop skipped
2. **process-patterns.md:** Added entry under "Process Compliance" documenting that 600+ LOC PRs should not skip the review loop
3. **process-patterns.md:** Added entry under "Adversarial Review Gaps" documenting the Telegram inline keyboard cleanup gap

## Recommendations

1. **Do not skip the code review loop on 600+ LOC PRs.** This PR demonstrates the cost: 0% shift-left rate, 67% fix-up ratio, and 2 post-push review rounds. The ~20 min saved by skipping steps 4a-4e was offset by ~30 min of post-push fix cycles. The review loop should be treated as mandatory above the 600 LOC threshold regardless of user request.

2. **Add Telegram inline keyboard cleanup to adversarial checklist.** New Tier 3 item: "After handling an inline keyboard callback (confirm/cancel/error), clear the keyboard via `reply_markup: { inline_keyboard: [] }` in the `editMessageText` call to prevent re-triggering." This is a Telegram-specific state cleanup pattern.

3. **Error message exposure remains a recurring security gap.** The BadRequestError -> raw `err.message` to user pattern was caught by CodeRabbit, not locally. The adversarial checklist Tier 3 "Error message specificity" covers this, but it requires the review loop to run. This is the same class of finding as PR #208's HTML-escape gap -- internal error details leaking to users.
