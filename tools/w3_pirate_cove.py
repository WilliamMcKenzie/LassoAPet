"""World 3 biome 1, Pirate Cove props (QM, Oct 14). Adds to the pirate set (palms, crates,
barrels, ship): treasure chest, treasure pile, cannon, cannonball pile, anchor, skull rock,
shipwreck, rowboat and a little dock. Same style: faceted convex pieces, flat shaded,
studded, one colour per piece. Colours are my picks.

Run: python3 tools/w3_pirate_cove.py
Writes design/w3_pirate_cove/<Name>.obj, pieces/<Name>_<i>.obj + colours.txt, sizes.txt and
pirate_cove_lineup.png.
"""

import math
import os

import numpy as np

from w3props import (HERE, blob, prism, ball, disc, tube, torus, rot_y, rot_x, rot_z, move,
                     build_set, lineup_row, stack)
from crimson_meshes import slab
from tomb_meshes import ring, frustum, band
from rock_meshes import chunk

OUT = os.path.join(HERE, "..", "design", "w3_pirate_cove")
WOOD = (176, 112, 58)
WOOD_DARK = (122, 74, 38)
PLANK = (214, 162, 100)
GOLD = (252, 222, 81)
GOLD_DARK = (232, 182, 40)
RUBY = (240, 52, 80)
EMERALD = (40, 214, 120)
SAPPHIRE = (60, 140, 255)
IRON = (74, 82, 100)
IRON_DARK = (52, 56, 70)
BONE = (238, 228, 200)
SOCKET = (46, 36, 44)
ROCK = (132, 128, 140)
ROCK_DARK = (104, 100, 114)
ROPE = (226, 198, 140)
SAIL = (240, 232, 210)
RED = (220, 50, 46)
WHITE = (250, 250, 250)


# ---------------------------------------------------------------- treasure

def coins(rng, c, r, h, n=0):
    """A heap of gold: a squat lumpy mound."""
    return blob(rng, (c[0], c[1], c[2]), r, 18, squash=(1.0, h / r, 1.0), jitter=0.08)


def treasure_chest(rng):
    """An open chest (about 6 wide): wooden box with gold bands and corners, the lid
    swung back, gold coins heaped in it and three gems on top."""
    w, d, h = 5.6, 3.6, 3.0
    box = [slab(rng, -w / 2, 0, -d / 2, w / 2, h, d / 2, 0.15, 0.0)]
    # lid: half a barrel lying along x, hinged at the back edge, swung back ~110 degrees
    lid = []
    for i in range(7):
        a = math.pi * i / 6
        for x in (-w / 2, w / 2):
            lid.append((x, math.sin(a) * d / 2 * 0.9, -math.cos(a) * d / 2))
    lid = np.array(lid)
    hinge = np.array((0, 0, d / 2))
    lid = rot_x(lid - hinge, 1.95) + hinge + (0, h, 0)
    bands, corners = [], []
    for x in (-w / 2 + 1.0, w / 2 - 1.0):
        bands.append(slab(rng, x - 0.3, -0.02, -d / 2 - 0.1, x + 0.3, h + 0.02, d / 2 + 0.1, 0.0, 0.0))
        arc = lid.copy()
        arc[:, 0] = np.where(arc[:, 0] < 0, x - 0.3, x + 0.3)
        c = arc.mean(0)
        bands.append(c + (arc - c) * (1.06, 1.06, 1.06) * np.array((1, 1, 1)) + np.array((0, 0, 0)))
    lock = [slab(rng, -0.5, h - 1.1, -d / 2 - 0.25, 0.5, h - 0.1, -d / 2 + 0.05, 0.05, 0.0)]
    pile = [coins(rng, (0, h - 0.1, 0), 2.3, 1.3), coins(rng, (1.2, h + 0.2, -0.3), 1.2, 0.9),
            coins(rng, (-1.4, h + 0.1, 0.4), 1.1, 0.8)]
    pile = [p[p[:, 1] > h - 0.3] if len(p[p[:, 1] > h - 0.3]) > 4 else p for p in pile]
    pile = [np.clip(p, (-w / 2 + 0.25, -10, -d / 2 + 0.25), (w / 2 - 0.25, 10, d / 2 - 0.25)) for p in pile]
    gems = [("Ruby", RUBY, [ball((-0.6, h + 1.35, -0.5), 0.45, 8)]),
            ("Emerald", EMERALD, [ball((1.4, h + 1.0, -0.6), 0.4, 8)]),
            ("Sapphire", SAPPHIRE, [ball((-1.7, h + 0.85, 0.2), 0.38, 8)])]
    return [("Chest", WOOD, box), ("Lid", WOOD_DARK, [lid]), ("Bands", GOLD_DARK, bands + lock),
            ("Gold", GOLD, pile)] + gems


