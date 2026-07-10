# POST-MORTEM: second-brain PR #869 — feat(reference): contacts sheet (Postable export) lookups behind REFERENCE_LOOKUP

Branch: feat/contacts-sheet → main | Author: padminipyapali | merged 2026-07-10
Size: +1067 -37 across 11 files, 3 commits | Closes #859

## Summary of the change
New `ContactsSheetService` live-reads a separate Postable address-book export sheet (gated on `CONTACTS_SHEET_ID`), mirroring the household-sheet resilience contract (header-driven case-insensitive parse, first-tab un-prefixed A1 range, 1-hour cache, never-throws). Contact questions route through the existing REFERENCE_LOOKUP intent; matched contacts render into the delimited, XML-escaped grounding block. Household sheet becomes optional in the resolver.

## Local review (pre-push)
- CodeRabbit: not tracked — CLI timed out server-side on both attempts (initial + backoff retry, IDs 8333b8b5, 47d5066b). Skipped with justification per dev flow.
- Adversarial (fresh-context critic): 2 findings, 2 fixed. Verdict APPROVE.
  1. Raw-substring PII over-matching: a contact surname like "Long" matched the ordinary word in "how long until the nanny gets here?", bypassing the deterministic empty-state short-circuit and grounding that contact's PII into a Sonnet call. Fixed → whole-word possessive/capitalized token matching (precision over recall).
  2. Plural-family possessive recall regression: "the Smiths'" stripped to "smiths" and failed the whole-word match against lastName "Smith". Fixed → emit singular candidate for possessive base ending in "s".
- Shift-left rate: 100% of known issues caught locally (2/2), 0 post-merge escapes.

## Step compliance
Steps run: 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9). Skipped: 4b (CodeRabbit) — server-side timeout, unavoidable. Compliance 88.9%. Skip assessment: good (adversarial + 23 targeted tests covered; no post-merge escapes).

## Step timing
Not tracked (no `## Step Timing` section).

## Review friction (post-push)
Review rounds: 1 (no CHANGES_REQUESTED; no GitHub reviews). Comments: 0 inline, 0 general (excluding Vercel bot). Self-merged by author under the local-review gate. Timeline: PR opened and merged within ~2 min (branch developed over ~33h on 07-09→07-10 before opening).

## Adversarial review effectiveness
Both blocking findings are in-checklist classes: (1) PII/LLM-integration — validate/filter and separate user content before grounding into prompts (maps to defensive-coding + LLM-integration checklist items); (2) correctness edge case in name-token normalization. Pre-push catch potential realized: 2/2. adversarialCatchRate = 1.0 (evidence-backed, not fabricated). This is the critic-ran-with-findings shade of a strong signal, not a bare null.

## Fix-up metrics
- Post-merge fix rate: 0.0% (0 post-merge fix commits — ideal).
- Pre-merge catch by step: 4d (adversarial) = 2; all others 0.
- Pre-merge iteration count: 1 (both findings fixed in a single critic round).
- Fix-up taxonomy: defensive-coding 1, correctness 1.
- Legacy fix-up ratio: 66.7% (2 fix / 3 commits) — inflated by two pre-push critic fixes, which is the healthy direction (caught before merge).

## Planning quality
Complete. Body has Summary, Review, Tests, Deploy note, and a Performance & Cost Impact section (cache-bounded one-fetch/hour, matched-contact rendering capped at 25 and name-filtered so prompt size is independent of address-book size). Clean scope, no redesign/revert commits.

## Code quality signals
Recurring theme reinforced: the fresh-context critic catches real security/correctness bugs a single-pass author misses — here specifically PII-into-LLM over-matching. New capturable pattern: precision-first (possessive/capitalized whole-word) matching before grounding user PII into a prompt, with lowercase-only questions deliberately routed to the deterministic empty-state reply (documented recall trade-off).

## Recommendations
1. Adopt precision-first name/entity matching as the default whenever user PII is grounded into an LLM prompt — recall is the safer thing to sacrifice.
2. CodeRabbit CLI server-side timeouts are now a recurring reliability issue (both attempts on this PR). Continue treating a documented double-timeout as an acceptable skip when adversarial + targeted tests cover the diff; consider a shorter single-attempt budget before falling back rather than burning 60+ min twice.
