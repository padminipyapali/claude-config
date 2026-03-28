# Review, Triage, and Maintenance Protocols

Loaded on demand during Step 4 (code review) and when managing outside-diff issues.

## Adversarial Review (run by the critic, not the implementer)

Step 4d is run by the **critic** agent — a separate teammate with a fresh context window. The critic receives a deliberately limited context (see `orchestrator-protocol.md` "Critic's Fresh Context" for exact inputs/exclusions). This separation is mandatory — the implementer reviewing its own code has ~10% checklist execution rate.

The review is **targeted, not exhaustive** — classify changed files by category (async, routes, DB, UI, LLM, shell, config, test-only) and run only the matching checklist sections. See `adversarial-review.md` for the category-to-tier mapping.

**Two-phase execution:**
1. **Tier 0 (automated greps):** Run ALL Tier 0 grep checks mechanically and log exact output. These are pass/fail — no judgment required. See "Tier 0 Execution Protocol" in adversarial-review.md. The review marker cannot be written until Tier 0 execution is confirmed with logged output.
2. **Tier 1-4 (judgment items):** Run only the category-matched items, capped at 15-20 per PR (see "Checklist Item Cap" in adversarial-review.md). Every item must produce structured evidence with grep output or file:line references — not "looks fine."

**Critic subagent parallelization:** For PRs touching 3+ file categories, spawn focused subagents — one per category — each running only the relevant checklist section. Each subagent returns PASS/FAIL/SKIP evidence; the critic aggregates, deduplicates, and fixes.

### Universal Checks (always apply)

- **Pattern siblings.** When fixing a bug class, grep the entire codebase. Same-file: fix now. Cross-module: file GitHub issues with `outside-diff` label.
- **Walk full access chains.** Check every dereference for null/undefined/nil — not just the first level.
- **Fire-and-forget contract.** Every async operation in fire-and-forget methods must be error-handled.
- **Error message specificity.** Add specific branches for edge cases — no generic fallthrough.
- **Architecture self-review.** For 100+ LOC or 3+ directories: right location, abstraction, boundary, scope? See adversarial-review.md Tier 4.
- **Structured evidence required.** For every checklist item, record `PASS: [evidence]`, `FAIL: [finding]`, or `SKIP: [reason]`. Evidence must be verifiable (grep output, file:line refs, caller lists) — not "looks fine."
- **Default to fix.** Same rule as Step 4 intro: fix every finding immediately. The only valid deferral: "outside the diff's scope" — file a GitHub issue.

## Outside-Diff Triage Protocol

When the adversarial review (Step 4d) or pattern sibling checks discover issues **outside the current diff**, follow this protocol instead of fixing them inline.

### Per-PR Budget

Each PR may include at most **50 LOC / 2 findings** of outside-diff fixes. Beyond that threshold, file GitHub issues — do not expand the PR's scope.

### Pattern Sibling Split

- **Same-file siblings:** Fix now (counts toward the per-PR budget).
- **Cross-module siblings:** File a GitHub issue with the `outside-diff` label. Do not fix in the current PR.

This refines the "Pattern siblings" universal check above. The universal check defines *what* to look for; this section defines *how much* to fix in-PR vs. defer.

### Severity Classification

| Severity | Criteria | Required Action |
|----------|----------|-----------------|
| **P0 — Critical** | Security vulnerability, data loss, or production crash reachable from the current change. | Fix immediately in this PR regardless of budget. Notify the user. |
| **P1 — High** | Bug that affects correctness for common user paths. Not gated by the current change but discovered during review. | Fix if within per-PR budget. Otherwise, file issue with `outside-diff` label and link in the PR body. |
| **P2 — Medium** | Code smell, missing edge-case handling, or inconsistency that doesn't affect current functionality. | File issue with `outside-diff` label. Do not fix in this PR. |
| **P3 — Low** | Style, naming, minor refactoring opportunities. | File issue with `outside-diff` label only if the pattern is systemic (3+ occurrences). Otherwise, skip. |

