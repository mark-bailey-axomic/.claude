
def hex2Rgb(hex: str) -> tuple[int, int, int] | None:
  try:
    if (hex.startswith("#")): 
      if len(hex) == 4:
        return (int(hex[1]*2, 16), int(hex[2]*2, 16), int(hex[3]*2, 16))
      if len(hex) == 7:
        return (int(hex[1:3], 16), int(hex[3:5], 16), int(hex[5:7], 16))
    return None
  except ValueError:
    return None