def treasure_pile(rng):
    """A heap of gold coins with a goblet and a crown (about 6 across)."""
    heap = [coins(rng, (0, 0, 0), 3.0, 1.6), coins(rng, (1.6, 0, 1.0), 1.8, 1.1), coins(rng, (-1.8, 0, 0.6), 1.6, 0.9)]
    goblet = [frustum(10, 0.55, 1.2, 0.95, 3.4, c=(-0.8, 0.2)), frustum(10, 0.18, 0.6, 0.18, 1.4, c=(-0.8, 0.2)),
              frustum(10, 0.7, 0.4, 0.5, 0.75, c=(-0.8, 0.2))]
    crown = []
    cx, cy, cz = 1.4, 1.2, -0.8
    crown.append(frustum(10, 0.95, cy, 1.05, cy + 0.7, c=(cx, cz)))
    for i in range(5):
        a = 2 * math.pi * i / 5
        p = np.array((cx + math.cos(a) * 0.95, cy + 0.6, cz + math.sin(a) * 0.95))
        crown.append(np.array([p + (dx, 0, dz) for dx in (-0.25, 0.25) for dz in (-0.25, 0.25)] + [p + (0, 0.7, 0)]))
    return [("Gold", GOLD, heap), ("Goblet", GOLD_DARK, goblet), ("Crown", GOLD_DARK, crown)]


# ---------------------------------------------------------------- cannon

def cannon(rng):
    """A ship's cannon (about 7 long) on a wooden carriage with four iron-rimmed wheels."""
    car = [slab(rng, -1.5, 0.9, -2.6, -0.9, 2.4, 2.0, 0.08, 0.0), slab(rng, 0.9, 0.9, -2.6, 1.5, 2.4, 2.0, 0.08, 0.0),
           slab(rng, -1.0, 0.9, -1.0, 1.0, 1.5, 1.6, 0.05, 0.0)]
    wheels, hubs = [], []
    for x in (-1.75, 1.75):
        for z in (-1.8, 1.4):
            wheels.append(disc((x, 0.95, z), 0.95, 0.4, 12, axis="x"))
            hubs.append(disc((x + 0.18 * np.sign(x), 0.95, z), 0.35, 0.3, 8, axis="x"))
    # barrel: breech knob, body tapering to a flared muzzle, angled up a little
    tilt = -0.12
    body = [prism(rng, (0, 0, 2.4), (0, 0, -1.0), 1.05, 0.85, 12, 0.0),
            prism(rng, (0, 0, -0.9), (0, 0, -4.3), 0.85, 0.66, 12, 0.0)]
    rims = [frustum(12, 0.95, 0, 0.95, 0.5) @ np.array([[1, 0, 0], [0, 0, 1], [0, 1, 0]]) + (0, 0, 0.6),
            frustum(12, 0.82, 0, 0.82, 0.6) @ np.array([[1, 0, 0], [0, 0, 1], [0, 1, 0]]) + (0, 0, -4.9),
            ball((0, 0, 2.85), 0.5, 10)]
    trunnion = [prism(rng, (-1.2, 0, 0.4), (1.2, 0, 0.4), 0.3, 0.3, 8, 0.0)]
    place = lambda pts: rot_x(pts, tilt) + (0, 2.75, 0)  # noqa: E731
    muzzle = [disc((0, 0, -4.95), 0.5, 0.1, 10, axis="z")]
    return [("Carriage", WOOD, car), ("Wheels", WOOD_DARK, wheels), ("Hubs", IRON_DARK, hubs),
            ("Barrel", IRON, move(body + trunnion, place)), ("Rims", IRON_DARK, move(rims, place)),
            ("Bore", SOCKET, move(muzzle, place))]


def cannonballs(rng):
    """A pyramid of cannonballs (about 3 across): 4 below, 1 on top, 1 rolled away."""
    r = 0.7
    balls = [ball((x, r, z), r, 22) for x in (-r, r) for z in (-r, r)]
    balls.append(ball((0, r + r * 1.41, 0), r, 22))
    balls.append(ball((2.4, r, -0.9), r, 22))
    return [("Balls", IRON, balls)]


# ---------------------------------------------------------------- anchor

