---
description: Scan all projects and consolidate new patterns into shared knowledge
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Scan all projects under ~/dev/ for learning documents and consolidate new patterns into the shared knowledge base.

## Steps

1. **Check last consolidation.** Read `~/.claude/knowledge/.last-consolidated` if it exists. Note the timestamp — only process files modified after this date. If the file doesn't exist, process everything.

2. **Find all project docs.** Glob for `**/docs/**/bugs.md`, `**/docs/**/decisions.md`, `**/CLAUDE.md` under ~/dev/. Also check `**/docs/features/*/` for feature-scoped docs. If a `.last-consolidated` timestamp exists, focus on files modified after that date (check with `stat`).

3. **Read the current knowledge base.** Read `~/.claude/knowledge/INDEX.md` and all topic files listed there. Also read `~/.claude/CLAUDE.md`.

4. **Extract new patterns from project docs.** For each bug, decision, or rule found in project docs:
   - Is this pattern already captured in a knowledge topic file or global CLAUDE.md? If yes, skip.
   - Is this pattern project-specific (only applies to one project's unique architecture)? If yes, skip.
   - Is this a generalizable pattern that would help in future projects? If yes, capture it.

5. **Scan MEMORY.md files for cross-project patterns.** This is a dedicated pass over auto-memory.

   a. **Collect all MEMORY.md files.** Glob for `~/.claude/projects/*/memory/MEMORY.md`. Read every file.

   b. **Classify each entry.** For every non-heading entry in each MEMORY.md, classify it as one of:
      - **Project basics** — project name, path, stack, repo URL, architecture notes specific to that one project. These STAY in MEMORY.md (they're what auto-memory is for).
      - **Already a pointer** — entries that reference `~/.claude/knowledge/` or say "consolidated into knowledge base." Skip these.
      - **Cross-project pattern candidate** — a rule, preference, convention, or lesson that is NOT project-specific and could apply to other projects. These are promotion candidates.
      - **Stale/obsolete** — entries about completed work, old in-progress items, or outdated context. Flag for cleanup.

   c. **Detect cross-project patterns.** Look for:
      - The same pattern appearing in 2+ project MEMORY.md files (even if worded differently).
      - A pattern from one project that matches an existing knowledge topic (e.g., a TypeScript lesson that belongs in typescript-patterns.md).
      - Workflow or tool preferences that apply globally (e.g., "always use X for Y").
      - Defensive coding or testing lessons learned from a specific bug but applicable broadly.

   d. **Check for duplicates against knowledge base.** For each candidate, grep the knowledge topic files and CLAUDE.md for similar content. If already captured, mark for pointer replacement only (no promotion needed, just cleanup).

6. **Categorize and place.** Each new pattern goes to the correct location:
   - **`~/.claude/knowledge/*.md` topic files** — Detailed, actionable patterns organized by topic (this is the PRIMARY target).
   - **`~/.claude/CLAUDE.md` universal sections** — Only for concise, high-signal rules that apply to literally every project.
   - **`~/.claude/CLAUDE.md` "When Applicable" sections** — Only for concise stack-specific rules not already covered.
   - New topic files can be created if a pattern doesn't fit existing topics (update INDEX.md).

7. **Propose changes.** Show a summary table with two sections:

   **Promotions from project docs:**
   | Source File | Pattern | Target File | Section | Why |

   **MEMORY.md promotions & cleanups:**
   | MEMORY.md File | Entry | Action | Target (if promoting) | Replacement |

   Actions: `promote` (move to knowledge + replace with pointer), `pointer` (already in knowledge, just replace with pointer), `cleanup` (stale entry, remove or update), `keep` (project-specific, no change).

   Wait for user confirmation before applying.

8. **Apply MEMORY.md replacements.** For each promoted or pointer-replaced entry:
   - Remove the original detailed entry from MEMORY.md.
   - Add a pointer in its place. Use this format:
     ```
     ## Cross-Project Knowledge
     [Topic] patterns consolidated into ~/.claude/knowledge/[file].md. Load relevant topic files via INDEX.md.
     ```
   - If a `## Cross-Project Knowledge` section with a pointer already exists, append to it rather than creating a duplicate section.
   - Keep project-specific entries (basics, architecture, decisions unique to that project) untouched.

9. **Check for stale rules.** Flag any rules in the knowledge base that may be outdated based on recent project decisions or contradicted by newer learnings.

10. **Check for missing project memory.** For each project under ~/dev/, verify that `~/.claude/projects/<workspace>/memory/MEMORY.md` exists and is non-empty. Flag any projects with empty or missing auto-memory as a gap.

11. **Update the timestamp.** Write the current date to `~/.claude/knowledge/.last-consolidated`:
    ```bash
    date -u +"%Y-%m-%dT%H:%M:%SZ" > ~/.claude/knowledge/.last-consolidated
    ```

12. **Report.** Summarize:
    - Patterns promoted from project docs (count, by topic file)
    - MEMORY.md entries promoted (count, by source project)
    - MEMORY.md entries replaced with pointers (count)
    - Stale entries cleaned up (count)
    - Projects with missing memory
    - Next recommended action
