# POST-MORTEM: remodel-hq PR #84 — feat(atelier): arrow-key navigation in inspiration lightbox

Branch: `feat/atelier-lightbox-nav` → `main` | Author: padminipyapali | ~7 min PR open
Size: +302 -5 across 4 files, 2 commits
Merge commit: c2784355fc9dee80f1ce8a1def117e9c1da5f5b4

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` section in PR body — same gap as #83).
- Adversarial: not tracked.
- Critic loop (per user-supplied context): 1 critic round; 2 should-fix findings, both addressed in commit 2 (`fix(atelier): always consume arrow keys in lightbox; hide chevrons below md`).
- Shift-left rate: 100% qualitatively — all friction absorbed pre-PR via the critic; zero user-iteration rounds, zero post-push review comments.

## STEP COMPLIANCE
- Step compliance: not tracked (PR body has no `Steps skipped:` line). Per user context: orchestrator → implementer → critic loop ran with a fresh-context critic.

## STEP TIMING
- Not tracked in PR body. PR-open-to-merge: 7 minutes; on-branch work happened earlier in the session.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no `CHANGES_REQUESTED`; self-merge by author).
- Comments: 0 substantive (1 Vercel bot comment excluded).
- Categories: all zero.
- Timeline: created → merged in 7 minutes.

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: high. Both critic findings map to existing checklist/knowledge entries:
  1. **`preventDefault` must fire unconditionally inside a modal-scoped keyboard handler**, even when `canNavigate` is false. Otherwise ArrowLeft/Right bubble to the document and scroll the page when the filtered list is a single item or the current image was filtered out. This is a correctness/UX edge case adjacent to react-patterns.md line 95 (global keyboard shortcut suppression) but not previously called out as "consume even when no-op."
  2. **Chevron buttons must hide below `md:` breakpoint** to avoid overlapping the lightbox image on narrow viewports; touch users fall back to swipe/keyboard. This is a discoverability-vs-occlusion tradeoff for hover-only desktop affordances — adjacent to react-patterns.md line 84 (hover-only affordances need `:focus-within`/`@media (hover: none)`) but not previously called out for chevron overlays specifically.
- Covered but missed: neither. Both findings sit in **gaps** the checklist did not cover with grep-level enforcement.
- Not covered (new categories):
  - **Modal-scoped keyboard handlers: consume unconditionally.** Added to react-patterns.md.
  - **Desktop-only chevron overlays must hide below `md:`.** Added to react-patterns.md.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no post-merge follow-ups; #84 is HEAD of main).
- Pre-merge catch rate by step:
  - 4a (simplify): 0
  - 4b (internal/critic): **2** (both critic findings landed in commit 2)
  - 4c (CodeRabbit): 0 (not run)
  - 4d (adversarial): 0
  - post-push: 0
- Pre-merge iteration count: **1** (one critic round). Healthy.
- Fix-up taxonomy: { correctness: 1 (unconditional preventDefault + test), style: 1 (responsive chevron hiding) }.
- Legacy fix-up ratio: 50% (1 fix / 2 total commits) — both commits substantive; the "fix" commit is a critic-driven hardening pass, not user-iteration debt.

## PLANNING QUALITY
- Description: complete (Summary + Notes + Test plan with 7 explicit scenarios including the single-item edge case the critic flagged).
- Scope: clean — single feature, scoped to the lightbox + parent owner, explicitly punted on legacy `/dashboard` lightbox per project direction.
- Branch lifetime: < 1 day.
- Planning checklist coverage:
  - Entry points enumerated: yes (filter applied / single item / input focus / select focus / ESC / below-md / rapid-press all in test plan).
  - Performance/cost: implicit (per-image-id state generation counter + in-flight Set callout in Notes).
  - **Surfaces-touched table (post-#83 improvement): not present as a formal table, but the Notes section explicitly named the two surfaces (parent owns listener / lightbox is dumb) and the out-of-scope surface (legacy `/dashboard` lightbox). Lightweight version of the #83 recommendation; achieved the same disambiguation effect for a smaller PR.**

## CODE QUALITY SIGNALS
- Recurring issues: none.
- New unrecorded patterns:
  - **Modal-keyboard-handler contract**: parent-owns-listener / child-renders-affordance / unconditional preventDefault / input-guard for inputs+textarea+select+contenteditable. Adding to react-patterns.md.
  - **Desktop-only chevron overlay**: `hidden md:flex` for hover-affordance overlays that would occlude content on narrow viewports.

## PROCESS EFFICIENCY
- Automation opportunities:
  - Tier 4 (UI conventions) check: keyboard handlers inside a portal/modal must call `preventDefault()` outside any early-return guard.
  - Tier 4 (responsive): `position: absolute` chevron/handle buttons over images should have a breakpoint gate.
- Iteration: **efficient** (1 critic round, 0 user rounds). Sharpest contrast to PR #83 (4 pre-merge rounds).
- CI status: Vercel preview SUCCESS; Vercel Preview Comments SUCCESS.

## POST-#83 PROCESS-IMPROVEMENT ASSESSMENT
The two #83 recommendations this PR could exercise:

1. **Surfaces-touched table.** Not implemented as a formal table, but the PR description's Notes section did the equivalent: explicitly named the two affected surfaces (`AtelierInspiration` keyboard listener, `AtelierInspirationLightbox` chevrons) AND the deliberately-untouched legacy surface (`InspirationLightbox.tsx` in `/dashboard`). Scope creep risk: zero. The lightweight version was sufficient because the PR was small (4 files) and single-surface. **Recommendation: keep the table format as a "use when >2 surfaces" threshold; for small PRs, a Notes paragraph is enough.**

2. **Optimistic-by-default for write paths.** Not applicable — this PR added no write paths. However, the PR's reliance on `useInspoNotes`/`useInspoVotes`/`useInspoFavorites` with per-image-id generation counters (called out in Notes) suggests the optimistic-default audit from #83 has not yet been done. Track as outstanding follow-up.

**Friction reduction this round: dramatic.** PR #83: 4 pre-merge rounds, 6 commits, scope creep into grid. PR #84: 1 critic round, 2 commits, single surface. The biggest delta is feature scope (302 LOC vs 1411 LOC), not pure process improvement — but the planning-discipline carryover (explicit surface enumeration in Notes, explicit out-of-scope callout) did its job.

## ORCHESTRATOR → IMPLEMENTER → CRITIC LOOP EFFECTIVENESS
- Fresh-context critic caught 2 should-fix findings that were not in the checklist (preventDefault placement, responsive chevron hiding). **This is the empirical case for fresh-context review**: the critic saw the diff without the implementer's "I just built this and it works on my screen" bias and flagged a single-item edge case the test plan didn't yet cover.
- Both findings were under 5 lines each → fixed immediately per CLAUDE.md "Fix under-5-line issues now."
- Implementer added a new test (`asserts preventDefault fires on ArrowRight even when the filtered list is a single item`) in the same fix commit — closes the loop without requiring a third round.
- Zero user-iteration rounds confirms the critic absorbed the iteration that would otherwise have shown up as "feels broken when filtered to one image."

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/react-patterns.md`:
  - Added: "Modal-scoped keyboard handlers must call `preventDefault()` before any early-return guard." with PR #84 source.
  - Added: "Hover-affordance overlays on images (chevrons, handles) need a breakpoint gate (e.g., `hidden md:flex`)." with PR #84 source.
  - Added: "Modal arrow-key navigation pattern" (parent owns listener / child renders affordance / unconditional preventDefault / input-guard for INPUT/TEXTAREA/SELECT/contenteditable).
