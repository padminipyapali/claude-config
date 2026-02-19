# Session Tracker

Run the session tracker to show coding productivity across repos grouped by sessions.

Execute `~/.claude/bin/pump-sessions` with any arguments the user provides (default: last 24 hours).

Arguments:
- Time range: `48` (hours), `7d` (days) — default: 24 hours
- `--html` — generate a visual HTML report and open it with `open`

Examples:
- `pump-sessions` — terminal, last 24h
- `pump-sessions 7d` — terminal, last 7 days
- `pump-sessions --html 7d` — HTML report, last 7 days

Show the output to the user. After showing results, offer a brief encouraging comment.
