import os, subprocess

def get_segment(config: dict[str, str | bool], session: dict[str, object] | None = None) -> str | None:
    cwd = os.getcwd()
    show_icon = bool(config.get("show_icon", False))

    try:
      BRANCH_CMD = "git branch --show-current"
      CompletedProcess = subprocess.run(BRANCH_CMD, capture_output=True, text=True, timeout=5, cwd=cwd)
      if CompletedProcess.returncode == 0:
        branch = CompletedProcess.stdout.strip()
        icon = "🌿 " if show_icon else ""
        return f"{icon}{branch}"
      return None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
      return None