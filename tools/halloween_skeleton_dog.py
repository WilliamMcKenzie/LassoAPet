"""Skeleton Dog: Halloween Soul Valley Uncommon (draft, Oct 15). A happy bone dog: a white spine
over a rib cage block, a hip block, thin bone legs with knobbly paws, a skull with a long snout,
dark eye sockets holding googly eyes on the sides, and a two-bone tail.

Run: python3 tools/halloween_skeleton_dog.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import halloween_lib as H
from halloween_lib import Spooky, Rm

C = {"bone": (250, 246, 228), "bonedark": (206, 198, 172), "socket": (40, 52, 64), "collar": (40, 190, 190)}


def build():
    g = Spooky("SkeletonDog", C)
    y0 = 4.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Spine", (0, y0 + 1.4, 0.8), (1.0, 1.0, 7.0), "bone")
    g.box(root, "Ribs", (0, y0 + 0.4, -0.8), (3.6, 2.6, 3.4), "bonedark")
    g.box(root, "Hips", (0, y0 + 0.8, 3.4), (3.0, 1.6, 1.8), "bone")
    for nm, (x, z) in (("FL", (-1, -1.6)), ("FR", (1, -1.6)), ("HL", (-1, 3.4)), ("HR", (1, 3.4))):
        g.leg(root, nm, (x * 1.3, y0 - 0.4, z), y0 - 0.4, 0.8, "bone", foot=1.4, foot_col="bone")
    tail = g.group("Tail", (0, y0 + 1.6, 4.2), root)
    g.box(tail, "Tail", (0, y0 + 2.4, 5.0), (0.7, 0.7, 2.4), "bone", Rm(("x", -35)))
    neck = g.group("neck", (0, y0 + 1.4, -2.4), root)
    hy, hz = y0 + 2.6, -3.4
    g.box(neck, "Collar", (0, y0 + 1.6, -2.4), (2.4, 0.8, 1.2), "collar")
    g.box(neck, "Skull", (0, hy, hz), (3.2, 2.8, 2.8), "bone")
    g.box(neck, "Snout", (0, hy - 0.7, hz - 2.2), (1.8, 1.2, 1.8), "bone")
    g.box(neck, "Nose", (0, hy - 0.1, hz - 3.15), (0.8, 0.5, 0.3), "socket")
    for side, s in (("L", -1), ("R", 1)):
        g.box(neck, "Socket" + side, (s * 1.55, hy + 0.3, hz - 0.4), (0.2, 1.5, 1.5), "socket")
        g.eye(neck, side, (s * 1.7, hy + 0.3, hz - 0.4), 1.0, normal=(s, 0, 0))
        g.box(neck, "Ear" + side, (s * 1.2, hy + 1.8, hz + 0.6), (0.8, 1.2, 0.6), "bone", Rm(("z", s * 15)))
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(26, 44), hop=(2, 7)))
    if "--gif" in sys.argv:
        H.gif(m, "SkeletonDog")
