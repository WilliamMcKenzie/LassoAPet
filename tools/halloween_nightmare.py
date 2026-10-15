"""Nightmare: Halloween Haunted Hills Legendary (draft, Oct 15). A tall black horse on fire: a mane of
glowing purple flame pyramids from its forelock down its neck, a flame tail, glowing purple
hooves, googly eyes on the sides of its head (like the horse) and a dark purple muzzle.

Run: python3 tools/halloween_nightmare.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import numpy as np

import halloween_lib as H
from halloween_lib import Spooky, Rm

C = {"coat": (56, 46, 74), "coatdark": (26, 22, 34), "muzzle": (76, 48, 100), "flame": (190, 80, 255),
     "flamehot": (255, 150, 255)}


def build():
    g = Spooky("Nightmare", C)
    y0 = 7.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0 + 0.6, 0.6), (4.4, 4.2, 9.0), "coat")
    for nm, (x, z) in (("FL", (-1, -2.8)), ("FR", (1, -2.8)), ("HL", (-1, 3.8)), ("HR", (1, 3.8))):
        leg = g.leg(root, nm, (x * 1.3, y0 - 0.8, z), y0 - 0.8, 1.5, "coat")
        g.box(leg, "Glow_Hoof" + nm, (x * 1.3, 0.5, z), (1.9, 1.0, 1.9), "flame")
    tail = g.group("Tail", (0, y0 + 2.0, 5.0), root)
    for k, (dy, dz, L) in enumerate(((0.0, 0.0, 3.6), (-1.0, 0.4, 3.0), (0.9, 0.3, 2.6))):
        d = np.array([0, -0.6 + 0.4 * k, 1.0])
        g.pyr(tail, "Glow_Tail", (0, y0 + 2.0 + dy, 5.2 + dz), d, L, 0.8, 0.8, "flame" if k else "flamehot")
    neck = g.group("neck", (0, y0 + 2.2, -3.2), root)
    g.box(neck, "Neck", (0, y0 + 4.4, -4.4), (2.6, 4.6, 2.8), "coat", Rm(("x", 25)))
    hy, hz = y0 + 6.2, -5.8
    g.box(neck, "Head", (0, hy, hz), (2.8, 2.8, 3.2), "coat")
    g.box(neck, "Muzzle", (0, hy - 0.6, hz - 2.6), (2.4, 2.0, 2.4), "muzzle")
    g.box(neck, "Nostrils", (0, hy - 0.2, hz - 3.85), (1.6, 0.5, 0.2), "coatdark")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.45, hy + 0.3, hz - 0.3), 1.0, normal=(s, 0, 0))
        g.pyr(neck, "Ear" + side, (s * 0.8, hy + 1.4, hz + 0.9), (s * 0.15, 1, 0.2), 1.4, 0.45, 0.35, "coat")
    # the flame mane: a row of glowing pyramids up the back of the neck and a forelock
    for k in range(5):
        t = k / 4
        base = np.array([0, y0 + 3.0 + 4.0 * t, -2.4 - 2.0 * t])
        g.pyr(neck, "Glow_Mane", base, (0, 0.7, 1), 2.8 - 0.5 * t, 0.8, 0.8, "flamehot" if k % 2 else "flame")
    g.pyr(neck, "Glow_Forelock", (0, hy + 1.4, hz + 0.2), (0, 1, 0.5), 1.8, 0.6, 0.6, "flamehot")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(26, 44), hop=(2, 8), lean=-4))
    if "--gif" in sys.argv:
        H.gif(m, "Nightmare")
