import os
import re
import subprocess
from .helpers import get_icon


def parse_git_remote(url):
    ssh_match = re.match(r"git@[^:]+:(.+?)(?:\.git)?$", url)
    if ssh_match:
        return ssh_match.group(1)
    https_match = re.match(r"https?://[^/]+/(.+?)(?:\.git)?$", url)
    if https_match:
        return https_match.group(1)
    return None


def mod_git(data, config, jsonl_data):
    icon = get_icon("git", config)
    cwd = data.get("cwd", os.getcwd())

    try:
        branch = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True, text=True, timeout=5, cwd=cwd
        )
        if branch.returncode != 0:
            return f"{icon} {os.path.basename(cwd)}"
        branch_name = branch.stdout.strip()

        remote = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True, timeout=5, cwd=cwd
        )
        if remote.returncode == 0:
            url = remote.stdout.strip()
            repo_name = parse_git_remote(url)
            if repo_name:
                return f"{icon} {repo_name}:{branch_name}"

        return f"{icon} {os.path.basename(cwd)}:{branch_name}"
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return f"{icon} {os.path.basename(cwd)}"
