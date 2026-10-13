"""Living Birch: World 2's Woodland Maze Rare (QM, Oct 13), a walking autumn birch built
on Palm Guy's body plan (tools/palm_guy.py; QM: "more like palm guy"): a stout trunk of
four stacked blocks narrowing upward, the Cactus's arms (left bent up, right bent down)
with a leaf tuft on each hand, two stubby legs, and a crown of drooping branches round a
leafy heart. Birch colours from the woodland's prop birches (tools/world2_prop_assets.luau):
white bark with dark birch marks, autumn leaves in orange, red-orange, amber and yellow.
The face is Palm Guy's layout (eyes on the top block, a tall open mouth below) with the
standard white plate eyes and dark pupils.

Run: python3 tools/living_birch.py [out_dir]
writes designs/woodland/LivingBirch.bbmodel and <out_dir>/LivingBirch.png (3/4 front).

Bones, as Palm Guy's (so his idle, walk and gallop fit): root, LegL/LegR, ArmL/ArmR, neck
(the crown) > Branch<i> (turned round, rest Y) > Branch<i>Rise (tilted up, rest X) >
Branch<i>Droop (the leafy end hanging down, rest X).
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/world2/woodland/renders"
ROOT = os.path.join(os.path.dirname(__file__), "..")

BARK = [(238, 234, 226), (226, 221, 211)]  # the prop birches' trunk, and a touch darker
MARK = (52, 46, 44)  # birch marks
LEAF = [(242, 109, 57), (214, 72, 43), (248, 168, 64), (254, 234, 92)]  # the prop birches' leaves
HEART = (196, 58, 36)
WHITE, PUPIL, MOUTH = (255, 255, 255), (24, 20, 32), (54, 34, 24)
BRANCHES = 6
CROWN_Y = 11.0


def living_birch():
    a = Conv("LivingBirch", "Rare", 1.0)
    a.pivots["root"] = (0, 6.0, 0)

    # ---- two stubby legs
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 0.9, 2.4, 0))
        x0, x1 = X(sx, 0.3, 1.5)
        a.b("Leg" + side, (x0, 0.0, -0.6), (x1, 2.6, 0.6), BARK[1], leg)

    # ---- the trunk: four stacked blocks, a little narrower going up, a thin dark birch band
    # at each joint and short dark marks on the faces
    y = 2.2
    for i in range(4):
        h, w = 2.2, 3.6 - 0.2 * i
        a.b(f"Trunk{i}", (-w / 2, y, -w / 2), (w / 2, y + h, w / 2), BARK[i % 2], "root")
        if i:
            r = w / 2 + 0.08
            a.b(f"Band{i}", (-r, y - 0.1, -r), (r, y + 0.1, r), MARK, "root")
        y += h
    r0, r1 = 3.6 / 2 + 0.06, 3.0 / 2 + 0.06
    for i, (x0, x1, yy, z) in enumerate([(0.4, 1.3, 3.2, -r0), (-1.4, -0.5, 4.0, r0), (0.3, 1.2, 5.6, r1)]):
        a.b(f"Mark{i}", (x0, yy, z - 0.06), (x1, yy + 0.3, z + 0.06), MARK, "root")
    for i, (sx, z0, z1, yy) in enumerate([(-1, -0.9, 0.0, 3.5), (1, 0.2, 1.1, 5.0), (-1, 0.1, 0.9, 7.6)]):
        rr = (3.6 - 0.2 * int((yy - 2.2) // 2.2)) / 2 + 0.06
        a.b(f"MarkS{i}", (sx * rr - 0.06, yy, z0), (sx * rr + 0.06, yy + 0.3, z1), MARK, "root")

    # Palm Guy's face: plate eyes on the top block's front, the tall mouth on the one below
    ze, zm = -(3.6 - 0.2 * 3) / 2, -(3.6 - 0.2 * 2) / 2
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.12, 1.05)
        a.b("Eye" + side, (x0, 9.0, ze - 0.05), (x1, 10.2, ze), WHITE, "root")
        x0, x1 = X(sx, 0.2, 0.7)
        a.b("Pupil" + side, (x0, 9.15, ze - 0.1), (x1, 9.85, ze - 0.05), PUPIL, "root")
    a.b("Mouth", (-0.3, 7.2, zm - 0.08), (0.3, 8.6, zm + 0.02), MOUTH, "root")

    # ---- arms like the Cactus's: out to the side then bent, the left up and the right down,
    # an autumn leaf tuft on each hand
    for side, sx, up in (("L", -1, 1), ("R", 1, -1)):
        arm = a.bone("Arm" + side, "root", (sx * 1.6, 6.4, 0))
        x0, x1 = X(sx, 1.5, 3.3)
        a.b("Arm" + side, (x0, 6.0, -0.45), (x1, 6.9, 0.45), BARK[0], arm)
        x0, x1 = X(sx, 2.4, 3.3)
        y0, y1 = (6.9, 8.6) if up > 0 else (4.3, 6.0)
        a.b("Forearm" + side, (x0, y0, -0.45), (x1, y1, 0.45), BARK[0], arm)
        yt = y1 if up > 0 else y0 - 0.9
        a.b("Tuft" + side, (x0 - 0.3, yt, -0.75), (x1 + 0.3, yt + 0.9, 0.75), LEAF[3 if up > 0 else 2], arm)

    # ---- the crown: a leafy heart on top, branches rising out all round and drooping, each
    # ending in a broad clump of autumn leaves (a weeping birch)
    head = a.bone("neck", "root", (0, CROWN_Y, 0))
    a.b("Heart", (-1.6, CROWN_Y - 0.2, -1.6), (1.6, CROWN_Y + 1.6, 1.6), HEART, head)
    a.b("HeartTop", (-1.0, CROWN_Y + 1.6, -1.0), (1.0, CROWN_Y + 2.3, 1.0), LEAF[3], head)
    yc = CROWN_Y + 0.8
    for i in range(BRANCHES):
        yaw = 360 * i / BRANCHES + 30
        f = a.bone(f"Branch{i}", "neck", (0, yc, 0), rest=(0, yaw, 0))
        rise = a.bone(f"Branch{i}Rise", f, (0, yc, 0.8), rest=(-30, 0, 0))
        a.b(f"Branch{i}A", (-1.2, yc - 0.3, 0.8), (1.2, yc + 0.3, 3.0), LEAF[i % 4], rise)
        droop = a.bone(f"Branch{i}Droop", rise, (0, yc, 3.0), rest=(62, 0, 0))
        a.b(f"Branch{i}B", (-1.3, yc - 0.35, 3.0), (1.3, yc + 0.35, 5.0), LEAF[(i + 1) % 4], droop)
        a.b(f"Branch{i}C", (-0.9, yc - 0.3, 5.0), (0.9, yc + 0.3, 6.4), LEAF[(i + 2) % 4], droop)
    a.meta = {"seat": (0, CROWN_Y + 2.3, 0), "neck_loop": {"center": (0, 9.6, 0), "radius": 2.0}}
    return a


PLAIN = ("Eye", "Pupil", "Mouth", "Mark", "Band")


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "woodland"), exist_ok=True)
    a, model, parts = C.build(living_birch)
    model["meta"]["format_version"] = "5.0"
    with open(os.path.join(ROOT, "designs", "woodland", "LivingBirch.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True
    lo, hi = C.bounds(parts)
    print("LivingBirch", len(model["elements"]), "elements; size (studs)", np.round(hi - lo, 1))
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    v = np.array((-14, 8, -24), float)
    eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(15)) * 0.8
    img = render(parts, eye=eye, target=c, W=900, H=900, fov=30, transparent=True)
    bg = Image.new("RGBA", img.size, (238, 240, 244, 255))
    bg.alpha_composite(img)
    bg.convert("RGB").save(os.path.join(out, "LivingBirch.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
