from .helpers import get_icon


def mod_model(data, config, jsonl_data):
    icon = get_icon("model", config)
    model_info = data.get("model", {})
    if isinstance(model_info, dict):
        name = model_info.get("display_name", "")
    elif isinstance(model_info, str):
        name = model_info
    else:
        name = ""
    if not name:
        return None
    return f"{icon} {name}"
