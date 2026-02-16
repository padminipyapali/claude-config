---
description: Generate a technical flow diagram as a self-contained HTML file in docs/features/
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Task
argument-hint: [feature name or description]
---

Generate a technical flow diagram for a multi-component feature. Flow diagrams are self-contained HTML files stored in `docs/features/<feature-name>/flow-diagram.html`.

## When to Create Flow Diagrams

Flow diagrams are for features that span **multiple components, systems, or vendors**. Examples:
- Email forwarding (Cloudflare → Worker → Backend → DB → Telegram + Dashboard)
- Payment processing (Client → API → Stripe → Webhooks → DB)
- CI/CD pipelines (Git push → GitHub Actions → Build → Deploy → Notify)
- Real-time sync (Client → WebSocket → Server → DB → Other clients)

Do NOT create flow diagrams for:
- Single-component features (a new React component, a utility function)
- Simple CRUD routes with no external dependencies
- UI-only changes

## Steps

1. **Understand the feature.** If `$ARGUMENTS` is provided, use it as the feature name/description. Otherwise, ask the user what feature to diagram. Then:
   - Search the codebase for all files involved in this feature.
   - Trace the full data flow end-to-end: entry point → processing → storage → outputs.
   - Identify all external systems, vendors, and protocols involved.
   - Map error handling and failure modes at each step.

2. **Check for existing diagrams.** Look at `docs/features/` to:
   - See if a diagram already exists for this feature (offer to update if so).
   - Maintain visual consistency with other flow diagrams in the project.

3. **Derive the feature directory name.** Use kebab-case, matching the feature's common name (e.g., `email-forwarding`, `payment-processing`, `real-time-sync`). If ambiguous, ask the user.

4. **Generate the flow diagram.** Create `docs/features/<feature-name>/flow-diagram.html` with:
   - All CSS inlined in a `<style>` tag (no external dependencies).
   - Dark theme with clear visual hierarchy — use colored step numbers, connector arrows, and cards.
   - **Step-by-step flow cards** showing each stage: what happens, where the code lives (file paths), key technical details.
   - **Processor/pipeline breakdowns** when a step has sub-steps (e.g., middleware chains, pipeline stages).
   - **Destination cards** when the flow fans out to multiple outputs (e.g., DB + Telegram + Dashboard).
   - **Technologies & Vendors section** — a grid of cards, one per external technology or vendor used in the feature. Each card includes: name, role tag (e.g., "Edge Compute", "Database", "Library"), a short description of how it's used in this feature, and **relevant links** (official docs, dashboard URLs, API references, npm/GitHub pages). This section is mandatory.
   - **Security/auth callout** if the feature involves authentication, signing, or access control.
   - **Failure mode table** showing what happens when each component fails — this is critical for the user's understanding.
   - Responsive design (works on mobile).
   - File path references throughout so the user can jump to the relevant code.

5. **Design principles for flow diagrams:**
   - **Explain the "why", not just the "what"** — don't just say "Worker parses email", explain WHY it uses HMAC signing and what that prevents.
   - **Show the full chain** — from the very first trigger (DNS, HTTP request, user action) to the final outputs.
   - **Include failure modes** — a flow diagram that only shows the happy path is incomplete.
   - **Reference actual file paths** — the diagram should serve as a navigation guide to the code.
   - **Use realistic examples** — show actual domain names, actual payload shapes, actual error codes.
   - **Link to vendor docs** — the Technologies section should make it easy to look up how each vendor/library works.

6. **Report to the user:**
   - File path created.
   - How to open it (`open docs/features/<feature-name>/flow-diagram.html`).
   - Summary of the flow stages covered.
   - Any gaps or areas where the flow could be more resilient.

## Output Structure

```
docs/features/<feature-name>/
└── flow-diagram.html    # Self-contained diagram (inline CSS + JS)
```

## Visual Style Guide

- **Background:** Dark theme (dark navy/charcoal) — easier on the eyes for technical diagrams.
- **Step cards:** Numbered with colored badges, containing title, subtitle (file path), and description.
- **Connectors:** Vertical lines with arrows between steps.
- **Sub-steps:** Grid of smaller cards within a step (e.g., pipeline processors).
- **Fan-out:** Side-by-side destination cards when the flow splits.
- **Tech cards:** Grid of vendor/technology cards with role tags, descriptions, and doc links.
- **Callouts:** Bordered boxes for security, performance, or architecture notes.
- **Failure table:** Grid showing failure point → behavior pairs.
- **Typography:** System fonts, monospace for file paths and code references.
