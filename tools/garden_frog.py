"""DON'T RERUN: QM edited designs/garden/<this animal>.bbmodel by hand in Blockbench (Oct 15), which is now
the source; this would overwrite it. Convert that file instead.

Toadstool Frog: World 3 Garden Rare (draft, Oct 14). A fat lime frog wearing a giant purple
toadstool for a hat: a squat body with a pale yellow belly and darker green spots, a wide head
with a long grin and pink tongue tip, big googly eyes on bumps, folded hind legs with webbed
orange-ish toes, and a domed purple cap with chunky white spots and a cream gill rim on top of
its head. Ridden on the cap. It hops: the walk is small hops, the gallop big leaps.

Blocks, but the cap is one low-poly mesh (QM Oct 14 pilot: "the only mesh tbh should be the cap"):
convert with
  python3 tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/ToadstoolFrog designs/garden/ToadstoolFrog.bbmodel src/shared/Animals/ToadstoolFrogModel.luau

Run: python3 tools/garden_frog.py [--gif]
Bones (all rest 0): root -> neck (head + cap), LegFL/FR, LegHL/HR.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, track, sin, TAU

# green: a brighter lime, off the grass (coordinator Oct 14; was 92,196,52, greendark 40,128,40)
C = {"green": (150, 222, 40), "greendark": (60, 150, 40), "belly": (246, 236, 140), "mouth": (64, 24, 30),
     "tongue": (240, 92, 120), "cap": (156, 72, 214), "capdark": (98, 40, 150), "spot": (252, 248, 236),  # cap purple: the Rafflesia is red over green
     "gill": (240, 218, 176), "toe": (250, 160, 70)}


def build():
    g = Garden("ToadstoolFrog", C)
    y0 = 3.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0, 0.6), (6.4, 4.0, 6.0), "green")
    g.box(root, "Belly", (0, y0 - 0.5, -2.45), (4.6, 2.8, 0.3), "belly")
    g.box(root, "BellyLow", (0, y0 - 1.95, 0.2), (5.0, 0.3, 4.6), "belly")
    g.box(root, "Rump", (0, y0 + 0.4, 3.9), (5.2, 3.2, 1.0), "green")
    for (x, y, z) in ((-2.2, 2.05, 1.2), (1.6, 2.05, 2.4), (0.4, 2.05, -0.4), (3.25, 0.8, 1.6), (-3.25, 0.4, 2.4)):
        sz = (1.2, 0.3, 1.2) if abs(x) < 3 else (0.3, 1.2, 1.2)
        g.box(root, "Spot", (x, y0 + y, z), sz, "greendark")

    # head: wide, grinning, eyes on bumps, the toadstool on top
    neck = g.group("neck", (0, y0 + 1.0, -1.8), root)
    hy, hz = y0 + 1.6, -3.0
    g.box(neck, "Head", (0, hy, hz), (7.0, 3.0, 4.0), "green")
    g.box(neck, "Jaw", (0, hy - 1.6, hz - 0.2), (6.6, 0.6, 3.8), "belly")
    g.box(neck, "Mouth", (0, hy - 1.15, hz - 2.0), (5.6, 0.35, 0.2), "mouth")
    g.box(neck, "Tongue", (1.2, hy - 1.3, hz - 2.08), (1.0, 0.35, 0.2), "tongue")
    for side, s in (("L", -1), ("R", 1)):
        g.box(neck, "Bump" + side, (s * 2.2, hy + 1.8, hz - 0.8), (2.4, 1.6, 2.2), "green")
        g.eye(neck, side, (s * 2.2, hy + 1.9, hz - 1.98), 1.7, look=(0, -0.1))
        g.box(neck, "Nostril" + side, (s * 0.6, hy + 0.3, hz - 2.05), (0.4, 0.3, 0.15), "greendark")
    # the toadstool, 1 stud higher than it was (the eyes clear the brim): a stalk, and the cap and
    # its underside as meshes the way the Garden's GiantToadstool prop makes them (QM Oct 14: "copy
    # the mushroom decor", no cubes in them; tools/w3_garden.py mushroom()), with 5 flat white spots
    cy, cz = hy + 3.9, hz + 0.9
    g.box(neck, "Stalk", (0, cy - 0.9, cz), (2.4, 2.4, 2.4), "gill")
    top, r = np.array([0, cy + 1.2, cz]), 4.7
    rng = np.random.default_rng(7)
    dome = blob(rng, top + (0, r * 0.1, 0), r, 22, squash=(1.0, 0.62, 1.0), jitter=0.04)
    dome = dome[dome[:, 1] > top[1] - 0.2]
    cap = np.concatenate([dome, ring(14, r * 1.03, top[1] - 0.25, top)])
    g.hull(neck, "Cap", cap, "cap")
    g.hull(neck, "Underside", ring(12, r * 0.9, top[1] - 0.15, top) + ring(12, 1.35, top[1] - r * 0.3, top), "gill")
    plates(g, neck, "CapSpot", cap, ((0, 1, -0.3), (0, 0.4, -1), (-1, 0.4, 0.3), (1, 0.4, 0.3), (0, 0.4, 1)), "spot")

    # legs: short front legs, big folded hind legs, orange toes
    for side, s in (("L", -1), ("R", 1)):
        fl = g.group("LegF" + side, (s * 2.4, y0 - 0.6, -1.8), root)
        g.box(fl, "LegF" + side, (s * 2.6, y0 - 1.6, -2.2), (1.5, 2.6, 1.5), "green")
        for t in (-1, 0, 1):
            g.box(fl, "ToeF" + side, (s * 2.6 + t * 0.55 * s, 0.25, -2.8 + abs(t) * 0.2), (0.45, 0.5, 1.4), "toe")
        hl = g.group("LegH" + side, (s * 3.0, y0 - 0.2, 2.4), root)
        g.box(hl, "Thigh" + side, (s * 3.6, y0 - 0.4, 2.4), (1.6, 3.0, 4.0), "green")
        g.box(hl, "Shin" + side, (s * 3.8, 0.6, 1.2), (1.4, 1.2, 4.4), "green")
        for t in (-1, 0, 1):
            g.box(hl, "ToeH" + side, (s * 3.8 + t * 0.6, 0.25, -1.4 + abs(t) * 0.3), (0.5, 0.5, 1.6), "toe")
    return g


def blob(rng, c, r, n=12, squash=(1.0, 1.0, 1.0), jitter=0.12):
    """A faceted lump: n points spread over a sphere (jittered); as tools/plant_meshes.py."""
    pts = []
    for i in range(n):
        y = 1 - 2 * (i + 0.5) / n
        a = i * np.pi * (3 - np.sqrt(5)) + rng.uniform(-0.3, 0.3)
        s = np.sqrt(1 - y * y)
        rr = r * (1 + rng.uniform(-jitter, jitter))
        pts.append((c[0] + np.cos(a) * s * rr * squash[0], c[1] + y * rr * squash[1], c[2] + np.sin(a) * s * rr * squash[2]))
    return np.array(pts)


def ring(n, r, y, c):
    """n points round a circle of radius r at height y about c's x, z."""
    return [(c[0] + np.cos(2 * np.pi * i / n) * r, y, c[2] + np.sin(2 * np.pi * i / n) * r) for i in range(n)]


