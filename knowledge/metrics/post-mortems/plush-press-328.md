# Post-mortem: plush-press PR #328 — Bind a book to an art style and thread it into the composite render path (Stage 2 of Art Styles)

- Branch: `feat/book-style-binding` → `main` | Author: padminipyapali (self-merged) | created 2026-07-20T01:16:18Z → merged 2026-07-20T01:34:57Z (~19 min)
- Size: +774 / −40 across 14 files, 1 squashed commit. **814 LOC — exceeds the 600 LOC cap** with no explicit exception declared in the body (mitigation: a large share is tests + spec updates; single concern; see Recommendations).
- CI: `studio` check SUCCESS (only check; passed pre-merge).
- Process: orchestrator team, plan-first — 2 design decisions surfaced and confirmed with the operator before code (book binding lives on the Project record; README front-matter seam dropped). Implementer + fresh-context critic per protocol. This is also the pre-registered risk-escalation from the #327 post-mortem ("Stage 2 changes runtime behavior — route through the full fresh-context critic"), which was honored.

## Local review (pre-push) — from the PR body's `## Local Review` section

- **4a `/simplify`:** not run as a separate pass; skip recorded with reason (code written to house patterns). Tracked skip, not drift.
- **4b CodeRabbit CLI:** ran 3× (free CLI, non-deterministic): one run → 3 findings, two runs (incl. `--agent`) → 0. One substantive real finding: `SceneCanvas` re-fetches the render style per page because `SceneCreator` mounts it with `key={page.id}`. Real but minor (fast local-FS resolve, single-user tool); the clean fix is a non-trivial refactor of a critic-approved surface, so it was **deferred with a code comment + spec follow-up** rather than shipped unreviewed. Within the "only defer fixes needing new infrastructure" allowance; recorded → coderabbitFindings 1, fixed 0, iterations 3.
- **4c adversarial critic:** fresh context, verdict **SHIP, 0 findings**; full entry-point matrix walked (unbound / explicit-default / valid-non-watercolor / dangling / corrupt-pointer / global-pointer present-absent).
- **Gates:** all four green in the worktree (2475 tests / 158 files, lint 0 errors, typecheck clean, build with the new route present).
- Shift-left rate: 1/1 issues surfaced locally (100%); 0 post-push findings.

## Step compliance

- Steps run: 1, 2a, 2b, 3, 4b, 4c, 4d, 5 (8/9). Skipped: 4a with recorded reason. Compliance rate: 88.9%.
- Skip assessment: **good** — 0 post-merge fixes, no simplification-class escapes; both independent review lenses came back essentially clean.
- **Evidence-tracking gap FIXED:** #325 and #327 had no `## Local Review` / `Steps skipped:` sections (stepCompliance null, adversarialCatchRate "unmeasured"). #328 restored both sections per the #327 post-mortem's #1 recommendation, and the metric pipeline is populated again. Residual: `## Step Timing` still missing → stepTiming null (recommendation 2/3 landed).

## Review friction (post-push)

- GitHub reviews: none (`reviews: []`, `comments: []`, reviewDecision empty). Inline-comments API 503'd repeatedly during analysis, but PR-level arrays confirm zero review activity. Self-merge with no peer review — expected on this solo repo; the local trio (critic + CodeRabbit + gates) is the review, per standing pattern.
- Comment categories: all 0. Timeline: created → merge ~19 min, no review-fix cycles post-push.

## Adversarial review effectiveness

- **adversarialCatchRate: 0.0 (measured, n=1).** Denominator = 1 total pre-push finding (CodeRabbit's per-page re-fetch); the critic caught 0 of it. NOT a critic-failure signal: the finding is an efficiency/architecture class outside the correctness-focused adversarial checklist, and the critic's SHIP/0 came from a genuinely walked entry-point matrix. This is the "findings on this slice were CodeRabbit-flavored" shade (cf. second-brain #892–#903 division-of-labor entry). Not fabricated; computed from the PR body's per-gate evidence.
- Covered-but-missed: none (no escaped issues; 0 post-merge fixes).
- New checklist categories: none warranted — per-page redundant fetch is an efficiency nit CodeRabbit automates; adding it to the manual checklist would spend the convention budget on a machine-checkable class.

## Fix-up metrics

- **Post-merge fix rate: 0.0** — merge commit `a940fcc` is the current main tip; no follow-up fix commits/PRs touch the feature area.
- **Pre-merge catch by step:** all 0 fix commits (the single CodeRabbit finding was deferred, not fixed; the branch squashed to 1 clean feature commit). postPush: 0.
- **Pre-merge iteration count: 1** (healthy — one pass through the gates, no fix-review cycles).
- **Fix-up taxonomy:** all zeros. Legacy fixupCommitRatio: 0.0 (0 fix / 1 commit).

## Planning quality

- Description: **complete** — What & why, resolution-chain design, safety behavior (fail-closed on dangling/corrupt binding, no path leaks), byte-identity proof, a documented known limitation (global-pointer race on unbound books, unreachable today), gates evidence, spec updates. Entry-point matrix explicitly enumerated. No standalone Performance & Cost section, but the one perf-relevant fact (per-page style re-fetch) is analyzed and dispositioned in the body.
- Scope: clean single concern; branch lifetime under an hour; no revert/redesign indicators. Size is the one blemish (814 LOC > 600 cap, undeclared).
- Plan-first worked: the 2 design decisions (Project-record binding; dropping the README seam) were surfaced and confirmed before implementation, and the second is recorded in the spec's "Decisions locked."

## Process efficiency

- Iteration: efficient (1 local cycle, 0 post-push, 0 post-merge).
- Automation opportunity: none new. The CodeRabbit non-determinism (3/0/0 across three runs) suggests treating the union of runs as the finding set — captured in process-patterns.md.
- Safety design worth reusing: a bound book **blocks the paid render** on an unresolvable style rather than silently defaulting — fail-closed on a $0.04 irreproducible operation, consistent with the never-lose-a-render principle.

## Knowledge updates

- `~/.claude/knowledge/process-patterns.md`:
  - NEW (Review Efficiency): free CodeRabbit CLI non-determinism — triage the run WITH findings; never re-roll to 0 or accept a first 0 as proof. <!-- plush-press #328 -->
  - STRENGTHENED (Scope Decisions, "Annotate `Steps skipped:`"): recommendation-loop closed within one session — #327's restore-the-sections recommendation implemented on #328; evidence pipeline repopulated; Step Timing still missing.
- `post-mortem-metrics.json`: entry appended (470 PRs). `dashboard.html`: METRICS_DATA regenerated.

## Recommendations

1. **Add `## Step Timing` to the orchestrator's PR-body template** — the last third of the #327 recommendation. Local Review + Steps skipped are back; timing is still null, so bottleneck analysis (e.g., was 3× CodeRabbit the slowest step?) remains impossible.
2. **Declare 600-cap breaches in the PR body** ("cap exception — N LOC of tests/spec; logic LOC ~X"), per the standing rule. 814 LOC shipped silently; the breach was benign (test-heavy, 0 escapes) but silent exceptions erode the cap.
3. **Watch the deferred re-fetch follow-up** (lift style resolution to `SceneCreator`; tracked in `docs/ART_STYLES_SPEC.md`). Per Follow-Up Discipline, if it survives two more stage PRs un-landed, escalate to its own focused PR rather than re-noting.
4. **Durability check on the restored sections:** the next plush-press PR is the test of whether #328 was a primed one-off (the baby-name-picker #115→#121 signature) or a durable template change. If the sections vanish again, promote them from prose to a PR-template/hook artifact per the 3-violation escalation rule.
