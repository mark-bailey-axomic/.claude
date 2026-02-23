# Statusline Module Plan

## Context
Configurable Python statusline for Claude Code. Receives session JSON via stdin, outputs formatted status bar. Wired up in `settings.json`.

## Architecture
Single file `statusline.py` + `config.json`. Stdlib only (no pip deps).

## Config Schema (`config.json`)
```json
{
  "modules": [
    {"id": "git",     "enabled": true, "fg": "#c0caf5", "bg": null},
    {"id": "model",   "enabled": true, "fg": "#7aa2f7", "bg": null},
    {"id": "reset",   "enabled": true, "fg": "#e0af68", "bg": null},
    {"id": "daily",   "enabled": true, "fg": "#9ece6a", "bg": null},
    {"id": "weekly",  "enabled": true, "fg": "#bb9af7", "bg": null},
    {"id": "sandbox", "enabled": true, "fg": "#f7768e", "bg": null}
  ],
  "separator": " | ",
  "icons": "emoji",
  "cache_ttl_seconds": 10,
  "block_hours": 5,
  "limits": {
    "daily_tokens": 0,
    "weekly_tokens": 0
  }
}
```
- Array order = display order. Rearrange to reorder.
- `fg`/`bg`: hex (`#ff0000`), named ANSI (`red`, `green`), or `null` (default)
- `icons`: `"emoji"` (default) or `"nerd"` (Nerd Font glyphs)
- `limits`: token limits for % calc. 0 = show raw token count instead.

## Modules

### 1. `git` -- GitHub repo/branch
- `git branch --show-current` + `git remote get-url origin`
- Parse remote URL (SSH/HTTPS) to `owner/repo`
- Display: `🐙 owner/repo:branch`
- Fallback: cwd path if not in git repo

### 2. `model` -- Current Claude model
- Source: `data["model"]["display_name"]` from stdin JSON
- Display: `🤖 Opus`

### 3. `reset` -- 5h block reset timer
- Parse JSONL transcripts (all projects) for earliest activity in current 5h window
- Countdown: block_start + 5h - now
- Display: `⏱ 2h31m` or `⏱ --:--` when idle

### 4. `daily` -- 5h block usage
- Parse JSONL transcripts (all projects) for tokens in current 5h block
- Display: `5h: 45%` (limits set) or `5h: 1.2M` (limits=0)

### 5. `weekly` -- 7d usage
- Parse JSONL transcripts (all projects) for tokens in last 7 days
- Display: `7d: 23%` (limits set) or `7d: 8.4M` (limits=0)

### 6. `sandbox` -- Dangerous mode only
- Read `~/.claude/settings.json` for `skipDangerousModePermissionPrompt`
- Display: `🔓 YOLO` only when dangerous. Hidden when safe.

## Data Sources

| Source | Data | Latency |
|--------|------|---------|
| Stdin JSON | model, cwd, session cost, context window | 0ms (piped) |
| Git subprocess | repo/branch | ~10ms |
| JSONL parsing | 5h/7d token usage, reset timer | cached 10s TTL |
| settings.json | sandbox mode | file read |

### JSONL Format (assistant messages)
```json
{
  "type": "assistant",
  "timestamp": "2026-02-21T22:41:46.918Z",
  "message": {
    "usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  }
}
```
Scan `~/.claude/projects/**/*.jsonl` for `type=assistant` entries. Sum all token fields per time window. Cache to temp file, refresh every `cache_ttl_seconds`.

## Script Structure
```
statusline.py:
  Constants (paths, defaults)
  Color helpers (ansi_fg, ansi_bg, colorize) -- truecolor 24-bit ANSI
  JSONL parser (scan transcripts, aggregate tokens by time window)
  Cache layer (TTL-based temp file)
  6 module functions: mod_git, mod_model, mod_reset, mod_daily, mod_weekly, mod_sandbox
  Module registry dict
  Config loader (merge user config over defaults)
  Main: stdin JSON -> enabled modules -> colorize -> join separator -> print
```

## Error Handling
- Per-module try/except -- one failure never kills the line
- Stdin parse failure -> empty dict
- Config parse failure -> defaults
- Outer wrapper -> empty string on total failure

## Files
- `statusline/statusline.py` -- single script, all logic
- `statusline/config.json` -- user configuration

## Verification
1. `echo '{"model":{"id":"claude-opus-4-6","display_name":"Opus"},"cwd":"/tmp"}' | python ~/.claude/statusline/statusline.py`
2. Open Claude Code session, confirm statusline renders
3. Toggle modules/colors in config.json, verify changes
