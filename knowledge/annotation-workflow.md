# Annotation Feedback Workflow

How the mockup/page annotation system works and how to pick up user feedback.

## Architecture

1. **Inbox server** (`node ~/.claude/tools/inbox-server.js`) — runs on `localhost:9876`. Serves the annotation script (`annotate.js`) and accepts feedback via `POST /inbox`.
2. **Bookmarklet** (installed in user's bookmarks bar) — a tiny loader that injects `annotate.js` from `localhost:9876`. Installer page: `~/.claude/tools/annotate-install.html`.
3. **Feedback files** — saved to `~/.claude/inbox/<timestamp>.json` by the inbox server.

## Key Paths

| What | Path |
|------|------|
| Inbox server script | `~/.claude/tools/inbox-server.js` |
| Bookmarklet installer | `~/.claude/tools/annotate-install.html` |
| Annotation script | Served by inbox server at `localhost:9876/annotate.js` |
| Feedback inbox | `~/.claude/inbox/` |

## Feedback JSON Format

Each file in `~/.claude/inbox/` is a JSON object containing:

- `url` — which page was annotated (identifies the source page)
- `annotations` — array of user feedback entries with coordinates, text, and screenshots
- `timestamp` — when the feedback was submitted

## How Annotations Get Created

- **For mockups we create:** Inline `annotate.js` at the bottom of the HTML file before `</body>`. No bookmarklet needed — annotation UI is built in.
- **For dev server / production pages:** User clicks the bookmarklet in their browser. It injects the annotation UI. Feedback POSTs to `localhost:9876/inbox`.
- **After annotating:** Annotations auto-clear from the page.
- **Fallback:** If the inbox server is down, the script falls back to a file download (user would need to manually place the JSON in `~/.claude/inbox/`).

## Session Start Protocol (MANDATORY)

Every Claude Code session must do these steps automatically — do not wait for the user to ask:

1. **Check for pending annotations:**
   ```bash
   ls ~/.claude/inbox/*.json 2>/dev/null
   ```
   Read each JSON file, process the feedback, then delete the file.

2. **Start a background inbox poller** — check `~/.claude/inbox/*.json` every ~10 seconds so mid-session annotations are picked up automatically.

3. **Start the inbox server** if it's not already running:
   ```bash
   # Check if already running
   lsof -i :9876 2>/dev/null
   # If not, start it
   node ~/.claude/tools/inbox-server.js &
   ```

## After Building Visual Features

1. Start the inbox server if not already running.
2. Tell the user to open the page and annotate (bookmarklet for dev server pages, built-in for mockups).
3. Poll the inbox for feedback.

## No Playwright Needed

The annotation workflow opens in the user's own browser. No headless browser, no Chrome conflicts.
