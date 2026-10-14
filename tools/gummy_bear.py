"""Gummy Bear: World 3 Candyland Common. A chunky cherry gummy bear on all fours, after the
Candyland Hunting Grounds gummy bears: rounded by stepped caps, a lighter strawberry belly
and muzzle, round ears with bubblegum insides, a chocolate nose, short thick legs with dark
cherry paw pads, and a stubby tail.

Same bones as every quadruped (root, neck, EarL, EarR, Tail, Leg*), nothing turned.

    python3 tools/gummy_bear.py [--still]
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402

BODY = C.CHERRY
DARK = C.CHERRY_DK
LIGHT = C.STRAWB


def gummy_bear(name="GummyBear", rarity="Common", body=BODY, dark=DARK, light=LIGHT):
    a = Animal(name, rarity)
    x, y0, y1, z0, z1 = 1.9, 1.9, 5.2, -2.4, 2.6
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Body", (-x, y0, z0), (x, y1, z1), body, "root")
    # stepped caps round the body off on top and on both sides
    a.box("BodyTop", (-x + 0.35, y1, z0 + 0.35), (x - 0.35, y1 + 0.3, z1 - 0.35), body, "root")
    C.sym(a, "BodySide*", (x, y0 + 0.4, z0 + 0.4), (x + 0.25, y1 - 0.4, z1 - 0.4), body, "root")
    a.box("Belly", (-1.3, y0 - 0.2, z0 + 0.6), (1.3, y0, z1 - 0.6), light, "root")
    a.box("Chest", (-1.2, y0 + 0.4, z0 - 0.2), (1.2, y1 - 0.8, z0), light, "root")
    a.box("Rump", (-x + 0.4, y0 + 0.5, z1), (x - 0.4, y1 - 0.4, z1 + 0.25), body, "root")

    a.legs(0.55, 1.75, 1.5, 0.45, body, dark)
    for leg in ("FL", "FR", "HL", "HR"):  # paw pads poke out the front of each foot
        sx = -1 if leg[1] == "L" else 1
        za = z0 + 0.001 if leg[0] == "F" else z1 - 1.5
        xa, xb = sorted((sx * 0.7, sx * 1.6))
        a.box("Toes" + leg, (xa, 0, za - 0.2), (xb, 0.35, za), dark, "Leg" + leg)

    # ---- big round head on the neck bone
    hx, hy0, hy1, hz0, hz1 = 1.8, 3.8, 7.0, -5.3, -2.0
    a.box("Head", (-hx, hy0, hz0), (hx, hy1, hz1), body, "neck")
    a.box("HeadTop", (-hx + 0.35, hy1, hz0 + 0.35), (hx - 0.35, hy1 + 0.3, hz1 - 0.35), body, "neck")
    a.box("Cheeks", (-hx - 0.2, hy0 + 0.3, hz0 + 0.5), (hx + 0.2, hy0 + 1.4, hz1 - 0.6), body, "neck")
    a.box("Muzzle", (-0.95, hy0 + 0.25, hz0 - 0.9), (0.95, hy0 + 1.55, hz0), light, "neck")
    a.box("MuzzleTop", (-0.7, hy0 + 1.55, hz0 - 0.75), (0.7, hy0 + 1.75, hz0), light, "neck")
    a.box("Nose", (-0.42, hy0 + 1.1, hz0 - 1.05), (0.42, hy0 + 1.65, hz0 - 0.75), C.CHOC, "neck")
    a.box("Mouth", (-0.3, hy0 + 0.45, hz0 - 0.95), (0.3, hy0 + 0.6, hz0 - 0.9), C.CHOC, "neck")
    a.eyes(hx, 5.3, 6.5, -5.05, -4.05)
    a.pivots["neck"] = (0, 4.2, -2.1)

    # ---- round ears: stepped blocks with bubblegum insides
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.55, sx * 1.55))
        a.box(bone, (xa, hy1 + 0.3, -4.3), (xb, hy1 + 1.1, -3.6), body, bone)
        xc, xd = sorted((sx * 0.7, sx * 1.4))
        a.box(bone + "Top", (xc, hy1 + 1.1, -4.25), (xd, hy1 + 1.3, -3.65), body, bone)
        a.box(bone + "In", (xc, hy1 + 0.4, -4.36), (xd, hy1 + 1.05, -4.3), C.BUBBLE, bone)
        a.pivots[bone] = ((xa + xb) / 2, hy1 + 0.3, -4.3)

    a.box("Tail", (-0.45, 3.6, z1 + 0.25), (0.45, 4.5, z1 + 0.85), body, "Tail")
    a.pivots["Tail"] = (0, 4.5, z1 + 0.25)

    a.meta = {"seat": (0, y1 + 0.3, 0.2), "neck_loop": {"center": (0, 5.6, -3.7), "radius": 2.2}}
    a.animations = quad_animations
    return a


if __name__ == "__main__":
    C.publish(gummy_bear(), still="--still" in sys.argv)
