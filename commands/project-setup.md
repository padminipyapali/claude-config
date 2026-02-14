Bootstrap a new project with the standard documentation structure, Claude Code configuration, and relevant cross-project knowledge.

## Steps

1. **Ask the user** about:
   - Project name and description.
   - Tech stack (to populate the CLAUDE.md and match knowledge topics).
   - Whether to set up the adversarial review hook.

2. **Create docs directory** with empty templates:
   - `docs/BUGS.md` — Header + empty template for bug entries (Description, Root Cause, Fix, Lesson).
   - `docs/DECISIONS.md` — Header + note to log decisions from human-Claude discussions.
   - `docs/PRODUCT_SPEC.md` — Header + sections for project overview, features, and architecture.
   - `docs/QA.md` — Header + note for technical Q&A.

3. **Inject relevant cross-project knowledge.** Read `~/.claude/knowledge/INDEX.md` and match the declared stack against available topic files using the Stack Matching Guide. For each matching topic file:
   - Read the file.
   - Extract the most critical patterns (top 5-10 per topic) relevant to the new project's stack.
   - Include them in the project CLAUDE.md under a "Key Patterns from Cross-Project Knowledge" section, with references back to the full topic files.

4. **Create project CLAUDE.md** with:
   - A note that global rules from `~/.claude/CLAUDE.md` apply.
   - Sections for: Development Workflow, Project Structure, Tech Stack.
   - Pre-PR checks specific to the project's build system.
   - Any project-specific coding conventions.
   - **Key Patterns section** (from step 3) — the most relevant cross-project patterns, with pointers to the full `~/.claude/knowledge/*.md` files for deeper reference.
   - Pre-PR Adversarial Review section referencing `~/.claude/knowledge/adversarial-review.md`.

5. **Create .claude/ directory** with:
   - `settings.json` if the adversarial review hook is enabled.
   - Copy `require-adversarial-review.sh` hook from an existing project or create from template.
   - If adversarial review is enabled, create `.claude/skills/adversarial-review/SKILL.md` that references the shared checklist at `~/.claude/knowledge/adversarial-review.md` and includes project-specific checks.

6. **Initialize auto-memory.** Create the project's memory directory structure:
   - Determine the workspace path encoding for `~/.claude/projects/<encoded-path>/memory/`.
   - Create `MEMORY.md` with the project name, stack, and a note to populate during development.

7. **Summarize** what was created and report:
   - Files created (docs, CLAUDE.md, hooks, skills).
   - Knowledge topics injected and how many patterns were included.
   - Remind the user that:
     - The adversarial review will automatically capture learnings at PR time.
     - `/consolidate-learnings` can be run periodically as a safety net.
     - The shared knowledge at `~/.claude/knowledge/` will be loaded automatically when planning features.
