
THEME = {
  "light": {
    "git_repo": {"fg": "#f6f8fa", "bg": "#1f2328"},
    "git_branch": {"fg": "#0969da", "bg": "#ddf4ff"}
  },
  "dark": {
    "git_repo": {"fg": "#24292e", "bg": "#f6f8fa"},
    "git_branch": {"fg": "#1a62eb", "bg": "#121d2f" }
  }
}

def render_segment(config):
  color_scheme = config.get("color_scheme", "dark")
  theme = THEME.get(color_scheme, THEME["dark"])
  return