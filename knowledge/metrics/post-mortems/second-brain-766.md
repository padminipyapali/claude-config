# Post-Mortem: PR #766 — make the adversarial-review gate worktree-aware

**Branch:** `fix/adversarial-hook-worktree-aware` → `main`
**Author:** padminipyapali (with Claude Opus 4.8) | **Merged:** 2026-06-27T01:25:40Z
**Size:** +140 / −10 across 2 files, 1 commit | **Closes #703**

---

## Summary

A **hooks-only** change (no TypeScript). The pre-push gate `.claude/hooks/require-adversarial-review.sh`
detected "cd into another repo" with `[ -d "$dir/.git" ]`, which is **false for a git worktree** because a
linked worktree's `.git` is a *file*, not a directory. So every worktree push/PR silently fell back to
checking the **main** repo's HEAD against the **main** marker and was wrongly **BLOCKED** — even when the
worktree's own commit was genuinely reviewed (its own marker existed). This had blocked #698/#702 and the
export PRs (worked around by writing markers at two hashes).

**The fix:**
- Resolve repo roots via `git -C <dir> rev-parse --show-toplevel` (worktree-safe — works whether `.git` is a
  dir or a file), honoring the `cd` target.
- Decide enforce-vs-skip by comparing the absolute `--git-common-dir`: a project and its linked worktrees
  share **one** common dir, while an unrelated repo (e.g. `~/.claude`) has a different one. Project worktrees
  stay **ENFORCED**; unrelated repos still skip.
- The marker-vs-HEAD check, the push / `gh pr create` gating, and the `git push origin main` allow are
  **unchanged** — no weakening of the gate.
- New hermetic test `require-adversarial-review.test.sh` (125 lines) builds throwaway repos + a linked
  worktree under a temp `HOME` and asserts: reviewed worktree push → 0, **un-reviewed worktree push → 2**
  (no-weakening proof), unrelated repo → 0, `push origin main` → 0. **4/4 pass.**

This PR is the **"promote from prose to code"** execution of the recommendation already standing in
`~/.claude/knowledge/process-patterns.md:188` (the worktree-`.git`-is-a-file + `--git-common-dir` gating was
already documented in prose after #647/#683; this codifies it in the hook + a regression test).

---

## Unusual development flow (worth recording)

The orchestrator went to implement #703 and **discovered it was already implemented and committed**
(`9ed7539`) in a parked worktree ~2 days old, with no PR. Rather than re-implement, it:
1. Cherry-picked that vetted commit onto a clean branch off current `main`.
2. Re-ran the hermetic test on current main → **4/4**.
3. Put it through the adversarial gate (a deep no-weakening review — 7 independent adversarial probes all
   confirmed the gate still fails **CLOSED**: an un-reviewed worktree push still exits 2).
4. Shipped it.

**Lesson captured** (`process-patterns.md`, Process Rule Enforcement): before implementing an issue, check for
parked-but-unshipped work (`git worktree list`, `git branch -a | grep`, `git log --all --grep '#<issue>'`) and
reuse a vetted parked commit — re-verified against current `main` — instead of re-implementing it.

---

## Metrics

### Local review (pre-push)
- **Adversarial gate:** PASS, **0 must-fix**. Because this change modifies the GATE itself, the review was an
  extra-deep no-weakening probe (7 adversarial scenarios + the hermetic test's own no-weakening case).
- **CodeRabbit (4b) / simplify (4a):** not run — lightweight hooks-only change, pre-vetted parked commit.
- **lint / build / test (TS):** N/A — no TypeScript changed. The meaningful gate was the hermetic **bash**
  test (4/4), which maps to step 3 (Test).
- **Shift-left rate:** n/a (no findings on either side of the push).

### adversarialCatchRate — **unmeasured (null)**
The gate found **0 must-fix code defects** (PASS, with thorough probes). There was **no prior critic round**:
the code was pre-vetted in the parked commit and independently re-verified (hermetic test 4/4, deep no-weakening
gate). Real catches pre-merge = 0; escapes (post-merge fixes) = 0. With zero issues found on either side, there
is **no catch rate to compute** — recorded as `null`/"unmeasured" rather than a fabricated 0% or 100%.

### Step compliance
- **Steps run:** 1 (plan), 2a (implement), 3 (test — hermetic bash 4/4), 4c (adversarial gate), 5 (push+PR).
- **Steps skipped:** 2b (hardening — N/A, single-pass gate fix), 4a (simplify), 4b (CodeRabbit), 4d (TS
  lint/build/test — N/A, no TS).
- **Compliance rate:** 5/9 = **55.6%** of trackable steps.
- **Skip assessment:** **good** — no post-merge issues; the skipped steps (TS gates, CodeRabbit) had nothing to
  act on for a bash-only change. Skips reflect the change's nature, not corner-cutting.

### Step timing — not tracked
No `## Step Timing` table in the PR body. created→merged elapsed: **18.4 min**.

### Review friction (post-push)
- Review rounds: **1** (0 CHANGES_REQUESTED; self-merged solo workflow).
- Comments: **0 substantive** (1 Vercel bot comment, excluded).
- Timeline: created → merged: **0.31 h**. No peer review (expected for solo dev; gate + hermetic test are the
  review surface).

### Fix-up metrics
- **Post-merge fix rate: 0.0%** — no follow-up commits/PRs touch the hook after #766. Quality did not escape.
- **Pre-merge catch rate by step:** all 0 (no fix commits — single feature commit).
- **Pre-merge iteration count: 1** (healthy).
- **Fix-up taxonomy:** all 0.
- **Legacy fix-up ratio: 0.0%** (0 fix / 1 total commit — the lone commit is the feature/fix itself, not a
  review fix-up).

### Planning quality
- Description: **complete** — What & why, How, Testing (with exit-code table), Notes, Local Review sections all
  present. The PR body itself documents the no-weakening proof.
- Scope: **clean** — single concern (one hook + its test), 150 LOC, 1 commit, no redesign/revert markers.
- Branch lifetime: minutes (cherry-pick → verify → ship).

---

## Knowledge updates

- **Strengthened** `~/.claude/knowledge/process-patterns.md:188` — recorded that the "better fix" (resolve repo
  roots via `git rev-parse --show-toplevel`; gate by shared `--git-common-dir`) is now **shipped** in #766 with
  a hermetic regression test. This is the canonical line-238 "promote prose to enforceable artifact" execution.
- **Added** to `process-patterns.md` (Process Rule Enforcement): "Before implementing an issue, check for
  parked-but-unshipped work … reuse a vetted parked commit instead of re-implementing it."
- No adversarial-review.md gap (0 must-fix found; the gate worked as designed).

---

## Recommendations

1. **Confirm the new hook behavior across the team's worktrees.** The fix is now live on `main`; the
   long-standing friction tax on worktree pushes (#647/#683/export PRs) should disappear. If any worktree push
   is still wrongly blocked, that's a regression to investigate against the hermetic test.
2. **Adopt the parked-work check as a pre-implementation step.** The discovery of `9ed7539` was incidental;
   making the `git worktree list` / `git log --all --grep '#<issue>'` sweep a standing pre-dispatch check would
   make it deterministic and prevent duplicate implementation of any parked fix.
3. **For gate-modifying changes, keep the deep no-weakening review as the bar.** The 7-probe + hermetic
   no-weakening-case approach used here is the right gate for any change to the review gate itself; record it as
   the standard for `.claude/hooks/*` changes.
