"""Fox (Uncommon) and Nine-tailed Fox (Rare): World 2 Temple animals (QM, Oct 13), in the
Meadow animals' style.

Fox: a slim, Lion-sized red fox. Orange coat, white chest, cheeks and chin, a long
pointed snout with a black nose, black stockings, tall pointed ears with black tips
and cream insides, Horse googly eyes on the head's sides, a red shrine bib (two prism
halves) on the chest, and one big bushy tail swept up off the rump with a white tip.

Nine-tailed Fox: the same body in gold with crimson ear tips, a crimson flame mark on
the forehead, a crimson bib with a gold bell, and nine bushy white-tipped tails fanned
up behind it like a peacock (the middle one longest).

The tails are plain cubes turned about one axis only (Fox: X, Nine-tailed: Z), each
cube's origin at the tail root, so Blockbench and the converter agree (bones stay at 0).
Same bones as every quadruped (root, neck, EarL, EarR, Tail, Leg*); quad animations.

    python3 tools/temple_fox.py

writes designs/temple/Fox.bbmodel and NineTailedFox.bbmodel, and the renders to
/mnt/project-files/world2/temple/renders/.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402

WHITE = (255, 250, 242)
BLACK = (52, 40, 40)
NOSE = (30, 26, 30)
CREAM = (255, 226, 196)
RED = (214, 40, 46)
GOLD_BELL = (255, 204, 40)

FOX = dict(name="Fox", rarity="Uncommon", coat=(240, 128, 36), tip=BLACK, bib=RED)
NINE = dict(name="NineTailedFox", rarity="Rare", coat=(250, 184, 52), tip=(200, 30, 60), bib=(200, 30, 60))


def fox(v):
    coat = v["coat"]
    a = Animal(v["name"], v["rarity"])
    a.turned = {}  # part name -> (origin in studs, rotation in degrees)
    x, y0, y1, z0, z1 = 1.4, 2.8, 5.4, -2.6, 3.2
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Chest", (-x, y0, z0), (x, y1, -1.6), WHITE, "root")
    a.box("Body", (-x, y0, -1.6), (x, y1, z1), coat, "root")
    # slim legs in black stockings
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.45, sx * 1.3))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.0
        zb = za + 1.0
        name = "Leg" + leg
        a.box(name, (xa, 1.3, za), (xb, y0, zb), coat, name)
        a.box("Hoof" + leg, (xa, 0, za), (xb, 1.3, zb), BLACK, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # head out front over the chest: coat on top, white cheeks below, a long snout
    hx, hy0, hy1, hz0, hz1 = 1.5, 4.4, 6.8, -5.0, -2.4
    a.box("Head", (-hx, 5.3, hz0), (hx, hy1, hz1), coat, "neck")
    a.box("Cheeks", (-hx - 0.2, hy0, hz0 + 0.2), (hx + 0.2, 5.3, hz1), WHITE, "neck")
    a.box("Snout", (-0.75, 5.0, -6.8), (0.75, 5.7, hz0), coat, "neck")
    a.box("Chin", (-0.75, hy0, -6.8), (0.75, 5.0, hz0 + 0.2), WHITE, "neck")
    a.box("Nose", (-0.3, 5.15, -7.0), (0.3, 5.75, -6.8), NOSE, "neck")
    a.eyes(hx, 5.55, 6.45, -4.7, -3.7)
    a.pivots["neck"] = (0, 5.4, -2.6)
    if v is NINE:  # crimson flame mark on the forehead: a block with a prism flame on top
        a.box("Mark", (-0.2, 5.9, hz0 - 0.15), (0.2, 6.3, hz0), v["tip"], "neck")
        for half, dx in (("A", -1), ("B", 1)):
            a.tri(f"MarkTip{half}", [(0, 6.3), (dx * 0.2, 6.3), (0, 6.7)], hz0 - 0.15, hz0, v["tip"], "neck")

    # tall pointed ears: prism halves meeting at the tip, cream insides, dark tips
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        c = sx * 0.95
        for half, dx in (("A", -1), ("B", 1)):
            a.tri(f"{bone}{half}", [(c, hy1), (c + dx * 0.65, hy1), (c, hy1 + 1.4)], -4.0, -3.4, coat, bone)
            a.tri(f"{bone}Tip{half}", [(c, hy1 + 1.4), (c + dx * 0.32, hy1 + 1.4), (c, hy1 + 2.1)], -4.0, -3.4, v["tip"], bone)
            a.tri(f"{bone}In{half}", [(c, hy1), (c + dx * 0.4, hy1), (c, hy1 + 1.2)], -4.1, -4.0, CREAM, bone)
        a.pivots[bone] = (c, hy1, -4.1)

    # shrine bib on the chest: two prism halves pointing down
    bz = (z0 - 0.3, z0)
    for half, dx in (("A", -1), ("B", 1)):
        a.tri(f"Bib{half}", [(0, 4.4), (dx * 1.3, 4.4), (0, 2.9)], *bz, v["bib"], "root")
    if v is NINE:
        a.box("Bell", (-0.3, 3.3, z0 - 0.75), (0.3, 3.9, z0 - 0.3), GOLD_BELL, "root")

    if v is NINE:
        nine_tails(a, coat, z1)
    else:
        # one big bushy tail out of the rump, swept up 35 degrees
        o = np.array((0, 4.8, z1))
        for name, lo, hi, c in (("Tail", (-0.45, -0.45, 0), (0.45, 0.45, 1.0), coat),
                                ("TailBush", (-0.85, -0.85, 1.0), (0.85, 0.85, 3.4), coat),
                                ("TailTip", (-0.65, -0.65, 3.4), (0.65, 0.65, 4.4), WHITE)):
            a.box(name, o + lo, o + hi, c, "Tail")
            a.turned[name] = (o, (-35, 0, 0))
        a.pivots["Tail"] = tuple(o)

    a.meta = {"seat": (0, 6.2, 0.7), "neck_loop": {"center": (0, 5.6, -3.7), "radius": 2.0}}
    a.animations = quad_animations
    return a


def nine_tails(a, coat, z1):
    """Nine tails fanned up behind the rump, 18 degrees apart, each a little further
    back than the one inside it so the overlapping roots never share a face."""
    a.box("Tail", (-0.5, 4.4, z1), (0.5, 5.4, z1 + 0.8), coat, "Tail")
    for i in range(9):
        k = i - 4
        o = np.array((0, 4.9, z1 + 0.55 + 0.12 * abs(k) + 0.06 * (k > 0)))
        L = 6.0 - 0.3 * abs(k)
        rot = (0, 0, -18 * k)
        for name, lo, hi, c in ((f"Tail{i + 1}", (-0.25, 0, -0.25), (0.25, 1.7, 0.25), coat),
                                (f"Tail{i + 1}Bush", (-0.52, 1.6, -0.45), (0.52, L - 1.2, 0.45), coat),
                                (f"Tail{i + 1}Tip", (-0.4, L - 1.2, -0.36), (0.4, L, 0.36), WHITE)):
            a.box(name, o + lo, o + hi, c, "Tail")
            a.turned[name] = (o, rot)
    a.pivots["Tail"] = (0, 4.9, z1)


def build(a, out):
    m = A.build_animal(a, out)
    # the turned parts were built straight; turn them about their tail root
    for e in m["elements"]:
        if e["name"] in a.turned:
            o, rot = a.turned[e["name"]]
            e["origin"] = [round(float(c) * 10, 4) for c in o]
            e["rotation"] = list(rot)
    with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    return m


CAM = dict(eye=(-19, 12, -21), target=(0, 4.6, -0.6), W=520, H=520, fov=36)
BACK = dict(eye=(-16, 11, 20), target=(0, 5.0, 0.6), W=520, H=520, fov=36)


def main(out=os.path.join(A.ROOT, "designs", "temple"), shots="/mnt/project-files/world2/temple/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    for v in (FOX, NINE):
        a = fox(v)
        m = build(a, out)
        print(f"{a.name}: {len(a.parts)} parts")
        shot = render(pose(m, None, 0), transparent=True, **CAM)
        bg = Image.new("RGBA", shot.size, (242, 242, 238, 255))
        Image.alpha_composite(bg, shot).convert("RGB").save(os.path.join(shots, a.name + ".png"))
        tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM), render(pose(m, None, 0), **BACK)]
        im = Image.new("RGB", (520 * len(tiles), 520))
        for i, t in enumerate(tiles):
            im.paste(t, (520 * i, 0))
        A.label(im, ["Horse (for size)", f"{a.name} · {a.rarity}", "Back"]).save(os.path.join(shots, a.name + "_sheet.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
