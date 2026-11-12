"""Pumpkin Pup: Halloween Haunted Hills Uncommon (draft, Oct 15). A stocky little dog whose head is
a jack-o'-lantern: a faceted orange pumpkin (a mesh: it's round) with a green stem, floppy leaf
ears, googly eyes on its sides and a glowing carved grin in front. Tan body, leaf-green collar,
a curly vine tail.

Run: python3 tools/halloween_pumpkin_pup.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import numpy as np

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky, Rm

C = {"fur": (196, 132, 78), "furdark": (150, 92, 50), "pumpkin": (255, 136, 24), "stem": (70, 150, 50),
     "leaf": (110, 196, 60), "glow": (255, 230, 80)}


def build():
    g = Spooky("PumpkinPup", C)
    y0 = 3.6
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0 + 0.3, 0.8), (3.8, 3.0, 6.0), "fur")
    for nm, (x, z) in (("FL", (-1, -1.4)), ("FR", (1, -1.4)), ("HL", (-1, 3.0)), ("HR", (1, 3.0))):
        g.leg(root, nm, (x * 1.2, y0 - 0.6, z), y0 - 0.6, 1.3, "fur", foot=1.6, foot_col="furdark")
    tail = g.group("Tail", (0, y0 + 1.2, 3.7), root)
    path = [(0, y0 + 1.2 + 2.2 * u, 3.7 + 1.6 * np.sin(u * 2.2)) for u in np.linspace(0, 1, 5)]
    G.tube(g, tail, "Tail", path, [0.4] * 4 + [0.25], "stem")
    neck = g.group("neck", (0, y0 + 1.0, -1.8), root)
    hy, hz = y0 + 2.6, -2.8
    g.box(neck, "Collar", (0, y0 + 1.2, -1.8), (4.0, 0.8, 1.4), "leaf")
    g.hull(neck, "Head", G.ellipsoid((0, hy, hz), (2.6, 2.2, 2.4), seg=10, rings=4), "pumpkin")
    g.box(neck, "Stem", (0, hy + 2.5, hz + 0.2), (0.6, 1.2, 0.6), "stem", Rm(("x", 15)))
    g.box(neck, "Glow_Grin", (0, hy - 0.8, hz - 2.2), (2.2, 0.6, 0.3), "glow")  # (lit from inside)
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 2.45, hy + 0.3, hz - 0.5), 1.2, normal=(s, 0, -0.35))
        g.hull(neck, "Ear" + side, G.leaf((s * 2.0, hy + 1.2, hz + 0.6), (s * 1.0, -0.8, 0.3), (0, 0, 1), 2.4, 1.4, 0.3), "leaf")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(26, 44), hop=(2, 7)))
    if "--gif" in sys.argv:
        H.gif(m, "PumpkinPup")
