"""Vine Monster: World 3 Garden Rare (draft, Oct 14). A gorilla-shaped knot of living vines that
knuckle-walks: a barrel chest of twisted vine coils (each block turned a little against the next),
leafy shoulder pads, long dangling arms of braided vine ending in big knotted fists with thorns, two
stumpy root legs, a row of red-brown thorns down its back, and a vine-knot head with googly eyes
under grumpy brows, a wide mouth of pale thorn teeth, and a pink rose blooming on top.

Run: python3 tools/garden_vine.py [--gif]
Bones (all rest 0): root -> neck, ArmL/ArmR, LegL/LegR.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"vine": (64, 192, 64), "vinedark": (30, 116, 46), "vinelight": (150, 226, 70), "vinemid": (96, 210, 70), "leaf": (124, 214, 60),
     "thorn": (150, 64, 40), "tooth": (246, 236, 200), "mouth": (40, 18, 24), "rose": (250, 84, 140),
     "rosedark": (198, 30, 92), "bark": (110, 70, 44)}


def coil(g, node, name, c, w, h, d, twist, cols=("vine", "vinemid")):
    """A twisted vine coil: two overlapping blocks turned +-twist about Y (strands 0.25 narrower)."""
    g.box(node, name, c, (w, h, d), cols[0], Rm(("y", twist)))
    g.box(node, name + "B", np.array(c) + (0, 0.05, 0), (w - 0.25, h - 0.1, d - 0.25), cols[1], Rm(("y", -twist)))


def tendril(g, node, name, axis_x, axis_z, y_lo, y_hi, r, turns=1.25, phase=0.0, col="vinelight"):
    """A chunky tendril spiralling round a vertical limb: blocks stepping round the axis as they climb,
    each turned to follow the curl, ending in a curled tip (a pyramid) poking out."""
    n = max(4, int(turns * 6))
    for k in range(n):
        u = k / (n - 1)
        a = TAU * (phase + turns * u)
        y = y_lo + (y_hi - y_lo) * u
        p = (axis_x + r * np.sin(a), y, axis_z + r * np.cos(a))
        g.box(node, name, p, (0.7, 0.7, 1.4), col, Rm(("y", np.degrees(a) + 90), ("x", -20)))
    a = TAU * (phase + turns)
    out = np.array([np.sin(a), 0.6, np.cos(a)])
    g.pyr(node, name + "Tip", (axis_x + r * np.sin(a), y_hi + 0.3, axis_z + r * np.cos(a)), out, 1.2, 0.35, 0.35, col)


def build():
    g = Garden("VineMonster", C)
    y0 = 5.0
    root = g.group("root", (0, y0, 0))
    # chest: three coils, the top one widest (gorilla shoulders), leaning forward
    for k, (yy, w, h, d, tw) in enumerate(((y0 - 0.6, 5.0, 2.2, 4.4, 12), (y0 + 1.4, 6.4, 2.2, 5.0, -14),
                                           (y0 + 3.2, 7.6, 2.0, 5.2, 10))):
        coil(g, root, f"Coil{k + 1}", (0, yy, -0.4 * k), w, h, d, tw)
    g.box(root, "Hips", (0, y0 - 1.6, 0.8), (4.6, 1.6, 3.6), "vinedark")
    # leafy shoulder pads
    for side, s in (("L", -1), ("R", 1)):
        for k, (dx, dz, tilt) in enumerate(((3.6, -1.4, 20), (3.9, 0.4, 28), (3.4, 1.8, 16))):
            g.box(root, f"Leaf{side}", (s * dx, y0 + 4.4, dz - 0.8), (2.8, 0.4, 1.8), "leaf" if k != 1 else "vinelight",
                  Rm(("z", -s * tilt), ("y", s * 15 * (k - 1))))
    # back thorns, a row down the spine
    for k, (yy, zz) in enumerate(((y0 + 4.1, 0.6), (y0 + 3.0, 2.1), (y0 + 1.6, 2.6), (y0 + 0.0, 2.4))):
        g.spike(root, "Thorn", (0, yy, zz), (0, 0.5, 1), 1.4 - 0.15 * k, 0.45, "thorn")
    # head: a vine knot, rose on top, brows, thorn teeth
    neck = g.group("neck", (0, y0 + 4.0, -1.6), root)
    hy, hz = y0 + 5.0, -2.6
    coil(g, neck, "Head", (0, hy, hz), 4.4, 3.4, 3.6, 8)
    g.box(neck, "Brow", (0, hy + 0.9, hz - 1.9), (4.2, 0.6, 0.8), "vinedark")
    g.box(neck, "Mouth", (0, hy - 0.9, hz - 1.82), (3.2, 1.0, 0.2), "mouth")
    for t in (-1.2, -0.4, 0.4, 1.2):
        g.pyr(neck, "Tooth", (t, hy - 0.45, hz - 1.95), (0, -1, 0), 0.6, 0.25, 0.1, "tooth")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.0, hy + 0.15, hz - 1.92), 1.3, look=(0, 0))
        g.box(neck, "BrowTilt" + side, (s * 1.0, hy + 0.95, hz - 2.25), (1.6, 0.4, 0.3), "vinedark", Rm(("z", s * 18)))
    # the rose: a stem knot and three rings of petals, darkest in the middle
    ry = hy + 1.9
    g.box(neck, "RoseBase", (0.6, ry, hz + 0.2), (1.6, 0.6, 1.6), "vinelight")
    for ring, (rad, tilt, sz, col, off) in enumerate(((1.3, -50, (1.9, 1.6, 0.4), "rose", 0), (0.7, -25, (1.3, 1.5, 0.4), "rosedark", 36))):
        for ang in range(off, 360 + off, 72):
            a = np.radians(ang)
            g.box(neck, "Petal", (0.6 + rad * np.sin(a), ry + 0.9 + 0.2 * ring, hz + 0.2 + rad * np.cos(a)), sz, col,
                  Rm(("y", ang), ("x", tilt)))
    g.box(neck, "RoseMid", (0.6, ry + 1.1, hz + 0.2), (0.9, 1.4, 0.9), "rosedark", Rm(("y", 45)))
    for side, s in (("L", -1), ("R", 1)):
        g.box(neck, "RoseLeaf" + side, (0.6 + s * 1.5, ry + 0.2, hz + 0.6), (1.8, 0.3, 1.0), "leaf", Rm(("z", -s * 15)))
    # arms: long braided vines to the ground, knotted fists with thorns
    for side, s in (("L", -1), ("R", 1)):
        arm = g.group("Arm" + side, (s * 4.0, y0 + 3.6, -0.8), root)
        ax = s * 4.6
        for k, (yy, h, tw) in enumerate(((y0 + 2.2, 3.4, 15), (y0 - 0.9, 3.2, -15))):
            coil(g, arm, f"Arm{side}{k + 1}", (ax, yy, -1.0 - 0.3 * k), 1.8, h, 1.8, tw)
        g.box(arm, "Fist" + side, (ax, 1.1, -1.8), (2.6, 2.2, 2.6), "vinedark")
        g.box(arm, "Knuckle" + side, (ax, 1.3, -3.15), (2.4, 1.2, 0.3), "vine")
        g.spike(arm, "FistThorn" + side, (ax + s * 1.3, 1.6, -1.8), (s, 0.3, 0), 1.0, 0.35, "thorn")
        g.spike(arm, "FistThorn" + side, (ax, 2.2, -2.2), (0, 1, -0.3), 0.9, 0.3, "thorn")
        tendril(g, arm, "Tendril" + side, ax, -1.15, 2.4, y0 + 3.4, 1.15, turns=1.5, phase=0.1 if s > 0 else 0.6)
    # root legs: short and thick
    for side, s in (("L", -1), ("R", 1)):
        leg = g.group("Leg" + side, (s * 1.5, y0 - 1.8, 1.0), root)
        coil(g, leg, "Leg" + side, (s * 1.6, (y0 - 1.8) / 2, 1.0), 1.9, y0 - 1.8, 1.9, 12, ("bark", "vinedark"))
        g.box(leg, "Foot" + side, (s * 1.7, 0.35, 0.5), (2.4, 0.7, 2.8), "bark")
        tendril(g, leg, "LegTendril" + side, s * 1.6, 1.0, 1.0, y0 - 2.2, 1.2, turns=1.0, phase=0.3 if s > 0 else 0.8)
    return g


def animations(m):
    def knuckle(L, swing, lean, hop, n=16):
        return {"root": [track(L, lambda u: (lean, 0, 3 * sin(TAU * u)), n),
                         track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")],
                "ArmL": [track(L, lambda u: (-swing * sin(TAU * u), 0, 0), n)],
                "ArmR": [track(L, lambda u: (swing * sin(TAU * u), 0, 0), n)],
                "LegL": [track(L, lambda u: (swing * 0.7 * sin(TAU * u), 0, 0), n)],
                "LegR": [track(L, lambda u: (-swing * 0.7 * sin(TAU * u), 0, 0), n)],
                "neck": [track(L, lambda u: (4 * sin(2 * TAU * u), 0, -3 * sin(TAU * u)), n)]}

    L = 3.0
    idle = {"root": [track(L, lambda u: (0, 0, 2 * sin(TAU * u)), 24),
                     track(L, lambda u: (0, 2 * sin(TAU * 2 * u), 0), 24, "position")],
            "neck": [track(L, lambda u: (3 * sin(TAU * u), 10 * sin(TAU * u), 0), 24)],
            "ArmL": [track(L, lambda u: (4 * sin(TAU * u), 0, 0), 24)],
            "ArmR": [track(L, lambda u: (-4 * sin(TAU * u), 0, 0), 24)]}
    return {"idle": (L, idle), "walk": (0.8, knuckle(0.8, 22, 4, 3)), "gallop": (0.5, knuckle(0.5, 40, 12, 8))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/VineMonster_anims.gif")
