#!/usr/bin/env python3
"""Configurable statusline for Claude Code. Reads session JSON from stdin, outputs formatted status bar."""

import json
import os
import sys
import glob
import time
import hashlib
import tempfile
from datetime import datetime, timezone

CLAUDE_DIR = os.path.join(os.path.expanduser("~"), ".claude")
CONFIG_PATH = os.path.join(CLAUDE_DIR, "statusline", "config.json")
PROJECTS_DIR = os.path.join(CLAUDE_DIR, "projects")
CACHE_PREFIX = "claude_statusline_cache_"

DEFAULT_CONFIG = {
    "modules": [
        {"id": "git", "enabled": True, "fg": "#c0caf5", "bg": None},
        {"id": "model", "enabled": True, "fg": "#7aa2f7", "bg": None},
        {"id": "reset", "enabled": True, "fg": "#e0af68", "bg": None},
        {"id": "daily", "enabled": True, "fg": "#9ece6a", "bg": None},
        {"id": "weekly", "enabled": True, "fg": "#bb9af7", "bg": None},
        {"id": "sandbox", "enabled": True, "fg": "#f7768e", "bg": None},
    ],
    "separator": " | ",
    "icons": "emoji",
    "cache_ttl_seconds": 10,
    "block_hours": 5,
    "limits": {
        "daily_tokens": 0,
        "weekly_tokens": 0,
    },
}

NAMED_COLORS = {
    "red": (255, 0, 0),
    "green": (0, 255, 0),
    "blue": (0, 0, 255),
    "yellow": (255, 255, 0),
    "magenta": (255, 0, 255),
    "cyan": (0, 255, 255),
    "white": (255, 255, 255),
    "black": (0, 0, 0),
    "orange": (255, 165, 0),
}


# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------

def parse_color(color):
    if not color:
        return None
    if isinstance(color, str) and color.startswith("#") and len(color) == 7:
        try:
            return (int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16))
        except ValueError:
            return None
    if isinstance(color, str) and color.lower() in NAMED_COLORS:
        return NAMED_COLORS[color.lower()]
    return None


def ansi_fg(r, g, b):
    return f"\033[38;2;{r};{g};{b}m"


def ansi_bg(r, g, b):
    return f"\033[48;2;{r};{g};{b}m"


ANSI_RESET = "\033[0m"


def colorize(text, fg=None, bg=None):
    if not text:
        return text
    prefix = ""
    fg_rgb = parse_color(fg)
    bg_rgb = parse_color(bg)
    if fg_rgb:
        prefix += ansi_fg(*fg_rgb)
    if bg_rgb:
        prefix += ansi_bg(*bg_rgb)
    if prefix:
        return prefix + text + ANSI_RESET
    return text


# ---------------------------------------------------------------------------
# JSONL parser
# ---------------------------------------------------------------------------

def find_jsonl_files():
    pattern = os.path.join(PROJECTS_DIR, "**", "*.jsonl")
    return glob.glob(pattern, recursive=True)


def parse_iso_timestamp(s):
    s = s.rstrip("Z").rstrip("z")
    if "." in s:
        main, frac = s.rsplit(".", 1)
        frac = frac[:6]
        s = f"{main}.{frac}"
        try:
            dt = datetime.strptime(s, "%Y-%m-%dT%H:%M:%S.%f")
        except ValueError:
            dt = datetime.strptime(main, "%Y-%m-%dT%H:%M:%S")
    else:
        dt = datetime.strptime(s, "%Y-%m-%dT%H:%M:%S")
    return dt.replace(tzinfo=timezone.utc)


