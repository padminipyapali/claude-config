# Post-mortem: remodel-hq PR #44

**Title:** feat(design-studio): brush-drawn mask + nano-banana + in-place edit prompt
**Branch:** feat/inpaint-mask-and-model-swap -> main
**Author / Merged by:** padminipyapali (self-merged)
**Size:** +457 / -78 across 4 files, 1 commit (squashed)
**Time to merge:** ~38 minutes (PR open to merge); ~2 hours total dev time

## What was built

Three changes bundled to fix a class of "full regeneration instead of localized edit" bugs in Design Studio:

1. Switched image model from `gemini-3-pro-image-preview` to `gemini-2.5-flash-image` (nano-banana).
2. Rewrote the prompt as an explicit "EDIT operation, NOT a regeneration" with consistent base/inspiration/mask image naming.
3. Added brush-drawn mask UI in Design Studio that sends a B/W PNG to the model.
4. (Side fix bundled in) Send the currently-viewed step as the base image instead of always re-sending the original with text history.
5. (Side fix bundled in) Replaced overflowing `inline-block` wrapper with `grid-cols-1 grid-rows-1` cell to fix wide-window image overflow.

## Process

Used the orchestrator / implementer / critic team pattern (per global CLAUDE.md), not the documented step-numbered review-fix-loop flow. Four review-fix iterations occurred before merge:

1. Implementer first pass (general-purpose, in worktree).
2. Critic adversarial review (fresh-context general-purpose) - found 4 BLOCKING (B1-B4) and 9 SHOULD-FIX (S1-S9). Implementer applied B1, B3, S3, S4, plus untracked-file staging.
3. User-driven Fix A (send viewed step as base, drop edit history) + Fix B (resize bug) - first attempt at grid fix.
4. User reported B still broken + mask not affecting model - real grid fix (`grid-cols-1 grid-rows-1` + `overflow-hidden`), debug instrumentation added, prompt strengthened.
5. Cleanup pass - strip debug instrumentation.

User validated both behaviors live on a worktree dev server (port 3001) before merge.

## Quality signals

- **No GitHub reviews / comments** (self-authored, self-merged). Quality assurance happened via local critic agent + iterative user testing.
- **0 fix commits in the PR commit history** (everything squashed into 1 commit), but 4 actual review-fix iterations occurred during dev.
- **Adversarial review findings:** 13 (4 blocking, 9 should-fix); ~5 acted on.
- **Post-merge:** A new bug was reported immediately after merge (inspiration image's aspect ratio still leaks into output despite strengthened prompt language). This is the same class of issue that motivated the PR's first prompt fix. **Prompt-level dimension control is unreliable; a deterministic server-side resize is the real fix.**

## Patterns / learnings

- **Prompt-only constraints on image-model output dimensions are unreliable.** Gemini 2.5 / 3 will still inherit the inspiration image's aspect ratio in some cases regardless of how many times "MUST match base image dimensions" appears in the prompt. The robust fix is server-side: decode model output, crop/letterbox/resize to base-image dimensions before returning. This should have been part of the original PR.
- **`max-w-full max-h-full` on an image needs an ancestor with a definite size** AND a layout context that doesn't create content-circular sizing. `inline-block` and `grid` with auto tracks both create the circular dep. Use `grid-cols-1 grid-rows-1` (explicit `1fr` tracks) or explicit pixel/% dimensions on the wrapper.
- **For mask-based edits, the base image sent to the model MUST be the currently-viewed image, not the original.** Coordinates only align if the user is editing what they painted on. Compounding artifacts from successive edits is a strictly lesser harm than wrong-content output.
- **Iterative model-output testing requires a live dev server in the worktree.** The implementer-only verification (typecheck + tests) doesn't catch model-behavior regressions or layout bugs - only manual testing did.

## Knowledge updates

Adding to `~/.claude/knowledge/llm-integration.md`:
- Prompt-based image-dimension control is unreliable; always add a deterministic post-processing step that resizes model output to the desired dimensions.
