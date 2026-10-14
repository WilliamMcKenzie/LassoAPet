"""Desire Troll: World 3 Candyland Legendary (after the Candyland Hunting Grounds Desire Troll).
A hulking strawberry-pink troll knuckle-walking on huge fists: massive shoulders, a small
head sunk low in front with a big underbite and two candy-corn tusks (white, orange and
lemon, tipped with pyramids), heavy grape brows, a fat nose, a cotton-candy tuft of hair,
peppermint-striped wrist cuffs, short stumpy legs, a row of rainbow gumdrop spikes down the
back and a lemon candy-wrapper saddle (its twisted ends are pyramids). Large tier.

Quadruped bones (the arms are LegFL/LegFR) with the Giant Golem's heavy walk and
knuckle-run. Nothing turned.

    python3 tools/desire_troll.py [--still]
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
import giant_golem  # noqa: E402
from animal_designs import Animal  # noqa: E402
from snow_designs import pyramid  # noqa: E402

SKIN = C.STRAWB
SKIN_DK = C.STRAWB_DK
BELLY = C.BUBBLE
BROW = C.GRAPE_DK


def troll(name="DesireTroll", rarity="Legendary"):
    a = Animal(name, rarity)
    a.dims = dict(x=2.4, y0=3.6, y1=7.6, z0=-3.0, z1=3.0)
    a.pivots["root"] = (0, 5.6, 0)
    a.box("Body", (-2.4, 3.8, -3.0), (2.4, 7.6, 3.0), SKIN, "root")
    a.box("Hump", (-2.0, 7.6, -3.0), (2.0, 8.4, -0.6), SKIN, "root")
    a.box("Belly", (-1.9, 3.4, -2.6), (1.9, 3.8, 2.4), BELLY, "root")
    a.box("Chest", (-1.9, 4.0, -3.3), (1.9, 6.8, -3.0), BELLY, "root")
    a.box("Rump", (-2.0, 4.2, 3.0), (2.0, 7.2, 3.4), SKIN_DK, "root")
    # rainbow gumdrop spikes down the back
    for i, (z, col) in enumerate(((-2.5, C.CHERRY), (-1.6, C.ORANGE), (1.9, C.LIME), (2.7, C.SKY))):
        y = 8.4 if z < -0.6 else 7.6
        pyramid(a, f"Gumdrop{i + 1}", (-0.4, y, z - 0.4), (0.4, y, z + 0.4), "+y", 1.0 if i in (0, 3) else 1.3, col, "root")
    # lemon candy-wrapper saddle with twisted ends
    a.box("Saddle", (-1.6, 7.6, -0.6), (1.6, 8.2, 1.6), C.LEMON, "root")
    a.box("SaddleBand", (-1.65, 7.6, 0.35), (1.65, 8.25, 0.65), C.LEMON_DK, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.6, sx * 1.95))
        a.box("Twist" + side, (xa, 7.65, 0.2), (xb, 8.15, 0.8), C.LEMON_DK, "root")
        pyramid(a, "Wrapper" + side, (sx * 1.95, 7.5, -0.1), (sx * 1.95, 8.3, 1.1), "+x" if sx > 0 else "-x", 0.9, C.LEMON, "root")

    # ---- arms (front legs): boulder shoulders, forearms, big fists, peppermint cuffs
    for leg, sx in (("FL", -1), ("FR", 1)):
        bone = "Leg" + leg

        def xs(p, q):
            return tuple(sorted((sx * p, sx * q)))
        lo, hi = xs(2.3, 4.8)
        a.box("Shoulder" + leg, (lo, 6.0, -3.8), (hi, 8.8, -0.4), SKIN, bone)
        lo, hi = xs(2.6, 4.5)
        a.box("ShoulderTop" + leg, (lo, 8.8, -3.4), (hi, 9.2, -0.8), SKIN, bone)
        lo, hi = xs(2.6, 4.5)
        a.box("Forearm" + leg, (lo, 2.2, -3.3), (hi, 6.0, -0.9), SKIN, bone)
        for k, col in enumerate((C.CHERRY, C.ICING, C.CHERRY)):
            lo, hi = xs(2.45, 4.65)
            a.box(f"Cuff{leg}{k + 1}", (lo, 2.2 + 0.35 * k, -3.45), (hi, 2.55 + 0.35 * k, -0.75), col, bone)
        lo, hi = xs(2.3, 4.8)
        a.box("Fist" + leg, (lo, 0, -3.8), (hi, 2.2, -0.5), SKIN_DK, bone)
        for i in range(3):
            k0, k1 = xs(2.45 + 0.8 * i, 3.1 + 0.8 * i)
            a.box(f"Knuckle{leg}{i + 1}", (k0, 0.2, -4.25), (k1, 1.9, -3.8), SKIN, bone)
        a.pivots[bone] = (sx * 3.5, 8.2, -2.1)

    # ---- short stumpy legs
    for leg, sx in (("HL", -1), ("HR", 1)):
        bone = "Leg" + leg
        lo, hi = sorted((sx * 0.6, sx * 2.3))
        a.box(bone, (lo, 0.8, 1.0), (hi, 4.0, 3.0), SKIN, bone)
        fl, fh = sorted((sx * 0.4, sx * 2.5))
        a.box("Foot" + leg, (fl, 0, 0.4), (fh, 0.8, 3.2), SKIN_DK, bone)
        for i in range(2):
            t0, t1 = sorted((sx * (0.55 + 1.0 * i), sx * (1.35 + 1.0 * i)))
            pyramid(a, f"Claw{leg}{i + 1}", (t0, 0.05, 0.4), (t1, 0.65, 0.4), "-z", 0.5, C.ICING, bone)
        a.pivots[bone] = (sx * 1.45, 3.9, 1.1)

    # ---- head (neck): sunk low, underbite, candy-corn tusks, cotton-candy hair
    a.box("Head", (-1.5, 5.6, -5.2), (1.5, 8.2, -2.8), SKIN, "neck")
    a.box("Jaw", (-1.7, 4.8, -5.6), (1.7, 5.9, -3.0), BELLY, "neck")
    a.box("Mouth", (-1.4, 5.9, -5.62), (1.4, 6.05, -5.2), SKIN_DK, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        c = sx * 1.35
        a.box("TuskW" + side, (c - 0.3, 5.9, -5.55), (c + 0.3, 6.35, -4.95), C.ICING, "neck")
        a.box("TuskO" + side, (c - 0.27, 6.35, -5.52), (c + 0.27, 6.75, -4.98), C.ORANGE, "neck")
        pyramid(a, "TuskY" + side, (c - 0.27, 6.75, -5.52), (c + 0.27, 6.75, -4.98), "+y", 0.6, C.LEMON, "neck")
    a.box("Nose", (-0.55, 6.5, -5.75), (0.55, 7.3, -5.2), SKIN_DK, "neck")
    C.front_eyes(a, 0.7, 7.15, 7.95, -5.2, 0.65, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        C.rbox(a, "Brow" + side, (1.3, 0.4, 0.45), C.T(sx * 0.7, 8.08, -5.25) @ C.Rz(sx * 14), BROW, "neck")
    C.sym(a, "Ear*", (1.5, 6.6, -4.4), (1.9, 7.4, -3.6), SKIN, "neck")
    C.sym(a, "EarTip*", (1.9, 6.8, -4.2), (2.3, 7.2, -3.8), SKIN_DK, "neck")
    # cotton-candy hair tuft: stepped puffs in three colours
    a.box("Hair", (-1.3, 8.2, -4.8), (1.3, 8.9, -2.9), C.LILAC, "neck")
    a.box("HairPuff1", (-0.9, 8.9, -4.4), (0.5, 9.6, -3.1), C.BUBBLE, "neck")
    a.box("HairPuff2", (0.2, 8.9, -3.9), (1.1, 9.4, -2.9), C.SKY, "neck")
    a.box("HairPuff3", (-0.5, 9.6, -4.0), (0.2, 10.0, -3.3), C.LILAC, "neck")
    a.pivots["neck"] = (0, 6.0, -2.9)

    a.pivots["EarL"] = (-1.7, 7.0, -4.0)
    a.pivots["EarR"] = (1.7, 7.0, -4.0)
    a.box("Tail", (-0.4, 5.0, 3.4), (0.4, 5.8, 4.0), SKIN_DK, "Tail")
    a.pivots["Tail"] = (0, 5.8, 3.4)
    a.meta = {"seat": (0, 8.2, 0.5), "neck_loop": {"center": (0, 7.0, -4.0), "radius": 2.2}}
    a.animations = giant_golem.animations
    return a


if __name__ == "__main__":
    C.publish(troll(), still="--still" in sys.argv)
