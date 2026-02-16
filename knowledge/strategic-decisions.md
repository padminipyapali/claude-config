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

## Security & Multi-Tenancy

- Multi-tenant access control from day one, even for single-user MVPs. Retrofitting authorization is 10x harder than building it in. Define roles (owner, member, viewer) at the data layer before writing UI.
<!-- Source: nanny-app Firebase security rules; second-brain user_id scoping -->

## Monitoring & Observability

- Dashboard-only mode: monitoring tools should work independently of the systems they monitor. If your monitoring bot goes down, you should still see status via a web dashboard (and vice versa).
<!-- Source: command-center dashboard-only mode decision -->

- Sequential task queues for agent delegation. Predictable ordering beats throughput for personal tools — you want to understand what happened, not process things fast.
<!-- Source: command-center sequential queue decision -->

## Product Discovery

- When a user reports a bug, the fix is tactical but the pattern is strategic. Ask: "What were you trying to accomplish when you hit this?" — the answer reveals workflow assumptions.
- Feature requests encode unspoken product intuitions. Before implementing, ask: "What changed in your usage that made this feel necessary?" and "What are you doing manually right now that this would replace?"
- Changes requested to existing features reveal where the original design assumption broke. Capture the delta between "what we assumed" and "what actually happened."
