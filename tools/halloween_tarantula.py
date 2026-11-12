"""Purple Tarantula: Halloween Haunted Hills Rare (draft, Oct 15). A big friendly tarantula: a round
purple abdomen with an orange stripe and a smaller head (faceted meshes: they're round), googly
eyes on the sides of the head, two orange fangs, and eight two-piece legs (orange thighs bending
up at the knee, dark purple shins).

Run: python3 tools/halloween_tarantula.py [--gif]
Bones (all rest 0): root -> neck, Abdomen, Leg{L,R}{1..4}.
"""

import sys

import numpy as np

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky, track, sin, TAU

C = {"fur": (124, 58, 190), "furdark": (82, 34, 130), "orange": (255, 140, 30)}


def build():
    g = Spooky("PurpleTarantula", C)
    y0 = 4.2
    root = g.group("root", (0, y0, 0))
    g.hull(root, "Thorax", G.ellipsoid((0, y0, -0.6), (2.6, 1.6, 2.4), seg=8, rings=4), "fur")
    ab = g.group("Abdomen", (0, y0 + 0.4, 1.4), root)
    g.hull(ab, "Abdomen", G.ellipsoid((0, y0 + 1.0, 4.0), (3.0, 2.6, 3.2), seg=10, rings=4), "fur")
    g.hull(ab, "Stripe", G.ellipsoid((0, y0 + 1.1, 4.0), (1.0, 2.7, 3.3), seg=8, rings=4), "orange")
    neck = g.group("neck", (0, y0, -2.6), root)
    hy, hz = y0 + 0.2, -3.4
    g.hull(neck, "Head", G.ellipsoid((0, hy, hz), (1.8, 1.4, 1.5), seg=8, rings=4), "furdark")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.55, hy + 0.35, hz - 0.4), 1.0, normal=(s, 0.2, -0.5))
        g.pyr(neck, "Fang" + side, (s * 0.5, hy - 0.9, hz - 1.0), (0, -1, -0.2), 1.0, 0.3, 0.3, "orange")
    for side, s in (("L", -1), ("R", 1)):
        for k, (z, yaw) in enumerate(((-2.0, -35), (-1.0, -12), (0.0, 12), (1.0, 35))):
            b = f"Leg{side}{k + 1}"
            hip = np.array([s * 1.8, y0, z])
            leg = g.group(b, hip, root)
            a = np.radians(yaw)
            out = np.array([s * np.cos(a), 0, np.sin(a)])
            knee = hip + out * 3.4 + (0, 1.8, 0)
            foot = knee + out * 1.6 + (0, -y0 - 1.8, 0)
            for nm, p, q, col in (("Thigh", hip, knee, "orange"), ("Shin", knee, foot, "furdark")):
                d = q - p
                g.box(leg, b + nm, (p + q) / 2, (0.8, np.linalg.norm(d) + 0.4, 0.8), col, G.frame(d))
    return g


def animations(m):
    pairs = [("L1", 0), ("R2", 0), ("L3", 0), ("R4", 0), ("R1", 0.5), ("L2", 0.5), ("R3", 0.5), ("L4", 0.5)]

    def scuttle(L, swing, lift, lean, n=16):
        tr = {f"Leg{b}": [track(L, lambda u, ph=ph: (6 * sin(TAU * (u + ph + 0.25)), swing * sin(TAU * (u + ph)), 0), n)]
              for b, ph in pairs}
        tr["root"] = [track(L, lambda u: (lean, 0, 2 * sin(TAU * u)), n),
                      track(L, lambda u: (0, lift * abs(sin(TAU * u)), 0), n, "position")]
        tr["Abdomen"] = [track(L, lambda u: (4 * sin(TAU * u), 3 * sin(TAU * u), 0), n)]
        return tr

    L = 3.0
    idle = {"neck": [track(L, lambda u: (4 * sin(TAU * u), 8 * sin(TAU * u + 1), 0), 24)],
            "Abdomen": [track(L, lambda u: (3 * sin(TAU * u), 0, 0), 24)],
            "LegL1": [track(L, lambda u: (8 * sin(TAU * 2 * u), 0, 0), 24)],
            "LegR1": [track(L, lambda u: (-8 * sin(TAU * 2 * u), 0, 0), 24)],
            "root": [track(L, lambda u: (0, 1.2 * sin(TAU * u), 0), 24, "position")]}
    return {"idle": (L, idle), "walk": (0.6, scuttle(0.6, 18, 1.5, 0)), "gallop": (0.36, scuttle(0.36, 26, 3, -4))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        H.gif(m, "PurpleTarantula")