- `~/.claude/knowledge/process-patterns.md`:
  - Strengthened the existing "surfaces table" entry with a "for small PRs (< 5 files / single surface) a Notes paragraph is sufficient" qualifier, source PR #84.
- `~/.claude/knowledge/metrics/post-mortem-metrics.json`: appended entry for remodel-hq #84.
- `~/.claude/knowledge/metrics/dashboard.html`: regenerated with new METRICS_DATA.

## RECOMMENDATIONS (ranked)

1. **Promote the modal-arrow-key pattern to a reusable hook.** `useModalArrowKeys({ onPrev, onNext, enabled })` would (a) bake in the input-guard, (b) bake in the unconditional preventDefault, (c) make the pattern greppable. Each new Atelier modal that wants arrow nav can adopt it without re-deriving the edge cases. Track in Atelier roadmap.
2. **Add `## Local Review` and `## Step Timing` to the Atelier PR body template.** Still missing as of #84 (same gap flagged in #83). Without these sections, post-mortems can't distinguish "skipped review" from "ran review, zero findings" and can't measure where time was spent. Two-PR streak of the same gap → templatize now.
3. **Audit `useInspoNotes` / `useInspoVotes` / `useInspoFavorites` for optimistic-default compliance.** PR #84 confirms these hooks are now actively keyed by per-image-id; this is the right moment to do the #83-recommended sweep before more callers depend on the current pessimistic-default shape.
4. **Sweep other Atelier modals for arrow-key navigation parity.** The Studio result viewer and any future drawer/preview modals should adopt the same pattern (or the new hook from rec #1). Catalogue first to size the work.
5. **Keep using fresh-context critics for UI-edge-case PRs.** Two findings on a 4-file PR, both legitimate, both under-5-line fixes — this is exactly the ROI band where fresh-context review pays off.
