"""Palm Guy (QM Oct 11): one of the Jurassic's palm trees (the Cycad, design/jurassic_biome/
jungle_plants.py: a stout scaly trunk under a crown of fronds) walking about with the Cactus's
face (designs/desert/Cactus.bbmodel: two dark eyes over a tall open mouth), its arms held out
and bent like the Cactus's, a leaf tuft on each hand, on two stubby legs. Static draft.

Run: python3 tools/palm_guy.py [out_dir]
writes PalmGuy.bbmodel, PalmGuy.png (three views) and PalmGuy_vs_cactus.png.

Bones: root, LegL/LegR, ArmL/ArmR, neck (the crown) > Frond<i> (turned round, rest Y) >
Frond<i>Rise (tilted up, rest X) > Frond<i>Droop (the tip hanging down, rest X).
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/palm_guy"
ROOT = os.path.join(os.path.dirname(__file__), "..")

BARK = [(150, 110, 66), (132, 96, 58)]  # the Cycad's trunk
RING = (104, 74, 44)  # the scaly joints
LEAF = [(70, 156, 52), (58, 138, 46), (90, 176, 62)]  # the jungle plants' leaves
LEAF_DARK = (54, 124, 44)
FACE = (54, 34, 24)  # the Cactus's eyes and mouth
FRONDS = 6
CROWN_Y = 11.0


def palm_guy():
    a = Conv("PalmGuy", "Uncommon", 1.0)
    a.pivots["root"] = (0, 6.0, 0)

    # ---- two stubby legs
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 0.9, 2.4, 0))
        x0, x1 = X(sx, 0.3, 1.5)
        a.b("Leg" + side, (x0, 0.0, -0.6), (x1, 2.6, 0.6), BARK[1], leg)

    # ---- the trunk: four stacked scaly blocks, a little narrower going up, a dark ring at
    # each joint (the Cycad's pineapple bark)
    y = 2.2
    for i in range(4):
        h, w = 2.2, 3.6 - 0.2 * i
        a.b(f"Trunk{i}", (-w / 2, y, -w / 2), (w / 2, y + h, w / 2), BARK[i % 2], "root")
        if i:
            r = w / 2 + 0.12
            a.b(f"Ring{i}", (-r, y - 0.15, -r), (r, y + 0.15, r), RING, "root")
        y += h
    # the Cactus's face: the eyes on the top block's front, the tall mouth on the one below
    ze, zm = -(3.6 - 0.2 * 3) / 2, -(3.6 - 0.2 * 2) / 2
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.2, 0.75)
        a.b("Eye" + side, (x0, 9.3, ze - 0.08), (x1, 10.1, ze + 0.02), FACE, "root")
    a.b("Mouth", (-0.25, 7.3, zm - 0.08), (0.25, 8.6, zm + 0.02), FACE, "root")

    # ---- arms like the Cactus's: out to the side then bent, the left up and the right down,
    # a leaf tuft on each hand
    for side, sx, up in (("L", -1, 1), ("R", 1, -1)):
        arm = a.bone("Arm" + side, "root", (sx * 1.6, 6.4, 0))
        x0, x1 = X(sx, 1.5, 3.3)
        a.b("Arm" + side, (x0, 6.0, -0.45), (x1, 6.9, 0.45), BARK[0], arm)
        x0, x1 = X(sx, 2.4, 3.3)
        y0, y1 = (6.9, 8.6) if up > 0 else (4.3, 6.0)
        a.b("Forearm" + side, (x0, y0, -0.45), (x1, y1, 0.45), BARK[0], arm)
        yt = y1 if up > 0 else y0 - 0.7
        a.b("Tuft" + side, (x0 - 0.15, yt, -0.6), (x1 + 0.15, yt + 0.7, 0.6), LEAF[0], arm)

    # ---- the crown: a dark leafy heart on top, fronds rising out all round and drooping
    head = a.bone("neck", "root", (0, CROWN_Y, 0))
    a.b("Heart", (-1.3, CROWN_Y - 0.2, -1.3), (1.3, CROWN_Y + 1.0, 1.3), LEAF_DARK, head)
    yc = CROWN_Y + 0.6
    for i in range(FRONDS):
        yaw = 360 * i / FRONDS + 30
        f = a.bone(f"Frond{i}", "neck", (0, yc, 0), rest=(0, yaw, 0))
        rise = a.bone(f"Frond{i}Rise", f, (0, yc, 0.8), rest=(-32, 0, 0))
        a.b(f"Frond{i}A", (-0.9, yc - 0.18, 0.8), (0.9, yc + 0.18, 3.2), LEAF[i % 3], rise)
        droop = a.bone(f"Frond{i}Droop", rise, (0, yc, 3.2), rest=(42, 0, 0))
        a.b(f"Frond{i}B", (-0.75, yc - 0.17, 3.2), (0.75, yc + 0.17, 5.4), LEAF[(i + 1) % 3], droop)
        a.b(f"Frond{i}C", (-0.5, yc - 0.15, 5.4), (0.5, yc + 0.15, 7.0), LEAF[(i + 2) % 3], droop)
    a.meta = {"seat": (0, CROWN_Y + 1.0, 0), "neck_loop": {"center": (0, 9.6, 0), "radius": 2.0}}
    return a


PLAIN = ("Eye", "Mouth")


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(palm_guy)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "PalmGuy.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    W = 480
    sheet = Image.new("RGB", (W * 3, W))
    for i, v in enumerate(((-12, 6, -24), (-30, 4, 0), (19, 13, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=W, H=W, fov=34), (i * W, 0))
    A.label(sheet, ["Palm Guy", "side", "back"], 22).save(os.path.join(out, "PalmGuy.png"))
    from snow_rig import posed
    cactus = posed(json.load(open(os.path.join(ROOT, "designs", "desert", "Cactus.bbmodel"))))
    for p in parts:
        p.polys = [q + np.array([-5.0, 0, 0]) for q in p.polys]
    for p in cactus:
        p.polys = [q + np.array([4.0, 0, 0]) for q in p.polys]
        if p.name.startswith(PLAIN):
            p.plain = True
    cam = dict(eye=(-8, 12, -34), target=(-0.5, 6.5, 0), W=W * 2, H=W, fov=34)
    A.label(render(parts + cactus, **cam), ["Palm Guy and Cactus"], 22).save(os.path.join(out, "PalmGuy_vs_cactus.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
