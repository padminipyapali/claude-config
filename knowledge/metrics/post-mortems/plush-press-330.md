# Post-Mortem: plush-press PR #330 — Add the style specimen engine: storage, resolution, and class routing (Stage 3a of Art Styles)

Branch: `feat/specimen-routing` → `main` | Author: padminipyapali | Created 2026-07-20T03:01:58Z, merged 2026-07-20T03:07:12Z (~5 min)
Size: +693 -9 across 6 files, 1 squashed commit. CI: studio check SUCCESS.

## Context

Stage 3a of Art Styles (`docs/ART_STYLES_SPEC.md`): pure, unwired engine module `studio/src/lib/specimens.ts`
(specimen storage + resolution + class routing) with zero production imports — no-regression trivially proven.
Orchestrator team: plan-first with a scope amendment (the orchestrator split 3a/3b, overriding the implementer's
defer-everything proposal), fresh-context critic, CodeRabbit CLI, all four gates green (2496 tests, typecheck,
lint, build).

## Local review (pre-push)

- **Critic (fresh context): SHIP + 2 minor findings, both fixed.**
  1. Superseded render lost its provenance — old sidecar now renamed alongside the render.
  2. Same-millisecond supersede filename collision — `randomBytes(4)` suffix added.
  Each got a test.
- **CodeRabbit CLI: 1 MAJOR, fixed.** Partial-failure gap: a write failure after the supersede rename left
  the slot empty. Fix: try/catch restore of the superseded render + sidecar; failure-injection test asserts
  restore with no orphaned files. **First run hit the free-tier limit; the retry after the reset produced
  this finding.** The retry-once obligation directly prevented shipping a MAJOR.
- Shift-left rate: 100% (3/3 findings caught and fixed locally; 0 post-push findings).

## Step compliance

Steps run: 1, 2a, 2b, 3, 4b, 4c, 4d, 5 (8/9, complianceRate 0.889). Skipped: 4a `/simplify` (module written
to house patterns; critic + CodeRabbit reviewed structure) and Playwright (no UI surface — pure engine module).
Skip assessment: **good** — zero post-merge issues, no post-push findings related to any skipped step.

## Step timing

PR body's Step Timing table records statuses, not durations → `stepTiming: null` in metrics. (Recommendation:
restore per-step minute estimates so the bottleneck field stays measurable.)

## Review friction (post-push)

Review rounds: 1 (no CHANGES_REQUESTED). Comments: 0 inline, 0 general. Self-merged with no peer review —
solo-dev norm here; the layered local gate (critic + CodeRabbit + adversarial checklist) is the substitute.
Timeline: created → merge ~5 min.

## Adversarial review effectiveness

- **adversarialCatchRate = 0.667, measured from evidence** (2 of 3 local findings caught by the
  critic/adversarial pass; 1 caught by CodeRabbit). NOT fabricated — attribution is explicit in the PR body.
- **Covered but missed (critic):** the partial-failure restore gap arguably falls under "graceful degradation
  at every layer," but no checklist item named the destructive-first-step file-sequence class — so it was
  closer to **not covered**. New Tier 3 checklist item added (see Knowledge updates).
- Division-of-labor evidence strengthened: CodeRabbit again caught a robustness escape on a critic-PASSed
  surface (cf. second-brain #898/#900 pattern).

## Fix-up metrics

- Post-merge fix rate: 0% (no follow-up fix PRs; #330 is the latest merged PR at analysis time).
- Pre-merge catch by step (from PR-body finding attribution; single squashed commit so no per-commit signal):
  4a: 0 | 4b: 0 | 4c (CodeRabbit): 1 | 4d (adversarial/critic): 2 | post-push: 0.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: correctness 2 (provenance loss, filename collision), defensive-coding 1 (restore-on-failure).
- Legacy fix-up ratio: 0% (0 fix commits / 1 commit).

## Planning quality

- Description: **complete** — What & why, no-regression proof, Local Review with finding attribution, Steps
  skipped with reasons, LOC accounting vs the 600 cap, Docs section.
- Scope: **clean** — the 3a/3b split was a deliberate plan-time amendment (recorded in `docs/DECISIONS.md`),
  the opposite of scope creep: the orchestrator overrode the implementer's defer-everything proposal and
  carved a shippable pure-module slice with the create-* collision analysis recorded in the spec instead of
  half-wired. Branch lifetime < 2h; 702 LOC total diff, studio logic diff 593/1 — under cap.
- Planning checklist: entry points enumerated per class (scene/subject routing, partial sheets, absent dirs,
  soft-watercolor special case decoupled). No Performance & Cost section, defensible for a pure fs module
  with no API calls.

## Code quality signals

- Recurring issue classes: none post-push (0 comments). Local findings cluster around **supersede-never-delete
  file lifecycle robustness** — consistent with the repo's "never lose a generated render" core principle;
  the review gates enforced it three separate ways (provenance survives, collisions can't clobber, failures restore).
- New unrecorded pattern: destructive-then-write restore-on-failure (now captured).

## Process efficiency

- Automation opportunities: none beyond what ran — the finding classes need semantic review, not lint.
- Iteration: efficient (1 round, all fixes pre-push).
- CI: all passed.

## Knowledge updates

- `~/.claude/knowledge/adversarial-review.md` — new Tier 3 item: **multi-step file mutation — destructive
  first step needs restore-on-failure of every later step + failure-injection test** (source: #330).
- `~/.claude/knowledge/process-patterns.md` (Review Efficiency) — new entry: **a rate-limited CodeRabbit run
  is a skipped gate, not a passed one; the retry-once obligation caught a MAJOR** (source: #330).
- `post-mortem-metrics.json` — entry appended (471 PRs); dashboard regenerated.

## Recommendations

1. Keep the CodeRabbit retry-once rule non-negotiable; a throttled run is zero signal (it caught this PR's only MAJOR).
2. Restore per-step durations in the Step Timing table — statuses alone leave `stepTiming` unmeasurable.
3. When a module's contract is "supersede, never delete," the critic should explicitly failure-inject every
   multi-step mutation (now a checklist item).
4. The 3a/3b orchestrator split is a reusable scope move: when wiring has per-site collision risk, ship the
   pure engine + record the collision table in the spec rather than deferring everything or half-wiring.
