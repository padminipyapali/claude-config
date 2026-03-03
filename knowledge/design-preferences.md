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
