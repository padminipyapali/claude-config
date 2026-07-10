# Post-Mortem: second-brain PR #865 — fix(tags): always tag proper nouns and steer away from vague theme labels

Branch: fix/tag-proper-nouns → main | Author: padminipyapali | Created 2026-07-09T11:28Z, merged 2026-07-09T12:00Z (~0.5h)
Size: +46 -13 across 2 files, 1 commit. Closes #864.

## Local Review (pre-push)
- PR body has no `## Local Review` section → CodeRabbit/adversarial counts recorded as `null` (not tracked in body).
- Context: the lightweight review path for small PRs (<~100 LOC) was intentionally used — no critic agent, no CodeRabbit. Build, lint (343 files clean), and tests (449 passed across 23 files) all passed pre-push, with evidence pasted in the PR body under "Test evidence".
- Adversarial review gate: the pre-push hook requires a passing adversarial marker, so the adversarial checklist ran (the push succeeded), but no findings count was recorded.

## Step Compliance
- No `Steps skipped:` line in the PR body → `stepCompliance = null` (not tracked in structured form).
- Narrative: steps 1 (plan via issue #864), 2 (implement), 3 (build/lint/test with pasted evidence), 4c (adversarial, gate-enforced), 5 (push+PR) ran. Steps 4a (simplify) and 4b (CodeRabbit) were skipped per the documented lightweight-review convention for small PRs.

## Step Timing
- No `## Step Timing` section → `stepTiming = null`. External context: implementation was interrupted 3 times by API connection errors and once during merge (network instability); no work lost because worktree state persisted on disk.

## Review Friction (post-push)
- Review rounds: 1 (no CHANGES_REQUESTED, no reviews at all).
- Comments: 0 inline, 0 human general (1 Vercel bot comment, excluded).
- Timeline: created → merge 33 minutes. Merged by author with no peer review — expected for this solo project's lightweight path.
- CI: Vercel status SUCCESS; deployment intentionally skipped/ignored for this project.

## Adversarial Review Effectiveness
- Zero post-push review findings and zero fix commits → no denominator exists. `adversarialCatchRate = "unmeasured"` (per metric-integrity rule; not hardcoded).

## Fix-Up Metrics
- Post-merge fix rate: 0.0 as of analysis (2026-07-10, ~1 day post-merge). #865 is the newest merged PR; no follow-up fixes reference tag-suggestion.ts. Short observation window — low confidence.
- Pre-merge catch rate by step: 0 fix commits total (single feature commit). 4a: 0, 4b: 0, 4c: 0, 4d: 0, post-push: 0.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all zeros.
- Legacy fix-up ratio: 0% (0 fix / 1 commit).

## Planning Quality
- Description: complete — Summary with root-cause example (the "Sonam" entry that produced vague tags), precise per-change rationale, explicit note of what was NOT changed (code-level GENERIC_TAGS ban) and why, test evidence, `Closes #864`.
- Scope: clean. Single concern (prompt tuning + cap bump + matching tests). Branch lifetime < 2h of wall time.
- Planning checklist: entry points enumerated (both `suggestTags` and `suggestTagsForText` traced through the shared `suggestForText` core — good sibling-coverage discipline). No Performance & Cost Impact section, acceptable: no new API calls; a cap bump 5→6 marginally increases output tokens only.

## Code Quality Signals
- Recurring issues: none (no review comments to categorize).
- Good pattern worth noting: prompt-contract tests — asserting that the system prompt contains the HARD RULE and steering language keeps prompt tuning from silently regressing. Also: deliberately choosing prompt-level steering over a code-level ban when the banned words can be legitimate in other contexts.

## Process Efficiency
- Automation opportunities: none identified; lint/build/test already gate the push.
- Iteration: efficient (1 round, 1 commit).
- Resilience note: 4 network interruptions (3 during implementation, 1 during merge) caused zero rework because all state lived in the git worktree. Validates the worktree-first workflow as interruption insurance.
- Gap: the lightweight path leaves the PR body without `## Local Review` / `Steps skipped:` sections, so step compliance and local findings are untracked for these PRs. If small-PR post-mortems should stay measurable, the lightweight path should still emit a one-line `Steps skipped:` note.

## Knowledge Updates
- `~/.claude/knowledge/process-patterns.md` (Scope Decisions, "Annotate Steps skipped" entry): strengthened with #865 as a recurrence — the lightweight lane's PR-body template should hardcode a `Steps skipped: 4a, 4b (lightweight path, <100 LOC)` line so convention-sanctioned skips stay measurable.
- `~/.claude/knowledge/process-patterns.md` (Process Compliance): new pattern — worktree-persisted state makes network-interrupted sessions lossless; on resume, verify worktree state (status/diff) instead of trusting the interrupted transcript.
- Metrics: appended to `post-mortem-metrics.json` (adversarialCatchRate = "unmeasured" — critic skipped by convention, no post-push findings to measure against); dashboard regenerated.

## Recommendations
1. Add a one-line `Steps skipped: 4a, 4b (lightweight path, <100 LOC)` to the PR-body template for the lightweight review path — restores step-compliance measurability at near-zero cost.
2. Keep the prompt-contract test pattern (assert prompt contains the behavioral rule) for future prompt-tuning PRs; consider noting it in llm-integration knowledge if it recurs.
3. Re-check post-merge fix rate for this PR at the next post-mortem in this repo (observation window here was ~1 day).
