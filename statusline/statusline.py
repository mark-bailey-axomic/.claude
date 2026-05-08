#!/usr/bin/env python3
"""Configurable statusline for Claude Code. Reads session JSON from stdin, outputs formatted status bar."""
#loveit
import os, sys, json
from typing import Any #, cast

POWERLINE_SEP = ""  # Nerd Fonts solid right arrow

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

def build_segments(config:  dict[str, Any], session: dict[str, Any]) -> list[tuple[str, str]]:
  segments: list[tuple[str, str]] = []
  available_segments = load_segments()

  for cfg in config.get("segments", []):
    if not cfg.get("enabled", False): continue
    type = cfg.get("type")
    module = available_segments.get(type)

    if module and hasattr(module, "main"):
      try:
        color_scheme = config.get("color_scheme", "dark")
        text = module.main({ **cfg, "color_scheme": color_scheme }, session)
        if text: segments.append((type, text))
      except Exception as e:
        # Handle exceptions gracefully (e.g., log them, skip the segment, etc.)
        import sys; print(f"SEGMENT ERROR: {e}", file=sys.stderr)
        pass
  return segments

def render_powerline(pairs: list[tuple[str, str]], config: dict[str, Any]) -> str:
    from utils.color import hex2Rgb
    from utils.terminal import ANSI_RESET
    color_scheme = config.get("color_scheme", "dark")
    theme = config.get("themes", {}).get(color_scheme, {})
    result = ""
    prev_bg: tuple[int, int, int] | None = None
    for seg_type, text in pairs:
        colors = theme.get(seg_type, {})
        fg_rgb = hex2Rgb(colors.get("fg", "#ffffff")) or (255, 255, 255)
        bg_rgb = hex2Rgb(colors.get("bg", "#000000")) or (0, 0, 0)
        r1, g1, b1 = bg_rgb
        if prev_bg:
            r0, g0, b0 = prev_bg
            result += f"\033[38;2;{r0};{g0};{b0}m\033[48;2;{r1};{g1};{b1}m{POWERLINE_SEP}"
        else:
            result += f"\033[48;2;{r1};{g1};{b1}m"
        r, g, b = fg_rgb
        result += f"\033[38;2;{r};{g};{b}m {text} "
        prev_bg = bg_rgb
    if prev_bg:
        r0, g0, b0 = prev_bg
        result += f"{ANSI_RESET}\033[38;2;{r0};{g0};{b0}m{POWERLINE_SEP}{ANSI_RESET}"
    return result

# Main
def main():
  # Read session JSON from stdin (if available)
  try:
    session: dict[str, Any] = json.load(sys.stdin) if not sys.stdin.isatty() else {}
  except (json.JSONDecodeError, ValueError):
    session = {}

  # Load user config
  config = load_config()
  # Build segments
  pairs: list[tuple[str, str]] = build_segments(config, session)

  # Force UTF-8 output on Windows
  if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]

  # Render final statusline
  display_as = config.get("display_as", "plain")
  if display_as == "powerline":
      output = render_powerline(pairs, config)
  else:
      output = " ".join(text for _, text in pairs)
  sys.stdout.write(f"{output}\n")
  sys.stdout.flush()

if __name__ == "__main__":
  main()