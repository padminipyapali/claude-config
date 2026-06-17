# POST-MORTEM: plush-press PR #36 — Add a Browse file picker to the Scene studio source-photo field.

Branch: feat/source-photo-picker → main | Author: padminipyapali | self-merged ~2 min after creation
Size: +370 -7 across 4 files, 1 commit

## Summary
Replaces the Scene studio's hand-typed "Source photo" repo-path field with a Browse… file picker. A browser cannot read a chosen file's absolute disk path, so picking uploads the image into the current book's `backdrops/sources/` (a committed book asset, like the existing house source) and fills the field with the repo-relative path — which drives the existing image-to-image (scene-plate-photo) switch. New `POST /api/upload-source`: multipart, slug-gated + existence-checked book (404), image-extension allowlist (png/jpg/jpeg/webp/gif/heic/heif), 25 MB cap, filename reduced to a safe basename (strips all directory parts → no traversal), collision appends `-1/-2`, atomicWrite confined under the book sources dir only, returns the repo-relative path. `GeneratePanel.tsx` gains the Browse button + hidden file input, uploads via FormData, renders upload errors inline; the typed-path flow still works.

## Local review (pre-push)
- CodeRabbit: not tracked (skipped per session preference — step 4b, recorded in PR body).
- Adversarial / fresh-context **security-focused** critic: **mergeable, 0 must-fix.** Verified at REAL RUNTIME: write confinement (a `../../../etc/x.png` upload lands sanitized inside sources, nothing escapes), the allowlist (.html/.svg/double-extension rejected; HEIC accepted on write but inert at /api/file → no stored-XSS), collision suffix, unknown-book 404, client uses FormData not JSON.
- Two cleared **cosmetic** nits left as deliberate follow-up: a one-line note that the size cap is post-buffer, and a comment correction (atomic rename CAN overwrite). Neither is load-bearing; both are comment-only.
- typecheck/lint/build PASS; vitest 278 tests PASS (+13: upload write / allowlist / traversal-sanitize / collision / oversize / unknown-book; component picks file → FormData → fills field, error renders).

## Step compliance
- Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9).
- Skipped: 4b (CodeRabbit per session preference, recorded).
- Compliance: 88.9%. Skip assessment: **good** — 0 post-merge issues; the security-focused critic (4c) covered the load-bearing surface (write/upload endpoint) at real runtime; CI green.

## Review friction (post-push)
- 0 inline comments, 0 GitHub reviews, 1 round. Self-merged. CI (studio) SUCCESS.
- Timeline: commit 00:36 → created 00:40 → merged 00:42. ~6 min total, ~2 min created→merged.

## Adversarial review effectiveness
- The one real risk class for this PR — **path traversal / write confinement on a new upload endpoint** — is squarely in the adversarial checklist (Cross-platform path traversal validation, adversarial-review.md:367). It was caught and verified at runtime pre-push, not merely reviewed statically. Catch potential: high; nothing escaped.
- The two cleared nits are comment-accuracy only (no checklist tier), correctly deferred rather than triaged-away on code.

## Fix-up metrics
- Post-merge fix rate: 0.0 (no follow-up fix PRs; #37 reuses this endpoint and re-verified its confinement clean).
- Pre-merge catch rate by step: all 0 — the single commit shipped with 0 must-fix from the critic, so no fix commit was needed.
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: {} (no fix commits).
- adversarialCatchRate: **unmeasured** — there were no must-fix findings to attribute, so a catch-rate fraction has no evidentiary denominator. Per metric-integrity, recorded as "unmeasured" rather than a fabricated 1.0. (Distinct from #37, where there WAS a finding caught by the gate → 1.0.)

## Planning quality
- Complete: Summary (with the why-upload rationale), Review (critic verdict + the runtime-verification list), Test plan, explicit Steps-skipped line. Clean single-concept scope at a healthy 377 LOC — well under the 600 cap.

## Code quality signals
- Recurring positive: a NEW write/upload endpoint was paired with a **security-focused** critic (matched to the change's risk class) that verified confinement at runtime, not just by reading the sanitizer. This is the right critic-to-risk match.
- No new unrecorded code patterns; the confinement approach (strip-all-dirs basename + write-under-book-dir-only + allowlist) is the standard pattern and gets reused/extended by #37.

## Process efficiency
- Automation: the two comment nits (post-buffer cap note; atomic-rename overwrite correction) are sub-5-line comment edits — defensibly deferred, but the "fix under-5-line issues now" rule suggests they could have ridden the same commit. Trivial.
- Iteration: efficient (1 round). CI: all passed.

## Knowledge updates
- No new pattern unique to #36 (the matched-critic-to-risk-class observation is folded into the feature-level Characters-studio entry written with #37). Metrics + dashboard updated.

## Recommendations
1. Fold the two cleared cosmetic nits into the next touch of `upload-source` (both are comment-only, sub-5-line).
2. Continue matching the critic's lens to the change's dominant risk class (security-focused critic for write/upload endpoints) — it paid off here with a runtime-verified confinement pass.
