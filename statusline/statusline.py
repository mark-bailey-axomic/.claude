#!/usr/bin/env python3
"""Configurable statusline for Claude Code. Reads session JSON from stdin, outputs formatted status bar."""

import os, sys, json
from typing import Any

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
    for segment in config.get("segments", []):
      if not segment.get("enabled", False):
        continue
      try:
        # Dynamically import the segment module and get its text
        segment_module = __import__(f"segments.{segment['type']}", fromlist=["get_segment"])
        segment_text: str = segment_module.get_segment(segment, session)

        if segment_text:
          segments.append(segment_text)
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