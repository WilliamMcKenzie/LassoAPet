"""QM (Oct 10): 5 rock meshes (3 rocks, 2 boulders) recoloured per biome. The meshes are
the same; in Roblox only MeshPart.Color changes. Run: python3 design/rocks_biomes/rocks_biomes.py"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import partlib  # noqa: E402
import rock_meshes as RM  # noqa: E402

PICK = [("RockPebble", "Pebble"), ("RockStone", "Stone"), ("RockSlab", "Slab"),
        ("RockBoulder", "Boulder"), ("RockCrag", "Crag")]
BIOMES = [  # name, rock colour, ground checker (Config GroundColors)
    ("Meadow (now)", (159, 161, 172), ((113, 173, 31), (122, 190, 25))),
    ("Desert: red sandstone", (204, 124, 74), ((232, 188, 102), (250, 214, 130))),
    ("Tundra: ice", (158, 200, 240), ((228, 234, 242), (244, 247, 251))),
    ("Ocean: coral", (242, 120, 98), ((236, 214, 164), (246, 228, 184))),
    ("Godlands: dark stone", (64, 62, 76), ((208, 212, 224), (224, 228, 238))),
]
BUILD = {n: (f, s) for n, f, s, _ in RM.ROCKS}
W, H, BAND = 1500, 380, 44
FOV = 30


def font(sz):
    return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", sz)


def row(colour, ground):
    partlib.GROUND = np.array(ground[0], float)
    partlib.GROUND2 = np.array(ground[1], float)
    built = [RM.build(*BUILD[name]) for name, _ in PICK]
    widths = [np.ptp(np.concatenate([np.concatenate(t) for t in c])[:, 0]) for c in built]
    gap = 9
    x = -(sum(widths) + gap * (len(widths) - 1)) / 2
    parts, xs = [], []
    for chunks, w in zip(built, widths):
        cx = -(x + w / 2)  # (+x is screen left from this side)
        parts += RM.as_parts(chunks, cx, 0, yaw=20, color=colour)
        xs.append(cx)
        x += w + gap
    eye, target = (0, 26, -66), (0, 5, 0)
    img = partlib.render(parts, eye=eye, target=target, W=W, H=H, fov=FOV, fog=False, outline=False)
    return img, xs, eye, target


sheet = Image.new("RGB", (W, len(BIOMES) * (H + BAND)), (255, 255, 255))
d = ImageDraw.Draw(sheet)
for i, (title, colour, ground) in enumerate(BIOMES):
    img, xs, eye, target = row(colour, ground)
    y = i * (H + BAND)
    sheet.paste(img.convert("RGB"), (0, y + BAND))
    d.text((16, y + 8), f"{title}  {colour}", font=font(24), fill=(20, 20, 20))
    e, r, u, f = partlib.look_at(eye, target)
    focal = (H / 2) / np.tan(np.radians(FOV) / 2)
    for (_, label), cx in zip(PICK, xs):
        dv = np.array([cx, 0, 0]) - e
        px = W / 2 + focal * (dv @ r) / (dv @ f)
        if i == 0:
            tw = d.textlength(label, font=font(18))
            d.text((px - tw / 2, y + BAND + 6), label, font=font(18), fill=(255, 255, 255), stroke_width=3, stroke_fill=(0, 0, 0))
    print("row", title)
out = os.path.join(HERE, "rocks_biomes.png")
sheet.save(out)
print("wrote", out)
