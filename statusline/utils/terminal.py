# ANSI escape codes for styling the status line

ANSI_RESET = "\033[0m"
ANSI_RESET_FG = "\033[39m"
ANSI_RESET_BG = "\033[49m"
ANSI_REVERSE = "\033[7m"
ANSI_BOLD = "\033[1m"

def paint_fg(text: str, rgb: tuple[int, int, int], is_bold: bool = False) -> str:
    r, g, b = rgb
    bold = ANSI_BOLD if is_bold else ""
    return f"\033[38;2;{r};{g};{b}m{bold}{text}{ANSI_RESET_FG}"

def paint_bg(text: str, rgb: tuple[int, int, int]) -> str:
    r, g, b = rgb
    return f"\033[48;2;{r};{g};{b}m{text}{ANSI_RESET_BG}"

def paint_bold(text: str) -> str:
    return f"{ANSI_BOLD}{text}{ANSI_RESET}"

def paint_reverse(text: str) -> str:
    return f"{ANSI_REVERSE}{text}{ANSI_RESET}"