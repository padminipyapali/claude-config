---
name: review-fix-loop
description: Schedule recurring review-fix cycles on a PR until all comments are addressed and the PR is approved
allowed-tools: Read, Grep, Bash, Glob, CronCreate
argument-hint: "<pr-number> [interval]"
---

# Review-Fix Loop

Schedule a recurring `/review-fix` cycle on PR `$ARGUMENTS` until all reviewer comments are addressed and the PR is approved.

## Parsing Arguments

Parse `$ARGUMENTS` into `<pr-number>` and optional `[interval]`:

1. The first token must be a number (the PR number). If missing, show usage: `/review-fix-loop <pr-number> [interval]` and stop.
2. The second token (if present) is the interval. Accept formats: `5m`, `10m`, `1h`, `5 mins`, `5 minutes`, `10 min`. Extract the numeric value and unit.
3. If no interval is provided, default to `5m`.

## Interval to Cron

| Interval | Cron |
|----------|------|
| `Nm` where N <= 59 | `*/N * * * *` |
| `Nm` where N >= 60 | `0 */H * * *` (H = N/60) |
| `Nh` | `0 */N * * *` |

If the interval doesn't cleanly divide its unit, round to the nearest clean value and tell the user.

## Action

Call CronCreate with:
- `cron`: the expression from the table
- `prompt`: `/review-fix <pr-number>`
- `recurring`: `true`

## Response

Confirm to the user:
- What's scheduled: `/review-fix <pr-number>` every `<interval>`
- The cron expression
- That recurring tasks auto-expire after 3 days
- The job ID and how to cancel with CronDelete
