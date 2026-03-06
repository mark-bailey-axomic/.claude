import os, subprocess
from typing import cast
from helpers import colorize

def get_color(color_scheme: str, style: str) -> dict[str, str | None]:
  IS_DARK = color_scheme == "dark"

  if style == "powerline":
    fg = "#4493f8" if IS_DARK else "#0969da"
    bg = "#112034" if IS_DARK else "#ddf4ff"
  else:
    fg = "#4493f8" if IS_DARK else "#0969da"
    bg = None

  return dict(fg=fg, bg=bg)

def get_branch() -> str | None:
  try:
    BRANCH_CMD = "git branch --show-current"
    process = subprocess.run(BRANCH_CMD, capture_output=True, text=True, timeout=5)
    if process.returncode == 0:
      return process.stdout.strip()
    return None
  except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    return None

def get_segment(config: dict[str, str | bool], _: dict[str, object] | None = None) -> str | None:
  cwd = os.getcwd()
  show_icon = bool(config.get("show_icon", False))
  style = cast(str, config.get("style", "text"))
  color_scheme = cast(str, config.get("color_scheme", "dark"))
  colors = get_color(color_scheme, style)

  print(f"Debug: cwd={cwd}, show_icon={show_icon}, style={style}, color_scheme={color_scheme}")
  print(f"Debug: colors={colors}")
  try:
    branch = get_branch()
    if branch:
      icon = "🌿 " if show_icon else ""
      return colorize(f"{icon}{branch}", **colors)
    return None
  except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    return None