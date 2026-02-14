Capture a new learning and add it to the appropriate location in the knowledge base.

The user will describe a learning, bug pattern, decision, or preference. Your job:

1. **Determine scope.** Is this:
   - A cross-project pattern (goes in `~/.claude/knowledge/*.md` topic file)? → This is the most common case.
   - A concise universal rule (goes in `~/.claude/CLAUDE.md`)? → Only if it's a one-liner that applies to literally every project.
   - A project-specific rule (goes in the project's own CLAUDE.md)?

2. **Match to topic.** Read `~/.claude/knowledge/INDEX.md` to find the right topic file. If none fits, create a new topic file and update INDEX.md.

3. **Check for duplicates.** Read the target file. Is this pattern already captured? If so, does the existing version need updating or strengthening?

4. **Write it.** Add the learning to the correct file in the correct section. Use the existing format: concise, actionable, one-liner when possible. Include the "why" if it's not obvious. Add a source attribution comment at the bottom if the pattern came from a specific project.

5. **Confirm.** Show what was added and where.
