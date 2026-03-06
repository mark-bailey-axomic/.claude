#!/usr/bin/env python3
"""Configurable statusline for Claude Code. Reads session JSON from stdin, outputs formatted status bar."""
#loveit
import os, sys, json
from typing import Any #, cast

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

# Segment Methods
def load_segments() -> dict[str, Any]:
  # Dynamically import all segment modules
  segments: dict[str, Any] = {}
  file_path = os.path.abspath(__file__)
  file_dir = os.path.dirname(file_path)
  segments_dir = os.path.join(file_dir, "segments")

  if os.path.isdir(segments_dir):
    for filename in os.listdir(segments_dir):
      if filename.endswith(".py") and not filename.startswith("__"):
        segment_name = filename[:-3]
        try:
          segments[segment_name] = __import__(
            f"segments.{segment_name}", 
            fromlist=["main"]
          )
        except ImportError:
          pass

  return segments

def build_segments(config:  dict[str, Any], session: dict[str, Any]) -> list[str]:
  segments: list[str] = []
  available_segments = load_segments()
  
  for cfg in config.get("segments", []):
    if not cfg.get("enabled", False): continue
    type = cfg.get("type")
    module = available_segments.get(type)

    if module and hasattr(module, "main"):
      try:
        color_scheme = config.get("color_scheme", "dark")
        text = module.main({ **cfg, "color_scheme": color_scheme }, session)
        if text: segments.append(text)
      except Exception as _:
        # Handle exceptions gracefully (e.g., log them, skip the segment, etc.)
        pass
  return segments

# Main
def main():
  # Read session JSON from stdin (if available)
  session: dict[str, Any] = json.load(sys.stdin) if not sys.stdin.isatty() else {}
  
  # Load user config
  config = load_config()

  # Build segments
  segments: list[str] = build_segments(config, session)

  # Force UTF-8 output on Windows
  if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
      
  # Render final statusline``
  sys.stdout.write(" ".join(segments))
  sys.stdout.flush()

if __name__ == "__main__":
  main()