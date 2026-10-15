"""Sunflower Lion: World 3 Garden Legendary (draft, Oct 14; made majestic Oct 15). A golden lion whose mane is a giant
sunflower wrapped round its head: a seed-brown collar and three layers of pyramid petals (sunny
yellow out round the face, deeper gold out-and-back, yellow again sweeping back over the neck), so
it reads as a flower from every side. Hefty, with a big head and big paws. Meadow-style blocky body (the Meadow animals are the style
guide), cream muzzle, side plate eyes, little round ears, green leaf cuffs above its paws, and a
long stem tail ending in a small sunflower.

Run: python3 tools/garden_lion.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"fur": (228, 146, 58), "furdark": (176, 96, 34), "cream": (252, 232, 176), "nose": (88, 48, 36),
     "petal": (255, 214, 30), "petaldark": (246, 156, 20), "seed": (96, 56, 30), "seeddark": (56, 32, 22),
     "leaf": (70, 176, 52), "leafdark": (36, 120, 40)}


def sunflower(g, node, name, c, n, r, petals, L, W, back=(0.25, 0.45)):
    """A sunflower facing along n (unit) centred on c: a studded seed disc (a darker middle) and two
    rings of smooth pointed petals, the front ring yellow, the back ring gold and longer, each tilted
    back a little (the flower cups)."""
    c, n = np.array(c, float), np.array(n, float)
    M = G.frame(n)
    up, across = M @ (0, 0, 1.0), M @ (1.0, 0, 0)
    g.hull(node, name + "Disc", G.prism(c - n * 0.6, r, 1.0, seg=14, top=0.9, M=M), "seed")
    g.hull(node, name + "DiscMid", G.prism(c + n * 0.35, r * 0.55, 0.25, seg=10, M=M), "seeddark")
    for layer, (col, off, Lk, Wk, tilt, dz) in enumerate((("petal", 0.0, 1.0, 1.0, back[0], -0.05),
                                                         ("petaldark", 0.5, 1.15, 1.1, back[1], -0.45))):
        for k in range(petals):
            a = TAU * (k + off) / petals
            rad = across * np.cos(a) + up * np.sin(a)
            d = rad - n * tilt
            g.hull(node, "Smooth" + name + ("Petal" if layer == 0 else "PetalBack"),
                   G.leaf(c + rad * (r - 0.4) + n * dz, d, n, L * Lk, W * Wk, 0.2), col)


def build():
    """Majestic (QM Oct 15: "make sunflower lion hella majestic and cool looking", mesh where needed):
    a proud lion standing tall at the shoulders, head up, inside a huge sunflower mane: a studded
    seed disc behind the head and two rings of smooth pointed petals (meshes), a third ring
    sweeping back over the shoulders. Blocks for the body; leaf meshes at the ankles; a stem tail
    ending in a small sunflower."""
    g = Garden("SunflowerLion", C)
    y0 = 6.6
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0, 1.2), (5.4, 4.6, 8.0), "fur")
    g.box(root, "Chest", (0, y0 + 0.7, -2.6), (6.2, 6.0, 3.2), "fur")
    g.box(root, "Belly", (0, y0 - 2.35, 1.4), (4.4, 0.3, 6.6), "cream")
    g.box(root, "Back", (0, y0 + 2.35, 2.2), (3.2, 0.3, 5.6), "furdark")
    # legs: thick, the front pair taller (a proud stance), big cream paws, leaf cuffs
    for nm, (x, z) in (("FL", (-1, -2.6)), ("FR", (1, -2.6)), ("HL", (-1, 4.0)), ("HR", (1, 4.0))):
        leg = g.group("Leg" + nm, (x * 1.8, y0 - 1.6, z), root)
        g.box(leg, "Leg" + nm, (x * 1.8, (y0 - 1.6) / 2 + 0.45, z), (2.2, y0 - 0.7, 2.2), "fur")
        g.box(leg, "Paw" + nm, (x * 1.8, 0.45, z - 0.35), (2.7, 0.9, 2.9), "cream")
        for k in range(4):
            a = TAU * (k + 0.5) / 4
            out = np.array([np.cos(a), 0, np.sin(a)])
            g.hull(leg, "SmoothCuff" + nm, G.leaf((x * 1.8, 2.5, z) + out * 0.9, out * 0.5 + (0, -1, 0), out, 1.7, 1.2, 0.15), "leaf")
    # tail: a smooth stem curving up, a small sunflower at the tip
    tail = g.group("Tail", (0, y0 + 1.4, 5.2), root)
    path = [(0, y0 + 1.4 + 0.9 * np.sin(u * 1.6), 5.0 + 4.0 * u + 0.8 * u * u) for u in np.linspace(0, 1, 7)]
    path = [(x, y + 1.6 * u ** 2, z) for (x, y, z), u in zip(path, np.linspace(0, 1, 7))]
    G.tube(g, tail, "SmoothTailStem", path, [0.45] + [0.35] * 6, "leafdark")
    tip = np.array(path[-1])
    sunflower(g, tail, "Tail", tip + (0, 0.3, 0.3), np.array([0, 0.5, 1.0]) / np.hypot(0.5, 1.0), 0.8, 8, 1.1, 0.6)
    # head held high inside the sunflower mane
    neck = g.group("neck", (0, y0 + 2.0, -3.4), root)
    g.box(neck, "Neck", (0, y0 + 2.6, -3.6), (3.6, 3.0, 3.0), "fur")
    hy, hz = y0 + 4.1, -4.6
    sunflower(g, neck, "Mane", (0, hy + 0.3, hz + 2.4), np.array([0, 0, -1.0]), 3.6, 13, 3.4, 1.9, back=(0.35, 0.75))
    mc = np.array((0, hy + 0.3, hz + 2.4))
    g.hull(neck, "ManeCalyx", G.prism(mc + (0, 0, 0.35), 3.2, 1.0, seg=14, top=0.7, M=G.frame((0, 0, 1))), "leafdark")
    for k in range(10):  # a third ring sweeping back off the calyx over the neck and shoulders
        a = TAU * (k + 0.25) / 10
        rad = np.array([np.cos(a), np.sin(a), 0])
        g.hull(neck, "SmoothManePetalBack", G.leaf(mc + rad * 2.4 + (0, 0, 0.9), rad * 0.7 + (0, 0, 1), rad, 3.2, 1.8, 0.2), "petal")
    g.box(neck, "Head", (0, hy, hz), (4.6, 4.2, 4.0), "fur")
    g.box(neck, "Bridge", (0, hy, hz - 2.2), (1.6, 1.4, 0.6), "fur")
    g.box(neck, "Muzzle", (0, hy - 1.1, hz - 2.5), (3.0, 1.8, 1.2), "cream")
    g.pyr(neck, "Nose", (0, hy - 0.15, hz - 3.15), (0, -1, 0), 0.9, 0.8, 0.15, "nose")
    g.box(neck, "Mouth", (0, hy - 1.45, hz - 3.12), (1.6, 0.22, 0.1), "nose")
    g.box(neck, "Chin", (0, hy - 2.1, hz - 1.9), (2.4, 0.6, 1.6), "cream")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.15, hy + 0.35, hz - 2.05), (1.2, 1.1), look=(0, 0.1))
        g.box(neck, "Brow" + side, (s * 1.2, hy + 1.1, hz - 2.15), (2.0, 0.55, 0.5), "furdark", Rm(("z", s * 14)))
        g.box(neck, "Ear" + side, (s * 1.7, hy + 2.45, hz + 0.4), (1.3, 1.0, 0.8), "furdark")
    return g


def animations(m):
    def run(L, swing, lean, hop, n=16):
        tr = {"root": [track(L, lambda u: (lean + 3 * sin(TAU * u), 0, 0), n),
                       track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")],
              "neck": [track(L, lambda u: (-lean - 4 * sin(TAU * u), 0, 0), n)],
              "Tail": [track(L, lambda u: (10 + 10 * sin(TAU * u), 12 * sin(TAU * u), 0), n)]}
        for b, ph in (("LegFL", 0), ("LegHR", 0.0 if hop < 8 else 0.25), ("LegFR", 0.5), ("LegHL", 0.5 if hop < 8 else 0.75)):
            tr[b] = [track(L, lambda u, ph=ph: (swing * sin(TAU * (u + ph)), 0, 0), n)]
        return tr

    L = 3.0
    idle = {"neck": [track(L, lambda u: (3 * sin(TAU * u), 10 * sin(TAU * u), 4 * sin(TAU * u + 1)), 24)],
            "Tail": [track(L, lambda u: (10, 25 * sin(TAU * u), 0), 24)],
            "root": [track(L, lambda u: (0, 1.2 * sin(TAU * 2 * u), 0), 24, "position")]}
    return {"idle": (L, idle), "walk": (0.8, run(0.8, 24, 0, 2)), "gallop": (0.45, run(0.45, 42, -4, 10))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/SunflowerLion_anims.gif")
