import json
import sys
from .helpers import get_icon, SETTINGS_PATH


def mod_sandbox(data, config, jsonl_data):
    icon = get_icon("sandbox", config)
    try:
        with open(SETTINGS_PATH, "r", encoding="utf-8") as f:
            settings = json.loads(f.read())
        sandbox = settings.get("sandbox", {})
        if isinstance(sandbox, dict) and sandbox.get("enabled", False):
            return f"{icon} ON"
    except (OSError, IOError, json.JSONDecodeError, KeyError):
        pass
    # macOS (seatbelt) and linux/WSL2 (bubblewrap) only; native win32 unsupported
    return f"{icon} Unsupported" if sys.platform == "win32" else f"{icon} OFF"
