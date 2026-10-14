"""World 3 biome 3, Candyland props (QM, Oct 14): giant lollipop, candy cane, cupcake,
gingerbread house, donut arch, ice cream cone, chocolate bar, chocolate rocks, wrapped
candy, gumdrops. Same style as the other prop sets (faceted convex pieces, flat shaded,
studded, one colour per piece). Colours are my picks.

Run: python3 tools/w3_candyland.py
Writes design/w3_candyland/<Name>.obj, pieces/<Name>_<i>.obj + colours.txt, sizes.txt and
candyland_lineup.png.
"""

import math
import os

import numpy as np

from w3props import (HERE, blob, prism, ball, disc, tube, torus, rot_y, rot_x, rot_z, move,
                     build_set, lineup_row, stack)
from crimson_meshes import slab
from tomb_meshes import ring, frustum, band
from rock_meshes import chunk

OUT = os.path.join(HERE, "..", "design", "w3_candyland")
PINK = (255, 120, 180)
PINK_LIGHT = (255, 184, 214)
MINT = (100, 226, 186)
LEMON = (255, 226, 84)
GRAPE = (170, 110, 240)
CHERRY = (240, 40, 70)
ORANGE = (255, 150, 50)
BLUE = (90, 170, 255)
WHITE = (252, 252, 252)
CHOC = (112, 62, 38)
CHOC_LIGHT = (146, 88, 54)
GINGER = (200, 124, 62)
GINGER_DARK = (170, 98, 46)
WAFER = (232, 180, 100)
WAFER_DARK = (206, 150, 76)
STICK = (250, 246, 236)


def sprinkles(rng, centre, r, y, n, cols, lift=0.0):
    """Little candy rods scattered on a dome/plate; returns {colour: [hulls]}."""
    out = {c: [] for c in cols}
    for i in range(n):
        a = rng.uniform(0, 2 * math.pi)
        d = r * math.sqrt(rng.uniform(0.05, 1.0))
        p = np.array((centre[0] + math.cos(a) * d, y(d), centre[2] + math.sin(a) * d))
        b = rng.uniform(0, math.pi)
        q = p + (math.cos(b) * 0.35, 0.05, math.sin(b) * 0.35)
        out[cols[i % len(cols)]].append(prism(rng, p - (q - p), q, 0.12, 0.12, 4, 0.0))
    return out


def lollipop(rng):
    """A giant swirl lollipop (about 15 tall): white stick, a round candy of alternating
    pink and white wedges with a raised rim."""
    r, t, cy = 4.4, 1.2, 10.6
    stick = [prism(rng, (0, -0.4, 0.2), (0, cy, 0.2), 0.42, 0.4, 8, 0.0)]
    wedges = [[], []]
    n = 12
    for i in range(n):
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        # a pie wedge (twisted ones overlapped their neighbours and flickered)
        pts = [(0, cy, -t / 2), (0, cy, t / 2)]
        for k in range(4):
            a = a0 + (a1 - a0) * k / 3
            for z in (-t / 2, t / 2):
                pts.append((math.cos(a) * r, cy + math.sin(a) * r, z))
        wedges[i % 2].append(np.array(pts))
    rim = torus((0, cy, 0), r, 0.45, 16, 6, axis="z")
    bow = [np.array([(0, cy - r + 0.2, 0), (-1.6, cy - r - 0.8, -0.3), (-1.6, cy - r + 0.6, -0.3), (-1.6, cy - r - 0.8, 0.3), (-1.6, cy - r + 0.6, 0.3)]),
           np.array([(0, cy - r + 0.2, 0), (1.6, cy - r - 0.8, -0.3), (1.6, cy - r + 0.6, -0.3), (1.6, cy - r - 0.8, 0.3), (1.6, cy - r + 0.6, 0.3)])]
    return [("Stick", STICK, stick), ("Swirl", PINK, wedges[0]), ("Swirl", WHITE, wedges[1]), ("Rim", (255, 90, 160), rim),
            ("Bow", MINT, bow)]