def anchor(rng):
    """A big anchor (about 11 tall) planted in the sand, leaning: shank, ring, wooden stock,
    curved arms with spade flukes, rope coiled round the ring."""
    shank = [prism(rng, (0, -0.6, 0), (0, 9.4, 0), 0.55, 0.5, 8, 0.0)]
    ring_ = torus((0, 10.3, 0), 0.9, 0.24, 10, 6, axis="z")
    stock = [slab(rng, -3.2, 8.4, -0.45, 3.2, 9.2, 0.45, 0.15, 0.0)]
    stock_ends = [ball((s * 3.35, 8.8, 0), 0.5, 8) for s in (-1, 1)]
    arms = torus((0, 3.4, 0), 3.4, 0.45, 8, 7, axis="z", arc=(math.pi * 1.06, math.pi * 1.94))
    flukes = []
    for s in (-1, 1):
        a = math.pi * (1.06 if s < 0 else 1.94)
        tip = np.array((math.cos(a) * 3.4, 3.4 + math.sin(a) * 3.4, 0))
        out = np.array((s * 1, 0.0, 0))
        flukes.append(np.array([tip + (0, 0, z) for z in (-0.3, 0.3)] + [tip + (s * 0.2, 1.9, z) for z in (-0.3, 0.3)]
                               + [tip + (s * 1.25, 0.2, z) for z in (-0.25, 0.25)] + [tip + (-s * 0.6, 0.5, z) for z in (-0.25, 0.25)]))
    crown = [ball((0, 0.1, 0), 0.75, 10)]
    rope = torus((0, 9.2, 0), 0.75, 0.22, 10, 5, axis="y")
    lean = lambda p: rot_z(p, 0.28) + (0, 0.9, 0)  # noqa: E731
    return [("Anchor", IRON, move(shank + ring_ + arms + flukes + crown, lean)), ("Stock", WOOD, move(stock + stock_ends, lean)),
            ("Rope", ROPE, move(rope, lean))]


# ---------------------------------------------------------------- skull rock

def skull_rock(rng):
    """A big skull-shaped rock (about 18 tall) on a ring of grey boulders: bone-pale dome,
    dark eye sockets and nose, square teeth, cheekbones."""
    base = [chunk(rng, x, z, r, h, 7) for x, z, r, h in
            ((-6.5, 1.0, 3.6, 3.2), (6.0, 0.5, 3.4, 2.8), (0.5, 3.5, 4.2, 3.6), (-3.0, -3.8, 2.6, 2.0), (4.0, -3.6, 2.4, 1.8))]
    base_b = [chunk(rng, x, z, r, h, 6) for x, z, r, h in ((-8.8, -1.5, 1.8, 1.4), (8.6, -1.4, 1.6, 1.2), (-2.0, 6.0, 2.8, 2.6))]
    dome = [blob(rng, (0, 11.0, 0.4), 7.4, 26, squash=(1.0, 0.95, 0.95), jitter=0.04)]
    face = [blob(rng, (0, 6.0, -1.0), 5.2, 20, squash=(1.05, 0.9, 0.95), jitter=0.04),
            blob(rng, (0, 3.2, -1.6), 3.6, 16, squash=(1.1, 0.7, 0.9), jitter=0.05)]
    cheeks = [blob(rng, (s * 3.6, 6.8, -4.6), 1.6, 10, squash=(1.0, 0.7, 0.8), jitter=0.05) for s in (-1, 1)]
    sockets = [blob(rng, (s * 2.6, 9.0, -6.2), 1.9, 14, squash=(1.0, 1.1, 0.45), jitter=0.03) for s in (-1, 1)]
    nose = [np.array([(0, 7.6, -6.7), (-0.9, 5.6, -5.8), (0.9, 5.6, -5.8), (0, 7.4, -5.4), (-0.7, 5.6, -5.2), (0.7, 5.6, -5.2)])]
    teeth = [slab(rng, x - 0.45, 2.4, -5.25, x + 0.45, 4.0, -4.3, 0.1, 0.0) for x in (-1.5, -0.5, 0.5, 1.5)]
    return [("Rocks", ROCK, base), ("Rocks", ROCK_DARK, base_b), ("Skull", BONE, dome + face), ("Cheeks", (226, 212, 180), cheeks),
            ("Sockets", SOCKET, sockets + nose), ("Teeth", WHITE, teeth)]


# ---------------------------------------------------------------- boats

