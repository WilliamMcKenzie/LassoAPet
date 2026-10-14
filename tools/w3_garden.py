"""World 3 biome 2, Garden props (QM, Oct 14): a giant's garden that makes the player feel
tiny. Giant daisy, giant tulip, sunflower, toadstools, hedge wall, topiary, picket fence,
watering can, garden gnome, giant leaf, flower patch. Same style as the other prop sets
(faceted convex pieces, flat shaded, studded, one colour per piece). Colours are my picks.

Run: python3 tools/w3_garden.py
Writes design/w3_garden/<Name>.obj, pieces/<Name>_<i>.obj + colours.txt, sizes.txt and
garden_lineup.png.
"""

import math
import os

import numpy as np

from w3props import (HERE, blob, prism, ball, disc, tube, torus, rot_y, rot_x, rot_z, move,
                     build_set, lineup_row, stack)
from crimson_meshes import slab
from tomb_meshes import ring, frustum, band

OUT = os.path.join(HERE, "..", "design", "w3_garden")
STEM = (78, 172, 56)
LEAF = (60, 160, 66)
LEAF_LIGHT = (104, 200, 78)
PETAL_WHITE = (250, 250, 244)
YELLOW = (255, 204, 40)
ORANGE = (250, 150, 30)
SEEDS = (120, 74, 40)
RED = (236, 50, 60)
PINK = (250, 110, 170)
PURPLE = (160, 96, 230)
CREAM = (246, 236, 214)
CAP = (232, 52, 52)
HEDGE = (58, 148, 62)
HEDGE_LIGHT = (84, 176, 72)
POT = (214, 112, 70)
POT_RIM = (188, 92, 56)
FENCE = (250, 250, 250)
CAN = (64, 192, 176)
CAN_DARK = (40, 150, 140)
SKIN = (255, 200, 160)
BLUE = (60, 110, 220)
BOOT = (110, 70, 40)


def frame(n):
    """Two unit vectors perpendicular to n."""
    n = np.asarray(n, float) / np.linalg.norm(n)
    u = np.cross(n, (0, 1, 0) if abs(n[1]) < 0.9 else (1, 0, 0))
    u /= np.linalg.norm(u)
    return u, np.cross(n, u)


def petal(c, d, n, length, width, thick=0.25, cup=0.0, start=0.0):
    """A flat leaf-shaped petal from c out along d (unit), lying in the plane with normal n;
    cup lifts the tip along n."""
    c, d, n = (np.asarray(v, float) for v in (c, d, n))
    s = np.cross(n, d)
    pts = []
    for t, w in ((start, 0.25), (0.35, 1.0), (0.75, 0.8), (1.0, 0.15)):
        p = c + d * length * t + n * cup * t * t
        for k in (-1, 1):
            for h in (-thick / 2 * (1 - 0.6 * t), thick / 2 * (1 - 0.6 * t)):  # a wedge, thinning to the tip
                pts.append(p + s * k * width / 2 * w + n * h)
    return np.array(pts)


def leaf(rng, base, yaw, length, width, rise=0.3, droop=1.0, roll=0.0):
    """A long arching leaf from base: two convex halves (inner and outer); roll turns the
    blade from lying flat (0) toward standing on edge (pi/2)."""
    d = np.array((math.cos(yaw), 0, math.sin(yaw)))
    mid = np.asarray(base, float) + d * length * 0.5 + (0, length * rise, 0)
    tip = np.asarray(base, float) + d * length + (0, length * rise - droop, 0)
    n1 = np.cross(d, (0, 1, 0))
    out = []
    for p, q, st in ((np.asarray(base, float), mid, 0.0), (mid, tip, -0.1)):
        dd = (q - p) / np.linalg.norm(q - p)
        n = math.cos(roll) * np.cross(dd, n1) + math.sin(roll) * n1
        out.append(petal(p, dd, n / np.linalg.norm(n), np.linalg.norm(q - p) * (1.05 if st == 0 else 1.0), width, 0.7, 0.0, st))
    return out


