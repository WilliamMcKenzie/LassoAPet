"""Zombie Bear: Halloween Soul Valley Rare (draft, Oct 15). A big friendly zombie teddy: a green bear
with a purple stitched belly patch, one bandaged white leg, round ears, a pale muzzle, googly
eyes on the sides of its head and a stubby tail.

Run: python3 tools/halloween_zombie_bear.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky

C = {"fur": (120, 190, 110), "furdark": (84, 140, 80), "muzzle": (200, 230, 180), "patch": (150, 80, 200),
     "stitch": (40, 40, 52), "bandage": (246, 240, 222)}


def build():
    g = Spooky("ZombieBear", C)
    y0 = 4.6
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0 + 0.8, 0.6), (5.6, 4.6, 8.0), "fur")
    g.box(root, "Patch", (2.85, y0 + 1.0, 0.8), (0.2, 2.0, 2.4), "patch")
    g.box(root, "Stitch", (2.97, y0 + 1.0, 0.8), (0.1, 0.3, 2.8), "stitch")
    for nm, (x, z) in (("FL", (-1, -2.0)), ("FR", (1, -2.0)), ("HL", (-1, 3.4)), ("HR", (1, 3.4))):
        leg = g.leg(root, nm, (x * 1.7, y0 - 0.6, z), y0 - 0.6, 2.0, "fur", foot=2.4, foot_col="furdark")
        if nm == "FR":
            g.box(leg, "Bandage", (x * 1.7, y0 - 2.0, z), (2.2, 1.6, 2.2), "bandage")
    tail = g.group("Tail", (0, y0 + 1.6, 4.6), root)
    g.box(tail, "Tail", (0, y0 + 1.8, 4.9), (1.4, 1.4, 1.0), "furdark")
    neck = g.group("neck", (0, y0 + 2.0, -3.0), root)
    hy, hz = y0 + 2.8, -4.4
    g.box(neck, "Head", (0, hy, hz), (4.4, 3.8, 3.4), "fur")
    g.box(neck, "Muzzle", (0, hy - 0.8, hz - 2.1), (2.2, 1.6, 1.0), "muzzle")
    g.box(neck, "Nose", (0, hy - 0.2, hz - 2.7), (1.0, 0.6, 0.3), "stitch")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 2.25, hy + 0.4, hz - 0.6), 1.2, normal=(s, 0, 0))
        g.hull(neck, "Ear" + side, G.ellipsoid((s * 1.6, hy + 2.0, hz + 0.4), (0.9, 0.9, 0.5), seg=8, rings=3, cut=-0.5), "furdark")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(22, 36), hop=(2, 6), lean=-3))
    if "--gif" in sys.argv:
        H.gif(m, "ZombieBear")
