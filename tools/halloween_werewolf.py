"""Werewolf: Halloween Haunted Hills Epic (draft, Oct 15). A big shaggy grey-blue wolf on all fours,
hunched: a huge chest and shoulders over a lean waist, shaggy pyramid tufts on the
shoulders, a long snout with a black nose and white fangs, tall pointed ears, googly eyes on the
sides of the head, ripped purple shorts on the hind legs and a bushy tail.

Run: python3 tools/halloween_werewolf.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import halloween_lib as H
from halloween_lib import Spooky, Rm

C = {"fur": (112, 122, 150), "furdark": (74, 80, 106), "furlight": (170, 178, 200), "nose": (30, 28, 36),
     "fang": (252, 250, 244), "shorts": (140, 70, 200)}


def build():
    g = Spooky("Werewolf", C)
    y0 = 6.0
    root = g.group("root", (0, y0, 0))
    g.box(root, "Chest", (0, y0 + 1.0, -1.4), (6.0, 5.4, 4.4), "fur")
    g.box(root, "Waist", (0, y0 + 0.4, 2.6), (4.2, 3.6, 4.2), "fur")
    g.box(root, "Shorts", (0, y0 - 0.4, 3.4), (4.6, 2.2, 3.2), "shorts")
    for side, s in (("L", -1), ("R", 1)):
        for k, (y, z) in enumerate(((y0 + 3.4, -2.4), (y0 + 3.0, -0.4))):
            g.pyr(root, "Tuft" + side, (s * 1.6, y, z), (s * 0.4, 1, 0.5), 1.8, 0.9, 0.9, "furdark")
    for nm, (x, z, w) in (("FL", (-1, -2.0, 1.9)), ("FR", (1, -2.0, 1.9)), ("HL", (-1, 3.6, 1.7)), ("HR", (1, 3.6, 1.7))):
        g.leg(root, nm, (x * (2.0 if nm[0] == "F" else 1.5), y0 - 0.8, z), y0 - 0.8, w, "fur", foot=w + 0.7, foot_col="furdark")
    tail = g.group("Tail", (0, y0 + 1.2, 4.6), root)
    g.box(tail, "Tail", (0, y0 + 2.2, 6.4), (1.8, 1.8, 4.0), "fur", Rm(("x", -30)))
    g.pyr(tail, "TailTip", (0, y0 + 3.3, 8.3), (0, 0.5, 1), 1.4, 0.9, 0.9, "furlight")
    neck = g.group("neck", (0, y0 + 2.0, -3.6), root)
    hy, hz = y0 + 3.8, -5.4
    g.box(neck, "Head", (0, hy, hz), (4.0, 3.4, 3.4), "fur")
    g.box(neck, "Snout", (0, hy - 0.8, hz - 2.8), (2.4, 1.8, 2.4), "furlight")
    g.box(neck, "Nose", (0, hy + 0.05, hz - 4.0), (1.0, 0.7, 0.4), "nose")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 2.05, hy + 0.5, hz - 0.8), 1.2, normal=(s, 0, 0))
        g.pyr(neck, "Ear" + side, (s * 1.2, hy + 1.7, hz + 0.6), (s * 0.2, 1, 0.1), 2.2, 0.8, 0.6, "furdark")
        g.pyr(neck, "Fang" + side, (s * 0.7, hy - 1.7, hz - 3.6), (0, -1, 0), 0.7, 0.22, 0.2, "fang")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(24, 44), gait="bound", hop=(2, 9), lean=-6))
    if "--gif" in sys.argv:
        H.gif(m, "Werewolf")
