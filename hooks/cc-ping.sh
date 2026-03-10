#!/bin/bash
# Command Center live activity ping hook.
#
# Fires on SessionStart, PostToolUse, and SessionEnd to report agent
# activity to the CC dashboard. All calls are fire-and-forget.
#
# Required env vars (set in ~/.zshrc, NOT in settings.json):
#   CC_API_URL       — e.g., https://your-app.railway.app
#   CC_WEBHOOK_TOKEN — shared secret for X-CC-Token header

set -euo pipefail

# Always consume stdin first to avoid broken pipe.
INPUT=$(cat)

# Skip if env vars are not configured.
if [ -z "${CC_API_URL:-}" ] || [ -z "${CC_WEBHOOK_TOKEN:-}" ]; then
  exit 0
fi

# Skip if running inside a subagent (agent_id is only present in subagent context).
AGENT_ID_FIELD=$(echo "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null)
if [ -n "$AGENT_ID_FIELD" ]; then
  exit 0
fi

# Extract hook event info.
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

if [ -z "$EVENT" ] || [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Derive agent identity from the git repo.
REPO_ROOT=$(git -C "${CWD:-.}" rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$REPO_ROOT" ]; then
  exit 0  # Not in a git repo — nothing to report.
fi

# Resolve the real repo root (worktrees report their own path, not the main repo).
MAIN_REPO=$(git -C "$REPO_ROOT" rev-parse --show-superproject-working-tree 2>/dev/null || echo "")
REPO_NAME=$(basename "${MAIN_REPO:-$REPO_ROOT}")
SHORT_SESSION="${SESSION_ID:0:8}"
PING_AGENT_ID="${REPO_NAME}-${SHORT_SESSION}"
PING_AGENT_NAME="${REPO_NAME}"

# Project slug — CC uses repo name as slug.
PROJECT_SLUG="$REPO_NAME"

# Description file — agents write a one-sentence description here.
DESC_FILE="/tmp/cc-ping-desc-${SHORT_SESSION}"

# Current branch name for live activity display.
BRANCH_NAME=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "")

# Temp file paths (per-session to avoid cross-session interference).
HEARTBEAT_FILE="/tmp/cc-ping-heartbeat-${PING_AGENT_ID}"
PR_CACHE_FILE="/tmp/cc-ping-pr-${PING_AGENT_ID}"

# --- PR detection (cached, only re-runs when branch changes) ---

detect_pr() {
  local branch
  branch=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "")
  if [ -z "$branch" ]; then
    echo ""
    return
  fi

  local cached_branch=""
  local cached_pr=""
  if [ -f "$PR_CACHE_FILE" ]; then
    cached_branch=$(head -1 "$PR_CACHE_FILE" 2>/dev/null || echo "")
    cached_pr=$(tail -1 "$PR_CACHE_FILE" 2>/dev/null || echo "")
  fi

  if [ "$branch" = "$cached_branch" ]; then
    echo "$cached_pr"
    return
  fi

  # Branch changed — re-detect PR.
  local pr_number
  pr_number=$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null || echo "")
  printf '%s\n%s\n' "$branch" "$pr_number" > "$PR_CACHE_FILE"
  echo "$pr_number"
}

# --- Build JSON payload ---

build_payload() {
  local activity="$1"
  local pr_number
  pr_number=$(detect_pr)

  # Read description from temp file if it exists.
  local description=""
  if [ -f "$DESC_FILE" ]; then
    description=$(head -1 "$DESC_FILE" 2>/dev/null || echo "")
  fi

  local payload
  payload=$(jq -n \
    --arg agentId "$PING_AGENT_ID" \
    --arg agentName "$PING_AGENT_NAME" \
    --arg projectSlug "$PROJECT_SLUG" \
    --arg activity "$activity" \
    --arg prNumber "${pr_number:-}" \
    --arg branchName "${BRANCH_NAME:-}" \
    --arg description "$description" \
    '{
      agentId: $agentId,
      agentName: $agentName,
      projectSlug: $projectSlug,
      activity: $activity
    } + (if $prNumber != "" then { prNumber: ($prNumber | tonumber) } else {} end)
      + (if $branchName != "" then { branchName: $branchName } else {} end)
      + (if $description != "" then { description: $description } else {} end)'
  )
  echo "$payload"
}

# --- Send ping ---

send_ping() {
  local activity="$1"
  local payload
  payload=$(build_payload "$activity")

  curl -s -X POST "${CC_API_URL}/api/pings" \
    -H "Content-Type: application/json" \
    -H "X-CC-Token: ${CC_WEBHOOK_TOKEN}" \
    -d "$payload" \
    --connect-timeout 5 \
    --max-time 10 \
    >/dev/null 2>&1 || true
}

# --- Delete ping ---

delete_ping() {
  curl -s -X DELETE "${CC_API_URL}/api/pings/${PING_AGENT_ID}" \
    -H "X-CC-Token: ${CC_WEBHOOK_TOKEN}" \
    --connect-timeout 5 \
    --max-time 10 \
    >/dev/null 2>&1 || true
}

# --- Dispatch on event ---

case "$EVENT" in
  SessionStart)
    send_ping "Starting session"
    date +%s > "$HEARTBEAT_FILE"
    ;;

  PostToolUse)
    # Debounce: skip if less than 60s since last ping.
    if [ -f "$HEARTBEAT_FILE" ]; then
      LAST=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo "0")
      NOW=$(date +%s)
      if [ $((NOW - LAST)) -lt 60 ]; then
        exit 0
      fi
    fi
    send_ping "Active"
    date +%s > "$HEARTBEAT_FILE"
    ;;

  SessionEnd)
    delete_ping
    # Clean up temp files.
    rm -f "$HEARTBEAT_FILE" "$PR_CACHE_FILE" "$DESC_FILE"
    ;;
esac

exit 0
