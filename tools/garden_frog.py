"""Toadstool Frog: World 3 Garden Rare (draft, Oct 14). A fat lime frog wearing a giant purple
toadstool for a hat: a squat body with a pale yellow belly and darker green spots, a wide head
with a long grin and pink tongue tip, big googly eyes on bumps, folded hind legs with webbed
orange-ish toes, and a domed purple cap with chunky white spots and a cream gill rim on top of
its head. Ridden on the cap. It hops: the walk is small hops, the gallop big leaps.

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
        g.box(neck, "EyeBump" + side, (s * 2.2, hy + 1.8, hz - 0.8), (2.4, 1.6, 2.2), "green")
        g.eye(neck, side, (s * 2.2, hy + 1.9, hz - 1.98), 1.7, look=(0, -0.1))
        g.box(neck, "Nostril" + side, (s * 0.6, hy + 0.3, hz - 2.05), (0.4, 0.3, 0.15), "greendark")
    # the toadstool: a gill rim, a domed cap in three layers, chunky white spots
    cy = hy + 2.9
    g.box(neck, "Stalk", (0, cy - 0.4, hz + 0.9), (2.4, 1.4, 2.4), "gill")
    g.box(neck, "Gills", (0, cy + 0.3, hz + 0.9), (7.6, 0.5, 7.0), "gill")
    for k, (w, d, h) in enumerate(((9.0, 8.4, 1.3), (7.8, 7.2, 1.1), (5.8, 5.4, 0.9), (3.4, 3.2, 0.6))):
        yy = cy + 0.9 + sum(x[2] for x in ((9.0, 8.4, 1.3), (7.8, 7.2, 1.1), (5.8, 5.4, 0.9))[:k]) - (0 if k == 0 else 0)
        g.box(neck, "Cap", (0, yy, hz + 0.9), (w, h, d), "cap" if k else "capdark")
    top = cy + 0.9 + 1.3 + 1.1 + 0.9
    for (x, y, z, sz) in ((0, top + 0.05, 0.9, (1.6, 0.4, 1.6)), (-2.6, cy + 2.6, -1.0, (1.4, 0.4, 1.4)),
                          (2.4, cy + 2.6, 2.6, (1.4, 0.4, 1.4)), (2.6, cy + 2.6, -1.4, (1.1, 0.4, 1.1)),
                          (-2.2, cy + 2.6, 2.8, (1.2, 0.4, 1.2))):
        g.box(neck, "CapSpot", (x, y, hz + z), sz, "spot")
    for (x, z) in ((-4.55, 0.0), (4.55, 1.6)):
        g.box(neck, "CapSpotSide", (x, cy + 1.6, hz + 0.9 + z - 0.8), (0.3, 1.0, 1.4), "spot")
    g.box(neck, "CapSpotFront", (1.6, cy + 1.6, hz + 0.9 - 4.25), (1.4, 1.0, 0.3), "spot")
    g.box(neck, "CapSpotFront", (-2.4, cy + 1.4, hz + 0.9 - 4.25), (1.0, 0.8, 0.3), "spot")

    # legs: short front legs, big folded hind legs, orange toes
    for side, s in (("L", -1), ("R", 1)):
        fl = g.group("LegF" + side, (s * 2.4, y0 - 0.6, -1.8), root)
        g.box(fl, "LegF" + side, (s * 2.6, y0 - 1.6, -2.2), (1.2, 2.6, 1.2), "green")
        for t in (-1, 0, 1):
            g.box(fl, "ToeF" + side, (s * 2.6 + t * 0.55 * s, 0.25, -2.8 + abs(t) * 0.2), (0.45, 0.5, 1.4), "toe")
        hl = g.group("LegH" + side, (s * 3.0, y0 - 0.2, 2.4), root)
        g.box(hl, "Thigh" + side, (s * 3.6, y0 - 0.4, 2.4), (1.6, 3.0, 4.0), "green")
        g.box(hl, "ThighSpot" + side, (s * 4.45, y0 - 0.2, 2.6), (0.2, 1.0, 1.2), "greendark")
        g.box(hl, "Shin" + side, (s * 3.8, 0.6, 1.2), (1.4, 1.2, 4.4), "green")
        for t in (-1, 0, 1):
            g.box(hl, "ToeH" + side, (s * 3.8 + t * 0.6, 0.25, -1.4 + abs(t) * 0.3), (0.5, 0.5, 1.6), "toe")
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
