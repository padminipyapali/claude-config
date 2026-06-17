# POST-MORTEM: plush-press PR #37 — Add the Characters tab UI: onboard a character end-to-end (Characters studio Wave 3).

Branch: feat/characters-tab → main | Author: padminipyapali | self-merged ~96 min after creation
Size: +1831 -128 across 14 files, 1 commit (squash ef8138e)

## Summary
The **capstone of the Characters studio**: the live 01 Characters tab wiring the merged backend into a clickable onboarding flow — upload photos → Claude drafts the hero-prompt slots → approve/edit → generate best-of-N hero → pick → tune → lock hero → edit + save the text bible → lock character. Mirrors the 02 Scenes loop. Key pieces: `StudioShell` tab routing (01 live, book picker hidden on the book-agnostic Characters tab); `CharacterPicker` (status pills + hero thumbs + plush/human New-character form); `CharacterStudio` 7-step timeline; **`GeneratePanel`/`TunePanel` generalized with a discriminated `context` prop** so the same components drive both the scene and character loops (scene path byte-identical = default context); `/api/upload-source` gains a `dest` discriminator (book-source vs character-photo → `character bible/<slug>/inspiration_photos/`) reusing the same confinement guards; `/api/characters/[slug]` GET now returns `bibleBody` + `photos`. Completes the Characters studio: data (#34) + draft (#33) + ops (#35) + UI (#37).

## Local review (pre-push)
- CodeRabbit: not tracked (skipped per session preference — step 4b, recorded).
- Adversarial / fresh-context critic: **mergeable after one should-fix (applied pre-merge).**
  - The two LOAD-BEARING concerns both PASS clean: (1) **no scene-loop regression** from the shared `GeneratePanel`/`TunePanel` generalization (scene path byte-identical on the default context); (2) **upload-path security** — the new character-photo `dest` is as confined as the book path (slug-gated, basename-only, allowlist, traversal-tested).
  - SHOULD-FIX (correctness/UX): **HEIC inspiration-photo thumbnails rendered broken** — `/api/file` doesn't serve HEIC, and the operator's real photos ARE HEIC, so the DEFAULT path showed broken images. Fixed pre-merge with filename chips for .heic/.heif (real thumbnails kept for png/jpg/webp/gif).
- typecheck/lint/build PASS; vitest 318 tests PASS (+37: tab/picker/studio flow, draft prefill, lock-confirm dialog, blocked states, upload `dest` security, GET bibleBody/photos, the HEIC-chip render).
- Real-runtime + Playwright (no keys): Characters tab renders cast + form; studio shows blocked draft/generate with right links; Scenes tab unchanged. Two design screenshots in PR body.

## Step compliance
- Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9).
- Skipped: 4b (CodeRabbit per session preference, recorded).
- Compliance: 88.9%. Skip assessment: **good** — 0 post-merge issues; the critic (4c) caught the one should-fix that 4b might have, the two load-bearing risks were independently verified, CI green.

## Review friction (post-push)
- 0 inline comments, 0 GitHub reviews, 1 round. Self-merged. CI (studio) SUCCESS.
- Timeline: created 01:06 → merged 02:42 ≈ 96 min. The window spans the HEIC should-fix fix + Playwright design-screenshot capture (no separate fix commit — squashed into ef8138e).

## Adversarial review effectiveness
- The HEIC defect is a **default-path real-data UX class** — it is in the lineage of the existing plush-press #28/#31 pattern ("UI must be verified in the POPULATED/real-data state, not just empty/open"). Here the critic DID demand the real-data render and caught it because the operator's actual photos (HEIC) hit a server that doesn't serve that format. Catch attributed to 4c.
- The shared-component generalization (`GeneratePanel`/`TunePanel` → discriminated `context`) is exactly the "shared component renders in N contexts" risk from #28/#31; the critic verified the scene path stayed byte-identical, which is the correct way to discharge that risk (prove the existing context is untouched, then exercise the new one).

## Fix-up metrics
- Post-merge fix rate: 0.0 (no follow-up fix PRs; the studio is complete).
- Pre-merge catch rate by step: **4c (critic) caught 1** (the HEIC should-fix); all others 0.
- Pre-merge iteration count: 1 (healthy — one critic round, should-fix applied before push).
- Fix-up taxonomy: { correctness: 1 } (the HEIC broken-thumbnail default-path defect).
- adversarialCatchRate: **1.0** — the one finding was caught by the adversarial/critic gate, zero escaped to post-merge.

## Planning quality
- Complete: Summary, Designs (2 Playwright screenshots), Review (critic verdict + the two load-bearing PASSes + the should-fix narrative), Test plan, explicit Steps-skipped line, AND a deliberate follow-on note (auto-drafting the *bible* via Claude is out of scope; hero auto-draft is in, bible ships as an editor).
- Size 1959 LOC is over the 600 cap, but legitimately atomic-ish: it is the UI capstone that has no value half-wired, ~1/4 is tests (+37), and the riskiest refactor (shared panels) was discharged by a byte-identical proof. Still, this is the kind of PR the "atomic-exception" rule (process-patterns) says to justify explicitly — it did, via the byte-identical scene-path argument.

## Code quality signals
- Recurring positive: every data hook renders its error, every button explicitly typed, inputs trimmed, confirm dialog has Escape + initial focus — the project's UI-hardening conventions were applied uniformly (matches the global Web-UI rules).
- New pattern captured (feature-level, see process-patterns): the Characters studio shipped as 4 vertically-sliced waves (data→draft→ops→UI), each its own self-merged PR with a matched-lens critic; the UI capstone is where the default-path real-data defect surfaced — consistent with #28/#31 that real-data render bugs live in the UI layer, caught only when the critic exercises the operator's actual inputs.

## Process efficiency
- Automation: the HEIC defect could in principle be caught by a render-test fixture that feeds a .heic filename and asserts a chip (not an <img>) — and #37 added exactly that test (the HEIC-chip render test), so the regression is now guarded.
- Iteration: efficient (1 round). CI: all passed.

## Knowledge updates
- process-patterns.md: strengthened the existing #28/#31 populated/real-data-state entry with the #37 HEIC default-path occurrence, and added a feature-level entry on the 4-wave vertical-slice shape of the Characters studio. Metrics + dashboard updated.

## Recommendations
1. The HEIC blind spot is broader than thumbnails: any place `/api/file` serves operator-supplied images can hit an unservable format. Consider a single format-capability helper (servable vs chip) so the next image surface doesn't re-discover this.
2. For the next multi-wave feature, keep the matched-lens critic per wave (security lens on upload/write waves, real-data/render lens on UI waves) — it caught the right class each time across #34/#35/#36/#37.
3. When a capstone PR generalizes a shared component, the byte-identical-existing-path proof is the cheapest way to discharge the regression risk; make it a standing expectation in the PR body, as #37 did.
