"""Halloween world props (QM, Oct 15), from his two reference shots: a spooky bare tree
with a lantern hanging off a branch, jack-o'-lanterns, pumpkins and fallen autumn leaves
(chunky low piles, not flat decals). Same style as the other prop sets (faceted convex pieces, flat shaded, studded, one colour
per piece). Pointy things (branch tips, the lantern roof, the leaf points) are pyramids.

Run: python3 tools/w3_halloween.py
Writes design/w3_halloween/<Name>.obj, pieces/<Name>_<i>.obj + colours.txt, sizes.txt and
halloween_lineup.png.
"""

import math
import os

import numpy as np

from w3props import HERE, blob, prism, tube, rot_y, move, build_set, lineup_row, stack
from crimson_meshes import slab
from tomb_meshes import ring, frustum

OUT = os.path.join(HERE, "..", "design", "w3_halloween")
BARK = (96, 64, 58)
BARK_DARK = (74, 50, 50)
IRON = (52, 46, 58)
GLOW = (255, 214, 60)  # lantern glass and carved faces (Neon in Studio)
PUMPKIN = (236, 96, 20)  # a redder orange than the grass so it stands out
PUMPKIN_DARK = (204, 76, 16)
STEM = (104, 120, 46)
LEAF_COLS = [(214, 52, 40), (252, 200, 50), (150, 80, 40)]  # red, yellow, brown: they read on orange grass


def cone(base, tip, r, sides=4):
    """A pyramid from a base ring of radius r (perpendicular to base->tip) to the tip."""
    base, tip = np.asarray(base, float), np.asarray(tip, float)
    a = tip - base
    a /= np.linalg.norm(a)
    u = np.cross(a, (1, 0, 0) if abs(a[0]) < 0.9 else (0, 0, 1))
    u /= np.linalg.norm(u)
    v = np.cross(a, u)
    pts = [base + (u * math.cos(t) + v * math.sin(t)) * r for t in np.linspace(0, 2 * math.pi, sides, endpoint=False)]
    return np.array(pts + [tip])


# ---------------------------------------------------------------- spooky tree

def spooky_tree(rng):
    """A bare, crooked tree (about 15 tall) with flared roots and forked branches ending in
    pyramid points; an iron lantern with a glowing pane hangs from the right branch."""
    trunk = tube(rng, [(0, -0.4, 0), (0.3, 2.5, 0.1), (-0.2, 5.0, 0), (0.2, 7.0, 0)], 1.25, 0.8, 7)
    roots = [prism(rng, (math.cos(a) * 0.6, 0.9, math.sin(a) * 0.6), (math.cos(a) * 2.4, -0.2, math.sin(a) * 2.4), 0.55, 0.25, 6, 0.0)
             for a in (0.4, 2.3, 4.3)]
    branches, tips = [], []

    def grow(p, d, length, r, depth):
        mid = p + d * length * 0.5 + (rng.uniform(-0.4, 0.4), rng.uniform(-0.2, 0.3), rng.uniform(-0.4, 0.4))
        q = p + d * length
        branches.extend(tube(rng, [p, mid, q], r, r * 0.7, 6))
        if depth == 0:
            tips.append(cone(q - d * 0.1, q + d * length * 0.45, r * 0.75))
            return
        for turn in (-0.55, 0.5):
            nd = rot_y(np.array([d]), turn + rng.uniform(-0.2, 0.2))[0] + (0, 0.25, 0)
            grow(q, nd / np.linalg.norm(nd), length * 0.7, r * 0.7, depth - 1)

    top = np.array((0.2, 7.0, 0))
    for a, e, L in ((0.2, 0.55, 4.2), (2.9, 0.6, 3.8), (1.6, 0.9, 3.4), (4.6, 0.7, 3.0)):
        d = np.array((math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e)))
        grow(top - (0, 0.6, 0), d, L, 0.6, 1)
    # the lantern arm: a near-level branch out to +x, then the lantern hanging below its end
    arm_end = np.array((5.6, 7.2, -0.6))
    branches += tube(rng, [(0.2, 5.6, 0), (2.6, 6.6, -0.3), arm_end], 0.5, 0.3, 6)
    tips.append(cone(arm_end - (0.2, 0, 0), arm_end + (1.2, 0.3, 0), 0.25))
    hx, hz = 5.0, -0.55
    rod = [prism(rng, (hx, 7.1, hz), (hx, 5.6, hz), 0.08, 0.08, 4, 0.0)]
    frame = [slab(rng, hx - 0.65, 3.4, hz - 0.65, hx + 0.65, 3.65, hz + 0.65, 0.05, 0.0),
             slab(rng, hx - 0.7, 5.15, hz - 0.7, hx + 0.7, 5.4, hz + 0.7, 0.05, 0.0)]
    frame += [slab(rng, hx + sx * 0.6 - 0.1, 3.6, hz + sz * 0.6 - 0.1, hx + sx * 0.6 + 0.1, 5.2, hz + sz * 0.6 + 0.1, 0.0, 0.0)
              for sx in (-1, 1) for sz in (-1, 1)]
    roof = [np.array(ring(4, 1.0, 5.35, a0=math.pi / 4, c=(hx, hz)) + [(hx, 6.1, hz)])]
    glass = [slab(rng, hx - 0.55, 3.6, hz - 0.55, hx + 0.55, 5.2, hz + 0.55, 0.0, 0.0)]
    return [("Trunk", BARK, trunk + roots), ("Branches", BARK_DARK, branches + tips),
            ("Lantern", IRON, rod + frame + roof), ("Glass", GLOW, glass)]


