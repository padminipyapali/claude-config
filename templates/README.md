# Templates

Scaffolding files meant to be copied into projects. These are NOT auto-loaded or auto-executed.

## Files

- `css-interaction-regression.spec.ts` — Playwright regression tests for CSS property interactions that cause visual bugs. Uses `page.setContent()` with self-contained HTML/CSS fixtures (no dev server needed).
- `playwright.config.portable.ts` — Minimal Playwright config for headless Chromium testing. No webServer configured — tests use `page.setContent()` directly.

## Usage

1. Copy the relevant files into your project's test directory.
2. Install dependencies: `npm install -D @playwright/test && npx playwright install chromium`
3. Adjust paths and config as needed for the project structure.
