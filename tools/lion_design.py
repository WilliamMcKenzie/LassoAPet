"""Lion: World 2 Meadow's Rare (QM, Oct 13), in the Meadow animals' style, built like the
Kitten (tools/kitten_design.py ginger()) but horse-sized: golden coat, cream muzzle,
chest and paws, a big blocky mane framing the head (a thick ring round the face and a
cap over the top, darker at the back), small round ears poking out of the mane, Horse
googly eyes on the head's sides, and a long tail curving down to a dark tuft.

Same bones and rules as every quadruped (root, neck, EarL, EarR, Tail, Leg*); walk is
QM's horse walk, the gallop the shared leap (a pounce).

    python3 tools/lion_design.py

writes designs/world2/Lion.bbmodel and renders to /mnt/project-files/animals/lion/.
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

COAT = (232, 172, 72)
CREAM = (255, 238, 200)
MANE = (196, 102, 34)
MANE_DARK = (150, 70, 26)
NOSE = (120, 64, 48)


def lion():
    a = Animal("Lion", "Rare")
    x, y0, y1, z0, z1 = 1.7, 2.8, 5.8, -2.6, 3.4
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Chest", (-x, y0, z0), (x, y1, -1.6), CREAM, "root")
    a.box("Body", (-x, y0, -1.6), (x, y1, z1), COAT, "root")
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.5, sx * 1.6))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.2
        zb = za + 1.2
        name = "Leg" + leg
        a.box(name, (xa, 0.6, za), (xb, y0, zb), COAT, name)
        a.box("Hoof" + leg, (xa - 0.05 * (sx < 0), 0, za - 0.1), (xb + 0.05 * (sx > 0), 0.6, zb), CREAM, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # head out front, raised over the chest
    hx, hy0, hy1, hz0, hz1 = 1.4, 4.4, 7.2, -5.2, -2.6
    a.box("Head", (-hx, hy0, hz0), (hx, hy1, hz1), COAT, "neck")
    a.box("Muzzle", (-0.9, hy0, -5.8), (0.9, 5.5, hz0), CREAM, "neck")
    a.box("Nose", (-0.35, 5.2, -5.95), (0.35, 5.6, -5.8), NOSE, "neck")
    a.eyes(hx, 5.7, 6.7, -4.9, -3.9)

    # mane: a ring round the face (sides, top, chin) set behind the eyes, a cap
    # over the head and a darker back slab down the neck
    mz0, mz1 = -3.8, -2.2
    a.box("ManeL", (-2.4, 3.8, mz0), (-hx, 7.8, mz1), MANE, "neck")
    a.box("ManeR", (hx, 3.8, mz0), (2.4, 7.8, mz1), MANE, "neck")
    a.box("ManeTop", (-hx, hy1, mz0), (hx, 7.8, mz1), MANE, "neck")
    a.box("ManeChin", (-hx, 3.6, mz0), (hx, hy0, mz1), MANE, "neck")
    a.box("ManeCap", (-hx, hy1, -4.9), (hx, 7.5, mz0), MANE, "neck")
    a.box("ManeBack", (-2.0, 3.6, mz1), (2.0, 7.4, -1.4), MANE_DARK, "neck")
    a.pivots["neck"] = (0, 5.8, -2.6)

    # small round ears poking out of the mane's top
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.7, sx * 1.4))
        a.box(bone, (xa, 7.8, -3.4), (xb, 8.5, -2.8), COAT, bone)
        ia, ib = sorted((sx * 0.85, sx * 1.25))
        a.box(bone + "In", (ia, 7.8, -3.45), (ib, 8.35, -3.4), MANE_DARK, bone)
        a.pivots[bone] = ((xa + xb) / 2, 7.8, -3.45)

    # long tail out the back of the rump, curving down to a dark tuft
    a.box("Tail", (-0.3, 5.0, z1), (0.3, 5.6, z1 + 1.8), COAT, "Tail")
    a.box("Tail2", (-0.3, 3.8, z1 + 1.2), (0.3, 5.0, z1 + 1.8), COAT, "Tail")
    a.box("TailTuft", (-0.45, 2.8, z1 + 1.05), (0.45, 3.8, z1 + 1.95), MANE_DARK, "Tail")
    a.pivots["Tail"] = (0, 5.6, z1)

    a.meta = {"seat": (0, 6.6, 0.9), "neck_loop": {"center": (0, 5.8, -3.0), "radius": 2.2}}
    a.animations = quad_animations
    return a


CAM = dict(eye=(-19, 12, -21), target=(0, 4.4, -0.8), W=420, H=420, fov=36)
SIDE = dict(eye=(-28, 5, -1), target=(0, 4.4, -1), W=420, H=420, fov=34)
FRONT = dict(eye=(-5, 7, -22), target=(0, 4.6, -1), W=420, H=420, fov=34)


def main(out=os.path.join(A.ROOT, "designs", "world2"), shots="/mnt/project-files/animals/lion"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = lion()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM),
             render(pose(m, None, 0), **FRONT), render(pose(m, None, 0), **SIDE)]
    im = Image.new("RGB", (420 * len(tiles), 420))
    for i, t in enumerate(tiles):
        im.paste(t, (420 * i, 0))
    A.label(im, ["Horse (for size)", "Lion · Rare", "Front", "Side"]).save(os.path.join(shots, "Lion.png"))
    frames = []
    for name, n in (("walk", 20), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for k in range(n):
            frames.append(A.label(render(pose(m, anim, k / n * anim["length"]), **SIDE), [name]))
    A.gif(os.path.join(shots, "Lion_anims.gif"), frames, fps=20)
    json.dump(m, open(os.path.join(shots, "Lion.bbmodel"), "w"), separators=(",", ":"))


if __name__ == "__main__":
    main(*sys.argv[1:])