# ---------------------------------------------------------------- pumpkins

def pumpkin_parts(rng, c, r, h, lobes=8, yaw=0.0):
    """A ribbed pumpkin: lobes are clean wedges round a centre axis (bulging in the middle,
    grooved at their edges), in two alternating shades, and a stem."""
    c = np.asarray(c, float)
    prof = ((0.0, 0.5), (0.12, 0.84), (0.45, 1.0), (0.82, 0.86), (1.0, 0.42))  # (height, radius) fractions
    a_lobes, b_lobes = [], []
    for i in range(lobes):
        a0 = yaw + 2 * math.pi * i / lobes
        a1 = yaw + 2 * math.pi * (i + 1) / lobes
        pts = []
        for fy, fr in prof:
            y = h * fy
            pts.append(c + (0, y, 0))
            for a, k in ((a0, 0.86), ((a0 + a1) / 2, 1.0), (a1, 0.86)):
                pts.append(c + (math.cos(a) * r * fr * k, y, math.sin(a) * r * fr * k))
        (a_lobes if i % 2 else b_lobes).append(np.array(pts))
    stem = [prism(rng, c + (0, h * 0.85, 0), c + (r * 0.12, h + r * 0.35, 0), r * 0.16, r * 0.11, 6, 0.0)]
    return a_lobes, b_lobes, stem


def face(c, r, h, kind):
    """Glowing carved-face plates on the pumpkin's front (-z): triangle eyes and nose, a
    toothy grin. Each plate pokes a little out of the skin."""
    cx, cy, cz = c
    yc = cy + h / 2
    zf = cz - r * 0.98

    def plate(poly, depth=0.6):
        pts = []
        for x, y in poly:
            # sit each point on the front of the pumpkin, slightly proud of it
            k = max(0.0, 1 - ((x / r) ** 2 + ((y) / (h / 2)) ** 2) * 0.9)
            z = cz - r * 1.02 * math.sqrt(k) - 0.06
            pts += [(cx + x, yc + y, z), (cx + x, yc + y, z + depth)]
        return np.array(pts)

    s = r
    eyes = [plate([(-0.48 * s, 0.12 * s), (-0.16 * s, 0.12 * s), (-0.32 * s, 0.4 * s)]),
            plate([(0.16 * s, 0.12 * s), (0.48 * s, 0.12 * s), (0.32 * s, 0.4 * s)])]
    if kind == "angry":
        eyes = [plate([(-0.5 * s, 0.38 * s), (-0.14 * s, 0.2 * s), (-0.42 * s, 0.1 * s)]),
                plate([(0.5 * s, 0.38 * s), (0.14 * s, 0.2 * s), (0.42 * s, 0.1 * s)])]
    nose = [plate([(-0.08 * s, -0.04 * s), (0.08 * s, -0.04 * s), (0, 0.08 * s)])]
    mouth = []
    xs = np.linspace(-0.5 * s, 0.5 * s, 6)
    for i, (x0, x1) in enumerate(zip(xs[:-1], xs[1:])):
        sag = lambda x: -0.18 * s - 0.12 * s * (1 - (x / (0.5 * s)) ** 2)  # noqa: E731
        top = sag(x0) + 0.16 * s if i % 2 else sag(x0) + 0.22 * s
        mouth.append(plate([(x0, sag(x0)), (x1, sag(x1)), (x1, top), (x0, top)]))
    return eyes + nose + mouth


def jack(rng, r, h, kind, yaw=0.0):
    a, b, stem = pumpkin_parts(rng, (0, 0, 0), r, h)
    return [("Pumpkin", PUMPKIN, a), ("Pumpkin", PUMPKIN_DARK, b), ("Stem", STEM, stem), ("Face", GLOW, face((0, 0, 0), r, h, kind))]


def jack_o_lantern(rng):
    """A big jack-o'-lantern (about 6 across) with a glowing toothy grin."""
    return jack(rng, 3.0, 4.4, "happy")


def jack_o_lantern_small(rng):
    """A smaller, angry jack-o'-lantern (about 4 across)."""
    return jack(rng, 2.0, 2.9, "angry")


