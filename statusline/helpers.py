# Color helper functions for ANSI escape codes
from globals import ANSI_RESET

def ansi_fg(r: int, g: int, b: int) -> str:
    return f"\033[38;2;{r};{g};{b}m"

def ansi_bg(r: int, g: int, b: int) -> str:
    return f"\033[48;2;{r};{g};{b}m"

# Colorize text with optional foreground and background colors
def parse_color(color: str | None) -> tuple[int, int, int] | None:
    if not color:
        return None
    if color.startswith("#") and len(color) == 7:
        try:
            return (int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16))
        except ValueError:
            return None
    return None

def colorize(text: str, fg: str | None = None, bg: str | None = None) -> str:
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
        return f"{prefix}{text}{ANSI_RESET}"  # Reset at the end
    return text