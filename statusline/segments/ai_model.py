from typing import Any

# Main
def main(config: dict[str, str | bool], session: dict[str, Any]) -> str | None:
    model = session.get('model', {}).get('display_name', None)
    show_label = bool(config.get("show_label", False))

    label = "Model: " if show_label else ""
    if not model:
        return None
    return f"{label}{model}"