def hull(stations, deck_y):
    pts = []
    for z, wd, wb, yb in stations:
        for s in (-1, 1):
            pts += [(s * wb, yb, z), (s * wd, deck_y, z)]
    return np.array(pts)


def width_at(stations, deck_y, z, y):
    zs = [s[0] for s in stations]
    wd = np.interp(z, zs, [s[1] for s in stations])
    wb = np.interp(z, zs, [s[2] for s in stations])
    yb = np.interp(z, zs, [s[3] for s in stations])
    return wb + (wd - wb) * (y - yb) / (deck_y - yb)


def shipwreck(rng):
    """The front half of a wrecked ship (about 26 long) run aground and keeled over: hull
    with gold stripe and holes, broken mainmast with a torn sail, snapped bowsprit."""
    st = [(-14.0, 0.4, 0.2, 4.0), (-10.0, 4.0, 1.2, 1.4), (-3.0, 6.0, 2.4, 0.0), (8.0, 6.0, 2.4, 0.0)]
    dy = 7.0
    # the hull is split in three chunks along z so the broken back end can be jagged
    h1 = hull(st[:3], dy)
    h2 = hull(st[2:], dy)
    jag = np.array([(s * w, y, 8.0 + j) for s, w, y, j in
                    ((-1, 6.0, 7.0, -1.2), (1, 6.0, 7.0, 0.0), (-1, 4.0, 3.5, 0.6), (1, 4.0, 3.5, -1.0), (-1, 2.4, 0.0, 0.0), (1, 2.4, 0.0, 0.8))])
    h2 = np.concatenate([h2[h2[:, 2] < 7.5], jag])
    stripe = band(np.concatenate([h1, h2]), 5.3, 6.0, 0.03)
    deck = []
    for z, wd, _, _ in st[1:]:
        for s in (-1, 1):
            deck += [(s * (wd - 0.1), dy - 0.05, z), (s * (wd - 0.1), dy + 0.15, z)]
    deck = np.array(deck + [(0, dy + 0.15, -13.6), (0, dy - 0.05, -13.6)])
    deck = deck[deck[:, 2] < 7.0]
    holes = []
    for z, y in ((-4.0, 3.0), (2.0, 4.5), (5.0, 2.2)):
        w = width_at(st, dy, z, y)
        holes.append(np.array([(w + dw, y + dy_, z + dz) for dw in (-0.5, 0.08) for dy_, dz in
                               ((-0.8, -0.9), (0.9, -0.5), (0.5, 0.9), (-0.9, 0.7))]))
    planks = [slab(rng, 4.8, 0, 6.0 + i * 1.4, 5.7, 0.35, 7.2 + i * 1.4, 0.05, 0.0) for i in range(2)]
    mast = [prism(rng, (0, dy - 1, 0.0), (0.3, 19.0, -0.2), 0.75, 0.55, 8, 0.0)]
    snap = [np.array([np.add((0.3, 19.0, -0.2), d) for d in ((-0.55, 0, 0), (0.55, 0, 0), (0, 0, -0.55), (0, 0, 0.55))]
                     + [(0.6, 20.6, -0.1), (-0.1, 19.8, 0.3)])]
    yard = [prism(rng, (-6.0, 15.0, 0.0), (6.0, 15.6, 0.0), 0.3, 0.3, 6, 0.0)]
    sail = []
    for x0, x1, drop in ((-5.6, -1.5, 5.2), (-1.5, 2.0, 3.6), (2.0, 5.6, 4.6)):
        # a chunky wedge, thick at the yard and thinner at the torn foot
        sail.append(np.array([(x0, 15.2, -1.0), (x1, 15.3, -1.0), (x0, 15.2 - drop, -1.9), (x1, 15.3 - drop * 0.8, -1.7),
                              (x0, 15.2, 0.3), (x1, 15.3, 0.3), (x0, 15.2 - drop, -1.3), (x1, 15.3 - drop * 0.8, -1.1)]))
    sprit = [prism(rng, (0, dy + 1, -12.5), (0, 10.0, -17.5), 0.45, 0.35, 6, 0.0)]
    tilt = lambda p: rot_z(p, 0.32) + (0, -1.4, 0)  # noqa: E731  keeled over, sunk into the sand
    turn = lambda p: rot_y(tilt(p), 0.5)  # noqa: E731
    return [("Hull", (132, 78, 42), move([h1, h2], turn)), ("Stripe", GOLD, move([stripe], turn)),
            ("Deck", PLANK, move([deck] + planks, turn)), ("Holes", SOCKET, move(holes, turn)),
            ("Mast", WOOD_DARK, move(mast + snap + yard + sprit, turn)), ("Sail", SAIL, move(sail, turn))]


