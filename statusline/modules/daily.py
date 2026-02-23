from datetime import datetime, timezone, timedelta
from .helpers import get_icon, filter_entries_since, sum_tokens, format_token_count


def mod_daily(data, config, jsonl_data):
    icon = get_icon("daily", config)
    block_hours = config.get("block_hours", 5)
    now = datetime.now(timezone.utc)
    block_start = now - timedelta(hours=block_hours)

    recent = filter_entries_since(jsonl_data, block_start)
    total = sum_tokens(recent)

    limit = config.get("limits", {}).get("daily_tokens", 0)
    if limit > 0:
        pct = min(int(total / limit * 100), 999)
        return f"{icon} {block_hours}h: {pct}%"
    return f"{icon} {block_hours}h: {format_token_count(total)}"