def flower_head(c, n, r_centre, n_petals, petal_len, petal_w, petal_col, centre_col, cup=0.6, a0=0.0):
    """A disc centre facing n and a ring of petals; returns (petals, centre)."""
    u, v = frame(n)
    n = np.asarray(n, float) / np.linalg.norm(n)
    petals = []
    for i in range(n_petals):
        a = a0 + 2 * math.pi * i / n_petals
        d = u * math.cos(a) + v * math.sin(a)
        petals.append(petal(np.asarray(c) + d * r_centre * 0.6 - n * 0.1, d, n, petal_len, petal_w, petal_w * 0.6, cup))
    pts = []
    for i in range(12):
        a = 2 * math.pi * i / 12
        d = u * math.cos(a) + v * math.sin(a)
        pts += [np.asarray(c) + d * r_centre - n * 0.2, np.asarray(c) + d * r_centre * 0.95 + n * 0.35,
                np.asarray(c) + d * r_centre * 0.5 + n * 0.75]
    return petals, [np.array(pts)]


def tall_flower(rng, h, lean, n_petals, petal_len, petal_w, r_centre, petal_col, centre_col, tilt=0.5, cup=0.6):
    path = [(0, -0.4, 0), (lean * 0.2, h * 0.35, 0.1), (lean * 0.6, h * 0.7, -0.2), (lean, h, -0.6)]
    stem = tube(rng, path, 0.75, 0.55, 7)
    top = np.array(path[-1], float)
    n = np.array((0, math.cos(tilt), -math.sin(tilt)))
    calyx = [frustum(8, 0.6, 0, 1.3, 0.9) @ np.eye(3) + top - (0, 0.6, 0)]
    petals, centre = flower_head(top + n * 0.4, n, r_centre, n_petals, petal_len, petal_w, petal_col, centre_col, cup)
    leaves = leaf(rng, np.array((0, h * 0.25, 0)), 0.9, h * 0.35, 1.8, 0.25, 1.2) + leaf(rng, np.array((0, h * 0.4, 0)), 3.8, h * 0.3, 1.6, 0.25, 1.0)
    return [("Stem", STEM, stem + calyx), ("Leaves", LEAF, leaves), ("Petals", petal_col, petals), ("Centre", centre_col, centre)]


def daisy(rng):
    """A giant daisy (about 17 tall): white petals, yellow centre, nodding forward."""
    return tall_flower(rng, 15.0, 1.5, 14, 4.2, 1.5, 2.0, PETAL_WHITE, YELLOW)


def sunflower(rng):
    """A giant sunflower (about 22 tall): big brown seed face, yellow petals."""
    p = tall_flower(rng, 20.0, -1.0, 18, 3.6, 1.5, 3.2, YELLOW, SEEDS, tilt=0.35, cup=0.3)
    p[2] = ("Petals", YELLOW, p[2][2])
    return p


def tulip(rng):
    """A giant tulip (about 13 tall): a closed red cup of six petals, two long leaves."""
    h = 11.0
    path = [(0, -0.4, 0), (0.4, h * 0.5, 0), (0.6, h, -0.2)]
    stem = tube(rng, path, 0.6, 0.5, 7)
    top = np.array(path[-1], float)
    petals = []
    for i in range(6):
        a = 2 * math.pi * i / 6 + (0.5 if i % 2 else 0)
        rr = 1.6 if i % 2 else 1.75
        d = np.array((math.cos(a), 0, math.sin(a)))
        pts = []
        for y, w in ((0.0, 0.5), (1.2, 1.0), (2.6, 1.05), (3.7, 0.8), (4.3, 0.2)):
            c = top + d * (0.5 + rr * w * 0.85 - (0.25 if y > 3.5 else 0)) + (0, y, 0)
            s = np.cross(d, (0, 1, 0))
            for k in (-1, 1):
                pts += [c + s * k * 1.1 * w, c + s * k * 1.0 * w - d * 0.35]
        petals.append(np.array(pts))
    leaves = (leaf(rng, np.array((0, 0.2, 0)), 0.4, 6.0, 3.2, 0.9, 2.0, 1.1)
              + leaf(rng, np.array((0, 0.4, 0)), 3.6, 5.5, 3.0, 1.0, 2.0, 1.1))
    core = [ball(top + (0, 1.8, 0), 1.6, 12)]
    return [("Stem", STEM, stem), ("Leaves", LEAF_LIGHT, leaves), ("Petals", RED, petals[0::2]), ("Petals", (250, 84, 96), petals[1::2] + core)]


