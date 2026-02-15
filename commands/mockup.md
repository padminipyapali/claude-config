---
description: Generate UI mockups as self-contained HTML files stored in docs/mockups/
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
argument-hint: [description of the UI to mock up]
---

Generate a UI mockup based on the user's free-form description. Mockups are self-contained HTML files stored in `docs/mockups/<subdirectory>/`.

## Steps

1. **Parse the description.** Extract:
   - What UI is being mocked up (page, component, flow, etc.).
   - Key elements and interactions described.
   - Any styling preferences or constraints mentioned.
   - Derive a short, kebab-case subdirectory name from the description (e.g., "login page with forgot password" → `login-page`). If ambiguous, ask the user.

2. **Check for existing mockups.** Look at `docs/mockups/` in the project root to understand:
   - Whether the directory exists (create it if not).
   - What mockups already exist (to maintain consistency in styling and naming).
   - Whether this is an update to an existing mockup (if a matching subdirectory exists, ask whether to update or create a new version).

3. **Check for project context.** Look for:
   - An existing design system, CSS variables, or theme files in the project — reuse colors, fonts, and spacing to keep mockups consistent with the actual app.
   - `docs/PRODUCT_SPEC.md` for feature context that might inform the mockup.
   - Other mockups in `docs/mockups/` to maintain visual consistency across mockups.

4. **Generate the mockup.** Create a self-contained HTML file (`index.html`) with:
   - All CSS inlined in a `<style>` tag (no external dependencies).
   - All JS inlined in a `<script>` tag if interactivity is needed.
   - Responsive design using modern CSS (flexbox/grid, clamp, media queries).
   - A clean, professional default aesthetic — use system fonts, sensible spacing, and a neutral color palette unless the project has an existing design system.
   - Realistic placeholder content (not "Lorem ipsum" — use plausible names, dates, text that reflects actual usage).
   - If the mockup represents a multi-step flow or multiple states, include all states in one file with navigation/tabs to switch between them.

5. **Create a README.md** in the subdirectory with:
   - A one-line summary of what's being mocked up.
   - **Description:** What the mockup shows and its purpose.
   - **Design decisions:** Key choices made (layout, color, interaction patterns) and why.
   - **States/views included:** List of all states or views in the mockup (if multi-state).
   - **Open questions:** Anything the user should decide on that wasn't specified.
   - **How to view:** `open docs/mockups/<subdirectory>/index.html` in a browser.

6. **Report to the user:**
   - File paths created.
   - How to open the mockup (`open docs/mockups/<subdirectory>/index.html`).
   - Summary of design decisions and any open questions.

## Output Structure

```
docs/mockups/<subdirectory>/
├── index.html    # Self-contained mockup (inline CSS + JS)
└── README.md     # Description, design decisions, open questions
```

## Guidelines

- **Self-contained:** Every mockup must work by opening the HTML file directly in a browser. No build steps, no external CDN links, no dependencies.
- **Realistic content:** Use plausible names, numbers, and text. "Jane Smith" not "User 1". "$142.50" not "$XX.XX".
- **Accessible:** Use semantic HTML, sufficient color contrast, and keyboard-navigable interactions.
- **Mobile-aware:** Include responsive breakpoints unless the user specifies desktop-only.
- **Consistent:** If other mockups exist in the project, match their visual style unless the user requests something different.
- **Subdirectory naming:** Use kebab-case, descriptive but concise. Examples: `user-dashboard`, `onboarding-flow`, `settings-page`, `search-results`.
