# POST-MORTEM: plush-press PR #344 — Complete book-style coherence: scenes, staged-content flags, and write-stamping (Stage 6a PR2)

Branch: feat/style-coherence-scenes → main | Author: padminipyapali | ~5 min PR-to-merge (solo flow; ~108 min dev total)
Size: +350 -33 across 11 files, 1 squashed commit

## Local review (pre-push)
- CodeRabbit CLI: **2 findings, 2 fixed** (1 iteration) — (MAJOR) resolve-window write: a pick taken before `useResolvedStyle` resolves could stamp the fallback `"watercolor"` tag, persisting an off-style backdrop; (MINOR) missing deferred-fetch test.
- Adversarial (critic, fresh context): **0 findings** — but the critic had SEEN the resolve-window wrinkle and **accepted it as minor** ("self-healing; the mismatch flag catches it after"). CodeRabbit independently escalated it to MAJOR and it was **prevented** (bound book holds backdrop adds until style resolves) per default-to-fix.
- Shift-left rate: 100% (all issues caught locally; 0 post-push comments).

## Step compliance
- Steps run: 1, 2a, 2b, 3, 4a (folded into implement, declared), 4b, 4c, 4d, 5 — compliance 100%, skip assessment: good.

## Step timing
Plan ~15m · Implement ~35m · Gates ~6m · Rebase ~4m · Critic ~5m · CodeRabbit ~40m (incl. ~25m rate-limit waits) · Push/PR ~3m · **Total ~108m**. Bottleneck: CodeRabbit rate limits.

## Review friction (post-push)
- 0 reviews, 0 comments; self-merged ~5 min after creation (solo flow with local-review gate — by design).

## Adversarial review effectiveness
- adversarialCatchRate = **0/2 = 0.0** (evidence: both substantive findings came from CodeRabbit; the critic explicitly triaged the MAJOR as acceptable). Notably the critic DID run the cached-async-state checklist item against the new async state and passed it — the miss was a *severity judgment* (accepting a known race as "self-healing"), not a blind spot. This is the docket's key process data point: **"self-healing later" is not an acceptance rationale for a paid/persisted write** — the write is the harm, not the display.

## Fix-up metrics
- Post-merge fix rate: 0.0 (#345 is an unrelated create-look lane; no follow-up fixes touched this PR's files).
- Pre-merge catches: 4c (CodeRabbit) 2; others 0. Iterations: 2 (critic pass, then CodeRabbit fix cycle). Taxonomy: correctness 1, test-quality 1.

## Planning quality
- Description: complete (what/why, decisions 1–5 status, byte-identity + fail-open proofs, LOC split, gates). Scope clean; branch same-day.

## Process efficiency
- CodeRabbit rate-limit waits (~25m) dominated review time.
- Automation: the resolve-window class (async-resolved config consumed by a write path) is grep-adjacent but really a review-lens item — added to the cached-async lens tally (5th consecutive PR at that time).

## Recommendations
1. Codify: a race that results in a **persisted or paid** artifact can never be accepted as "minor/self-healing" — prevent (hold the action until resolution), don't flag-after.
2. Keep the cached-async/paid-click lens mandatory — it or its sibling class has now recurred across the docket.
