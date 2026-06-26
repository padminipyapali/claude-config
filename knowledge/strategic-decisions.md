# Strategic & Product Decisions

Cross-project product thinking patterns. These are decision frameworks and product instincts — not technical patterns (those live in other topic files).

## AI Model Selection

- Use the cheapest model that meets the quality bar. Haiku for classification/extraction, Sonnet for generation/conversation. Only upgrade when you can demonstrate quality failures at the lower tier.
<!-- Source: second-brain, vocab_app architecture decisions -->

- Two-phase AI patterns (fast stream + structured extraction) let you optimize cost AND UX simultaneously. Don't force one model to do both jobs.
<!-- Source: vocab_app phase 1/phase 2 streaming design -->

## Feature Scope

- When a feature adds configuration surface area without validated user demand, cut it. Personality modes, theme pickers, and optional toggles are complexity debt until proven otherwise.
<!-- Source: vocab_app removed personalities; second-brain deferred email threading options -->

- Actively remove shipped features that prove unused. The bar for keeping a shipped feature is the same as building one: validated user demand. Sunk cost shouldn't keep dead code alive — 3,500 LOC of agent delegation and an AI thread summary were both removed post-ship because they added maintenance burden and cost without actual usage.
<!-- Source: command-center D10 (agent delegation removal, #40); second-brain thread summary removal (#282), 2026-02-28 -->

- Nudge over mandate. Guide user behavior through suggestions and defaults, not restrictions. Topic suggestions > forced categories.
<!-- Source: vocab_app topic suggestion decision -->

- Natural language as primary interface for personal tools. If the user has to learn a new UI grammar, the tool failed. Structured UI for dashboards and review; conversational for capture and input.
<!-- Source: second-brain Telegram-first design; command-center slash commands -->

- **Phase-gate the destructive / scale-sensitive parts of a multi-part feature behind an actual-data trigger; ship only the cheap, non-destructive core now.** When a planned feature has a load-bearing core plus expensive or irreversible add-ons (a one-time backfill that rewrites existing rows, a near-duplicate/dedup UX that only pays off at volume), split so the core lands immediately and the heavy parts are deferred until the live data actually warrants them — measured against *current* scale, not hypothetical future scale. second-brain #747 cut a 3-part tag-canonicalization plan (canonicalize-at-write + pg_trgm "use existing tag?" hint + destructive backfill) down ~3× to the canonicalization core after a mid-stream product conversation, because the live system had 8 tags, exactly 1 affected, 0 collisions: the backfill (destructive, needs a dry-run) and the dedup UX (only useful at high tag counts) were both gated on real scale. This differs from "cut unproven configuration" (a different bullet above) and from deferring an *aesthetic* layer (baby-name-picker) — it is about right-sizing the *engineering investment and blast radius* to the data you actually have, keeping the shipping PR a coherent, reversible, no-migration unit. Generalizes to any feature where storage/dedup/backfill scale with data volume: build for the row count you have, defer the volume-driven and destructive parts behind an explicit "revisit at N" trigger. <!-- Source: post-mortem, second-brain #747, 2026-06-26 -->

## MVP Strategy

- Single deployment for tightly coupled services at single-user scale. Don't split into microservices until you have multi-user load or independent scaling needs. A monorepo with workspaces gives you the code boundary without the infra overhead.
<!-- Source: all four projects use monorepo + single deploy -->

- Build the capture loop first, refinement second. Users tolerate rough output if input is frictionless. The reverse kills adoption.
<!-- Source: second-brain prioritized Telegram input over web dashboard polish -->

- Channel adapter pattern for input sources. Design the core as channel-agnostic from day one even if you only ship one channel at launch — the second channel is always closer than you think.
<!-- Source: second-brain ChannelAdapter interface (Telegram → email → SMS) -->

- Zero-friction onboarding for consumer apps with a simple core loop. Skip all setup screens — drop users directly into the primary interaction. Infer preferences (e.g., gender, name origin) from behavior after a few rounds rather than asking upfront. Inline prompts at natural pauses ("What's your last name?" after 3-5 swipes) feel like conversation, not configuration. Every screen before the core loop is a drop-off point.
<!-- Source: baby-name-picker DEC-001, DEC-003, DEC-005, 2026-02-25 -->

- Start online-only for MVPs. Offline-first adds substantial complexity (sync conflicts, local storage, migration strategies) that's wasted if the product doesn't find fit. A simple "No connection" banner is sufficient until real usage proves offline demand. Validate the product before investing in offline support.
<!-- Source: folio D001, 2026-02-23 -->

## Security & Multi-Tenancy

- Multi-tenant access control from day one, even for single-user MVPs. Retrofitting authorization is 10x harder than building it in. Define roles (owner, member, viewer) at the data layer before writing UI.
<!-- Source: nanny-app Firebase security rules; second-brain user_id scoping -->

## Monitoring & Observability

- Dashboard-only mode: monitoring tools should work independently of the systems they monitor. If your monitoring bot goes down, you should still see status via a web dashboard (and vice versa).
<!-- Source: command-center dashboard-only mode decision -->

- Sequential task queues for agent delegation. Predictable ordering beats throughput for personal tools — you want to understand what happened, not process things fast.
<!-- Source: command-center sequential queue decision -->

## Product Lifecycle & Process

- Deliverables are the unit of progress, not phase labels. A phase without its deliverable is still the previous phase. This principle drives both UI design (thread detail = deliverable timeline) and cross-session continuity (deliverables ARE the context — no separate orchestrator state needed).
<!-- Source: command-center thread lifecycle RFC discussion, 2026-02-28 -->

- The orchestrator's role should expand from managing engineering execution (Plan → PR) to managing the full product lifecycle (Spark → Bug Bash), acting as COO to the user's CEO. Every phase has: expected deliverables, a definition of done, and a gate where the user approves.
<!-- Source: command-center thread lifecycle RFC discussion, 2026-02-28 -->

- Go/no-go gates at Discover and Ideate/Design are the most important product filters. They prevent wasted engineering effort. Archived threads (no-go decisions) are preserved as product decision history — "we considered X and decided against it because Y."
<!-- Source: command-center thread lifecycle RFC discussion, 2026-02-28 -->

- **Design-to-implementation pipeline for an aesthetic feature: mockup-exploration → named-theme → AskUserQuestion on the open variables → phased build with ornamentation deferred.** baby-name-picker's Nocturne theme (#198 mockups → #199 build) ran this cleanly: a Sabyasachi-inspired mockup exploration first established the look as its own PR; the chosen direction was *named* ("Nocturne") so it became a referenceable concept rather than a vague "dark mode"; the genuinely-open decisions (accent treatment, where the toggle lives) were surfaced via AskUserQuestion before any code; then the build shipped the palette/token layer and toggle while explicitly *deferring* the heavy ornamentation (damask, gold-foil text, crest, Roman numerals, double frames) to a polish follow-up. The deferral is what kept the build PR a coherent single concept (a token system, not a token system + decorative chrome). Reusable shape for any look-led feature: explore visually and commit the mockups first, name the result, ask the user only the truly-open variables, then build the structural layer and defer the decorative layer. <!-- Source: post-mortem, baby-name-picker #198/#199, 2026-06-17 -->

- **For a DESTRUCTIVE production migration/backfill, complete the FULL review gate (and ideally land the PR) BEFORE applying it to prod — even with explicit user authorization to apply. The correct ordering is gate-pass → merge → apply, never approve-dry-run → apply → gate.** second-brain #750 (one-time tag-canonicalization backfill that rewrites `tags.name` and merges UNIQUE collisions) was applied to prod — dry-run reviewed (5 renames), user-approved, `--apply` run, idempotency verified — and ONLY THEN did the adversarial gate run and FAIL TWICE: (1) the grouping-map delimiter was a literal NUL byte (`\x00`), which made git classify the `.ts` as **binary** and the PR diff unreviewable — and that defect had passed lint, `tsc`, 2300 tests, AND a 3-lens perspective-diverse code review (data-loss / idempotency-concurrency / SQL-edge-case, verdict SHIP-READY); only git's binary classification surfaced it (now Tier-0 check 0.29). (2) Fixing the NUL turned the file back into text, which then exposed a pre-existing non-`.trim()` env guard (Tier-0 0.9). The outcome was clean (the gate's findings were a reviewability defect and a guard, not a data-loss bug), but the ordering created a window in which an **un-gated destructive script touched production** — and the very gate that ran late is the one layer that caught what lint/tsc/tests/3-lens-review all missed. The whole point of the adversarial gate on destructive work is to catch the class of defect every other layer misses; running it AFTER the irreversible action forfeits that protection for the one operation that least tolerates it. Rule: treat "apply a destructive/irreversible migration to prod" as a step that is GATED on the same completed review the merge is gated on — explicit user authorization to apply is permission for the *action*, not a waiver of the *review ordering*. A reviewed dry-run is necessary but not sufficient; the dry-run shows the *plan*, the adversarial gate vets the *executor*, and on #750 the executor was the part that was broken. Pairs with database-patterns.md's rename-survivor-last/dry-run-by-default backfill mechanics (the *how*) — this is the *when*: gate fully, then apply. <!-- Source: post-mortem, second-brain #750, 2026-06-26 -->

## Product Discovery

- When a user reports a bug, the fix is tactical but the pattern is strategic. Ask: "What were you trying to accomplish when you hit this?" — the answer reveals workflow assumptions.
- Feature requests encode unspoken product intuitions. Before implementing, ask: "What changed in your usage that made this feel necessary?" and "What are you doing manually right now that this would replace?"
- Changes requested to existing features reveal where the original design assumption broke. Capture the delta between "what we assumed" and "what actually happened."

## Data Presentation

- When a record is simply absent from a dataset (not measured, out of scope), **omit the whole section rather than rendering a "no data" explainer.** An explainer reads as a negative judgment about the item ("unpopular," "missing") when it really only reflects a coverage gap in the source. Especially load-bearing when the dataset has a cultural/geographic bias (e.g. US-only SSA name popularity vs. a multicultural catalog) — a "no US data" label on a foreign name implies it's unpopular, which is the opposite of true.
<!-- Source: baby-name-picker popularity-trends (#54) — no-US-data → omit section, 2026-05-27 -->
- Prefer showing raw data over derived tiers/buckets when the cutoffs would be arbitrary. Bucketing a continuous metric (e.g. SSA rank → "Rare"/"Popular") imports judgmental labels and invented thresholds; the raw series is more accurate and lets the user interpret. Add interpretive labels only when the cutoffs are principled, not convenient.
<!-- Source: baby-name-picker popularity-trends (#54) — kept trend arc over recency tiers, 2026-05-27 -->
- **A derived signal must measure preference relative to exposure, not absolute exposure — in a deliberately diverse catalog, an absolute-count threshold measures the catalog, not the user.** The Cosmopolitan taste archetype fired on an absolute "4+ distinct cultural families" count, but because the matchmaker shows a multicultural catalog, that floor was cleared by exposure rather than choice — defaulting most signal-less users into Cosmopolitan and over-claiming intent. The fix made it relative: winners' family diversity must exceed seen-families' diversity (inverse-Simpson / Hill q=2 effective-count ratio > 1.15), and the tell-copy branches by which clause fired so the "wider range than you were shown" claim is only made when literally true. Generalizes to any "user is into X" inference over a curated feed: compare the user's kept distribution against the distribution they were *shown*, never against an absolute count the feed's composition can satisfy on its own. **Pairs with the deferred phonetic-texture signal:** relative-Cosmopolitan is the *residual* archetype (priority #9) — it should fire rarely, only for genuine over-diversifiers. The deferred phonetic-texture signal is its complement: it gives soft/sound-based tastes a real home earlier in the priority order so they never fall through to this residual. Ship the two together (or sequence texture next) to fully drain the false-Cosmopolitan bucket; tightening the residual alone leaves soft-taste users with no archetype until texture lands.
<!-- Source: post-mortem, baby-name-picker #165, 2026-06-02 -->
