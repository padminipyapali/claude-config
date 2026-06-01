# Task Queue

Tasks queued because the target repo had active work in progress. Check `[PENDING]` entries at session start.

---

## [PENDING] Import Euphony-discovered real names into seed.db
- **Repo:** /Users/padminipyapali/dev/baby-name-picker
- **Queued:** 2026-05-31
- **Context:** While building the "Euphony" coined-name generator/rater (tool at /Users/padminipyapali/dev/euphony-rater), screening + a second adversarial audit flagged ~84 generated candidates as *actually real* names. 82 of them are NOT yet in seed.db (1240 rows). User wants these real names added to the seed catalog.
- **Flagged-real (82 new):** Aaditri, Aelin, Aislen, Aneira, Anira, Anvith, Anvitha, Aryesh, Avyan, Bhekani, Brynwen, Caderyn, Caelina, Caelvin, Chandhini, Chiranth, Conlin, Coralind, Daleen, Delvina, Domek, Eirenia, Ekantha, Eshanya, Feyzan, Glenwen, Hadwyn, Ishvari, Ivora, Kazek, Kerwyn, Khanyiso, Kotaru, Lavisha, Lesko, Liyana, Lohitan, Lubek, Lunella, Maaran, Maewyn, Mahveen, Matveo, Maurelio, Mehra, Milek, Mirel, Naliaka, Nilan, Norina, Oksena, Olamiji, Ozay, Ozren, Pranshul, Radmil, Rivaani, Rivansh, Romelia, Ronwyn, Roryk, Rudransh, Salviano, Sanvitha, Saren, Saviel, Senya, Shamira, Sharvi, Sorina, Tanvika, Temidara, Tesfalem, Vihang, Xanthia, Yadiel, Yaro, Yashvin, Yotaro, Yuvraan, Zamira, Zenya. (Source lists: /Users/padminipyapali/dev/euphony-rater/keep/flag_*.json)
- **ENRICHMENT DONE (2026-05-31):** read-only enrichment + verification complete. Of 84 flagged, **50 net-new verified rows** are ready at `/Users/padminipyapali/dev/euphony-rater/keep/seed_additions.json` — each with accurate sourced meaning, corrected TRUE origin, gender, pronunciation, category (short_sweet|global|classic|literary|bold), syllables, length, meaning_depth. ~34 were dropped (not attested / no verifiable meaning / Niran already in db). Names: Aaditri, Anvith, Anvitha, Avyan, Bhekani, Brynwen, Caderyn, Caelina, Chandhini, Chiranth, Delvina, Domek, Eirenia, Ekantha, Eshanya, Feyzan, Hadwyn, Ishvari, Kazek, Khanyiso, Lesko, Lubek, Maaran, Maewyn, Maurelio, Mehra, Milek, Mirel, Nilan, Olamiji, Ozay, Pranshul, Radmil, Romelia, Rudransh, Salviano, Saviel, Senya, Shamira, Sharvi, Tanvika, Temidara, Tesfalem, Vihang, Xanthia, Yadiel, Yaro, Yashvin, Yotaro, Zenya.
- **NOTE for implementer:** a few origins (Albanian, Romanian, Polish, Serbian, Ukrainian) may not be in the existing origin vocabulary — confirm the app accepts them or map appropriately. seed.db INSERT shape (13 cols): VALUES(id,name,meaning,origin,origins_json,gender,pronunciation,category,categories_json,syllables,length,created_at,meanings_json).
- **Remaining path (needs repo free):** add rows via scripts/seed-data.sql → rebuild via scripts/build-seed-db.py → run seed-additions.test.ts / seed-corrections.test.ts → PR via orchestrator/worktree flow.
- **Detection 2026-05-31 (still BUSY):** active `expo run:ios` node process (pid ~84777) running in repo; untracked docs/mockups dirs present. Do NOT make code changes until clear.

---

## [DONE] Outside-diff sweep for sleep-tracker
- **Repo:** /Users/padminipyapali/dev/sleep-tracker
- **Queued:** 2026-03-02
- **Completed:** 2026-03-04
- **Context:** Cleanup sweep PR for issue #9 (3 deferred CodeRabbit findings from PR #8: auto-focus scroll, misleading test name, fixed maxHeight)
- **Resolution:** Folded into comprehensive bug sweep session. PRs #34-37 address all P1 bugs. Issue #9 findings superseded by broader fixes.
