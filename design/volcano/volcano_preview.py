"""Preview of the Volcano as built (tools/volcano.py floor, tools/biome_rocks.py rocks,
tools/volcano_crack.py's crack), funnelled to its in-game width.
Run: python3 design/volcano/volcano_preview.py"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "design", "lava_biome"))
import partlib  # noqa: E402
from partlib import Part, T  # noqa: E402
import volcano as VO  # noqa: E402
import biome_rocks as BR  # noqa: E402
import rock_meshes as RM  # noqa: E402
import lava_biome as LB  # noqa: E402

OUT = "/mnt/project-files/design/volcano"
START, RATE, MAX = 56, 0.005, 137
GROW = 2.6 ** 0.8  # tools/funnel.luau: obstacles grow with the biome's AnimalSize
COL = {"Ground": [(156, 98, 66), (168, 108, 74)], "Ash": [(184, 124, 84), (196, 134, 92)],
       "Crust": [(124, 78, 58), (136, 86, 64)], "Lava": [(255, 116, 24), (255, 146, 40)]}
WALL = [(170, 92, 58), (186, 104, 66)]
SHIFT = MAX - START  # in the volcano the course is at its widest: x past the start width moves out by this


def mapx(x):
    return x * MAX / START


def window(z_hi, z_lo, crack=False):
    kind = VO.layout()
    parts = []
    for zi in range(int((z_hi - z_lo) // 4)):
        z = z_hi - zi * 4 - 2
        j = int((VO.Z_START - z) // VO.CELL)
        for xi in range(-MAX // 4, MAX // 4 + 1):
            x = xi * 4 + 2
            if abs(x) > MAX:
                continue
            i = int((x * START / MAX + VO.HALF_W) // VO.CELL)
            i = min(max(i, 0), kind.shape[0] - 1)
            k = int(kind[i, j]) if 0 <= j < kind.shape[1] else 0
            name = VO.KINDS[k]
            top = VO.TOP[k]
            p = Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), COL[name][(xi + zi) % 2])
            if name == "Lava":
                p.neon, p.plain = True, True
                p.color = tuple(c / 1.2 for c in p.color)
            parts.append(p)
    for side in (-1, 1):
        for zi in range(int((z_hi - z_lo) // 4)):
            for yi in range(6):
                parts.append(Part("Wall", (4, 4, 4), T(side * (MAX + 2), yi * 4 + 2, z_hi - zi * 4 - 2), WALL[(zi + yi) % 2], plain=True))
    items = json.load(open(os.path.join(ROOT, "design", "biome_rocks", "layout.json")))
    for it in items:
        if it["biome"] != "Volcano" or not (z_lo - 20 <= it["z"] <= z_hi + 20):
            continue
        name = it["asset"][4:]
        s = BR.ROCK_SCALE[name] * GROW
        x = it["x"] + math.copysign(SHIFT, it["x"])  # (wall-hugging: out with the wall)
        for i, ch in enumerate(RM.build(*LB.BUILD[name])):
            ch = [[v * s for v in t] for t in ch]
            parts += RM.as_parts([ch], x, it["z"], yaw=it["yaw"], color=BR.SHADES["Volcano"][i % 5])
        for p in parts[-len(RM.build(*LB.BUILD[name])):]:
            p.cf = T(0, it["y"], 0) @ p.cf
    mask, inside = [], []
    if crack:
        cz = VO.END + 50 + 110
        mask, inside = LB.demo_crack_parts(0, cz, 48, 100)
    return parts, mask, inside


def shot(parts, mask, inside, eye, target, fov=58):
    LB.DEMO = True
    return LB.shot(parts, mask, inside, eye=eye, target=target, W=1400, H=900, fov=fov)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    z = VO.Z_START - 1500
    a = shot(*window(z + 40, z - 300), eye=(0, 120, z + 70), target=(0, 0, z - 160))
    a.save(os.path.join(OUT, "volcano_ride.png"))
    print("ride")
    ze = VO.END + 50
    b = shot(*window(ze + 420, ze - 10, crack=True), eye=(0, 110, ze + 400), target=(0, 0, ze + 110), fov=55)
    b.save(os.path.join(OUT, "volcano_end.png"))
    print("end")
    band = 44
    sheet = Image.new("RGB", (1400, 2 * (900 + band)), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    for i, (img, title) in enumerate(((a, "Volcano as built: riding through (funnelled to its full width)"),
                                      (b, "The end of the volcano: the big crack before the finish line"))):
        y = i * (900 + band)
        d.text((16, y + 8), title, font=f, fill=(20, 20, 20))
        sheet.paste(img.convert("RGB"), (0, y + band))
    sheet.save(os.path.join(OUT, "volcano_biome.png"))
    print("wrote", OUT)
