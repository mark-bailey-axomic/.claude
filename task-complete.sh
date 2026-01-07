#!/bin/bash
# Reads Stop hook input and announces what was completed

# Read JSON from stdin
input=$(cat)

# Extract transcript path
transcript_path=$(echo "$input" | /usr/bin/python3 -c "import sys, json; print(json.load(sys.stdin).get('transcript_path', ''))" 2>/dev/null)

if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
  say "Task complete"
  exit 0
fi

# Parse JSONL transcript to find last significant action
summary=$(/usr/bin/python3 -c "
import json
import sys
import re

def clean_tool_name(name):
    # Remove mcp__ prefix and server name (e.g., mcp__atlassian__getJiraIssue -> getJiraIssue)
    if name.startswith('mcp__'):
        parts = name.split('__')
        if len(parts) >= 3:
            name = parts[-1]

    # Convert camelCase/PascalCase to spaces
    # insertBefore -> insert Before, getJiraIssue -> get Jira Issue
    name = re.sub(r'([a-z])([A-Z])', r'\1 \2', name)
    name = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', name)

    # Capitalize first letter of each word
    return name.title()

try:
    transcript_path = sys.argv[1]
    last_action = None

    with open(transcript_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except:
                continue

            if entry.get('type') != 'assistant':
                continue

            message = entry.get('message', {})
            content = message.get('content', [])

            if not isinstance(content, list):
                continue

            for item in content:
                if item.get('type') != 'tool_use':
                    continue

                tool = item.get('name', '')
                tool_input = item.get('input', {})

                if tool == 'Skill':
                    skill = tool_input.get('skill', 'unknown')
                    last_action = skill.replace('-', ' ').title()
                elif tool == 'Task':
                    desc = tool_input.get('description', 'task')
                    last_action = desc
                elif tool in ('Write', 'Edit'):
                    path = tool_input.get('file_path', '')
                    filename = path.split('/')[-1] if path else 'file'
                    last_action = 'Edited ' + filename
                elif tool == 'Bash':
                    desc = tool_input.get('description', '')
                    if desc:
                        last_action = desc
                    else:
                        last_action = 'Command'
                elif tool == 'Read':
                    path = tool_input.get('file_path', '')
                    filename = path.split('/')[-1] if path else 'file'
                    last_action = 'Read ' + filename
                elif tool:
                    last_action = clean_tool_name(tool)

    print(last_action or 'Task')
except Exception as e:
    print('Task')
" "$transcript_path")

say "${summary} complete"
