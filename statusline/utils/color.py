
def hex_to_rgb(hex_str: str) -> tuple[int, int, int] | None:
  try:
    if (hex_str.startswith("#")):
      if len(hex_str) == 4:
        return (int(hex_str[1]*2, 16), int(hex_str[2]*2, 16), int(hex_str[3]*2, 16))
      if len(hex_str) == 7:
        return (int(hex_str[1:3], 16), int(hex_str[3:5], 16), int(hex_str[5:7], 16))
    return None
  except ValueError:
    return None