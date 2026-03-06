from typing import Any, cast

def make_progress_bar(pct: int, width: int = 10) -> str:
    filled = int(width * pct / 100)
    bar = "█" * filled + "░" * (width - filled)
    return f"[{bar} {pct}]"

# Token Methods
def format_tokens(tokens: int) -> str:
    if tokens >= 1_000_000:
        return f"{tokens / 1_000_000:.0f}M"
    elif tokens >= 1_000:
        return f"{tokens / 1_000:.0f}K"
    else:
        return f"{tokens}"

def get_token_usage(session: dict[str, Any]) -> str:
    context_window = session.get('context_window', {})
    total_input_tokens: int = context_window.get('total_input_tokens', 0)
    total_output_tokens: int = context_window.get('total_output_tokens', 0)
    token_limit: int = context_window.get('context_window_size', 0)
    total_tokens = total_input_tokens + total_output_tokens

    return f"{format_tokens(total_tokens)}/{format_tokens(token_limit)}"

# Main
def main(config: dict[str, str | bool], session: dict[str, Any]) -> str | None:
    # show_icon = bool(config.get("show_icon", False))
    display = cast(list[str], config.get("display", []))# Debug statement to check display config

    # Build the segment text based on the display settings
    segment_parts: list[str] = []
    for item in display:
        if item == "percentage":     
            # Extract usage context information from the session
            context_window = session.get('context_window', {})
            used_percentage: int = context_window.get('used_percentage', 0) or 0
            segment_parts.append(make_progress_bar(used_percentage))
        elif item == "tokens":
            segment_parts.append(get_token_usage(session))
        elif item == "cost":
            total_cost: float = session.get('cost', {}).get('total_cost_usd', 0)
            segment_parts.append(f"${total_cost:.2f}")

    return f"{' '.join(segment_parts)}" if segment_parts else None