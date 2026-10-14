"""Spoiled Creampuff: World 3 Candyland Rare (after the Candyland Hunting Grounds creampuffs).
A grumpy cream puff: a golden choux pastry bun cut in half with a thick ring of whipped
cream between, the top half a lid that chomps open and shut like a mouth, a cherry on top,
googly eyes with chocolate brows, and four stubby pastry feet. It hops.

Bones: root (bottom bun and cream), neck (the lid: opens with +X), EarL/EarR empty, Tail
empty, Leg* (feet). Nothing turned.

    python3 tools/creampuff.py [--still]
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal  # noqa: E402
from snow_designs import pyramid  # noqa: E402

BUN = C.PASTRY
BUN_DK = C.PASTRY_DK
CREAM = C.WHITE


def creampuff(name="Creampuff", rarity="Rare"):
    a = Animal(name, rarity)
    x, y0, y1, z0, z1 = 2.4, 0.9, 2.6, -2.4, 2.4
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, 2.0, 0)
    a.box("Bun", (-x, y0 + 0.3, z0), (x, y1, z1), BUN, "root")
    a.box("BunBase", (-x + 0.4, y0, z0 + 0.4), (x - 0.4, y0 + 0.3, z1 - 0.4), BUN_DK, "root")
    # whipped cream ring, bulging past the bun, with drips down the sides
    a.box("Cream", (-x - 0.25, y1, z0 - 0.25), (x + 0.25, y1 + 0.8, z1 + 0.25), CREAM, "root")
    for i, (dx, dz) in enumerate(((-1.4, None), (0.2, None), (1.5, None))):
        a.box(f"DripF{i + 1}", (dx - 0.3, y1 - 0.5 + 0.15 * i, z0 - 0.25), (dx + 0.3, y1, z0), CREAM, "root")
    C.sym(a, "DripS*", (x, y1 - 0.6, -0.8), (x + 0.25, y1, -0.2), CREAM, "root")
    C.sym(a, "DripB*", (x, y1 - 0.4, 1.2), (x + 0.25, y1, 1.7), CREAM, "root")

    # four stubby feet
    for leg in ("FL", "FR", "HL", "HR"):
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.8, sx * 1.9))
        za = -2.0 if front else 0.9
        a.box("Leg" + leg, (xa, 0, za), (xb, y0 + 0.35, za + 1.1), BUN_DK, "Leg" + leg)
        a.pivots["Leg" + leg] = ((xa + xb) / 2, y0, za + (1.0 if front else 0.1))

    # ---- the lid (neck bone, hinged at the back of the cream)
    ly0 = y1 + 0.8
    a.box("Lid", (-2.2, ly0, -2.2), (2.2, ly0 + 1.5, 2.2), BUN, "neck")
    a.box("LidTop", (-1.7, ly0 + 1.5, -1.7), (1.7, ly0 + 2.0, 1.7), BUN, "neck")
    a.box("LidCap", (-1.0, ly0 + 2.0, -1.0), (1.0, ly0 + 2.25, 1.0), BUN_DK, "neck")
    # powdered sugar dusting
    for i, (sx, sz) in enumerate(((-1.2, -0.6), (0.9, -1.2), (1.2, 0.8), (-0.6, 1.2))):
        a.box(f"Sugar{i + 1}", (sx - 0.15, ly0 + 2.0, sz - 0.15), (sx + 0.15, ly0 + 2.12, sz + 0.15), C.ICING, "neck")
    # cherry with a stem
    a.box("Cherry", (-0.5, ly0 + 2.25, -0.5), (0.5, ly0 + 3.1, 0.5), C.CHERRY, "neck")
    a.box("CherryTop", (-0.3, ly0 + 3.1, -0.3), (0.3, ly0 + 3.25, 0.3), C.CHERRY_DK, "neck")
    C.beam(a, "Stem", (0, ly0 + 3.2, 0), (0.35, ly0 + 4.0, 0.25), 0.14, 0.14, C.LIME_DK, "neck")
    # cross eyes on the lid front, chocolate brows slanting down to the middle
    C.front_eyes(a, 0.85, ly0 + 0.15, ly0 + 1.2, -2.2, 0.9, "neck")
    for side, sx in (("L", -1), ("R", 1)):  # angry: inner ends low
        C.rbox(a, "Brow" + side, (1.2, 0.3, 0.3), C.T(sx * 0.85, ly0 + 1.38, -2.35) @ C.Rz(sx * 16), C.CHOC, "neck")
    a.pivots["neck"] = (0, ly0, 2.2)
    # the bottom bun's grumpy teeth: little cream pyramids along the front of the cream
    for i, dx in enumerate((-1.2, -0.4, 0.4, 1.2)):
        pyramid(a, f"Tooth{i + 1}", (dx - 0.25, y1 + 0.8, z0 + 0.3), (dx + 0.25, y1 + 0.8, z0 + 0.7), "+y", 0.45, CREAM, "root")

    a.pivots["EarL"] = (-1, ly0 + 2, -1)
    a.pivots["EarR"] = (1, ly0 + 2, -1)
    a.pivots["Tail"] = (0, 2, z1)
    a.meta = {"seat": (0, ly0 + 2.25, 0.9), "seatBone": "neck",
              "neck_loop": {"center": (0, ly0 + 1, -0.2), "radius": 2.6}}
    a.animations = animations
    return a


def animations():
    tr = C.track

    def hop(L, height, chomp, legs, n=16):
        s = lambda u: math.sin(C.TAU * u)
        up = lambda u: max(0.0, math.sin(math.pi * (2 * u % 1))) if u < 1 else 0.0
        return {
            "root": [tr(L, lambda u: (0, height * up(u), 0), n, "position"),
                     tr(L, lambda u: (4 * s(2 * u), 0, 0), n)],
            "neck": [tr(L, lambda u: (chomp * max(0.0, s(2 * u)), 0, 0), n)],
            "LegFL": [tr(L, lambda u: (legs * up(u), 0, 0), n)],
            "LegFR": [tr(L, lambda u: (legs * up(u), 0, 0), n)],
            "LegHL": [tr(L, lambda u: (-legs * up(u), 0, 0), n)],
            "LegHR": [tr(L, lambda u: (-legs * up(u), 0, 0), n)],
        }

    L = 2.0
    idle = (L, {"root": [tr(L, lambda u: (0, 1.5 * math.sin(C.TAU * u), 0), 16, "position")],
                "neck": [tr(L, lambda u: (6 * max(0.0, math.sin(C.TAU * u)) ** 4, 0, 0), 16)]})
    return {"idle": idle, "walk": (1.0, hop(1.0, 8, 14, 20)), "gallop": (0.6, hop(0.6, 18, 26, 40))}


if __name__ == "__main__":
    C.publish(creampuff(), still="--still" in sys.argv)