def candy_cane(rng):
    """A giant candy cane (about 14 tall) stuck in the ground, red and white stripes."""
    path = [(0, -0.6, 0)]
    n_up = 10
    for i in range(1, n_up + 1):
        path.append((0, 10.5 * i / n_up, 0))
    for i in range(1, 8):
        a = math.pi * i / 7
        path.append((-1.9 + 1.9 * math.cos(a), 10.5 + 1.9 * math.sin(a), 0))
    path.append((-3.8, 9.4, 0))
    segs = tube(rng, path, 0.75, 0.75, 10)
    tip = [ball(path[-1], 0.75, 12)]
    return [("Cane", WHITE, segs[0::2] + tip), ("Stripes", CHERRY, segs[1::2])]


def cupcake(rng):
    """A giant cupcake (about 11 tall): ridged pink wrapper, swirled frosting in three
    tiers, sprinkles and a cherry with a stem."""
    wrapper = []
    for i in range(14):
        a0, a1 = 2 * math.pi * i / 14, 2 * math.pi * (i + 1) / 14
        pts = []
        for a in (a0, (a0 + a1) / 2, a1):
            out = 1.0 if a == (a0 + a1) / 2 else 0.94
            pts += [(math.cos(a) * 3.2 * out, 0, math.sin(a) * 3.2 * out), (math.cos(a) * 4.0 * out, 4.2, math.sin(a) * 4.0 * out)]
        pts += [(0, 0, 0), (0, 4.2, 0)]
        wrapper.append(np.array(pts))
    cake = [frustum(14, 4.0, 4.0, 3.9, 4.8)]
    frost = (torus((0, 5.3, 0), 3.4, 1.1, 14, 7) + torus((0, 6.9, 0), 2.4, 0.95, 12, 7) + torus((0, 8.3, 0), 1.4, 0.8, 10, 6)
             + [ball((0, 9.2, 0), 1.1, 14), ball((0, 6.2, 0), 2.8, 16), ball((0, 7.6, 0), 1.8, 12)])
    cherry = [ball((0.2, 10.6, 0), 0.9, 14)]
    stem = tube(rng, [(0.3, 11.2, 0), (0.6, 12.2, 0.1), (1.3, 12.8, 0.2)], 0.12, 0.1, 5)
    sp = sprinkles(rng, (0, 0, 0), 3.6, lambda d: 5.3 + 1.1 if d > 2.9 else 6.9 + 0.9 if d > 1.9 else 8.4 + 0.8, 26, [LEMON, MINT, BLUE, GRAPE])
    return ([("Wrapper", PINK, wrapper[0::2]), ("Wrapper", (240, 96, 160), wrapper[1::2]), ("Cake", CHOC_LIGHT, cake),
             ("Frosting", PINK_LIGHT, frost), ("Cherry", CHERRY, cherry), ("Stem", (90, 160, 60), stem)]
            + [("Sprinkles", c, h) for c, h in sp.items()])


