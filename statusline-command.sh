#!/usr/bin/env bash
# Claude Code status line command
# Reads JSON from stdin and outputs a formatted status line

input=$(cat)

user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
cwd="${cwd/#$HOME/~}"

# Git info — skip optional locks to avoid blocking
git_branch=$(git -C "${cwd/#\~/$HOME}" --no-optional-locks branch --show-current 2>/dev/null)
git_repo=$(git -C "${cwd/#\~/$HOME}" --no-optional-locks rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null)

# Build status parts
parts="${user}@${host} ${cwd}"

if [ -n "$git_repo" ] && [ -n "$git_branch" ]; then
    parts="${parts} (${git_repo}:${git_branch})"
elif [ -n "$git_repo" ]; then
    parts="${parts} (${git_repo})"
fi

if [ -n "$model" ]; then
    parts="${parts} | ${model}"
fi

if [ -n "$used" ]; then
    used_int=${used%.*}
    parts="${parts} | ctx ${used_int}%"
fi

printf "%s" "$parts"
