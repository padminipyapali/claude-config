# Post-mortem: baby-name-picker PR #41 — Reproducible seed-DB build pipeline
+1538 -2077, 8 files, 1 commit, ~47 min, self-merged, 0 GitHub reviews, no CI configured.
**Review:** orchestrator implementer→critic team (no CodeRabbit). Critic APPROVE, 0 must-fix; 2 nice-to-haves (row-count assert, .gitattributes) folded before commit.
**Key win:** the critic on the *prior* corrections attempt caught a product-breaking architectural issue — the shipped `assets/seed.db` could not be regenerated from any repo source (drift), so fixes wouldn't reach users. That triggered splitting work into this pipeline PR first.
**Catch rate:** 1.0 (0 post-merge fixes). **Planning:** complete. **Compliance:** 6/9 (used critic in place of 4a/4b).
**Learning:** verify the artifact that *ships*, not an intermediate build output.