def plates(g, node, name, pts, dirs, col, fill=0.75):
    """Flat round spots lying in the facets of hull(pts), sunk in a little: one in the facet
    facing most along each direction in dirs, centred on its incircle (fill of its radius),
    so none overhangs an edge. They're meshes, so they merge into one MeshPart."""
    tris = G.hull_tris(pts)

    def inr(t):
        a, b, c = np.linalg.norm(t[1] - t[2]), np.linalg.norm(t[2] - t[0]), np.linalg.norm(t[0] - t[1])
        return np.linalg.norm(np.cross(t[1] - t[0], t[2] - t[0])) / (a + b + c)

    def facing(t, d):
        n = np.cross(t[1] - t[0], t[2] - t[0])
        return np.dot(n / np.linalg.norm(n), d)
    used = set()
    for d in dirs:
        d = np.array(d, float) / np.linalg.norm(d)
        k = max((i for i in range(len(tris)) if i not in used and facing(tris[i], d) > 0.85),
                key=lambda i: inr(tris[i]))  # (the roomiest facet facing about that way)
        A, B, Cc = tris[k]
        n = np.cross(B - A, Cc - A)
        area2 = np.linalg.norm(n)
        n /= area2
        a, b, c = np.linalg.norm(B - Cc), np.linalg.norm(Cc - A), np.linalg.norm(A - B)
        centre = (a * A + b * B + c * Cc) / (a + b + c)
        r = area2 / (a + b + c)
        g.hull(node, name, G.prism(centre - n * 0.15, r * fill, 0.2, seg=8, M=G.frame(n)), col)


def animations(m):
    def hops(L, height, reach, lean, n=16):
        h = lambda u: max(0.0, sin(TAU * u))  # in the air for the first half
        return {"root": [track(L, lambda u: (lean - 14 * h(u) + 6 * max(0, -sin(TAU * u)), 0, 0), n),
                         track(L, lambda u: (0, height * h(u), 0), n, "position")],
                "LegHL": [track(L, lambda u: (-reach * h(u), 0, 0), n)],
                "LegHR": [track(L, lambda u: (-reach * h(u), 0, 0), n)],
                "LegFL": [track(L, lambda u: (reach * 0.8 * h(u), 0, 0), n)],
                "LegFR": [track(L, lambda u: (reach * 0.8 * h(u), 0, 0), n)],
                "neck": [track(L, lambda u: (8 * h(u), 0, 0), n)]}

    L = 3.0
    idle = {"neck": [track(L, lambda u: (3 * sin(TAU * u), 6 * sin(TAU * u), 2 * sin(TAU * 2 * u)), 24)],
            "root": [track(L, lambda u: (0, 1.5 * abs(sin(TAU * 2 * u)), 0), 24, "position")]}  # throat breathing
    return {"idle": (L, idle), "walk": (0.7, hops(0.7, 14, 30, 0)), "gallop": (0.5, hops(0.5, 30, 55, -4))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/ToadstoolFrog_anims.gif")
