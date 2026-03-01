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

## Product Discovery

- When a user reports a bug, the fix is tactical but the pattern is strategic. Ask: "What were you trying to accomplish when you hit this?" — the answer reveals workflow assumptions.
- Feature requests encode unspoken product intuitions. Before implementing, ask: "What changed in your usage that made this feel necessary?" and "What are you doing manually right now that this would replace?"
- Changes requested to existing features reveal where the original design assumption broke. Capture the delta between "what we assumed" and "what actually happened."
