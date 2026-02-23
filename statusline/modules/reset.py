from datetime import datetime, timezone, timedelta
from .helpers import get_icon, filter_entries_since, format_duration


def mod_reset(data, config, jsonl_data):
    icon = get_icon("reset", config)
    block_hours = config.get("block_hours", 5)
    now = datetime.now(timezone.utc)
    block_start = now - timedelta(hours=block_hours)

    recent = filter_entries_since(jsonl_data, block_start)
    if not recent:
        return f"{icon} --:--"

    earliest = min(e["timestamp"] for e in recent)
    reset_at = earliest + timedelta(hours=block_hours)
    remaining = (reset_at - now).total_seconds()

    if remaining <= 0:
        return f"{icon} --:--"

    return f"{icon} {format_duration(remaining)}"
