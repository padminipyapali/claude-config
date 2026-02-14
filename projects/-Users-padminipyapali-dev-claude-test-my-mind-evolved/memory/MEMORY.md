# Memory

## Project-Specific
- See `patterns.md` for codebase patterns and conventions.

## LLM Integration Learnings
- See `llm-integration.md` for lessons on parsing LLM output, prompt design, etc.

## Architecture Learnings
- See `architecture.md` for identity mapping, fire-and-forget patterns, etc.

## Database / pg Driver Learnings
- **pg returns DATE columns as JS Date objects, not strings.** TypeScript generic params on `pool.query<T>()` don't enforce runtime types — pg returns what it returns. Always verify pg's actual JS type for new columns (DATE→Date, TIMESTAMPTZ→Date, JSONB→object, TEXT→string). Mocks using strings will pass but production breaks.
- When adding a new DB column to a query result, the adversarial review should ask: "Does the TypeScript type match what pg actually returns at runtime?"

## PR Review Anti-Patterns (from PR #23, #50, #55, #58, #59)
- See `patterns.md` section "Common PR Review Anti-Patterns" for the full checklist (items #1-26).
- See `architecture.md` for async initialization ordering, timezone computation, and external API patterns.
- Key items: dead code cleanup, server-timezone-dependent date parsing, loose parameter typing, async startup ordering, LLM prompt example consistency.
- **From PR #50:** Input type validation at API boundaries (`typeof` before `.trim()`), guard after create→reload patterns, CSS modern color notation (`rgb()` not `rgba()`), JSDoc on test helper factories.
- **From PR #55:** Correlated subqueries must include `user_id` scoping (defense in depth). Shared type changes require updating all test mock factories.
- **From PR #58:** Optimistic UI must capture prev state (not invert). Business logic in service not route. Env var range validation. Fail-fast timezone validation. SVG `<title>` for a11y. Semantic `<button>` not `<div role="button">`. Surface hook error states. At-most-once dedup markers before action. Validate enum query params with 400.
- **From PR #59:** Timezone consistency (resolve once, pass through). Reuse existing DB pools (no ad-hoc `new Pool()`). Off-by-one time boundaries (exclusive upper bound, not T23:59:59). Filter external API data before mapping. UTC `Z` suffix in test Date strings. JSON.parse try/catch on external config.

## Planning Discipline
- **Always adversarial-review plans before presenting them.** The first plan is often not the best. After generating a plan, run a cost/risk/tradeoff analysis asking: "What are the downsides? What costs (monetary, complexity, accuracy) are we not thinking about? Is there a simpler alternative with similar benefits?"
- Example: "Combine classifier + response into one AI call" sounded good but was ~25% more expensive per message, risked classification accuracy, and added parsing fragility. "Parallelize createEntry + generateResponse" achieves the same latency savings with zero risk and no cost increase.
- Run at least one adversarial review pass on every non-trivial plan. For high-impact changes, run two.
- **Every plan and product spec MUST include a "Performance & Cost Impact" section.** Cover: (1) latency impact per user action, (2) new external API calls and their per-call cost, (3) new DB query load, (4) frequency of the affected code path (once/day vs. every click), (5) mitigations if impact is non-negligible. Flag avoidable costs (e.g., re-embedding content that's already stored).

## Sub-Agent Delegation Learnings
- When spawning agents for PRs, ALWAYS include explicit instruction: "Run the Pre-PR Adversarial Review checklist from CLAUDE.md before committing."
- Key items agents miss: (1) user scoping on ALL DB queries, (2) log sanitization (no raw user content in console.log), (3) try/catch granularity matching existing graceful degradation patterns.
- Agents follow feature correctness but skip security/robustness review unless explicitly prompted.
- **Parallel agents must use separate branches/worktrees.** If two agents share a checkout (same branch), Edit tool triggers "file modified since read" errors because one agent's writes look like linter reverts to the other. Use `git worktree` or ensure each agent creates its own branch before editing files. The P0.2 agent lost ~15 min fighting this when it shared a checkout with the docs cleanup agent.

## Why Checklists Fail (and How to Fix It)
Root causes identified from PR #58 (missed same items across round 1, adversarial review, AND round 2):
1. **Checklist items are principles, not procedures.** "Fire-and-forget contract enforcement" tells WHAT but not HOW. Fix: convert to mechanical grep-based steps (grep → trace → verify).
2. **Fix agents deprioritize secondary tasks.** When told "fix 9 comments AND run adversarial review," the review gets checkbox treatment. Fix: use SEPARATE agents — fixer commits, then reviewer runs review as sole job.
3. **Fix-induced bugs escape the fixer.** The agent that wrote a catch-all `return []` won't question its own code. Fix: second pair of eyes (separate reviewer agent).
- **Implemented:** Updated `adversarial-review/SKILL.md` with Tier 1 mechanical grep steps. Updated `review-fix/SKILL.md` with two-agent pipeline (fixer → reviewer).

## Adversarial Review Blindspots (Recurring)
These patterns are in the checklist but keep getting missed. DOUBLE-CHECK these explicitly:
- **Fire-and-forget try/catch granularity.** When a method is called with `.catch()` at the call site, EVERY `await` inside must have its own try/catch. We've missed this on PR #23, #58 (round 1 AND round 2). Check: find every `.catch()` call site → trace into the method → verify each `await` is guarded.
- **Error swallowing in catch blocks.** A catch-all that returns `[]` or a default value masks real DB outages. Only return defaults for EXPECTED edge cases (entry not found, no embedding). Unexpected errors (connection failure, query syntax) must propagate or be rethrown. Check: every `catch` block — is the error expected or unexpected?
- **Broad vs. narrow try/catch scope.** Don't wrap an entire method in one try/catch. Wrap only the part that can fail in expected ways. Let unexpected failures propagate to the caller's error handler.
- **Grammar in user-facing text.** When constructing messages with count-dependent nouns ("entry"/"entries"), also check pronouns ("it"/"them") and other dependent words.
