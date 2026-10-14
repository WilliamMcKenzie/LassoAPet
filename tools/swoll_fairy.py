"""Swoll Fairy: World 3 Candyland Epic (after the Candyland Hunting Grounds Swoll Fairy).
A hugely muscly bubblegum-pink fairy hovering upright and flexing both biceps: a mint tank
top, a lilac tutu, a grape hair bun with a cherry bow, googly eyes and a cheeky grin, mint
slippers with pyramid toes, and two pairs of candy-glass wings (sky blue and lilac) buzzing
on her back. The rider sits on a strawberry cushion strapped high on her back. Flies
(SprintSpecials Fly).

Bones: root (body) -> neck (head), ArmL, ArmR (flexing), WingL, WingR (flap about Y),
LegHL, LegHR (dangling). Rests baked, all bones at 0.

    python3 tools/swoll_fairy.py [--still]
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal  # noqa: E402
from snow_designs import pyramid  # noqa: E402

SKIN = C.BUBBLE
SKIN_DK = C.BUBBLE_DK
TOP = C.MINT
TOP_DK = C.MINT_DK
TUTU = C.LILAC
HAIR = C.GRAPE
WING = C.SKY
WING_DK = C.SKY_DK


def swoll_fairy(name="SwollFairy", rarity="Epic"):
    a = Animal(name, rarity)
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root"),
                    ("WingL", "root"), ("WingR", "root"), ("LegHL", "root"), ("LegHR", "root")]
    # ---- torso: broad chest in a mint tank top over a narrow waist, bulging delts
    a.box("Chest", (-2.0, 4.6, -1.1), (2.0, 6.8, 1.1), TOP, "root")
    a.box("Waist", (-1.3, 3.4, -0.9), (1.3, 4.6, 0.9), TOP_DK, "root")
    a.box("Collar", (-1.0, 6.3, -1.2), (1.0, 6.8, 1.0), SKIN, "root")
    C.sym(a, "Delt*", (1.9, 5.6, -1.0), (3.0, 7.0, 1.0), SKIN, "root")
    C.sym(a, "Strap*", (1.1, 6.8, -1.15), (1.7, 7.0, 1.15), TOP_DK, "root")
    # tutu: a wide skirt with a grape frill
    a.box("Tutu", (-2.4, 3.2, -1.6), (2.4, 4.0, 1.6), TUTU, "root")
    a.box("TutuFrill", (-2.8, 3.35, -2.0), (2.8, 3.75, 2.0), C.GRAPE, "root")
    # strawberry cushion strapped high on her back for the rider
    a.box("Cushion", (-1.3, 5.4, 1.1), (1.3, 6.9, 2.3), C.STRAWB, "root")
    a.box("CushionTop", (-1.0, 6.9, 1.25), (1.0, 7.1, 2.15), C.STRAWB_DK, "root")

    # ---- head (neck bone): hair cap, bun and bow
    a.box("Head", (-1.2, 6.8, -1.1), (1.2, 9.0, 1.1), SKIN, "neck")
    a.box("Hair", (-1.3, 8.6, -1.2), (1.3, 9.3, 1.2), HAIR, "neck")
    a.box("HairBack", (-1.3, 7.2, 0.8), (1.3, 8.6, 1.2), HAIR, "neck")
    a.box("Bun", (-0.6, 9.3, -0.4), (0.6, 10.2, 0.8), HAIR, "neck")
    C.sym(a, "Bow*", (0.6, 9.45, -0.2), (1.2, 9.95, 0.6), C.CHERRY, "neck")
    C.front_eyes(a, 0.58, 7.8, 8.65, -1.1, 0.78, "neck")
    a.box("Grin", (-0.55, 7.25, -1.17), (0.55, 7.45, -1.1), C.CHERRY_DK, "neck")
    a.box("Nose", (-0.18, 7.65, -1.3), (0.18, 7.95, -1.1), SKIN_DK, "neck")
    C.sym(a, "Cheek*", (0.75, 7.5, -1.15), (1.05, 7.75, -1.1), C.STRAWB, "neck")
    a.pivots["neck"] = (0, 6.8, 0)

    # ---- double-biceps flex: upper arm out sideways, forearm up, big fist
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side

        def xs(p, q):
            return tuple(sorted((sx * p, sx * q)))
        lo, hi = xs(2.8, 4.6)
        a.box("Upper" + side, (lo, 5.9, -0.7), (hi, 7.1, 0.7), SKIN, bone)
        lo, hi = xs(3.1, 4.3)
        a.box("Bicep" + side, (lo, 7.1, -0.6), (hi, 7.6, 0.6), SKIN, bone)
        lo, hi = xs(3.7, 4.9)
        a.box("Forearm" + side, (lo, 7.1, -0.6), (hi, 9.1, 0.6), SKIN, bone)
        a.box("Cuff" + side, (lo - 0.05, 8.8, -0.65), (hi + 0.05, 9.1, 0.65), C.LEMON, bone)
        lo, hi = xs(3.55, 5.05)
        a.box("Fist" + side, (lo, 9.1, -0.75), (hi, 10.3, 0.75), SKIN, bone)
        a.box("Knuckles" + side, (lo + 0.1, 9.2, -0.85), (hi - 0.1, 10.2, -0.75), SKIN_DK, bone)
        a.pivots[bone] = (sx * 2.8, 6.5, 0)

    # ---- legs dangling, mint slippers with pyramid toes
    for side, sx in (("L", -1), ("R", 1)):
        bone = "LegH" + side
        xa, xb = sorted((sx * 0.25, sx * 1.2))
        a.box("Leg" + side, (xa, 1.0, -0.5), (xb, 3.3, 0.5), SKIN, bone)
        a.box("Slipper" + side, (xa - 0.05, 0.3, -0.6), (xb + 0.05, 1.0, 0.6), TOP, bone)
        pyramid(a, "Toe" + side, (xa, 0.4, -0.6), (xb, 0.9, -0.6), "-z", 0.6, TOP_DK, bone)
        a.pivots[bone] = ((xa + xb) / 2, 3.3, 0)

    # ---- two pairs of candy-glass wings fanning out from her back (flap about Y)
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Wing" + side
        base = (sx * 0.5, 4.9, 1.2)
        for j, (ang, L, wd, col, edge) in enumerate(((58, 5.6, 2.2, WING, WING_DK), (-15, 2.8, 0.9, C.LILAC, C.GRAPE))):
            M = C.T(*base) @ C.Rz(sx * ang) @ C.T(sx * L / 2, 0, 0.15 * j)
            C.rbox(a, f"{bone}Pane{j + 1}", (L, wd, 0.3), M, col, bone)
            C.rbox(a, f"{bone}Edge{j + 1}", (0.35, wd + 0.1, 0.36), M @ C.T(sx * (L / 2 - 0.17), 0, 0), edge, bone)
        a.pivots[bone] = base

    a.pivots["root"] = (0, 5.0, 0)
    a.meta = {"seat": (0, 7.1, 1.7), "neck_loop": {"center": (0, 8.0, 0), "radius": 1.7}}
    a.animations = animations
    return a


def animations():
    tr = C.track

    def fly(L, beats, amp, bob, flex, lean, n=24):
        w = lambda u, ph=0.0: math.sin(C.TAU * (beats * u - ph))
        s = lambda u: math.sin(C.TAU * u)
        return {
            "root": [tr(L, lambda u: (-lean, 0, 3 * s(u)), n),
                     tr(L, lambda u: (0, bob * s(u), 0), n, "position")],
            "neck": [tr(L, lambda u: (lean * 0.5, 0, -4 * s(u)), n)],
            "WingL": [tr(L, lambda u: (0, amp * w(u), 0), n)],
            "WingR": [tr(L, lambda u: (0, -amp * w(u), 0), n)],
            "ArmL": [tr(L, lambda u: (0, 0, -flex * max(0.0, s(2 * u))), n)],
            "ArmR": [tr(L, lambda u: (0, 0, flex * max(0.0, s(2 * u))), n)],
            "LegHL": [tr(L, lambda u: (12 * s(u) + lean, 0, 0), n)],
            "LegHR": [tr(L, lambda u: (-12 * s(u) + lean, 0, 0), n)],
        }

    return {"idle": (1.6, fly(1.6, 8, 30, 6, 8, 0)), "walk": (1.0, fly(1.0, 6, 32, 5, 10, 8)),
            "gallop": (0.6, fly(0.6, 4, 38, 4, 14, 18))}


if __name__ == "__main__":
    C.publish(swoll_fairy(), still="--still" in sys.argv)
