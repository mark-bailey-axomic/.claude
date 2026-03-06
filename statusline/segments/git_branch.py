import os, subprocess
# from typing import cast
# from helpers import colorize

BRANCH_CMD = "git branch --show-current"

# def get_color(color_scheme: str, style: str) -> dict[str, str | None]:
#   IS_DARK = color_scheme == "dark"

#   if style == "powerline":
#     fg = "#4493f8" if IS_DARK else "#0969da"
#     bg = "#112034" if IS_DARK else "#ddf4ff"
#   else:
#     fg = "#4493f8" if IS_DARK else "#0969da"
#     bg = None

#   return dict(fg=fg, bg=bg)

def get_branch() -> str | None:
  try:
    cwd = os.getcwd()
    process = subprocess.run(
      BRANCH_CMD, 
      capture_output=True, 
      text=True, 
      shell=True, 
      timeout=5, 
      cwd=cwd
    )

    if process.returncode == 0:
      return process.stdout.strip()
    return None
  except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    return None
  
# Main
def main(config: dict[str, str | bool], session: dict[str, object] | None = None) -> str | None:
  try:
    show_icon = bool(config.get("show_icon", False))
    branch = get_branch()

    if branch:
      prefix = "🌿 " if show_icon else ""
      return f"{prefix}{branch}"
    return None
  except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    return None