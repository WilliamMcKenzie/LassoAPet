"""QM (Oct 10): multi-piece rocks with each piece a slightly different shade of the
biome's rock colour (low contrast). Crag (5 pieces) per biome: one colour vs shaded.
In Roblox a MeshPart has one Color, so shaded rocks need one MeshPart per piece.
Run: python3 design/rocks_biomes/rocks_multishade.py"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import partlib  # noqa: E402
import rock_meshes as RM  # noqa: E402

BIOMES = [  # name, base colour, piece shades (small steps around the base), ground
    ("Meadow", (159, 161, 172), [(159, 161, 172), (148, 151, 163), (168, 170, 179), (153, 157, 164), (164, 164, 176)],
     ((113, 173, 31), (122, 190, 25))),
    ("Desert", (234, 190, 122), [(234, 190, 122), (224, 176, 110), (240, 200, 136), (228, 184, 112), (238, 194, 130)],
     ((232, 188, 102), (250, 214, 130))),
    ("Tundra", (158, 200, 240), [(158, 200, 240), (146, 190, 234), (170, 210, 244), (152, 196, 232), (164, 202, 246)],
     ((228, 234, 242), (244, 247, 251))),
    ("Ocean", (242, 120, 98), [(242, 120, 98), (232, 108, 90), (246, 134, 110), (236, 116, 92), (244, 126, 106)],
     ((236, 214, 164), (246, 228, 184))),
]
W, H, BAND = 1500, 420, 44
FOV = 30
fnt = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)

chunks = RM.build(*{n: (f, s) for n, f, s, _ in RM.ROCKS}["RockCrag"])
wid = np.ptp(np.concatenate([np.concatenate(t) for t in chunks])[:, 0])


SPREAD = 2.2  # (QM, Oct 10: more contrast between pieces) each shade's step from the base, scaled


def spread(base, c):
    return tuple(int(max(0, min(255, b + (x - b) * SPREAD))) for b, x in zip(base, c))


def row(base, shades, ground):
    shades = [spread(base, c) for c in shades]
    partlib.GROUND = np.array(ground[0], float)
    partlib.GROUND2 = np.array(ground[1], float)
    off = wid / 2 + 8
    parts = RM.as_parts(chunks, off, 0, yaw=20, color=base)  # left: one colour
    for i, c in enumerate(chunks):
        parts += RM.as_parts([c], -off, 0, yaw=20, color=shades[i % len(shades)])  # right: shaded
    return partlib.render(parts, eye=(0, 30, -78), target=(0, 6, 0), W=W, H=H, fov=FOV, fog=False, outline=False)


sheet = Image.new("RGB", (W, len(BIOMES) * (H + BAND)), (255, 255, 255))
d = ImageDraw.Draw(sheet)
for i, (name, base, shades, ground) in enumerate(BIOMES):
    y = i * (H + BAND)
    sheet.paste(row(base, shades, ground).convert("RGB"), (0, y + BAND))
    d.text((16, y + 8), f"{name}: one colour (left) vs shaded pieces (right)", font=fnt, fill=(20, 20, 20))
    print(name)
out = os.path.join(HERE, "rocks_multishade.png")
sheet.save(out)
print("wrote", out)
