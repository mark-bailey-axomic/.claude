from typing import Any

def get_segment(_, session: dict[str, Any]) -> str | None:
    model = session.get('model', {}).get('display_name', None)
    if not model:
      return f" [MODEL_NOT_FOUND] "
    return f" {model} "
