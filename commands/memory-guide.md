---
description: Display the cross-project learning system guide
model: haiku
---

Display the cross-project learning system guide.

Print the following guide directly (do NOT read any files, just output this):

---

## Knowledge System Guide

### Architecture

```
~/.claude/knowledge/                    ← SHARED KNOWLEDGE (by topic, not project)
├── INDEX.md                            ← Topic list + stack matching guide
├── typescript-patterns.md              ← TypeScript/Node.js patterns
├── react-patterns.md                   ← React + React Native patterns
├── llm-integration.md                  ← LLM/AI integration patterns
├── database-patterns.md                ← PostgreSQL/SQL patterns
├── firebase-patterns.md                ← Firebase/Firestore patterns
├── telegram-bot-patterns.md            ← Telegram bot patterns
├── architecture-patterns.md            ← Service design, error handling
├── testing-patterns.md                 ← Test strategy, mocking, assertions
├── adversarial-review.md               ← Shared review checklist (all tiers)
└── .last-consolidated                  ← Timestamp tracking

~/.claude/CLAUDE.md                     ← GLOBAL RULES (concise, universal)
~/.claude/projects/*/memory/            ← PER-PROJECT context (project-specific)
<project>/.claude/skills/               ← PER-PROJECT skills (reference shared knowledge)
```

### Key Principle

Knowledge is organized **by topic, not by project**. A new React + PostgreSQL project automatically sees all React and database learnings from every previous project.

### Automated Knowledge Flow

| Action | Trigger | How |
|--------|---------|-----|
| Load knowledge at plan time | Planning a feature | Agent reads INDEX.md + relevant topics (CLAUDE.md directive) |
| Capture learnings at PR time | Adversarial review | Step 7: Learning Capture Gate (hook-enforced) |
| Update project docs | Every PR | CLAUDE.md Living Documentation directive |

### Manual Commands (Safety Nets)

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/consolidate-learnings` | Batch-scan all projects, merge new patterns | Periodically, or after wrapping up a major feature |
| `/capture-learning` | Quick-add a single learning | Mid-session, when you notice a reusable pattern |
| `/project-setup` | Bootstrap new project with knowledge injection | Starting a new project |
| `/post-mortem` | Analyze merged PR's development loop | After merging a PR (runs automatically, or invoke manually) |
| `/memory-guide` | Show this guide | Anytime |

### Tips

- Run `/consolidate-learnings` after wrapping up a major feature or finishing a project
- Say "remember that I prefer X" to explicitly save a preference
- New topic files can be created — just update INDEX.md
- The adversarial review hook handles most learning capture automatically
