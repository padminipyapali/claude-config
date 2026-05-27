# Post-mortem: baby-name-picker PR #47 — Version-control Claude config
+451 -0, 6 files, 1 commit, ~19 min, self-merged.
**Context:** the adversarial-review hook was silently dead because `.claude/settings.json` was untracked and pointed at a hook script in a different local checkout. This PR commits the shared config (CLAUDE.md, settings.json, hooks/, skills/) and gitignores personal/ephemeral state.
**Review:** orchestrator self-scanned committed files for secrets + hardcoded paths (the exact bug class); gate proven to block (no marker) and allow (marker present) end-to-end. adversarialCatchRate=null (config-only, no code logic).
**Learning:** config-as-code — hooks/skills referenced by the repo must be committed and use `$CLAUDE_PROJECT_DIR`, not hardcoded paths, or the gate breaks per-clone.
