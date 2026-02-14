---
description: Scan all projects and consolidate new patterns into shared knowledge
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Scan all projects under ~/dev/ for learning documents and consolidate new patterns into the shared knowledge base.

## Steps

1. **Check last consolidation.** Read `~/.claude/knowledge/.last-consolidated` if it exists. Note the timestamp — only process files modified after this date. If the file doesn't exist, process everything.

2. **Find all project docs.** Glob for `**/docs/BUGS.md`, `**/docs/DECISIONS.md`, `**/CLAUDE.md` under ~/dev/. Also read auto-memory files in `~/.claude/projects/*/memory/`. If a `.last-consolidated` timestamp exists, focus on files modified after that date (check with `stat` or `git log --since`).

3. **Read the current knowledge base.** Read `~/.claude/knowledge/INDEX.md` and all topic files listed there. Also read `~/.claude/CLAUDE.md`.

4. **Extract new patterns.** For each bug, decision, or rule found in project docs:
   - Is this pattern already captured in a knowledge topic file or global CLAUDE.md? If yes, skip.
   - Is this pattern project-specific (only applies to one project's unique architecture)? If yes, skip.
   - Is this a generalizable pattern that would help in future projects? If yes, capture it.

5. **Categorize and place.** Each new pattern goes to the correct location:
   - **`~/.claude/knowledge/*.md` topic files** — Detailed, actionable patterns organized by topic (this is the PRIMARY target).
   - **`~/.claude/CLAUDE.md` universal sections** — Only for concise, high-signal rules that apply to literally every project.
   - **`~/.claude/CLAUDE.md` "When Applicable" sections** — Only for concise stack-specific rules not already covered.
   - New topic files can be created if a pattern doesn't fit existing topics (update INDEX.md).

6. **Propose changes.** Show a summary table:
   | Source | Pattern | Target File | Section | Why |
   Then apply the changes after confirmation.

7. **Check for stale rules.** Flag any rules in the knowledge base that may be outdated based on recent project decisions or contradicted by newer learnings.

8. **Check for missing project memory.** For each project under ~/dev/, verify that `~/.claude/projects/<workspace>/memory/MEMORY.md` exists and is non-empty. Flag any projects with empty or missing auto-memory as a gap.

9. **Update the timestamp.** Write the current date to `~/.claude/knowledge/.last-consolidated`:
   ```bash
   date -u +"%Y-%m-%dT%H:%M:%SZ" > ~/.claude/knowledge/.last-consolidated
   ```

10. **Report.** Summarize:
    - Patterns added (count, by topic file)
    - Stale rules flagged
    - Projects with missing memory
    - Next recommended action
