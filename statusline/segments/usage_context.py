from typing import Any, cast

def get_segment(config: dict[str, str | bool], session: dict[str, Any]) -> str | None:
    show_icon = bool(config.get("show_icon", False))
    display = cast(list[str], config.get("display", []))

    # Extract usage context information from the session
    context_window = session.get('context_window', {})
    used_percentage: float = context_window.get('used_percentage', 0)

    # Build the segment text based on the display settings
    segment_parts: list[str] = []
    for item in display:
        if item == "percentage":        
            segment_parts.append(f"{used_percentage:.0f}%")
        elif item == "tokens":
            total_input_tokens: int = context_window.get('total_input_tokens', 0)
            total_output_tokens: int = context_window.get('total_output_tokens', 0)
            token_limit: int = context_window.get('context_window_size', 0)
            total_tokens = total_input_tokens + total_output_tokens
            segment_parts.append(f"{total_tokens}/{token_limit}")
        elif item == "cost":
            total_cost: float = session.get('cost', {}).get('total_cost_usd', 0)
            segment_parts.append(f"${total_cost:.2f}")

    return f"{' '.join(segment_parts)}" if segment_parts else None