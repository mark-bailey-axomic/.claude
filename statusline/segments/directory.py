import os, re, subprocess
# from helpers import colorize

def hyperlink(url: str, text: str) -> str:
    return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"

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
        if name:
          return f" {icon}{name} "#colorize(f"{icon}{name}", fg="#f6f8fa", bg="#1f2328")
        return None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
      return None
    
def get_directory(cwd: str, show_icon: bool) -> str:
  dir_icon = "📁 " if show_icon else ""
  dir_name = os.path.basename(cwd)
  return f" {dir_icon}{dir_name} "# colorize(f"{dir_icon}{dir_name}", fg="#ffffff")

def get_segment(config: dict[str, str | bool], session: dict[str, object] | None = None) -> str | None:
  cwd = os.getcwd()
  show_icon = bool(config.get("show_icon", False))

  try:
    repo = get_repo(cwd, show_icon)
    if repo:
      return f"{repo}"
    return get_directory(cwd, show_icon)
  except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    return get_directory(cwd, show_icon)