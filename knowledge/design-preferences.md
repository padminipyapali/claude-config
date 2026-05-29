# Design Preferences

Padmini's preferred visual styles for generated HTML documents, mockups, and diagrams.

## Preferred Theme: Light Editorial

**Reference implementation:** `my_mind_evolved/docs/features/_cross-cutting/explainers/performance-optimizations.html`

**Confirmed:** Padmini loves this theme. Use it as the default for all HTML explainers, flow diagrams, and documentation pages.

### Palette

```css
--bg: #fafaf9;           /* warm off-white page background */
--surface: #ffffff;       /* card/box backgrounds */
--surface-alt: #f5f5f3;  /* table headers, alternate rows */
--border: #e8e6e1;       /* borders, dividers */
--border-light: #f0eeea; /* subtle inner borders */
--text: #1a1a1a;         /* primary text */
--text-secondary: #6b6560; /* descriptions, body copy */
--text-tertiary: #9b958e;  /* labels, captions */
--accent: #b85c38;       /* terracotta — primary accent */
--accent-light: #f5ebe4; /* accent backgrounds */
--green: #3a7d5c;        /* success, improvements */
--green-light: #e8f4ed;
--blue: #3b6b9a;         /* informational */
--blue-light: #e8f0f8;
--purple: #7b5ea7;       /* DB, technical */
--purple-light: #f0eaf8;
--orange: #c17a2f;       /* warnings, optimistic UI */
--orange-light: #faf0e0;
--teal: #3a8a7b;         /* secondary accent */
--teal-light: #e4f4f0;
--red: #b54a4a;          /* errors, "before" states */
--red-light: #fae8e8;
--code-bg: #f0eeea;      /* inline code background */
```

### Typography

- **Font stack:** `"Inter", "Helvetica Neue", Helvetica, Arial, sans-serif` — always sans-serif
- **Code font:** `"SF Mono", "Fira Code", "Consolas", monospace`
- **Hero title:** Light weight (300) with bold (700) emphasis on key word
- **Section headers:** Same light/bold pattern
- **Kicker labels:** Tiny uppercase, letter-spaced, colored with category accent
- **Body:** 1.7 line-height, `-webkit-font-smoothing: antialiased`

### Layout Principles

- **Max width:** 840px container, centered
- **Generous whitespace:** 56px between sections, 32px padding
- **Cards:** White background, 1px border, 12px border-radius, 28px/32px padding
- **Stat bar:** Grid of 4 highlight numbers at the top, separated by 1px gaps
- **Before/after splits:** Side-by-side boxes, red-tinted (before) and green-tinted (after)
- **Impact pills:** Small rounded badges in green for metrics
- **Flow diagrams:** Vertical timeline with colored dots and a thin connector line
- **Tables:** Minimal — no outer border, subtle row separators, uppercase headers
- **Pattern grids:** 2x2 grid of cards with numbered icons

### Color Coding by Category

Use consistent accent colors to identify domains:
- **Terracotta (accent):** Primary brand, general/UI
- **Green:** Search, success, improvements
- **Blue:** API, informational
- **Purple:** Database, technical infrastructure
- **Orange:** Optimistic UI, warnings
- **Teal:** Secondary features (thread panel, etc.)
- **Red:** Errors, "before" states in comparisons

### Tone

- Clean, magazine-like presentation
- Light and airy — never dark backgrounds
- Warm color palette (not cold/corporate blues)
- Editorial feel — like a well-designed technical article
- Restrained use of color — mostly white/cream with accent pops

## UX Principles

- **Empty states must be delightful and actionable.** Never leave a blank area or terse "No data" message. Include: (1) a clear message explaining what will appear, (2) a call-to-action guiding the next step (e.g., "Add your first vendor"), (3) optionally an illustration or icon to make it feel intentional. Empty states are the first thing new users see — they set the tone. <!-- Source: command-center dispatch dashboard, 2026-03 -->
- **Truncated text must have full-text access.** Any text clipped with `truncate`, `text-ellipsis`, or `overflow-hidden` needs a `title` attribute (tooltip), expandable click, or other mechanism to view the full content. <!-- Source: remodel-app room sidebar, also in react-patterns.md -->

## Motion & Interaction

- **Proximity interaction is the default for every website.** As the cursor nears interactive elements, nearby elements respond on a *gradient* of distance (scale / lift / brightness / glow) rather than a binary hover on/off. Padmini loves this — "every time we design a website I want this interaction design to be used" (confirmed 2026-05-29). Apply it to docks, card grids, nav lists, button clusters — anywhere with a cluster of interactive targets.

  **Rules that make it feel right (not gimmicky):**
  - Use **true distance**, not just `clientX`: 2D radial (`Math.hypot`) for grids/free layouts; horizontal (`|Δx|`) for docks; vertical (`|Δy|`) for lists/nav.
  - **Ease toward a target every frame** (lerp inside a `requestAnimationFrame` loop). Do NOT set styles directly inside `pointermove` — the easing is what gives motion weight.
  - **Smoothstep falloff** (`t*t*(3-2*t)`), not linear, so there's no hard pop at the influence-radius edge.
  - Respect `prefers-reduced-motion` (don't attach the effect under it). Reset styles on `pointerleave` / teardown. Use one shared pointer listener + one rAF loop for all targets; let the loop coast to an idle tick when nothing's animating.

  **Reusable helpers (vanilla `attachProximity` + React `useProximity`) and a verified demo:** `~/dev/proximity-interaction/` (`proximity.js`, `useProximity.js`, `demo.html`, `index.html`). Not in git — copy into the project, or pull from there. Core model: `distance → smoothstep → 0..1 influence → ease → visual props`.

  ```js
  // minimal vanilla core — drop into any project
  const smooth = t => (t = Math.max(0, Math.min(1, t)), t*t*(3-2*t));
  const lerp = (a,b,n) => a + (b-a)*n;
  const ptr = {x:-1e9,y:-1e9,inside:false};
  addEventListener("pointermove", e => { ptr.x=e.clientX; ptr.y=e.clientY; ptr.inside=true; });
  addEventListener("pointerleave", () => ptr.inside = false);
  const nodes = [...root.children].map(el => ({el, cur:0}));
  const RADIUS = 240, EASE = 0.18;
  (function frame(){
    for (const n of nodes){
      const r = n.el.getBoundingClientRect();
      const d = Math.hypot(ptr.x-(r.left+r.width/2), ptr.y-(r.top+r.height/2));
      const tgt = ptr.inside ? smooth(1 - d/RADIUS) : 0;
      n.cur = lerp(n.cur, tgt, EASE);
      n.el.style.transform = `translateY(${(-n.cur*8).toFixed(2)}px) scale(${(1+n.cur*0.12).toFixed(3)})`;
      n.el.style.filter = `brightness(${(1+n.cur*0.25).toFixed(3)})`;
    }
    requestAnimationFrame(frame);
  })();
  ```
  <!-- Source: proximity-interaction demo, 2026-05-29; verified in-browser via Playwright -->

