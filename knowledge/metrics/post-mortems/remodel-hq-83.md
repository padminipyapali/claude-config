# POST-MORTEM: remodel-hq PR #83 — feat(atelier): collapse inspo filters + redesign lightbox with comments

Branch: `feat/atelier-inspo-ux` → `main` | Author: padminipyapali | 31 minutes open
Size: +1411 -175 across 8 files, 6 commits
Merge commit: cd64e47

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` section in PR body).
- Adversarial: not tracked.
- Shift-left rate: n/a.

## STEP COMPLIANCE
- Step compliance: not tracked (PR body has no `Steps skipped:` line).

## STEP TIMING
- Not tracked (no `## Step Timing` section).
- User-supplied qualitative timing: 3 implementer rounds + 1 critic round before merge.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no `CHANGES_REQUESTED`; self-merge by author).
- Comments: 0 substantive (1 Vercel bot comment excluded).
- Categories: all zero — there were no GitHub review comments because review friction was absorbed pre-PR through implementer/critic rounds.
- Timeline: created → merged in 31 minutes (no peer review).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: moderate. The 5 fix commits before merge break down as:
  - Critic-caught: 1 (commit 2: "address critic round-2 — controlled room picker, stale-...").
  - User-iteration-caught (after preview deploy): 4 (hover/focus, glyph→SVG in lightbox, glyph→SVG sibling sweep in grid, optimistic vote/favorite + grid pill placement).
- Covered but missed:
  - **Unicode glyph icons in buttons** — react-patterns.md already says "Use SVG icons, not Unicode characters." The rule existed; the adversarial checklist had no grep-level enforcement. Now added as Tier 0 check #0.25.
  - **Optimistic UI for write paths** — react-patterns.md covers optimistic revert mechanics but does not enforce "default to optimistic" for new write-path hooks. Now added as a positive rule.
- Not covered (new categories):
  - **Surface-misidentification rework** — user said "lightbox looks bad" twice while pointing at the CARD GRID. No process artifact catches this. Added to process-patterns.md (Planning Discipline + Iteration Velocity).
  - **Mockup-coverage boundary documentation** — the mockup file covered only the lightbox, but feedback drifted to the grid; no plan section declared what the mockup did NOT cover. Added to Planning Discipline.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no post-merge follow-ups; #83 is HEAD of main as of 2026-05-15).
- Pre-merge catch rate by step:
  - 4a (simplify): 0 fixes
  - 4b (internal/critic): 1 fix (round-2 critic correctness/stale-state)
  - 4c (CodeRabbit): 0 fixes (not run / not tracked)
  - 4d (adversarial): 0 fixes
  - post-push: 0 fixes (the 4 "user-feedback" fixes happened on the branch BEFORE PR creation — they appear in the PR's commit list but not as post-push commits)
  - **Untracked "user-preview" rounds: 4** (not in the 4-step taxonomy; user observed the Vercel preview between local push iterations). This is the dominant friction vector for this PR.
- Pre-merge iteration count: **4** (1 critic + 3 user-feedback). High friction.
- Fix-up taxonomy: { a11y: 2 (SVG icon swaps), correctness: 2 (critic-fix + optimistic updates), style: 1 (hover/focus + pill placement) }.
- Legacy fix-up ratio: 83% (5 fix / 6 total commits) — inflated by absorbing user-iteration cycles as separate commits.

## PLANNING QUALITY
- Description: partial (Summary + Test plan + Notes — no Performance & Cost Impact section, which is OK here since no paid API was added).
- Scope: scope creep observed (grid-card concerns absorbed despite the mockup targeting only the lightbox).
- Branch lifetime: ~hours (created same day, merged 31min after PR open; implementation iterations happened on-branch before PR open).
- Planning checklist gaps: (a) no surface enumeration (lightbox vs card-grid), (b) no mockup-coverage-boundary declaration.

## CODE QUALITY SIGNALS
- Recurring issues: Unicode-glyph antipattern hit 3+ files (lightbox toolbar, grid vote pills, action row). Sibling-sweep was needed and happened across separate commits.
- New unrecorded patterns:
  - Optimistic-by-default for custom data hook write paths.
  - Plan-time surface enumeration table for UI redesigns.
  - Mockup-coverage-boundary declaration in plans referencing a mockup.

## PROCESS EFFICIENCY
- Automation opportunities:
  - Tier 0 grep for `>[★♥✕↑↓●...]<` in `.tsx` files (added).
  - Hook factory enforcement of optimistic-by-default for write paths (design-level, not lintable yet).
  - Pre-implementer disambiguation prompt: "which surface — card grid or lightbox?" when user feedback is ambiguous.
- Iteration: **high friction** (4 pre-merge rounds for a UI redesign).
- CI status: Vercel preview + Vercel Preview Comments both SUCCESS.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/process-patterns.md`:
  - Added "Plans for UI redesigns must enumerate every visible surface by name" under Planning Discipline.
  - Added "Mockup-driven UI work needs explicit 'what the mockup covers vs NOT' section" under Planning Discipline.
  - Added "User-perceived-latency feedback is a process smell" under Iteration Velocity.
  - Added "Surface-misidentification during iteration is an avoidable rework category" under Iteration Velocity.
- `~/.claude/knowledge/react-patterns.md`:
  - Strengthened the "Use SVG icons, not Unicode characters" line with PR #83 evidence and the two-part fix (swap + sibling sweep) plus Tier 0 grep recommendation.
  - Added "Default custom data hooks to optimistic writes; require explicit pessimistic opt-out" under State Management.
- `~/.claude/knowledge/adversarial-review.md`:
  - Added Tier 0 check 0.25: Unicode glyph icons in buttons.
- `~/.claude/knowledge/metrics/post-mortem-metrics.json`: appended entry for remodel-hq #83.
- `~/.claude/knowledge/metrics/dashboard.html`: regenerated with new METRICS_DATA.

## RECOMMENDATIONS (ranked)

1. **Add a "Surfaces touched" table to every UI-redesign plan** with columns: surface name, file path, mockup variant ref, before/after screenshot. Before dispatching the implementer on user feedback, the orchestrator must ask "which row in the surfaces table?" if the feedback is ambiguous. This single artifact would have prevented 2 of the 4 iteration rounds in PR #83.
2. **Promote optimistic-by-default to a hook-factory contract.** Audit `useAtelierData`, `useInspoFavorites`, `useInspoNotes`, and any other Atelier write-path hooks: they should perform optimistic updates by default with `{ pessimistic: true }` as an opt-out. Track as a follow-up task in the Atelier roadmap.
3. **Run the new Tier 0 Unicode-glyph grep** as part of step 4c on the next Atelier PR. Sweep `src/components/atelier/**/*.tsx` once now for residual glyphs (PR #83 fixed the known instances but a sweep validates).
4. **Add `## Local Review` and `## Step Timing` sections to the Atelier PR body template.** Both were absent from PR #83 — without them, post-mortems can't distinguish "didn't run review" from "ran but found nothing." Same gap the process-patterns evidence file already flags for other projects.
5. **When user feedback arrives between implementer rounds, capture a screenshot (Playwright or manual) in the feedback channel.** A screenshot would have caught the lightbox/grid surface confusion in round 1, not round 3.
