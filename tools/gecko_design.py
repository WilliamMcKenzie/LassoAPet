"""Gecko: World 1 Meadow's Rare (QM, Nov 6), in the Meadow animals' style, built low
like the Crocodile (tools/crocodile_design.py): a bright green day gecko with orange
spots down its back, a pale yellow belly, a wide flat head with big Horse googly eyes on
its sides and a smile, brow bumps over the eyes (the ear bones), short splayed legs on
wide sticky toe pads with three round toes each, and a long tapering spotted tail.

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
    x, y0, y1, z0, z1 = 1.6, 1.0, 3.0, -3.0, 3.0
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, 0)
    a.box("Belly", (-x, y0, z0), (x, 1.5, z1), BELLY, "root")
    a.box("Body", (-x, 1.5, z0), (x, y1, z1), GREEN, "root")
    body = ((-x, y0, z0), (x, y1, z1))
    # orange spots: two staggered rows down the back and one on each side
    for i, (xa, xb, za, zb) in enumerate(((-1.2, -0.4, -2.4, -1.6), (0.4, 1.2, -1.2, -0.4),
                                          (-1.1, -0.3, 0.2, 1.0), (0.3, 1.1, 1.4, 2.2), (-0.5, 0.3, 2.4, 2.9))):
        a.patch(f"Spot{i + 1}", "T", xa, xb, za, zb, SPOT, box=body)
    for side, face in (("L", "L"), ("R", "R")):
        a.patch(f"SpotSide{side}1", face, -1.8, -1.1, 2.1, 2.7, SPOT, box=body)
        a.patch(f"SpotSide{side}2", face, 0.9, 1.6, 2.0, 2.6, SPOT, box=body)

    # short splayed legs at the corners on wide sticky toe pads, three round toes out front
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 1.4, sx * 2.3))
        za, zb = (-2.7, -1.8) if front else (1.8, 2.7)
        name = "Leg" + leg
        a.box(name, (xa, 0.3, za), (xb, 2.2, zb), GREEN, name)
        fa, fb = sorted((sx * 1.2, sx * 2.6))
        a.box("Hoof" + leg, (fa, 0, za - 0.4), (fb, 0.3, zb + 0.1), PAD, name)
        for k, tx in enumerate((1.25, 1.75, 2.25)):
            ta, tb = sorted((sx * tx, sx * (tx + 0.35)))
            a.box(f"Toe{leg}{k + 1}", (ta, 0, za - 0.8), (tb, 0.35, za - 0.4), PAD, name)
        a.pivots[name] = ((xa + xb) / 2, 2.175, zb - 0.05 if front else za + 0.05)

    # head: wide and flat, a shorter snout with a smile, nostrils on top
    a.box("HeadBelly", (-1.5, 1.1, -5.6), (1.5, 1.6, -2.999), BELLY, "neck")
    a.box("Head", (-1.5, 1.6, -5.6), (1.5, 3.2, -2.999), GREEN, "neck")
    a.box("Snout", (-1.1, 1.2, -6.4), (1.1, 2.7, -5.6), GREEN, "neck")
    a.box("Mouth", (-0.9, 1.55, -6.43), (0.9, 1.7, -6.4), MOUTH, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.65))
        a.box("Nostril" + side, (xa, 2.7, -6.3), (xb, 2.75, -6.0), MOUTH, "neck")
    a.patch("HeadSpot", "T", -0.4, 0.4, -4.2, -3.5, SPOT, "neck", box=((-1.5, 1.6, -5.6), (1.5, 3.2, -3.0)))
    a.eyes(1.5, 1.9, 3.1, -5.3, -4.0)
    a.pivots["neck"] = (0, 3.0, -3.0)
    # brow bumps over the eyes (the ear bones)
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.6, sx * 1.5))
        a.box(bone, (xa, 3.2, -5.4), (xb, 3.6, -3.9), GREEN, bone)
        a.pivots[bone] = ((xa + xb) / 2, 3.2, -5.4)

    # long tail: three narrowing blocks, an orange spot on each
    for i, (w, top, za, zb) in enumerate(((1.1, 2.7, 3.0, 5.2), (0.75, 2.3, 5.2, 7.4), (0.4, 1.9, 7.4, 9.2))):
        name = "Tail" if i == 0 else f"Tail{i + 1}"
        a.box(name, (-w, 1.1, za), (w, top, zb), GREEN, "Tail")
        s = min(0.35, w - 0.1)
        a.box(f"TailSpot{i + 1}", (-s, top, za + 0.6), (s, top + 0.05, za + 1.2), SPOT, "Tail")
    a.pivots["Tail"] = (0, 2.7, 3.0)

    a.meta = {"seat": (0, 3.7, 0.4), "neck_loop": {"center": (0, 2.3, -4.4), "radius": 1.9}}
    a.animations = quad_animations
    return a


def main(out=os.path.join(A.ROOT, "designs", "animals")):
    a = gecko()
    A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
