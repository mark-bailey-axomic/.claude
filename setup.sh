#!/bin/bash
# setup.sh - Configure Claude Code MCP servers

set -e

echo "Setting up Claude Code MCP servers..."

# Add Figma MCP server
echo "Adding Figma MCP server..."
claude mcp add --transport http figma https://mcp.figma.com/mcp --scope user

# Add Atlassian MCP server (Jira, Confluence, Compass)
echo "Adding Atlassian MCP server..."
claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse --scope user

echo ""
echo "MCP servers added. Run '/mcp' in Claude Code to authenticate each server."
echo ""
claude mcp list
