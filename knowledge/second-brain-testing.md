# Second Brain — Local Testing Instructions

How to run and test the second-brain (innershelf.xyz) project locally.

## Project Structure

Monorepo with npm workspaces:
- `packages/web/` — React + Vite frontend (port 5173 by default)
- `packages/server/` — Express API + Telegram bot (port 3000)
- `packages/shared/` — Shared types

## Starting the Frontend (UI-only testing)

```bash
cd /Users/padminipyapali/dev/second-brain/packages/web
npx vite --port 5174
```

Vite reads env vars from the monorepo root (`envDir: resolve(__dirname, "../..")`), so `.env` lives at `/Users/padminipyapali/dev/second-brain/.env`.

The frontend proxies `/api` requests to `http://localhost:3000` (configured in `vite.config.ts`). For UI-only checks (layout, CSS, component rendering), the backend isn't needed — API calls will fail but the UI renders.

## Bypassing Login

Auth is controlled by two env vars: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.

- **If both are unset (or commented out):** Auth is completely bypassed. `supabase.ts` returns `null`, `AuthProvider` sets `authEnabled: false`, and `App.tsx` skips the `LoginPage` gate. You go straight to the Dashboard.
- **If both are set:** Supabase Auth is active. You'll see the login page with magic link email sign-in.

For local UI testing, simply ensure these vars are NOT set. There is no `.env` file checked in — if one exists at the monorepo root, check that `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are commented out.

## Starting the Full Stack (API + frontend)

For testing that requires working API calls (creating entries, AI responses, etc.):

1. Copy `.env.example` to `.env` at the monorepo root.
2. Fill in required vars: `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_TOKEN`, `VITE_API_TOKEN` (must match `API_TOKEN`).
3. Start the server: `cd packages/server && npm run dev` (uses tsx watch, port 3000).
4. Start the frontend: `cd packages/web && npm run dev` (Vite, port 5173).
5. The Vite proxy forwards `/api` to `localhost:3000` automatically.

## Pre-PR Checks

```bash
npm run lint    # Biome
npm run build   # TypeScript compilation
npm test        # Vitest
```

Run from the monorepo root.

## Cleanup

Always kill the dev server after testing. If started in background:
```bash
pkill -f "vite.*5174"
```

Switch back to main if you checked out a feature branch:
```bash
git -C /Users/padminipyapali/dev/second-brain checkout main
```
