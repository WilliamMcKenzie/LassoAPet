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
PUMPKIN = (206, 70, 18)  # a deep red-orange, darker than the grass so it pops
PUMPKIN_DARK = (172, 54, 14)
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
            tips.append(cone(q - d * 0.1, q + d * length * 0.45, r * 0.9))
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
    rod_frame, glass = lantern(rng, 5.0, -0.55, 7.1)
    return [("Trunk", BARK, trunk + roots), ("Branches", BARK_DARK, branches + tips),
            ("Lantern", IRON, rod_frame), ("Glass", GLOW, glass)]


def lantern(rng, hx, hz, top):
    """An iron lantern hanging on a rod from (hx, top, hz): base and cap plates, corner
    posts, a pyramid roof and a glowing pane. Returns (iron, glass)."""
    b = top - 3.7  # the lantern's base
    rod = [prism(rng, (hx, top, hz), (hx, b + 2.2, hz), 0.08, 0.08, 4, 0.0)]
    frame = [slab(rng, hx - 0.65, b, hz - 0.65, hx + 0.65, b + 0.25, hz + 0.65, 0.05, 0.0),
             slab(rng, hx - 0.7, b + 1.75, hz - 0.7, hx + 0.7, b + 2.0, hz + 0.7, 0.05, 0.0)]
    frame += [slab(rng, hx + sx * 0.6 - 0.1, b + 0.2, hz + sz * 0.6 - 0.1, hx + sx * 0.6 + 0.1, b + 1.8, hz + sz * 0.6 + 0.1, 0.0, 0.0)
              for sx in (-1, 1) for sz in (-1, 1)]
    roof = [np.array(ring(4, 1.0, b + 1.95, a0=math.pi / 4, c=(hx, hz)) + [(hx, b + 2.7, hz)])]
    glass = [slab(rng, hx - 0.55, b + 0.2, hz - 0.55, hx + 0.55, b + 1.8, hz + 0.55, 0.0, 0.0)]
    return rod + frame + roof, glass


def lantern_tree(rng):
    """An autumn tree (about 13 tall): a short trunk and three thick branches under a round
    canopy of faceted leaf clumps in red, orange and crimson, red apples hanging below, and
    an iron lantern hanging from a low branch."""
    trunk = tube(rng, [(0, -0.4, 0), (0.4, 3.0, 0.1), (0.1, 6.0, 0)], 1.3, 0.85, 7)
    roots = [prism(rng, (math.cos(a) * 0.6, 0.9, math.sin(a) * 0.6), (math.cos(a) * 2.3, -0.2, math.sin(a) * 2.3), 0.55, 0.25, 6, 0.0)
             for a in (0.4, 2.3, 4.3)]
    branches = []
    for a, e, L in ((0.3, 0.6, 3.6), (2.8, 0.6, 3.4), (4.5, 0.8, 2.8)):
        d = np.array((math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e)))
        branches += tube(rng, [(0.1, 5.4, 0), (0.1, 5.4, 0) + d * L], 0.6, 0.35, 6)
    # the lantern arm, low and to the right, sticking out from under the canopy
    arm_end = np.array((5.4, 5.6, -0.8))
    branches += tube(rng, [(0.2, 4.4, 0), (2.8, 5.2, -0.4), arm_end], 0.5, 0.3, 6)
    rod_frame, glass = lantern(rng, 4.9, -0.75, 5.5)
    clumps = [[], [], []]
    for i, (x, y, z, r) in enumerate(((0, 10.6, 0, 3.2), (2.9, 9.4, 0.6, 2.4), (-2.9, 9.2, 0.4, 2.5), (0.6, 9.0, -2.5, 2.3),
                                      (-0.8, 9.2, 2.6, 2.3), (2.0, 11.6, 1.2, 1.9), (-1.9, 11.4, -1.0, 2.0))):
        clumps[i % 3].append(blob(rng, (x, y, z), r, 22, squash=(1.0, 0.85, 1.0), jitter=0.06))
    apples, stems = [], []
    for x, y, z in ((1.6, 7.9, -2.9), (-1.8, 8.1, -2.8), (3.9, 8.4, -1.2), (-4.1, 8.2, -0.6), (0.2, 7.4, -1.6), (2.6, 7.6, 2.2)):
        apples.append(blob(rng, (x, y, z), 0.6, 12, jitter=0.03))
        stems.append(prism(rng, (x, y + 0.4, z), (x, y + 0.9, z), 0.07, 0.07, 4, 0.0))
    return [("Trunk", BARK, trunk + roots + branches), ("Leaves", (204, 52, 40), clumps[0]), ("Leaves", (232, 102, 36), clumps[1]),
            ("Leaves", (160, 34, 62), clumps[2]), ("Apples", (226, 30, 40), apples), ("Lantern", IRON, rod_frame + stems),
            ("Glass", GLOW, glass)]


