"""Rafflesia Beast: World 3 Garden giga rare (draft, Oct 14; about 1 in 1,000). A hulking
moss-green beast carrying a giant corpse flower on its back: five huge warty red-orange petals
spread over it like a saddle cloth, a dark maroon well in the middle ringed by a cream rim and
bristling with pyramid spines (you ride in the well). Four thick root legs with pyramid root-claws,
a broad head with two googly eyes, a wide grin of pyramid fangs, a frill of small red petals round
its neck, vines hanging from the petal tips, and a heavy vine tail ending in a fat bud.

Run: python3 tools/garden_rafflesia.py [--gif]
Bones (all rest 0): root -> neck -> Jaw; Petal1..5; Tail; LegFL/FR/HL/HR.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"moss": (70, 140, 60), "mossdark": (40, 92, 44), "mosslight": (120, 186, 70), "petal": (220, 62, 40),
     "petaldark": (150, 30, 30), "wart": (250, 222, 196), "well": (90, 18, 34), "rim": (246, 226, 200),
     "spine": (250, 236, 210), "root": (110, 72, 46), "rootdark": (70, 46, 32), "mouth": (60, 16, 26),
     "tooth": (252, 244, 220), "vine": (60, 150, 50), "bud": (196, 44, 60)}


def build():
    g = Garden("RafflesiaBeast", C)
    y0 = 11.0
    root = g.group("root", (0, y0, 0))
    # the body: a broad moss block with a lighter back and darker flanks
    g.box(root, "Body", (0, y0, 0.5), (14.0, 8.0, 18.0), "moss")
    g.box(root, "Belly", (0, y0 - 4.2, 0.5), (11.0, 0.6, 15.0), "mossdark")
    for side, s in (("L", -1), ("R", 1)):
        for k, z in enumerate((-5, 0, 5)):
            g.box(root, "MossTuft" + side, (s * 7.2, y0 + 1.6 - 0.8 * (k % 2), z + 0.5), (0.6, 2.6, 2.6), "mosslight")
            g.box(root, "Stripe" + side, (s * 7.15, y0 - 2.2, z + 3.0), (0.5, 3.0, 1.0), "mossdark")
    g.box(root, "Chest", (0, y0 - 0.5, -8.7), (12.0, 7.0, 0.6), "mossdark")
    # the flower: a raised well in the middle, five petals radiating out over the back
    top = y0 + 4.0
    fc = np.array([0, top, 0.5])
    g.box(root, "FlowerBase", fc + (0, 0.5, 0), (10.0, 1.0, 10.0), "petaldark")
    for k in range(10):  # the rim: ten blocks in a ring
        a = TAU * k / 10
        p = fc + (4.0 * np.sin(a), 2.0, 4.0 * np.cos(a))
        g.box(root, "Rim", p, (2.9, 2.0, 1.2), "rim", Rm(("y", np.degrees(a))))
    g.box(root, "Well", fc + (0, 1.1, 0), (7.2, 0.4, 7.2), "well")
    g.box(root, "RimBand", fc + (0, 1.2, 0), (9.6, 0.6, 9.6), "petaldark", Rm(("y", 18)))
    for k in range(7):  # spines standing in the well, ringed round the seat
        a = TAU * (k + 0.5) / 7
        g.pyr(root, "Spine", fc + (2.4 * np.sin(a), 1.3, 2.4 * np.cos(a)), (0.25 * np.sin(a), 1, 0.25 * np.cos(a)),
              1.6, 0.35, 0.35, "spine")
    for i in range(5):
        ang = 72 * i  # 0 = straight back; the front (the head) falls between two petals
        a = np.radians(ang)
        out = np.array([np.sin(a), 0, np.cos(a)])
        pivot = fc + out * 3.8 + (0, 0.6, 0)
        node = g.group(f"Petal{i + 1}", pivot, root)
        M = Rm(("y", ang), ("x", -8))  # local +z out along the petal, cupped a little up
        def P(p):
            return pivot + M @ np.array(p, float)
        for k, (z, w, L, col) in enumerate(((3.0, 9.4, 6.0, "petal"), (7.6, 8.2, 3.6, "petal"), (10.4, 5.8, 2.4, "petal"))):
            g.box(node, f"Petal{i + 1}", P((0, 0, z)), (w, 1.1, L), col, M)
        g.box(node, f"PetalEdge{i + 1}", P((0, -0.3, 7.0)), (9.0, 0.9, 8.4), "petaldark", M)
        for (x, z, sz) in ((-2.8, 2.2, 1.3), (2.4, 3.4, 1.5), (-0.4, 5.4, 1.2), (3.0, 7.4, 1.0), (-2.8, 7.8, 1.1), (0.4, 9.8, 1.1), (-0.8, 2.0, 0.9), (1.4, 11.0, 0.7)):
            g.box(node, f"Wart{i + 1}", P((x, 0.7, z)), (sz, 0.4, sz), "wart", M)
        # a vine hanging off the tip
        tip = P((0, -0.4, 11.4))
        g.box(node, f"Vine{i + 1}", tip + (0, -1.6, 0), (0.5, 3.2, 0.5), "vine")
        g.box(node, f"VineLeaf{i + 1}", tip + (0.5, -2.8, 0), (1.2, 0.3, 0.7), "mosslight", Rm(("z", -25)))
    # head: broad, low, eyes on top corners, a grin of fangs; the jaw drops in the gallop
    neck = g.group("neck", (0, y0 + 0.5, -8.6), root)
    hy, hz = y0 + 1.0, -12.0
    g.box(neck, "Head", (0, hy, hz), (10.0, 6.0, 7.0), "moss")
    g.box(neck, "Brow", (0, hy + 3.2, hz - 1.0), (9.0, 0.6, 4.6), "mossdark")
    for side, s in (("L", -1), ("R", 1)):
        g.box(neck, "EyeMound" + side, (s * 3.0, hy + 3.4, hz - 1.6), (3.0, 1.6, 3.0), "moss")
        g.eye(neck, side, (s * 3.0, hy + 3.5, hz - 3.15), 2.4, look=(0, -0.1))
        g.box(neck, "BrowTilt" + side, (s * 3.0, hy + 5.0, hz - 3.0), (3.0, 0.6, 0.8), "mossdark", Rm(("z", s * 15)))
        g.box(neck, "Nostril" + side, (s * 1.0, hy + 1.6, hz - 3.6), (0.8, 0.5, 0.3), "mossdark")
    g.box(neck, "Mouth", (0, hy - 0.8, hz - 3.55), (8.0, 1.6, 0.2), "mouth")
    for k in range(6):
        x = -3.2 + 6.4 * k / 5
        g.pyr(neck, "Fang", (x, hy - 0.05, hz - 3.6), (0, -1, 0), 1.2 if k in (0, 5) else 0.8, 0.35, 0.2, "tooth")
    jaw = g.group("Jaw", (0, hy - 1.6, hz + 2.0), neck)
    g.box(jaw, "Jaw", (0, hy - 2.6, hz - 0.2), (9.0, 1.6, 6.4), "mossdark")
    for k in range(5):
        x = -2.8 + 5.6 * k / 4
        g.pyr(jaw, "LowFang", (x, hy - 1.8, hz - 3.0), (0, 1, 0), 1.0 if k in (0, 4) else 0.7, 0.35, 0.2, "tooth")
    # neck frill: small red petals (pyramids) round the back of the head
    for k in range(9):
        a = np.radians(-80 + 160 * k / 8)
        d = np.array([np.sin(a), np.cos(a) * 0.9 + 0.2, 0.6])
        d /= np.linalg.norm(d)
        g.pyr(neck, "Frill", (np.sin(a) * 4.4, hy + 0.5 + np.cos(a) * 2.6, hz + 3.6), d, 2.6, 1.0, 0.3,
              "petal" if k % 2 else "bud")
    # legs: thick root columns, a knee band, pyramid root-claws
    for nm, (x, z) in (("FL", (-1, -6.0)), ("FR", (1, -6.0)), ("HL", (-1, 6.5)), ("HR", (1, 6.5))):
        leg = g.group("Leg" + nm, (x * 5.0, y0 - 3.0, z), root)
        h = y0 - 3.0
        g.box(leg, "Leg" + nm, (x * 5.0, h / 2 + 0.4, z), (4.0, h + 0.8, 4.0), "root")
        g.box(leg, "Knee" + nm, (x * 5.0, h * 0.55, z), (4.4, 1.0, 4.4), "rootdark")
        g.box(leg, "Foot" + nm, (x * 5.0, 0.6, z - 0.4), (4.8, 1.2, 5.0), "rootdark")
        for t in (-1, 0, 1):
            g.pyr(leg, "Claw" + nm, (x * 5.0 + t * 1.5, 0.6, z - 2.9), (t * 0.3, -0.25, -1), 1.6, 0.55, 0.5, "root")
    # tail: two vine segments and a fat bud
    tail = g.group("Tail", (0, y0 + 1.0, 9.4), root)
    d = np.array([0, 0.35, 1.0])
    d /= np.linalg.norm(d)
    base = np.array([0, y0 + 1.0, 9.4])
    g.box(tail, "Tail", base + d * 3.0, (2.2, 6.0, 2.2), "vine", G.frame(d))
    g.box(tail, "TailBud", base + d * 6.6, (3.0, 3.0, 3.0), "bud", Rm(("x", -20)))
    for k in range(4):
        a = TAU * k / 4 + 0.4
        g.pyr(tail, "TailSepal", base + d * 5.6 + (1.2 * np.cos(a), 1.2 * np.sin(a), 0), (np.cos(a), np.sin(a), 0.6),
              1.4, 0.5, 0.25, "vine")
    return g


def animations(m):
    def stomp(L, swing, lean, hop, jaw, petals, n=16):
        tr = {"root": [track(L, lambda u: (lean, 0, 2.5 * sin(TAU * u)), n),
                       track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")],
              "neck": [track(L, lambda u: (-lean * 0.5 + 3 * sin(2 * TAU * u), 4 * sin(TAU * u), 0), n)],
              "Jaw": [track(L, lambda u: (jaw * (0.5 + 0.5 * sin(TAU * 2 * u)), 0, 0), n)],
              "Tail": [track(L, lambda u: (5 * sin(TAU * 2 * u), 14 * sin(TAU * u), 0), n)]}
        for b, ph in (("LegFL", 0), ("LegHR", 0), ("LegFR", 0.5), ("LegHL", 0.5)):
            tr[b] = [track(L, lambda u, ph=ph: (swing * sin(TAU * (u + ph)), 0, 0), n)]
        for i in range(5):
            tr[f"Petal{i + 1}"] = [track(L, lambda u, i=i: (-petals * (0.5 + 0.5 * sin(TAU * 2 * u + i)), 0, 0), n)]
        return tr

    L = 4.0
    idle = {"neck": [track(L, lambda u: (2 * sin(TAU * u), 8 * sin(TAU * u), 0), 24)],
            "Jaw": [track(L, lambda u: (10 * max(0, sin(TAU * u)) ** 4, 0, 0), 24)],
            "Tail": [track(L, lambda u: (0, 12 * sin(TAU * u), 0), 24)],
            "root": [track(L, lambda u: (0, 2 * sin(TAU * 2 * u), 0), 24, "position")]}
    for i in range(5):  # the petals breathe
        idle[f"Petal{i + 1}"] = [track(L, lambda u, i=i: (-4 * (0.5 + 0.5 * sin(TAU * u + i * 0.6)), 0, 0), 24)]
    return {"idle": (L, idle), "walk": (1.2, stomp(1.2, 16, 0, 4, 6, 4)), "gallop": (0.8, stomp(0.8, 26, -4, 10, 18, 10))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/RafflesiaBeast_anims.gif")
