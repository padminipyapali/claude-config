# Post-mortem: second-brain PR #609

**Title:** feat(morning-brief): show due-today only with project name prefix
**Branch:** feat/morning-brief-due-only → main
**Merged:** 2026-05-06T14:05:14Z (~18m to merge)
**Author/Merger:** padminipyapali (self-merge)
**Size:** +157 / -19 across 4 files, 1 commit
**Closes:** #602

## Change summary

- Telegram morning brief and `/brief` show only Due Today TODOs when any exist; Open is fallback when none.
- Project-linked TODOs prefixed with `[Project Title]` (HTML-escaped, no linkification).
- Added optional/nullable `TodoMatch.projectName` field; `findTodosForDate` and `findAllOpenTodos` LEFT JOIN `projects` (column `title`).
- Both `buildMorningBrief` and `buildDailyBrief` apply the rule. Past-date `/brief` unchanged (Open gated behind `isToday`).

## Local review

Not annotated in PR body — third consecutive second-brain PR (#603, #606, #609) without `## Local Review` or `Steps skipped:`.

## Review friction

- 1 round, 0 inline comments, 0 human comments. Self-merge.
- Only Vercel preview check ran (Ignored — server-only diff). No required test gate visible in CI rollup.

## Adversarial review effectiveness

Critic agent ran pre-push (orchestrator pattern). All 14 checklist items returned PASS, including:
- Sibling sweep on `TodoMatch` consumers (6 callers, none broken by optional field).
- Both `buildMorningBrief` and `buildDailyBrief` correctly skip Open when due-today non-empty.
- HTML escape verified with `&` and `<` in tests.
- LEFT JOIN does not introduce cross-user leakage (existing `WHERE e.user_id = $1` retained; project-FK constraint prevents cross-user assignment).
- Past-date `/brief` Open-suppression preserved via `isToday` gate.

Critic also flagged a stale-base artifact: branch was created before #603 merged, so its diff appeared to remove `.brand { line-height: 1 }`. Orchestrator rebased onto current main; final diff was server-only.

## Captured patterns

1. **Optional join-derived field.** `T?: V | null` for fields sourced from a `LEFT JOIN` that not all consumers invoke. Optional in type → non-joining callers don't change. Nullable → faithful representation of LEFT JOIN absence.
2. **Escape-but-don't-linkify for label fields.** `escapeHtml` only — never `formatLinksHtml` — for project titles, identifiers, or any non-prose label, to prevent accidental linkification of URL-shaped names.
3. **Stale-branch rebase before opening PR.** When parallel branches exist, the orchestrator must `git fetch origin main` and rebase if main moved during the implementer's work. The diff against origin/main is the test — if it touches files the branch never modified, rebase first.

## Recommendations

1. **Promote `## Local Review` / `Steps skipped:` to a PR template.** Three consecutive second-brain PRs (#603, #606, #609) merged without these annotations. Per the family-digest #12 escalation rule (knowledge/process-patterns.md), this should be converted from prose recommendation to artifact: `.github/PULL_REQUEST_TEMPLATE.md`.
2. **Add explicit "rebase if base diverged" step to dev flow Step 5.** Solo-dev parallel branches hit this on every concurrent PR.
3. **Add Performance & Cost Impact section to PR template.** This PR added a `LEFT JOIN` to two hot-path queries (cron brief + on-demand `/brief`); negligible at single-user scale on indexed FK, but the section is required by global CLAUDE.md.
4. **Confirm `npm test` is a required CI check** for server-touching PRs — server diff cannot lean on Vercel preview.
5. **Capture the optional-join-derived-field pattern** in `~/.claude/knowledge/database-patterns.md`.
6. **Capture escape-but-don't-linkify-for-label-fields rule** in `~/.claude/knowledge/typescript-patterns.md` or LLM-integration patterns.

## Key finding

Three-strikes Local Review tracking gap is now confirmed across #603, #606, #609. The existing process-patterns.md "three consecutive ignored recommendations" rule mandates artifact conversion at this point — the next prose-only restatement would violate that rule.