def pumpkin(rng):
    """A plain pumpkin (about 5 across)."""
    a, b, stem = pumpkin_parts(rng, (0, 0, 0), 2.5, 3.4)
    return [("Pumpkin", PUMPKIN, a), ("Pumpkin", PUMPKIN_DARK, b), ("Stem", STEM, stem)]


def pumpkin_pile(rng):
    """Three plain pumpkins together (about 8 across)."""
    A, B, S = [], [], []
    for c, r, h, yaw in (((0, 0, 0), 2.2, 3.0, 0.0), ((3.4, 0, 1.0), 1.6, 2.2, 0.3), ((-2.8, 0, 1.4), 1.3, 1.8, 0.6)):
        a, b, s = pumpkin_parts(rng, c, r, h, yaw=yaw)
        A += a
        B += b
        S += s
    return [("Pumpkin", PUMPKIN, A), ("Pumpkin", PUMPKIN_DARK, B), ("Stem", STEM, S)]


# ---------------------------------------------------------------- autumn leaves

def maple(c, s, yaw, tilt=0.0):
    """A chunky maple leaf lying on the ground: three pointed lobes (pyramid-ish plates) and
    a short stalk, about s across."""
    lobes = []
    for a, L in ((0.0, 1.0), (1.15, 0.8), (-1.15, 0.8)):
        d = np.array((math.sin(a), 0, -math.cos(a)))
        sd = np.array((-d[2], 0, d[0]))
        tip = d * s * 0.55 * L
        pts = [sd * s * 0.16, -sd * s * 0.16, tip, d * s * 0.28 * L + sd * s * 0.2, d * s * 0.28 * L - sd * s * 0.2]
        pts = [np.asarray(p) for p in pts]
        lobes.append(np.array(pts + [p + (0, 0.45, 0) for p in pts[:2]] + [pts[2] + (0, 0.15, 0)] + [p + (0, 0.35, 0) for p in pts[3:]]))
    stalk = np.array([(0, 0, 0.0), (0, 0.1, 0.0), (0.05, 0, s * 0.3), (0.05, 0.08, s * 0.3), (-0.05, 0, s * 0.3)])
    out = []
    for p in lobes + [stalk]:
        q = rot_y(p, yaw)
        q[:, 1] += 0.02 + tilt * q[:, 0]
        out.append(q + (c[0], 0, c[2]))
    return out


def leaves(rng, n, spread, mound):
    """A low chunky mound of leaves (no flat decals): a faceted heap in two leaf colours with
    thick maple leaves lying on and around it."""
    cols = {c: [] for c in LEAF_COLS}
    heap = blob(rng, (0, 0, 0), spread, 16, squash=(1.0, mound / spread, 0.85), jitter=0.08)
    heap = heap[heap[:, 1] > -0.05]
    heap = np.concatenate([heap, np.array(ring(10, spread * 0.95, 0.0, sz=0.85))])
    cols[LEAF_COLS[0]].append(heap)
    for i in range(n):
        a = rng.uniform(0, 2 * math.pi)
        d = spread * math.sqrt(rng.uniform(0.02, 1.2))
        y = mound * max(0.0, 1 - (d / spread) ** 2) * 0.85
        lf = maple((math.cos(a) * d, 0, math.sin(a) * d), rng.uniform(2.0, 2.6), rng.uniform(0, 6.28), rng.uniform(-0.1, 0.1))
        cols[LEAF_COLS[1 + i % 2]] += [p + (0, y, 0) for p in lf]
    return [("Leaves", c, hs) for c, hs in cols.items() if hs]


def leaf_pile(rng):
    """A raked pile of autumn leaves (about 7 across, 2 tall) in red, yellow and brown."""
    return leaves(rng, 12, 3.0, 1.9)


def leaf_scatter(rng):
    """A small heap of leaves (about 4 across)."""
    return leaves(rng, 6, 1.6, 1.0)


ITEMS = [  # name, builder, seed, label
    ("SpookyTree", spooky_tree, 3, "Spooky tree"),
    ("JackOLantern", jack_o_lantern, 1, "Jack-o'-lantern"),
    ("JackOLanternSmall", jack_o_lantern_small, 2, "Small jack"),
    ("Pumpkin", pumpkin, 1, "Pumpkin"),
    ("PumpkinPile", pumpkin_pile, 2, "Pumpkins"),
    ("LeafPile", leaf_pile, 4, "Leaf pile"),
    ("LeafScatter", leaf_scatter, 5, "Leaves"),
]

FLOOR = [(240, 136, 36), (226, 122, 28)]  # the Halloween world's orange grass


def main():
    built, sizes = build_set(OUT, ITEMS)
    rows = [lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[:3]], FLOOR, yaw=0),
            lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[3:]], FLOOR, ppst=36, yaw=0)]
    stack(rows, os.path.join(OUT, "halloween_lineup.png"), "Halloween props (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
