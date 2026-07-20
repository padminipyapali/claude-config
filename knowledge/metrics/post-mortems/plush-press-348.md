# POST-MORTEM: plush-press PR #348 — Make the New Scene page generate in the book's pinned style (Stage 6c)

Branch: Stage 6c style-aware New Scene → main | Author: padminipyapali | ~6 min PR-to-merge (~138 min dev total)
Size: +702 -16 across 12 files, 1 squashed commit. Closes the Art-Styles picker/creation docket.

## Local review (pre-push)
- Adversarial (critic, fresh context): **1 CRITICAL, fixed** — a bound book could fall through to the watercolor default while `backdropStyle` was still resolving (race) OR deterministically on a 422 resolve failure (silent default), firing a **paid wrong-style generation**. Fixed with a pin-aware generate gate: bound book HOLDS generation while resolving (the PR2 "Checking this book's art style…" idiom) and BLOCKS loudly on resolve failure (Stage-2 no-silent-defaults doctrine); choked at `generate()`, `genCandidates`, and `canGenerate`. Tests: bound+pending, bound+422, unbound+pending.
- CodeRabbit CLI: **1 MAJOR, fixed** — a **sibling instance** of the prompt-honesty issue in the photo-book-palette branch (claimed "an existing backdrop from THIS SAME book" when the ref was the style specimen). Both prompt branches now name the actual reference. Test added.
- Shift-left rate: 100%; 0 post-push comments; post-merge fix rate 0.0.

## Adversarial review effectiveness
- adversarialCatchRate = **1/2 = 0.5** (critic caught the CRITICAL; CodeRabbit caught the sibling). The critic's catch is the **cached-async / paid-click lens** firing exactly as designed — this class has now hit **6 of 7 consecutive PRs** in this project (#338's useResolvedStyle, #344's resolve-window write, the #346 rebind trace, this pin-gate, and predecessors). It is no longer an "edge" — it is the project's dominant defect class: any UI whose behavior depends on an async-resolved style/config MUST hold paid or persisting actions until resolution, and fail loud (not default) on resolve failure.
- The CodeRabbit sibling is a **sibling-sweep miss**: after fixing prompt honesty on the from-scratch branch, the photo branch had the identical claim. Universal convention #1 (sibling sweep) would have caught it in-pass.

## Step compliance / timing
- All 9 trackable steps ran; compliance 100%. Declared skip outside the 9: no live paid Gemini render (operator action; covered by tests + MEDIA byte-parity guard) — good skip, consistent with "never fire paid renders from CI".
- Plan ~25m · Implement ~35m · Tests ~20m · Gates ~7m · Critic+CRITICAL fix ~30m · CodeRabbit+MAJOR fix ~15m · Rebases ×2 + PR ~6m · **Total ~138m.** Bottleneck: the critic round (time well spent — it prevented paid wrong-style generations).

## Fix-up metrics
- Pre-merge catches: 4d (adversarial) 1, 4c (CodeRabbit) 1. Iterations: 2 (normal). Taxonomy: correctness 2.

## Planning quality
- Description complete: isDefault byte-identity gate, palette-ref leak analysis, 5-cap attachment invariant, prompt-honesty-equals-UI-honesty principle, LOC split.

## Recommendations (docket-closing)
1. Promote the cached-async/paid-click lens from "checklist item" to a **design-time rule** stated in the plan for any feature consuming async-resolved config: enumerate (a) the pending window and (b) the resolve-failure path for every paid/persisting action BEFORE implementing. 6/7 recurrence means catching it in review is already too late in the loop.
2. Pair prompt-wording fixes with an immediate sibling sweep across all prompt branches (from-scratch vs photo here) — same-file siblings are the cheapest sweep there is.
