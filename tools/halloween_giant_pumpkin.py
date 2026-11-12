"""Giant Pumpkin: the Halloween world's Haunted Hills boss (QM, Oct 15). A huge jack-o'-lantern
that bounds after you: six faceted pumpkin lobes (meshes: it's round) in two oranges, a thick
curled green stem, two big leaves, angry glowing triangle eyes and a jagged glowing grin with
pumpkin teeth, and two vine arms curling forward from its sides. No legs: it hops.

Run: python3 tools/halloween_giant_pumpkin.py [--gif]
Bones (all rest 0): root -> Top, VineL, VineR.
"""

import math
import sys

import numpy as np

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky, Rm, track, sin, TAU

C = {"pumpkin": (255, 128, 20), "pumpkindark": (226, 96, 14), "stem": (70, 120, 40), "leaf": (110, 190, 60),
     "glow": (255, 220, 60)}


def build():
    g = Spooky("GiantPumpkin", C)
    cy = 5.0
    root = g.group("root", (0, cy, 0))
    for k in range(6):
        a = math.radians(90 + 60 * k)  # lobe 0 straight ahead (-z)
        c = (2.6 * math.cos(a), cy, -2.6 * math.sin(a))
        g.hull(root, "Pumpkin", G.ellipsoid(c, (3.4, 4.8, 3.4), seg=10, rings=5),
               "pumpkin" if k % 2 == 0 else "pumpkindark")
    z = -5.85  # the front lobe's face (carved into it: the features sit flush, turned with the curve)
    for side, s in (("L", -1), ("R", 1)):
        # an angry triangle eye: a flat pyramid pointing up and in, on the curve of the face
        yaw = math.radians(s * 28)
        g.pyr(root, "Glow_Eye" + side, (s * 1.75, cy + 0.9, z + 0.5), (-s * 0.45, 1, 0), 1.9, 1.0, 0.3, "glow",
              wv=(math.cos(yaw), 0, math.sin(yaw)))
    g.box(root, "Glow_Grin", (0, cy - 1.6, z + 0.35), (3.6, 1.5, 0.5), "glow")
    for x in (-1.2, 0.0, 1.2):  # teeth down from the top lip
        g.pyr(root, "Tooth", (x, cy - 0.85, z + 0.05), (0, -1, 0), 0.9, 0.38, 0.25, "pumpkin")
    for x in (-0.6, 0.6):  # and up from the bottom
        g.pyr(root, "Tooth", (x, cy - 2.35, z + 0.05), (0, 1, 0), 0.8, 0.38, 0.25, "pumpkin")
    top = g.group("Top", (0, cy + 4.6, 0), root)
    g.box(top, "Stem", (0, cy + 5.6, 0.3), (1.4, 2.6, 1.4), "stem", Rm(("x", 18)))
    g.pyr(top, "StemTip", (0, cy + 6.8, 0.75), (0, 0.4, 1), 1.6, 0.7, 0.7, "stem")
    for s in (-1, 1):
        g.hull(top, "Leaf", G.leaf((s * 0.6, cy + 4.9, 0.2), (s, 0.15, 0.3), (0, 1, 0), 5.0, 3.0, 0.4), "leaf")
    for side, s in (("L", -1), ("R", 1)):
        vine = g.group("Vine" + side, (s * 5.4, cy, 0), root)
        path = [(s * (5.2 + 3.0 * u), cy - 0.5 + 2.4 * math.sin(u * 2.4), -5.0 * u ** 1.3) for u in np.linspace(0, 1, 6)]
        G.tube(g, vine, "Vine", path, [0.8, 0.7, 0.6, 0.5, 0.4, 0.12], "stem")
        g.hull(vine, "VineLeaf", G.leaf(path[2], (s * 0.4, 0.8, -0.3), (s, 0, 0), 3.2, 2.0, 0.35), "leaf")
    return g


def animations(m):
    def hop(L, h, lean, n=16):
        return {
            "root": [track(L, lambda u: (lean + 6 * sin(TAU * u), 0, 3 * sin(TAU * u)), n),
                     track(L, lambda u: (0, h * abs(sin(TAU * u / 2)) ** 0.8, 0), n, "position")],
            "Top": [track(L, lambda u: (-10 * sin(TAU * u), 0, 6 * sin(TAU * u + 1)), n)],
            "VineL": [track(L, lambda u: (25 * sin(TAU * u), 0, -15 * sin(TAU * u)), n)],
            "VineR": [track(L, lambda u: (-25 * sin(TAU * u), 0, 15 * sin(TAU * u)), n)],
        }

    L = 3.0
    idle = {"root": [track(L, lambda u: (0, 0.6 * sin(TAU * 2 * u), 0), 24, "position")],
            "Top": [track(L, lambda u: (4 * sin(TAU * u), 0, 6 * sin(TAU * u)), 24)],
            "VineL": [track(L, lambda u: (12 * sin(TAU * u), 0, -8 * sin(TAU * u)), 24)],
            "VineR": [track(L, lambda u: (12 * sin(TAU * u + 1), 0, 8 * sin(TAU * u + 1)), 24)]}
    return {"idle": (L, idle), "walk": (0.9, hop(0.9, 2.5, -4)), "gallop": (0.6, hop(0.6, 5, -8))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        H.gif(m, "GiantPumpkin")
