# Color Palettes for Web Projects

Generated using OKLCH perceptual uniformity principles. Reference tool: [kigen.design/color](https://kigen.design/color)

Use these as starting points for `/frontend-design` and `/mockup` work. Each palette has a primary, accent, neutral, success, warning, and error scale.

---

## Palette 1: "Ember & Slate"
Warm, editorial feel. Good for content-heavy sites, dashboards, tools.

| Role | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
|------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| **Primary (Terracotta)** | `#fdf4f0` | `#fbe5db` | `#f6c8b4` | `#f0a586` | `#e87f57` | `#d4613a` | `#b34a2a` | `#8f3a20` | `#6b2c18` | `#4a1e10` | `#2d120a` |
| **Accent (Teal)** | `#f0fafb` | `#d4f1f4` | `#a3e0e8` | `#6ccad6` | `#3aafbf` | `#2493a3` | `#1d7785` | `#175c67` | `#12444c` | `#0d2f34` | `#081c1f` |
| **Neutral (Warm Gray)** | `#fafaf8` | `#f0efec` | `#dddbd6` | `#c4c1ba` | `#a8a49c` | `#8c877e` | `#716c64` | `#58544d` | `#413e38` | `#2b2926` | `#1a1917` |

### CSS Variables
```css
:root {
  --primary-50: oklch(97.5% 0.015 45);
  --primary-100: oklch(93% 0.035 45);
  --primary-200: oklch(84% 0.07 45);
  --primary-300: oklch(75% 0.11 40);
  --primary-400: oklch(65% 0.145 35);
  --primary-500: oklch(55% 0.155 32);
  --primary-600: oklch(46% 0.14 30);
  --primary-700: oklch(38% 0.11 28);
  --primary-800: oklch(31% 0.08 26);
  --primary-900: oklch(24% 0.055 24);
  --primary-950: oklch(18% 0.035 22);

  --accent-50: oklch(97% 0.015 200);
  --accent-100: oklch(93% 0.035 195);
  --accent-200: oklch(86% 0.065 195);
  --accent-300: oklch(77% 0.09 192);
  --accent-400: oklch(68% 0.1 190);
  --accent-500: oklch(59% 0.095 190);
  --accent-600: oklch(50% 0.08 188);
  --accent-700: oklch(42% 0.065 186);
  --accent-800: oklch(34% 0.05 184);
  --accent-900: oklch(26% 0.035 182);
  --accent-950: oklch(19% 0.02 180);

  --neutral-50: oklch(98% 0.005 80);
  --neutral-100: oklch(95% 0.008 80);
  --neutral-200: oklch(89% 0.01 75);
  --neutral-300: oklch(81% 0.012 70);
  --neutral-400: oklch(72% 0.013 65);
  --neutral-500: oklch(63% 0.013 60);
  --neutral-600: oklch(53% 0.012 55);
  --neutral-700: oklch(43% 0.01 50);
  --neutral-800: oklch(34% 0.008 45);
  --neutral-900: oklch(25% 0.006 40);
  --neutral-950: oklch(18% 0.004 35);
}
```

---

## Palette 2: "Indigo Dusk"
Deep, modern, slightly moody. Good for SaaS products, dev tools, creative apps.

| Role | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
|------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| **Primary (Deep Indigo)** | `#f4f3ff` | `#e8e5ff` | `#cec8ff` | `#b0a5ff` | `#8f7fff` | `#7161e6` | `#5a49c4` | `#45389a` | `#332a72` | `#231d4d` | `#15112e` |
| **Accent (Amber)** | `#fffcf0` | `#fff6d4` | `#ffeba3` | `#ffdd6c` | `#f5ca3a` | `#d9af24` | `#b3901d` | `#8a6f17` | `#645112` | `#42360c` | `#272008` |
| **Neutral (Cool Gray)** | `#f9f9fb` | `#ededf2` | `#dcdce4` | `#c3c3cf` | `#a7a7b6` | `#8b8b9b` | `#6f6f7e` | `#565663` | `#3f3f4a` | `#2a2a33` | `#19191f` |

### CSS Variables
```css
:root {
  --primary-50: oklch(97% 0.02 285);
  --primary-100: oklch(93% 0.04 285);
  --primary-200: oklch(84% 0.085 280);
  --primary-300: oklch(75% 0.13 278);
  --primary-400: oklch(64% 0.17 275);
  --primary-500: oklch(54% 0.17 273);
  --primary-600: oklch(45% 0.155 270);
  --primary-700: oklch(37% 0.125 268);
  --primary-800: oklch(30% 0.095 265);
  --primary-900: oklch(23% 0.065 262);
  --primary-950: oklch(17% 0.04 260);

  --accent-50: oklch(99% 0.015 95);
  --accent-100: oklch(96% 0.04 95);
  --accent-200: oklch(93% 0.09 92);
  --accent-300: oklch(88% 0.14 88);
  --accent-400: oklch(83% 0.155 85);
  --accent-500: oklch(76% 0.145 82);
  --accent-600: oklch(66% 0.125 78);
  --accent-700: oklch(55% 0.1 75);
  --accent-800: oklch(44% 0.075 72);
  --accent-900: oklch(33% 0.05 68);
  --accent-950: oklch(24% 0.03 65);
}
```

---

## Palette 3: "Forest & Copper"
Natural, grounded. Good for wellness, sustainability, lifestyle brands.

| Role | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
|------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| **Primary (Forest Green)** | `#f2f8f4` | `#ddeee2` | `#b5d9c0` | `#88c09a` | `#5da576` | `#448a5c` | `#357049` | `#2a5839` | `#20412b` | `#172d1e` | `#0d1b12` |
| **Accent (Copper)** | `#fdf6f1` | `#fae8d8` | `#f3ccac` | `#e9ab7c` | `#dc884e` | `#c46e35` | `#a2582a` | `#7d4421` | `#5c3219` | `#3e2211` | `#25140a` |
| **Neutral (Stone)** | `#faf9f7` | `#f0eee9` | `#dedad3` | `#c5c0b6` | `#aaa498` | `#8e887c` | `#726d62` | `#58534a` | `#403c35` | `#2b2823` | `#1a1815` |

### CSS Variables
```css
:root {
  --primary-50: oklch(97% 0.015 155);
  --primary-100: oklch(93% 0.035 155);
  --primary-200: oklch(85% 0.065 155);
  --primary-300: oklch(76% 0.09 155);
  --primary-400: oklch(66% 0.1 155);
  --primary-500: oklch(56% 0.095 155);
  --primary-600: oklch(47% 0.08 155);
  --primary-700: oklch(39% 0.065 155);
  --primary-800: oklch(31% 0.05 155);
  --primary-900: oklch(24% 0.035 155);
  --primary-950: oklch(17% 0.02 155);

  --accent-50: oklch(97.5% 0.015 60);
  --accent-100: oklch(93% 0.035 55);
  --accent-200: oklch(85% 0.075 50);
  --accent-300: oklch(76% 0.11 45);
  --accent-400: oklch(67% 0.135 40);
  --accent-500: oklch(58% 0.13 38);
  --accent-600: oklch(49% 0.11 35);
  --accent-700: oklch(40% 0.085 33);
  --accent-800: oklch(33% 0.06 30);
  --accent-900: oklch(25% 0.04 28);
  --accent-950: oklch(18% 0.025 25);
}
```

---

## Palette 4: "Midnight Rose"
Bold, high-contrast. Good for creative portfolios, fashion, entertainment.

| Role | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
|------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| **Primary (Rose)** | `#fff4f6` | `#ffe4ea` | `#ffc5d2` | `#ffa0b5` | `#f57593` | `#e05274` | `#c23a5b` | `#9c2d48` | `#752236` | `#4f1725` | `#300e17` |
| **Accent (Gold)** | `#fdfaf0` | `#faf2d2` | `#f3e19e` | `#eacd65` | `#deb638` | `#c29c24` | `#9f7f1e` | `#7a6218` | `#584712` | `#3b2f0c` | `#231c07` |
| **Neutral (Deep Charcoal)** | `#f8f8fa` | `#ebebf0` | `#d8d8e0` | `#bfbfc9` | `#a3a3b0` | `#878795` | `#6b6b78` | `#52525d` | `#3c3c44` | `#28282e` | `#18181c` |

### CSS Variables
```css
:root {
  --primary-50: oklch(97.5% 0.015 0);
  --primary-100: oklch(93% 0.04 355);
  --primary-200: oklch(85% 0.08 350);
  --primary-300: oklch(76% 0.12 348);
  --primary-400: oklch(65% 0.155 345);
  --primary-500: oklch(55% 0.16 343);
  --primary-600: oklch(46% 0.15 340);
  --primary-700: oklch(38% 0.12 338);
  --primary-800: oklch(30% 0.085 336);
  --primary-900: oklch(23% 0.055 334);
  --primary-950: oklch(17% 0.035 332);
}
```

---

## Semantic Colors (shared across all palettes)

```css
:root {
  --success-500: oklch(62% 0.14 145);
  --success-600: oklch(52% 0.12 145);
  --warning-500: oklch(80% 0.15 80);
  --warning-600: oklch(70% 0.14 78);
  --error-500: oklch(55% 0.2 25);
  --error-600: oklch(46% 0.18 24);
  --info-500: oklch(60% 0.12 240);
  --info-600: oklch(50% 0.11 238);
}
```

---

## Usage Notes

- **OKLCH is the source of truth.** HEX values are approximations for quick reference. Use the OKLCH values in CSS.
- **All palettes use the same lightness curve** — 97% at 50 down to ~17% at 950 — ensuring consistent contrast ratios across palettes.
- **To customize:** Adjust the hue angle in OKLCH to shift the palette while keeping perceptual uniformity. Adjust chroma to make colors more vivid or muted.
- **Kigen tool:** Use [kigen.design/color](https://kigen.design/color) to fine-tune individual scales with the Tailwind algorithm and OKLCH output.
- **Dark mode:** Invert the scale (950 becomes background, 50 becomes text). The perceptual uniformity means contrast ratios hold in both directions.