def mushroom(rng, x, z, h, cap_r, stem_r, lean=0.0):
    top = np.array((x + lean, h, z))
    stem = [prism(rng, (x, -0.4, z), top, stem_r * 1.15, stem_r * 0.85, 9, 0.03)]
    dome = blob(rng, top + (0, cap_r * 0.1, 0), cap_r, 22, squash=(1.0, 0.62, 1.0), jitter=0.04)
    dome = dome[dome[:, 1] > top[1] - 0.2]
    lip = np.array(ring(14, cap_r * 1.03, top[1] - 0.25, c=(top[0], top[2])))
    under = np.array(ring(12, cap_r * 0.9, top[1] - 0.15, c=(top[0], top[2])) + ring(12, stem_r * 1.0, top[1] - cap_r * 0.3, c=(top[0], top[2])))
    skirt = frustum(10, stem_r * 1.0, h * 0.62, stem_r * 1.6, h * 0.55, c=(x + lean * 0.62, z))
    return [np.concatenate([dome, lip])], [stem[0], skirt], [under]


def toadstool(rng):
    """A giant red toadstool (about 13 tall) with a cream stem and a skirt ring."""
    cap, stem, under = mushroom(rng, 0, 0, 10.5, 6.0, 1.5, 0.6)
    return [("Stem", CREAM, stem), ("Underside", (236, 200, 170), under), ("Cap", CAP, cap)]


def toadstools(rng):
    """A cluster of three small toadstools (about 6 across)."""
    caps, stems, unders = [], [], []
    for x, z, h, r, s, lean in ((0, 0, 4.2, 2.2, 0.6, 0.3), (2.4, 1.2, 2.6, 1.4, 0.45, 0.3), (-2.0, 1.4, 1.8, 1.1, 0.35, -0.2)):
        c, st, u = mushroom(rng, x, z, h, r, s, lean)
        caps += c
        stems += st
        unders += u
    return [("Stem", CREAM, stems), ("Underside", (236, 200, 170), unders), ("Cap", (255, 120, 40), caps)]


def hedge(rng):
    """A clipped hedge wall (about 16 long, 7 tall): a box with a rounded, bumpy top."""
    core = [slab(rng, -8, 0, -2.2, 8, 5.4, 2.2, 0.6, 0.05)]
    bumps = []
    for i in range(7):
        x = -6.9 + i * 2.3
        bumps.append(blob(rng, (x, 5.0, rng.uniform(-0.3, 0.3)), 2.5, 14, squash=(1.0, 0.7, 0.95), jitter=0.06))
    return [("Hedge", HEDGE, core), ("Top", HEDGE_LIGHT, bumps)]


def topiary(rng):
    """A topiary in a pot (about 11 tall): three stacked balls on a trunk."""
    pot = [frustum(10, 1.9, 0, 2.5, 3.0)]
    rim = [frustum(10, 2.75, 2.7, 2.75, 3.6)]
    trunk = [prism(rng, (0, 2.5, 0), (0, 9.0, 0), 0.35, 0.3, 6, 0.0)]
    balls = [ball((0, 5.3, 0), 2.2, 22), ball((0, 8.4, 0), 1.6, 18), ball((0, 10.6, 0), 1.0, 14)]
    soil = [disc((0, 3.4, 0), 2.4, 0.3, 10)]
    return [("Pot", POT, pot), ("Rim", POT_RIM, rim), ("Soil", SEEDS, soil), ("Trunk", BOOT, trunk), ("Leaves", HEDGE_LIGHT, balls)]


