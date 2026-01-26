#!/bin/bash
# setup.sh - Configure Claude Code MCP servers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prompt for employee code
read -p "Enter your employee code: " EMPLOYEE_CODE

# Prompt for GitHub reviewers (allow empty)
read -p "Enter GitHub reviewers (comma-separated, or leave empty): " GITHUB_REVIEWERS

# Create/update .env file
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"

if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
        echo "Creating .env from .env.example..."
        cp "$ENV_EXAMPLE" "$ENV_FILE"
    else
        echo "Creating new .env file..."
        touch "$ENV_FILE"
    fi
fi

# Update EMPLOYEE_CODE in .env
if grep -q "^EMPLOYEE_CODE=" "$ENV_FILE" 2>/dev/null; then
    sed -i '' "s/^EMPLOYEE_CODE=.*/EMPLOYEE_CODE=$EMPLOYEE_CODE/" "$ENV_FILE"
else
    echo "EMPLOYEE_CODE=$EMPLOYEE_CODE" >> "$ENV_FILE"
fi

# Update GITHUB_REVIEWERS in .env
if grep -q "^GITHUB_REVIEWERS=" "$ENV_FILE" 2>/dev/null; then
    sed -i '' "s/^GITHUB_REVIEWERS=.*/GITHUB_REVIEWERS=$GITHUB_REVIEWERS/" "$ENV_FILE"
else
    echo "GITHUB_REVIEWERS=$GITHUB_REVIEWERS" >> "$ENV_FILE"
fi

echo ".env file updated"
echo ""

echo "Setting up Claude Code MCP servers..."

MCP_LIST=$(TERM=xterm claude mcp list 2>/dev/null || true)

# Add Figma MCP server (if not exists)
if ! echo "$MCP_LIST" | grep -q "^figma:"; then
    echo "Adding Figma MCP server..."
    claude mcp add --transport http figma https://mcp.figma.com/mcp --scope user
else
    echo "Figma MCP server already configured"
fi

# Add Atlassian MCP server (if not exists)
if ! echo "$MCP_LIST" | grep -q "^atlassian:"; then
    echo "Adding Atlassian MCP server..."
    claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse --scope user
else
    echo "Atlassian MCP server already configured"
fi

echo ""
echo "Run '/mcp' in Claude Code to authenticate each server."
echo ""
claude mcp list
