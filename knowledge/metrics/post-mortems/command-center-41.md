# Post-Mortem: command-center PR #41 — Add /explainers route for collected HTML explainers

**Branch:** feat/explainers-tab → main
**Author:** padminipyapali | **Merged by:** padminipyapali
**Created:** 2026-02-27T06:36:23Z | **Merged:** 2026-02-27T19:47:53Z
**Size:** +152 -4 across 5 files, 2 commits
**Time to merge:** 13.2 hours

## Summary

Added a build-time shell script (`scripts/collect-explainers.sh`) that collects HTML explainer files from knowledge base and project directories, generates an index page, and serves them via Express at `/explainers`. NPM lifecycle hooks (`prebuild`/`predev`) run the collection automatically.

## Local Review (pre-push)

- **Internal review:** 4 issues found, 4 fixed (trailing slash normalization, dev mode gap, gitignore, spaces in hrefs)
- **CodeRabbit local:** SKIPPED — "sub-50 LOC diff in tracked files"
- **Adversarial review:** SKIPPED — "N/A"
- **Playwright:** N/A (no UI components changed) — valid skip
- **CI:** prebuild passes; pre-existing TS errors on main unrelated

**Shift-left rate:** 44% (4 local / 9 total issues)

## Step Compliance

| Step | Status | Notes |
|------|--------|-------|
| 1 - Plan | SKIPPED | "lightweight feature, user-directed" |
| 2 - Implement | RAN | |
| 3 - Test locally | RAN | Build/prebuild passed; Playwright N/A (no UI) |
| 4a - Code simplification | SKIPPED | Not mentioned |
| 4b - Internal review | RAN | 4 issues found, 4 fixed |
| 4c - CodeRabbit | SKIPPED | "sub-50 LOC diff" |
| 4d - Adversarial review | SKIPPED | "N/A" |
| 5 - Push & create PR | RAN | |

**Compliance rate:** 50% (4/8 steps)
**Skip assessment:** BAD — CodeRabbit found 5 issues post-push that the skipped steps (4c, 4d) would have caught.

## Review Friction (post-push)

- **Review rounds:** 2 (CodeRabbit review on initial commit, CodeRabbit re-review on fix commit)
- **Human reviews:** 0
- **Bot inline comments:** 5 (4 from first review, 1 from re-review)
- **Self-merge:** Yes, no peer review

### Comment Categories

| Category | Count | Details |
|----------|-------|---------|
| security | 3 | Gate route behind env flag, opt-in home docs, HTML escaping |
| style | 1 | .gitignore alphabetical sorting |
| architecture | 1 | python3 dependency in build hooks |

### Timeline

- Created → first review: 0.1h (CodeRabbit automated)
- First review → merge: 13.1h
- Total: 13.2h

## Adversarial Review Effectiveness

**Pre-push catch potential:** 20% (1/5 partially covered)

| Comment | Covered? | Notes |
|---------|----------|-------|
| .gitignore sort | By CLAUDE.md rules | Convention, not checklist item |
| Gate route behind env flag | Partially | Security tier could catch, but not specific to static routes |
| Home dir opt-in | NOT covered | New pattern — already added to architecture-patterns.md |
| HTML escaping | Partially covered (0.10) | Checklist grep targets .ts/.tsx files, misses bash scripts |
| python3 dependency | NOT covered | New pattern — build hook runtime dependency alignment |

### Fix-up Analysis

- **Commit 1:** "Add /explainers route to serve collected HTML explainers." → FEATURE
- **Commit 2:** "Address PR review: sort gitignore, gate explainers route, opt-in home…" → FIX
- **Fix-up ratio:** 50% (1 fix / 2 total)

## Planning Quality

- **Description:** Partial — has Summary and Changes but no Test Plan section
- **Scope:** Clean (branch lifetime 13.2h, 156 LOC, single concern)
- **Redesign indicators:** None
- **Performance/cost section:** Missing

## Code Quality Signals

- **Recurring issues:** Security category had 3 comments — theme is "build hooks touching local filesystem need explicit opt-in and defense in depth"
- **New unrecorded patterns:**
  1. Build hooks should not depend on runtimes outside the project's stack (python3 in a Node project) — **not yet added**
  2. Build hooks must not default to home directory access — **already added** to architecture-patterns.md

## Process Efficiency

- **Automation opportunities:** All 5 post-push findings could have been caught by running CodeRabbit local (step 4c) and adversarial review (step 4d). The "sub-50 LOC" skip justification was incorrect — the actual diff was 156 LOC (+152 -4), well above the 50 LOC threshold.
- **Iteration:** Normal (2 rounds — initial + fix commit re-review)
- **CI status:** Vercel Preview Comments passed; pre-existing TS build errors unrelated

## Unaddressed Review Comment

The 5th comment (from CodeRabbit re-review) flagging python3 dependency in the `url_encode()` function was **not addressed** before merge. This should be fixed in a follow-up.

## Knowledge Updates

| Learning | File | Status |
|----------|------|--------|
| Build hooks must not default to home directories | architecture-patterns.md | New entry (added during review-fix) |
| Shell-generated HTML needs same escaping discipline | adversarial-review.md | Strengthened existing 0.10 check (added during review-fix) |
| Build hooks should use project-stack runtimes only | architecture-patterns.md | **TODO** — add based on python3 comment |

## Recommendations

1. **Stop using LOC as skip justification without checking.** The PR body claimed "sub-50 LOC diff" but the actual diff was 156 LOC. This directly caused 5 post-push findings. Compliance rate dropped to 50%.
2. **CodeRabbit local is mandatory for >= 50 LOC.** This is already a CLAUDE.md rule but was violated. The shift-left rate (44%) is well below the ~80% target.
3. **Fix python3 dependency.** Replace `python3 urllib.parse.quote` with `node -e 'encodeURIComponent(...)'` in a follow-up PR.
4. **Add adversarial review check for build scripts.** The current 0.10 check greps `.ts`/`.tsx` files only. Extend to shell scripts that generate HTML.