def gingerbread_house(rng):
    """A gingerbread house (about 12 wide, 13 tall): walls, a pitched roof with white icing
    edges, a door, two windows, gumdrops along the ridge and candy cane corners."""
    w, d, h = 10.0, 8.0, 6.0
    walls = [slab(rng, -w / 2, 0, -d / 2, w / 2, h, d / 2, 0.2, 0.0)]
    gables = [np.array([(-w / 2 + 0.1, h, z), (w / 2 - 0.1, h, z), (0, h + 4.2, z)] + [(-w / 2 + 0.1, h, z2), (w / 2 - 0.1, h, z2), (0, h + 4.2, z2)])
              for z, z2 in ((-d / 2, d / 2),)]
    roof = []
    for s in (-1, 1):
        roof.append(np.array([(s * (w / 2 + 1.0), h - 0.7, z) for z in (-d / 2 - 1.0, d / 2 + 1.0)]
                             + [(0, h + 4.6, z) for z in (-d / 2 - 1.0, d / 2 + 1.0)]
                             + [(s * (w / 2 + 1.0), h - 0.1, z) for z in (-d / 2 - 1.0, d / 2 + 1.0)]
                             + [(s * 0.3, h + 5.1, z) for z in (-d / 2 - 1.0, d / 2 + 1.0)]))
    icing = []
    for s in (-1, 1):  # drips along the eaves and the gable edges
        icing.append(np.array([(s * (w / 2 + 1.15), y, z) for y in (h - 0.9, h - 0.05) for z in (-d / 2 - 1.15, d / 2 + 1.15)]
                              + [(s * (w / 2 + 0.6), y, z) for y in (h - 0.9, h + 0.3) for z in (-d / 2 - 1.15, d / 2 + 1.15)]))
        for zz in (-d / 2 - 1.15, d / 2 + 0.85):
            p, q = np.array((s * (w / 2 + 1.1), h - 0.3, zz)), np.array((0, h + 5.0, zz))
            icing.append(np.array([p, q, p + (0, 0.6, 0), q + (0, 0.6, 0), p + (0, 0, 0.3), q + (0, 0, 0.3), p + (0, 0.6, 0.3), q + (0, 0.6, 0.3)]))
    door = [slab(rng, -1.3, 0, -d / 2 - 0.2, 1.3, 3.8, -d / 2 + 0.1, 0.1, 0.0)]
    knob = [ball((0.8, 1.9, -d / 2 - 0.3), 0.25, 8)]
    windows = [slab(rng, x - 1.0, 2.6, -d / 2 - 0.15, x + 1.0, 4.6, -d / 2 + 0.1, 0.05, 0.0) for x in (-3.3, 3.3)]
    frames = [slab(rng, x - 1.25, 2.35, -d / 2 - 0.1, x + 1.25, 4.85, -d / 2 + 0.05, 0.05, 0.0) for x in (-3.3, 3.3)]
    drops = {CHERRY: [], MINT: [], LEMON: [], GRAPE: []}
    for i, z in enumerate(np.linspace(-d / 2 - 0.4, d / 2 + 0.4, 5)):
        drops[list(drops)[i % 4]].append(np.array(ring(10, 0.75, h + 4.8) + ring(10, 0.5, h + 5.6) + [(0, h + 6.0, z * 0 + 0)]) + (0, 0, z))
    canes = []
    stripes = []
    for x in (-w / 2 - 0.4, w / 2 + 0.4):
        segs = tube(rng, [(x, 0, -d / 2 - 0.4)] + [(x, 5.0 * i / 6, -d / 2 - 0.4) for i in range(1, 7)] + [(x + np.sign(x) * 0.6, 5.6, -d / 2 - 0.4), (x + np.sign(x) * 1.2, 5.0, -d / 2 - 0.4)], 0.35, 0.35, 8)
        canes += segs[0::2]
        stripes += segs[1::2]
    return ([("Walls", GINGER, walls + gables), ("Roof", GINGER_DARK, roof), ("Icing", WHITE, icing + frames + canes),
             ("Door", CHOC, door), ("Knob", LEMON, knob), ("Windows", (120, 210, 255), windows), ("Stripes", CHERRY, stripes)]
            + [("Gumdrops", c, hs) for c, hs in drops.items()])


def donut_arch(rng):
    """A giant donut standing on its edge as an arch (about 14 tall), half sunk in the
    ground: dough ring, pink icing on the front and back faces, sprinkles."""
    R, r = 5.6, 2.3
    cy = R + r - 1.6
    dough = torus((0, cy, 0), R, r, 20, 8, axis="z")
    icing = []
    for i in range(20):
        a0, a1 = 2 * math.pi * i / 20, 2 * math.pi * (i + 1) / 20
        pts = []
        for a in (a0, a1):
            for b in np.linspace(math.pi * 0.25, math.pi * 0.75, 4):
                for side in (-1, 1):
                    zz = side * (r + 0.15) * math.sin(b)
                    pts.append((math.cos(a) * (R + (r + 0.15) * math.cos(b)), cy + math.sin(a) * (R + (r + 0.15) * math.cos(b)), zz))
        icing.append(np.array(pts))
    sp = {LEMON: [], MINT: [], BLUE: [], WHITE: []}
    cols = list(sp)
    for i in range(36):
        a = rng.uniform(0, 2 * math.pi)
        b = rng.uniform(-0.5, 0.5)
        side = -1 if i % 2 else 1
        rr = R + (r + 0.2) * math.sin(b)
        p = np.array((math.cos(a) * rr, cy + math.sin(a) * rr, side * (r + 0.2) * math.cos(b)))
        if p[1] < 0.3:
            continue
        t = rng.uniform(0, math.pi)
        q = p + (math.cos(t) * 0.4, math.sin(t) * 0.4, 0)
        sp[cols[i % 4]].append(prism(rng, p - (q - p) * 0.5, q, 0.13, 0.13, 4, 0.0))
    return [("Dough", WAFER, dough), ("Icing", PINK, icing)] + [("Sprinkles", c, h) for c, h in sp.items() if h]


