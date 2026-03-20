# Chaining Skills with Hooks

Use hooks to automatically invoke one skill before/after another.

## Config

In `.claude/settings.json` or `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/chain-skills.sh"
          }
        ]
      }
    ]
  }
}
```

## Hook Script

`~/.claude/hooks/chain-skills.sh`:

```bash
skill=$(jq -r '.tool_input.skill' < /dev/stdin)

if [[ "$skill" == "review" ]]; then
  cat <<'EOF'
{
  "result": "IMPORTANT: Before proceeding with /review, first invoke /coding-guidelines to load the coding rules, then invoke /review."
}
EOF
  exit 2
fi
```

## How It Works

1. **`PreToolUse`** fires before any tool call
2. **`matcher: "Skill"`** filters to only Skill tool invocations
3. Script checks if the skill being invoked is `/review`
4. If match: injects instructions to run `/coding-guidelines` first, then **exit 2 blocks** the original `/review` so Claude runs guidelines before retrying review
5. If no match: exits 0 (implicit), skill proceeds normally

## Exit Codes

| Code | Behavior |
|------|----------|
| `0`  | Allow — skill proceeds, `result` field shown to Claude as context |
| `2`  | Block — skill is stopped, `result` tells Claude what to do instead |

## Pre vs Post

- **`PreToolUse`** — chain skills that set up context (e.g., load guidelines before review)
- **`PostToolUse`** — chain skills that act on output (e.g., simplify after review)

## Detecting User-Typed vs Claude-Triggered

| Source | Hook |
|--------|------|
| User types `/review` | `UserPromptSubmit` — check `prompt` field |
| Claude calls Skill tool | `PreToolUse` with matcher `Skill` — check `tool_input.skill` |

To cover both, configure both hooks.
