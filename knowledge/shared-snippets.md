# Shared Code Snippets

Canonical implementations of small utilities that recur across projects. Copy these into new projects rather than reimplementing — the subtle details (regex flavors, trim-vs-falsy, NaN guards) have caused bugs when reimplemented from scratch.

**When to use:** During `/project-setup` or when adding a feature that needs one of these patterns. Copy the function into the project's own utils — do NOT create a shared npm package for these (see adversarial review, 2026-03-18).

---

## String Escaping

### escapeXml

Sanitize user input before embedding in Claude API XML-tagged prompts. Prevents prompt injection via XML metacharacters.

```typescript
export function escapeXml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}
```

**Used in:** Leaflet (`server/helpers.ts`), Second Brain (`services/response.ts`)

### stripFences

Strip markdown code fences from LLM output before `JSON.parse()`. Use `\w*` (not just `json`) — models sometimes emit ` ```typescript ` or bare ` ``` `.

```typescript
export function stripFences(str: string): string {
  return str.replace(/^```(?:\w*)\s*\n?/i, "").replace(/\n?```\s*$/i, "");
}
```

**Used in:** Leaflet (`server/helpers.ts`), Second Brain (`services/response.ts`)

**Related CLAUDE.md rule:** "Always strip markdown code fences before parsing LLM output as structured data."

---

## Input Validation

### requireNonEmpty

Guard against empty and whitespace-only strings at system boundaries. Returns the trimmed value so callers don't need to trim again.

```typescript
export function requireNonEmpty(value: string, fieldName: string): string {
  const trimmed = value.trim();
  if (!trimmed) throw new Error(`${fieldName} is required`);
  return trimmed;
}
```

**Why this exists:** `!text` misses whitespace-only strings (they're truthy in JS). `!text.trim()` is the correct guard but easy to forget. This function encodes the pattern once.

**Used in:** Sleep Tracker (`services/sleep-event.service.ts` — 10+ inline occurrences)

### validateDateString

Safe date parsing with NaN guard. Catches invalid date strings that `new Date()` silently accepts as `Invalid Date`.

```typescript
export function validateDateString(value: string, fieldName: string): Date {
  const date = new Date(value);
  if (isNaN(date.getTime())) throw new Error(`Invalid ${fieldName}: ${value}`);
  return date;
}
```

**Gotcha:** `new Date("2026-02-14T10:00:00")` without `Z` suffix parses in local timezone, making tests flaky on CI. Always use explicit timezone or UTC suffix.

**Used in:** Sleep Tracker (`services/time-utils.ts`, `services/sleep-event.service.ts`)

---

## Express Server Boilerplate

### Process signal handlers

Graceful shutdown boilerplate for Express/Node servers. Pass a cleanup callback for project-specific teardown (close DB pools, stop pollers, etc.).

```typescript
export function registerShutdownHandlers(cleanup: () => Promise<void>): void {
  process.on("unhandledRejection", (reason) => {
    console.error("Unhandled rejection:", reason);
  });
  process.on("uncaughtException", (err) => {
    console.error("Uncaught exception:", err);
    process.exit(1);
  });
  process.on("SIGTERM", async () => {
    console.log("SIGTERM received, shutting down...");
    await cleanup();
    process.exit(0);
  });
}
```

**Used in:** Command Center (`server.ts`), Second Brain (`server.ts`)

### Environment variable validation

Fail fast at startup if required env vars are missing. Call before any service initialization.

```typescript
export function requireEnvVars(keys: string[]): void {
  const missing = keys.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(", ")}`);
  }
}
```

**Used in:** Command Center, Leaflet, Second Brain — each reimplements this inline.

---

## Error Classes

Typed errors with semantic meaning for Express error-handling middleware. Map to HTTP status codes in a single middleware rather than scattering `res.status()` calls.

```typescript
export class NotFoundError extends Error {
  constructor(message: string) { super(message); this.name = "NotFoundError"; }
}

export class BadRequestError extends Error {
  constructor(message: string) { super(message); this.name = "BadRequestError"; }
}

export class ConflictError extends Error {
  constructor(message: string) { super(message); this.name = "ConflictError"; }
}
```

Pair with this middleware:

```typescript
export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction): void {
  if (err instanceof BadRequestError) { res.status(400).json({ error: err.message }); return; }
  if (err instanceof NotFoundError) { res.status(404).json({ error: err.message }); return; }
  if (err instanceof ConflictError) { res.status(409).json({ error: err.message }); return; }
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Internal server error" });
}
```

**Used in:** Second Brain (`services/errors.ts`). Other Express projects use ad-hoc status codes — consider adopting this pattern when the route count grows past ~5.
