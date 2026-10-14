"""Sunflower Lion: World 3 Garden Legendary (draft, Oct 14). A golden lion whose mane is a giant
sunflower: a ring of sunny yellow petals (pyramids, two layers, the back layer deeper gold) round a
dark brown seed disc behind its head. Meadow-style blocky body (the Meadow animals are the style
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


def sunflower(g, node, name, c, r, petals, plen, layer2=True, depth=1.0):
    """A sunflower facing -Z centred on c: seed disc, petal pyramids pointing out in the XY plane."""
    c = np.array(c, float)
    g.box(node, name + "Disc", c, (2 * r, 2 * r, depth), "seed")
    g.box(node, name + "DiscMid", c + (0, 0, -depth / 2 - 0.1), (1.2 * r, 1.2 * r, 0.3), "seeddark")
    g.box(node, name + "Back", c + (0, 0, depth / 2 + 0.25), (2 * r - 0.4, 2 * r - 0.4, 0.5), "leafdark")
    g.box(node, name + "DiscRim", c + (0, 0, 0.1), (2 * r + 0.6, 2 * r - 0.6, depth - 0.2), "seed")
    g.box(node, name + "DiscRim", c + (0, 0, 0.1), (2 * r - 0.6, 2 * r + 0.6, depth - 0.2), "seed")
    for layer, (col, off, L, z) in enumerate((("petal", 0.0, plen, -0.1), ("petaldark", 0.5, plen * 1.1, 0.35))):
        if layer and not layer2:
            break
        for k in range(petals):
            a = TAU * (k + off) / petals
            d = np.array([np.cos(a), np.sin(a), 0])
            g.pyr(node, name + "Petal", c + d * (r - 0.2) + (0, 0, z), d, L, r * 0.55, 0.3, col, wv=(-d[1], d[0], 0))


def build():
    g = Garden("SunflowerLion", C)
    y0 = 6.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0, 0.6), (4.4, 4.0, 8.4), "fur")
    g.box(root, "Belly", (0, y0 - 2.05, 0.6), (3.6, 0.3, 7.0), "cream")
    # legs, leaf cuffs above the paws
    for nm, (x, z) in (("FL", (-1, -2.4)), ("FR", (1, -2.4)), ("HL", (-1, 3.4)), ("HR", (1, 3.4))):
        leg = g.group("Leg" + nm, (x * 1.3, y0 - 1.6, z), root)
        g.box(leg, "Leg" + nm, (x * 1.3, (y0 - 1.6) / 2 + 0.3, z), (1.5, y0 - 1.0, 1.5), "fur")
        g.box(leg, "Paw" + nm, (x * 1.3, 0.35, z - 0.15), (1.7, 0.7, 1.8), "cream")
        g.box(leg, "Cuff" + nm, (x * 1.3, 1.3, z), (1.8, 0.5, 1.8), "leaf")
    # tail: a stem with a leaf, a little sunflower at the tip
    tail = g.group("Tail", (0, y0 + 1.4, 4.8), root)
    d = np.array([0, 0.75, 1.0]) / 1.25
    g.box(tail, "TailStem", np.array([0, y0 + 1.4, 4.8]) + d * 2.0, (0.6, 4.0, 0.6), "leafdark", G.frame(d))
    g.box(tail, "TailLeaf", np.array([0.7, y0 + 2.4, 5.8]), (1.4, 0.3, 0.8), "leaf", Rm(("z", -20)))
    tip = np.array([0, y0 + 1.4, 4.8]) + d * 4.2
    for k in range(6):
        a = TAU * k / 6
        dd = np.array([np.cos(a), np.sin(a) * 0.6, np.sin(a) * -0.8])
        dd /= np.linalg.norm(dd)
        g.pyr(tail, "TailPetal", tip + dd * 0.5, dd, 1.0, 0.4, 0.2, "petal")
    g.box(tail, "TailDisc", tip, (1.1, 1.1, 1.1), "seed")
    # head and the sunflower mane
    neck = g.group("neck", (0, y0 + 1.6, -3.4), root)
    hy, hz = y0 + 2.8, -4.6
    sunflower(g, neck, "Mane", (0, hy + 0.2, hz + 1.4), 3.0, 11, 2.4, depth=1.4)
    g.box(neck, "Head", (0, hy, hz), (3.8, 3.6, 3.4), "fur")
    g.box(neck, "Muzzle", (0, hy - 0.8, hz - 2.1), (2.4, 1.6, 1.0), "cream")
    g.box(neck, "Nose", (0, hy - 0.2, hz - 2.7), (1.0, 0.5, 0.3), "nose")
    g.box(neck, "Mouth", (0, hy - 1.15, hz - 2.62), (1.2, 0.2, 0.1), "nose")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 1.95, hy + 0.5, hz - 0.8), (1.1, 1.1), normal=(s, 0, 0), look=(0.2 * -s, 0))
        g.box(neck, "Ear" + side, (s * 1.3, hy + 2.0, hz + 0.6), (1.0, 0.9, 0.6), "furdark")
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
