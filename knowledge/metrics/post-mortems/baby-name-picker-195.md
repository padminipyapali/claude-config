# POST-MORTEM: baby-name-picker PR #195 — Rebrand the app from Sona to Ria.

Branch: `chore/rebrand-ria` → `main` | Author: padminipyapali | created 2026-06-16T20:18:18Z, merged 20:20:24Z (~2 min on GitHub; local work preceded push)
Size: +49 -49 across 21 files, 2 commits
Team: full 3-role orchestrator team (`dev-ria-rebrand`) — implementer + fresh-context critic + orchestrator.

## What shipped
Renamed the app **Sona → Ria** across every live brand surface (app + Next.js `/web` landing + 5 regenerated icon assets + privacy policy) and moved product identity to **Keya LLC** (iOS bundle id / Android package `com.keya.ria`, URL scheme `ria`, support email `support@keya.dev`). No logic/behavior change — brand, copy, identity config, and icon art only. App Store listing name set to "Ria — Baby Names".

## LOCAL REVIEW (pre-push)
- **4a simplify: PASS.** Rename centralized through `web/lib/brand.ts` (`BRAND_NAME`); web surfaces derive their name from one source. `RiaIcon` keeps the exact geometry of `SonaIcon` (git saw an 88%-similar rename). No second source of truth.
- **4b CodeRabbit CLI: ran, exit 0.** Its one "major" finding was a **pre-existing** contradiction between the privacy policy ("collects nothing") and `app-store-listing.md`'s future "anonymous usage funnel" note — correctly scoped OUT to a follow-up (needs a v1-analytics product decision; the shipping app has no network SDKs, so "None" is accurate to the code today). Zero actionable findings against this diff.
- **4c adversarial review: PASS** (fresh-context critic). Verified: catalog "Sona" survives in seed data + its test; all 5 regenerated icons checked for dimensions/alpha; identity strings correct; no live brand "Sona" left on an active surface. Its one recommended fix was committed: web footer `© Ria` → `© Keya LLC`.
- **Shift-left: 100%** — the single actionable issue (footer copyright entity) was caught locally and fixed before push; 0 escaped post-merge.

## STEP COMPLIANCE
Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d (CI), 5 — all tracked steps ran. Compliance rate: 100%. Steps skipped: none. Skip assessment: good (no skips; CI green pre-merge). Notably this PR ran 4b CodeRabbit — continuing the corrected behavior, not the long baby-name-picker 4b-skip streak.

## STEP TIMING
Not tracked — no `## Step Timing` section in the PR body.

## REVIEW FRICTION (post-push)
Review rounds: 1 (0 GitHub CHANGES_REQUESTED — all review was local). Comments: 0 inline, 0 general (GitHub side). Categories: documentation 1 (footer copyright entity), all others 0. Timeline: created → merge ~2 min on GitHub; no post-push review iterations.

## ADVERSARIAL REVIEW EFFECTIVENESS
Pre-push catch potential: 100% (1/1 actionable issue caught locally). Covered but missed: none. Not covered (new categories): brand-rename-vs-domain-data safety (now captured) and the review-marker-refresh-after-post-PASS-critic-fix process gap (now captured). The CodeRabbit "major" was a pre-existing doc contradiction, not introduced by this PR — correctly deferred.

## FIX-UP METRICS
- Post-merge fix rate: 0% (0 post-merge fix commits — ideal).
- Pre-merge catch rate by step: 4a 0 | 4b 0 | 4c (CodeRabbit) 0 | 4d (adversarial) 1 | post-push 0.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: documentation 1 (footer copyright `© Ria` → `© Keya LLC`); all others 0.
- Legacy fix-up ratio: 50% (1 fix / 2 commits) — inflated by the small commit count; the lone "fix" is a trivial 1-line copyright entity correction, not a quality escape.

## PLANNING QUALITY
Description: complete — Summary, Designs (rendered icon + per-asset regeneration notes), Local Review (4a/4b/4c with results), Test plan (tsc/lint/jest/web build/sips icon checks/Playwright/brand grep), and Known follow-ups. Scope: clean — single concern (rebrand + identity), 98 LOC, well under the 600-LOC cap. Branch lifetime: minutes. Explicit keep/change boundaries documented (catalog "Sona" preserved; Expo `owner`/`projectId` intentionally deferred; dated historical artifacts intentionally not rewritten).

## CODE QUALITY SIGNALS
Recurring issues: none. New patterns captured (3): (1) brand-rename safety when the brand string collides with domain data — carve out data surfaces in the brief + require paired grep-proof; (2) rasterize app icons from an SVG logomark via headless Chromium when no native rasterizer is installed (match per-asset background, flatten iOS icon to no-alpha, verify with `sips`); (3) refresh the adversarial-review marker for the NEW head when a critic commits a post-PASS fix.

## PROCESS EFFICIENCY
Automation opportunities: have the critic write/refresh the review marker as the last step of any fix it commits (prevents the push-hook block hit here). Iteration: efficient (1 local round, 0 post-push). CI status: all passed ("Typecheck, lint & test: SUCCESS") — the previously-flagged CI gap is now closed and the gate was green before merge.

## NOTABLE PROCESS EVENT
The critic committed its own one-line footer-copyright fix AFTER returning PASS, so HEAD advanced past the reviewed commit and the push hook (`require-adversarial-review.sh`, marker keyed to `md5(worktree-path)`=HEAD) correctly blocked the push. Resolution: the orchestrator self-eyeballed the trivial 1-line delta (Critic Round Tiers "self-eyeball" tier) and re-wrote the marker for the new HEAD. Captured as a reusable process learning.

## KNOWLEDGE UPDATES
- `~/.claude/knowledge/process-patterns.md` — added 3 entries: brand-rename-vs-domain-data safety (Data Quality / Audits), icon-from-SVG via headless Chromium (Automation Opportunities), review-marker-refresh-after-post-PASS-critic-fix (Process Rule Enforcement).
- `~/.claude/knowledge/metrics/post-mortem-metrics.json` — appended PR #195 entry (375 → 376).
- `~/.claude/knowledge/metrics/dashboard.html` — re-embedded METRICS_DATA (376 PRs).

## RECOMMENDATIONS
1. **Automate the review-marker refresh.** Make the critic re-write the marker keyed to the new HEAD as the final step of any fix it commits, so post-PASS critic fixes never strand the marker and block the push.
2. **Resolve follow-up #1** (privacy "Data: None" vs. analytics-funnel note) once the v1 analytics decision is made — the only open product contradiction CodeRabbit surfaced.
3. **Keep recording 4b results in the PR body** — #195 continues the corrected 4b-run behavior; this is discipline, not enforcement, so the standing 4b-skip pre-push hook remains the durable fix.
