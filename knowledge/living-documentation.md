# Living Documentation

Documentation is organized **by feature**, not by type. Everything about a feature lives together.

## Directory Structure

```
docs/
  product-spec.md              # overall product direction & roadmap
  features/
    <feature-name>/
      spec.md                  # feature spec (starts as proposal, evolves)
      mockups/                 # UI mockups (self-contained HTML)
      explainers/              # flow diagrams, architecture docs, tech docs
      decisions.md             # feature-scoped decisions
      bugs.md                  # feature-scoped bugs
      post-mortems/            # one file per PR/incident
    _cross-cutting/            # for things spanning multiple features
      decisions.md
      bugs.md
```

## Rules

- Create feature directories only when there's content — not for theoretical features.
- Specs start in `docs/specs/` during ideation, move to `docs/features/<feature>/spec.md` at implementation.
- Every PR should update relevant feature docs. Cross-cutting changes update `_cross-cutting/`.
- `product-spec.md` stays top-level as the bird's-eye view.
- QA entries go in the feature's `decisions.md`.

## Flow Diagrams

For features spanning **3+ systems**, create `docs/features/<feature-name>/explainers/flow-diagram.html` via `/flow-diagram`.

- **Create when:** Crosses network boundaries or has non-obvious failure modes.
- **Skip when:** Single-component, simple CRUD, or UI-only.
- **Required sections:** Step-by-step flow, technologies & vendors (with doc links), security notes (if applicable), failure mode table.
