---
name: review-fix-loop
description: Schedule recurring review-fix cycles on a PR until all comments are addressed and the PR is approved
allowed-tools: Read, Grep, Bash, Glob, CronCreate, CronDelete
argument-hint: "<pr-number> [interval] [expire:<duration>]"
---

# Review-Fix Loop

Schedule a recurring `/review-fix` cycle on PR `$ARGUMENTS` until all reviewer comments are addressed and the PR is approved.

## Parsing Arguments

Parse `$ARGUMENTS` into `<pr-number>` and optional `[interval]`:

1. The first token must be a number (the PR number). If missing, show usage: `/review-fix-loop <pr-number> [interval] [expire:<duration>]` and stop.
2. The second token (if present) is the interval. Accept formats: `5m`, `10m`, `1h`, `5 mins`, `5 minutes`, `10 min`. Extract the numeric value and unit.
3. If no interval is provided, default to `5m`.
4. Look for an expiration duration anywhere in the arguments. Accept formats: `expire:1h`, `expire:30m`, `expire:2h`, or natural language like `expire in 1 hour`, `expire after 30m`, `expire this at 1 hour`. Extract the duration. If not provided, **default to `expire:30m`** — review-fix loops rarely need to run longer than 30 minutes unattended.

## Interval to Cron

| Interval | Cron |
|----------|------|
| `Nm` where N <= 59 | `*/N * * * *` |
| `Nm` where N >= 60 | `0 */H * * *` (H = N/60) |
| `Nh` | `0 */N * * *` |

If the interval doesn't cleanly divide its unit, round to the nearest clean value and tell the user.

## Action

1. Call CronCreate with:
   - `cron`: the expression from the table
   - `prompt`: `/review-fix <pr-number>`
   - `recurring`: `true`

2. If an expiration duration was specified, schedule a one-shot CronCreate to cancel the review-fix job:
   - Convert the expiration duration to a specific time (now + duration).
   - `cron`: pin to the exact minute/hour/day-of-month/month of the expiration time.
   - `prompt`: `Cancel review-fix loop for PR #<pr-number> (job <job-id>) — expiration reached. Use CronDelete to remove job <job-id>.`
   - `recurring`: `false`

## Response

Confirm to the user:
- What's scheduled: `/review-fix <pr-number>` every `<interval>`
- The cron expression
- Expiration: if set, when it expires. If not set, that it auto-expires after 3 days.
- The job ID and how to cancel with CronDelete
