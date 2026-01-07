#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r ".workspace.current_dir")
model=$(echo "$input" | jq -r ".model.display_name")

# Change to the working directory
cd "$cwd" 2>/dev/null || cd ~

# Calculate time until reset (4pm GMT)
now_gmt=$(TZ=GMT date +%s)
today_4pm_gmt=$(TZ=GMT date -v16H -v0M -v0S +%s)

if [ $now_gmt -lt $today_4pm_gmt ]; then
    reset_time=$today_4pm_gmt
else
    reset_time=$(TZ=GMT date -v+1d -v16H -v0M -v0S +%s)
fi

seconds_left=$((reset_time - now_gmt))
hours=$((seconds_left / 3600))
minutes=$(((seconds_left % 3600) / 60))

# Get cost data from JSON input and estimate tokens
total_cost=$(echo "$input" | jq -r ".cost.total_cost_usd // empty")
token_display=""

if [ -n "$total_cost" ] && [ "$total_cost" != "null" ] && [ "$total_cost" != "0" ]; then
    # Estimate tokens from cost
    # Sonnet 4.5: ~$3/M input, ~$15/M output
    # Assume average of ~$6/M tokens (typical input/output mix)
    estimated_tokens=$(echo "$total_cost * 1000000 / 6" | bc 2>/dev/null || echo 0)

    # Calculate percentage of 200K context window
    context_limit=200000
    usage_percent=$(awk "BEGIN {printf \"%.1f\", ($estimated_tokens / $context_limit) * 100}")

    # Format percentage for comparison (get integer part)
    usage_percent_int=$(echo "$usage_percent" | awk -F. '{print $1}')

    # Color code based on percentage thresholds
    if [ "$usage_percent_int" -lt 50 ]; then
        token_color="32"  # Green (< 50%)
    elif [ "$usage_percent_int" -lt 80 ]; then
        token_color="33"  # Yellow (50-80%)
    else
        token_color="31"  # Red (>= 80%)
    fi

    token_display=" | 📊 \033[${token_color}m${usage_percent}%\033[0m"
fi

# Get sandbox mode status from settings file
settings_file="$HOME/.claude/settings.local.json"
if [ -f "$settings_file" ]; then
    sandbox_enabled=$(jq -r ".sandbox.enabled // false" "$settings_file" 2>/dev/null)
else
    sandbox_enabled="false"
fi

if [ "$sandbox_enabled" = "true" ]; then
    sandbox_display=" | 🏖️ \033[32mSandbox\033[0m"
else
    sandbox_display=" | 🚫 \033[38;2;255;165;0mSandbox Off\033[0m"
fi

# Build status line based on git status
if git rev-parse --git-dir > /dev/null 2>&1; then
    # In a git repository
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -n "$remote_url" ]; then
        # Extract account and repo from remote URL
        account=$(echo "$remote_url" | sed -E "s#.*[:/]([^/]+)/([^/]+)(\.git)?\$#\1#")
        repo=$(echo "$remote_url" | sed -E "s#.*[:/]([^/]+)/([^/]+)(\.git)?\$#\2#" | sed "s/\.git\$//")
    else
        # No remote - try package.json, fallback to directory name
        git_root=$(git rev-parse --show-toplevel)
        if [ -f "$git_root/package.json" ]; then
            repo=$(jq -r ".name // empty" "$git_root/package.json" 2>/dev/null)
            if [ -z "$repo" ] || [ "$repo" = "null" ]; then
                repo=$(basename "$git_root")
            fi
        else
            repo=$(basename "$git_root")
        fi
        account=""
    fi
    branch_name=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    if [ -n "$account" ]; then
        printf "🐙 \033[36m%s\033[0m/\033[92m%s\033[0m (\033[33m%s\033[0m) | 🤖 \033[35m%s\033[0m | ⏳ \033[33m%dh %dm\033[0m%b%b" \
            "$account" "$repo" "$branch_name" "$model" "$hours" "$minutes" "$token_display" "$sandbox_display"
    else
        printf "🐙 \033[92m%s\033[0m (\033[33m%s\033[0m) | 🤖 \033[35m%s\033[0m | ⏳ \033[33m%dh %dm\033[0m%b%b" \
            "$repo" "$branch_name" "$model" "$hours" "$minutes" "$token_display" "$sandbox_display"
    fi
else
    # Not in a git repository
    printf "\033[37m%s\033[0m | 🤖 \033[35m%s\033[0m | ⏳ \033[33m%dh %dm\033[0m%b%b" \
        "$cwd" "$model" "$hours" "$minutes" "$token_display" "$sandbox_display"
fi
