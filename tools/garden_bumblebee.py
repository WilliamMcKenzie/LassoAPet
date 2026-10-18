"""DON'T RERUN: QM edited designs/garden/<this animal>.bbmodel by hand in Blockbench (Oct 15), which is now
the source; this would overwrite it. Convert that file instead.

Bumblebee: World 3 Garden Uncommon flier (draft, Oct 14). A round, fuzzy bumblebee you ride
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
    # round body as low-poly meshes (QM Oct 14: meshes where blocks faked a curve): a black thorax
    # with a yellow collar, and a fat abdomen in yellow and black bands meeting flush
    for k, pts in enumerate(G.bands((0, y0, -0.5), (3.1, 2.9, 2.7), [-2.7, -1.5, 0.0, 1.4, 2.7], seg=16)):
        g.hull(root, f"SmoothThorax{k + 1}", pts, "yellow" if k == 0 else "black")
    abd = g.group("Abdomen", (0, y0, 1.2), root)
    # (the first yellow band shows right behind the thorax, so the black head, thorax and
    # first black band don't run together)
    cuts = [-4.2, -1.9, -0.6, 0.6, 1.8, 3.0, 4.2]
    for k, pts in enumerate(G.bands((0, y0 + 0.1, 5.1), (3.5, 3.1, 4.2), cuts, seg=16)):
        g.hull(abd, f"SmoothBand{k + 1}", pts, "yellow" if k % 2 == 0 else "black")
    g.spike(abd, "Stinger", (0, y0, 9.1), (0, -0.25, 1), 1.4, 0.45, "black")
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
    # wings: flat oval paddles (one mesh each), fore and hind
    for wname, pz, py, span, chord, sweep in (("WingF", -1.0, 2.3, 7.6, 4.2, 30), ("WingB", 0.8, 2.1, 5.4, 3.2, 50)):
        for side, s in (("L", -1), ("R", 1)):
            pivot = np.array([s * 1.6, y0 + py, pz])
            node = g.group(wname + side, pivot, root)
            M = Rm(("z", s * 10), ("y", -s * sweep))
            oval = [pivot + M @ np.array([s * span * (0.5 + 0.5 * np.cos(a)), t, chord * (0.1 + 0.5 * np.sin(a))])
                    for a in np.linspace(0, TAU, 12, endpoint=False) for t in (-0.22, 0.22)]
            g.hull(node, f"{wname}{side}", oval, "wing")
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
