# POST-MORTEM: plush-press PR #352 — P0: stop stripping a book's styleId pin on every editor autosave (BUG-016)

Branch: feat/styleid-strip-fix → main | Author: padminipyapali | 16 min created→merged
Size: +157 -4 across 6 files, 1 commit (squashed; one `rebase --onto` for a BUGS.md collision)
Bug ledger: BUG-016. Severity: P0 — five silent un-pins in one day defeated the whole art-style feature.

## THE BUG (context for the metrics)

Client `hooks/useProject.ts` `coerceRaw` rebuilt the loaded project as an object literal of known
fields, dropping the Next-only pass-through fields `styleId`/`done`/`authors`. The autosave PUT the
stripped in-memory snapshot verbatim; `normalizeProject` read `styleId` only from the body → erased
on disk ~51s after every pin, on any unrelated edit. Found by a hypothesis-driven hunt after the
operator hit it repeatedly. Critically: **the bug lived in UNCHANGED code**, so it survived the
entire diff-scoped review gauntlet of the PRs that added `styleId` — no reviewer's diff contained
the offending field-pick.

## LOCAL REVIEW (pre-push)

- CodeRabbit: skipped (P0 urgency) — coderabbit fields recorded null.
- Adversarial critic: RAN. 1 finding, 1 fixed — a MINOR-must-fix demanding a structural
  schema-keyof MIRROR test (coerceRaw's preserved keys must structurally track the schema so the
  NEXT added field can't be silently dropped by the same class). This converged independently with
  the hooks-audit's tripwire recommendation — two fresh contexts proposing the same structural
  guard.
- Shift-left rate: 100% — the only issue found on this PR was caught locally, pre-push.

## STEP COMPLIANCE

- Steps run: 1, 2a, 2b (defense-in-depth store guard), 3, 4c (adversarial), 4d (CI), 5 (7/9) —
  compliance 78%.
- Steps skipped: 4a (simplify), 4b (CodeRabbit) — reason: P0 hotfix urgency.
- **Skip assessment: GOOD.** 0 post-push findings, 0 post-merge fixes (nothing after #352 touches
  useProject/saveProject), CI green.

## STEP TIMING

Not tracked. Wall clock branch→merge ≈ 16 min (plus the pre-branch diagnostic hunt).

## REVIEW FRICTION (post-push)

- Review rounds: 1 (self-merge, zero GitHub comments). Timeline: created 22:19 → merged 22:35 (0.265 h).

## ADVERSARIAL REVIEW EFFECTIVENESS

- **adversarialCatchRate: 1.0 (evidence-based).** Denominator = 1 total issue on this PR (the
  missing structural mirror test); the critic caught it pre-push; 0 issues found post-push or
  post-merge. 1/1.
- Note the two-tier reading: the critic was perfect ON THE DIFF, but the underlying bug's five-strip
  history is the canonical case of diff-scoped review missing unchanged-code relationship bugs. That
  producer-sweep lesson is ALREADY recorded — universal convention 8 (now "union member / schema
  field completeness": consumer sweep AND producer sweep) and the process-patterns.md 2026-07-20
  "Diff-scoped review misses relationship bugs" entry — verified present; strengthened with this
  PR's ship record rather than duplicated.

## FIX-UP METRICS

- Post-merge fix rate: 0%.
- Pre-merge catch by step: 4d (adversarial): 1 | all others 0 | post-push: 0.
- Pre-merge iteration count: 2 (critic round + fix — normal).
- Fix-up taxonomy: test-quality: 1 (the schema-keyof mirror test). Legacy ratio: 0% (fix folded
  into the single squashed commit).

## PLANNING QUALITY

- Description: complete — root cause traced end-to-end (coerceRaw → projectRef → autosave PUT →
  normalizeProject), fix at both levels per the brief, tests enumerated including a regression
  replaying the operator's exact sequence (pin → stale PUT without styleId → pin survives).
- Scope: clean; one rebase for a docs collision, no redesign.

## CODE QUALITY SIGNALS

- Fix shape is exemplary and now ledgered: (a) fix the offending site (preserve pass-through
  fields), (b) make the invariant STRUCTURAL at the store (`saveProject` preserves on-disk styleId
  unless `preserveStyleId: false`; the dedicated PATCH `runSetProjectStyle` is the only legitimate
  un-pinner), (c) a structural test that guards the CLASS, not the instance.
- Convergence signal: critic must-fix and independent hooks-audit tripwire recommendation landed on
  the same structural guard — recorded in process-patterns.md as a durability signal.

## PROCESS EFFICIENCY

- Automation opportunity: the schema-keyof mirror test IS the automation — the next schema field
  addition fails a test instead of silently stripping. No further tooling needed.
- Iteration: efficient. CI: passed.

## KNOWLEDGE UPDATES

- `~/.claude/CLAUDE.md` convention 8: verified already updated with the producer sweep (no change).
- `process-patterns.md`: strengthened the existing 2026-07-20 diff-scoped entry with the #352 ship
  record, fix shape, catch record, and the mirror-test convergence; added source citation.
- Repo `docs/BUGS.md` BUG-016: verified present with the full lesson.
- Metrics JSON + dashboard regenerated.

## RECOMMENDATIONS

1. Treat the schema-keyof mirror test as the template for every core-entity round-tripping
   coercer/serializer — it converts convention 8's producer sweep from manual to mechanical.
2. When a field should have exactly one mutation path, enforce it at the store (preserve-guard +
   single legitimate clearer), never by convention — this PR's (b) is the reference implementation.
3. Keep at least one ENSEMBLE regression per feature simulating the real multi-surface session
   (pin via endpoint, then an ordinary save from another surface) — fixtures test one surface.