def fence(rng):
    """A white picket fence section (about 12 long, 4 tall)."""
    pickets = []
    for i in range(9):
        x = -5.6 + i * 1.4
        pts = [(x + dx, y, dz) for dx in (-0.45, 0.45) for y in (-0.4, 3.4) for dz in (-0.15, 0.15)]
        pts += [(x, 4.2, dz) for dz in (-0.15, 0.15)]
        pickets.append(np.array(pts))
    rails = [slab(rng, -6.2, y, 0.15, 6.2, y + 0.4, 0.45, 0.04, 0.0) for y in (0.9, 2.6)]
    return [("Pickets", FENCE, pickets), ("Rails", (226, 226, 232), rails)]


def watering_can(rng):
    """A giant watering can (about 13 long, 9 tall) standing, spout forward."""
    body = [frustum(14, 3.4, 0, 3.0, 6.0)]
    top = [frustum(14, 3.0, 5.9, 1.8, 6.8)]
    hoops = [band(body[0], 0.0, 0.5, 0.03), band(body[0], 5.4, 6.0, 0.03)]
    spout = tube(rng, [(0, 1.5, -2.6), (0, 4.0, -5.6), (0, 7.0, -8.0)], 0.75, 0.5, 8)
    rose = [frustum(10, 0.6, 0, 1.3, 1.0) @ np.array([[1, 0, 0], [0, 0.8, 0.6], [0, -0.6, 0.8]]).T + (0, 7.0, -8.0)]
    handle = torus((0, 6.4, 1.0), 2.4, 0.38, 9, 6, axis="z", arc=(0.15, math.pi * 0.9))
    handle = move(handle, lambda p: rot_y(p, math.pi / 2, (0, 0, 1.0)))
    return [("Can", CAN, body), ("Top", CAN_DARK, top + hoops), ("Spout", CAN, spout), ("Rose", (250, 210, 70), rose), ("Handle", CAN_DARK, handle)]


def gnome(rng):
    """A giant garden gnome (about 10 tall): boots, blue coat, belt, white beard, round nose,
    tall red pyramid hat."""
    boots = [blob(rng, (s * 0.9, 0.5, -0.3), 0.9, 12, squash=(0.9, 0.6, 1.3), jitter=0.03) for s in (-1, 1)]
    coat = [frustum(10, 2.0, 0.6, 1.5, 4.6)]
    belt = [band(coat[0], 2.6, 3.1, 0.04)]
    buckle = [slab(rng, -0.45, 2.55, -2.05, 0.45, 3.15, -1.8, 0.05, 0.0)]
    arms = [prism(rng, (s * 1.5, 4.2, 0), (s * 2.0, 2.6, -0.8), 0.5, 0.45, 7, 0.0) for s in (-1, 1)]
    hands = [ball((s * 2.0, 2.4, -0.9), 0.55, 10) for s in (-1, 1)]
    head = [ball((0, 5.4, 0), 1.45, 16)]
    nose = [ball((0, 5.4, -1.45), 0.5, 10)]
    beard = [np.array([(0, 2.6, -1.85), (-1.4, 5.0, -1.0), (1.4, 5.0, -1.0), (-0.9, 3.6, -1.6), (0.9, 3.6, -1.6),
                       (-1.3, 5.0, 0.2), (1.3, 5.0, 0.2), (0, 3.4, -0.4)])]
    hat = [np.array(ring(4, 1.75, 6.1, a0=math.pi / 4) + [(0.4, 10.4, 0.9)])]  # a pyramid
    brim = [frustum(4, 1.8, 5.9, 1.8, 6.4, a0=math.pi / 4)]
    return [("Boots", BOOT, boots), ("Coat", BLUE, coat + arms), ("Belt", SEEDS, belt), ("Buckle", YELLOW, buckle),
            ("Skin", SKIN, head + nose + hands), ("Beard", PETAL_WHITE, beard), ("Hat", RED, hat + brim)]


