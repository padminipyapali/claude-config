---
name: review-fix
description: Read PR review comments, validate them, fix the issues, and run adversarial review before pushing
allowed-tools: Read, Grep, Bash, Edit, Write, Glob, Task
argument-hint: "[pr-number]"
---

# Fix PR Review Comments

Automatically read code review comments on PR `$ARGUMENTS`, validate them, fix the issues, run adversarial review, and push.

## Steps

### 1. Fetch Review Comments

Read all review comments from the PR:

```bash
gh pr view $ARGUMENTS --comments
gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/reviews
gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/comments
```

Parse out:
- File path and line number for each comment
- The requested change description
- Whether it's a blocking "request changes" or a suggestion

### 2. Validate Each Comment

For each review comment:
- Read the referenced file and line range
- Assess whether the comment is valid (security issue, bug, correctness, style, etc.)
- Categorize: **must fix** (security, correctness, data integrity) vs **should fix** (style, DRY, performance) vs **disagree** (explain why)
- Report your assessment to the user before proceeding

### 3. Fix the Issues

Spin off a background `general-purpose` agent with `bypassPermissions` mode. Include ALL of the following in the agent prompt:

- Check out the PR branch
- For each validated comment, describe the exact fix needed with file path, line numbers, and the review comment text
- Add/update tests if the fix changes behavior
- Run `npm run build` and `npm test` — all must pass

**CRITICAL: Include the full adversarial review checklist:**
- User scoping on ALL DB queries (WHERE user_id = $X)
- No raw user content in console.log/console.error statements
- Try/catch granularity matches existing graceful degradation patterns
- Walk full access chains for null/undefined guards
- LLM output parsing: code fences stripped, empty responses handled
- Index coverage for new query patterns
- Grep for pattern siblings of the same bug class across the codebase
- Type sync between SQL and TypeScript — every TEXT column backed by a TS union must have a CHECK constraint
- Shell command validation: regex bypass via prefix/suffix injection, extracted variable validation
- Bash variable validation: empty strings in path construction or comparisons
- State timing and directory context: marker writes after commits, `git -C` for correct repo
- Error message specificity: edge-case fallthroughs should return specific messages, not generic errors

Report any ADDITIONAL issues found during the adversarial review that weren't in the original comments, and fix those too.

- Commit the fixes: `git commit -m "Address PR review: <brief summary of changes>."`
- Write the adversarial review marker AFTER the commit (marker lives OUTSIDE the repo): `PROJECT_HASH=$(echo -n "$PWD" | md5 -q 2>/dev/null || echo -n "$PWD" | md5sum 2>/dev/null | cut -d' ' -f1) && mkdir -p "$HOME/.claude/review-markers" && git rev-parse HEAD > "$HOME/.claude/review-markers/$PROJECT_HASH"`
- Push to the branch

### 4. Report Results

After the agent finishes:
- Summarize all changes made
- List any additional issues found during adversarial review
- Note any review comments that were intentionally not addressed (with reasoning)
- Provide the PR URL for re-review

### 5. Extract Learnings to Shared Knowledge Base

After fixing issues, extract durable lessons from the **valid** PR comments into the shared knowledge base at `~/.claude/knowledge/`. PR review comments are one of the highest-signal sources of cross-project learnings — this step is not optional.

**For each valid PR comment that was fixed**, evaluate:

1. **Is this a generalizable pattern?** Would this same mistake be possible in another project with a similar stack? If yes → add to the matching `~/.claude/knowledge/*.md` topic file.
2. **Is this a new adversarial review check?** Does it reveal a bug class not covered by the existing checklist? If yes → add to `~/.claude/knowledge/adversarial-review.md` under the appropriate tier.
3. **Is this project-specific only?** If the pattern only applies to this project's unique architecture → update only the project CLAUDE.md.

**Procedure:**

1. Read `~/.claude/knowledge/INDEX.md` to identify which topic file(s) match the pattern (e.g., TypeScript async issue → `typescript-patterns.md`, missing DB index → `database-patterns.md`, React state bug → `react-patterns.md`).
2. Read the target topic file(s) and check for duplicates. If the pattern already exists, **strengthen** the existing entry with new context rather than adding a duplicate. If not present, add it.
3. Use the existing format in the topic file: concise, actionable, one-liner when possible. Include the "why" if it's not obvious.
4. Add a source comment: `<!-- Source: PR review, [project-name] #[PR-number], [date] -->`
5. If no existing topic file fits, create a new one and update `INDEX.md`.

**Also update project-level docs as applicable:**

- **Project CLAUDE.md**: If the comment reveals a missing or under-specified rule in the adversarial review checklist or code style section.
- **`docs/BUGS.md`**: If the comment identified a bug — document root cause and lesson learned.
- **`docs/DECISIONS.md`**: If the comment led to an architectural or design decision.

**Report** what was captured: list each learning, which knowledge file it was added to, and whether it was new or strengthened an existing entry. Skip one-off fixes that have no cross-project value.
