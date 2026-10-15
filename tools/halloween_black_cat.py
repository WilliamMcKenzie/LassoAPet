"""Black Cat: Halloween Haunted Hills Common (draft, Oct 15). A chunky black cat: googly eyes on
lime plates on the sides of its head (like the horse), pink inner ears and nose, a purple collar
with an orange bell, and a tall tail with a hooked tip. Fewest pieces (QM, Oct 15).

Run: python3 tools/halloween_black_cat.py [--gif]
Bones (all rest 0): root -> neck, Tail, LegFL/FR/HL/HR.
"""

import sys

import halloween_lib as H
from halloween_lib import Spooky, Rm

C = {"fur": (44, 40, 54), "furlight": (70, 64, 86), "pink": (255, 140, 190),
     "collar": (150, 70, 220), "bell": (255, 150, 30)}


def build():
    g = Spooky("BlackCat", C)
    y0 = 3.4
    root = g.group("root", (0, y0, 0))
    g.box(root, "Body", (0, y0 + 0.3, 0.6), (3.6, 3.0, 6.4), "fur")
    for nm, (x, z) in (("FL", (-1, -1.8)), ("FR", (1, -1.8)), ("HL", (-1, 3.0)), ("HR", (1, 3.0))):
        g.leg(root, nm, (x * 1.15, y0 - 0.6, z), y0 - 0.6, 1.2, "fur")
    tail = g.group("Tail", (0, y0 + 1.2, 3.8), root)
    g.box(tail, "Tail", (0, y0 + 3.2, 4.3), (0.9, 4.4, 0.9), "fur", Rm(("x", 12)))
    g.box(tail, "TailTip", (0, y0 + 5.5, 4.0), (0.9, 0.9, 1.6), "fur")
    neck = g.group("neck", (0, y0 + 1.0, -2.0), root)
    hy, hz = y0 + 2.4, -3.2
    g.box(neck, "Collar", (0, y0 + 1.0, -2.2), (4.2, 0.8, 1.6), "collar")
    g.box(neck, "Bell", (0, y0 + 0.3, -3.2), (1.0, 1.0, 1.0), "bell")
    g.box(neck, "Head", (0, hy, hz), (4.0, 3.2, 3.0), "fur")
    g.box(neck, "Muzzle", (0, hy - 0.8, hz - 1.7), (2.0, 1.2, 0.6), "furlight")
    g.box(neck, "Nose", (0, hy - 0.35, hz - 2.05), (0.8, 0.5, 0.3), "pink")
    for side, s in (("L", -1), ("R", 1)):
        g.eye(neck, side, (s * 2.05, hy + 0.3, hz - 0.6), 1.2, normal=(s, 0, 0))
        g.pyr(neck, "Ear" + side, (s * 1.2, hy + 1.6, hz + 0.2), (s * 0.2, 1, 0), 1.6, 0.8, 0.6, "fur")
        g.pyr(neck, "EarIn" + side, (s * 1.2, hy + 1.6, hz - 0.45), (s * 0.2, 1, 0), 1.1, 0.5, 0.1, "pink")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(26, 46), gait="bound", hop=(1.5, 6)))
    if "--gif" in sys.argv:
        H.gif(m, "BlackCat")
