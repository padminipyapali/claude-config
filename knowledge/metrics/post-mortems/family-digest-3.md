# Post-Mortem: family-digest PR #3 — PR 2a: filter + categorize + LLM narrative

**Branch:** `feat/pr2a-compose-narrative` -> `main`
**Author:** padminipyapali
**Created:** 2026-04-25 05:37:11 UTC
**Merged:** 2026-04-25 05:38:54 UTC (self-merge)
**Duration:** ~1.7 minutes (open -> merged)
**Size:** +954 / -0 across 12 files, 8 commits

## Summary

Second implementation PR of the v0 family-digest stack. Adds the composition pipeline's first three stages: a busy/cancelled event filter, attendee-aware categorization (`together` vs `owner` fallback), and an Anthropic-backed narrative generator with an output-validation hallucination guard. 35 new tests bring the suite to 67/67. Self-merged by author ~1.7 minutes after open with no peer reviews and no CI checks configured.

## Local Review (pre-push)

- **CodeRabbit:** not tracked. The PR body has no `## Local Review` section; CodeRabbit CLI was not invoked.
- **Adversarial:** 4 findings, 4 fixed in one cycle, named explicitly in the PR body's Test plan: (1) force LLM to wrap event titles in double quotes (hallucination guard hardening), (2) frame event JSON as read-only data to defend against prompt injection, (3) replace non-null assertions in tests with explicit checks (defensive coding), (4) add a whitespace-only LLM response test (edge case).
- **Shift-left rate:** 100% of known issues caught locally; 0 post-push findings.

## Step Compliance

- **Step compliance:** not tracked (PR body has no `Steps skipped:` line).
- **Inferred from PR body:** Step 1 (plan implied by PR body referencing PR-2a/2b/2c split), Step 2 (implement), Step 3 (`tsc --noEmit` + `vitest run` + `eslint` all green per Test plan), Step 4c (adversarial review APPROVE after one fix cycle), Step 5 (push+PR). No evidence of Step 4a (`/simplify`) or Step 4b (CodeRabbit CLI).
- **Skip assessment:** neutral — no post-push review happened, so we cannot confirm whether `/simplify` or CodeRabbit would have caught additional issues.

## Step Timing

Not tracked (no `## Step Timing` section in PR body).

## Review Friction (post-push)

- **Review rounds:** 0. No reviewers assigned; `reviewDecision` empty; `reviews: []`; `comments: []`; inline comments empty.
- **Comments:** 0 inline, 0 general.
- **Categories:** all zero.
- **Timeline:** created -> merged in ~1.7 minutes by author. No peer review gate applied.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 100% (4/4 substantive issues caught pre-push; 0 escaped to post-push review).
- **Covered and caught:**
  - Prompt-injection framing (Tier: LLM integration / instruction-data separation) — present in `llm-integration.md`.
  - Hallucination guard via verifiable output structure (LLM integration / structured output validation).
  - Non-null assertions in tests (defensive coding / test-quality) — replace `!` with explicit existence checks.
  - Whitespace-only LLM response edge case (LLM integration / empty-response handling, and "trim and validate user input at the earliest pipeline entry point").
- **Not covered (no new categories required):** none. All four findings map cleanly to the existing adversarial checklist + LLM integration knowledge file.

## Fix-up Metrics

- **Post-merge fix rate:** 0% (0 follow-up fix commits within 48 h of merge — confirmed by checking the merged-PR list).
- **Pre-merge catch rate by step:**
  - 4a (simplify): 0 fixes
  - 4b (internal/CodeRabbit CLI): 0 fixes (not run)
  - 4c (adversarial): 4 fixes (commits 5–8 are the four named adversarial fixes)
  - 4d (CI): 0 fixes
  - post-push: 0 fixes
- **Pre-merge iteration count:** 1 (healthy; single adversarial fix cycle).
- **Fix-up taxonomy:** correctness 1 (force LLM to quote event titles — prompt change tightening the hallucination guard), style/llm-hardening 1 (frame event JSON as read-only — prompt-injection defense), defensive-coding 1 (replace non-null assertions in tests), test-quality 1 (whitespace-only response test).
- **Legacy fix-up ratio:** 50% (4 fix / 8 total commits). Same caveat as PR #1 — fix commits are landed individually rather than squashed into the feature commit they amend, which inflates this ratio. Iteration count (1) is the more meaningful signal.

## Planning Quality

- **Description:** complete — Summary by file, hallucination-guard explanation, multi-PR scoping note ("Part 2a of multi-part PR 2"), Test plan with checkboxes, explicit Size note declaring the 600-LOC exception (817 LOC total: 351 source + 466 tests).
- **Scope:** clean — three tightly-coupled composition stages land together because they share the typed event model and tests need the full surface. No scope creep, no redesign indicators.
- **Branch lifetime:** ~0.03 hours (one-shot push).
- **Planning checklist:** entry points enumerated implicitly via tests (together vs owner fallback, unknown source calendar throw, busy filter, cancelled filter, whitespace-only LLM response). No explicit Performance & Cost Impact section — relevant here because this PR introduces the first paid LLM call (Claude Sonnet) on every digest run. The cost envelope and rate-limit posture should have been documented.

