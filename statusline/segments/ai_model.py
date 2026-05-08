from typing import Any

# Main
def main(config: dict[str, str | bool], session: dict[str, Any]) -> str | None:
    model = session.get('model', {}).get('display_name', None)
    if not model:
        return None
    return model
