"""Gumdrop Frog: World 3 Candyland Uncommon. A squat frog shaped like an orange gumdrop: a
smooth dome body (widest at the bottom like a gumdrop) rolled in white sugar crystals, a
darker orange base band, a wide frog head with two round smooth eye bumps on top (googly plates
facing forward), a wide chocolate grin with a cherry tongue tip, bubblegum cheeks, short
front legs and big folded hind thighs with webbed feet. It hops (the quadruped leap gallop).
(QM, Oct 15: the gumdrop, base band and eye bumps are smooth meshes.)

    python3 tools/gumdrop_frog.py [--still]
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402

GUM = C.ORANGE
GUM_DK = C.ORANGE_DK
BELLY = (255, 200, 120)
SUGAR = C.WHITE


def gumdrop_frog(name="GumdropFrog", rarity="Uncommon", gum=GUM, gum_dk=GUM_DK, belly=BELLY):
    a = Animal(name, rarity)
    x, y0, y1, z0, z1 = 2.1, 1.1, 3.4, -2.0, 2.4
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    # the gumdrop: a smooth dome (widest at the bottom) on a darker base band, rolled in sugar
    cz, rx, rz, h = (z0 + z1) / 2, x + 0.1, (z1 - z0) / 2 + 0.1, y1 + 1.7 - (y0 + 0.9)
    C.hull(a, "SmoothBase", C.G.prism((0, y0, cz), (rx + 0.08, rz + 0.08), 0.55, seg=16), gum_dk, "root")
    C.hull(a, "SmoothBody", C.G.dome((0, y0 + 0.9, cz), (rx, rz), h, seg=16, rings=5, base=0.75), gum, "root")
    a.box("Belly", (-1.5, y0 - 0.15, z0 + 0.3), (1.5, y0, z1 - 0.5), belly, "root")

    def surf(phi, az):
        p_, a_ = math.radians(phi), math.radians(az)
        q = np.array((rx * math.cos(p_) * math.sin(a_), y0 + 0.9 + h * math.sin(p_), cz - rz * math.cos(p_) * math.cos(a_)))
        n = np.array((q[0] / rx ** 2, (q[1] - y0 - 0.9) / h ** 2, (q[2] - cz) / rz ** 2))
        return q, n
    # sugar crystals rolled all over the dome (none on the front, where the head sits)
    for i in range(22):  # spread evenly (golden angle round, rising up the dome)
        phi, az = 8 + 70 * (i + 0.5) / 22, 55 + 250 * (i * 0.618 % 1)
        q, n = surf(phi, az)
        C.stick(a, f"Sugar{i + 1}", q, n, (0.28, 0.28, 0.2), SUGAR, "root", (i * 37) % 90)

    # ---- short front legs with three toes
    for side, sx in (("L", -1), ("R", 1)):
        bone = "LegF" + side
        xa, xb = sorted((sx * 1.0, sx * 1.8))
        a.box(bone, (xa, 0.3, z0 + 0.2), (xb, y0 + 0.05, z0 + 1.0), gum, bone)
        a.box("Foot" + bone, (xa - 0.15 * (sx < 0), 0, z0 - 0.2), (xb + 0.15 * (sx > 0), 0.3, z0 + 1.0), gum_dk, bone)
        a.pivots[bone] = ((xa + xb) / 2, y0, z0 + 0.95)

    # ---- big folded hind thighs on the flanks with long webbed feet
    for side, sx in (("L", -1), ("R", 1)):
        bone = "LegH" + side
        xa, xb = sorted((sx * x, sx * (x + 0.7)))
        a.box("Thigh" + side, (xa, 0.5, 0.2), (xb, 2.5, 2.4), gum, bone)
        a.box("Knee" + side, (xa, 0.5, -0.4), (xb, 1.3, 0.2), gum, bone)
        a.box("Shin" + side, (xa, 0.25, 0.8), (xb, 0.5, 2.6), gum_dk, bone)
        fa, fb = sorted((sx * (x - 0.1), sx * (x + 1.0)))
        a.box("Foot" + bone, (fa, 0, -1.1), (fb, 0.25, 0.2), gum_dk, bone)
        for k, tx in enumerate((0.0, 0.45, 0.9)):
            ta, tb = sorted((sx * (x - 0.1 + tx), sx * (x + 0.1 + tx)))
            a.box(f"Toe{side}{k + 1}", (ta, 0, -1.45), (tb, 0.25, -1.1), gum_dk, bone)
        a.pivots[bone] = ((xa + xb) / 2, 1.6, 0.3)

    # ---- wide frog head (neck bone) with eye turrets on top
    hx, hy0, hy1, hz0, hz1 = 1.9, 1.0, 3.2, -4.0, -1.9
    a.box("Head", (-hx, hy0 + 0.4, hz0), (hx, hy1, hz1), gum, "neck")
    a.box("Jaw", (-hx + 0.1, hy0, hz0 + 0.1), (hx - 0.1, hy0 + 0.4, hz1), belly, "neck")
    a.box("HeadTop", (-hx + 0.4, hy1, hz0 + 0.3), (hx - 0.4, hy1 + 0.35, hz1), gum, "neck")
    a.box("Mouth", (-hx + 0.25, hy0 + 0.35, hz0 - 0.06), (hx - 0.25, hy0 + 0.5, hz0), C.CHOC, "neck")
    C.sym(a, "MouthEnd*", (hx - 0.4, hy0 + 0.5, hz0 - 0.06), (hx - 0.25, hy0 + 0.75, hz0), C.CHOC, "neck")
    a.box("Tongue", (-0.35, hy0 + 0.1, hz0 - 0.25), (0.35, hy0 + 0.38, hz0 + 0.2), C.CHERRY, "neck")
    C.sym(a, "Cheek*", (1.05, hy0 + 0.7, hz0 - 0.08), (1.6, hy0 + 1.05, hz0), C.BUBBLE, "neck")
    C.sym(a, "Nostril*", (0.25, hy1 - 0.45, hz0 - 0.06), (0.45, hy1 - 0.3, hz0), gum_dk, "neck")
    for side, sx in (("L", -1), ("R", 1)):  # round eye bumps, googly eyes looking forward
        c = np.array((sx * 1.1, hy1 + 0.3, -3.0))
        C.hull(a, "SmoothTurret", C.G.ellipsoid(c, (0.8, 0.95, 0.8), seg=10, rings=5, cut=0.0), gum, "neck")
        d = np.array((sx * 0.25, 0.45, -1.0))
        d /= np.linalg.norm(d)
        C.surface_eye(a, side, c + d * np.array((0.8, 0.95, 0.8)), d, 0.95, 1.0, "neck")
    a.pivots["neck"] = (0, 2.0, -1.95)

    # EarL/EarR stay as empty bones for the quadruped animations; a sugar-tipped tail nub
    a.pivots["EarL"] = (-1.1, 4.6, -3.0)
    a.pivots["EarR"] = (1.1, 4.6, -3.0)
    a.box("Tail", (-0.4, 1.6, z1), (0.4, 2.3, z1 + 0.45), gum, "Tail")
    a.pivots["Tail"] = (0, 2.3, z1)

    a.meta = {"seat": (0, y1 + 1.7, 0.2), "neck_loop": {"center": (0, 2.6, -3.0), "radius": 2.3}}
    a.animations = quad_animations
    return a


if __name__ == "__main__":
    C.publish(gumdrop_frog(), still="--still" in sys.argv)
