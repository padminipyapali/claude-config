# POST-MORTEM: second-brain PR #683

**Title:** fix(calendar): resolve bare weekdays deterministically and show previous date on update confirmations
**Branch:** fix/calendar-write-date-accuracy → main | **Author:** padminipyapali (self-merged)
**Size:** +517 -30 across 5 files, 3 commits | created→merged ~5.8 min (0.097h)
**Closes:** #681, #682

## What & why
Two calendar-write Telegram-flow bugs surfaced in manual bot testing:
- **#681** — a bare weekday ("Schedule … Tuesday at 2pm …" on a Tuesday) resolved one day late (landed Wednesday), and the address+time were jammed into the event title.
- **#682** — update confirmations rendered only the new value, not `old → new`.

Root cause of #681: date resolution was fully delegated to the LLM, which was asked to do weekday→date *arithmetic* itself (unreliable). Fix introduces an exported, unit-testable `buildCalendarDateReference(now, timezone)` that hands the model a deterministic 14-day weekday→`YYYY-MM-DD` lookup table (TODAY marked) with an explicit "look them up, don't compute" rule and a bare-weekday rule, injected into BOTH the calendar-write and calendar-query prompts. #682 renders `old → new` per changed field by matching the original event in the fetched window, degrading to new-only if not found.

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked in PR body (4a/4b not recorded — likely skipped on a small focused fix).
- Adversarial (4c): 3 findings, 3 fixed. Two ROUNDS run.

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4c, 5 (7/9).
- Steps skipped: 4a (/simplify), 4b (CodeRabbit) — not recorded in body.
- Compliance rate: ~78%.
- Skip assessment: **neutral** — no post-merge issues attributable to the skipped steps; 4c covered the correctness surface and caught all escapes.

## STEP TIMING
Not tracked (no `## Step Timing` section).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no GitHub reviews; self-merged solo dev).
- Comments: 0 substantive (only Vercel bot comment).
- Timeline: created→merged ~5.8 min; no peer review (solo dev with orchestrator + fresh-context critic standing in).

## ADVERSARIAL REVIEW EFFECTIVENESS — the headline signal
The fresh-context critic caught, with execution verification, **two off-by-one bugs in the NEW date-helper code itself** plus a missed sibling path:
1. The date table built each line by reformatting a UTC-noon instant back through `Intl.DateTimeFormat(timezone)`, shifting the date +1 in far-east zones (UTC+13 Tongatapu, UTC+14 Kiritimati). **The fix had reintroduced the exact off-by-one date-bug class it was fixing.**
2. The same UTC-instant-round-trip pattern in the all-day inclusive-end display (`formatWhenFromEvent`).
3. Sibling miss: the calendar-QUERY prompt still used the old single-line nowStr (caught by sibling sweep, now reuses the same reference + weekday rule).

All three fixed in a second pass; computed on UTC date parts and covered by Tongatapu/Kiritimati + DST spring/fall tests. **adversarialCatchRate = 1.0** (3 issues caught locally that would otherwise have shipped, 0 post-merge escapes — evidence-based, not a hardcoded baseline).

Author self-review did NOT catch any of the three — this is precisely the fresh-context critic's value.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no follow-up fix PRs).
- Pre-merge catch rate by step: 4c (adversarial) caught all 3 (2 correctness + the doc-header drift surfaced alongside).
- Pre-merge iteration count: 2 (implement → critic round 1 (fix-first) → critic round 2 (ship)).
- Fix-up taxonomy: correctness 2, documentation 1.

## PLANNING QUALITY
- Description: complete (What/why, Review notes, Testing, Note on pre-existing main break, Closes #681/#682).
- Scope: clean — two related calendar-write bugs, focused; far-east-tz hardening folded in appropriately.
- Branch lifetime: short.

## PROCESS EFFICIENCY / FRICTION
- **Worktree-unaware push hook:** `require-adversarial-review.sh` checked the main-checkout HEAD/path instead of the worktree's, so the push was initially blocked despite a valid review marker. Resolved by pushing with cwd set to the worktree. This is a **recurrence of #647** — two second-brain occurrences now justify promoting the hook fix from prose to code (canonicalize `$CWD` via worktree-aware `git rev-parse --show-toplevel` before hashing).
- CI: Vercel green. PR body notes a pre-existing, unrelated main build/lint break (hasAiResponse/ApiFeedEntry drift + a web a11y lint error) not touched by this branch.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/process-patterns.md`:
  - Strengthened the "Adversarial review marker is keyed by `$CWD`" entry with the #683 recurrence; escalated the recommended fix to code (worktree-aware canonicalization).
  - Added to Adversarial Review Gaps / Critic Blind Spots: "A fix for a bug class frequently REINTRODUCES the same bug class in its own new code — the critic must replay the original repro (and its adversarial extremes) against the fix; author self-review systematically misses it."
- Already captured (no duplication needed):
  - `~/.claude/knowledge/llm-integration.md` lines 68–69: don't make the LLM do weekday→date math (inject a date table); build that table with UTC date-part arithmetic, not by reformatting an instant through the target tz; always cover UTC+13/+14 + DST. Sourced to #681/#682.
  - Project `docs/BUGS.md`: BUG-031 (LLM date delegation) and BUG-032 (far-east tz +1 shift).

## RECOMMENDATIONS (ranked)
1. **Make `require-adversarial-review.sh` worktree-aware** — canonicalize the path with `git rev-parse --show-toplevel` before hashing the marker. This friction has now hit second-brain twice (#647, #683); it taxes every worktree-based PR.
2. **Critic prompt: replay the original repro against the fix.** When a PR replaces a faulty computation, mandate that the critic execute the new code against the exact inputs that triggered the original bug plus known adversarial extremes (for date/time: UTC+13/+14 + a DST boundary, run for real).
3. Consider recording 4a/4b skip rationale in the PR body's `Steps skipped:` line even on small fixes, so skips are tracked rather than silent (assessed neutral here, but tracking removes ambiguity).
