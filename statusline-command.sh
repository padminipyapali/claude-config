#!/usr/bin/env bash
# Claude Code status line command — Rich preset
# Format: user@host:dir | git-branch | model | context remaining
# Reads JSON from stdin and outputs a formatted status line

input=$(cat)

user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten home directory to ~
cwd="${cwd/#$HOME/~}"

# Resolve ~ back to full path for git commands
cwd_full="${cwd/#\~/$HOME}"

# Git branch — skip optional locks to avoid blocking
git_branch=$(git -C "$cwd_full" --no-optional-locks branch --show-current 2>/dev/null)

# Build status line: user@host:dir
parts="${user}@${host}:${cwd}"

# Append git branch if available
if [ -n "$git_branch" ]; then
    parts="${parts} | ${git_branch}"
fi

# Append model if available
if [ -n "$model" ]; then
    parts="${parts} | ${model}"
fi

# Append context remaining if available
if [ -n "$remaining" ]; then
    remaining_int=${remaining%.*}
    parts="${parts} | ctx ${remaining_int}% remaining"
fi

printf "%s" "$parts"
