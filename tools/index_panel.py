"""The Index page without its arrows (QM, Oct 11): assets/ui/dex/IndexPanel.png has the
arrows drawn on, but in game they're buttons (IndexArrow.png) that spring under the mouse,
so they're painted out here with the background from 4 dots along (the dots repeat every
~26.5 px; the gradient only runs top to bottom).

    python3 tools/index_panel.py  -> assets/ui/dex/IndexPanelBare.png
"""
from PIL import Image

SHIFT = 106  # 4 of the background's dots
PAD = 7
ARROWS = [((297, 370, 351, 421), SHIFT), ((822, 370, 876, 421), -SHIFT)]  # (box, where to copy from)

im = Image.open("assets/ui/dex/IndexPanel.png").convert("RGBA")
for (x0, y0, x1, y1), dx in ARROWS:
    box = (x0 - PAD, y0 - PAD, x1 + PAD, y1 + PAD)
    im.paste(im.crop((box[0] + dx, box[1], box[2] + dx, box[3])), box[:2])
im.save("assets/ui/dex/IndexPanelBare.png")
