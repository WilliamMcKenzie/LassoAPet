"""Ancient Treant: World 3 Garden giga rare (draft, Oct 14; about 1 in 1,000). A towering old tree
that walks: a thick trunk of stacked bark blocks with darker ridges, a face in the bark (deep
sockets with big googly eyes, a knotted nose, a wide mossy beard), shelf mushrooms and moss patches
up its sides, branch arms ending in forked twig fingers (pyramid tips), two huge root legs with
splayed pyramid roots, and a vast layered canopy dotted with pink blossoms. Ridden on the canopy.
Same family as the Living Birch and Palm Guy, just ancient and enormous.

Run: python3 tools/garden_treant.py [--gif]
Bones (all rest 0): root -> neck (canopy), ArmL/ArmR, LegL/LegR.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"bark": (126, 84, 52), "barkdark": (84, 54, 36), "barklight": (160, 112, 70), "socket": (44, 28, 22),
     "moss": (96, 170, 60), "mossdark": (56, 120, 44), "leaf": (60, 160, 60), "leafdark": (34, 112, 46),
     "leaflight": (120, 200, 70), "blossom": (255, 140, 190), "blossomdark": (220, 80, 150),
     "shroom": (240, 132, 40), "shroomdark": (190, 90, 30)}


def build():
    g = Garden("AncientTreant", C)
    y0 = 14.0
    root = g.group("root", (0, y0, 0))
    # trunk: four stacked blocks, ridges down every face
    y = 5.0
    for i, (w, d, h) in enumerate(((12.0, 9.0, 3.2), (11.4, 8.6, 3.4), (10.8, 8.2, 3.4), (10.2, 7.8, 3.4), (9.6, 7.4, 3.6))):
        g.box(root, "Trunk", (0, y + h / 2, 0), (w, h + 0.05, d), "bark" if i % 2 == 0 else "barklight")
        for k, x in enumerate((-w * 0.3, w * 0.05, w * 0.36)):
            g.box(root, "Ridge", (x, y + h / 2, -d / 2 - 0.15), (0.7, h - 0.4 * (k % 2), 0.3), "barkdark")
            g.box(root, "RidgeB", (x * 0.9, y + h / 2, d / 2 + 0.15), (0.7, h - 0.3, 0.3), "barkdark")
        for s in (-1, 1):
            g.box(root, "RidgeS", (s * (w / 2 + 0.15), y + h / 2, (i % 2 - 0.5) * 2.0), (0.3, h - 0.4, 0.7), "barkdark")
        y += h
    top = y
    # face on the upper trunk: sockets, eyes, a knot nose, brows
    fz = -3.7 - 0.2
    for side, s in (("L", -1), ("R", 1)):
        g.box(root, "Socket" + side, (s * 2.2, top - 2.2, fz), (3.2, 2.8, 0.4), "socket")
        g.eye(root, side, (s * 2.2, top - 2.2, fz - 0.25), 2.4, look=(0, -0.1))
        g.box(root, "Brow" + side, (s * 2.3, top - 0.45, fz - 0.4), (3.8, 0.9, 0.9), "barkdark", Rm(("z", s * 12)))
    g.box(root, "Nose", (0, top - 3.6, fz - 0.6), (1.4, 1.8, 1.2), "barklight")
    g.box(root, "Mouth", (0, top - 5.4, fz), (3.6, 0.8, 0.4), "socket")
    # mossy beard hanging from under the mouth
    for k, (x, h) in enumerate(((-2.6, 3.0), (-1.3, 4.2), (0.0, 5.0), (1.3, 4.0), (2.6, 2.8))):
        g.box(root, "Beard", (x, top - 6.0 - h / 2, fz - 0.5), (1.4, h, 1.0), "moss" if k % 2 == 0 else "mossdark")
        g.pyr(root, "BeardTip", (x, top - 6.0 - h, fz - 0.5), (0, -1, 0), 1.0, 0.7, 0.5, "moss" if k % 2 == 0 else "mossdark")
    # moss patches and shelf mushrooms up the sides and back
    for (x, yy, z, sz, col) in ((5.9, 7.6, 1.6, (0.6, 2.2, 3.0), "moss"), (-5.3, 15.0, -1.4, (0.6, 1.8, 2.4), "moss"),
                                (2.6, 10.0, 4.4, (3.0, 2.0, 0.6), "mossdark"), (-1.8, 17.4, 4.0, (3.4, 1.6, 0.6), "moss")):
        g.box(root, "Moss", (x, yy, z), sz, col)
    for (x, yy, z, s) in ((-5.6, 9.6, 1.0, -1), (-5.5, 10.8, 2.6, -1), (5.3, 14.4, -1.0, 1), (3.4, 12.4, 4.2, 0)):
        if s:
            g.box(root, "Shroom", (x + s * 0.8, yy, z), (1.8, 0.5, 2.0), "shroom")
            g.box(root, "ShroomRim", (x + s * 0.8, yy - 0.35, z), (1.6, 0.3, 1.8), "shroomdark")
        else:
            g.box(root, "Shroom", (x, yy, z + 0.8), (2.0, 0.5, 1.8), "shroom")
    # legs: massive root columns with splayed pyramid roots
    for side, s in (("L", -1), ("R", 1)):
        leg = g.group("Leg" + side, (s * 3.0, 5.0, 0), root)
        g.box(leg, "Leg" + side, (s * 3.0, 3.0, 0), (4.6, 4.6, 4.6), "bark")
        g.box(leg, "LegRidge" + side, (s * 3.0, 3.0, -2.45), (0.7, 3.6, 0.3), "barkdark")
        g.box(leg, "Foot" + side, (s * 3.0, 0.7, -0.4), (5.6, 1.4, 6.0), "barkdark")
        for k, (dx, dz) in enumerate(((-0.6, -1), (0.0, -1), (0.6, -1), (s * 1.0, 0.1), (0.0, 1.0))):
            d = np.array([dx, -0.15, dz])
            g.pyr(leg, "Root" + side, (s * 3.0 + dx * 2.0, 0.6, -0.4 + dz * 2.7), d, 2.4, 0.6, 0.5, "barkdark")
    # arms: branches out and down, forked twig fingers, leaf tufts on the shoulders
    for side, s in (("L", -1), ("R", 1)):
        arm = g.group("Arm" + side, (s * 4.8, top - 1.6, 0), root)
        sh = np.array([s * 4.8, top - 1.6, 0])
        d1 = np.array([s * 1.0, -0.3, -0.1]) / np.linalg.norm([s, -0.3, -0.1])
        g.box(arm, "UpperArm" + side, sh + d1 * 2.8, (3.0, 5.6, 3.0), "bark", G.frame(d1))
        el = sh + d1 * 5.4
        d2 = np.array([s * 0.2, -1, -0.25]) / np.linalg.norm([s * 0.2, -1, -0.25])
        g.box(arm, "Forearm" + side, el + d2 * 3.2, (2.6, 6.4, 2.6), "barklight", G.frame(d2))
        hand = el + d2 * 6.2
        g.box(arm, "Hand" + side, hand, (3.2, 1.8, 3.2), "bark")
        for k, dd in enumerate(((-0.5, -1, -0.4), (0.0, -1, -0.8), (0.5, -1, -0.4), (s * 0.9, -0.6, 0.2))):
            g.spike(arm, "Twig" + side, hand + np.array(dd) * 0.8, dd, 1.2, 0.3, "barkdark", shaft=1.2)
        g.box(arm, "ElbowTwig" + side, el + (0, 1.2, 0), (0.6, 2.4, 0.6), "barkdark", Rm(("z", -s * 20)))
        g.box(arm, "ElbowLeaf" + side, el + (s * -0.4, 2.6, 0), (2.0, 1.2, 1.8), "leaflight")
        for k, (dx, dy, dz) in enumerate(((0.4, 1.6, -0.6), (1.6, 1.2, 0.8), (-0.2, 1.4, 1.4))):
            g.box(arm, "ShoulderLeaf" + side, sh + (s * dx, dy, dz), (3.0, 1.6, 2.6), "leaf" if k % 2 else "leafdark")
    # canopy: a broad layered crown, clumps round it, blossoms dotted on top and sides
    neck = g.group("neck", (0, top, 0), root)
    c = top + 1.0
    for name, lo, hi, col in [
            ("Crown", (-5.0, c - 1.0, -4.4), (5.0, c + 1.2, 4.4), "barkdark"),
            ("LeavesLow", (-8.0, c + 0.8, -6.6), (8.0, c + 3.6, 6.6), "leafdark"),
            ("Leaves", (-9.4, c + 3.2, -7.8), (9.4, c + 7.2, 7.8), "leaf"),
            ("LeavesMid", (-7.6, c + 6.8, -6.2), (7.6, c + 9.6, 6.2), "leaf"),
            ("LeavesTop", (-4.6, c + 9.2, -4.0), (4.6, c + 11.0, 4.0), "leaflight"),
            ("ClumpFL", (-10.4, c + 4.4, -8.6), (-5.6, c + 8.4, -4.4), "leaflight"),
            ("ClumpFR", (5.0, c + 2.2, -9.0), (9.8, c + 6.0, -4.6), "leafdark"),
            ("ClumpBL", (-9.8, c + 2.4, 4.0), (-5.2, c + 6.2, 8.6), "leafdark"),
            ("ClumpBR", (5.4, c + 5.0, 3.6), (10.2, c + 9.2, 8.4), "leaflight"),
            ("ClumpL", (-11.0, c + 6.4, -1.6), (-7.0, c + 9.6, 2.4), "leafdark"),
            ("ClumpR", (7.0, c + 7.0, -2.8), (10.8, c + 10.0, 1.2), "leaflight"),
            ("ClumpTop", (-1.0, c + 10.6, -1.4), (3.0, c + 12.4, 2.6), "leaf"),
            ("ClumpTopB", (-4.0, c + 10.4, 0.8), (-0.8, c + 11.8, 4.2), "leafdark"),
            ("ClumpF", (-3.0, c + 4.0, -9.4), (3.4, c + 7.4, -7.0), "leaflight")]:
        lo, hi = np.array(lo), np.array(hi)
        g.box(neck, name, (lo + hi) / 2, hi - lo, col)
    for k, (x, yy, z) in enumerate(((-6.0, 7.4, -7.0), (2.0, 7.6, -8.2), (7.0, 6.2, -4.8), (-9.6, 5.0, 2.0), (9.6, 8.2, 3.0),
                                    (-3.0, 9.8, -4.4), (3.2, 9.8, 3.0), (0.6, 12.6, 0.6), (-8.4, 8.4, -4.2), (6.8, 3.6, 6.8),
                                    (-6.0, 4.4, 7.0), (5.6, 9.8, -3.6), (-2.4, 11.3, 2.6), (0.0, 6.0, 8.0))):
        g.box(neck, "Blossom", (x, c + yy, z), (2.0, 2.0, 2.0), "blossom" if k % 3 else "blossomdark", Rm(("y", 45)))
    return g


def animations(m):
    def stride(L, swing, arms, lean, hop, n=16):
        return {"root": [track(L, lambda u: (lean, 2 * sin(TAU * u), 3 * sin(TAU * u)), n),
                         track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")],
                "LegL": [track(L, lambda u: (-lean + swing * sin(TAU * u), 0, 0), n)],
                "LegR": [track(L, lambda u: (-lean - swing * sin(TAU * u), 0, 0), n)],
                "ArmL": [track(L, lambda u: (-arms * sin(TAU * u), 0, 0), n)],
                "ArmR": [track(L, lambda u: (arms * sin(TAU * u), 0, 0), n)],
                "neck": [track(L, lambda u: (-lean * 0.4 + 2 * sin(2 * TAU * u), 0, -2 * sin(TAU * u)), n)]}

    L = 5.0
    idle = {"neck": [track(L, lambda u: (2 * sin(TAU * u), 3 * sin(TAU * u), 3 * sin(TAU * u + 0.7)), 24)],
            "ArmL": [track(L, lambda u: (3 * sin(TAU * u), 0, -4 * sin(TAU * u)), 24)],
            "ArmR": [track(L, lambda u: (-3 * sin(TAU * u), 0, 4 * sin(TAU * u)), 24)],
            "root": [track(L, lambda u: (0, 0, 1.5 * sin(TAU * u)), 24)]}
    return {"idle": (L, idle), "walk": (1.4, stride(1.4, 18, 16, 0, 4)), "gallop": (0.9, stride(0.9, 30, 30, 8, 12))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/AncientTreant_anims.gif")
