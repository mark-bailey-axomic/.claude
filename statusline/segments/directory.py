import os, re, subprocess
# from typing import cast
# from helpers import colorize

REPO_CMD = "git remote get-url origin"
ICON = dict(folder="📁", repo="🐙")

# Github Repo Methods
def parse_git_remote(url: str, separator: str = " ") -> str | None:
  match = re.match(r"(https?://[^/]+/|git@[^:]+:)(.+?)(?:\.git)?$", url)
  if match:
    return match.group(2).replace('/', separator)
  return None

def get_repo(include_at: bool = True) -> str | None:
    try:
      cwd = os.getcwd()
      process = subprocess.run(
        REPO_CMD, 
        capture_output=True, 
        text=True, 
        shell=True, 
        timeout=5, 
        cwd=cwd
      )

      if process.returncode == 0:
        url = process.stdout.strip()
        repo = parse_git_remote(url)
        prefix = "@" if include_at else ""
        return f"{prefix}{repo}" if repo else None
      return None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
      return None

# Main
def main(config: dict[str, str | bool], _) -> str:
  show_icon = bool(config.get("show_icon", False))
  show_label = bool(config.get("show_label", False))
  repo = get_repo()

  if repo:
    icon = f"{ICON['repo']} " if show_icon else ""
    return f"{icon}{repo}"
  
  cwd = os.getcwd()
  dir_name = os.path.basename(cwd)
  icon = f"{ICON['folder']} " if show_icon else ""
  label = "CWD: " if show_label else ""
  return f"{label}{icon}{dir_name}"

# def hyperlink(url: str, text: str) -> str:
#     return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"

# def get_color(color_scheme: str, style: str, is_repo: bool = False) -> dict[str, str | None]:
#   IS_DARK = color_scheme == "dark"

#   if style == "powerline":
#     fg = "#ffffff" if IS_DARK else "#1f2328"
#     bg = "#151b22" if IS_DARK else "#f6f8fa"
#   else:
#     fg = "#f6f8fa"
#     bg = None

#   return { "fg": fg, "bg": bg }