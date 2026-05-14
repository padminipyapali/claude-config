# Post-mortem: remodel-hq PR #46

**Title:** fix(design-studio): center-crop inspo to base aspect ratio
**Branch:** fix/inspo-aspect-crop -> main
**Author / Merged by:** padminipyapali (self-merged)
**Size:** +119 / -1 across 3 files, 1 commit (squashed)
**Time to merge:** ~19 minutes (PR open to merge)

## Context

Direct follow-up to merged PR #44. After #44 added prompt language and a brush-mask UI, the model still occasionally inherited the inspo's aspect ratio. An earlier attempt (PR #45, closed unmerged) added a server-side letterbox post-processor. The user disliked the visible blurred bars and proposed a better approach: pre-crop the inspo to the base aspect ratio so the model sees same-shaped inputs.

This PR implements that approach.

## What changed

- New `src/app/api/design-generate/crop-to-base.ts` — sharp-based helper that center-crops the inspo to match the base's aspect ratio.
- New `src/app/api/design-generate/crop-to-base.test.ts` — 5 vitest cases (portrait/landscape both directions, same-aspect upscale, already-matching, corrupted-input).
- `src/app/api/design-generate/route.ts` — calls the helper inside try/catch when `inspoImage` is provided; falls back to un-cropped inspo on sharp failure; logs `[design-generate] cropped inspo` on success.

## Process

Same orchestrator / implementer / critic team pattern as PR #44. Cycles:

1. Implementer first pass.
2. Critic adversarial review - 8 findings (3 SHOULD-FIX numbered 1-3, 5 NITs 4-8). The key finding: redundant `sharp().metadata()` call in `route.ts` decoded the base image twice (once in the route to enrich the log, once inside the helper).
3. Implementer applied the dedupe fix - helper now returns `baseW`/`baseH` and the route reads from the result.

User validated live on worktree dev server (port 3001) before merge.

## Quality signals

- No GitHub reviews / comments (self-authored, self-merged). QA via local critic + iterative user testing.
- 0 fix commits in the PR commit history (squashed). 1 real review-fix iteration during dev.
- **Post-merge:** no follow-up fixes needed so far (user confirmed "looks AWESOME").
- **Worked first try** in production - the user's intuition (pre-process input vs post-process output) was correct, and the team executed cleanly.

## Patterns / learnings

- **For multi-image LLM inputs, normalize ALL inputs to the desired output shape BEFORE the model call.** The model is more likely to produce output matching its inputs than output matching a prompt instruction. If you want the output to have base dimensions, force every input image to have base dimensions. Prompt instructions are weak; matching inputs are strong.
- **When iterating on an image-model bug class, try input-side fixes before output-side fixes.** Input pre-processing is deterministic, fast (~100ms with sharp), and produces clean output. Output post-processing (letterboxing/cropping) is also deterministic but always visible to the user as a treatment.
- **User intuition beats engineering instincts on UX tradeoffs.** I initially proposed a server-side letterbox post-processor (PR #45). The user suggested input pre-cropping instead — a better fix because it removes the symptom at the source. I almost committed to a more complex output-side fix when the simpler input-side fix existed.
- **Closing an unmerged PR in favor of a better approach is the right call when discovered mid-flight.** PR #45 was opened, deployed to a worktree dev server, and the user explicitly chose to close it in favor of the alternative. Sunk-cost reasoning would have merged it; the user vetoed.

## Knowledge updates

- `~/.claude/knowledge/llm-integration.md` already had the prompt-dimension-control entry added during PR #44's post-mortem. Adding:
  - **Normalize multi-image inputs to the desired output shape before the model call.** When passing multiple images to an edit model (e.g., base + reference), pre-process them all to the SAME aspect ratio/dimensions as the desired output. The model is more likely to produce output matching its inputs than output matching a prompt instruction. Center-crop the reference image if framing is irrelevant (style/color swatches); letterbox if framing matters. <!-- Source: post-mortem, remodel-hq #46, 2026-05-13 -->
