#!/usr/bin/env python3
"""Configurable statusline for Claude Code. Reads session JSON from stdin, outputs formatted status bar."""
#loveit
import os, sys, json
from typing import Any, cast

from globals import DEFAULT_SEPARATOR

def load_config() -> dict[str, Any]:
    # Load user config
    config = dict(segments=[])

    try:
      file_path = os.path.abspath(__file__)
      file_dir = os.path.dirname(file_path)
      CONFIG_PATH = os.path.join(file_dir, "config.json")

      with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        config = dict(json.loads(f.read()))
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    
    return config

def build_segments(config:  dict[str, Any], session: dict[str, Any]) -> list[str]:
    segments: list[str] = []
    color_scheme = cast(str, config.get("color_scheme", "dark"))
    enabled_segments = [s for s in config.get("segments", []) if s.get("enabled", False)]
    total_segments = len(enabled_segments)

    for i, segment in enumerate(enabled_segments):
      try:
        # Dynamically import the segment module and get its text
        segment_module = __import__(f"segments.{segment['type']}", fromlist=["get_segment"])
        segment_text: str = segment_module.get_segment({**segment, "color_scheme": color_scheme}, session)

        if segment_text:
          is_last = (i == total_segments - 1)
          separator: str = "" if is_last else config.get("separator", DEFAULT_SEPARATOR)
          segments.append(f"{segment_text}{separator}")
      except ImportError:
        pass

    return segments

def main():
  # Read session JSON from stdin (if available)
  session: dict[str, Any] = json.load(sys.stdin) if not sys.stdin.isatty() else {}
  
  # Load user config
  config = load_config()
  # Build segments
  segments = build_segments(config, session)

  # Force UTF-8 output on Windows
  if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
      
  # Render final statusline``
  sys.stdout.write("".join(segments))
  sys.stdout.flush()

if __name__ == "__main__":
  main()