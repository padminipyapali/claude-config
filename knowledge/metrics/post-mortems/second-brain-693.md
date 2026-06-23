# POST-MORTEM: second-brain PR #693 — feat(export): media binaries, Markdown views & pg_dump (PR2)

Branch: `feat/export-media-markdown-pgdump` → `main` | Author: padminipyapali | created 2026-06-23T20:12:41Z → merged 2026-06-23T20:35:23Z (~0.38h wall post-rebase; active spanned several hours incl. a stalled-implementer handoff)
Size: +3186 -11 across 16 files, 8 commits | Part of #686 — PR2 of 3 (stacked on #690; PR3 = scheduling)

## LOCAL REVIEW (pre-push)
- CodeRabbit (CLI authed, 3 rounds): 16 findings — 4 MAJOR → 0 (the two real security issues below + 2 Markdown-injection), 4 Minor, 8 Trivial; all fixed.
  - SECURITY MAJOR (media OOM): the 25MB cap was enforced only AFTER `response.arrayBuffer()` buffered the whole body, so a hostile/redirecting server at x5 concurrency could OOM the export. Fixed: early-reject on oversized Content-Length, stream `response.body` and abort the moment the running total exceeds the cap, cancel the body on every early-return.
  - SECURITY MAJOR (pg_dump credential exposure): the DB connection URL (with password) was the last argv element, visible via `ps`/`/proc/<pid>/cmdline`. Fixed: parse the URL into libpq env vars (PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE/PGSSLMODE) passed via the child's environment; no connection string on argv.
- Sub-agent critics + sibling-sweep: per-module critic sub-agents (media=resource/OOM lens, pg_dump=credential lens, markdown=injection lens) + an explicit sibling-sweep found 6 more Markdown-injection sites after the first fix — INCLUDING LLM-generated content (the inbox `ai_summary` from the email pipeline), where a model-emitted `\n## ` / `\n- ` could forge document structure in the trusted backup. Also context/project/chat-session titles and the INDEX link label. Fixed via shared `inlineText`/`inlineCode` helpers + `[`/`]` escaping.
- /simplify (4a): clean (helpers reused, not reimplemented).
- Adversarial (4c): Tier 0 clean; doc-sync verified; properties 1-8 PASS with file:line evidence. Marker certifies HEAD 0048089.
- Shift-left: every real security/correctness issue caught pre-push; 0 GitHub-review comments, 0 post-merge fixes.

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 4d (Vercel SUCCESS), 5 — all 9 trackable steps ran.
- Steps skipped: none at the trackable-step level. Playwright (sub-part of step 3) N/A — backend CLI — recorded in body.
- Compliance rate: 100%.
- Skip assessment: good (no UI files).

## STEP TIMING (qualitative per PR body — no precise per-step minutes)
| Step | Notes |
|------|-------|
| 2 Implement | spanned multiple cycles INCL. a stalled-implementer handoff (WIP committed, agent went dormant; a fresh implementer finished from the on-disk WIP); active work ~1.5h |
| 3 Test | folded into implement; 1897 pass / 0 fail / 48 skipped |
| 4a-4c Review | per-module critic sub-agents + 3 CodeRabbit rounds; 2 security + 6 injection fixes — BOTTLENECK |
| 5 Push/PR | ~5 min (incl. rebase --onto squashed main after #690 merged + marker re-cert) |

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED post-push; solo self-merge).
- Comments: 0 inline, 0 general (1 Vercel bot comment excluded).
- Categories: all 0.
- Timeline: PR was opened only AFTER the stall+handoff+rebase, so wall-clock open→merge is ~23 min; all substantive review was pre-push (local).

