from pathlib import Path
from PIL import Image

source = Path("assets/wof_logo.png")
output = Path("windows/runner/resources/app_icon.ico")

if not source.exists():
    raise FileNotFoundError(f"Source asset not found: {source}")

img = Image.open(source).convert("RGBA")
size = max(img.size)
if img.width != img.height:
    square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    square.paste(img, ((size - img.width) // 2, (size - img.height) // 2), img)
    img = square

img.save(output, format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (256, 256)])
print(f"Created {output}")
