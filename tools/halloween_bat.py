"""Bat: Halloween Haunted Hills Uncommon, a flier (draft, Oct 15). A round purple bat: a faceted
ball body (a mesh: it's round), big pointed ears, googly eyes on the sides, two little white
fangs, and wings in two jointed panels each (meshes), the outer panel ending in points.

Run: python3 tools/halloween_bat.py [--gif]
Bones (all rest 0): root -> neck, WingL/WingR -> WingL2/WingR2, LegL/LegR.
"""

import math
import sys

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky, track, TAU

C = {"fur": (110, 60, 150), "furdark": (66, 34, 96), "wing": (52, 28, 76), "pink": (255, 140, 190),
     "fang": (252, 250, 244)}


def build():
    g = Spooky("Bat", C)
    y0 = 4.0
    root = g.group("root", (0, y0, 0))
    g.hull(root, "Body", G.ellipsoid((0, y0, 0.3), (2.2, 2.3, 2.6), seg=8, rings=4), "fur")
    for side, s in (("L", -1), ("R", 1)):
        leg = g.group("Leg" + side, (s * 0.8, y0 - 1.8, 0.8), root)
        g.box(leg, "Leg" + side, (s * 0.8, y0 - 2.4, 0.9), (0.5, 1.4, 0.5), "furdark")
    neck = g.group("neck", (0, y0 + 0.6, -1.4), root)
    hy, hz = y0 + 1.0, -2.2
    g.hull(neck, "Head", G.ellipsoid((0, hy, hz), (1.8, 1.6, 1.6), seg=8, rings=4), "fur")
    g.box(neck, "Snout", (0, hy - 0.4, hz - 1.5), (1.4, 0.9, 0.8), "furdark")
    g.box(neck, "Nose", (0, hy - 0.1, hz - 1.95), (0.6, 0.4, 0.2), "pink")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.62, hy + 0.15, hz - 0.5), 1.0, normal=(s, 0, -0.45))
        g.pyr(neck, "Ear" + side, (s * 0.95, hy + 1.2, hz + 0.1), (s * 0.35, 1, 0.1), 2.2, 0.7, 0.4, "fur")
        g.pyr(neck, "Fang" + side, (s * 0.35, hy - 0.85, hz - 1.75), (0, -1, 0), 0.6, 0.18, 0.15, "fang")
        # wings: an inner panel from the shoulder, an outer panel with three points
        w1 = g.group("Wing" + side, (s * 1.6, y0 + 0.6, 0), root)
        x0, x1, x2 = s * 1.4, s * 5.0, s * 9.0
        t = 0.2
        Y = y0 + 0.6
        sh = [(x0, Y + 0.3, -1.0), (x0, Y - 0.6, 2.0)]
        el = [(x1, Y + 1.6, -0.6), (x1, Y + 0.5, 1.2), (x1, Y - 0.5, 3.2)]
        thick = lambda P: [(x, y + d, z) for x, y, z in P for d in (-t, t)]
        g.hull(w1, "Wing" + side, thick(sh + [el[0], el[2]]), "wing")
        w2 = g.group(f"Wing{side}2", (x1, Y + 0.5, 0.6), w1)
        g.hull(w2, f"Wing{side}2", thick([el[0], el[1], (x2, Y + 2.8, -0.2)]), "wing")  # (two points, a
        g.hull(w2, f"Wing{side}2", thick([el[1], el[2], (s * 7.6, Y - 0.6, 3.8)]), "wing")  # bat's scallop between)
    return g


def animations(m):
    def flap(L, amp, amp2, bias=0.0, n=16):
        tr = {}
        for s, nm in ((-1, "L"), (1, "R")):
            tr[f"Wing{nm}"] = [track(L, lambda u, s=s: (0, 0, -s * (bias + amp * math.sin(TAU * u))), n)]
            tr[f"Wing{nm}2"] = [track(L, lambda u, s=s: (0, 0, -s * amp2 * math.sin(TAU * u - 0.9)), n)]
        return tr

    def legs(L, a):
        return {f"Leg{nm}": [track(L, lambda u, s=s: (a + 10 * math.sin(TAU * u + s), 0, 0), 8)] for s, nm in ((-1, "L"), (1, "R"))}

    L = 1.0
    idle = {**flap(L, 34, 20, 6), **legs(L, 10),
            "root": [track(L, lambda u: (0, 0.7 * math.sin(TAU * u - 1.4), 0), 16, "position")],
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u), 0, 6 * math.sin(TAU * u * 0.5)), 16)]}
    Lw = 0.6
    walk = {**flap(Lw, 40, 24, 4), **legs(Lw, 25),
            "root": [track(Lw, lambda u: (-6, 0, 0), 4), track(Lw, lambda u: (0, 0.8 * math.sin(TAU * u - 1.4), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (5, 0, 0), 4)]}
    Lg = 0.35
    gallop = {**flap(Lg, 48, 30, 0), **legs(Lg, 45),
              "root": [track(Lg, lambda u: (-12, 0, 0), 4), track(Lg, lambda u: (0, 1.0 * math.sin(TAU * u - 1.4), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (12, 0, 0), 4)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        H.gif(m, "Bat")
