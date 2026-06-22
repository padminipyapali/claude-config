# POST-MORTEM: second-brain PR #687 — feat(calendar): compute free/busy availability deterministically

Branch: feat/calendar-deterministic-freebusy → main | Author: padminipyapali | ~5 min open-to-merge (self-merged)
Size: +1593 -15 across 7 files, 5 commits

## Context / trigger
Manual Telegram testing found the bot called a day "fully booked 8am–8pm" when the only event (Shelo) ran 8am–**7pm**, so 7–8pm was actually free. The LLM was doing the free/busy interval subtraction itself and got it wrong. This is the **third instance in one week** of the same root anti-pattern — "LLM doing computation it shouldn't" — each surfaced by manual testing, not review:
- #681 — LLM weekday→date arithmetic (off-by-one).
- #683 — the deterministic fix for #681 REINTRODUCED the same off-by-one class in far-east timezones.
- #685 (this PR) — LLM doing free/busy interval-subtraction.

The fix generalizes the lesson from date-math to all computation: the model only classifies the question + extracts parameters (windows, days) and narrates; a pure, unit-tested engine (`packages/server/src/services/calendar-availability.ts`) does the interval math (clip to day+window, merge overlapping/adjacent, subtract, drop zero-length gaps). Answer formatted deterministically in code — no second narration round-trip, zero added latency.

Two requirements surfaced mid-implementation from continued testing and were folded into the same PR (both shared the new engine + the forced tool's `availability` object): (a) default availability to this-week instead of asking "which day?", (b) support multiple named windows (coffee + lunch) in one query.

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (lightweight-review policy; PR body has no `## Local Review` section).
- Adversarial (fresh-context critic): 4 findings, 4 fixed across 3 rounds.
- Shift-left: 100% of issues caught locally (0 post-merge escapes).

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4c, 5 (skipped 4a /simplify, 4b CodeRabbit) — compliance 66.7%.
- Skip assessment: **neutral** — no GitHub review data to compare against; 0 post-merge fixes. Note: per MEMORY.md the lightweight lane skips critic+CodeRabbit under ~100 LOC, but this PR is +1593 (mostly new engine + 42-test suite), above that threshold; the critic DID run and caught real issues, so the skip of 4a/4b is the only gap.

## STEP TIMING
Not tracked (no `## Step Timing` section in PR body).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; self-merged, no GitHub reviews).
- Comments: 0 inline, 0 general (only a Vercel bot preview comment).
- Timeline: created → merged in ~5 min. No peer review (solo dev; the fresh-context critic is the gate).

## ADVERSARIAL REVIEW EFFECTIVENESS
The fresh-context critic caught 4 issues author self-review missed (all would otherwise have shipped):
1. **SHOULD-FIX — out-of-fetch-range days reported confidently "all free."** The INVERSE of the bug being fixed: days beyond the ~14-day fetch window have zero loaded events and would be reported as fully free. Fixed by bounding availability to the fetched coverage range (`fetchCalendarWindow` now returns coverage bounds; `partitionDaysByCoverage`) and refusing out-of-range days explicitly.
2. Unused parameter.
3. Availability-vs-clarify precedence gap.
4. Duplicated lookup-window constant (hoisted to `CALENDAR_LOOKUP_WINDOW_DAYS` in the leaf module so fetch-window length and guard-range length can't drift).

adversarialCatchRate = **1.0**, computed from evidence: 4 caught locally / (4 caught + 0 post-merge escapes). Not hardcoded.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (687 is the latest merged PR; no follow-up fix PRs reference it or its files).
- Pre-merge catch by step: 4c (adversarial/critic) = 2 fix commits; all others 0.
- Pre-merge iteration count: 3 (3 critic rounds — high-ish, consistent with a large new engine; produced a correct, false-confidence-free result).
- Fix-up taxonomy: defensive-coding 1 (out-of-range guard), correctness 1 (precedence/unused-param/constant squashed). 
- Legacy fix-up ratio: 0.4 (2 critic-fix commits / 5 total; the 2 core/feature commits + 1 doc commit are not quality fix-ups).

## PLANNING QUALITY
Complete. PR body has What/why, Changes, Behavior improvements, Testing (42 tests incl. exact Thursday repro, DST, UTC+13, two-window, out-of-range), and a Performance section (explicitly: no added latency). `Closes #685`.

## CODE QUALITY SIGNALS
- Recurring issue (3rd time): LLM-delegated computation. The recurrence itself is now the headline finding.
- Recurring critic value: author self-review caught 0/4; the fresh-context critic is load-bearing even for code the author just wrote and tested.
- New unrecorded patterns: none at code level (llm-integration.md already has the #685 delegate-computation + bound-to-fetched-range entries; BUGS.md has BUG-033). Process-level patterns added this post-mortem (see below).

## PROCESS EFFICIENCY
- Automation opportunity: a grep-able Tier-style signal — an LLM prompt asking the model to "calculate / subtract / determine which / how many / what's free" should flag moving that op into code.
- Iteration: 3 critic rounds — normal-to-high for a large new engine; justified.
- CI: Vercel preview SUCCESS. Pre-existing unrelated main break (#684) noted, not touched by branch.

## KNOWLEDGE UPDATES
- `process-patterns.md` → Critic Blind Spots: (1) three-strike LLM-computation recurrence → promote to a plan-time premise check on any LLM feature that produces a user-facing answer; the recurrence itself is the finding. (2) a fix replacing one false-confidence trap can introduce the INVERSE trap (empty/unfetched data read as a confident positive) — critic must check the opposite boundary. (3) author self-review caught none of 4; critic is the gate.
- `process-patterns.md` → Scope Decisions: mid-implementation requirements may fold into the same PR when they extend the same code path/abstraction and stay under the size cap.
- `llm-integration.md` and `docs/BUGS.md` (BUG-033): code-level learnings already captured in-loop; no change needed.

## RECOMMENDATIONS (ranked)
1. **Promote the LLM-computation premise check to the plan template.** Three reactive instances in a week means the next LLM feature should be audited up-front: enumerate every arithmetic/set/interval/sort/dedup op in the model's answer and assert each runs in unit-tested code. This is the terminal "stop fixing instances, fix the process" move.
2. **Add an inverse-false-confidence line to the adversarial/critic prompt:** "does this fix now over-claim in the opposite direction — empty/unfetched/null data read as a confident positive?" — caught here only by the critic.
3. **Record `Steps skipped:` and a `## Local Review` line even on lightweight-lane PRs** so the metric pipeline isn't blind to which lane a PR took (recurring across second-brain post-mortems).
