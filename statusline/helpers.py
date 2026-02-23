ANSI_RESET = "\033[0m"

def ansi_fg(r, g, b):
    return f"\033[38;2;{r};{g};{b}m"


def ansi_bg(r, g, b):
    return f"\033[48;2;{r};{g};{b}m"

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------

def parse_color(color):
    if not color:
        return None
    if isinstance(color, str) and color.startswith("#") and len(color) == 7:
        try:
            return (int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16))
        except ValueError:
            return None
    return None

def colorize(text, fg=None, bg=None):
    if not text:
        return text
    prefix = ""
    fg_rgb = parse_color(fg)
    bg_rgb = parse_color(bg)
    if fg_rgb:
        prefix += ansi_fg(*fg_rgb)
    if bg_rgb:
        prefix += ansi_bg(*bg_rgb)
    if prefix:
        return prefix + text + ANSI_RESET
    return text

def get_system_color_scheme():
    # Detect system color scheme (light/dark) if possible, default to dark
    import platform
    system = platform.system()
    if system == "Windows":
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize") as key:
                value, _ = winreg.QueryValueEx(key, "AppsUseLightTheme")
                return "light" if value == 1 else "dark"
        except Exception:
            pass
    elif system == "Darwin":
        try:
            import subprocess
            result = subprocess.run(["defaults", "read", "-g", "AppleInterfaceStyle"], capture_output=True, text=True)
            return "dark" if result.returncode == 0 and result.stdout.strip() == "Dark" else "light"
        except Exception:
            pass
    # For Linux, we could check common desktop environment settings, but it's complex. Default to dark.
    return "dark"