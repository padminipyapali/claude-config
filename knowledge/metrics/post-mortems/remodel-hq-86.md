# POST-MORTEM: remodel-hq PR #86 — feat(atelier): pin photos + /atelier/review page + with-notes filter

Branch: `feat/atelier-pin` → `main` | Author: padminipyapali | ~13 min PR open
Size: +1438 -42 across 16 files, 3 commits (squash-merged)
Merge commit: 786faab6ee67f1c24a2fc1bb5a595eaab264a7e1

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (no `## Local Review` section in PR body — four-PR streak: #83, #84, #85, #86).
- Adversarial: not tracked.
- Critic loop (inferred from commit 3 `fix(atelier): address critic findings on review surface + togglePin polish`):
  - **2 should-fix findings** addressed (per commit body):
    1. `AtelierReview` must wire `onNoteAdded` / `onNoteDeleted` so the library's `noteCounts` cache stays in sync when notes are added/deleted from `/atelier/review`. Without this, the "With notes" filter chip went stale after every mutation on the review page.
    2. `AtelierReview` must render a per-note delete trash button on each note row, mirroring the lightbox pattern.
  - **3 nits** addressed:
    1. `togglePin` callback captures snapshot via fresh `imagesRef`, dropping `images` from deps to stop identity churn (same pattern as PR #85).
    2. `inspoActionIcons`: deduped a copy-pasted block comment in `PinIcon`.
    3. `useAtelierData`: dropped a pointless `.order(created_at)` on the aggregate note-count fetch.
  - Tests added in commit 3: lock the `bumpNoteCount` contract (notifier MUST NOT fire when `addNote` rejects); fix mock for the aggregate-notes thenable.
- Shift-left rate: 100% qualitatively — all friction absorbed pre-PR via the critic; zero user-iteration rounds, zero post-push review comments.

## STEP COMPLIANCE
- Step compliance: not tracked. Per user-supplied context: a **mid-flight rebase** occurred because PR #85 merged between the implementer and critic rounds. The rebase is the notable operational event of this PR.

## STEP TIMING
- Not tracked in PR body. PR-open-to-merge: 13 minutes. The mid-flight rebase added unmeasured overhead on the branch.

## REVIEW FRICTION (post-push)
- Review rounds: 1 (no `CHANGES_REQUESTED`; self-merge by author).
- Comments: 0 substantive (1 Vercel bot comment excluded).
- Categories: all zero.
- Timeline: created → merged in 13 minutes.

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch potential: high for 4 of 5 critic findings.
  1. **Cache-sync on cross-surface mutations.** When two surfaces (lightbox AND `/atelier/review`) can mutate notes, both must notify the shared `noteCounts` cache. Caller-side coverage gap — covered by "new-union-member completeness" Tier in adversarial-review.md if you treat the surfaces as cases of a switch.
  2. **Sibling-feature parity sweep.** Per-note delete trash existed in the lightbox (added in #85). When a sibling surface (`/atelier/review`) lists notes, the same affordance must be present. This is the **sibling-sweep convention** (Tier 0 universal manual) applied across UI surfaces, not just bug-fix patterns.
  3. **Callback identity churn from mutating list in deps.** Already documented; repeated miss across #85 and #86. **Covered but missed twice in a row.** Strong signal this should be a Tier 0 grep: `useCallback\(.*, \[.*\b(images|items|list)\b.*\]\)` — flag for review.
  4. **Dead `.order(created_at)` on an aggregate count query.** Covered by `/simplify` (4a) — step apparently not run pre-push (same gap as #85).
  5. **Duplicated block comment in PinIcon.** Covered by `/simplify`.
- Covered but missed: 3 of 5 (callback-identity-churn AGAIN, two `/simplify`-eligible nits).
- Not covered (new categories):
  - **Cross-surface cache notifier coverage.** When a derived cache is mutated on Surface A, every other surface that can mutate the same underlying entity must wire the same notifier. Add to adversarial-review.md as a Tier 1 sweep when adding a new surface that lists items also rendered elsewhere.

## FIX-UP METRICS
- Post-merge fix rate: 0% (no post-merge follow-ups; #86 is HEAD of feature line; #87 is a separate concern).
- Pre-merge catch rate by step:
  - 4a (simplify): 0 fixes (would have caught 2 nits)
  - 4b (internal/critic): **5** (all critic findings landed in commit 3)
  - 4c (CodeRabbit): 0 (not run / not tracked)
  - 4d (adversarial): 0
  - post-push: 0
- Pre-merge iteration count: **1** critic round + **1 mid-flight rebase** (operational, not a fix iteration). Healthy on the review axis; an unmeasured operational cost on the merge-coordination axis.
- Fix-up taxonomy: { correctness: 2 (cache-sync notifier + identity-churn), test-quality: 1 (notifier-NOT-fired contract), style: 2 (dedup comment + drop pointless order) }.
- Legacy fix-up ratio: 33% (1 fix / 3 total commits).

## REBASE-MID-FLIGHT EVENT
- **What happened:** PR #85 merged into main while PR #86's branch was between implementer and critic rounds. The implementer's branch had to be rebased onto the new main before the critic could review against an accurate diff.
- **Cost:** Unmeasured (no `## Step Timing` section). Per user-supplied context, the rebase required manual conflict resolution because both PRs touched `useInspoLibrary` / `useInspoNotes` / `inspoActionIcons`.
- **Trigger:** Two near-back-to-back PRs (#85 merged at 05:01:33Z, #86 created at 05:23:26Z — 22 minutes apart) on overlapping files in the same hook surface.
- **Mitigation options for future runs:**
  1. **Stacked branches via `gh pr create --update-base`.** Make #86 explicitly stacked on #85; #86 rebases automatically when #85 lands. Best for known-overlapping work where the second feature depends on or extends the first.
  2. **Sequential merges with a "no new feature work on shared surface until prior PR merges" rule.** Simpler operationally; the cost is wall-clock blocked time.
  3. **Detect overlap up-front:** before starting a second feature on the same hook, run `git log main..HEAD -- <shared-files>` and `git log HEAD..origin/main -- <shared-files>` to surface in-flight conflicts.
- **Recommendation:** Prefer **option 1 (stacked branches)** when the second PR explicitly builds on the first (which was the case here — #86's "With notes" filter relies on note infrastructure touched by #85's note-delete). Use option 2 only when the features are independent and either order is acceptable. Option 3 should be added to the orchestrator's pre-implementer brief as a 30-second smoke.

## PLANNING QUALITY
- Description: complete (Summary + Migration callout + Notes + Test plan with 6 scenarios).
- **Scope: bundled — three distinct features in one branch:** (a) pin + `/atelier/review` page, (b) "With notes" filter chip + note-count cache, (c) optimistic toggle for pin. Each feature added a separate `feat()` commit before the final critic-fix commit.
- Branch lifetime: < 1 day.
- Planning checklist coverage:
  - Entry points enumerated: yes (6 test-plan scenarios).
  - Migration risk: explicit "⚠ Migration required" callout — good.
  - Performance/cost: implicit (third query added to `useInspoLibrary` called out in Notes).
  - **Surfaces-touched table: NOT present and arguably needed here.** This PR touched 16 files across 6 distinct surfaces: Inspiration grid filter row, Inspiration lightbox (pin button), Inspiration lightbox (note notifier wiring), AtelierReview page (new), Review sidebar entry, useInspoLibrary cache. The #83 recommendation was specifically "use the table when >2 surfaces" — this PR exceeded that threshold but did not adopt the formal table. The critic-fix commit's items #1 and #2 (cross-surface cache-sync and sibling-feature parity sweep) are precisely the failure modes the table is designed to surface. **Strong signal: the heuristic was right, but the threshold trigger was not enforced.**

## CODE QUALITY SIGNALS
- Recurring issues:
  - **Callback identity churn from including mutating list in deps** — third occurrence in three PRs (#83, #85, #86). Promote to Tier 0 grep now.
  - **Cross-surface cache notifier omission** — first occurrence; flag as new category.
- New unrecorded patterns:
  - **When adding a new UI surface that lists items also mutated elsewhere, audit every existing mutation site for cache-notifier coverage.**
  - **Stacked-PR coordination protocol** for sequential features on overlapping files.

## PROCESS EFFICIENCY
- Automation opportunities:
  - Tier 0 grep: `useCallback\([^,]*, \[[^\]]*\bimages\b[^\]]*\])` and analogous for `notes` / `items` — likely identity-churn smells.
  - Tier 0 grep: `\.order\(` followed immediately by `count` / `length` access — pointless ORDER BY.
  - Pre-implementer step: when two features will touch the same hook, declare them as stacked branches up-front.
  - Re-run `/simplify` (step 4a) before push — would have caught 2 nits.
- Iteration: **efficient on the review axis** (1 critic round, 0 user rounds), **inefficient on the merge-coordination axis** (1 unmeasured rebase).
- CI status: Vercel preview SUCCESS.

## POST-#83 / #84 / #85 PROCESS-IMPROVEMENT ASSESSMENT

**Surfaces-touched table.** This is the PR where the table would have paid off. 16 files / 6 surfaces; the critic's top two findings were both cross-surface coordination misses. The "use when >2 surfaces" heuristic from #84 was correct but not actively enforced. **Recommendation: change the heuristic from advisory to mandatory — when a PR's plan implies a surface count >2 (or a file count >8), the plan MUST include the surfaces-touched table before implementation begins. The orchestrator should refuse to dispatch the implementer otherwise.**

**Optimistic-by-default for write paths.** `togglePin` was implemented optimistically on the first pass. Note-count `bumpNoteCount` / `dropNoteCount` were implemented optimistically. **Optimistic-by-default is now de-facto house style across 6 distinct write-path hooks (vote, favorite, note-add, note-delete, image-delete, pin, updateImageCategory).** This is the signal-strength threshold to promote it from a knowledge pattern to a default expectation in adversarial-review.md.

**Three new react-patterns from #85 acceptance test.** #85's "transient per-row error reset" and "Cancel-focus default" did not regress in #86 — but #86 was a different surface, so this is weak evidence. Re-test in #87.

## ORCHESTRATOR → IMPLEMENTER → CRITIC LOOP EFFECTIVENESS
- Fresh-context critic caught 5 findings (2 should-fix + 3 nits) on a 16-file PR.
- The 2 should-fix findings were both **cross-surface coordination misses** — exactly the failure mode the surfaces-touched table is designed to surface up-front. The critic absorbed iteration debt that planning discipline could have prevented entirely.
- The 3 nits were `/simplify`-eligible — would have been caught by step 4a if run.
- All 5 fixed in a single commit + test additions; no third round needed.
- Zero user-iteration rounds.

## TEST COUNT GROWTH ASSESSMENT
- Trajectory: 56 (#85) → 74 (#86) → 86 (current #87 WIP).
- Per-PR delta: +18 tests in #86 (+24% suite growth). Most concentrated in `AtelierInspiration.test.tsx`, `useAtelierData.optimistic.test.tsx`, `AtelierInspirationLightbox.test.tsx`.
- Current vitest run time: not measured in PR body (timing gap again).
- **Splitting threshold guidance:** the canonical signals for per-feature vitest config + parallel runs are (a) suite wall-clock > 60s on local hardware, (b) flake rate > 1% across runs, or (c) >200 tests with semantic clustering by feature. At 86 tests with linear growth of ~15-20 per PR, the suite will cross 200 in ~6-8 PRs (≈ 2-3 weeks at current cadence). **Recommendation: defer the split until 150-180 tests** unless local wall-clock crosses 30s before then. At the current rate the split decision should be revisited at PR #92-#94. When splitting, the natural axes are `atelier/inspiration/*`, `atelier/studio/*`, `atelier/review/*`, and shared `hooks/*` — already aligned with directory structure, so the split is cheap.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/adversarial-review.md`:
  - Strengthened section 1.5 (Optimistic UI Revert Safety) — optimistic-by-default is now the **default expectation** for any new write-path hook in Atelier. Pessimistic implementations require a one-line justification in the PR body. <!-- Source: post-mortems, remodel-hq #83/#85/#86 -->
  - Added Tier 1 sweep: **Cross-surface cache notifier coverage** — when adding a UI surface that mutates items also rendered elsewhere, every existing mutation site must wire the same notifier. <!-- Source: post-mortem, remodel-hq #86 -->
- `~/.claude/knowledge/react-patterns.md`:
  - Strengthened "snapshot via functional setter / ref" entry with PR #86 as third repeat occurrence — promoted from pattern to Tier 0 grep candidate. <!-- Source: post-mortems, remodel-hq #83/#85/#86 -->
- `~/.claude/knowledge/process-patterns.md`:
  - **Strengthened surfaces-touched-table entry from advisory to mandatory** when plan implies >2 surfaces or >8 files. Orchestrator should refuse to dispatch implementer without the table. <!-- Source: post-mortem, remodel-hq #86 -->
  - Added "Stacked-PR coordination protocol" — when two features will touch the same hook/files, declare them as stacked branches via `gh pr create --update-base` up-front. <!-- Source: post-mortem, remodel-hq #86 -->
  - Added "Mid-flight rebase detection" — at orchestrator dispatch time, run `git log HEAD..origin/main -- <shared-files>` and `git log main..HEAD -- <shared-files>` to surface in-flight conflicts on overlapping files. <!-- Source: post-mortem, remodel-hq #86 -->
- `~/.claude/knowledge/metrics/post-mortem-metrics.json`: appended entry.
- `~/.claude/knowledge/metrics/dashboard.html`: METRICS_DATA refresh queued.

## RECOMMENDATIONS (ranked)

1. **Promote optimistic-by-default from knowledge pattern to default expectation in adversarial-review.md.** Three consecutive PRs (#83, #85, #86) plus prior PR #83 evidence: vote, favorite, note-add, note-delete, image-delete, pin, updateImageCategory — seven distinct write-path hooks, all optimistic. The pattern is no longer aspirational; it is house style. Make the adversarial-review.md entry an explicit Tier 1 check.
2. **Promote the surfaces-touched table from advisory to mandatory at >2 surfaces or >8 files.** PR #86 is the prototypical case the table was designed to prevent — the critic's top two findings (cross-surface cache-sync and sibling-feature parity) are exactly the failure modes the table surfaces up-front. Orchestrator should refuse to dispatch the implementer for any plan that implies these thresholds without the table.
3. **Adopt stacked branches via `gh pr create --update-base` when two features touch the same hook.** PR #86 had to absorb a mid-flight rebase against PR #85's merge because the two PRs were created in series on overlapping files. The stacked-branch pattern lets the second PR auto-rebase when the first lands. The alternative (sequential merges blocking second feature work) is simpler but costs wall-clock; pick stacked branches when the second feature explicitly extends the first.
4. **Promote callback-identity-churn (`useCallback([..., images])`) to a Tier 0 grep.** Three repeat occurrences across #83/#85/#86. Greppable, recurring, fixable in one line. Exactly the convention-complexity-budget pattern that should move from manual to automated.
5. **Add `## Local Review` and `## Step Timing` to the Atelier PR body template.** Now a **four-PR streak** (#83, #84, #85, #86) of missing sections. This is the single highest-leverage process gap remaining — without these, every post-mortem hand-waves "where did the time go" and "did step 4a run." Templatize now.
6. **Defer per-feature vitest split until ~150-180 tests** (≈ PR #92-#94 at current growth). Earlier than that is premature optimization; the directory structure is already aligned with the natural split axes (`inspiration/`, `studio/`, `review/`, `hooks/`), so the future split is cheap. Re-evaluate when local wall-clock crosses 30s.