# ---------------------------------------------------------------- harvest

STRAW = (232, 196, 96)
STRAW_DARK = (206, 166, 70)
TWINE = (120, 78, 44)
WOOD = (120, 82, 52)


def bale(rng, x, y, z, yaw=0.0, w=3.6, h=1.8, d=2.2):
    """A hay bale: a straw block with two twine bands round it. Returns (straw, twine)."""
    body = slab(rng, -w / 2, 0, -d / 2, w / 2, h, d / 2, 0.18, 0.0)
    bands = [slab(rng, bx - 0.14, -0.04, -d / 2 - 0.06, bx + 0.14, h + 0.06, d / 2 + 0.06, 0.0, 0.0) for bx in (-w * 0.26, w * 0.26)]
    put = lambda p: rot_y(p, yaw) + (x, y, z)  # noqa: E731
    return [put(body)], [put(b) for b in bands]


def hay_bale(rng):
    """One hay bale (about 4 x 2 x 2)."""
    s, t = bale(rng, 0, 0, 0)
    return [("Straw", STRAW, s), ("Twine", TWINE, t)]


def hay_stack(rng):
    """Two bales side by side and one on top (about 5 wide, 4 tall)."""
    S, T = [], []
    for x, y, z, yaw in ((-1.0, 0, 0.0, 1.57), (1.4, 0, 0.1, 1.57), (0.2, 1.8, 0.05, 0.08)):
        s, t = bale(rng, x, y, z, yaw)
        S += s
        T += t
    return [("Straw", STRAW, S[:2]), ("Straw", STRAW_DARK, S[2:]), ("Twine", TWINE, T)]


def scarecrow(rng):
    """A scarecrow (about 10 tall): a post and crossbar, a patched green shirt with straw
    poking out of the cuffs and hem, a jack-o'-lantern head and a pointed witch hat."""
    post = [slab(rng, -0.3, -0.4, -0.3, 0.3, 7.0, 0.3, 0.05, 0.0)]
    bar = [slab(rng, -3.4, 5.0, -0.25, 3.4, 5.5, 0.25, 0.05, 0.0)]
    shirt = [slab(rng, -1.3, 2.6, -0.75, 1.3, 5.7, 0.75, 0.25, 0.0)]
    sleeves = [slab(rng, -3.0, 4.75, -0.55, -1.1, 5.75, 0.55, 0.15, 0.0), slab(rng, 1.1, 4.75, -0.55, 3.0, 5.75, 0.55, 0.15, 0.0)]
    patches = [slab(rng, -0.9, 3.2, -0.85, -0.2, 3.9, -0.7, 0.05, 0.0), slab(rng, 1.9, 4.85, -0.65, 2.5, 5.55, -0.5, 0.05, 0.0)]
    rope = [slab(rng, -1.35, 3.0, -0.8, 1.35, 3.3, 0.8, 0.0, 0.0)]
    straw = []
    for s in (-1, 1):  # straw tufts out of each cuff: pyramids
        for dy, dz in ((0.25, 0.0), (-0.2, 0.25), (-0.15, -0.25)):
            c = np.array((s * 3.0, 5.25 + dy, dz))
            straw.append(np.array([c + (0, dy2, dz2) for dy2 in (-0.22, 0.22) for dz2 in (-0.22, 0.22)] + [c + (s * 1.0, dy * 0.8, dz * 0.8)]))
    for x in (-0.9, -0.3, 0.3, 0.9):  # and down from the hem
        c = np.array((x, 2.7, -0.2))
        straw.append(np.array([c + (dx, 0, dz) for dx in (-0.25, 0.25) for dz in (-0.25, 0.25)] + [c + (x * 0.15, -1.0, 0)]))
    a, b, stem = pumpkin_parts(rng, (0, 5.6, 0), 1.35, 2.0)
    fc = face((0, 5.6, 0), 1.35, 2.0, "happy")
    hat_brim = [frustum(8, 1.9, 7.3, 1.9, 7.55)]
    hat = [np.array(ring(4, 1.05, 7.5, a0=math.pi / 4) + [(0.7, 10.0, 0.5)])]
    band_ = [frustum(4, 1.12, 7.5, 1.0, 7.85, a0=math.pi / 4)]
    return [("Post", WOOD, post + bar), ("Shirt", (96, 140, 70), shirt + sleeves), ("Patches", (176, 92, 56), patches),
            ("Rope", TWINE, rope), ("Straw", STRAW, straw), ("Pumpkin", PUMPKIN, a), ("Pumpkin", PUMPKIN_DARK, b),
            ("Stem", STEM, stem), ("Face", GLOW, fc), ("Hat", (70, 46, 74), hat + hat_brim), ("HatBand", (232, 102, 36), band_)]


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

