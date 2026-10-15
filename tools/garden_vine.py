"""Vine Monster: World 3 Garden Rare (draft, Oct 14; redone cleaner Oct 15). A gorilla-shaped knot of living vines that
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


def helix(x, z, y_lo, y_hi, r, turns, phase, n_per_turn=8):
    """Points of a vine spiralling up round a vertical limb at (x, z), then curling out at the top."""
    n = int(turns * n_per_turn) + 1
    pts = []
    for k in range(n):
        u = k / (n - 1)
        a = TAU * (phase + turns * u)
        pts.append((x + r * np.sin(a), y_lo + (y_hi - y_lo) * u, z + r * np.cos(a)))
    a = TAU * (phase + turns)
    out = np.array([np.sin(a), 0, np.cos(a)])
    side = np.array([np.cos(a), 0, -np.sin(a)])
    end = np.array(pts[-1])
    for k, (o, up, sd) in enumerate(((0.7, 0.4, 0.3), (1.3, 1.0, 0.3), (1.5, 1.6, -0.2))):
        pts.append(end + out * o + (0, up, 0) + side * sd)
    return pts


def build():
    """Cleaner (QM Oct 15: "redo vine monster to be cleaner, and use mesh where needed"): a plain
    block gorilla (chest, hips, hunched head, thick forearms, fists), with meshes only for the
    curved things: smooth vines spiralling up the arms, leaf shoulder pads and the rose."""
    g = Garden("VineMonster", C)
    y0 = 5.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Chest", (0, y0 + 2.2, -0.6), (7.2, 4.4, 4.8), "vine")
    g.box(root, "ChestPlate", (0, y0 + 1.6, -3.1), (4.6, 2.8, 0.2), "vinelight")
    g.box(root, "Hips", (0, y0 - 0.6, 1.0), (5.0, 2.4, 4.0), "vinedark")
    # back thorns down the spine
    for k, (yy, zz) in enumerate(((y0 + 4.4, 0.2), (y0 + 3.6, 1.8), (y0 + 2.0, 1.8))):
        d = (0, 1, 0.5) if k == 0 else (0, 0.4, 1)
        g.pyr(root, "Thorn", (0, yy, zz), d, 1.4 - 0.2 * k, 0.45, 0.45, "thorn")
    # leaf shoulder pads: three leaves fanned over each shoulder
    for side, s in (("L", -1), ("R", 1)):
        for k, (dz, ang) in enumerate(((-1.6, -35), (-0.4, 0), (0.8, 35))):
            a = np.radians(ang)
            d = np.array([s * np.cos(a), -0.35, np.sin(a)])
            g.hull(root, "SmoothLeaf", G.leaf((s * 2.6, y0 + 4.5, dz), d, (0, 1, 0), 3.8, 2.4), "leaf")
    # head: hunched forward between the shoulders, heavy brows, a muzzle full of thorn teeth
    neck = g.group("neck", (0, y0 + 3.4, -2.6), root)
    hy, hz = y0 + 3.8, -3.6
    g.box(neck, "Head", (0, hy, hz), (4.4, 3.6, 3.6), "vine")
    g.box(neck, "Muzzle", (0, hy - 0.9, hz - 2.2), (3.4, 1.8, 0.8), "vinelight")
    g.box(neck, "Mouth", (0, hy - 1.05, hz - 2.65), (2.6, 0.9, 0.1), "mouth")
    for t in (-0.9, -0.3, 0.3, 0.9):
        g.pyr(neck, "Tooth", (t, hy - 0.62, hz - 2.72), (0, -1, 0), 0.55, 0.22, 0.05, "tooth")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.0, hy + 0.55, hz - 1.9), 1.2, look=(0, -0.05))
        g.box(neck, "Brow" + side, (s * 1.05, hy + 1.3, hz - 2.0), (2.0, 0.6, 0.8), "vinedark", Rm(("z", s * 14)))
    # the rose on top: a bud and two rings of cupped petals, two leaves under it
    rc, k_ = np.array([0.7, hy + 1.8, hz + 0.3]), 1.4
    g.hull(neck, "SmoothRoseBud", G.ellipsoid(rc + (0, 1.0 * k_, 0), np.array((0.6, 0.8, 0.6)) * k_, seg=8, rings=4), "rosedark")
    for ring_i, (n, rad, h, tilt, col, off) in enumerate(((5, 0.75, 0.9, 25, "rosedark", 0.5), (5, 1.0, 0.7, 45, "rose", 0.0))):
        rad, h = rad * k_, h * k_
        for k in range(n):
            a = TAU * (k + off) / n
            out = np.array([np.sin(a), 0, np.cos(a)])
            M = G.frame(out * np.sin(np.radians(tilt)) + (0, np.cos(np.radians(tilt)), 0))
            pc = rc + out * rad + (0, h, 0)
            g.hull(neck, "SmoothRose", G.ellipsoid(pc, np.array((0.75, 0.75, 0.22)) * k_, seg=8, rings=3, M=M @ Rm(("x", 90))), col)
    for side, s in (("L", -1), ("R", 1)):
        g.hull(neck, "SmoothRoseLeaf", G.leaf(rc + (s * 0.6, 0.15, 0), (s, -0.15, 0.2), (0, 1, 0), 2.4, 1.3, 0.18), "leaf")
    # arms: to the ground, thick forearms, big knotted fists with thorns, a vine spiralling up each
    for side, s in (("L", -1), ("R", 1)):
        arm = g.group("Arm" + side, (s * 4.0, y0 + 3.6, -0.8), root)
        ax, az = s * 4.6, -1.0
        g.box(arm, "Arm" + side, (ax, y0 + 2.4, az), (2.4, 3.2, 2.4), "vine")
        g.box(arm, "Forearm" + side, (ax, 4.0, az - 0.2), (2.8, 3.6, 2.8), "vinemid")
        g.box(arm, "Fist" + side, (ax, 1.1, az - 0.4), (3.0, 2.2, 3.0), "vinedark")
        g.pyr(arm, "FistThorn" + side, (ax + s * 1.5, 1.5, az - 0.4), (s, 0.3, 0), 1.0, 0.35, 0.35, "thorn")
        g.pyr(arm, "FistThorn" + side, (ax, 2.2, az - 1.3), (0, 1, -0.4), 0.9, 0.3, 0.3, "thorn")
        path = helix(ax, az - 0.1, 2.3, y0 + 2.6, 1.75, 1.6, 0.15 if s > 0 else 0.65)
        radii = [0.38] * (len(path) - 3) + [0.32, 0.24, 0.0]
        G.tube(g, arm, "SmoothVine" + side, path, radii, "vinelight")
    # legs: short thick roots
    for side, s in (("L", -1), ("R", 1)):
        leg = g.group("Leg" + side, (s * 1.6, y0 - 1.6, 1.2), root)
        g.box(leg, "Leg" + side, (s * 1.6, (y0 - 1.2 + 0.7) / 2, 1.2), (2.2, y0 - 1.9, 2.2), "bark")
        g.box(leg, "Foot" + side, (s * 1.7, 0.35, 0.8), (2.8, 0.7, 3.0), "bark")
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
