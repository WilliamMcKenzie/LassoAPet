"""Bumblebee: World 3 Garden Uncommon flier (draft, Oct 14). A round, fuzzy bumblebee you ride
on its back: a fat body in sunny yellow and black bands with a tufted collar, a big black head
with googly eyes, pink cheeks and a little smile, bent antennae, a stubby stinger, six short legs
tucked under (the back pair carrying pollen baskets), and four pale blue wings that whirr.

Run: python3 tools/garden_bumblebee.py [--gif]
Bones (all rest 0): root (thorax) -> neck (head), Abdomen, WingFL/FR, WingBL/BR.
It hovers (gap 1.5 studs), like the Hawkmoth.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"yellow": (255, 196, 20), "yellowdark": (224, 146, 10), "black": (34, 28, 30), "fuzz": (255, 226, 120),
     "wing": (176, 226, 255), "wingrim": (90, 160, 214), "pink": (250, 120, 150), "pollen": (255, 140, 30),
     "white": (250, 246, 236)}


def build():
    g = Garden("Bumblebee", C)
    y0 = 4.0
    root = g.group("root", (0, y0, 0))
    # thorax: black with a fuzzy yellow collar and a tuft on top
    g.box(root, "Thorax", (0, y0, -0.6), (5.0, 4.4, 3.6), "black")
    g.box(root, "Collar", (0, y0 + 0.2, -2.3), (5.6, 4.8, 1.2), "yellow")
    g.box(root, "Tuft", (0, y0 + 2.5, -1.2), (3.0, 0.8, 2.4), "fuzz")
    # abdomen: fat, banded, tapering to a stubby stinger
    abd = g.group("Abdomen", (0, y0, 1.2), root)
    z = 1.2
    for k, (w, h, L, col) in enumerate(((6.4, 5.6, 1.6, "yellow"), (6.8, 6.0, 1.5, "black"), (6.6, 5.8, 1.5, "yellow"),
                                        (5.8, 5.0, 1.3, "black"), (4.4, 3.8, 1.1, "yellow"), (2.8, 2.4, 0.8, "black"))):
        g.box(abd, f"Band{k + 1}", (0, y0 + 0.2 - 0.12 * k, z + L / 2), (w, h, L + 0.04), col)
        z += L
    g.box(abd, "BandEdge", (0, y0 + 0.2, 1.2 + 0.9), (5.6, 6.3, 1.0), "yellowdark")
    g.spike(abd, "Stinger", (0, y0 - 0.5, z - 0.1), (0, -0.25, 1), 1.4, 0.45, "black")
    # head: big, black, googly eyes on the front, pink cheeks, smile, antennae
    neck = g.group("neck", (0, y0, -2.8), root)
    hz = -4.4
    g.box(neck, "Head", (0, y0 + 0.1, hz), (4.6, 4.0, 3.0), "black")
    g.box(neck, "Muzzle", (0, y0 - 0.9, hz - 1.6), (2.4, 1.2, 0.5), "black")
    g.box(neck, "Smile", (0, y0 - 1.1, hz - 1.88), (1.2, 0.25, 0.1), "white")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.1, y0 + 0.75, hz - 1.6), 1.6, look=(0, -0.1))
        g.box(neck, "Cheek" + side, (s * 1.75, y0 - 0.65, hz - 1.56), (0.9, 0.5, 0.15), "pink")
        base = np.array([s * 0.9, y0 + 2.0, hz - 0.6])
        d1 = np.array([s * 0.3, 1, -0.2])
        d1 /= np.linalg.norm(d1)
        g.box(neck, "Antenna" + side, base + d1 * 1.0, (0.4, 2.0, 0.4), "black", G.frame(d1))
        tip = base + d1 * 2.0
        d2 = np.array([s * 0.3, 0.2, -1])
        d2 /= np.linalg.norm(d2)
        g.box(neck, "Antenna" + side, tip + d2 * 0.75, (0.4, 1.5, 0.4), "black", G.frame(d2))
    # six short legs tucked under, the back pair with orange pollen baskets
    for side, s in (("L", -1), ("R", 1)):
        for k, zz in enumerate((-1.8, -0.4, 1.0)):
            M = Rm(("z", s * 20), ("x", 25 + 10 * k))
            d = M @ np.array([0, -1.0, 0])
            base = np.array([s * 1.6, y0 - 2.0, zz])
            g.box(root, f"Leg{side}{k + 1}", base + d * 0.9, (0.5, 1.8, 0.5), "black", M)
            if k == 2:
                g.box(root, f"Pollen{side}", base + d * 1.5, (1.0, 1.0, 1.0), "pollen", M)
    # wings: rounded paddles of three blocks with a darker rim; fore and hind
    for wname, pz, py, span, chord, sweep in (("WingF", -1.0, 2.3, 7.6, 4.2, 30), ("WingB", 0.8, 2.1, 5.4, 3.2, 50)):
        for side, s in (("L", -1), ("R", 1)):
            pivot = np.array([s * 1.6, y0 + py, pz])
            node = g.group(wname + side, pivot, root)
            M = Rm(("z", s * 10), ("y", -s * sweep))
            for k, (x, w, d) in enumerate(((span * 0.3, span * 0.6, chord), (span * 0.72, span * 0.36, chord * 0.82),
                                           (span * 0.95, span * 0.16, chord * 0.5))):
                g.box(node, f"{wname}{side}", pivot + M @ np.array([s * x, 0, chord * 0.1]), (w, 0.3, d), "wing", M)
            g.box(node, f"{wname}Rim{side}", pivot + M @ np.array([s * span * 0.5, 0.02, -chord * 0.45]),
                  (span, 0.34, 0.3), "wingrim", M)
    return g


def animations(m):
    def flap(L, amp, bias, beats, n):
        out = {}
        for w, ph, k in (("WingF", 0.0, 1.0), ("WingB", 0.5, 0.85)):
            for nm, s in (("R", 1), ("L", -1)):
                out[w + nm] = [track(L, lambda u, s=s, ph=ph, k=k: (0, 0, s * k * (bias + amp * sin(TAU * beats * u - ph))), n)]
        return out

    L = 1.0
    idle = {**flap(L, 30, 8, 6, 48),
            "root": [track(L, lambda u: (0, 5 * sin(TAU * u), 0), 16, "position")],
            "neck": [track(L, lambda u: (3 * sin(TAU * u), 6 * sin(TAU * u + 1), 0), 16)],
            "Abdomen": [track(L, lambda u: (5 * sin(TAU * u + 0.5), 0, 0), 16)]}
    Lw = 0.5
    walk = {**flap(Lw, 34, 8, 4, 32),
            "root": [track(Lw, lambda u: (-6, 0, 3 * sin(TAU * u)), 8), track(Lw, lambda u: (0, 4 * sin(TAU * u), 0), 16, "position")],
            "Abdomen": [track(Lw, lambda u: (6 * sin(TAU * u), 0, 0), 16)]}
    Lg = 0.4
    gallop = {**flap(Lg, 38, 10, 4, 32),
              "root": [track(Lg, lambda u: (-12, 0, 0), 4), track(Lg, lambda u: (0, 6 * sin(TAU * 2 * u), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (6, 0, 0), 4)],
              "Abdomen": [track(Lg, lambda u: (10 + 5 * sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


if __name__ == "__main__":
    m = build().finish(animations, gap=1.5)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/Bumblebee_anims.gif")
