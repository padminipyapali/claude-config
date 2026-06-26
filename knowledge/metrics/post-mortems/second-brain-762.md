# Post-Mortem: PR #762 — feat(notes): conservatively clean dictated dashboard notes, preserving the original

**Date:** 2026-06-26
**PR:** [#762](https://github.com/padminipyapali/second-brain/pull/762) — Closes [#755](https://github.com/padminipyapali/second-brain/issues/755)
**Branch:** `feat/wispr-note-cleanup` → main (squash-merged as `9915282`)
**Time to Merge:** ~7.6m on GitHub (created 22:19:42, merged 22:27:18 UTC) — the dev loop ran locally before push
**Merged by:** padminipyapali (self-merge, solo dev — expected for this workflow)
**Size:** +813 −5 across 12 files, 2 commits (squashed on merge)

## 1. What Shipped

Dashboard voice notes dictated via Wispr arrive as plain keyboard text — fillers, run-ons, no punctuation — with **no detectable signal** (Wispr inserts text like a keyboard: no API, no metadata, and the composer captures only the final text). The decided shape: **don't try to detect dictation; conservatively clean ALL qualifying notes**, because a meaning-preserving cleanup is a near-no-op on already-clean text and a real fix on messy dictation. **The original is never mutated.**

- **Heuristic gate** (`dictation-cleanup.ts`) — a *cost* control, not a detector: only spend an LLM call when a note plausibly needs it (≥40 chars AND filler markers / low punctuation density / a long run with no sentence breaks). Short/clean notes skip the LLM.
- **`ResponseService.cleanupDictatedText`** (Haiku): fixes punctuation/capitalization/fillers/false-starts; **preserves exact meaning — never summarizes/shortens/adds**; already-clean → unchanged; prompt-injection-safe (input XML-escaped + tag-wrapped); fence-stripped; empty output → original.
- **Pipeline** (`post-processor.ts`): runs **fire-and-forget after entry creation** (own try/catch per await), scoped to **THOUGHT + IN_APP only** (TODOs have their own cleanup; Telegram/SMS untouched; URL notes skipped so URL-enrichment owns `extracted_text` — never both). Success → `extracted_text`; any failure → stays null, original flows through. Env kill-switch `DISABLE_DICTATION_CLEANUP`.
- **Preserve original / reversible:** original stays in `content`; cleaned goes to `extracted_text` (existing enriched-copy field — **no schema change**). Editing a note edits `content`; clearing `extracted_text` restores the raw note.
- **Web** (`EntryCard.tsx`): shows cleaned text by default with a **"View original"** toggle.

## 2. The Process Story — an unsolvable detector dissolved by a conservative unconditional action

The defining design decision: the feature was *framed* as "detect a Wispr/dictated note, then clean it," but an **upstream feasibility investigation** (a workflow, run BEFORE building) found there is **no reliable way to detect dictation** — Wispr emits keystrokes, leaves no metadata, and the composer only sees final text. Rather than ship a flaky detector (which would both miss real dictation and false-positive on typed text), the decision was to **act unconditionally with a conservative, meaning-preserving action that no-ops on the negative case**: clean every qualifying THOUGHT+IN_APP note. Because a meaning-preserving cleanup leaves already-clean text essentially unchanged, "always-clean + preserve original" achieves the goal the unreliable "detect-then-clean" couldn't — and the decision was made **from evidence, not assumed**. The cheap heuristic gate is then purely a *cost* lever (skip the LLM on obviously-clean/short notes), not a correctness-bearing detector — a key reframing that keeps the unconditional action safe and cheap.

This earned a **full fresh-context critic** (not the lightweight gate): the feature modifies user-visible displayed content, runs an LLM pass, and the preserve-original invariant is load-bearing.

## 3. Metrics

| Metric | Value |
|--------|-------|
| **Additions** | 813 lines |
| **Deletions** | 5 lines |
| **PR size (add+del)** | 818 lines (~313 LOC production + tests) |
| **Files changed** | 12 |
| **Commits** | 2 (feature `36bcf88`, post-critic polish `868df8c`) |
| **PR open to merge** | ~7.6m (local dev loop ran before push) |
| **Review rounds** | 1 (full fresh-context critic + adversarial gate; no GitHub review rounds) |
| **GitHub review comments** | 0 substantive (only Vercel bot; 0 inline comments) |
| **CI** | Vercel SUCCESS; server **2388 passed**, web **346 passed** |
| **adversarialCatchRate** | **unmeasured** (see §5) |
| **Post-merge fix rate** | 0.0 (no follow-up fix touches the area; #755 closed) |

## 4. Pipeline (how it was built)

1. **Upstream feasibility investigation (a workflow)** established detect-vs-always-clean from evidence — Wispr is undetectable, so "always-clean, preserve original" was chosen deliberately.
2. **Implementer wrote the code** in a single pass: heuristic gate + Haiku cleanup + fire-and-forget pipeline + EntryCard toggle + tests.
3. **Implementer's own critic pass surfaced and fixed the substantive bug** — a *pre-existing* stale `extracted_text` on edit/reformat that this feature made user-visible. The fix (`updateEntryContent` now nulls `ai_response` AND `extracted_text`) shipped **inside the feature commit `36bcf88`**.
4. **Full independent fresh-context critic RAN** (warranted: user-visible content mutation + LLM pass + load-bearing preserve-original invariant). It returned **0 blockers**, confirmed the SHOULD-FIX was already handled, and flagged only **2 NITs** (a `prefers-reduced-motion` CSS override and a doc reword).
5. **Post-critic commit `868df8c`** carried only those two NITs (+13/−3: JSDoc reword + reduced-motion CSS). No new blockers or should-fixes.
6. **Gates kept:** build/lint/test green (server 2388, web 346), adversarial marker. **Skipped:** `/simplify` (4a) and CodeRabbit CLI (4b) per the lightweight-review preference for a ~313-LOC PR — the full critic carried the load.

## 5. adversarialCatchRate — Evidence

**Value: `unmeasured` (null)** — recorded honestly per the metric-integrity rule; NOT fabricated to 1.0 and NOT 0.

Commit-order evidence (the decisive fact):

- **Feature commit `36bcf88`** ALREADY contains the substantive SHOULD-FIX. Its diff to `entry.ts` changes
  `UPDATE entries SET content = $1, ai_response = NULL` → `..., ai_response = NULL, extracted_text = NULL`,
  plus a dedicated `entry.update-content.test.ts`. So the real bug (stale derived text on edit) was caught by the **implementer's own critic pass** and fixed *before* the independent critic ran.
- **Post-critic commit `868df8c`** contains ONLY a JSDoc/comment reword and a `prefers-reduced-motion` CSS NIT — **zero new blockers or should-fixes**.
- Therefore the independent fresh-context critic **ran fully and found 0 NEW actionable blockers/should-fixes** — it confirmed the already-shipped fix and surfaced 2 NITs (polish).
- New code defects caught by the *independent* critic = 0; **post-merge escapes = 0** (#755 closed, no follow-up fix touches the area).
- caught / (caught + escaped) for the independent critic = 0 / (0 + 0) = **undefined** → recorded as **`unmeasured`**, with the note that the critic ran clean (found polish only) and the **substantive bug was caught earlier by the implementer's own critic pass** and shipped in the feature commit.

This is the "critic ran fully, found the design genuinely clean, 0 escapes" shade (same family as #758/#760), distinct from the "no critic ran" shade — the note records which.

## 6. Step Compliance & Timing

- **Step compliance 7/9** (0.7778). Ran: 1 (plan, from the upstream feasibility workflow), 2a/2b (single-pass implement + hardening), 3 (build/lint/test), **4c (full fresh-context critic — NOT skipped)**, 4d (adversarial gate), 5 (PR). Skipped: **4a** (`/simplify`) and **4b** (CodeRabbit CLI) per the lightweight-review-for-small-PRs preference (~313 LOC), with the full critic carrying the review load.
- **Skip assessment: good** — 0 post-merge escapes; the gate that mattered for a content-mutating LLM feature (the full critic) was the one that ran.
- **Step timing:** the PR body has no per-step minutes → all `stepTiming` minute fields `null`. Only hard signal is the ~7.6m GitHub open→merge window (excludes the local dev loop).

## 7. What Went Well

- **An unsolvable detector was dissolved by reframing the action, not by a flaky heuristic.** "Always-clean + preserve original" replaced "detect dictation, then clean" once the feasibility investigation proved Wispr is undetectable. The cleanup no-ops on already-clean text, so acting unconditionally is safe — and the decision was evidence-driven, made BEFORE building.
- **The heuristic gate was correctly positioned as a cost lever, not a detector.** Mislabeling it a detector would have re-imported the correctness problem; keeping it as "should we spend an LLM call?" keeps the unconditional action both safe and cheap.
- **Preserve-original is structural, not a convention.** Original stays in `content`; cleaned lands in the existing `extracted_text` field (no schema change); the change is reversible by clearing `extracted_text`, and the "View original" toggle exposes it.
- **The right gate ran for the risk profile.** A content-mutating + LLM-pass + load-bearing-invariant feature earned the full fresh-context critic rather than the lightweight gate — and the critic's negative finding (0 new must-fix) is the signal of record.
- **The substantive bug was caught pre-merge by the implementer's own critic and shipped in the feature commit; 0 post-merge escapes; #755 closed.**

## 8. Process / Quality Signals

- **adversarialCatchRate is `unmeasured`, not a number.** Per the commit-order evidence, the independent critic found 0 new actionable items (polish only) and the real bug was already fixed pre-critic; `0/(0+0)` is undefined and must not be hardcoded to 1.0.
- **2 commits, 1 of which is a fix commit** → legacy `fixupCommitRatio` = 0.5, but the per-step *independent*-catch table is all zeros: the fix that the ratio counts (`868df8c`) is NIT polish, and the substantive fix rode inside the feature commit. The per-commit fix-attribution model overstates "iteration" here; the narrative records the true shape.
- **The fix taxonomy is `documentation: 1, a11y: 1`** (the doc reword + the reduced-motion CSS) — both NITs, no correctness/validation fixes post-feature-commit.

## 9. Learnings — Status

**Net-new (captured this post-mortem):**

- **When a feature is framed as "detect condition X, then act," and X turns out to be unreliably detectable, evaluate acting unconditionally with a conservative/idempotent action that no-ops on the negative case.** Such an action can *dominate* an unreliable detector: it never false-negatives (every case is handled) and never false-positives in effect (the negative case is left ~unchanged), so it achieves the goal the flaky detector couldn't — and any cost-side heuristic should be positioned as "is it worth spending the expensive step?" not as the detector itself (mislabeling re-imports the correctness problem). Added to `~/.claude/knowledge/architecture-patterns.md` (Pipeline Design). Source: Wispr #762/#755 — "always-clean, preserve original" replaced "detect dictation, then clean," decided from an upstream feasibility investigation, with the gate kept as a pure cost lever.

**Already captured — NOT duplicated:**

- **Fire-and-forget with per-await `.catch()`** — already in the TS/fire-and-forget conventions; #762 reuses it (cleanup runs fire-and-forget after creation, own try/catch).
- **Preserve originals / store derived copy in a separate field** — the project rule and the existing `extracted_text` enriched-copy pattern; #762 applies it, doesn't invent it.
- **Dedup/normalize across raw and cleaned text; derived-data fields must not collide** — `architecture-patterns.md` already has the "URL-enrichment owns `extracted_text`" class (the skip-URL-notes guard is the same single-writer discipline).

## 10. Recommendations

1. **Reach for "act conservatively + preserve original" whenever a planned detector proves unreliable.** Before building a classifier/detector for "is this input of type X?", ask whether an idempotent action that no-ops on the negative case reaches the same goal without the detection. Validate detectability with a cheap feasibility probe BEFORE committing to the detect-then-act shape — as #762 did.
2. **Keep the full fresh-context critic for content-mutating / LLM-pass / load-bearing-invariant features even when LOC is small.** #762 was ~313 LOC but correctly earned the full critic (not the lightweight gate) because it changes user-visible content and the preserve-original invariant is load-bearing. The skip of `/simplify`+CodeRabbit was assessed `good`.
3. **When recording adversarialCatchRate, use commit order to attribute catches honestly.** A SHOULD-FIX that shipped *in the feature commit* was caught by the implementer's own pass, not the independent critic; an independent critic that then finds only NITs is `unmeasured` (clean), not 1.0. Continue recording this distinction so the catch-rate trend isn't inflated.