def leaf_wedge(p, n, yaw, L, w, t=0.45):
    """A thick pointed leaf: a diamond of length L and width w lying on a surface at p with
    normal n, its top face smaller so it reads as a chunky wedge. Sunk a little into p."""
    n = np.asarray(n, float) / np.linalg.norm(n)
    u = np.cross(n, (math.cos(yaw), 0, math.sin(yaw)))
    if np.linalg.norm(u) < 1e-3:
        u = np.cross(n, (1, 0, 0))
    u /= np.linalg.norm(u)
    v = np.cross(n, u)
    base = np.asarray(p, float) - n * 0.15
    flat = [u * L / 2, v * w / 2, -u * L / 2, -v * w / 2]
    return np.array([base + f for f in flat] + [base + n * t + f * 0.55 for f in flat])


def leaves(rng, R, H, n_on, n_ground=0, ground_r=0.0):
    """A dome of leaves: a mound (half ellipsoid, R across, H tall) covered in thick leaf
    wedges resting on its surface, plus a few wedges lying on the ground round it. Mixed red,
    yellow and brown."""
    cols = {c: [] for c in LEAF_COLS}
    dome = blob(rng, (0, 0, 0), R, 20, squash=(1.0, H / R, 1.0), jitter=0.04)
    dome = np.concatenate([dome[dome[:, 1] > -0.05], np.array(ring(12, R, 0.0))])
    cols[LEAF_COLS[0]].append(dome)
    for i in range(n_on):
        # spread evenly over the upper dome (golden angle), not too near the rim
        k = (i + 0.5) / n_on
        el = math.asin(0.15 + 0.85 * (1 - k))  # high to low
        az = i * 2.39996 + rng.uniform(-0.2, 0.2)
        x, y, z = math.cos(el) * math.cos(az) * R, math.sin(el) * H, math.cos(el) * math.sin(az) * R
        nrm = (x / R ** 2, y / H ** 2, z / R ** 2)
        L = rng.uniform(1.5, 2.1)
        cols[LEAF_COLS[i % 3]].append(leaf_wedge((x, y, z), nrm, rng.uniform(0, 6.28), L, L * 0.62))
    for i in range(n_ground):
        az = 2 * math.pi * i / n_ground + rng.uniform(-0.3, 0.3)
        d = ground_r * rng.uniform(0.85, 1.1)
        L = rng.uniform(1.5, 2.0)
        cols[LEAF_COLS[(i + 1) % 3]].append(leaf_wedge((math.cos(az) * d, 0.15, math.sin(az) * d), (0, 1, 0), rng.uniform(0, 6.28), L, L * 0.62))
    return [("Leaves", c, hs) for c, hs in cols.items() if hs]


def leaf_pile(rng):
    """A raked dome of autumn leaves (about 7 across, 3 tall) in red, yellow and brown."""
    return leaves(rng, 3.0, 2.6, 26)


def leaf_scatter(rng):
    """A low heap of leaves with a ring of fallen ones round it (about 7 across)."""
    return leaves(rng, 1.6, 1.1, 9, 6, 2.8)


ITEMS = [  # name, builder, seed, label
    ("SpookyTree", spooky_tree, 3, "Spooky tree"),
    ("JackOLantern", jack_o_lantern, 1, "Jack-o'-lantern"),
    ("JackOLanternSmall", jack_o_lantern_small, 2, "Small jack"),
    ("Pumpkin", pumpkin, 1, "Pumpkin"),
    ("PumpkinPile", pumpkin_pile, 2, "Pumpkins"),
    ("LeafPile", leaf_pile, 4, "Leaf pile"),
    ("LeafScatter", leaf_scatter, 5, "Leaves"),
    ("LanternTree", lantern_tree, 2, "Lantern tree"),
    ("Scarecrow", scarecrow, 1, "Scarecrow"),
    ("HayBale", hay_bale, 1, "Hay bale"),
    ("HayStack", hay_stack, 2, "Hay stack"),
]

FLOOR = [(112, 82, 142), (102, 74, 130)]  # the Halloween world's purple floor (QM's recolour, Oct 15)


def main():
    built, sizes = build_set(OUT, ITEMS)
    rows = [lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[:3]], FLOOR, yaw=0),
            lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[3:7]], FLOOR, ppst=36, yaw=0)]
    stack(rows, os.path.join(OUT, "halloween_lineup.png"), "Halloween props (1x; figure is 5 studs)")
    new = ["LanternTree", "Scarecrow", "HayBale", "HayStack"]
    labels = dict((n, l) for n, _, _, l in ITEMS)
    row = lineup_row(built, sizes, [(n, labels[n]) for n in new], FLOOR, ppst=34, yaw=0)
    stack([row], os.path.join(OUT, "harvest_lineup.png"), "Halloween harvest props (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
