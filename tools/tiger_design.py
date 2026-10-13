"""Tiger: World 2 Temple's Rare (QM, Oct 13), built on the Lion (tools/lion_design.py)
but its own cat: bright orange coat, bold black stripes (bands wrapping over the back
and down both sides, on the forehead, legs and tail), white muzzle, chin, cheek ruffs,
belly and paws, pink nose, round ears with white insides, Horse googly eyes, and a long
striped tail with a black tip.

Same bones and animations as every quadruped (root, neck, EarL, EarR, Tail, Leg*): QM's
horse walk and the shared leap gallop (a pounce), as the Lion.

    python3 tools/tiger_design.py

writes designs/temple/Tiger.bbmodel and /mnt/project-files/world2/temple/renders/Tiger.png
(plus Tiger_vs_horse.png and Tiger_anims.gif). Convert without --zyx:
    python3 tools/bbmodel_to_luau.py designs/temple/Tiger.bbmodel src/shared/Animals/TigerModel.luau
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

COAT = (247, 133, 32)
WHITE = (255, 248, 236)
STRIPE = (34, 30, 36)
NOSE = (240, 120, 150)

S = 0.08  # how far a stripe band stands proud of the coat


def tiger():
    a = Animal("Tiger", "Rare")
    x, y0, y1, z0, z1 = 1.7, 2.8, 5.6, -2.8, 3.6
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Body", (-x, y0, z0), (x, y1, z1), COAT, "root")
    a.box("Belly", (-1.2, y0 - S, -2.4), (1.2, y0, 3.0), WHITE, "root")
    a.box("Chest", (-1.2, y0, z0 - S), (1.2, 4.6, z0), WHITE, "root")
    # stripe bands over the back and down both sides
    for i, zc in enumerate((-1.0, 0.4, 1.8, 3.0)):
        a.box(f"Stripe{i}", (-x - S, 3.7 + 0.15 * (i % 2), zc - 0.22), (x + S, y1 + S, zc + 0.22), STRIPE, "root")

    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.45, sx * 1.65))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.3
        zb = za + 1.3
        name = "Leg" + leg
        a.box(name, (xa, 0.6, za), (xb, y0, zb), COAT, name)
        a.box("Paw" + leg, (xa - 0.05 * (sx < 0), 0, za - 0.15), (xb + 0.05 * (sx > 0), 0.6, zb), WHITE, name)
        # one band right round the leg
        ba, bb = sorted((sx * (0.45 - S), sx * (1.65 + S)))
        a.box("LegStripe" + leg, (ba, 1.5, za - S), (bb, 1.85, zb + S), STRIPE, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # head out front, raised over the chest
    hx, hy0, hy1, hz0, hz1 = 1.5, 4.3, 7.0, -5.2, -2.4
    a.box("Head", (-hx, hy0, hz0), (hx, hy1, hz1), COAT, "neck")
    a.box("Muzzle", (-1.0, hy0, -5.9), (1.0, 5.5, hz0), WHITE, "neck")
    a.box("Nose", (-0.45, 5.1, -6.0), (0.45, 5.6, -5.9), NOSE, "neck")
    a.box("Chin", (-0.8, 3.9, -5.6), (0.8, hy0, -3.6), WHITE, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * hx, sx * (hx + 0.45)))
        a.box("Cheek" + side, (xa, 4.1, -4.2), (xb, 5.1, -3.0), WHITE, "neck")
        # whisker-cheek stripe up the side of the head behind the eye
        sa, sb = sorted((sx * hx, sx * (hx + S)))
        a.box("HeadStripe" + side, (sa, 5.3, -3.4), (sb, hy1, -3.0), STRIPE, "neck")
    a.eyes(hx, 5.6, 6.6, -4.9, -3.9)
    # forehead: a centre bar flanked by two shorter ones
    a.box("Brow", (-0.18, hy1, -5.0), (0.18, hy1 + S, -3.6), STRIPE, "neck")
    a.box("BrowL", (-0.9, hy1, -4.7), (-0.6, hy1 + S, -3.8), STRIPE, "neck")
    a.box("BrowR", (0.6, hy1, -4.7), (0.9, hy1 + S, -3.8), STRIPE, "neck")
    a.pivots["neck"] = (0, 5.6, -2.4)

    # round ears with white insides
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.6, sx * 1.4))
        a.box(bone, (xa, hy1, -3.2), (xb, 7.8, -2.6), COAT, bone)
        ia, ib = sorted((sx * 0.8, sx * 1.2))
        a.box(bone + "In", (ia, hy1 + 0.1, -3.25), (ib, 7.6, -3.2), WHITE, bone)
        a.pivots[bone] = ((xa + xb) / 2, hy1, -3.25)

    # long tail out the back, curving down, two black rings and a black tip
    a.box("Tail", (-0.3, 4.8, z1), (0.3, 5.4, z1 + 2.0), COAT, "Tail")
    a.box("TailRing", (-0.3 - S, 4.8 - S, z1 + 0.9), (0.3 + S, 5.4 + S, z1 + 1.2), STRIPE, "Tail")
    a.box("Tail2", (-0.3, 3.4, z1 + 1.4), (0.3, 4.8, z1 + 2.0), COAT, "Tail")
    a.box("TailRing2", (-0.3 - S, 3.9, z1 + 1.4 - S), (0.3 + S, 4.2, z1 + 2.0 + S), STRIPE, "Tail")
    a.box("TailTip", (-0.3, 2.6, z1 + 1.4), (0.3, 3.4, z1 + 2.0), STRIPE, "Tail")
    a.pivots["Tail"] = (0, 5.4, z1)

    a.meta = {"seat": (0, 6.4, 0.9), "neck_loop": {"center": (0, 5.6, -3.0), "radius": 2.2}}
    a.animations = quad_animations
    return a


SIDE = dict(eye=(-28, 5, -1), target=(0, 4.2, -1), W=420, H=420, fov=34)
CAM = dict(eye=(-19, 12, -21), target=(0, 4.0, 0.2), W=480, H=480, fov=30)


def main(out=os.path.join(A.ROOT, "designs", "temple"), shots="/mnt/project-files/world2/temple/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = tiger()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    shot = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", shot.size, (240, 240, 236, 255))
    bg.alpha_composite(shot)
    bg.convert("RGB").save(os.path.join(shots, "Tiger.png"))
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM)]
    im = Image.new("RGB", (480 * len(tiles), 480))
    for i, t in enumerate(tiles):
        im.paste(t, (480 * i, 0))
    A.label(im, ["Horse (for size)", "Tiger · Rare"]).save(os.path.join(shots, "Tiger_vs_horse.png"))
    frames = []
    for name, n in (("idle", 16), ("walk", 20), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for k in range(n):
            frames.append(A.label(render(pose(m, anim, k / n * anim["length"]), **SIDE), [name]))
    A.gif(os.path.join(shots, "Tiger_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*sys.argv[1:])
