"""Sunflower Lion: World 3 Garden Legendary (draft, Oct 14). A golden lion whose mane is a giant
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


def mane(g, node, c, r):
    """The sunflower mane wrapped round the head in layers, so it has depth from every side: a seed-brown
    collar, then rings of pyramid petals pointing out, out-and-back and back (front ring yellow, the
    deeper rings gold), and a few framing the face."""
    c = np.array(c, float)
    g.box(node, "ManeSeed", c + (0, 0, 0.6), (2 * r, 2 * r, 2.6), "seed")
    g.box(node, "ManeSeedDark", c + (0, 0, -0.75), (2 * r - 1.0, 2 * r - 1.0, 0.3), "seeddark")
    g.box(node, "ManeSeedBack", c + (0, 0, 2.2), (2 * r - 1.2, 2 * r - 1.2, 1.0), "seed")
    rings = ((10, 0.0, (1.0, 0.0), -0.2, r - 0.2, 3.2, "petal"),      # out, round the face
             (10, 0.5, (0.75, 0.7), 1.2, r - 0.2, 3.0, "petaldark"),  # out and back
             (6, 0.25, (0.5, 1.0), 2.9, 1.7, 2.6, "petal"))            # back, from the back of the head
    for n, off, (ro, back), z, br, L, col in rings:
        for k in range(n):
            a = TAU * (k + off) / n
            rad = np.array([np.cos(a), np.sin(a), 0])
            d = rad * ro + np.array([0, 0, back])
            d /= np.linalg.norm(d)
            base = c + rad * br + (0, 0, z)
            g.pyr(node, "Petal", base, d, L, r * 0.5, 0.4, col, wv=(-rad[1], rad[0], 0))


def build():
    g = Garden("SunflowerLion", C)
    y0 = 6.4
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0, 0.6), (5.6, 4.8, 9.0), "fur")
    g.box(root, "Belly", (0, y0 - 2.45, 0.6), (4.6, 0.3, 7.4), "cream")
    g.box(root, "Back", (0, y0 + 2.45, 1.4), (3.6, 0.3, 6.0), "furdark")
    # legs: thick, big cream paws with pyramid claws, leaf cuffs
    for nm, (x, z) in (("FL", (-1, -2.6)), ("FR", (1, -2.6)), ("HL", (-1, 3.6)), ("HR", (1, 3.6))):
        leg = g.group("Leg" + nm, (x * 1.7, y0 - 1.8, z), root)
        g.box(leg, "Leg" + nm, (x * 1.7, (y0 - 1.8) / 2 + 0.4, z), (2.1, y0 - 1.0, 2.1), "fur")
        g.box(leg, "Paw" + nm, (x * 1.7, 0.45, z - 0.3), (2.6, 0.9, 2.8), "cream")
        g.box(leg, "Cuff" + nm, (x * 1.7, 1.55, z), (2.4, 0.6, 2.4), "leaf")
    # tail: a stem with a leaf, a little sunflower at the tip
    tail = g.group("Tail", (0, y0 + 1.6, 5.1), root)
    d = np.array([0, 0.75, 1.0]) / 1.25
    base = np.array([0, y0 + 1.6, 5.1])
    g.box(tail, "TailStem", base + d * 2.0, (0.7, 4.0, 0.7), "leafdark", G.frame(d))
    g.box(tail, "TailLeaf", base + d * 1.6 + (0.8, 0.2, 0), (1.6, 0.35, 0.9), "leaf", Rm(("z", -20)))
    tip = base + d * 4.3
    for k in range(4):
        a = TAU * k / 4 + 0.4
        dd = np.array([np.cos(a), np.sin(a) * 0.6, np.sin(a) * -0.8])
        dd /= np.linalg.norm(dd)
        g.pyr(tail, "TailPetal", tip + dd * 0.6, dd, 1.2, 0.45, 0.25, "petal")
    g.box(tail, "TailDisc", tip, (1.3, 1.3, 1.3), "seed")
    # head inside the sunflower mane
    neck = g.group("neck", (0, y0 + 1.8, -3.6), root)
    hy, hz = y0 + 3.2, -5.2
    mane(g, neck, (0, hy + 0.2, hz + 1.8), 3.0)
    g.box(neck, "Head", (0, hy, hz), (4.8, 4.4, 4.2), "fur")
    g.box(neck, "Muzzle", (0, hy - 1.0, hz - 2.55), (3.0, 1.9, 1.0), "cream")
    g.box(neck, "Nose", (0, hy - 0.2, hz - 3.15), (1.3, 0.6, 0.3), "nose")
    g.box(neck, "Mouth", (0, hy - 1.45, hz - 3.08), (1.5, 0.25, 0.1), "nose")
    g.box(neck, "Chin", (0, hy - 2.05, hz - 1.9), (2.2, 0.5, 1.4), "cream")
    for side, s in (("L", -1), ("R", 1)):
        # side plate eyes set at the front corners, a brow over each so the face reads from the front
        g.eye(neck, side, (s * 2.45, hy + 0.6, hz - 1.1), (1.4, 1.4), normal=(s, 0, 0), look=(0.2 * -s, 0))
        g.box(neck, "Brow" + side, (s * 1.7, hy + 1.45, hz - 2.2), (1.6, 0.45, 0.4), "furdark")
        g.box(neck, "Ear" + side, (s * 1.6, hy + 2.5, hz + 0.6), (1.2, 1.0, 0.7), "furdark")
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
