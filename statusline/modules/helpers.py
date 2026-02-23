import os
from datetime import datetime, timezone, timedelta

CLAUDE_DIR = os.path.join(os.path.expanduser("~"), ".claude")
SETTINGS_PATH = os.path.join(CLAUDE_DIR, "settings.json")

ICONS = {
    "git":     {"emoji": "\U0001f419", "nerd": "\uf408"},
    "model":   {"emoji": "\U0001f916", "nerd": "\uf49c"},
    "reset":   {"emoji": "\u23f1",     "nerd": "\uf43a"},
    "daily":   {"emoji": "\U0001f4ca", "nerd": "\uf080"},
    "weekly":  {"emoji": "\U0001f4c8", "nerd": "\uf080"},
    "sandbox": {"emoji": "\U0001f513", "nerd": "\uf09c"},
}


def get_icon(module_id, config):
    style = config.get("icons", "emoji")
    icons = ICONS.get(module_id, {})
    return icons.get(style, icons.get("emoji", ""))


def filter_entries_since(entries, since_dt):
    return [e for e in entries if e["timestamp"] >= since_dt]


def sum_tokens(entries):
    total = 0
    for e in entries:
        total += e.get("input_tokens", 0)
        total += e.get("output_tokens", 0)
        total += e.get("cache_creation_input_tokens", 0)
        total += e.get("cache_read_input_tokens", 0)
    return total


def format_token_count(n):
    if n >= 1_000_000:
        val = n / 1_000_000
        if val >= 10:
            return f"{val:.0f}M"
        return f"{val:.1f}M"
    if n >= 1_000:
        val = n / 1_000
        if val >= 10:
            return f"{val:.0f}K"
        return f"{val:.1f}K"
    return str(n)


def format_duration(seconds):
    if seconds <= 0:
        return "--:--"
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    return f"{h}h{m:02d}m"
