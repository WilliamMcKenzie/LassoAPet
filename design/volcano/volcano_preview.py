"""Previews of the quasicrystal floors (QM, Oct 11) as they'll show in game, after
tools/funnel.luau: the Volcano (tools/volcano.py, rocks from tools/biome_rocks.py, the
crack from tools/volcano_crack.py) and the Ocean (tools/ocean_ground.py).
Run: python3 design/volcano/volcano_preview.py"""
import json
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "design", "lava_biome"))
from partlib import Part, T  # noqa: E402
import funnel_grid as FG  # noqa: E402
import volcano as VO  # noqa: E402
import ocean_ground as OG  # noqa: E402
import biome_rocks as BR  # noqa: E402
import lava_biome as LB  # noqa: E402

OUT = "/mnt/project-files/design/volcano"
GROW = 2.6 ** 0.8  # tools/funnel.luau: obstacles grow with the biome's AnimalSize
VCOL = {"Ground": [(156, 98, 66), (168, 108, 74)], "Ash": [(184, 124, 84), (196, 134, 92)],
        "Crust": [(124, 78, 58), (136, 86, 64)], "Lava": [(255, 116, 24), (255, 146, 40)]}
VWALL = [(170, 92, 58), (186, 104, 66)]


def ocean_depths():
    """Config.Biomes Ocean.Depths (the colours WorldColors paints in game)."""
    s = open(os.path.join(ROOT, "src", "shared", "Config.luau")).read()
    s = s[s.index("Depths = {", s.index('Name = "Ocean"')):]
    stops = []
    for m in re.finditer(r"At = ([\d.]+),(.*?)\n\t\t\t\t\}", s, re.S):
        d = {"At": float(m.group(1))}
        for key in ("Ground", "Grass", "Trench", "Wall"):
            k = re.search(key + r" = \{ Color3.fromRGB\((\d+), (\d+), (\d+)\), Color3.fromRGB\((\d+), (\d+), (\d+)\)", m.group(2))
            v = tuple(map(int, k.groups()))
            d[key] = [v[:3], v[3:]]
        stops.append(d)
        if d["At"] >= 1:
            break
    return stops


DEPTHS = ocean_depths()


def ocean_col(name, z):
    t = ((OG.Z_START - z) // OG.BAND + 0.5) * OG.BAND / OG.OCEAN_LENGTH
    if name == "Lava":
        return [(255, 72, 0), (255, 120, 10)]
    for a, b in zip(DEPTHS, DEPTHS[1:]):
        if t <= b["At"]:
            f = (t - a["At"]) / (b["At"] - a["At"])
            return [tuple(round(x + (y - x) * f) for x, y in zip(ca, cb)) for ca, cb in zip(a[name], b[name])]
    return DEPTHS[-1][name]


def floor(grid, names, tops, color, z_hi, z_lo, wall):
    parts = []
    for b in grid.bands:
        for j in range(b.nz):
            z0 = b.z0 - j * FG.CELL
            if not (z_lo <= z0 <= z_hi + FG.CELL):
                continue
            for i in range(b.nx):
                k = b.kind[i, j]
                top = tops[k]
                for di in (0, 1):
                    for dj in (0, 1):
                        x, z = -b.edge + i * FG.CELL + di * 4 + 2, z0 - dj * 4 - 2
                        p = Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), color(names[k], z)[(di + dj) % 2])
                        if names[k] == "Lava":
                            p.neon, p.plain = True, True
                            p.color = tuple(c / 1.2 for c in p.color)
                        parts.append(p)
            h = b.edge
            for side in (-1, 1):
                for dj in (0, 1):
                    for yi in range(6):
                        zz = z0 - dj * 4 - 2
                        parts.append(Part("Wall", (4, 4, 4), T(side * (h + 2), yi * 4 + 2, zz),
                                          wall(zz)[(dj + yi) % 2], plain=True))
    return parts


def rocks(biome, z_lo, z_hi):
    items = json.load(open(os.path.join(ROOT, "design", "biome_rocks", "layout.json")))
    parts = []
    for it in items:
        if it["biome"] != biome or not (z_lo - 20 <= it["z"] <= z_hi + 20):
            continue
        local = dict(it, x=0.0, y=0.0)  # (z kept: the ocean's colours fade with it)
        G = T(FG.map_x(it["x"], it["z"]), it["y"], it["z"]) @ np.diag([GROW, GROW, GROW, 1.0]) @ T(0, 0, -it["z"])
        for p in BR.placed_parts([local], it["z"] - 1, it["z"] + 1):
            p.cf = G @ p.cf  # (blocks and polys both scale through cf)
            parts.append(p)
    return parts