def rowboat(rng):
    """A little rowboat (about 9 long) beached on the sand, two benches and crossed oars."""
    st = [(-5.2, 0.05, 0.05, 2.4), (-3.6, 1.3, 0.35, 0.6), (-1.0, 2.2, 0.85, 0.0), (2.6, 2.2, 0.9, 0.05), (4.4, 1.8, 0.8, 0.5)]  # pointed bow
    dy = 2.2
    outer = hull(st, dy)
    inner = []
    for z, wd, wb, yb in st[1:]:
        for s in (-1, 1):
            inner += [(s * (wd - 0.25), dy + 0.01, z), (s * (wb - 0.15), yb + 0.4, z)]
    inner = np.array(inner)
    rim = band(outer, dy - 0.35, dy, 0.04)
    benches = [slab(rng, -width_at(st, dy, z, 1.6) + 0.1, 1.45, z - 0.5, width_at(st, dy, z, 1.6) - 0.1, 1.75, z + 0.5, 0.05, 0.0)
               for z in (-1.4, 1.8)]
    oars = []
    for s, yaw in ((-1, 0.25), (1, -0.15)):
        a = np.array((s * 0.4, 2.0, -3.2))
        b = np.array((s * 1.1, 2.3, 3.0))
        oars.append(prism(rng, a, b, 0.14, 0.14, 6, 0.0))
        blade = b + (b - a) / np.linalg.norm(b - a) * 1.2
        oars.append(np.array([b + (dx, dy_, 0) for dx in (-0.4, 0.4) for dy_ in (-0.07, 0.07)] + [blade + (dx, dy_, 0) for dx in (-0.5, 0.5) for dy_ in (-0.07, 0.07)]))
    tilt = lambda p: rot_y(rot_z(p, 0.08), 1.25) + (0, -0.2, 0)  # noqa: E731  side on, so the pointed bow shows
    return [("Hull", WOOD, move([outer], tilt)), ("Inside", PLANK, move([inner], tilt)), ("Rim", WOOD_DARK, move([rim], tilt)),
            ("Benches", WOOD, move(benches, tilt)), ("Oars", WOOD_DARK, move(oars, tilt))]


def dock(rng):
    """A short jetty (about 6 x 13) on posts, the two end posts taller."""
    planks = [slab(rng, -2.8, 2.0, z - 0.6, 2.8, 2.45, z + 0.6, 0.06, 0.04) for z in np.arange(-5.8, 6.2, 1.3)]
    posts = []
    tall = []
    for z in (-6.2, 0.0, 6.2):
        for s in (-1, 1):
            h = 5.2 if z == 6.2 else 2.0
            (tall if h > 3 else posts).append(prism(rng, (s * 2.9, -0.6, z), (s * 2.9, h, z), 0.5, 0.5, 8, 0.0))
    caps = [ball((s * 2.9, 5.2, 6.2), 0.5, 8) for s in (-1, 1)]
    return [("Planks", PLANK, planks), ("Posts", WOOD, posts + tall), ("Caps", WOOD_DARK, caps)]


ITEMS = [  # name, builder, seed, label
    ("SkullRock", skull_rock, 3, "Skull rock"),
    ("Shipwreck", shipwreck, 2, "Shipwreck"),
    ("Anchor", anchor, 1, "Anchor"),
    ("Dock", dock, 1, "Dock"),
    ("Rowboat", rowboat, 1, "Rowboat"),
    ("Cannon", cannon, 1, "Cannon"),
    ("Cannonballs", cannonballs, 1, "Cannonballs"),
    ("TreasureChest", treasure_chest, 1, "Treasure chest"),
    ("TreasurePile", treasure_pile, 2, "Treasure pile"),
]

SAND = [(240, 218, 160), (228, 204, 146)]


def main():
    built, sizes = build_set(OUT, ITEMS)
    big = [(n, l) for n, _, _, l in ITEMS[:4]]
    small = [(n, l) for n, _, _, l in ITEMS[4:]]
    rows = [lineup_row(built, sizes, big, SAND), lineup_row(built, sizes, small, SAND, ppst=34)]
    stack(rows, os.path.join(OUT, "pirate_cove_lineup.png"), "Pirate Cove props (1x; figure is 5 studs)")


if __name__ == "__main__":
    main()
