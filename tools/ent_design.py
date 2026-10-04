"""Ent (Godlands): QM's pixel tree. A brown trunk with a face (glowing yellow eyes, a dark
open mouth), branch arms reaching out and down to twig fingers, a chunky green canopy,
and roots splaying out round its base instead of legs (QM, Oct 4).

Run: python3 tools/ent_design.py [out_dir]   writes Ent.bbmodel and previews
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

BARK = (128, 82, 42)
BARK_DARK = (98, 60, 30)
ROOT = (88, 54, 28)
LEAF = (104, 192, 64)
LEAF_LIGHT = (140, 216, 88)
LEAF_DARK = (70, 150, 48)
EYE = (255, 232, 90)
MOUTH = (44, 26, 14)


def ent():
    a = A.Animal("Ent", "Epic")
    # roots on the leg bones (they can shuffle it along), arms, and the canopy on the neck
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root")]
    a.bone_order += [("Leg" + leg, "root") for leg in A.LEGS]
    a.animations = lambda: {}
    a.pivots["root"] = (0, 4.0, 0)
    a.box("Trunk", (-1.4, 0.4, -1.2), (1.4, 8.0, 1.2), BARK, "root")
    a.box("Bark", (-0.5, 0.4, 1.2), (0.5, 7.0, 1.4), BARK_DARK, "root")
    # face: glowing eyes, a long open mouth
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 0.85))
        a.box("GlowEye" + side, (xa, 6.0, -1.25), (xb, 6.6, -1.2), EYE, "root")
    a.box("Mouth", (-0.3, 4.2, -1.25), (0.3, 5.4, -1.2), MOUTH, "root")
    a.box("Brow", (-1.0, 6.6, -1.4), (1.0, 6.9, -1.2), BARK_DARK, "root")
    # roots: out from each corner of the base, thick then thin
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        sz = -1 if leg[0] == "F" else 1
        bone = "Leg" + leg
        xa, xb = sorted((sx * 0.6, sx * 2.2))
        za, zb = sorted((sz * 0.4, sz * 2.0))
        a.box("Root" + leg, (xa, 0, za), (xb, 0.9, zb), ROOT, bone)
        xa, xb = sorted((sx * 2.2, sx * 3.0))
        za, zb = sorted((sz * 1.4, sz * 2.8))
        a.box("RootTip" + leg, (xa, 0, za), (xb, 0.5, zb), ROOT, bone)
        a.pivots[bone] = (sx * 1.0, 0.9, sz * 0.8)
    a.box("RootFront", (-0.4, 0, -2.6), (0.4, 0.6, -1.2), ROOT, "root")
    a.box("RootBack", (-0.4, 0, 1.2), (0.4, 0.6, 2.6), ROOT, "root")
    # arms out and down, twig fingers at the ends
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side
        xa, xb = sorted((sx * 1.4, sx * 3.4))
        a.box(bone, (xa, 5.6, -0.35), (xb, 6.3, 0.35), BARK, bone)
        xa, xb = sorted((sx * 2.8, sx * 3.4))
        a.box("Forearm" + side, (xa, 3.8, -0.3), (xb, 5.6, 0.3), BARK, bone)
        xa, xb = sorted((sx * 3.4, sx * 3.9))
        a.box("TwigOut" + side, (xa, 3.6, -0.25), (xb, 4.2, 0.25), BARK_DARK, bone)
        xa, xb = sorted((sx * 2.3, sx * 2.8))
        a.box("TwigIn" + side, (xa, 3.3, -0.25), (xb, 3.9, 0.25), BARK_DARK, bone)
        xa, xb = sorted((sx * 2.9, sx * 3.3))
        a.box("TwigDown" + side, (xa, 3.2, -0.25), (xb, 3.8, 0.25), BARK_DARK, bone)
        a.pivots[bone] = (sx * 1.4, 5.95, 0)
    # canopy: a big chunk of leaves with clumps round it and branches poking out
    a.box("Leaves", (-2.6, 8.0, -2.2), (2.6, 10.4, 2.2), LEAF, "neck")
    a.box("LeavesTop", (-1.6, 10.4, -1.4), (1.4, 11.4, 1.4), LEAF_LIGHT, "neck")
    a.box("LeavesL", (-3.4, 8.4, -1.0), (-2.6, 9.8, 1.0), LEAF_LIGHT, "neck")
    a.box("LeavesR", (2.6, 8.8, -0.6), (3.4, 10.0, 1.4), LEAF_LIGHT, "neck")
    a.box("LeavesFrontL", (-2.2, 7.4, -2.6), (-0.4, 8.4, -1.8), LEAF_DARK, "neck")
    a.box("LeavesFrontR", (0.8, 7.6, -2.6), (2.4, 8.4, -1.8), LEAF_DARK, "neck")
    a.box("LeavesBack", (-1.8, 7.6, 1.8), (1.8, 8.6, 2.6), LEAF_DARK, "neck")
    a.box("Branch1", (2.6, 9.8, -1.6), (3.2, 10.2, -0.9), BARK_DARK, "neck")
    a.box("Branch2", (-3.0, 10.0, 1.0), (-2.6, 10.6, 1.6), BARK_DARK, "neck")
    a.pivots["neck"] = (0, 8.0, 0)
    a.meta = {"seat": (0, 11.4, 0.4), "neck_loop": {"center": (0, 7.4, 0), "radius": 1.9}}
    return a


def main(out="designs/godlands"):
    os.makedirs(out, exist_ok=True)
    a = ent()
    m = A.build_animal(a, out)
    cams = [dict(eye=(-16, 10, -19), target=(0, 5.6, 0), W=440, H=480, fov=36),
            dict(eye=(0, 7, -24), target=(0, 5.6, 0), W=440, H=480, fov=34),
            dict(eye=(18, 9, 15), target=(0, 5.6, 0), W=440, H=480, fov=36),
            dict(eye=(-24, 6, 0), target=(0, 5.6, 0), W=440, H=480, fov=34)]
    sheet = Image.new("RGB", (440 * len(cams), 480))
    for i, c in enumerate(cams):
        sheet.paste(render(pose(m, None, 0), **c), (440 * i, 0))
    sheet.save(os.path.join(out, "Ent.png"))
    print(f"Ent: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
