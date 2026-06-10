# Post-Mortem: plush-press PR #3 — Consolidate docs into a prompt-assembly system (templates + machine-readable bibles)

**Branch:** `docs/prompt-system` → `feat/book-assembler` (stacked on #2) | **Author:** padminipyapali | **Merged:** 2026-06-10T02:59:31Z (squash `7309eea`)
**Size:** +613 −167 across 24 files, 5 commits | **Created→merged:** ~10 min (development ~60 min wall clock)
**Process:** Full orchestrator team pattern (orchestrator + implementer + critic, fresh-context). Session log: `~/.claude/orchestrator-logs/2026-06-09-prompt-system.md`.

## Local review (pre-push)
- **CodeRabbit:** FAILED deterministically on both attempts — "Payload too large", caused by multi-MB PNG `git mv` renames in the diff; CLI v0.5.3 cannot scope the review to text files. A manual scripted review was substituted (link check across all 18 `.md` files, YAML parse of 6 templates + 3 bibles, attachment-manifest existence check, greps for stale refs) — run independently by implementer AND critic, all PASS.
- **Adversarial (fresh-context critic):** 1 finding, 1 fixed pre-PR — Berlioz eye rule forked between YAML front matter (`no eyebrows`) and prose (`no glancing/large eyes`); fixed in commit `f7ce6ef` ("Align Berlioz eye rule between front matter and prose."). Notably, this drift is exactly the bug class the PR's single-source design eliminates — good validation of the design.
- **Acceptance tests:** user-defined 3-test adversarial plan review (1c): fresh-agent orientation, fresh-agent prompt generation (critic did a live mechanical walk of a "new location picnic" assembly), tool-ready templates. All PASS, verified independently by the critic.
- **Shift-left rate:** 100% — the only issue found in the PR's lifecycle was caught locally by the critic; zero post-push findings.

## Step compliance
- Steps run: 1 (plan, incl. 1c via user's acceptance tests), 2a/2b (implement, single pass), 3 (verify locally — scripted checks substituted for build/lint/test on a docs-only PR, justified in PR body), 4a (simplify), 4c (adversarial/critic), 5 (push+PR). → 7/9 ≈ 78%.
- Steps skipped: 4b (CodeRabbit — tool failure, not a choice; scripted review substituted), 4d (CI — none configured on this repo).
- **Skip assessment: neutral** — no post-push review data exists to compare against (solo squash-merge minutes after creation), and no post-merge issues observed. The 4b skip was involuntary and mitigated.

## Step timing (from PR body)
| Step | Duration | Notes |
|---|---|---|
| 1 Plan | ~20 min | user's 3-test adversarial pass served as 1c |
| 2 Implement | ~25 min | bottleneck — 24 files, 4 commits |
| 3 Verify | ~5 min | scripted checks (links/YAML/manifests/greps) |
| 4a–4c Review | ~7 min | CodeRabbit failed ×2; critic + scripted review |
| 5 Push/PR | ~2 min | |
| **Total** | **~60 min** | |

## Review friction (post-push)
None. 0 reviews, 0 comments, self-merged ~10 min after creation (solo-dev norm; the fresh-context critic is the peer-review substitute). A stacked-on-squash conflict arose because parent #2 squash-merged first; resolved with `git rebase --onto` (the known pattern from baby-name-picker #43) before merging.

## Fix-up metrics
- **Post-merge fix rate: 0.0** (nothing as of post-mortem time).
- **Pre-merge catch by step:** 4d/adversarial-critic: 1 (eye-rule fork). 4a/4b/4c/post-push: 0.
- **Pre-merge iteration count: 1** (healthy — single critic round).
- **Taxonomy:** documentation: 1.
- **Legacy fix-up ratio:** 1/5 = 20% (one critic-fix commit kept separate; acceptable, though the "squash adversarial fixes into the commit they amend" pattern would have made this 0%).
- **adversarialCatchRate: unmeasured** — the canonical metric (% of post-push review issues the checklist could have caught) has a zero denominator: no post-push review occurred. Evidence-based observation: 1/1 known issues caught pre-push.

## Planning quality
- **Complete.** PR body has Summary, acceptance tests with independent verification, explicit tests-skipped justification, stacked-PR merge-order callout, CodeRabbit failure note, and Step Timing table.
- **Scope:** clean — docs-only, no app code, no PNG content (renames only). 780 LOC exceeds the 600 cap but is dominated by mechanical doc moves/templates; docs-only exemption reasonable, and the exception was implicitly visible in the body.
- Branch lifetime ~45 min (worktree created → merged).

## Code quality signals
- Recurring issues: none (single finding).
- New pattern validated: machine-readable YAML front matter + single canonical style block kills the duplicated-prose drift class the critic caught one last instance of.

## Process efficiency
- **Automation opportunity (real, recurring hazard):** CodeRabbit CLI cannot review art-heavy diffs — any diff containing multi-MB binary renames trips "Payload too large" with no text-only scoping flag in v0.5.3. For art-heavy repos: separate binary renames into their own commit/PR, or pre-build a text-only diff strategy, and have the scripted-review substitute ready. Captured in process-patterns.md.
- Iteration: efficient (1 round, ~60 min total, clean run, no violations per session log).
- CI: none configured (statusCheckRollup empty).

## Knowledge updates
- `process-patterns.md` → Automation Opportunities: new entry on CodeRabbit CLI payload limit with binary renames (source: this PR).
- `process-patterns.md` → strengthened the stacked-PR + squash-merge `rebase --onto` entry with this PR's confirmation.

## Recommendations
1. For future plush-press PRs (art-heavy repo), keep PNG additions/renames in separate commits or PRs from text changes so CodeRabbit can run on the text diff.
2. Squash critic-fix commits into the commit they amend to keep the legacy fix-up ratio at 0% (existing pattern, family-digest #1).
3. Consider a tiny CI (link check + YAML parse) for this repo — the scripted checks built here are exactly that and could run on every push for free.
