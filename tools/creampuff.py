"""Creampuff: World 3 Candyland Rare (after the Candyland Hunting Grounds creampuffs).
A grumpy cream puff: a golden choux bun cut in half with a fat puffy ring of whipped cream
between, the top half a round lid that chomps open and shut like a mouth, a cherry on top,
powdered sugar, googly eyes with chocolate brows and four stubby pastry feet. It hops. (QM, Oct 15: no longer spoiled; the bun, cream, lid and cherry are smooth
meshes.)

Bones: root (bottom bun and cream), neck (the lid: opens with +X), EarL/EarR empty, Tail
empty, Leg* (feet). Nothing turned.

    python3 tools/creampuff.py [--still]
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal  # noqa: E402

BUN = C.PASTRY
BUN_DK = C.PASTRY_DK
CREAM = C.WHITE


def creampuff(name="Creampuff", rarity="Rare"):
    a = Animal(name, rarity)
    x, y0, y1, z0, z1 = 2.4, 0.9, 2.6, -2.4, 2.4
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, 2.0, 0)
    # bottom bun: a squashed round bun, flat underneath and cut flat on top
    P = C.G.ellipsoid((0, 1.95, 0), (x, 1.25, x), seg=14, rings=7)
    P[:, 1] = np.clip(P[:, 1], y0, y1 + 0.1)
    C.hull(a, "SmoothBun", P, BUN, "root")
    # whipped cream piped round the cut: a ring of fat puffs bulging out past the bun
    C.hull(a, "SmoothCream", C.G.ellipsoid((0, y1 + 0.45, 0), (x - 0.1, 0.55, x - 0.1), seg=14, rings=5), CREAM, "root")
    for k in range(10):
        t = C.TAU * (k + 0.5) / 10
        C.hull(a, "SmoothCream", C.G.ellipsoid((2.05 * math.sin(t), y1 + 0.45, 2.05 * math.cos(t)), (0.8, 0.62, 0.8), seg=8, rings=4), CREAM, "root")

    # four stubby feet
    for leg in ("FL", "FR", "HL", "HR"):
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.8, sx * 1.9))
        za = -2.0 if front else 0.9
        a.box("Leg" + leg, (xa, 0, za), (xb, y0 + 0.35, za + 1.1), BUN_DK, "Leg" + leg)
        a.pivots["Leg" + leg] = ((xa + xb) / 2, y0, za + (1.0 if front else 0.1))

    # ---- the lid (neck bone, hinged at the back of the cream): a round choux dome
    ly0 = y1 + 0.9
    r, h = 2.5, 1.9
    C.hull(a, "SmoothLid", C.G.dome((0, ly0, 0), r, h, seg=14, rings=5, base=0.25), BUN, "neck")

    def surf(phi, az):
        """A point on the lid (phi up from its rim, az round from the front) and its normal."""
        p_, a_ = math.radians(phi), math.radians(az)
        q = np.array((r * math.cos(p_) * math.sin(a_), ly0 + h * math.sin(p_), -r * math.cos(p_) * math.cos(a_)))
        n = np.array(((q[0]) / r ** 2, (q[1] - ly0) / h ** 2, q[2] / r ** 2))
        return q, n / np.linalg.norm(n)

    def on_lid(name, phi, az, size, col, turn=0.0):
        q, n = surf(phi, az)
        C.stick(a, name, q, n, size, col, "neck", turn)

    # powdered sugar dusting
    for i, (phi, az) in enumerate(((62, 140), (58, 230), (66, 320), (55, 50), (72, 190))):
        on_lid(f"Sugar{i + 1}", phi, az, (0.3, 0.3, 0.12), C.ICING)
    # a round cherry with a stem
    C.hull(a, "SmoothCherry", C.G.ellipsoid((0, ly0 + h + 0.45, 0), (0.55, 0.5, 0.55), seg=10, rings=5), C.CHERRY, "neck")
    C.beam(a, "Stem", (0, ly0 + h + 0.85, 0), (0.35, ly0 + h + 1.6, 0.25), 0.14, 0.14, C.LIME_DK, "neck")
    # googly eyes on the lid front, chocolate brows slanting down to the middle
    for side, sx in (("L", -1), ("R", 1)):
        q, n = surf(24, sx * 22)
        C.surface_eye(a, side, q, n, 0.9, 1.0, "neck")
        on_lid("Brow" + side, 50, sx * 20, (1.2, 0.3, 0.3), C.CHOC, sx * 16)
    a.pivots["neck"] = (0, ly0, 2.2)

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
