# Session Tracker

Run the session tracker to show coding productivity across repos grouped by sessions.

Execute `~/.claude/bin/sessions` with any arguments the user provides (default: last 24 hours).

Arguments:
- Time range: `48` (hours), `7d` (days) — default: 24 hours
- `--html` — generate a visual HTML report and open it with `open`

Examples:
- `sessions` — terminal, last 24h
- `sessions 7d` — terminal, last 7 days
- `sessions --html 7d` — HTML report, last 7 days

Show the output to the user. After showing results, offer a brief encouraging comment.