## Code Quality Signals

- **Recurring issues:** none across the 2-PR history. Adversarial review continues to surface defensive-coding and edge-case gaps (1 in PR #1, 4 in PR #3) and the catch rate is 100% pre-push.
- **New unrecorded patterns observed:**
  - **Hallucination guard via verifiable output structure.** The LLM is instructed to quote event titles; the post-processor regex-extracts quoted titles and verifies each against the input event list. This is a generalizable pattern — strengthens the existing "validate/filter LLM structured output against the source of truth" entry in `llm-integration.md`.
  - **Throw on unknown source calendar (programming error).** The categorizer throws rather than returning a default for an unknown calendar. This aligns with the existing "exhaustive `never` checks should throw, not return" rule in `typescript-patterns.md` but this is a runtime-data variant worth noting (config drift, not type-system drift).
  - **Multi-part PR with explicit 2a/2b/2c sequencing in the body.** Useful template for splitting a >600-LOC feature into review-friendly chunks.

## Process Efficiency

- **Automation opportunities:**
  - The `## Local Review` and `## Step Timing` sections remain absent from family-digest PR bodies (PR #1 recommended adding them; PR #3 still does not). This is the clearest unaddressed recommendation from the previous post-mortem.
  - CodeRabbit CLI was not invoked, again. For a 954-LOC PR introducing the first paid LLM integration with a custom prompt-injection defense and output validator, an independent second opinion would have been high-leverage.
  - No GitHub Actions CI configured (`statusCheckRollup: []`). Local checks remain the only gate.
- **Iteration:** efficient (1 adversarial cycle, 0 post-push rounds).
- **CI status:** none configured. Local `tsc`, `vitest`, `eslint` clean per PR body.

## Risks & Observations

- **Self-merge with no peer review, second time.** Same posture as PR #1: merged by author within 2 minutes of open. Pragmatic for solo dev, but PR #3 introduces an external paid API + a security boundary (prompt-injection defense). The independent-review gap is more material here than in PR #1's scaffolding.
- **No Performance & Cost Impact section.** PR #3 is the first PR that adds a recurring per-digest paid API call (Claude Sonnet). The PR body should have explicitly stated the expected cost per digest, the rate-limit posture, and the failure mode (throw vs partial content).
- **PR #1 recommendations not adopted.** The previous post-mortem recommended (1) adding `## Local Review`/`## Step Timing` sections to PR bodies, (2) running CodeRabbit CLI on every PR >= 500 LOC, (3) configuring CI before PR #2. None of the three landed before PR #3. Recommendation drift is the most actionable signal from this post-mortem.

## Recommendations (ranked)

1. **Adopt the PR-body template now.** Add `## Local Review`, `## Step Compliance`, and `## Step Timing` sections to family-digest PR template (e.g. `.github/PULL_REQUEST_TEMPLATE.md`). PR #4 should use it.
2. **Run CodeRabbit CLI on PR #4.** PR #3 is the second consecutive PR >= 500 LOC without an independent second opinion. Even if shift-left remains 100%, the gap should be closed before more LLM-integrated code lands.
3. **Add a Performance & Cost Impact section to LLM-touching PRs.** Required for any PR that adds or changes a paid API call. Include $/digest, rate-limit headroom, and failure mode.
4. **Configure GitHub Actions CI before PR #4.** Two PRs in with no CI gate. A minimal workflow running `tsc --noEmit` + `vitest run` + `eslint` would close the loop.
5. **Strengthen `llm-integration.md` with the verifiable-output-structure hallucination guard pattern** (force the model to quote source-of-truth strings, then regex-extract and verify post-hoc). Generalizable to any LLM-generated reference to known entities (event titles, file paths, user IDs).

## Knowledge Updates

- `llm-integration.md`: strengthen the "validate/filter LLM structured output against the source of truth" entry with the quoted-title-verification pattern (force quoting via system prompt + regex-extract + set-membership check). Source: post-mortem, family-digest #3, 2026-04-22.
- `process-patterns.md`: new pattern — Recommendation drift across consecutive PRs. When a post-mortem recommendation does not land before the next PR ships, escalate it: convert it from prose recommendation to a project artifact (PR template file, CI workflow, lint rule). Source: post-mortem, family-digest #3, 2026-04-22.
- `process-patterns.md`: new pattern — PRs that introduce or modify paid external API calls require a "Performance & Cost Impact" section in the body, even when planning quality is otherwise complete. Source: post-mortem, family-digest #3, 2026-04-22.
