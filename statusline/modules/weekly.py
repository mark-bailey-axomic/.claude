from datetime import datetime, timezone, timedelta
from .helpers import get_icon, filter_entries_since, sum_tokens, format_token_count


def mod_weekly(data, config, jsonl_data):
    icon = get_icon("weekly", config)
    now = datetime.now(timezone.utc)
    week_start = now - timedelta(days=7)

    recent = filter_entries_since(jsonl_data, week_start)
    total = sum_tokens(recent)

    limit = config.get("limits", {}).get("weekly_tokens", 0)
    if limit > 0:
        pct = min(int(total / limit * 100), 999)
        return f"{icon} 7d: {pct}%"
    return f"{icon} 7d: {format_token_count(total)}"
