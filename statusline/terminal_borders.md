# Terminal Border Techniques

## 1. Powerline Separators

Requires Powerline-patched or Nerd Font.

```python
RIGHT_ARROW = "\uE0B0"
LEFT_ARROW  = "\uE0B2"
RIGHT_ROUND = "\uE0B4"
LEFT_ROUND  = "\uE0B6"

def fg(color): return f"\033[38;2;{color}m"
def bg(color): return f"\033[48;2;{color}m"
RESET = "\033[0m"

# Arrow pill
def pill(text, fg_color="255;255;255", bg_color="60;60;60"):
    return (
        f"{fg(bg_color)}{RIGHT_ARROW}"
        f"{bg(bg_color)}{fg(fg_color)} {text} "
        f"{RESET}{fg(bg_color)}{RIGHT_ARROW}"
        f"{RESET}"
    )

# Round pill
def round_pill(text, fg_color="255;255;255", bg_color="60;60;60"):
    return (
        f"{fg(bg_color)}{LEFT_ROUND}"
        f"{bg(bg_color)}{fg(fg_color)} {text} "
        f"{RESET}{fg(bg_color)}{RIGHT_ROUND}"
        f"{RESET}"
    )
```

Output (Nerd Fonts terminal — glyphs are U+E0B0 / U+E0B4 / U+E0B6):
```
# pill()        main  Python 3.11 
# round_pill()  main  Python 3.11 
```

## 2. Terminal Block Characters

Works with any terminal font.

```python
FULL  = "█"  # U+2588
UPPER = "▀"  # U+2580
LOWER = "▄"  # U+2584
LEFT  = "▌"  # U+258C
RIGHT = "▐"  # U+2590

def fg(color): return f"\033[38;2;{color}m"
def bg(color): return f"\033[48;2;{color}m"
RESET = "\033[0m"

# Inline: left/right block borders
def block_segment(text, fg_c="255;255;255", bg_c="60;60;60"):
    return (
        f"{fg(bg_c)}{LEFT}"
        f"{bg(bg_c)}{fg(fg_c)} {text} "
        f"{RESET}{fg(bg_c)}{RIGHT}"
        f"{RESET}"
    )

# Full box: 3 lines using upper/lower half-blocks
def block_box(text, fg_c="255;255;255", bg_c="80;80;80"):
    pad = len(text) + 2
    top = f"{fg(bg_c)}{LOWER * (pad + 2)}{RESET}"
    mid = f"{fg(bg_c)}{FULL}{bg(bg_c)}{fg(fg_c)} {text} {RESET}{fg(bg_c)}{FULL}{RESET}"
    bot = f"{fg(bg_c)}{UPPER * (pad + 2)}{RESET}"
    return f"{top}\n{mid}\n{bot}"
```

Output:
```
▌ main ▐ ▌ 3.11 ▐

▄▄▄▄▄▄▄▄▄▄▄▄▄
█ Hello World █
▀▀▀▀▀▀▀▀▀▀▀▀▀
```

## 3. Unicode Box-Drawing Characters

```
┌──────────┐
│  Hello!  │
└──────────┘
```

Characters: `┌ ┐ └ ┘ ─ │`