def giant_leaf(rng):
    """A giant fallen leaf (about 9 x 14): a thick faceted body in two shades, edges curled up,
    a raised pale midrib and a stalk."""
    halves = []
    for s in (-1, 1):
        pts = []
        for z, w in ((-6.0, 0.4), (-3.6, 3.0), (0.0, 4.2), (3.4, 3.2), (5.8, 0.4)):
            pts += [(0, 0.0, z), (0, 1.3, z), (s * w, 0.6 + w * 0.3, z), (s * w, 1.3 + w * 0.3, z), (s * w * 0.55, 0.0, z), (s * w * 0.55, 1.1, z)]
        halves.append(np.array(pts))
    rib = [np.array([(dx, y, z) for z, wz in ((-6.6, 0.5), (0.0, 0.7), (6.0, 0.25)) for dx in (-wz, wz) for y in (1.0, 1.75 - abs(z) * 0.06)])]
    stalk = [prism(rng, (0, 0.9, -6.4), (0.4, 1.9, -8.2), 0.45, 0.35, 6, 0.0)]
    return [("Leaf", LEAF, halves[:1]), ("Leaf", LEAF_LIGHT, halves[1:]), ("Rib", (170, 220, 110), rib + stalk)]


def flower_patch(rng):
    """Three big blooms (about 6 across) in pink, purple and yellow, with chunky leaves."""
    stems, centres, leaves = [], [], []
    blooms = []
    for (x, z, h), col in zip(((0, 0, 3.4), (2.2, 1.0, 2.4), (-2.1, 0.9, 2.8)), (PINK, PURPLE, YELLOW)):
        top = np.array((x, h, z))
        stems.append(prism(rng, (x, -0.2, z), top, 0.3, 0.25, 6, 0.0))
        n = np.array((x * 0.1, 1.0, -0.5))
        p, c = flower_head(top, n, 0.55, 5, 1.3, 1.0, None, None, 0.3, rng.uniform(0, 1))
        blooms.append(("Petals", col, p))
        centres += c
        leaves += [petal((x, 0.1, z), (math.cos(a), 0.3, math.sin(a)), (0, 1, 0), 1.6, 0.9, 0.5, 0.2) for a in (0.6 + x, 3.7 + x)]
    return [("Stems", STEM, stems + leaves), ("Centres", ORANGE, centres)] + blooms


ITEMS = [  # name, builder, seed, label
    ("GiantSunflower", sunflower, 3, "Sunflower"),
    ("GiantDaisy", daisy, 1, "Giant daisy"),
    ("GiantTulip", tulip, 2, "Giant tulip"),
    ("GiantToadstool", toadstool, 1, "Toadstool"),
    ("HedgeWall", hedge, 1, "Hedge wall"),
    ("WateringCan", watering_can, 1, "Watering can"),
    ("GardenGnome", gnome, 1, "Garden gnome"),
    ("Topiary", topiary, 1, "Topiary"),
    ("PicketFence", fence, 1, "Picket fence"),
    ("GiantLeaf", giant_leaf, 1, "Giant leaf"),
    ("Toadstools", toadstools, 2, "Toadstools"),
    ("FlowerPatch", flower_patch, 4, "Flower patch"),
]

GRASS = [(110, 200, 74), (98, 188, 66)]


def main():
    built, sizes = build_set(OUT, ITEMS)
    rows = [lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[:6]], GRASS),
            lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[6:]], GRASS, ppst=30)]
    stack(rows, os.path.join(OUT, "garden_lineup.png"), "Garden props (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
