# Post-Mortem: plush-press PR #2 — Add Book Assembler + The Zoo Bus (book #1)

**Branch:** `feat/book-assembler` → `main` | **Author:** padminipyapali | **Merged:** 2026-06-10T02:56:37Z (squash `7140d81`)
**Size:** +542 −1 across 26 files (mostly PNG art assets), 2 commits | **Created→merged:** ~22.4 h
**Process:** Developed in a PRIOR session via a manual, hand-built book pipeline — NOT the orchestrator team pattern. Very little process telemetry exists; per the metric-integrity rule, unmeasurable metrics below are marked **unmeasured**/null rather than fabricated.

## Local review (pre-push)
**Not tracked.** No `## Local Review` section in the PR body, no orchestrator session log, no critic. All `localReview` fields are null (null = "not tracked", distinct from 0 = "tracked, none found").

## Step compliance
**Not tracked** (no `Steps skipped:` line; pre-dates this repo's first orchestrator run). `stepCompliance` = null. Qualitatively: this was a scrappy-MVP/design-tooling PR (single self-contained `book.html`, README, art) built hand-in-the-loop with the user; the formal dev flow was not followed.

## Step timing
**Not tracked.** `stepTiming` = null.

## Review friction (post-push)
None recorded: 0 reviews, 0 comments, self-merged, no CI configured. No peer review — flagged per skill (mergedBy == author, no reviews), normal for this solo repo but unlike other recent PRs there was no fresh-context critic substitute either.

## Fix-up metrics
- **Post-merge fix rate: 0.5 (1 fix commit / 2 PR commits) — quality escaped review gates.** Evidence: PR #3 (merged 3 minutes later, developed with full process) contains commit `9122563` "Fix book-folder docs to match reality." which corrects defects #2 shipped: (a) `scene-prompts.md` declared output path `scenes/` while the real folder is `backdrops/`; (b) the book folder slug `the-zoo-bus` contradicts the book's actual title — `book.html` `CONFIG.title` is **"While We Wait"** — and docs followed the stale slug; (c) bible README listed bunny rows as if folders existed. These are documentation-vs-reality drift defects from hand-maintained docs, not app-code bugs.
- **Pre-merge catch by step:** 0 across all steps — no fix commits within the PR (both commits are feature commits).
- **Pre-merge iteration count: 1** (no review cycles at all).
- **Taxonomy (in-PR fixes):** all 0. The post-merge fix was documentation-class.
- **adversarialCatchRate: unmeasured** — no adversarial review was run and no post-push review occurred; there is no evidence base to compute from. (HARD RULE honored: not hardcoded.)
- Checklist cross-reference: the escaped defects (doc path/title drift) map to the existing Tier 4 doc-sync check ("for docs-only PRs run at least the Tier 4 doc sync check") — i.e., **covered but missed** because the review loop never ran.

## Planning quality
- **Partial.** PR body has a good Summary and workflow narrative but no Test Plan section, no entry-point enumeration, no Performance & Cost section (n/a for a static HTML tool, but unstated).
- **Scope:** mild scope creep — commit 2 landed ~22 h after commit 1 and bundled divergent themes onto the "Book Assembler" PR: 12 generated page images, `docs/style-guide.md` (house watercolor style), Scene Bible prompt kit, art reorganization into `backdrops/`/`characters/`. Tooling + art assets + style docs would have been cleaner as 2 PRs.
- Branch lifetime ~22 h (< 48 h threshold).

## Code quality signals
- Recurring issue class: **hand-maintained docs drift from artifact reality** (output paths, book title vs folder slug). PR #3's entire prompt-assembly restructure is the systemic fix (single canonical source + machine-readable front matter), and its critic caught the last remaining drift instance — so this class is now structurally addressed in this repo.
- Good call preserved: captions render in an overlay band so text is never baked into artwork — keeps pages regenerable.

## Process efficiency
- Automation opportunities: none beyond what #3's post-mortem captures (CI link/YAML check would have caught the dead `scenes/` path reference).
- Iteration: n/a (no review loop ran).
- CI: none configured.

## Knowledge updates
- No new entries needed beyond those filed under PR #3's post-mortem (the doc-drift lesson is the motivation already recorded there; the Tier 4 doc-sync rule already exists in process-patterns.md).

## Recommendations
1. Even for scrappy-MVP/design-tooling PRs in greenfield repos, run the minimal review loop — the Tier 4 doc-sync check alone would have caught all three escaped drift defects.
2. Resolve the `the-zoo-bus` folder-slug vs "While We Wait" title question (deliberately left unrenamed in #3) before book #2 starts, so the slug convention is settled.
3. Keep art-asset drops in separate commits/PRs from tooling — also unblocks CodeRabbit (see #3's payload finding).