## ADVERSARIAL REVIEW EFFECTIVENESS
- Pre-push catch: layered local gate (per-module critic sub-agents + 3-round CodeRabbit + explicit sibling-sweep + adversarial Tier 0) caught 100% of the real security/correctness issues; 0 escapes. This is the load-bearing finding — it's what made a >600-LOC self-merge safe.
- Covered + caught: Markdown-injection (now Tier 0 0.26), secret-on-argv (now Tier 0 0.27), size-cap-after-buffering / unbounded-remote-body (now Tier 0 0.28), input validation (unknown-flag rejection), stale-state (media index gated on includeMedia).
- adversarialCatchRate marked UNMEASURED per the integrity rule (gates caught + validated, but the all-possible-issues denominator is ill-defined).

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (#693 is the latest export PR; nothing merged after it touches the feature).
- Pre-merge catch rate by step (findings caught; skill Step-6 attribution): 4a (simplify) 0 · 4b (internal/critic sub-agents) 7 · 4c (CodeRabbit) 16 · 4d (adversarial sibling-sweep) 3 · post-push 0.
- Pre-merge iteration count: 4 (3 CodeRabbit rounds + 1 sibling-sweep) — high friction, but expected and appropriate for a 3186-LOC security-sensitive PR (media-download + subprocess-exec + Markdown-rendering of untrusted/LLM content). Per the rule, 3+ rounds = large PR / high surface, not a mental-model mismatch here.
- Fix-up taxonomy: validation 7 (6 Markdown-injection escaping + 1 unknown-flag rejection), defensive-coding 3 (media OOM bound, pg_dump credential out-of-band, stale media-index gate), correctness 1 (chat-session slug overwrite), test-quality 1, documentation 1.
- Legacy fix-up ratio: 0.75 (keyword-based: 6 of 8 commits match fix/test keywords). TRUE review-driven fixup count is 4 (commits 5-8); commit 3 is the test commit and commit 4 is a pre-review design reconciliation (pg_dump pooler-skip removal). The legacy metric over-counts here — exactly the "squash adversarial fix commits" caveat.

## PLANNING QUALITY
- Description: complete (Summary, What/How/Safety, Test plan, Local Review, Fix-Up Metrics, Perf & Cost, LOC with size-cap exception justified, Step Timing).
- Scope: clean. Three artifacts (media/markdown/pg_dump) ship together because they share the exporter integration + manifest types; additive-only over PR1's unchanged JSONL transaction. Size-cap exception declared and justified (mechanical rendering + tests + the three features share one integration point).
- Branch lifetime: short wall-clock (opened post-rebase), active spanned hours including the stall.
- Planning checklist: covered — entry points + error branches enumerated (12 new tests across media/markdown/pg_dump/integration/CLI), Performance & Cost Impact present, "best-effort, never aborts BACKUP_COMPLETE" failure model stated.

## CODE QUALITY SIGNALS
- Recurring issue WITHIN this PR: Markdown-structure injection appeared at 7 sites (1 found first, 6 by sibling-sweep) — a single bug class, correctly swept rather than point-fixed.
- New unrecorded patterns: 3 (all captured) — (1) LLM/user content into Markdown is a structure-injection sink; (2) secret on subprocess argv leaks via `ps`/`/proc`; (3) size cap after fully buffering a remote body is too late (OOM).

## PROCESS EFFICIENCY
- Automation opportunities: the 3 new Tier 0 greps (0.26/0.27/0.28) now make these classes detectable mechanically on the next PR — especially relevant as PR3 (scheduling) builds on this media/subprocess surface.
- Iteration: high friction by round-count (4) but ZERO escapes — friction was the gate working on a large security-sensitive surface, not rework from a bad plan.
- CI status: Vercel SUCCESS; full server suite 1897 pass / 0 fail (orchestrator-verified post-review).
- LIVENESS: the implementer STALLED mid-implementation (committed partial WIP, then went dormant across idle cycles). Recovered by standing it down and spawning a FRESH implementer that finished from the committed on-disk WIP. Captured as a process learning (WIP-commit-as-handoff + bound implementer liveness).
- MERGE: stacked-PR squash-merge produced an add/add conflict (PR1's files appeared "added" on both squashed-main and the PR2 branch); resolved with `git rebase --onto origin/main <pr1-branch> <pr2-branch>`, content-identity proven to the certified commit, marker re-certified, force-pushed. Captured.

## KNOWLEDGE UPDATES
- process-patterns.md → Review Efficiency: NEW — layered local-review lenses (per-module critic sub-agents + multi-round CodeRabbit + explicit sibling-sweep) caught 100% of real security/correctness issues pre-merge with 0 escapes; the layering is what made a >600-cap PR safe to self-merge.
- process-patterns.md → "Stacked PR + squash-merge: rebase --onto" entry: STRENGTHENED with the add/add-from-squash specialization + the two extra steps a squash-rebase needs (prove content-identity to the certified commit; re-certify the marker for the rewritten head before force-push) — second-brain #690/#693.
- process-patterns.md → "A parallel-build agent that dies ... recoverable from WIP" entry: EXTENDED to the SILENT-STALL (not death) case + WIP-commit-as-handoff: stand down a dormant implementer and respawn fresh from the committed WIP; set a liveness expectation; checkpoint long implementations as WIP commits so a stall/death is recoverable — second-brain #693.
- adversarial-review.md → Tier 0: ADDED 0.26 (user/LLM content interpolated into Markdown without escaping), 0.27 (secret/connection-string on subprocess argv), 0.28 (size cap enforced after fully buffering a remote body).
- llm-integration.md → Safety & Prompt Injection: ADDED the Markdown twin of the render-side-XSS rule (LLM output into Markdown is a structure-injection sink; escape/fence + sibling-sweep + adversarial test).

## RECOMMENDATIONS
1. (Process, highest leverage) Bound implementer liveness: when a long-running implementer produces no progress across N idle cycles, treat it as stalled — stand it down and respawn a fresh agent from the last WIP commit. The #693 stall cost hours of wall-clock that a liveness watchdog + WIP-checkpoint cadence would have capped. Consider making periodic `wip(...)` commits a standing expectation for any implementation expected to exceed one work cycle.
2. (Process) For PR3 (scheduling), branch off the MERGED head of #693, not the pre-merge branch, so the stacked squash-merge can't re-create the add/add conflict; budget the `rebase --onto` + marker re-cert step if it stacks anyway.
3. (Automation, landed) The 3 new Tier 0 greps now catch the Markdown-injection / secret-on-argv / unbounded-body classes mechanically — run them on PR3, which extends the same media/subprocess surface.
4. (Sizing, accept) The >600-LOC PR was justified (three artifacts share one exporter integration; bulk is mechanical rendering + tests) and shipped with 0 escapes via per-module critic lenses — a valid atomic-feature exception, not drift. No action.
