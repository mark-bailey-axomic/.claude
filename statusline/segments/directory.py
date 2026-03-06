import os, re, subprocess
from typing import cast
from helpers import colorize

def hyperlink(url: str, text: str) -> str:
    return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"

def get_color(color_scheme: str, style: str, is_repo: bool = False) -> dict[str, str | None]:
  IS_DARK = color_scheme == "dark"

  if style == "powerline":
    fg = "#ffffff" if IS_DARK else "#1f2328"
    bg = "#151b22" if IS_DARK else "#f6f8fa"
  else:
    fg = "#f6f8fa"
    bg = None

  return { "fg": fg, "bg": bg }

def parse_git_remote(url: str) -> str | None:
  https_match = re.match(r"https?://[^/]+/(.+?)(?:\.git)?$", url)
  if https_match:
    return hyperlink(url, https_match.group(1))
  
  ssh_match = re.match(r"git@[^:]+:(.+?)(?:\.git)?$", url)
  if ssh_match:
    return hyperlink(url, ssh_match.group(1))
  return None

def get_repo(cwd: str, show_icon: bool) -> str | None:
    try:
      REPO_CMD = "git remote get-url origin"
      CompletedProcess = subprocess.run(REPO_CMD, capture_output=True, text=True, timeout=5, cwd=cwd)
      if CompletedProcess.returncode == 0:
        url = CompletedProcess.stdout.strip()
        name = parse_git_remote(url)
        icon = "🐙 " if show_icon else ""
        return f"{icon}{name}" if name else None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
      return None
    
def get_directory(cwd: str, show_icon: bool) -> str:
  dir_icon = "📁 " if show_icon else ""
  dir_name = os.path.basename(cwd)
  return f"{dir_icon}{dir_name}"

def get_segment(config: dict[str, str | bool], session: dict[str, object] | None = None) -> str | None:
  cwd = os.getcwd()
  show_icon = bool(config.get("show_icon", False))
  style = cast(str, config.get("style", "text"))
  color_scheme = cast(str, config.get("color_scheme", "dark"))

  try:
    repo = get_repo(cwd, show_icon)
    is_repo = repo is not None
    colors = get_color(color_scheme, style, is_repo)
    output = repo if repo else get_directory(cwd, show_icon)
    return colorize(output, **colors)
  except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    return get_directory(cwd, show_icon)