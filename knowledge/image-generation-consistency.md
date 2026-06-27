# AI Image Generation — Multi-Image Consistency

Patterns for making a *set* of independently-generated images (storybook pages, character sheets, a
themed asset pack) read as **one coherent body of work**. Extracted from the Plush Press storybook
pipeline (2026-06). Detailed, project-specific version: that repo's `prompts/gemini-playbook.md`
(lessons 10–14).

## The core insight: consistency is mostly a COLOR-GRADE problem, not a prompting problem

Independent diffusion generations have **irreducible per-image variance** — you cannot prompt two
images into the same color cast, and re-generating "to match" just reintroduces drift. But the things
that make a set look inconsistent — **daylight warmth, saturation, overall color cast** — are *global,
linear* properties. Fix them deterministically in post:

- **Warmth / white-balance:** per-channel linear scale. In `sharp`: `.linear([1+a, 1, 1-a])` warms
  (a>0 boosts R, cuts B); negative cools. Measure each image's mean `R−B`, pull all toward one target.
- **Saturation:** a Rec709 *saturate* matrix via `.recomb()` (same matrix SVG `feColorMatrix
  type="saturate"` uses). Measure each image's mean saturation `(max−min)/max`, normalize toward a
  shared target.
- Pick the target from **one reference image** (or the operator's favorite spread), not a global mean —
  averaging across different content (e.g. an interior vs. a forest) over-corrects.
- A uniform **vignette** (e.g. radial cream gradient) composited on every image is a second cheap
  unifier.

This closed a facing-spread that jumped from pale-sepia to vivid-green almost entirely, where
regeneration had failed for many rounds.

## Split the fix by AXIS

| Inconsistency | Fix |
|---|---|
| Warmth, saturation, daylight cast | **Deterministic grade** (above) — reproducible, no variance |
| Pencil grain / gloss / smoothness | **Regenerate** with an on-model image attached as a texture anchor |
| Wrong season / props / background | **Regenerate** (content change) |
| Off-model face / expression | **Regenerate** with an on-model face reference |

Don't grade your way out of a texture or likeness problem; don't re-roll a whole image for a color cast.

## Review at scale: judge panel + adversarial spread-verify

- **Pick** the best candidate per image with a panel of N independent vision judges (majority vote);
  back the vote with cheap deterministic stats (saturation/hue closeness) when "converge two images" is
  the goal.
- **Verify** with adversarial skeptics (default-to-flag), **one per *facing pair*** — seams live at the
  gutter, so verify adjacent pairs, not single images. Tell verifiers the *intended* look ("cool/muted
  on purpose") so they don't flag the deliberate grade.
- **Blind spot:** vision judges reliably catch color/texture/cast seams but **miss off-model
  faces/expressions**. Keep a human pass for character faces.

## Hand subjective grading to the operator — WYSIWYG

"How warm / how saturated should the whole thing be" is the human's call. Build a self-contained HTML
tuner with per-image **and** global warmth + saturation sliders. Make the preview transform the
**identical math** you bake with: SVG `feColorMatrix` (warmth = R/B channel-scale matrix; saturation =
`type="saturate"`) in the browser ⇄ `sharp` `.linear` + `.recomb()` Rec709 saturate at bake time. Same
numbers in → same pixels out. Inline thumbnails as base64 data-URIs so a `file://` canvas/filter isn't
cross-origin-tainted. Operator exports per-image values → you bake at full res.

## Generation tactics that help consistency

- **best-of-N is mandatory** (per-image variance); a single generation is a draw, not a verdict.
- **Attach a style/texture/identity anchor** image at generation — reference-conditioning beats words.
- To make two images **"meet in the middle,"** attach BOTH + an explicit midpoint-palette description,
  generate best-of-N each, pick the convergent pair by stats *and* eye, then a final deterministic grade.
- Use the **newest** image model; a stale model ID can make a whole class of edits impossible.

## Tooling notes

- **`sharp`** does all the deterministic work (`.linear`, `.recomb`, `.modulate`, `.composite` for
  vignettes, `.stats`/raw for measuring warmth+saturation).
- **Dependency-free PDF:** embed one JPEG per page via `/Filter /DCTDecode` (JPEG bytes drop straight
  into a PDF stream; PNG needs Flate+predictors). Validate with `qlmanage -t -s 500 -o <dir> file.pdf`
  (macOS Quick Look = the Preview renderer) — a thumbnail means the xref offsets are correct.
- A reusable **HTML review gallery** (★ favorite + comment + "copy summary") makes operator picks fast.