def shot(parts, mask, inside, eye, target, fov=58):
    LB.DEMO = True
    return LB.shot(parts, mask, inside, eye=eye, target=target, W=1400, H=900, fov=fov)


def volcano(z_hi, z_lo, crack=False):
    parts = floor(VO.layout(), VO.KINDS, VO.TOP, lambda n, z: VCOL[n], z_hi, z_lo, lambda z: VWALL)
    parts += rocks("Volcano", z_lo, z_hi)
    mask, inside = LB.demo_crack_parts(0, VO.CRACK_Z, 48, 100) if crack else ([], [])
    return parts, mask, inside


def ocean(z_hi, z_lo):
    tops = (0, OG.GRASS_UP, -OG.TRENCH_DOWN, -OG.LAVA_DOWN)
    return floor(OG.full_layout(), OG.KINDS, tops, ocean_col, z_hi, z_lo,
                 lambda z: ocean_col("Wall", z)) + rocks("Ocean", z_lo, z_hi), [], []


def top_down(grid, names, color, z_hi, z_lo, px=2):
    rows = []
    for b in grid.bands:
        for j in range(b.nz):
            z = b.z0 - j * FG.CELL - 4
            if z_lo < z < z_hi:
                row = np.zeros((34, 3), np.uint8) + 255
                off = (34 - b.nx) // 2
                for i in range(b.nx):
                    row[off + i] = color(names[b.kind[i, j]], z)[0]
                rows.append(row)
    a = np.array(rows).transpose(1, 0, 2)
    return Image.fromarray(a).resize((a.shape[1] * px, a.shape[0] * px), Image.NEAREST)


def sheet(shots, path):
    band = 44
    out = Image.new("RGB", (1400, len(shots) * (900 + band)), (255, 255, 255))
    d = ImageDraw.Draw(out)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    for i, (img, title) in enumerate(shots):
        y = i * (900 + band)
        d.text((16, y + 8), title, font=f, fill=(20, 20, 20))
        out.paste(img.convert("RGB"), (0, y + band))
    out.save(path)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    z = VO.Z_START - 1500
    a = shot(*volcano(z + 40, z - 340), eye=(0, 130, z + 70), target=(0, 0, z - 170))
    ze = VO.END + 50
    b = shot(*volcano(ze + 460, ze - 10, crack=True), eye=(0, 120, ze + 420), target=(0, 0, ze + 110), fov=55)
    sheet([(a, "Volcano: riding through (quasicrystal floor, rocks on its peaks)"),
           (b, "The end of the volcano: the rings spread out from the big crack")],
          os.path.join(OUT, "volcano_biome.png"))
    print("volcano")
    zo = OG.Z_START - 900
    c = shot(*ocean(zo + 40, zo - 340), eye=(0, 110, zo + 70), target=(0, 0, zo - 170))
    zd = OG.Z_START - 6600
    e = shot(*ocean(zd + 40, zd - 340), eye=(0, 130, zd + 70), target=(0, 0, zd - 170))
    sheet([(c, "Ocean reef: quasicrystal seagrass and trenches"),
           (e, "Deep ocean: raised rock and lava on the same pattern")],
          os.path.join(OUT, "ocean_quasicrystal.png"))
    print("ocean")
    # whole biomes from above, start on the left (two rows each)
    vg, og = VO.layout(), OG.full_layout()
    rows = []
    for g, names, col, z0, n in ((vg, VO.KINDS, lambda nm, z: VCOL[nm], VO.Z_START, VO.LENGTH),
                                 (og, OG.KINDS, ocean_col, OG.Z_START, OG.OCEAN_LENGTH)):
        for k in range(2):
            rows.append(top_down(g, names, col, z0 - k * n / 2, z0 - (k + 1) * n / 2))
    W = max(r.width for r in rows)
    out = Image.new("RGB", (W, sum(r.height + 10 for r in rows)), (255, 255, 255))
    y = 0
    for r in rows:
        out.paste(r, (0, y))
        y += r.height + 10
    out.save(os.path.join(OUT, "quasicrystal_top.png"))
    print("wrote", OUT)
