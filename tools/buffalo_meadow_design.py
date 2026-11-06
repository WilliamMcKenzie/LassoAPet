"""Buffalo, redone for World 1's Meadow (QM, Nov 6: "redo buffalo"), built the way QM's
Kitten and Sandworm are (designs/desert/): a few big stepped sections instead of many small
blocks. A tall dark shaggy hump with a fringe under it, a lower, narrower brown back half,
a low heavy head with a pale snout, a beard and a tuft, cream horns running out sideways
and turning up at grey tips, small ears under them, thick dark front legs and a tasselled
tail. Same colours as tools/buffalo_design.py (World 2's, which this replaces in game),
so its egg and palette still fit.

Same bones and rules as every quadruped (root, neck, EarL, EarR, Tail, Leg*); walk is
QM's horse walk, the gallop the shared leap.

    python3 tools/buffalo_meadow_design.py
    python3 tools/bbmodel_to_luau.py designs/animals/Buffalo.bbmodel src/shared/Animals/BuffaloModel.luau
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from buffalo_design import COAT, FUR, SNOUT, HORN, HORN_TIP, HOOF, NOSTRIL  # noqa: E402


def buffalo():
    a = Animal("Buffalo", "Rare")
    # the hump up front, tall and shaggy with a fringe hanging under it; the back half
    # stepped down and in
    a.box("Hump", (-2.0, 3.0, -3.0), (2.0, 7.4, 0.2), FUR, "root")
    a.box("Fringe", (-2.1, 2.4, -3.0), (2.1, 3.0, 0.0), FUR, "root")
    a.box("Body", (-1.8, 3.2, 0.2), (1.8, 6.4, 3.6), COAT, "root")
    a.dims = dict(x=2.0, y0=3.0, y1=7.4, z0=-3.0, z1=3.6)
    a.pivots["root"] = (0, 5.0, 0.3)
    # thick shaggy front legs, slimmer brown hind legs, dark hooves
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.5, sx * (1.9 if front else 1.6)))
        za, zb = (-2.8, -1.4) if front else (2.2, 3.4)
        top = 3.0 if front else 3.2
        name = "Leg" + leg
        a.box(name, (xa, 0.6, za), (xb, top, zb), FUR if front else COAT, name)
        a.box("Hoof" + leg, (xa, 0, za), (xb, 0.6, zb), HOOF, name)
        a.pivots[name] = ((xa + xb) / 2, top - 0.025, zb - 0.05 if front else za + 0.05)

    # the head hangs low off the hump's front: pale snout, beard under the chin, a tuft on top
    a.box("Head", (-1.4, 2.6, -5.4), (1.4, 5.4, -2.999), FUR, "neck")
    a.box("Snout", (-1.0, 2.6, -6.2), (1.0, 4.2, -5.4), SNOUT, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.7))
        a.box("Nostril" + side, (xa, 3.5, -6.25), (xb, 3.8, -6.2), NOSTRIL, "neck")
    a.box("Beard", (-0.7, 1.8, -5.6), (0.7, 2.6, -4.0), FUR, "neck")
    a.box("Tuft", (-1.0, 5.4, -5.0), (1.0, 5.9, -3.6), FUR, "neck")
    a.eyes(1.4, 3.9, 4.7, -5.1, -4.3)
    a.pivots["neck"] = (0, 5.0, -3.0)
    # horns: out the sides, then up to grey tips; small ears just under them
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.4, sx * 2.4))
        a.box("Horn" + side, (xa, 4.6, -4.7), (xb, 5.1, -4.1), HORN, "neck")
        ua, ub = sorted((sx * 1.95, sx * 2.4))
        a.box("HornUp" + side, (ua, 5.1, -4.7), (ub, 5.8, -4.1), HORN, "neck")
        a.box("HornTip" + side, (ua, 5.8, -4.65), (ub, 6.2, -4.15), HORN_TIP, "neck")
        bone = "Ear" + side
        ea, eb = sorted((sx * 1.4, sx * 2.0))
        a.box(bone, (ea, 3.9, -3.9), (eb, 4.4, -3.4), FUR, bone)
        a.pivots[bone] = (sx * 1.4, 4.15, -3.65)

    # thin tail with a dark tassel
    a.box("Tail", (-0.2, 4.6, 3.6), (0.2, 6.0, 4.0), COAT, "Tail")
    a.box("TailTuft", (-0.35, 3.8, 3.55), (0.35, 4.6, 4.1), FUR, "Tail")
    a.pivots["Tail"] = (0, 6.0, 3.6)

    a.meta = {"seat": (0, 7.2, 1.6), "neck_loop": {"center": (0, 4.2, -4.4), "radius": 2.2}}
    a.animations = quad_animations
    a.scale(1.35)  # Rhino-sized and up, as World 2's was
    return a


def main(out=os.path.join(A.ROOT, "designs", "animals")):
    a = buffalo()
    A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
