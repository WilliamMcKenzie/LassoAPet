"""Gumdrop Frog: World 3 Candyland Uncommon. A squat frog shaped like a lime gumdrop: a
stepped dome body (widest at the bottom like a gumdrop) rolled in white sugar crystals, a
darker lime base band, a wide frog head with two bulging eye turrets on top (googly plates
facing forward), a wide chocolate grin with a cherry tongue tip, bubblegum cheeks, short
front legs and big folded hind thighs with webbed feet. It hops (the quadruped leap gallop).

    python3 tools/gumdrop_frog.py [--still]
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402

GUM = C.LIME
GUM_DK = C.LIME_DK
BELLY = (196, 246, 120)
SUGAR = C.WHITE


def gumdrop_frog(name="GumdropFrog", rarity="Uncommon", gum=GUM, gum_dk=GUM_DK, belly=BELLY):
    a = Animal(name, rarity)
    x, y0, y1, z0, z1 = 2.1, 1.1, 3.4, -2.0, 2.4
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Base", (-x, y0, z0), (x, y0 + 0.5, z1), gum_dk, "root")
    a.box("Body", (-x, y0 + 0.5, z0), (x, y1, z1), gum, "root")
    a.box("Dome1", (-x + 0.4, y1, z0 + 0.3), (x - 0.4, y1 + 0.7, z1 - 0.3), gum, "root")
    a.box("Dome2", (-x + 0.9, y1 + 0.7, z0 + 0.7), (x - 0.9, y1 + 1.2, z1 - 0.7), gum, "root")
    a.box("Belly", (-1.5, y0 - 0.15, z0 + 0.3), (1.5, y0, z1 - 0.5), belly, "root")
    # sugar crystals rolled all over the dome
    grains = [(-1.6, y1, -1.4), (1.3, y1, -0.6), (-1.5, y1, 1.2), (1.5, y1, 1.8), (-0.6, y1 + 0.7, -1.0),
              (0.7, y1 + 0.7, 0.2), (-0.8, y1 + 0.7, 1.5), (0.2, y1 + 1.2, -0.4), (-0.3, y1 + 1.2, 0.9),
              (0.9, y1 + 0.7, -1.2)]
    for i, (gx, gy, gz) in enumerate(grains):
        a.box(f"Sugar{i + 1}", (gx - 0.14, gy, gz - 0.14), (gx + 0.14, gy + 0.2, gz + 0.14), SUGAR, "root")
    for i, (gy, gz) in enumerate(((2.2, -0.8), (2.9, 0.9), (1.9, 1.7))):
        C.sym(a, f"SideSugar{i + 1}*", (x, gy - 0.14, gz - 0.14), (x + 0.18, gy + 0.14, gz + 0.14), SUGAR, "root")

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
    C.sym(a, "Nostril*", (0.25, hy1 - 0.45, hz0 - 0.06), (0.45, hy1 - 0.3, hz0), GUM_DK, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.45, sx * 1.75))
        a.box("Turret" + side, (xa, hy1, -3.7), (xb, hy1 + 1.4, -2.3), gum, "neck")
        xc, xd = sorted((sx * 0.6, sx * 1.6))
        a.box("TurretTop" + side, (xc, hy1 + 1.4, -3.55), (xd, hy1 + 1.65, -2.45), gum, "neck")
        a.box("Sugar" + side + "T", (sx * 1.1 - 0.13, hy1 + 1.65, -3.1), (sx * 1.1 + 0.13, hy1 + 1.82, -2.84), SUGAR, "neck")
    C.front_eyes(a, 1.1, hy1 + 0.2, hy1 + 1.3, -3.7, 1.05, "neck")
    a.pivots["neck"] = (0, 2.0, -1.95)

    # EarL/EarR stay as empty bones for the quadruped animations; a sugar-tipped tail nub
    a.pivots["EarL"] = (-1.1, 4.6, -3.0)
    a.pivots["EarR"] = (1.1, 4.6, -3.0)
    a.box("Tail", (-0.4, 1.6, z1), (0.4, 2.3, z1 + 0.45), gum, "Tail")
    a.pivots["Tail"] = (0, 2.3, z1)

    a.meta = {"seat": (0, y1 + 1.2, 0.3), "neck_loop": {"center": (0, 2.6, -3.0), "radius": 2.3}}
    a.animations = quad_animations
    return a


if __name__ == "__main__":
    C.publish(gumdrop_frog(), still="--still" in sys.argv)
