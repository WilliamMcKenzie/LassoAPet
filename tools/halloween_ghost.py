"""Ghost: Halloween Soul Valley Common, floats (draft, Oct 15). A plump pale-mint ghost: a rounded
body (a faceted mesh: it's round) with a wavy hem of four downward points, stubby arms held out,
googly eyes on the sides of its head and a little round "oo" mouth.

Run: python3 tools/halloween_ghost.py [--gif]
Bones (all rest 0): root -> ArmL/ArmR.
"""

import sys

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky, track, sin, TAU

C = {"ghost": (220, 255, 246), "ghostdark": (150, 226, 214), "mouth": (40, 60, 70)}


def build():
    g = Spooky("Ghost", C)
    y0 = 5.0
    root = g.group("root", (0, y0, 0))
    g.hull(root, "Body", G.dome((0, y0 + 2.6, 0), 2.6, 3.0, seg=10, rings=3, base=2.6), "ghost")
    for k, (x, z) in enumerate(((-1.5, -1.5), (1.5, -1.5), (-1.5, 1.5), (1.5, 1.5))):
        g.pyr(root, "Hem", (x, y0 + 0.2, z), (0, -1, 0), 2.8 - 0.5 * (k % 2), 1.3, 1.3, "ghost")
    g.box(root, "Mouth", (0, y0 + 2.2, -2.55), (0.8, 0.9, 0.3), "mouth")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(root, side, (s * 2.3, y0 + 3.4, -1.1), 1.1, normal=(s, 0, -0.5))
        arm = g.group("Arm" + side, (s * 2.4, y0 + 1.8, 0), root)
        g.box(arm, "Arm" + side, (s * 3.2, y0 + 1.7, -0.4), (1.8, 1.0, 1.2), "ghostdark")
    return g


def animations(m):
    def float_(L, amp, wave, lean):
        return {"root": [track(L, lambda u: (lean, 0, 3 * sin(TAU * u)), 16),
                         track(L, lambda u: (0, amp * sin(TAU * u), 0), 16, "position")],
                "ArmL": [track(L, lambda u: (0, 0, -wave * sin(TAU * u)), 16)],
                "ArmR": [track(L, lambda u: (0, 0, wave * sin(TAU * u + 1)), 16)]}
    return {"idle": (2.0, float_(2.0, 0.8, 12, 0)), "walk": (1.0, float_(1.0, 1.0, 20, -8)),
            "gallop": (0.6, float_(0.6, 1.2, 30, -16))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        H.gif(m, "Ghost")
