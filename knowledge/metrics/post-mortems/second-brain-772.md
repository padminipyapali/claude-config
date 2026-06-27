# Post-Mortem: second-brain PR #772 — HouseholdSheetService (live-read the kids' master sheet)

**PR:** [#772](https://github.com/padminipyapali/second-brain/pull/772) — Closes [#770](https://github.com/padminipyapali/second-brain/issues/770) (P1 / PR-b of the kids' master-sheet integration)
**Branch:** `feat/sheets-service` → main (squash-merged as `aa4af10`)
**Author / Merged by:** padminipyapali (self-merge, solo dev)
**Created → Merged:** 2026-06-27 05:50:06 → 05:50:25 UTC (~19s on GitHub; full dev loop ran locally before push)
**Size:** +1036 −6 across 6 files, 1 squashed commit (~620 non-test LOC)

## What Shipped

A read-only Google **Sheets** reference service — `HouseholdSheetService` — modeled on the calendar adapter: a live read via `values.batchGet` over a centralized `TAB_RANGES` map, a 1-hour in-memory cache, and a never-throws / `[]`-on-failure contract per getter. No DB, no intent, no user surface (that's P2). Reuses the existing Google OAuth client (same client serves Calendar + Sheets).

- Interface: `getHiredNannies`, `getDoctors`, `getRamiSchedule`, `getMiraSchedule`, `getRawTab`.
- Header-driven defensive parsers for HiredNanny / Doctor / DailyScheduleRow; bad rows skipped, `raw` retained.
- Wired as optional `householdSheet?` on `MessageProcessorDeps`, constructed in `server.ts` only when `GOOGLE_KIDS_SHEET_ID` + `GOOGLE_OAUTH_*` present.
- Preceded by #771 (scope `spreadsheets.readonly` + env) and a design workflow.
- Files: `.env.example`, `message-processor.ts`, `server.ts`, `household-sheet.ts` (+525), `household-sheet.test.ts` (+385), `shared/index.ts` (+87).

## Process — VALIDATE-FIRST real-data probe gate (no fresh-context critic)

A read-only external-integration parser with no side effects and no user surface. Gated through a **VALIDATE-FIRST REAL-DATA PROBE** (a read against the live sheet) rather than a fresh-context code critic — because the real risk is parser/tab-name correctness against a human-edited sheet, which a critic reasoning about code structurally cannot assess but a real read can.

- Build / lint / test green: `@second-brain/server` 2427 passed, 48 skipped (+4 real-shape tests after the probe).
- GitHub: 0 reviews, 0 inline comments, 0 CodeRabbit GitHub review (1 Vercel bot comment, excluded). Vercel SUCCESS.

## The load-bearing validation: a real-sheet read-only probe

The unit fixtures encode assumptions; the live sheet encodes reality. The probe (run after the user enabled the Sheets API + re-minted with `spreadsheets.readonly`) caught **3 real bugs** no fixture or code critic would have:

1. **Wrong tab names** — all four `TAB_RANGES` names were wrong; real tabs: `"Nannies"`, `"Pediatrician / Dentist"`, `"Daily Schedule - School (8-11:20)"`, `"Mira Daily Schedule - No School"`. Every getter would have returned `[]` in prod while every mock stayed green.
2. **Header-below-banner** — the Nannies tab has a title banner above the header row (header not row 0).
3. **Section-bleed** — the Nannies tab continues into a 60+ roster below the 3 hired; the parser had to stop at the first blank row or return the whole roster as "hired."

All fixed pre-merge (TAB_RANGES remapped, parser hardened, +4 real-shape tests). The probe also surfaced a **403 first** (Sheets API not enabled on the GCP project) — an environment blocker the user fixed; the never-throws contract degraded cleanly against the live 403.

## adversarialCatchRate

**Unmeasured (`null`) — probe-was-the-gate shade.** No fresh-context critic ran, so there is no critic numerator/denominator; recording a rate would fabricate one. Honest record: for an EXTERNAL-INTEGRATION PARSER, the load-bearing gate is a real-data probe, not a code critic — and the probe caught 3 real bugs (tab-name mismatch, header-below-banner, section-bleed). **0 post-merge escapes** (#772 is newest merge; no follow-up touches the sheet path).

Distinct from #768 (full critic ran clean → `null`) and the refine slices (lightweight gate, critic-SKIPPED → `null`): here the critic was correctly *substituted* by the instrument that can assert the load-bearing property.

## Net-new lesson (captured)

**For a parser/adapter over an EXTERNAL human-edited source (a Google Sheet, a scraped page, a third-party export), unit fixtures encode your ASSUMPTIONS, not reality — the load-bearing validation is a read-only probe against the REAL source before merge.** It caught wrong tab names, a banner-above-header, and section-bleed here that no fixture or code critic would have. Generalizes the LLM real-model-probe lesson (#735/#761/#768) to a new domain: real-data probe > mocked tests for external-source parsers; swap "prompt interpretation" for "real source shape."

Captured in:
- `testing-patterns.md` → "Fixtures vs. Live Product Data" (primary, code-side).
- `llm-integration.md` → strengthened the real-model-probe entry with the external-source generalization (#772).
- `process-patterns.md` → "Critic Blind Spots" (when the external-match is the risk, a probe — not a code critic — is the gate; cousin of #696 auth-under-production and #768 probe/critic complementarity; record adversarialCatchRate unmeasured, not fabricated).

## Deferred decision (noted, not in P1)

Schedule tabs are organized **school-day vs no-school-day**, NOT per-child — so `getRamiSchedule`→school-day and `getMiraSchedule`→no-school-day are **placeholder mappings** to finalize in P2 with the user. Also for P3 (contacts table): strip invisible bidi marks from phone cells before storing.

## Metrics

| Metric | Value |
|--------|-------|
| Review rounds | 1 |
| Total comments | 0 (1 Vercel bot, excluded) |
| adversarialCatchRate | `null` — unmeasured (probe-was-the-gate; caught 3 real bugs; not fabricated) |
| Post-merge fix rate | 0.0 |
| Pre-merge iteration count | 1 (healthy) |
| Fix-up taxonomy | 0 fix commits (single squashed feature commit; probe-caught bugs fixed pre-commit) |
| Planning quality | complete |
| PR size | 1042 (+1036 −6) |
| Step compliance | 5/9 trackable run (1, 2a, 2b, 3, 5); 4a/4b/4c/4d substituted by real-data probe; assessment **good** |
| CI | Vercel SUCCESS; server suite 2427 pass / 48 skip |
