# POST-MORTEM: second-brain PR #208 — Add ResearchService core (Issue #130, PR 2/8)

Branch: feat/research-service → main | Author: padminipyapali | ~21 min
Size: +1373 -0 across 3 files, 2 commits

## LOCAL REVIEW (pre-push)

- **CodeRabbit (local):** 2 findings, 2 fixed
- **Adversarial review:** 7 findings, 5 fixed
- **Shift-left rate:** 64% (9 local / 14 total)

## STEP COMPLIANCE

- Steps run: 1, 2, 4a, 4b, 4c, 4d, 5 (7/8)
- Steps skipped: 3-Playwright (backend-only service, no UI changes)
- Compliance rate: 87.5%
- Skip assessment: good (no UI-related findings post-push)

## REVIEW FRICTION (post-push)

- Review rounds: 2 (2 CHANGES_REQUESTED from coderabbitai[bot])
- Comments: 5 inline (all bot), 0 human
- Categories: { security: 2, correctness: 2, architecture: 1 }
- Timeline: created → first review: ~5min | first review → merge: ~16min | total: ~21min
- Self-merge: yes (no human peer review)

### Round 1 (3 comments, addressed):
1. **Defensive Date conversion** (correctness, lines 110-125): `toApiResearchTask` used `as Date` cast; pg returns Date objects but defensive `toDate()` helper is safer.
2. **Advisory lock for TOCTOU race** (correctness, lines 164-189): `SELECT COUNT(*) ... INSERT` in transaction allows concurrent reads before commit. Fixed with `pg_advisory_xact_lock(hashtext($1))`.
3. **HTML-escape topicPreview in notification** (security, lines 443-455): User-derived topic content in `parse_mode: "HTML"` message without escaping.

### Round 2 (2 comments, NOT addressed before merge):
4. **formattedContext escaping** (security, lines 370-393): Context text in notification could contain unescaped HTML entities.
5. **Pool shutdown method** (architecture, lines 134-156): Missing `close()`/`end()` method for graceful pool cleanup.

## ADVERSARIAL REVIEW EFFECTIVENESS

- Pre-push catch potential: 67% (2 of 3 round-1 findings covered by checklist but missed)
- Covered but missed:
  - Advisory lock (TOCTOU race) — Tier 2 DB patterns covers transaction races
  - HTML-escape in notification — Tier 1 user content escaping covers this
- Not covered (new categories):
  - Defensive Date conversion in row mapper — belt-and-suspenders, pg returns Dates
- Fix commits: 1 of 2 total (50% fix-up ratio) — HIGH

### Commit classification:
1. `Add ResearchService core...` → **feature**
2. `Address PR review: defensive Date...` → **fix**

## PLANNING QUALITY

- Description: **complete** (Summary with bullet points, detailed Test Plan, Local Review section with metrics)
- Scope: **clean** (focused on one concern — service layer + tests + server wiring)
- Branch lifetime: ~21 minutes
- Planning checklist: **covered** (detailed plan with adversarial review, entry points enumerated, performance/cost section implicit via model selection)

## CODE QUALITY SIGNALS

- Recurring issues: HTML escaping in notification methods (also caught in PR #206 context)
- Fix-up ratio: 50%
- New unrecorded patterns: TOCTOU race on count-based limits (now recorded in database-patterns.md)

## PROCESS EFFICIENCY

- Automation opportunities:
  - A grep for `parse_mode.*HTML` + user-derived content would catch the escaping issue mechanically
  - A grep for `SELECT COUNT.*INSERT` patterns could flag TOCTOU risks
- Iteration: **normal** (2 rounds, standard for 1300+ LOC PRs)
- CI status: all passed (CodeRabbit SUCCESS, Vercel SUCCESS)

## KNOWLEDGE UPDATES

- `~/.claude/knowledge/database-patterns.md`: Added advisory lock pattern for count-based limits (new)
- `~/.claude/knowledge/telegram-bot-patterns.md`: Strengthened HTML-escape rule to cover ALL outbound channels including notification methods (broadened)
- `~/.claude/knowledge/process-patterns.md`: Added iteration velocity entry for PR #208, added TOCTOU race adversarial review gap

## RECOMMENDATIONS

1. **Add TOCTOU count-limit check to adversarial Tier 2 DB checklist.** The pattern `SELECT COUNT(*) ... INSERT` needs advisory locks, not just transactions. This is distinct from dedup (unique index) and should be a separate checklist item.
2. **Grep for `parse_mode.*HTML` during adversarial review.** Any outbound message with HTML parse mode should trigger a check for user-derived content without escaping. This would mechanically catch the recurring HTML-escape gap.
3. **Address remaining 2 CodeRabbit findings.** The formattedContext escaping and pool shutdown method were left unaddressed — consider addressing in next PR touching research.ts.
4. **Shift-left rate below target.** 64% is below the 80% target for PRs of this size. The adversarial review caught 7 issues but missed 3 that were in its checklist coverage. Execution discipline remains the bottleneck, not coverage.
