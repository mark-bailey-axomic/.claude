import os, re, subprocess

REPO_CMD = ["git", "remote", "get-url", "origin"]
ICON = dict(folder="📁", repo="🐙")

# GitHub Repo Methods
def parse_git_remote(url: str, separator: str = " ") -> str | None:
    match = re.match(r"(https?://[^/]+/|git@[^:]+:)(.+?)(?:\.git)?$", url)
    if match:
        return match.group(2).replace('/', separator)
    return None

def get_repo(cwd: str, include_at: bool = True) -> str | None:
    try:
        process = subprocess.run(
            REPO_CMD,
            capture_output=True,
            text=True,
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
def main(config: dict[str, str | bool], session: dict | None = None) -> str:
    show_icon = bool(config.get("show_icon", False))
    show_label = bool(config.get("show_label", False))
    cwd = (session or {}).get("cwd") or os.getcwd()
    repo = get_repo(cwd)
    if repo:
        icon = f"{ICON['repo']} " if show_icon else ""
        return f"{icon}{repo}"
    dir_name = os.path.basename(cwd) or "/"
    icon = f"{ICON['folder']} " if show_icon else ""
    label = "CWD: " if show_label else ""
    return f"{label}{icon}{dir_name}"
