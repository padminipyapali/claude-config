# Post-mortem: baby-name-picker PR #43 — 23 name-meaning corrections
+344 -23, 3 files, 1 commit, ~27 min, self-merged, 0 GitHub reviews.
**Review:** implementer→critic. Implementer self-caught a dedup-ordering hazard mid-impl; critic independently verified exactly-23-rows-changed and web-verified accuracy. 2 nice-to-haves folded pre-commit.
**Process highlight:** the original flat-view audit flagged 30 errors; re-triaging against the structured `meanings_json` revealed 7 were FALSE POSITIVES (legitimate multi-origin entries). Auditing the flattened projection instead of the structured data caused them.
**Catch rate:** 1.0 in-scope (0 post-merge). **Caveat:** a later deep per-language re-audit found 18 MORE errors in OTHER (untouched) multi-origin rows — out of this PR's scope, surfaced only by auditing the structured field directly.
**Learning:** audit structured/multi-valued data on its structured representation — a flat view causes both false positives AND false negatives.
