# Post-Mortem: command-center PR #39 — Add project CRUD: SQLite store, REST API, and dynamic frontend wiring

**Branch:** feat/project-crud -> main | **Author:** padminipyapali | **Duration:** 0.9h
**Size:** +1315 -201 (1516 LOC) across 18 files, 3 commits
**Date merged:** 2026-02-26T16:00:20Z

---

## Local Review (pre-push)

| Tool | Findings | Fixed |
|------|----------|-------|
| Code simplifier | 10 | 4 |
| Internal review | 2 | 2 |
| CodeRabbit (local) | 16 | 6 |
| Adversarial review | 7 | 5 |
| **Total pre-push** | **35** | **17** |

Shift-left rate: **78%** (35 of 45 total issues caught locally).

Known v1 deferrals: COALESCE pattern for nullable fields (can't clear `relativePath` to NULL via COALESCE).

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4c, 4d, 5 (8/8)
- **Steps skipped:** none
- **Note:** Playwright browser testing skipped within step 3 (backend routes + data source change, no visual UI changes). Unit tests ran (227 tests, 14 files).
- **Compliance rate:** 100%
- **Skip assessment:** n/a

## Review Friction (post-push)

- **Review rounds:** 3 (0 CHANGES_REQUESTED, 3 COMMENTED from CodeRabbit)
- **Comments:** 11 inline, 2 general (1 Vercel deploy, 1 CodeRabbit walkthrough)
- **Human reviewers:** none (self-merge with bot-only review)
- **Categories:** correctness: 6, other: 4, performance: 1
- **Timeline:** created -> first review: 6 min | first review -> merge: 49 min | total: 54 min

## Adversarial Review Effectiveness

**Pre-push catch potential: 70%** (7 of 10 unique post-push findings covered by existing checklist items)

### Covered but missed (7 findings)

1. **Guard validators against non-object request bodies** — Tier 2: Input validation at boundaries (`typeof` guard before `.trim()`)
2. **Log projectStore.close() failures instead of swallowing** — Tier 1.2: Error Swallowing in Catch Blocks (empty catch)
3. **Add accessible names to inline edit inputs** — Tier 0.4b: Form inputs without accessible labels (grep check)
4. **Expose loading/error states from useProjects** — Tier 3: Hook error states surfaced in UI
5. **Guard against non-JSON error responses** — Tier 3: Error message specificity
6. **Render useProjects fetch failure/loading states explicitly** — Tier 3: Hook error states (same as #4)
7. **Fire-and-forget refresh() without .catch()** — Tier 0.2 + Tier 1.1: Fire-and-forget safety

### Not covered (3 new categories)

1. **Windows-style absolute path validation** — Path traversal checklist only covers Unix `/` prefixes. Windows `C:\` and UNC `\\server\` paths not checked.
2. **Content-Type enforcement on POST endpoints** — No checklist item for requiring JSON content-type headers.
3. **useMemo dependency completeness** — Known gap from process-patterns.md; nanny-app #28 flagged same issue.

### Fix commits

- 2 of 3 commits were fixes (66.7% fix-up ratio)
- Commit 2: "Address PR #39 review: guard body validators, add content-type checks..."
- Commit 3: "Address PR #39 re-review: guard against non-JSON error responses..."

## Planning Quality

- **Description:** Complete (Summary + Test Plan sections present)
- **Scope:** Clean (1516 LOC is above 600 LOC threshold but cohesive — single feature with store+API+frontend)
- **Branch lifetime:** 0.9 hours (well under 48h)
- **Planning checklist:** Complete (entry points enumerated in summary, validation edge cases in test plan)
- **Redesign indicators:** None

## Code Quality Signals

### Recurring issues
- **Correctness (6 comments):** Dominant category. Input validation gaps, error state handling, fire-and-forget safety.
- **Hook error states (2 comments):** Both useProjects loading/error state exposure — same class, different angles.

### Fix-up ratio: 66.7%
HIGH — above 50% threshold. Adversarial review should have caught more pre-push.

### New unrecorded patterns
- **Content-Type header validation on mutation endpoints.** Express `json()` middleware parses JSON bodies but doesn't reject non-JSON content types. POST/PUT handlers accepting `req.body` should guard `Content-Type: application/json` to prevent silent null body processing.
- **Windows path validation in path traversal guards.** When validating relative paths, checking for `/` prefix is insufficient — also reject `C:\`, `D:\`, UNC `\\`, and any `path.isAbsolute()` match.

## Process Efficiency

### Automation opportunities
- **Tier 0.4b grep would have caught accessible label finding.** The grep check for `<input>` without `aria-label` exists in the adversarial checklist but wasn't executed.
- **Tier 0.2 grep would have caught fire-and-forget finding.** Same — the grep exists but wasn't run.
- **Tier 1.2 mechanical verification would have caught error swallowing.** Empty catch block in `projectStore.close()`.

### Iteration assessment
- 3 rounds — **high friction** for a PR that ran the full local review loop.
- The local review caught 35 issues (impressive volume) but the 10 post-push findings show gaps in execution of existing checklist items.

### CI status
- All passed (227 tests, 14 test files, build clean)

## Recommendations

1. **Execute Tier 0 grep checks mechanically.** 3 of 7 "covered but missed" findings have automated grep patterns (0.2, 0.4b, 1.2). The adversarial review identified them conceptually but the grep patterns weren't run. Require grep output in the review evidence log.

2. **Add Content-Type header validation to the routes-api checklist.** POST/PUT handlers should reject non-JSON content types before parsing. This is a new gap — add to Tier 2 as a mechanical check.

3. **Add Windows path validation to the security checklist.** Path traversal guards need `path.isAbsolute()` or explicit `C:\`/UNC prefix rejection, not just `/` prefix check. Add to Tier 2.

4. **High fix-up ratio (67%) despite 100% step compliance and 78% shift-left rate.** The local review volume was strong but still missed 10 post-push findings. The gap is execution discipline on existing checklist items, not missing checklist coverage. This matches the systemic pattern noted in process-patterns.md (6th consecutive occurrence of "covered but not executed").

5. **1516 LOC exceeds the 600 LOC PR size threshold.** Consider splitting future CRUD features into: (a) backend store + API, (b) frontend wiring + UI. The cohesive scope worked here (0.9h to merge) but larger PRs consistently generate more review rounds.

## Knowledge Updates

- Updated `post-mortem-metrics.json` with PR #39 entry
- Updated `dashboard.html` with fresh metrics data
- Saved raw report to `post-mortems/command-center-39.md`
- Process patterns: no new patterns beyond what's already documented (fix-up ratio on 1500+ LOC PR with full review loop confirms existing pattern)
