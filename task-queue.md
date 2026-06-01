# Task Queue

Tasks queued because the target repo had active work in progress. Check `[PENDING]` entries at session start.

---

## [PENDING] Import Euphony-discovered real names into seed.db
- **Repo:** /Users/padminipyapali/dev/baby-name-picker
- **Queued:** 2026-05-31
- **Context:** While building the "Euphony" coined-name generator/rater (tool at /Users/padminipyapali/dev/euphony-rater), screening + a second adversarial audit flagged ~84 generated candidates as *actually real* names. 82 of them are NOT yet in seed.db (1240 rows). User wants these real names added to the seed catalog.
- **Flagged-real (82 new):** Aaditri, Aelin, Aislen, Aneira, Anira, Anvith, Anvitha, Aryesh, Avyan, Bhekani, Brynwen, Caderyn, Caelina, Caelvin, Chandhini, Chiranth, Conlin, Coralind, Daleen, Delvina, Domek, Eirenia, Ekantha, Eshanya, Feyzan, Glenwen, Hadwyn, Ishvari, Ivora, Kazek, Kerwyn, Khanyiso, Kotaru, Lavisha, Lesko, Liyana, Lohitan, Lubek, Lunella, Maaran, Maewyn, Mahveen, Matveo, Maurelio, Mehra, Milek, Mirel, Naliaka, Nilan, Norina, Oksena, Olamiji, Ozay, Ozren, Pranshul, Radmil, Rivaani, Rivansh, Romelia, Ronwyn, Roryk, Rudransh, Salviano, Sanvitha, Saren, Saviel, Senya, Shamira, Sharvi, Sorina, Tanvika, Temidara, Tesfalem, Vihang, Xanthia, Yadiel, Yaro, Yashvin, Yotaro, Yuvraan, Zamira, Zenya. (Source lists: /Users/padminipyapali/dev/euphony-rater/keep/flag_*.json)
- **Required before insert (data-quality gate):** auditors used HIGH-RECALL, so (1) re-verify each is genuinely a real attested name (drop false-positives); (2) look up ACCURATE meaning + CORRECT origin/culture (generated origin is often wrong); (3) fill pronunciation, category, syllables, length per schema (meaning/origin/category NOT NULL).
- **Path:** edit scripts/seed-data.sql → rebuild via scripts/build-seed-db.py → run seed-additions.test.ts / seed-corrections.test.ts → PR via orchestrator/worktree flow.
- **Detection at queue time:** active agent running `npm run ios` in repo; uncommitted `M src/stores/gameStore.ts` + untracked docs/mockups dirs; worktrees animations & multi-origin present.

---

## [DONE] Outside-diff sweep for sleep-tracker
- **Repo:** /Users/padminipyapali/dev/sleep-tracker
- **Queued:** 2026-03-02
- **Completed:** 2026-03-04
- **Context:** Cleanup sweep PR for issue #9 (3 deferred CodeRabbit findings from PR #8: auto-focus scroll, misleading test name, fixed maxHeight)
- **Resolution:** Folded into comprehensive bug sweep session. PRs #34-37 address all P1 bugs. Issue #9 findings superseded by broader fixes.
