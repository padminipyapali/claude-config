# POST-MORTEM: second-brain PR #873 — Telegram connect flow registers spreadsheet sources (PR-B1 of #860)

Branch: `feat/source-connect-b1` → `main` | Author: padminipyapali | created→merged in ~21s (self-squash of a fully-locally-reviewed branch)
Size: +1402 −14 across 13 files, 3 commits (1 feature + 2 pre-push fix commits)

## LOCAL REVIEW (pre-push)
- CodeRabbit: 2 findings emitted / 2 fixed, across 3 attempts — CLI timed out server-side on all 3 (~60+ min each) and never completed a full run; the 2 findings (raw-googleapis-error token-leak in logs; error-cache TTL on transient DB errors) were emitted partially before it died, then fixed and sibling-swept. Pre-existing same-class sites filed as #872.
- Adversarial (fresh-context critic): 1 finding / 1 fixed — a BLOCKING data-loss bug.
- Shift-left: 100% of surfaced issues caught locally; 0 post-merge escapes.

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9)
- Steps skipped: 4b (CodeRabbit) — timed out on all 3 attempts; partial findings fixed, pre-existing sites → #872.
- Compliance rate: 88.9%
- Skip assessment: good (no post-merge escape attributable to the CodeRabbit gap; findings it did emit were fixed).

## STEP TIMING
Not tracked (no `## Step Timing` section in PR body).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; solo self-merge, all review pre-push).
- Comments: 0 inline, 0 general human (1 Vercel bot comment excluded).
- Timeline: created → merged ≈ 21s (branch reviewed locally before PR creation, standard solo 3-role flow).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: 100% — every issue was caught before merge.
- Covered but missed: none.
- Not covered (new checklist category ADDED): "New message-trigger gate on a shared input path must narrow its match AND persist input on every non-completing branch" — the critic-caught bug (connect gate matched any message *containing* a Sheets URL and dropped the pasted content on cancel = silent data loss). Fixed by (a) narrowing the trigger to essentially-just-the-URL / `connect <url>` so unrelated sentences fall through to normal capture, and (b) save-on-decline on every non-completing branch (cancel, unreadable, reserved kind, already-connected). Added to adversarial-review.md §1.7.

## FIX-UP METRICS
- Post-merge fix rate: 0% (0 post-merge fix commits; 874 is the planned PR-B2 stack, #875 a B2 follow-up — neither fixes 873).
- Pre-merge catch rate by step: 4c (CodeRabbit) 1 fix (raw-error redaction) | 4d (adversarial/critic) 1 fix (gate narrowing + save-on-decline) | 4a/4b/postPush 0.
- Pre-merge iteration count: 1 (single local review cycle, all fixes pre-push).
- Fix-up taxonomy: correctness 1 (data-loss gate fix), defensive-coding 1 (redact token-leak from logs).
- Legacy fix-up ratio: 66.7% (2 fix / 3 total commits — both pre-push, not escapes).

## PLANNING QUALITY
- Description: complete (Summary, LOC note, Review, Tests, Deploy note, Performance & Cost Impact).
- Scope: clean — deliberate stacked split of #860's ~1900-line diff into B1/B2; B1 documented ~680-source LOC exception with rationale (irreducible detect→confirm→persist atom).
- Branch lifetime: short (solo flow).
- Planning checklist: covered — entry points enumerated (URL-in-sentence fall-through, cancel, unreadable, reserved, already-connected, foreign-user callback, stale/expired), Performance & Cost section present.

## CODE QUALITY SIGNALS
- Recurring issues: none within this PR.
- New pattern captured: shippable-unit floor (a split may legitimately leave the interactive-flow half slightly over the 600 cap because its atom is detector+confirm+persist) → process-patterns.md.

## PROCESS EFFICIENCY
- Automation opportunities: the CodeRabbit CLI server-side timeout recurred (matches the plush-press #23 unbounded-hang lesson) — the `timeout 600` wrapper is the mitigation; the critic + adversarial checklist substituted for the missing CodeRabbit gate with 0 escapes.
- Iteration: efficient (1 round).
- CI status: all passed (Vercel preview success; no failing checks).

## KNOWLEDGE UPDATES
- adversarial-review.md §1.7: added trigger-gate narrowing + save-on-decline data-loss checklist item (Source: #873).
- process-patterns.md: added shippable-unit-floor sub-entry under the #694 split worked-example (Source: #873).
- post-mortem-metrics.json: appended #873 entry; dashboard.html regenerated (447 PRs embedded).

## RECOMMENDATIONS
1. Keep wrapping the CodeRabbit CLI in `timeout 600` — 3 server-side timeouts on one PR is the same failure class already documented; don't spend >30 min total waiting on it before falling back to critic + adversarial and recording the skip.
2. When splitting a large interactive-flow feature, size the flow half to the detect→confirm→persist atom and accept a documented small over-cap rather than shipping a detector-only or callback-only PR.
3. The trigger-gate/save-on-decline check is now in the checklist; apply it to any future message-handler interceptor (command prefixes, keyword gates) in this bot.
