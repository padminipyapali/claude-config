# POST-MORTEM: baby-name-picker PR #199 — Add a runtime-switchable Nocturne theme behind a manual toggle.

Branch: `feat/nocturne-theme` → `main` | Author: padminipyapali | created 2026-06-17T04:46:30Z → merged 05:00:02Z (~13.5 min)
Size: +1814 / -409 across 47 files, 1 commit (oid 5e1cad5). Self-merged. CI green (Typecheck, lint & test, ~2 min).

## What shipped
A second app theme, **Nocturne** (Sabyasachi-inspired: oxblood velvet surfaces, antique-gold accents, emerald origin pills, ivory serif), runtime-switchable behind a manual toggle in the Favorites overflow menu. The app previously had a single static `colors` palette imported into every stylesheet; this PR made it runtime-switchable:
- Dual palettes in `src/theme.ts` (`lightColors` = today's exact values + `nocturneColors`, identical key set); widened `Palette` type; theme-aware `accentForGenderIn`/`genderDotColorIn`/`genderGlowColorIn`; per-theme shadow sets (gold glow on dark); `normalizeThemeName` for safe rehydration.
- `useTheme()` React-context hook + `ThemeProvider` at app root.
- `themePreference` persisted via the existing `app_state` pattern (mirrors `genderPreference`: defaults light, hydrates on launch, invalid→light, optimistic `setTheme`).
- 28 consumers migrated from static `StyleSheet.create` to `makeStyles(colors)` + `useMemo`. Two intentional static holdouts (`ErrorBoundary` crash fallback; a test-only `favoriteIconProps` helper).
- Heavy mockup ornamentation (damask, gold-foil text, R crest, Roman numerals, double frames) deliberately deferred to a polish follow-up.

## LOCAL REVIEW (pre-push)
- 4a simplify: PASS — palettes share one key set; makeStyles take colors as a param; accent logic centralized.
- 4b CodeRabbit: PASS — clean on this diff (only pre-existing doc nits in merged mockup READMEs, outside this PR).
- 4c adversarial: PASS (fresh-context critic + sub-agent audit). Zero code defects. Real verification, not "looks fine":
  - Light theme **byte-for-byte unchanged**: 28/28 palette keys mechanically diffed, zero drift; NameCard migration spot-checked 24-for-24.
  - **No stranded static color sites**: sub-agent audited every live color across 25 files; all hook-bound; 2 holdouts defensible.
  - Persistence correct across all 5 branches; accent/provider/white/shadows all PASS.
  - Static WCAG contrast audit stood in for an un-runnable simulator.
- CodeRabbit findings: 0. Adversarial findings: 0.

## STEP COMPLIANCE
Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d, 5 (9/9). Steps skipped: none.
Compliance rate: 100%. Skip assessment: neutral — visual/simulator verification was *deferred* (not a process skip): native CNG build too slow/SIGKILL-prone in this env; compensated with the light-unchanged proof + WCAG audit + per-theme render test, aesthetic eyeball deferred to next beta build.

## STEP TIMING
Not tracked (no `## Step Timing` section in PR body). Open-to-merge wall clock ~13.5 min.

## REVIEW FRICTION (post-push)
Review rounds: 1 (0 CHANGES_REQUESTED). Comments: 0 inline, 0 general. Categories: all zero.
Timeline: created → merge ~13.5 min, no GitHub review (solo dev; gate was the local fresh-context critic).

## ADVERSARIAL REVIEW EFFECTIVENESS
adversarialCatchRate: **unmeasured** — 0 findings locally, 0 escaped post-merge, no denominator. Confirmed from evidence (PR body, 0 commits beyond the feature commit, 0 follow-up fix PRs). The critic did substantive verification (palette diff, stranded-color audit, WCAG, persistence branches), it simply found nothing to fix — so there is no catch rate to compute. Not a fabricated 0.0; recorded as the string "unmeasured".
Covered but missed: none. Not covered (new categories): none.

## FIX-UP METRICS
- Post-merge fix rate: 0.0% — #199 is the latest merged PR; no follow-up fix PRs reference it or its files.
- Pre-merge catch rate by step: 4a 0 | 4b 0 | 4c 0 | 4d 0 | post-push 0 (no fix commits — single clean feature commit).
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all zero.
- Legacy fix-up ratio: 0.0% (0 fix / 1 total commit).

## PLANNING QUALITY
Complete. PR body has Summary, Local Review, Test plan, Known follow-ups. Clean design-to-implementation pipeline: Sabyasachi mockup exploration (PR #198 mockups) → "Nocturne" naming → AskUserQuestion on accent treatment + toggle home → phased build with ornamentation explicitly deferred. Scope clean (single concept: palette/token theme + toggle). Branch lifetime < 1 hour.

## CODE QUALITY SIGNALS
Recurring issues: none. New unrecorded patterns: the theme-retrofit LOC-cap exception and the RN visual-verification deferral pattern (see Knowledge Updates).

## PROCESS EFFICIENCY
Automation opportunities: the light-palette regression test is currently a shape/value check; critic's nit suggests a full `toEqual` snapshot tripwire (low effort, durable). WCAG contrast could be automated (cf. existing process-patterns line "CSS theme PRs need automated WCAG contrast checks").
Iteration: efficient (1 round, 0 escapes). CI: all passed.

## RECOMMENDATIONS
1. Promote the light-palette regression test to a full `toEqual` snapshot tripwire so any future palette key drift fails loudly (cheap, the critic already flagged it).
2. When the next beta build is cut, eyeball Nocturne last-name legibility (faint tier by design) — the one item the static net could not verify.
3. Consider an automated WCAG contrast assertion in the test suite for both palettes, retiring the manual audit (aligns with the standing process-patterns rule).

## KNOWLEDGE UPDATES
- `process-patterns.md` (PR Sizing): added the theme-retrofit / token-routing variant of the >600-LOC atomic-refactor exception.
- `process-patterns.md` (RN visual-verification entry, line ~243): extended with #199 as the 4th data point — a theme/color PR where the static net (light-unchanged proof + WCAG + per-theme render test) legitimately replaced the un-runnable simulator gate, deferring aesthetics to the beta build.