**P0 overrides the per-PR budget.** All other severities respect it.

### Integration with Review Steps

- **Step 4b (Internal review):** When cross-file consistency checks find siblings outside the diff, classify per this table before acting.
- **Step 4d (Adversarial review):** The critic records outside-diff findings with severity and disposition (`fixed-in-PR` or `issue-filed: #N`) in structured evidence.
- **PR body:** List all outside-diff issues in the Local Review section: severity, file, and disposition.

## Cleanup Sweep Cadence

Over time, `outside-diff` issues accumulate. This section establishes a scheduled cadence to resolve them systematically, preventing backlog growth.

### Trigger and Frequency

**Create a cleanup sweep PR when:**
- 3 feature/fix PRs have been merged since the last sweep (whichever comes first), OR
- 7 days have elapsed since the last sweep.

**Tracking:** Record the timestamp and PR count in a sweep log (e.g., `~/.claude/SWEEP_LOG.md`) to avoid manual date arithmetic.

### Scope and Prioritization

Cleanup sweeps target issues filed with the `outside-diff` label. Query the issue tracker sorted by severity.

**In each sweep, address:**
- **All P1 issues** (high-severity bugs affecting correctness for common user paths).
- **All P2 issues that fit within 400 LOC** (code smells, missing edge-case handling, inconsistencies). If a P2 issue requires >400 LOC, defer to the next sweep or break into smaller issues.

Do not attempt P3 (low-priority style/naming) issues in cleanup sweeps unless they are quick wins (<20 LOC).

### Branch Naming and Process

- **Branch name:** `chore/sweep-<YYYY-MM-DD>` (e.g., `chore/sweep-2026-03-07`).
- **Process:** Sweep PRs follow the standard development flow (Steps 1-5) but with one exception:
  - **Step 1c (Adversarial plan review) is skipped.** Cleanup sweeps are deterministic and low-risk — the plan is simply "resolve these N specific issues from the issue tracker." A separate plan reviewer is unnecessary.
  - Steps 2-5 proceed normally. Sweeps still require Step 3 (local testing), Step 4 (code review), and go through the full critic review pipeline (4a-4e).

- **PR body:** Include the same Local Review section and Step Timing section as standard PRs. Additionally, document:
  ```
  ## Sweep Summary
  - **P1 issues resolved:** [count] (issue numbers)
  - **P2 issues resolved:** [count] (issue numbers)
  - **Issues deferred:** [count] (reason or next sweep date)
  ```

### Metrics and Monitoring

Track and report the following monthly:
1. **Filed vs. resolved:** Issues filed with `outside-diff` vs. issues closed via cleanup sweeps.
2. **Average age:** Mean age of open `outside-diff` issues (from creation to current date).
3. **P1 latency:** Average time from filing to resolution for P1 issues. Target: under 3 days.

Review these metrics in post-mortems and quarterly retrospectives to detect backlog saturation or reviewer bottlenecks.

## CodeRabbit Local Review Notes

Step 4c uses the CLI directly:

```bash
coderabbit review --plain -t all --base main -c .coderabbit.yaml CLAUDE.md
```

The `-c` flag feeds project instructions and CLAUDE.md to the reviewer. Fall back to `/coderabbit:review --base main` if no `.coderabbit.yaml` exists.

**Every project should have a `.coderabbit.yaml`** with:
- `profile: "assertive"` — catches issues the default "chill" profile skips.
- `path_instructions` — domain-specific guidance per file pattern.
- `knowledge_base.code_guidelines.filePatterns: ["CLAUDE.md"]` — feeds conventions to the reviewer.

- **Never skip CodeRabbit local.** If rate-limited, wait — don't skip. Skipping drops shift-left rates from ~80% to ~37%.
- **Review time:** 7-30+ minutes. Run in background when possible.
- **Minor style suggestions** can be skipped if they conflict with project conventions.
