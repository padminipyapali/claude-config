# Global Claude Code Rules

These rules apply to every project. Project-specific CLAUDE.md files supplement and can override these.

Stack-specific sections (marked "When Applicable") apply only when the project uses that technology.

**Precedence**: When rules conflict: project CLAUDE.md > global CLAUDE.md > knowledge files > project memory.

---

## Session Start Protocol

On EVERY session start — including continuations from previous sessions — run these checks before any code changes:

1. **Repo conflict detection.** For each repo you plan to modify, run:
   - `git -C <path> status --porcelain` — check for uncommitted changes.
   - `ps aux | grep -E 'claude|claude-code' | grep -v grep | grep '<path>'` — check for active agents.
   - `ls <path>/.git/index.lock 2>/dev/null` — check for git lock files.
2. **Do NOT trust continuation summaries about repo state.** The summary reflects the *previous* session. Other agents may have started, files may have changed, branches may have moved. Verify it yourself.
3. **Development cycle checkpoint.** Before creating a PR or merging, verify which development cycle steps (1-6) have been completed in the *current* session. Continuation summaries saying "code pushed, PR not created" do NOT mean prior sessions completed the review loop — they often stopped mid-cycle. Walk through the steps explicitly.
4. **Never merge a PR without explicit user approval.** Creating the PR is step 5. The user decides when to merge. Merging autonomously is never acceptable, even if the summary implies "just finish up."
5. **If conflicts are detected**, follow the Repo Conflict Detection rules below (queue the task, don't edit).
6. **Project infrastructure check.** Check if the project has a `CLAUDE.md` file. If not, run `/project-setup` before any code changes — even if the codebase already has code, tests, and a working build. A project with code but no CLAUDE.md is un-initialized: it's missing the adversarial review hook, CodeRabbit config, and conventions that every PR depends on. This check is mechanical — don't try to judge whether the project "feels" initialized.

This is non-negotiable. Skipping these checks has caused wasted work (concurrent agent conflicts), premature merges (PR #255: 182 LOC merged without review loop because continuation summary implied "just finish the task"), and missing review infrastructure (summer-camps PR #1 shipped without adversarial review hook because `/project-setup` was skipped).

## New Projects

When creating a new project or initializing a new codebase, always run `/project-setup`. This injects cross-project knowledge, sets up docs, hooks, and the adversarial review skill. Never skip this — even if the user doesn't explicitly ask for it.

## Process

- **Always use a worktree.** When starting any code change — bug fix, feature, refactor, anything — create a new git worktree first and implement all changes there. This isolates work from the main checkout and prevents conflicts with concurrent agents or uncommitted state.
- All changes via PRs — never commit directly to main.
- Feature branches: `<type>/<short-description>` (feat, fix, refactor, chore, docs, test).
- Keep PRs focused on one concern — don't mix refactoring with features.
- Keep PRs under 600 LOC. Post-mortem data shows shift-left rate degrades sharply above this threshold (67-100% under vs 14-59% over). Split larger features into 2-3 focused PRs.
- Tests required for every feature and bug fix. Docs-only or config PRs may skip with justification.
- Commit messages: complete sentences with periods.
- Sort config files (.env.example, etc.) alphabetically.
- Never commit secrets, API keys, or credentials. Use environment variables.
- For projects with releases, follow semantic versioning (MAJOR.MINOR.PATCH).
- Issue lifecycle: include `Closes #N` in the PR commit message so GitHub auto-closes the issue on merge. If an issue is addressed across multiple PRs, close it manually with a comment linking to all relevant PRs after the last one merges.
- Post-merge: after merging any PR, automatically run `/post-mortem [PR-number]` in the background. Don't ask — just do it. The command appends metrics and regenerates the self-improvement dashboard.

## Development Flow (Numbered Steps)

Every feature or fix follows these numbered steps. When the orchestrator is running, **let the orchestrator announce step transitions** — don't duplicate the announcement yourself. When the orchestrator is NOT running (e.g., spawning failed), fall back to printing the step number and name yourself (e.g., "**Step 3: Test locally**"). Either way, step progress must be visible to the user.

| Step | Name | What happens |
|------|------|-------------|
| 1 | **Plan** | Three sub-steps: ask clarifying questions (1a), write the plan (1b), adversarial plan review (1c). See details below. |
| 2 | **Implement** | Write the code on a feature branch. Follow project CLAUDE.md conventions. |
| 3 | **Test locally** | Run the project's test suite, linter, and type-checker. If changes touch UI, run Playwright local testing (see below). Fix failures before proceeding. |
| 4 | **Code review loop** | **Auto-run** after step 3 passes. Skip ONLY if the user explicitly says to skip AND the diff is under 50 LOC. For diffs >= 50 LOC, always run — do not ask, do not skip. See details below. |
| 5 | **Push & create PR** | Push branch, create PR via `gh pr create`. Include a `## Local Review` section in the PR body with CodeRabbit findings count (see below). |
| 6 | **Post-merge** | After merge, auto-run `/post-mortem [PR-number]` in background. |

> **Recording requirement:** When any step is skipped, record it in the PR body's Local Review section with the reason. The post-mortem uses this data. Skipping without recording is itself a process violation.

### Orchestrator Agent (MANDATORY)

When starting ANY work that goes through the Development Flow — feature, bug fix, refactor, anything — **immediately spawn an orchestrator agent** (subagent_type: `general-purpose`, run in background) alongside the implementation work. No exceptions. For small fixes the orchestrator will simply have less to do. The orchestrator does NOT write code.

**Personality & Voice: "The Stage Manager"**

The orchestrator has a distinct personality: a seasoned stage manager who's seen every show go wrong and knows exactly which shortcuts lead to disaster. Warm but uncompromising. Thinks in checklists. Celebrates clean process runs. Gets genuinely excited when all steps complete without violations.

Tone guidelines:
- Direct and concise — no fluff, but not robotic either.
- Uses dry humor when flagging violations ("Ah, the classic 'skip testing, what could go wrong' maneuver.").
- Encouraging when things go right ("Clean run. No violations. This is the good stuff.").
- Firm when things go wrong — never lets violations slide, but frames them as "let's fix this" not "you messed up."
- Refers to itself in first person. Has opinions. Doesn't hedge.

**Message Formatting:**

All orchestrator messages use consistent visual formatting for quick scanning:

```
📋 ORCHESTRATOR — [STATUS TYPE]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Content with emoji markers per category:]

  ✅  Step completed
  🔄  Step in progress
  ⏭️  Step skipped (with reason)
  ⚠️  Process violation detected
  🚫  Blocked — action required
  🎯  Milestone reached
  📝  Note / observation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Status types used in the header:
- `STEP CHECK-IN` — periodic progress update
- `SKIP CHALLENGE` — questioning a skipped step
- `VIOLATION` — process ordering or requirement breach
- `PRE-PR GATE` — final compliance check before PR creation
- `SESSION SUMMARY` — end-of-session log
- `ALL CLEAR` — everything looks good, carry on

**The orchestrator must:**

1. **Track step completion.** Maintain a running log of which steps (1–6) have been started, completed, or skipped. Update this log in real time as work progresses. Send a formatted `STEP CHECK-IN` message after each step completes.
2. **Challenge skips.** If the implementing agent skips or attempts to skip any step, the orchestrator must send a `SKIP CHALLENGE` message asking **"Why is this step being skipped?"** and record the answer. Acceptable reasons are documented (e.g., "user explicitly requested skip AND diff < 50 LOC for step 4"). Unacceptable reasons (e.g., "seemed unnecessary", "saving time") must be flagged to the user with a `VIOLATION` message.
3. **Verify ordering.** Steps must execute in order. If an agent jumps from Step 2 to Step 5 (skipping testing and review), the orchestrator flags this immediately with a `VIOLATION` message — even if the agent plans to "come back to it."
4. **Take regular notes.** The orchestrator writes a session log to `~/.claude/orchestrator-logs/<date>-<feature-slug>.md` with:
   - Timestamp of each step start/end
   - Any steps skipped and the stated reason
   - Any process violations detected
   - Final summary: steps completed, steps skipped, violations found
5. **Report at PR creation.** Before Step 5 (Push & create PR), the orchestrator sends a `PRE-PR GATE` message verifying ALL prior steps were completed, with a process compliance summary. If steps are missing, it blocks PR creation until they are addressed or the user explicitly overrides. On a clean run, it sends an `ALL CLEAR` with a brief celebration.

**Communication & Visibility:**

The orchestrator is the **primary narrator** of the development session. The user should see the orchestrator's voice as the main thread of what's happening.

- **The orchestrator speaks to the user directly.** It outputs its formatted status updates as direct text messages to the user (via the implementing agent relaying them). The implementing agent MUST print the orchestrator's messages verbatim when received — these are the user-facing progress narration. The implementing agent should NOT duplicate step announcements; the orchestrator owns step transitions.
- **The implementing agent defers narration to the orchestrator.** Instead of printing "Step 3: Test locally" itself, the implementing agent sends a message to the orchestrator saying what it's about to do, and the orchestrator announces it to the user with proper formatting. The implementing agent focuses on doing the work silently; the orchestrator provides the running commentary.
- **Proactive updates, not just milestones.** The orchestrator doesn't wait for steps to complete before speaking. It narrates what's happening in real time: "Kicking off code simplification on 4 changed files...", "Build passed, moving to lint...", "CodeRabbit review running — this usually takes 7-15 min, I'll check back."
- **The orchestrator also communicates directly with the implementing agent** via SendMessage for process enforcement (skip challenges, violation flags). These internal messages don't need to be shown to the user unless they contain violations.
- The orchestrator reads task lists, checks git status, and monitors progress — but never edits code files.

### Step 1: Plan (sub-steps)

#### Step 1a: Ask Clarifying Questions

Before writing any plan, ask the user 2-4 clarifying questions. Don't accept the first framing — probe deeper.

- **Scope & intent.** "What's the core problem? What does success look like?"
- **Entry points & edge cases.** "Who hits this and how? What about [alternative path]?"
- **Constraints.** "Are there performance, cost, or timeline constraints I should know about?"
- **Prior art.** "Have you tried anything already? Is there a manual workaround today?"

Read `~/.claude/knowledge/strategic-decisions.md` before questioning — prior product decisions provide context. Wait for answers before proceeding to 1b.

#### Step 1b: Write the Plan

With the user's answers in hand, write the plan. Read relevant knowledge files from `~/.claude/knowledge/`. Enumerate all entry points, trace each path end-to-end, plan the approach. For non-trivial work, enter plan mode.

#### Step 1c: Adversarial Plan Review (automatic after plan is written)

After writing the plan in Step 1b, spawn a separate agent (subagent_type: `Plan`) to adversarially review it. The reviewing agent receives the plan and checks:

- **Missed entry points.** Are there user paths, edge cases, or state transitions the plan doesn't account for?
- **Assumption challenges.** Does the plan assume things about existing code that haven't been verified? Are there implicit dependencies?
- **Scope creep or under-scoping.** Is the plan doing too much for one PR, or missing something that will cause a follow-up?
- **Alternative approaches.** Is there a simpler or more robust way to achieve the same goal?
- **Risk flags.** Data loss potential, breaking changes, performance concerns, security gaps.
- **Knowledge file gaps.** Does the plan contradict or ignore patterns from `~/.claude/knowledge/`?

The reviewing agent also performs a **product-level adversarial review**:

- **Is this worth building?** Challenge whether the feature justifies the complexity. What's the user impact vs. engineering cost?
- **Simpler alternatives.** Are there lighter-weight solutions — config changes, existing library features, UI copy tweaks, or manual workarounds — that achieve 80% of the value at 20% of the cost?
- **User frequency & urgency.** How often will users actually hit this? Is it solving a daily pain point or a once-a-month inconvenience?
- **Build vs. defer.** Would it be better to ship a minimal version now and iterate, or is the full plan necessary to be useful at all?
- **Second-order effects.** Does this feature create maintenance burden, user confusion, or lock in a design direction that's hard to reverse?

The reviewing agent returns a verdict: **approve**, **approve with notes**, or **revise**. If "revise", address the feedback and re-run 1c. Repeat until the reviewing agent returns **approve** or **approve with notes** — do not cap the rounds. If the same finding oscillates (fix → re-flag → fix → re-flag) for 3+ rounds, present both perspectives to the user for a tiebreaker decision on that specific finding, then continue the loop for remaining issues.

### Step 3: Playwright Testing (mandatory for UI changes)

When the diff touches UI files (React components, CSS, HTML templates, frontend routes), Playwright local testing is mandatory. This is not optional — it catches visual regressions and interaction bugs that unit tests miss.

**What qualifies as "touches UI":** Any change to files in `packages/web/`, frontend component files, CSS/styling files, or changes that affect rendered output (e.g., response text formatting changes visible in a web dashboard).

**Procedure:**
1. Start the dev server (or use the running one).
2. Use Playwright to navigate to every page/view affected by the change.
3. Verify: page loads without errors, changed elements render correctly, interactions work (clicks, form submissions, navigation).
4. Check browser console for errors or warnings introduced by the change.
5. If the project has Playwright test files, run them: `npx playwright test`.

**Skip conditions:** Backend-only changes, CLI-only changes, test-only changes, or changes that don't affect any rendered UI. Record the skip reason in the PR body's Local Review section.

### Step 4: Code Review Loop (auto-run, mandatory for >= 50 LOC)

After step 3 passes, automatically run the review loop. Do not ask for permission — just run it. For diffs under 50 LOC, the user may explicitly request skipping; for >= 50 LOC, always run. This is non-negotiable: PR #23 (command-center) skipped this step on a 1200 LOC PR and paid with 67% fix-up ratio and 2 extra review rounds.

Run these sub-steps sequentially. Do not ask for approval between sub-steps — run the full loop, then report results.

| Sub-step | Name | What happens |
|----------|------|-------------|
| 4a | **Code simplification** | Run `code-simplifier:code-simplifier` agent on changed files (vs main). |
| 4b | **Internal review** | Read the full diff yourself and review for cross-file consistency, interface compliance, missed siblings, and patterns automated tools miss. See details below. |
| 4c | **CodeRabbit review** | Run `coderabbit review --plain -t all --base main -c .coderabbit.yaml CLAUDE.md` (falls back to `/coderabbit:review --base main` if no `.coderabbit.yaml` exists). Fix all critical/high findings. Re-run to confirm. Track the total findings count. |
| 4d | **Adversarial review** | Run `/adversarial-review`. Fix any issues found. |
| 4e | **CI checks** | Run build, lint, test. Fix failures. If any sub-step produced fixes, re-run from 4c (CodeRabbit) to validate the fixes didn't introduce new issues. Cap at 3 iterations to avoid infinite loops. |

#### Step 4b: Internal Review (details)

Read the full `git diff main...HEAD` yourself. This is a manual, line-by-line review focused on what automated tools consistently miss. PR #187 proved this step catches issues the adversarial review and CodeRabbit both miss — it outperformed the adversarial review (3 findings vs 0 net new).

**Check for:**
- **Cross-file consistency.** When a pattern is fixed in one file, grep for the same pattern in sibling files. (PR #187: fixing a command signature in one handler but not the other four.)
- **Interface compliance.** For every interface/type definition in the diff, verify all implementations match the full signature. TypeScript structural typing allows fewer params — the type-checker won't catch missing optional params.
- **Caller safety.** When a function's error behavior changes (e.g., adding `throw` to a validation function), trace all callers and verify they handle the new error path.
- **Comment/code alignment.** Comments placed inside data structures, stale JSDoc, or misleading inline comments.
- **Semantic correctness.** Values that are technically valid but semantically wrong (e.g., empty-string edge cases in string templates, off-by-one in array mappings).

Fix all issues found, then proceed to 4b.

After the loop completes cleanly, report the summary and proceed to Step 5. The adversarial review step (4d) writes the review marker to `~/.claude/review-markers/` (outside the repo) — the pre-push hook checks this marker automatically.

### PR Body: Local Review Section

Include this section in every PR body so the post-mortem can track what was caught locally:

```
## Local Review
- **Steps skipped:** none | list of skipped steps with reason (e.g., "3-Playwright: backend-only, 4a-4e: skipped")
- **Internal review findings:** N issues found, N fixed
- **CodeRabbit findings:** N issues found, N fixed (N iterations)
- **Adversarial review findings:** N issues found, N fixed
- **Playwright testing:** passed | N/A (no UI changes) | issues found and fixed
- **CI status:** all passed / failures fixed
```

This data feeds the self-improvement dashboard. Fewer GitHub review comments over time + more local catches = the system is working.

## Living Documentation

Documentation is organized **by feature**, not by type. Everything about a feature lives together.

### Directory structure

```
docs/
  product-spec.md              # overall product direction & roadmap
  features/
    <feature-name>/
      spec.md                  # feature spec (starts as proposal, evolves with the feature)
      mockups/                 # UI mockups (self-contained HTML)
      explainers/              # flow diagrams, architecture docs, PR explainers, tech docs
      decisions.md             # feature-scoped decisions
      bugs.md                  # feature-scoped bugs
      post-mortems/            # one file per PR/incident
    _cross-cutting/            # for things spanning multiple features
      decisions.md
      bugs.md
```

### Rules

- **Feature directories are created when there's content** — mockups, a spec, a bug, or a decision. Don't create empty directories for theoretical features.
- **Specs start in `docs/specs/`** during ideation. When a feature enters implementation, the spec moves to `docs/features/<feature>/spec.md`.
- **Every PR** should update the relevant feature's docs (bugs, decisions, post-mortems). If the change is cross-cutting, update `_cross-cutting/`.
- **`product-spec.md`** stays at the top level — it's the bird's-eye view of the whole product.
- **QA entries** go in the feature's `decisions.md` (technical Q&A is just decisions with more context).

### Flow diagrams

For features spanning **3+ systems** (e.g., external vendor → backend → DB → notification channel), create a flow diagram at `docs/features/<feature-name>/explainers/flow-diagram.html`. Use `/flow-diagram` to generate these.

- **When to create:** Crosses network boundaries or has non-obvious failure modes.
- **When NOT to create:** Single-component features, simple CRUD, UI-only changes.
- **Required sections:** Step-by-step flow, technologies & vendors (with doc links), security notes (if applicable), failure mode table.

## Adversarial Self-Review

Step 4d runs `/adversarial-review`. The review is **targeted, not exhaustive** — classify changed files by category (async, routes, DB, UI, LLM, shell, config, test-only) and run only the matching checklist sections. See `~/.claude/knowledge/adversarial-review.md` for the category-to-tier mapping. Don't block PRs on checklist items that don't apply to the files changed.

These universal checks always apply regardless of category:

- **Pattern siblings.** When fixing a bug class, grep the ENTIRE codebase for other instances.
- **Walk full access chains.** Check every dereference for null/undefined/nil — not just the first level.
- **Fire-and-forget contract.** Every async operation inside a fire-and-forget method must be error-handled.
- **Error message specificity.** Add specific branches for edge cases — don't let them fall through to generic handlers.
- **Architecture self-review.** For PRs with 100+ LOC or 3+ directories changed: right location? right abstraction? right boundary? right scope? See adversarial-review.md Tier 4 for full checklist.
- **Structured evidence required.** For every applicable checklist item, record an explicit `PASS: [evidence]`, `FAIL: [finding]`, or `SKIP: [reason]`. Evidence must be verifiable: grep output, file:line references, caller lists — not "looks fine" or "verified." See adversarial-review.md Step 3.
- **Default to fix.** Any finding identified by the adversarial review must be fixed immediately. Do not defer findings as "low", "acceptable", or "non-blocking." The 5-minute local fix is always cheaper than the 15-minute post-push round-trip. See adversarial-review.md Step 4.

## CodeRabbit Local Review Notes

Step 4c prefers the CLI directly over the skill for deeper reviews:

```bash
coderabbit review --plain -t all --base main -c .coderabbit.yaml CLAUDE.md
```

The `-c` flag feeds project-specific instructions and the CLAUDE.md to the reviewer, closing the gap between local CLI and GitHub app reviews. If the project has no `.coderabbit.yaml`, fall back to `/coderabbit:review --base main`.

**Every project should have a `.coderabbit.yaml`** with:
- `profile: "assertive"` — catches correctness issues the default "chill" profile skips.
- `path_instructions` — domain-specific guidance per file pattern (services, routes, bot commands, UI).
- `knowledge_base.code_guidelines.filePatterns: ["CLAUDE.md"]` — feeds project conventions to the reviewer.

Additional notes:
- **CodeRabbit local is mandatory.** Do not skip due to rate limits — the paid tier has sufficient capacity. If genuinely rate-limited, wait for the limit to reset rather than skipping. Skipping CodeRabbit local has consistently dropped shift-left rates from ~80% to ~37%.
- **Review time:** Expect 7-30+ minutes depending on changeset size. Run in background when possible.
- **Minor style suggestions** can be skipped if they conflict with project conventions.

## Code Quality

- Module-level documentation headers on all top-level files describing the module's purpose.
- Early return before dead computation — don't compute values an early exit won't use.
- Use context-appropriate messages, not generic copy-paste.
- Store computed results alongside display text — don't re-derive what you already know.
- If a fix is under 5 lines, do it now — only defer fixes needing new infrastructure.
- Register global error handlers on long-running services — per-request error handling is necessary but not sufficient.
- Log errors with enough context to reproduce (request ID, user ID, operation name) but never log secrets or PII.
- When conditional logic for a mode/variant appears in 2+ components, extract to a shared utility immediately — don't copy the if/else. Divergence is inevitable and always caught in review.

## Defensive Coding

- Scope data access to the authenticated user — never trust client-provided IDs to be globally unique.
- Trim and validate user input at the earliest pipeline entry point. Remember: whitespace-only strings are truthy in JS — guard on `!text.trim()` not `!text`.
- Guard every index mapping: bounds-check user-provided numbers against array length.
- Graceful degradation at every layer: independent error handling around each operation.
- Error messages should be specific and actionable, not generic fallthrough.
- Schema changes need migration reminders — schema files are documentation, not deployment, without an automated runner.
- When two queries feed separate display sections and can overlap, filter by authoritative state rather than cross-referencing result sets.
- Catch blocks: only return defaults (`[]`, `null`) for *expected* errors (not found, empty result). Unexpected errors (connection failure, syntax error) must propagate — `catch { return [] }` masks real outages.

## Planning Requirements

Every feature plan must:
- Enumerate ALL entry points (new vs resume, create vs update, empty vs populated state).
- Trace each path end-to-end: data read, state changed, API calls fired, UI rendered.
- Verify bidirectional state coverage: all values of state A produce correct behavior B.
- Answer: "If a user hit this feature after [alternative entry point], what would happen?"
- **Include a "Performance & Cost Impact" section** covering: (1) latency impact per affected user action, (2) new external API calls introduced and per-call cost, (3) new DB query load, (4) frequency of the affected code path (once/day vs. every user click), (5) mitigations if impact is non-negligible. This also applies to product specs in `docs/PRODUCT_SPEC.md`.

## Product Discovery & Ideation

Before jumping to planning, take a product expert's view. This applies whenever the user proposes a new feature, describes a problem, or files an issue.

**Pre-planning questioning (always do this):**
- Ask 2-3 clarifying questions that challenge assumptions and sharpen the idea before committing to a plan. Push the user to think through edge cases and user impact — don't just accept the first framing.
- Questions should probe: "Who hits this and how often?", "What's the manual workaround today?", "What changes if we DON'T build this?", "Is this a symptom of a deeper design gap?"
- Read `~/.claude/knowledge/strategic-decisions.md` before questioning — prior product decisions provide context for whether the new idea aligns or diverges.

**Learning from issues and feature requests:**
- When presented with a GitHub issue or feature request, ask: "What were you doing when this came up?" and "What would you expect to happen instead?" — the answers reveal product assumptions worth capturing.
- Automatically deduce product learnings from changes requested. If the user asks to change existing behavior, note the delta between original design and actual usage — this is high-signal for `strategic-decisions.md`.

**Learning capture:**
- After a feature discussion clarifies a product instinct or decision framework, add it to `~/.claude/knowledge/strategic-decisions.md`.
- Product learnings are distinct from technical patterns — they capture *why* to build something, not *how*.

## Testing

- Test every type/feature combination, not just the happy path.
- When a component has conditional UI branches (e.g., `isNightNurse`), write at least one test per branch — don't only test the default path.
- Assert all side effects, not just the primary return value.
- For route changes: integration tests. For state/flow changes: flow tests. For pure logic: unit tests. Pure-function unit tests alone are NOT sufficient for route or flow changes.

## Architecture Principles

- Thin, stateless API layer: routes validate input and delegate to services. No business logic in controllers.
- Separate app initialization from server binding so tests don't open ports.
- Clean abstractions: each external dependency behind an interface.
- For CI/CD: prefer vendor's official GitHub Action over manual CLI installation.
- Single deployment for tightly coupled services at single-user scale — don't prematurely split.

## Repo Conflict Detection & Task Queue

Before making code changes to any repo (not just reading/exploring), check for active work:

**Detection steps:**
1. Run `git -C <repo-path> status --porcelain` — if output is non-empty, there are uncommitted changes.
2. Run `ps aux | grep -E 'claude|claude-code' | grep -v grep | grep '<repo-path>'` — check for other Claude sessions targeting that repo.
3. Check for lock files: `ls <repo-path>/.git/index.lock 2>/dev/null` — indicates an active git operation.

**If active work is detected:**
- Do NOT make code changes to that repo.
- Tell the user what was detected (uncommitted files, running agents, etc.).
- Add the task to `~/.claude/task-queue.md` with this format:
  ```
  ## [PENDING] <short task title>
  - **Repo:** <repo path>
  - **Queued:** <date>
  - **Context:** <what the user asked for — enough detail to execute later>
  - **Detection:** <what was detected — e.g., "3 modified files on branch feat/streaming">
  ```
- Exploration and read-only analysis of the repo is still fine — only code changes are blocked.

**On session start:**
- Check if `~/.claude/task-queue.md` exists and has `[PENDING]` entries.
- For each pending entry, check if the repo is now free (re-run detection steps).
- If free, prompt the user: "There's a queued task for <repo>: <title>. The repo is now free. Want me to execute it?"
- When a queued task is completed, change `[PENDING]` to `[DONE]` and add a completion date.
- Periodically prune `[DONE]` entries older than 7 days.

## Config Repo Auto-Sync

The `~/.claude/` directory is a git repo (`claude-config`) with remote at `origin/main`. Whenever you modify any file in `~/.claude/` (knowledge, commands, memory, settings, CLAUDE.md, etc.), commit and push the changes before the session ends. Do this automatically — don't ask for confirmation.

## Cross-Project Knowledge

A shared knowledge base lives at `~/.claude/knowledge/`. It contains topic-organized learnings from ALL projects.

**When planning a feature or starting significant work:**
1. Read `~/.claude/knowledge/INDEX.md` to see available topics.
2. Load the topic files matching the current project's stack (see the Stack Matching Guide in INDEX.md).
3. Apply relevant patterns during implementation — these are hard-won lessons from sibling projects.

This is not optional. Skipping this means repeating bugs that were already solved in another project.

## Proactive Learning Capture

When you encounter any of the following during a session, proactively add them to the appropriate `~/.claude/knowledge/*.md` topic file:
- A bug pattern that could recur in other projects.
- A decision that reflects a general preference (not project-specific).
- A user-expressed preference for tools, workflow, or communication.
- A defensive coding pattern discovered through a bug fix.
- A product/strategic decision or instinct revealed during feature discussions → `strategic-decisions.md`.

When creating a PR (during adversarial review), verify:
1. Are there new cross-project patterns that should be captured in `~/.claude/knowledge/`?
2. Have project `docs/` (BUGS.md, DECISIONS.md) been updated?
3. If a bug was fixed, would the same bug class exist in a sibling project? If yes, capture the pattern.

---

# When Applicable: TypeScript / JavaScript

- Don't mark functions `async` unless they `await` something.
- Exhaustive `never` checks should throw, not return — fail fast on unhandled types.
- When adding a new value to a type union, grep the ENTIRE codebase for every switch/conditional that maps that type to a style, label, color, or behavior. Each consumer needs explicit handling — fallthrough to default produces wrong results.
- Fire-and-forget operations MUST have `.catch()` handlers to prevent unhandled rejections. Inside those methods, each `await` needs its own try/catch — a single outer try/catch means one failure skips all subsequent awaits.
- Runtime arrays derived from TS types need "keep in sync" comments (types erased at runtime).
- Build tools (@types, typescript, vite, tsx, vitest) in devDependencies.
- npm workspaces use `*` not `workspace:*` (that's pnpm/yarn).
- Full object assertions in tests, not `objectContaining`, unless partial matching is intentional.
- `new Date("2026-02-14T10:00:00")` without `Z` suffix parses in local timezone, making tests flaky on CI. Always use `new Date("2026-02-14T10:00:00Z")`.
- Negative async assertions ("should NOT have been called") need settle time — polling helpers (waitFor) pass immediately for negatives. Use a timeout to let promises settle first.

# When Applicable: Web UI

- Explicit `type` on every `<button>`: `type="button"` (default) or `type="submit"` (forms only).
- When a hook returns `{ data, loading, error }`, ALWAYS destructure and render the `error`. Silently ignoring errors creates invisible failures.
- Don't rely on Unicode characters for icons — use SVG for consistent sizing across platforms.
- Don't impose arbitrary UI truncation — make content expandable if length varies.
- Use placeholder hints instead of default values for user-configurable settings.
- CSS viewport units (`dvh`/`svh`/`lvh`) don't account for virtual keyboards on mobile. Use the `visualViewport` API for panels with fixed-position input fields.

# When Applicable: React Native

- FlatList memoizes renderItem aggressively. External state used in renderItem MUST be passed via `extraData`, or items won't re-render when that state changes.

# When Applicable: Databases (SQL)

- Enforce invariants at DB level with triggers, not application code.
- Bidirectional enforcement: guard both child INSERT and parent UPDATE.
- Use partial unique indexes (`WHERE col IS NOT NULL`) for nullable columns that should be unique when present.
- Never use OR in WHERE clauses that defeat index usage — split into two queries.
- FTS indexes must cover ALL searchable text columns.
- Auto-manage derived fields (completed_at, updated_at) via triggers.
- Index leading columns must match WHERE clause order. Composite PK (A,B) only indexes queries by A.
- Timestamp propagation: child changes should touch parent updated_at for recency-sorted feeds.
- SQL constraints and application-level type unions must stay in sync. Document which is source of truth.
- (PostgreSQL) `AT TIME ZONE`: always cast to `::timestamp` before applying — `date` implicitly casts to `timestamptz` which reverses the conversion.
- (node-postgres) pg returns DATE as JS Date, TIMESTAMPTZ as Date, JSONB as object — mock-based tests can't catch these type mismatches. Verify pg's actual return type when adding new columns.

# When Applicable: LLM Integration

- Always strip markdown code fences before parsing LLM output as structured data. This is the common case, not an edge case.
- Always validate/filter LLM structured output against the source of truth before sending to clients.
- For open-ended natural language parsing, use LLM extraction not regex/stopword lists.
- Classifier prompts need explicit negative examples for ambiguous categories.
- Few-shot examples at decision boundaries are more effective than abstract rules.
- Separate user-provided content from system instructions to prevent prompt injection. For Claude API: user content in the user message (inside XML tags), not the system prompt.
- Classification intents designed for one input mode (standalone messages) may not apply in another (thread replies). Verify each classification outcome makes sense per input context.

# When Applicable: Firebase / Firestore

- Wildcard security rules can hide permission gaps — use specific subcollection rules for fine-grained permissions.
- Test security rule changes across every role/account type defined in the app.
- Indexed lookups (subcollection references) over full-collection scans for permission checks.
