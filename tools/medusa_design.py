"""Medusa (Godlands): QM's pixel sprite as a few blocks. A woman's top half on a snake's
coiled tail, a grey dress with a brown belt, arms held out, glowing red eyes, and hair
made of green pyramid spikes. QM (Oct 4): keep the block count low.

Run: python3 tools/medusa_design.py [out_dir]   writes Medusa.bbmodel and previews
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402
from snow_designs import pyramid  # noqa: E402

SKIN = (250, 222, 150)
DRESS = (204, 206, 212)
BELT = (150, 92, 40)
GREEN = (96, 184, 56)
GREEN_DARK = (58, 136, 44)
BELLY = (226, 232, 196)
EYE = (236, 40, 40)


def medusa():
    a = A.Animal("Medusa", "Legendary")
    a.bone_order = [("root", None), ("Tail", "root"), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root")]
    a.animations = lambda: {}
    # the snake: a thick coil under the dress, running back and curling round to the right
    a.box("Coil", (-1.5, 0, -1.4), (1.5, 2.8, 1.4), GREEN, "root")
    a.box("Belly", (-0.9, 0, -1.6), (0.9, 2.8, -1.4), BELLY, "root")
    a.box("Tail", (-1.1, 0, 1.4), (1.1, 1.4, 3.6), GREEN, "Tail")
    a.box("Tail2", (1.1, 0, 2.4), (3.6, 1.2, 3.6), GREEN_DARK, "Tail")
    a.box("Tail3", (2.4, 0, -0.8), (3.6, 1.0, 2.4), GREEN, "Tail")
    pyramid(a, "TailTip", (2.4, 0, -0.8), (3.6, 1.0, -0.8), "-z", 1.4, GREEN_DARK, "Tail")
    a.pivots["root"] = (0, 4.0, 0)
    a.pivots["Tail"] = (0, 0.7, 1.4)
    # the woman: dress, belt, shoulders, arms out and down
    a.box("Dress", (-1.3, 2.8, -1.0), (1.3, 5.0, 1.0), DRESS, "root")
    a.box("Belt", (-1.35, 4.6, -1.05), (1.35, 5.0, 1.05), BELT, "root")
    a.box("Chest", (-1.1, 5.0, -0.7), (1.1, 6.4, 0.7), DRESS, "root")
    a.box("Shoulders", (-1.1, 6.4, -0.7), (1.1, 7.0, 0.7), SKIN, "root")
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side
        xa, xb = sorted((sx * 1.1, sx * 2.9))
        a.box(bone, (xa, 6.4, -0.3), (xb, 7.0, 0.3), SKIN, bone)
        xa, xb = sorted((sx * 2.3, sx * 2.9))
        a.box("Hand" + side, (xa, 5.2, -0.3), (xb, 6.4, 0.3), SKIN, bone)
        a.pivots[bone] = (sx * 1.1, 6.7, 0)
    # head: glowing red eyes, a green cap of hair and spikes all round
    a.box("Neck", (-0.35, 7.0, -0.3), (0.35, 7.4, 0.3), SKIN, "neck")
    a.box("Head", (-0.9, 7.4, -0.9), (0.9, 9.2, 0.9), SKIN, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.2, sx * 0.65))
        a.box("GlowEye" + side, (xa, 8.1, -0.95), (xb, 8.6, -0.9), EYE, "neck")
    a.box("Hair", (-1.0, 9.2, -1.0), (1.0, 9.6, 1.0), GREEN, "neck")
    a.box("HairBack", (-1.0, 7.4, 0.9), (1.0, 9.2, 1.2), GREEN, "neck")
    a.pivots["neck"] = (0, 7.0, 0)
    spikes = [
        ((-0.95, 9.6, -0.95), (-0.05, 9.6, -0.05), "+y", 1.3, GREEN_DARK),
        ((0.05, 9.6, -0.95), (0.95, 9.6, -0.05), "+y", 1.0, GREEN),
        ((-0.95, 9.6, 0.05), (-0.05, 9.6, 0.95), "+y", 1.0, GREEN),
        ((0.05, 9.6, 0.05), (0.95, 9.6, 0.95), "+y", 1.3, GREEN_DARK),
        ((-1.0, 8.6, -0.8), (-1.0, 9.5, 0.1), "-x", 1.1, GREEN),
        ((-1.0, 7.8, 0.2), (-1.0, 8.7, 1.1), "-x", 0.9, GREEN_DARK),
        ((0.9, 8.6, -0.8), (0.9, 9.5, 0.1), "+x", 1.1, GREEN),
        ((0.9, 7.8, 0.2), (0.9, 8.7, 1.1), "+x", 0.9, GREEN_DARK),
        ((-0.9, 8.3, 1.2), (0.0, 9.2, 1.2), "+z", 1.1, GREEN_DARK),
        ((0.0, 7.4, 1.2), (0.9, 8.3, 1.2), "+z", 1.0, GREEN),
    ]
    for i, (lo, hi, axis, h, c) in enumerate(spikes):
        pyramid(a, f"HairSpike{i + 1}", lo, hi, axis, h, c, "neck")
    a.meta = {"seat": (0, 2.2, 3.0), "neck_loop": {"center": (0, 7.2, 0), "radius": 1.1}}
    return a


def main(out="designs/godlands"):
    os.makedirs(out, exist_ok=True)
    a = medusa()
    m = A.build_animal(a, out)
    cams = [dict(eye=(-14, 9, -17), target=(0, 4.8, 1), W=440, H=480, fov=36),
            dict(eye=(0, 6, -22), target=(0, 4.8, 1), W=440, H=480, fov=34),
            dict(eye=(16, 9, 14), target=(0, 4.8, 1), W=440, H=480, fov=36),
            dict(eye=(-22, 5, 1), target=(0, 4.8, 1), W=440, H=480, fov=34)]
    sheet = Image.new("RGB", (440 * len(cams), 480))
    for i, c in enumerate(cams):
        sheet.paste(render(pose(m, None, 0), **c), (440 * i, 0))
    sheet.save(os.path.join(out, "Medusa.png"))
    print(f"Medusa: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
