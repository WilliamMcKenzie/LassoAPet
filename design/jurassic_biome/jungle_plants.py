"""QM (Oct 10): ferns and trees for the Jurassic biome, in the studded block style (real
blocks, no flat plates). Four assets: Fern, Cycad (a stout prehistoric palm), Jungle Tree
(buttress roots, wide canopy, vines) and Horsetail (segmented reeds).
Run: python3 design/jurassic_biome/jungle_plants.py"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz  # noqa: E402
import jurassic as J  # noqa: E402

OUT = J.OUT
LEAF = [(70, 156, 52), (58, 138, 46), (90, 176, 62)]
LEAF_DARK = [(46, 112, 40), (54, 124, 44)]
FERN = [(104, 182, 66), (88, 166, 58)]
BARK = [(122, 86, 54), (108, 76, 48), (134, 96, 60)]
CYCAD = [(150, 110, 66), (132, 96, 58)]
STALK = [(120, 168, 70), (104, 150, 60)]
JOINT = (70, 104, 44)


def block(parts, M, size, color, name="Leaf"):
    parts.append(Part(name, size, M, color))


def frond(parts, M, segs, seglen, w0, thick, droop, colors, leaflets=True):
    """A leaf from M (local +Z outward): segments bending down by droop each, with
    leaflet blocks in pairs along it, tapering to the tip."""
    for i in range(segs):
        w = w0 * (1 - 0.55 * i / segs)
        mid = M @ T(0, 0, seglen / 2)
        block(parts, mid, (w, thick, seglen * 1.05), colors[i % len(colors)])
        if leaflets:
            for sgn in (-1, 1):
                L = mid @ T(sgn * (w / 2 + w * 0.55), -thick * 0.2, 0) @ Rz(sgn * 14) @ Ry(sgn * 18)
                block(parts, L, (w * 1.1, thick * 0.8, seglen * 0.55), colors[(i + 1) % len(colors)])
        M = M @ T(0, 0, seglen) @ Rx(droop)
    return parts


def fern(x=0, z=0, yaw=0, s=1.0, seed=1):
    rng = np.random.default_rng(seed)
    parts = []
    n = 8
    for i in range(n):
        a = yaw + 360 * i / n + rng.uniform(-12, 12)
        M = T(x, 0.6 * s, z) @ Ry(a) @ Rx(-rng.uniform(48, 62))
        frond(parts, M, 4, 2.0 * s, 1.3 * s, 0.45 * s, 24, FERN)
    block(parts, T(x, 0.6 * s, z), (1.6 * s, 1.2 * s, 1.6 * s), LEAF_DARK[0])  # the heart
    return parts


def cycad(x=0, z=0, yaw=0, s=1.0, seed=2):
    rng = np.random.default_rng(seed)
    parts = []
    y = 0
    lean = rng.uniform(-6, 6)
    M = T(x, 0, z) @ Ry(yaw) @ Rz(lean)
    for i in range(7):  # a scaly trunk: stacked blocks, each turned a little (pineapple bark)
        h = 2.0 * s
        w = (3.4 - 0.18 * i) * s
        block(parts, M @ T(0, y + h / 2, 0) @ Ry(i * 22), (w, h * 1.02, w), CYCAD[i % 2], "Bark")
        y += h
    top = M @ T(0, y, 0)
    block(parts, top @ T(0, 0.6 * s, 0), (2.6 * s, 1.4 * s, 2.6 * s), LEAF_DARK[1])
    n = 9
    for i in range(n):
        a = 360 * i / n + rng.uniform(-10, 10)
        F = top @ T(0, 0.8 * s, 0) @ Ry(a) @ Rx(-rng.uniform(30, 45))
        frond(parts, F, 5, 2.4 * s, 1.5 * s, 0.5 * s, 16, LEAF)
    return parts


def jungle_tree(x=0, z=0, yaw=0, s=1.0, seed=3):
    rng = np.random.default_rng(seed)
    parts = []
    B = T(x, 0, z) @ Ry(yaw)
    trunk_h = 20 * s
    for i in range(5):  # trunk: thick, slightly narrowing, a few offset blocks for knots
        h = trunk_h / 5
        w = (4.6 - 0.35 * i) * s
        block(parts, B @ T(rng.uniform(-0.3, 0.3) * s, h * i + h / 2, rng.uniform(-0.3, 0.3) * s) @ Ry(rng.uniform(-8, 8)),
              (w, h * 1.03, w), BARK[i % 3], "Bark")
    for i in range(5):  # buttress roots: wedges of blocks leaning out from the base
        a = 72 * i + rng.uniform(-15, 15)
        R = B @ Ry(a) @ T(0, 0, 2.2 * s)
        block(parts, R @ T(0, 2.4 * s, 0.6 * s) @ Rx(28), (1.2 * s, 5.0 * s, 2.0 * s), BARK[(i + 1) % 3], "Bark")
        block(parts, R @ T(0, 0.8 * s, 2.0 * s) @ Rx(55), (1.0 * s, 2.6 * s, 2.2 * s), BARK[i % 3], "Bark")
    for i in range(3):  # two or three branches out to the canopy
        a = 120 * i + rng.uniform(-20, 20)
        Br = B @ T(0, trunk_h * 0.78, 0) @ Ry(a) @ Rx(-50)
        block(parts, Br @ T(0, 0, 3.5 * s), (1.6 * s, 1.6 * s, 7 * s), BARK[1], "Bark")
    # canopy: a wide, flat-topped mass of leaf blocks, darker underneath
    cy = trunk_h + 2 * s
    for k in range(14):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(0, 9) * s
        w = rng.uniform(7, 11) * s
        h = rng.uniform(3.5, 5) * s
        px, pz = r * math.cos(a), r * math.sin(a)
        dy = -0.9 * s if r > 6 * s else rng.uniform(0, 1.5) * s
        block(parts, B @ T(px, cy + dy, pz) @ Ry(rng.uniform(0, 90)), (w, h, w * rng.uniform(0.8, 1.1)), LEAF[k % 3])
    for k in range(6):  # under-canopy, darker
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(3, 10) * s
        block(parts, B @ T(r * math.cos(a), cy - 2.6 * s, r * math.sin(a)) @ Ry(rng.uniform(0, 90)),
              (6 * s, 2.2 * s, 6 * s), LEAF_DARK[k % 2])
    for k in range(7):  # vines hanging from the canopy edge
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(6, 9) * s
        ln = rng.uniform(5, 10) * s
        block(parts, B @ T(r * math.cos(a), cy - 3 * s - ln / 2, r * math.sin(a)), (0.6 * s, ln, 0.6 * s), LEAF_DARK[k % 2], "Vine")
        block(parts, B @ T(r * math.cos(a), cy - 3 * s - ln, r * math.sin(a)) @ Ry(45), (1.4 * s, 1.0 * s, 1.4 * s), LEAF[2], "Vine")
    return parts


def horsetail(x=0, z=0, yaw=0, s=1.0, seed=4):
    rng = np.random.default_rng(seed)
    parts = []
    for k in range(9):  # a clump of segmented reeds with dark joints and little whorls
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(0, 2.4) * s
        bx, bz = x + r * math.cos(a), z + r * math.sin(a)
        tilt = rng.uniform(-10, 10)
        M = T(bx, 0, bz) @ Ry(rng.uniform(0, 360)) @ Rx(tilt)
        n = int(rng.integers(4, 7))
        seg = 1.8 * s
        for i in range(n):
            w = (0.9 - 0.08 * i) * s
            block(parts, M @ T(0, seg * i + seg / 2, 0), (w, seg * 0.95, w), STALK[i % 2], "Stalk")
            block(parts, M @ T(0, seg * (i + 1), 0), (w * 1.5, 0.3 * s, w * 1.5), JOINT, "Stalk")
        block(parts, M @ T(0, seg * n + 0.6 * s, 0), (w * 1.1, 1.2 * s, w * 1.1), (150, 120, 70), "Stalk")  # the cone tip
    return parts


ASSETS = [("Fern", fern, 2.0), ("Cycad", cycad, 1.6), ("Jungle Tree", jungle_tree, 1.5), ("Horsetail", horsetail, 1.6)]


def lineup():
    partlib.SKY_TOP = partlib.SKY_BOT = J.SKY
    partlib.GROUND = np.array(J.GRASS[0], float)
    partlib.GROUND2 = np.array(J.GRASS[1], float)
    xs = [-62, -30, 12, 54]
    parts = []
    for (name, fn, sc), x in zip(ASSETS, xs):
        parts += fn(-x, 0, 20, sc)
    img = partlib.render(parts, eye=(0, 40, -110), target=(0, 18, 0), W=1600, H=760, fov=50, fog=False, outline=False)
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
    e, r, u, fw = partlib.look_at((0, 40, -110), (0, 18, 0))
    focal = (760 / 2) / math.tan(math.radians(50) / 2)
    for (name, _, _), x in zip(ASSETS, xs):
        dv = np.array([-x, 0, 0.0]) - e
        px = 800 + focal * (dv @ r) / (dv @ fw)
        tw = d.textlength(name, font=f)
        d.text((px - tw / 2, 700), name, font=f, fill=(255, 255, 255), stroke_width=4, stroke_fill=(0, 0, 0))
    return img


def in_biome():
    parts = J.scene()
    rng = np.random.default_rng(9)
    z = 20
    k = 0
    while z > J.Z_LO + 20:  # clusters by the walls, alternating sides; trees the anchors
        side = 1 if k % 2 else -1
        x = side * (J.HALF_W - rng.uniform(14, 26))
        if J.RIB_Z0 + 10 > z > J.RIB_Z0 - (J.RIB_N - 1) * J.RIB_GAP - 10 and k % 3:
            parts += cycad(x, z, rng.uniform(0, 360), 1.6, k)  # (inside the ribcage: lower plants)
        else:
            parts += jungle_tree(x, z, rng.uniform(0, 360), 1.5, k)
        parts += fern(x - side * 16, z + rng.uniform(-10, 10), rng.uniform(0, 360), 2.0, k + 50)
        parts += horsetail(x - side * 8, z - 14, 0, 1.6, k + 80)
        if k % 2 == 0:
            parts += fern(J.trail_x(z - 30) + side * 30, z - 30, 0, 1.6, k + 90)  # a few out in the open
        z -= 46
        k += 1
    partlib.SKY_TOP = partlib.SKY_BOT = J.SKY
    partlib.GROUND = np.array(J.GRASS[0], float)
    partlib.GROUND2 = np.array(J.GRASS[1], float)
    return partlib.render(parts, eye=(0, 110, 90), target=(0, 10, -110), W=1400, H=900, fov=58, fog=False, outline=False)


if __name__ == "__main__":
    a = lineup()
    a.save(os.path.join(OUT, "jungle_plants.png"))
    print("lineup")
    b = in_biome()
    b.save(os.path.join(OUT, "jurassic_with_plants.png"))
    print("wrote", OUT)