def parse_jsonl_entries():
    entries = []
    for filepath in find_jsonl_files():
        try:
            with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if obj.get("type") != "assistant":
                        continue
                    msg = obj.get("message", {})
                    usage = msg.get("usage")
                    if not usage:
                        continue
                    ts_str = obj.get("timestamp")
                    if not ts_str:
                        continue
                    try:
                        ts = parse_iso_timestamp(ts_str)
                    except (ValueError, TypeError):
                        continue
                    entries.append({
                        "timestamp": ts,
                        "input_tokens": usage.get("input_tokens", 0),
                        "output_tokens": usage.get("output_tokens", 0),
                        "cache_creation_input_tokens": usage.get("cache_creation_input_tokens", 0),
                        "cache_read_input_tokens": usage.get("cache_read_input_tokens", 0),
                    })
        except (OSError, IOError):
            continue
    return entries


# ---------------------------------------------------------------------------
# Cache layer
# ---------------------------------------------------------------------------

def get_cache_path():
    h = hashlib.md5(PROJECTS_DIR.encode()).hexdigest()[:12]
    return os.path.join(tempfile.gettempdir(), f"{CACHE_PREFIX}{h}.json")


def load_cache(ttl_seconds):
    cache_path = get_cache_path()
    try:
        with open(cache_path, "r", encoding="utf-8") as f:
            cached = json.loads(f.read())
        if time.time() - cached.get("timestamp", 0) < ttl_seconds:
            data = cached.get("data", [])
            for e in data:
                if isinstance(e.get("timestamp"), str):
                    e["timestamp"] = parse_iso_timestamp(e["timestamp"])
                elif isinstance(e.get("timestamp"), (int, float)):
                    e["timestamp"] = datetime.fromtimestamp(e["timestamp"], tz=timezone.utc)
            return data
    except (OSError, IOError, json.JSONDecodeError, ValueError, KeyError):
        pass
    return None


def save_cache(entries):
    cache_path = get_cache_path()
    serializable = []
    for e in entries:
        se = dict(e)
        se["timestamp"] = e["timestamp"].isoformat()
        serializable.append(se)
    try:
        with open(cache_path, "w", encoding="utf-8") as f:
            json.dump({"timestamp": time.time(), "data": serializable}, f)
    except (OSError, IOError):
        pass


def get_jsonl_data(config):
    ttl = config.get("cache_ttl_seconds", 10)
    cached = load_cache(ttl)
    if cached is not None:
        return cached
    entries = parse_jsonl_entries()
    save_cache(entries)
    return entries


# ---------------------------------------------------------------------------
# Config loader
# ---------------------------------------------------------------------------

def deep_merge(base, override):
    result = dict(base)
    for k, v in override.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v)
        else:
            result[k] = v
    return result


def load_config():
    config = dict(DEFAULT_CONFIG)
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            user_config = json.loads(f.read())
        config = deep_merge(DEFAULT_CONFIG, user_config)
    except (OSError, IOError, json.JSONDecodeError):
        pass
    return config


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    try:
        if sys.platform == "win32":
            sys.stdin.reconfigure(encoding="utf-8", errors="replace")
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")

        pkg_dir = os.path.dirname(os.path.abspath(__file__))
        if pkg_dir not in sys.path:
            sys.path.insert(0, pkg_dir)

        from modules import MODULES

        raw = sys.stdin.read()
        try:
            data = json.loads(raw) if raw.strip() else {}
        except (json.JSONDecodeError, ValueError):
            data = {}

        config = load_config()

        try:
            jsonl_data = get_jsonl_data(config)
        except Exception:
            jsonl_data = []

        separator = config.get("separator", " | ")
        modules_config = config.get("modules", DEFAULT_CONFIG["modules"])

        parts = []
        for mod_cfg in modules_config:
            if not mod_cfg.get("enabled", True):
                continue
            mod_id = mod_cfg.get("id", "")
            func = MODULES.get(mod_id)
            if not func:
                continue
            try:
                result = func(data, config, jsonl_data)
            except Exception:
                continue
            if not result:
                continue
            fg = mod_cfg.get("fg")
            bg = mod_cfg.get("bg")
            parts.append(colorize(result, fg, bg))

        output = separator.join(parts)
        sys.stdout.write(output)
        sys.stdout.flush()

    except Exception:
        sys.stdout.write("")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
