"""Buffalo: World 2 Meadow animal (QM, Oct 13), rebuilt in our block style from QM's
Minecraft-style base (a bison: big shaggy hump, low head, curved horns). Laid out in that
model's pixels (front is -z) and scaled to studs at the end: a dark shaggy hump and head,
a lighter brown back half, a pale snout, a fluffy tuft between cream horns that run out
sideways and turn up at grey tips, small ears under the horns, a beard, shaggy cuffs on
the front legs, dark hooves and a tasselled tail. Horse googly eyes on the head's sides.

Same bones and rules as every quadruped (root, neck, EarL, EarR, Tail, Leg*); walk is
QM's horse walk, the gallop the shared leap.

    python3 tools/buffalo_design.py

writes designs/world2/Buffalo.bbmodel and renders to /mnt/project-files/animals/buffalo/.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402

PX = 0.25  # studs per pixel of QM's base
COAT = (178, 114, 64)
FUR = (120, 74, 44)
SNOUT = (184, 136, 98)
HORN = (240, 230, 205)
HORN_TIP = (150, 146, 140)
HOOF = (58, 46, 42)
NOSTRIL = (60, 38, 28)


def buffalo():
    a = Animal("Buffalo", "Rare")
    # body: hump at the front (tall, shaggy), then the back half a little lower
    a.dims = dict(x=11, y0=11, y1=26, z0=-17, z1=14)
    a.pivots["root"] = (0, 19, -1.5)
    a.box("Hump", (-11, 11, -17), (11, 29, -4), FUR, "root")
    a.box("Body", (-10, 11, -4.001), (10, 25, 3.001), COAT, "root")
    a.box("Rump", (-11, 11, 3), (11, 26, 14), COAT, "root")
    # legs: shaggy cuffs at the top of the front ones, dark hooves
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 2, sx * 8))
        za, zb = (-12, -7) if front else (7, 12)
        name = "Leg" + leg
        a.box(name, (xa, 3, za), (xb, 11, zb), COAT if not front else FUR, name)
        a.box("Hoof" + leg, (xa, 0, za), (xb, 3, zb), HOOF, name)
        if front:
            ca, cb = sorted((sx * 1.5, sx * 8.5))
            a.box("Cuff" + leg, (ca, 6, za - 0.5), (cb, 11, zb + 0.5), FUR, name)
        a.pivots[name] = ((xa + xb) / 2, 10.9, zb - 0.25 if front else za + 0.25)
    # head low out of the front of the hump, beard under it, pale snout, fluffy top
    a.box("Neck", (-4, 14, -20), (4, 23, -16.999), FUR, "neck")
    a.box("Head", (-6, 13, -29), (6, 24, -20), FUR, "neck")
    a.box("Snout", (-4, 13, -35), (4, 19, -29), SNOUT, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1, sx * 3))
        a.box("Nostril" + side, (xa, 16, -35.25), (xb, 17.5, -35), NOSTRIL, "neck")
    a.box("Beard", (-4, 8, -28), (4, 13, -21), FUR, "neck")
    a.box("Tuft", (-6, 24, -26), (6, 27, -21), FUR, "neck")
    a.eyes(6, 18, 21, -28.5, -25.5)
    # horns out the sides of the head, turning up at grey tips
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 6, sx * 15))
        a.box("Horn" + side, (xa, 20.5, -25), (xb, 23.5, -22), HORN, "neck")
        ta, tb = sorted((sx * 12, sx * 15))
        a.box("HornUp" + side, (ta, 23.5, -25), (tb, 26.5, -22), HORN, "neck")
        a.box("HornTip" + side, (ta + 0.5 * (sx > 0), 26.5, -24.5), (tb - 0.5 * (sx < 0), 28.5, -22.5), HORN_TIP, "neck")
        # small ear under each horn, folding back
        bone = "Ear" + side
        ea, eb = sorted((sx * 6, sx * 9))
        a.box(bone, (ea, 17.5, -24), (eb, 20, -22), FUR, bone)
        a.pivots[bone] = ((ea + eb) / 2, 17.5, -24)
    a.pivots["neck"] = (0, 23, -17)
    # tail down the back of the rump, tasselled
    a.box("Tail", (-1.5, 16, 14), (1.5, 26, 16), COAT, "Tail")
    a.box("TailTuft", (-2, 11, 13.8), (2, 16, 16.4), FUR, "Tail")
    a.pivots["Tail"] = (0, 26, 14)

    a.meta = {"seat": (0, 27, -0.5), "neck_loop": {"center": (0, 19, -25), "radius": 8}}
    a.scale(PX)
    a.animations = quad_animations
    return a


CAM = dict(eye=(-19, 12, -21), target=(0, 4.2, -1.2), W=420, H=420, fov=36)
SIDE = dict(eye=(-28, 4, -1.5), target=(0, 4.2, -1.5), W=420, H=420, fov=34)
FRONT = dict(eye=(-5, 6, -22), target=(0, 3.6, -1.5), W=420, H=420, fov=34)


def main(out=os.path.join(A.ROOT, "designs", "world2"), shots="/mnt/project-files/animals/buffalo"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = buffalo()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM),
             render(pose(m, None, 0), **FRONT), render(pose(m, None, 0), **SIDE)]
    im = Image.new("RGB", (420 * len(tiles), 420))
    for i, t in enumerate(tiles):
        im.paste(t, (420 * i, 0))
    A.label(im, ["Horse (for size)", "Buffalo", "Front", "Side"]).save(os.path.join(shots, "Buffalo.png"))
    frames = []
    for name, n in (("walk", 20), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for k in range(n):
            frames.append(A.label(render(pose(m, anim, k / n * anim["length"]), **SIDE), [name]))
    A.gif(os.path.join(shots, "Buffalo_anims.gif"), frames, fps=20)
    json.dump(m, open(os.path.join(shots, "Buffalo.bbmodel"), "w"), separators=(",", ":"))


if __name__ == "__main__":
    main(*sys.argv[1:])