def ice_cream(rng):
    """A giant ice cream cone (about 14 tall) on its waffle cone, three scoops (mint,
    strawberry, vanilla) with drips, and a wafer stick."""
    cone = [frustum(12, 0.5, -0.4, 2.6, 6.5)]
    grid = [band(cone[0], y, y + 0.3, 0.05) for y in (1.4, 3.0, 4.6)]
    lip = [frustum(12, 2.9, 6.2, 3.0, 7.0)]
    scoops = [blob(rng, (0, 8.0, 0), 2.8, 18, squash=(1.0, 0.85, 1.0), jitter=0.05),
              blob(rng, (0.2, 10.4, 0.1), 2.4, 16, squash=(1.0, 0.85, 1.0), jitter=0.05),
              blob(rng, (0.0, 12.4, 0.0), 2.0, 14, squash=(1.0, 0.9, 1.0), jitter=0.05)]
    drips = [[ball((math.cos(a) * 2.7, 7.0 - k, math.sin(a) * 2.7), 0.55 - 0.1 * k, 8) for a, k in ((-1.9, 0.3), (-0.9, 0.7), (2.4, 0.2))]]
    wafer = [slab(rng, 0.8, 11.5, -0.4, 1.6, 15.0, 0.4, 0.05, 0.0)]
    rot = lambda p: rot_z(p, -0.25, (0.8, 11.5, 0))  # noqa: E731
    cherry = [ball((-0.4, 14.6, 0), 0.8, 12)]
    return [("Cone", WAFER, cone + lip), ("Grid", WAFER_DARK, grid), ("Scoop", MINT, scoops[:1] + drips[0]), ("Scoop", PINK, scoops[1:2]),
            ("Scoop", (255, 244, 214), scoops[2:]), ("Wafer", WAFER_DARK, move(wafer, rot)), ("Cherry", CHERRY, cherry)]


def chocolate_bar(rng):
    """A giant chocolate bar (about 10 x 14) stuck upright in the ground, half unwrapped:
    a grid of squares and a red foil wrapper on the lower half."""
    back = [slab(rng, -5, -0.6, 0.0, 5, 13.0, 1.2, 0.15, 0.0)]
    squares = []
    for i in range(3):
        for j in range(4):
            x0 = -4.6 + i * 3.1
            y0 = 6.2 + j * 1.7 if j < 4 else 0
            if y0 > 12.4:
                continue
            squares.append(slab(rng, x0, y0, -0.6, x0 + 2.9, y0 + 1.5, 0.1, 0.35, 0.0))
    wrapper = [slab(rng, -5.3, -0.6, -0.9, 5.3, 6.0, 1.5, 0.1, 0.0)]
    tear = [np.array([(x, 6.0 + (0.8 if i % 2 else 0), z) for i, x in enumerate(np.linspace(-5.3, 5.3, 7)) for z in (-0.9, 1.5)]
                     + [(x, 5.6, z) for x in (-5.3, 5.3) for z in (-0.9, 1.5)])]
    label = [slab(rng, -3.4, 1.6, -1.05, 3.4, 4.4, -0.8, 0.1, 0.0)]
    lean = lambda p: rot_x(rot_y(p, 0.35), -0.12)  # noqa: E731
    return [("Chocolate", CHOC, move(back, lean)), ("Squares", CHOC_LIGHT, move(squares, lean)),
            ("Wrapper", CHERRY, move(wrapper + tear, lean)), ("Label", LEMON, move(label, lean))]


