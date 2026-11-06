"""Gecko: World 1 Meadow's Rare (QM, Nov 6), low and long like the Crocodile, built the way
QM's Kitten and Sandworm are (designs/desert/): a pale belly under each section, colour as
flush slices (the Kitten's stripes), and a tail that tapers section by section (the
Sandworm's). A bright green day gecko with two thin orange bands across its back and two
on its tail, a wide flat head with big googly eyes and a smile, brow bumps over the eyes
(the ear bones), short splayed legs on wide sticky toe pads, and an orange tail tip.

Same bones and rules as every quadruped (root, neck, EarL, EarR, Tail, Leg*); walk is
QM's horse walk, the gallop the shared leap.

    python3 tools/gecko_design.py

writes designs/animals/Gecko.bbmodel.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402

GREEN = (96, 196, 72)
BELLY = (232, 236, 150)
SPOT = (244, 120, 48)
PAD = (176, 230, 120)
MOUTH = (40, 70, 34)


def gecko():
    a = Animal("Gecko", "Rare")
    x, y0, y1, z0, z1 = 1.5, 1.0, 2.8, -2.8, 2.6
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, 0)
    a.box("Belly", (-x, y0, z0), (x, 1.5, z1), BELLY, "root")
    for i, (za, zb, c) in enumerate(((z0, -1.6, GREEN), (-1.6, -1.1, SPOT), (-1.1, 0.2, GREEN), (0.2, 0.7, SPOT), (0.7, z1, GREEN))):
        a.box(f"Body{i + 1}", (-x, 1.5, za), (x, y1, zb), c, "root")

    # short splayed legs at the corners on wide sticky toe pads
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 1.3, sx * 2.1))
        za, zb = (-2.5, -1.7) if front else (1.6, 2.4)
        name = "Leg" + leg
        a.box(name, (xa, 0.3, za), (xb, 1.9, zb), GREEN, name)
        fa, fb = sorted((sx * 1.1, sx * 2.5))
        a.box("Hoof" + leg, (fa, 0, za - 0.5), (fb, 0.3, zb + 0.1), PAD, name)
        a.pivots[name] = ((xa + xb) / 2, 1.875, zb - 0.05 if front else za + 0.05)

    # head: wide and flat with a pale chin, a shorter snout with a smile across its front
    a.box("HeadBelly", (-1.6, 0.9, -5.6), (1.6, 1.5, -2.799), BELLY, "neck")
    a.box("Head", (-1.6, 1.5, -5.6), (1.6, 3.0, -2.799), GREEN, "neck")
    a.box("Snout", (-1.1, 1.0, -6.4), (1.1, 2.5, -5.6), GREEN, "neck")
    a.box("Mouth", (-0.9, 1.35, -6.43), (0.9, 1.5, -6.4), MOUTH, "neck")
    a.eyes(1.6, 1.7, 3.0, -5.3, -4.0)
    a.pivots["neck"] = (0, 2.8, -2.8)
    # brow bumps over the eyes (the ear bones)
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.6, sx * 1.6))
        a.box(bone, (xa, 3.0, -5.4), (xb, 3.5, -3.9), GREEN, bone)
        a.pivots[bone] = ((xa + xb) / 2, 3.0, -5.4)

    # tail tapering section by section, a thin orange band between them, an orange tip
    for i, (w, top, za, zb, c) in enumerate(((1.1, 2.5, z1, 4.8, GREEN), (0.8, 2.2, 4.8, 5.2, SPOT), (0.8, 2.2, 5.2, 7.2, GREEN),
                                             (0.5, 1.8, 7.2, 7.5, SPOT), (0.5, 1.8, 7.5, 9.0, GREEN))):
        a.box("Tail" if i == 0 else f"Tail{i + 1}", (-w, 1.0, za), (w, top, zb), c, "Tail")
    a.wedge("TailTip", (-0.35, 1.0, 9.0), (0.35, 1.6, 9.9), SPOT, "Tail", "down_back")
    a.pivots["Tail"] = (0, 2.5, z1)

    a.meta = {"seat": (0, 3.5, 0.2), "neck_loop": {"center": (0, 2.2, -4.4), "radius": 1.9}}
    a.animations = quad_animations
    return a


def main(out=os.path.join(A.ROOT, "designs", "animals")):
    a = gecko()
    A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
