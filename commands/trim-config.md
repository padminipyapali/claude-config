---
description: Scan ~/.claude/ config files for bloat and trim them down
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion
---

Scan the ~/.claude/ configuration files for bloat and compress them. Run this when the CLAUDE.md performance warning appears or periodically to keep config lean.

## Targets (check in order)

1. **~/.claude/CLAUDE.md** — the highest-impact file (loaded every conversation)
2. **~/.claude/projects/*/memory/MEMORY.md** — per-project auto-memory files
3. **~/.claude/knowledge/*.md** — topic files (loaded on-demand, lower priority)

## Analysis Phase

For each target file:

1. **Measure size.** Report current byte count. Flag if over threshold:
   - CLAUDE.md: warn at 35KB, critical at 40KB
   - MEMORY.md: warn at 150 lines (lines after 200 are truncated)
   - Knowledge files: warn at 50KB (context window pressure when loaded)

2. **Identify bloat categories:**
   - **Duplication:** Same rule/concept stated in multiple places. Grep for repeated phrases.
   - **Extractable detail:** Detailed procedures that could live in a knowledge file, referenced by a one-liner.
   - **Stale content:** Rules referencing PRs/features that no longer exist, or patterns superseded by newer entries.
   - **Verbose prose:** Explanations that could be tighter without losing meaning.
   - **Redundancy with knowledge files:** Content in CLAUDE.md that's already covered in ~/.claude/knowledge/*.md topic files.

3. **Report findings.** For each file over threshold, show:
   - Current size vs threshold
   - Top 3 bloat categories with estimated savings
   - Suggested actions (extract, deduplicate, trim, delete)

## Action Phase

Ask the user which approach to take:
- **Auto-fix:** Apply all suggested compressions automatically
- **Interactive:** Walk through each finding and ask before changing
- **Report only:** Just show the analysis, don't change anything

### Compression Techniques (apply in order)

1. **Deduplicate.** Find rules stated 2+ times. Keep one canonical instance, replace others with a reference.
2. **Extract procedures.** Move detailed how-to procedures (>20 lines) to ~/.claude/knowledge/ and replace with a stub + reference in CLAUDE.md.
3. **Trim PR examples.** War stories ("PR #NNN did X") are useful context but verbose. Compress to one-liners or cut if the rule is self-explanatory.
4. **Merge overlapping sections.** Sections covering the same topic from different angles should be consolidated.
5. **Prune stale entries.** In MEMORY.md: remove project entries for repos that no longer exist. In knowledge files: remove patterns that have been superseded.

### After Changes

1. Verify no rules were lost — do a before/after diff and confirm every rule in the original has a counterpart.
2. Update ~/.claude/knowledge/INDEX.md if new knowledge files were created.
3. Report final sizes and savings.
4. Commit and push changes to the claude-config repo.
