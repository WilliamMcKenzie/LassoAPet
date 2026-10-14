"""Toadstool Frog: World 3 Garden Rare (draft, Oct 14). A fat lime frog wearing a giant purple
toadstool for a hat: a squat body with a pale yellow belly and darker green spots, a wide head
with a long grin and pink tongue tip, big googly eyes on bumps, folded hind legs with webbed
orange-ish toes, and a domed purple cap with chunky white spots and a cream gill rim on top of
its head. Ridden on the cap. It hops: the walk is small hops, the gallop big leaps.

Low-poly meshes (QM Oct 14 pilot), not blocks: convert with
  python3 tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/ToadstoolFrog designs/garden/ToadstoolFrog.bbmodel src/shared/Animals/ToadstoolFrogModel.luau

Run: python3 tools/garden_frog.py [--gif]
Bones (all rest 0): root -> neck (head + cap), LegFL/FR, LegHL/HR.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, track, sin, TAU

C = {"green": (92, 196, 52), "greendark": (40, 128, 40), "belly": (246, 236, 140), "mouth": (64, 24, 30),
     "tongue": (240, 92, 120), "cap": (156, 72, 214), "capdark": (98, 40, 150), "spot": (252, 248, 236),  # cap purple: the Rafflesia is red over green
     "gill": (240, 218, 176), "toe": (250, 160, 70)}


def on(c, r, d):
    """The point on ellipsoid (c, r) in direction d from its centre, and its outward normal."""
    d = np.array(d, float) / np.linalg.norm(d)
    r = np.array(r, float)
    t = 1 / np.linalg.norm(d / r)
    p = d * t
    n = p / r ** 2
    return np.array(c, float) + p, n / np.linalg.norm(n)


def spot(g, node, name, c, r, d, size, col, h=0.22):
    """A flat faceted spot sitting on ellipsoid (c, r) in direction d (its base sunk in)."""
    p, n = on(c, r, d)
    sz = (size, size * 0.85) if np.isscalar(size) else size
    g.hull(node, name, G.dome(p, sz, h, seg=6, rings=2, M=G.frame(n), base=0.35), col)


def foot(g, node, name, heel, toes, col):
    """A webbed foot: one flat fan from the heel out to the toe tips."""
    pts = []
    for q in [heel] + toes:
        q = np.array(q, float)
        for dx, dz in ((-0.25, 0), (0.25, 0), (0, -0.25), (0, 0.25)):
            pts += [q + (dx, 0, dz), q + (dx * 0.7, 0.45, dz * 0.7)]
    g.hull(node, name, pts, col)


def build():
    """Low-poly meshes (QM Oct 14: one mesh where blocks were imitating low poly). Every
    shape on a bone in one colour becomes one MeshPart (bbmodel_to_luau.py --meshes);
    the eyes stay plate blocks."""
    g = Garden("ToadstoolFrog", C)
    y0 = 3.0
    root = g.group("root", (0, y0, 0))
    body_c, body_r = (0, y0 + 0.1, 0.8), (3.3, 2.2, 3.4)
    g.hull(root, "Body", G.ellipsoid(body_c, body_r, seg=8, rings=4, cut=-1.7), "green")
    g.hull(root, "Belly", G.ellipsoid((0, y0 - 0.5, -1.2), (2.5, 1.6, 1.45), seg=8, rings=4, cut=-1.2), "belly")
    for d, sz in (((-0.5, 1, 0.1), 1.2), ((0.45, 1, 0.5), 1.0), ((0.1, 1, -0.35), 0.8), ((1, 0.3, 0.4), 0.9),
                  ((-1, 0.1, 0.6), 1.0)):
        spot(g, root, "Spot", body_c, body_r, d, sz, "greendark")

    # head: wide, grinning, eyes on bumps, the toadstool on top
    neck = g.group("neck", (0, y0 + 1.0, -1.8), root)
    head_c, head_r = np.array([0, y0 + 1.7, -3.0]), np.array([3.6, 1.7, 2.4])
    g.hull(neck, "Head", G.ellipsoid(head_c, head_r, seg=8, rings=4), "green")
    for side, s in (("L", -1), ("R", 1)):
        bump = np.array([s * 2.1, y0 + 3.2, -3.7])
        g.hull(neck, "Bump" + side, G.ellipsoid(bump, (1.25, 1.1, 1.25), seg=8, rings=4), "green")
        g.eye(neck, side, bump + (0, 0.1, -1.3), 1.7, look=(0, -0.1))
        p, n = on(head_c, head_r, (s * 0.25, 0.25, -1))
        g.hull(neck, "Nose", G.ellipsoid(p, (0.22, 0.16, 0.16), seg=6, rings=2), "greendark")
    g.hull(neck, "Jaw", G.ellipsoid(head_c + (0, -1.25, -0.15), (3.35, 0.75, 2.2), seg=8, rings=4), "belly")
    # the grin: a thin band round the front of the head, just proud of it
    grin = []
    for x in np.linspace(-2.7, 2.7, 9):
        for dy in (-0.16, 0.16):
            y = -0.55 + dy - 0.12 * (1 - (x / 2.7) ** 2)  # (a smile: the middle dips)
            u = 1 - (x / head_r[0]) ** 2 - (y / head_r[1]) ** 2
            z = -head_r[2] * np.sqrt(max(u, 0)) - 0.06
            grin += [head_c + (x, y, z), head_c + (x * 0.9, y, z * 0.7)]
    g.hull(neck, "Mouth", grin, "mouth")
    g.hull(neck, "Tongue", G.ellipsoid(head_c + (1.2, -0.85, -2.1), (0.5, 0.3, 0.4), seg=6, rings=2), "tongue")

    # the toadstool: a stalk, a gill skirt, a dark rim, a domed purple cap, chunky white spots
    hz = -2.1
    g.hull(neck, "Stalk", G.prism((0, y0 + 3.0, hz), 1.3, 1.9, seg=8, top=0.9), "gill")
    g.hull(neck, "Gills", G.prism((0, y0 + 4.7, hz), (4.1, 3.8), 0.5, seg=10, top=1.08), "gill")
    g.hull(neck, "CapRim", G.prism((0, y0 + 5.0, hz), (4.7, 4.4), 0.6, seg=10, top=1.0), "capdark")
    cap_c, cap_r, cap_h = np.array([0, y0 + 5.5, hz]), (4.55, 4.25), 3.7
    g.hull(neck, "Cap", G.dome(cap_c, cap_r, cap_h, seg=10, rings=3), "cap")
    cap_e = (cap_r[0], cap_h, cap_r[1])
    for d, sz in (((0, 1, 0), 1.3), ((-0.8, 0.8, -0.6), 1.0), ((0.9, 0.7, 0.6), 1.0), ((0.8, 0.9, -0.7), 0.8),
                  ((-0.7, 0.8, 0.8), 0.9), ((-1, 0.25, 0), 0.8), ((1, 0.3, -0.1), 0.7), ((0.3, 0.3, -1), 0.8),
                  ((-0.4, 0.25, -1), 0.6), ((0, 0.3, 1), 0.8)):
        spot(g, neck, "CapSpot", cap_c, cap_e, d, sz, "spot", h=0.25)

    # legs: short front legs, big folded hind legs, webbed orange feet
    for side, s in (("L", -1), ("R", 1)):
        fl = g.group("LegF" + side, (s * 2.4, y0 - 0.6, -1.8), root)
        g.hull(fl, "LegF" + side, G.ellipsoid((s * 2.6, y0 - 1.5, -2.1), (0.9, 1.6, 0.9), seg=6, rings=3), "green")
        foot(g, fl, "ToeF" + side, (s * 2.6, 0, -2.2), [(s * 2.6 + t * 0.7, 0, -3.3 + abs(t) * 0.25) for t in (-1, 0, 1)],
             "toe")
        hl = g.group("LegH" + side, (s * 3.0, y0 - 0.2, 2.4), root)
        g.hull(hl, "Thigh" + side, G.ellipsoid((s * 3.5, y0 - 0.5, 2.4), (1.0, 1.7, 2.2), seg=8, rings=4,
                                               M=G.Rm(("x", 25))), "green")
        g.hull(hl, "Shin" + side, G.ellipsoid((s * 3.8, 0.75, 1.0), (0.8, 0.75, 2.3), seg=8, rings=3), "green")
        foot(g, hl, "ToeH" + side, (s * 3.8, 0, -0.6), [(s * 3.8 + t * 0.8, 0, -1.9 + abs(t) * 0.3) for t in (-1, 0, 1)],
             "toe")
    return g


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
