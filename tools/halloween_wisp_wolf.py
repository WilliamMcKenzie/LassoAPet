"""Wisp Wolf: Halloween Soul Valley Epic (draft, Oct 15). A spirit wolf in Soul Valley's teal: a lean
teal wolf with a glowing ruff of flame pyramids round its neck, a glowing flame tail, glowing
paws, tall ears, a long snout and googly eyes on the sides of its head.

Run: python3 tools/halloween_wisp_wolf.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import numpy as np

import halloween_lib as H
from halloween_lib import Spooky

C = {"fur": (60, 170, 180), "furdark": (36, 116, 130), "snout": (150, 230, 226), "nose": (24, 40, 48),
     "wisp": (90, 255, 230), "wisphot": (210, 255, 250)}


def build():
    g = Spooky("WispWolf", C)
    y0 = 6.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0 + 0.6, 0.8), (4.4, 4.0, 9.0), "fur")
    for nm, (x, z) in (("FL", (-1, -2.6)), ("FR", (1, -2.6)), ("HL", (-1, 4.0)), ("HR", (1, 4.0))):
        leg = g.leg(root, nm, (x * 1.4, y0 - 0.8, z), y0 - 0.8, 1.5, "fur")
        g.box(leg, "Glow_Paw" + nm, (x * 1.4, 0.5, z - 0.2), (2.0, 1.0, 2.2), "wisp")
    tail = g.group("Tail", (0, y0 + 1.8, 5.2), root)
    for k, (dy, L) in enumerate(((0.0, 4.2), (0.9, 3.0), (-0.8, 3.0))):
        g.pyr(tail, "Glow_Tail", (0, y0 + 1.8 + dy, 5.4), (0, 0.5 + 0.3 * (k == 1) - 0.3 * (k == 2), 1), L, 0.9, 0.9,
              "wisphot" if k == 0 else "wisp")
    neck = g.group("neck", (0, y0 + 1.8, -3.4), root)
    hy, hz = y0 + 3.4, -5.0
    for k in range(6):  # the glowing ruff, a ring of flames round the neck pointing back
        a = 2 * np.pi * k / 6
        g.pyr(neck, "Glow_Ruff", (2.0 * np.cos(a), hy - 1.0 + 1.8 * np.sin(a), -3.6), (np.cos(a) * 0.6, np.sin(a) * 0.6, 1), 2.6, 0.8, 0.8,
              "wisphot" if k % 2 else "wisp")
    g.box(neck, "Head", (0, hy, hz), (3.6, 3.2, 3.4), "fur")
    g.box(neck, "Snout", (0, hy - 0.7, hz - 2.8), (2.0, 1.6, 2.4), "snout")
    g.box(neck, "Nose", (0, hy + 0.15, hz - 4.0), (0.9, 0.6, 0.4), "nose")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.85, hy + 0.5, hz - 0.7), 1.1, normal=(s, 0, 0))
        g.pyr(neck, "Ear" + side, (s * 1.1, hy + 1.6, hz + 0.6), (s * 0.15, 1, 0.1), 2.4, 0.75, 0.55, "furdark")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(26, 46), gait="bound", hop=(2, 9), lean=-6))
    if "--gif" in sys.argv:
        H.gif(m, "WispWolf")
