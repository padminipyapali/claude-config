# Pumping Session Tracker

Run the session tracker to show productivity across repos grouped by pumping sessions.

Execute `~/.claude/bin/pump-sessions` with any arguments the user provides (default: last 24 hours).

Show the output to the user. If the user asks for a specific time range, pass it as the first argument:
- `pump-sessions 48` — last 48 hours
- `pump-sessions 7d` — last 7 days

After showing the output, offer a brief encouraging comment about the session productivity.
