"""Grim Reaper: Halloween Soul Valley Legendary, floats (draft, Oct 15). A cute floating reaper: a
dark robe that tapers to a point (a faceted mesh: it's a cone), a round hood (a mesh) around a
bone-white skull face with googly eyes (on the front: the hood hides its sides), little sleeve arms, and a big scythe with a
teal glowing blade held in front.

Run: python3 tools/halloween_grim_reaper.py [--gif]
Bones (all rest 0): root -> neck, ArmL/ArmR (the scythe in ArmR).
"""

import sys

import numpy as np

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky, Rm, track, sin, TAU

C = {"robe": (52, 46, 70), "robedark": (32, 28, 46), "skull": (250, 246, 230), "socket": (40, 52, 64),
     "wood": (120, 78, 50), "blade": (90, 255, 230)}


def build():
    g = Spooky("GrimReaper", C)
    y0 = 6.0
    root = g.group("root", (0, y0, 0))
    g.hull(root, "Robe", G.prism((0, y0 - 4.0, 0), 0.6, 7.0, seg=8, top=5.0), "robe")  # (a cone, point down)
    neck = g.group("neck", (0, y0 + 3.0, 0), root)
    hy = y0 + 4.6
    g.hull(neck, "Hood", G.ellipsoid((0, hy, 0.3), (2.9, 2.8, 2.9), seg=10, rings=4, cut=-1.6), "robedark")
    g.box(neck, "Face", (0, hy - 0.3, -2.2), (2.6, 2.4, 1.0), "skull")
    g.box(neck, "Teeth", (0, hy - 1.05, -2.72), (1.4, 0.35, 0.1), "socket")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 0.65, hy + 0.05, -2.75), 0.9)
        arm = g.group("Arm" + side, (s * 2.4, y0 + 2.0, 0), root)
        g.box(arm, "Sleeve" + side, (s * 2.9, y0 + 1.4, -0.6), (1.4, 2.4, 1.4), "robe", Rm(("x", 30)))
        g.box(arm, "Hand" + side, (s * 2.9, y0 + 0.4, -1.4), (1.0, 1.0, 1.0), "skull")
        if s > 0:
            g.box(arm, "Handle", (3.0, y0 + 1.8, -1.6), (0.5, 9.0, 0.5), "wood")
            g.box(arm, "Glow_Blade", (3.0, y0 + 6.1, -3.6), (0.5, 1.1, 4.4), "blade")
            g.pyr(arm, "Glow_BladeTip", (3.0, y0 + 6.1, -5.8), (0, -0.6, -1), 2.4, 0.25, 0.55, "blade")
    return g


def animations(m):
    def float_(L, amp, sw, lean):
        return {"root": [track(L, lambda u: (lean, 0, 3 * sin(TAU * u)), 16),
                         track(L, lambda u: (0, amp * sin(TAU * u), 0), 16, "position")],
                "neck": [track(L, lambda u: (3 * sin(TAU * u), 6 * sin(TAU * u * 0.5), 0), 16)],
                "ArmL": [track(L, lambda u: (sw * sin(TAU * u), 0, 0), 16)],
                "ArmR": [track(L, lambda u: (-sw * 0.5 * sin(TAU * u), 0, 0), 16)]}
    return {"idle": (2.4, float_(2.4, 0.8, 8, 0)), "walk": (1.2, float_(1.2, 1.0, 14, -8)),
            "gallop": (0.7, float_(0.7, 1.2, 20, -16))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        H.gif(m, "GrimReaper")