def chocolate_rocks(rng):
    """A pile of chocolate boulders (about 12 across) in milk and dark chocolate."""
    a = [chunk(rng, x, z, r, h, 7, bevel=0.2) for x, z, r, h in ((0, 0, 3.6, 4.4), (4.2, 1.2, 2.4, 2.6), (-3.8, 1.6, 2.6, 2.2))]
    b = [chunk(rng, x, z, r, h, 6, bevel=0.2) for x, z, r, h in ((2.0, -3.0, 1.8, 1.6), (-2.4, -2.8, 1.5, 1.2), (5.4, -2.0, 1.0, 0.9))]
    return [("Chocolate", CHOC_LIGHT, a), ("Dark", CHOC, b)]


def wrapped_candy(rng):
    """A giant wrapped sweet (about 9 long) lying on the ground, twisted ends."""
    body = [blob(rng, (0, 1.9, 0), 1.9, 18, squash=(1.35, 1.0, 1.0), jitter=0.02)]
    stripes = [band(np.array(rot_z(body[0], math.pi / 2)), y - 0.25, y + 0.25, 0.04) for y in (-1.2, 0.0, 1.2)]
    stripes = [rot_z(s, -math.pi / 2) for s in stripes]
    ends = []
    for s in (-1, 1):
        knot = np.array((s * 2.6, 1.9, 0))
        ends.append(np.array([knot + (0, dy, dz) for dy in (-0.4, 0.4) for dz in (-0.4, 0.4)] + [knot + (s * 0.3, 0, 0)]))
        fan = [knot + (s * 0.2, 0, 0)] + [knot + (s * 1.9, math.cos(a) * 1.5, math.sin(a) * 1.5) for a in np.linspace(0, 2 * math.pi, 8, endpoint=False)]
        ends.append(np.array(fan))
    yaw = lambda p: rot_y(p, 0.3)  # noqa: E731
    return [("Candy", BLUE, move(body, yaw)), ("Stripes", WHITE, move(stripes, yaw)), ("Wrapper", (150, 210, 255), move(ends, yaw))]


def gumdrops(rng):
    """A cluster of gumdrops (about 6 across) in four colours."""
    out = []
    for (x, z, s), col in zip(((0, 0, 1.6), (2.3, 1.1, 1.1), (-2.1, 0.9, 1.2), (0.6, -2.2, 0.9), (-1.6, -1.8, 0.8)),
                              (CHERRY, MINT, LEMON, GRAPE, ORANGE)):
        dome = np.array(ring(10, s, 0) + ring(10, s * 0.92, s * 0.8) + ring(10, s * 0.6, s * 1.4) + [(0, s * 1.6, 0)]) + (x, 0, z)
        out.append(("Gumdrop", col, [dome]))
    return out


ITEMS = [  # name, builder, seed, label
    ("GingerbreadHouse", gingerbread_house, 1, "Gingerbread house"),
    ("DonutArch", donut_arch, 2, "Donut arch"),
    ("Lollipop", lollipop, 1, "Lollipop"),
    ("CandyCane", candy_cane, 1, "Candy cane"),
    ("IceCream", ice_cream, 1, "Ice cream"),
    ("ChocolateBar", chocolate_bar, 1, "Chocolate bar"),
    ("Cupcake", cupcake, 3, "Cupcake"),
    ("ChocolateRocks", chocolate_rocks, 2, "Chocolate rocks"),
    ("WrappedCandy", wrapped_candy, 1, "Wrapped candy"),
    ("Gumdrops", gumdrops, 1, "Gumdrops"),
]

FLOOR = [(252, 196, 222), (246, 182, 212)]


def main():
    built, sizes = build_set(OUT, ITEMS)
    rows = [lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[:5]], FLOOR),
            lineup_row(built, sizes, [(n, l) for n, _, _, l in ITEMS[5:]], FLOOR, ppst=30)]
    stack(rows, os.path.join(OUT, "candyland_lineup.png"), "Candyland props (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
