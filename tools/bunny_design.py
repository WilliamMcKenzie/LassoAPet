"""Bunny: an early-game Meadow animal on the same rig as the Pig.

Run: python3 tools/bunny_design.py [out_dir]

Three takes for QM to pick from (same build, different coat and ears):
  A  Cottontail  tan, cream muzzle and paws, tall upright ears
  B  Grey        blue-grey, white muzzle and paws, tall upright ears
  C  Lop         cream with brown lop ears hanging down the head's sides

Built like the Pig: one body block, the head on the body's front (raised),
Horse googly eyes on the head's sides. Bunny tweaks: long block ears (real
depth, no plates), a pink nose and buck teeth, small front legs, big hind
legs with long feet, a white cotton tail. Same bones as every quadruped
(root, neck, EarL, EarR, Tail, Leg*), same rules: front legs swing forward,
hind legs kick back, upright ears fold back. Gallop is the shared leap; walk is a
small version of it (bunnies hop).
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, EYE_WHITE, PINK, leap, read_tracks, QM_HORSE  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

TAKES = {
    "A": dict(label="Cottontail", coat=(206, 150, 98), light=(250, 236, 212), ears="up"),
    "B": dict(label="Grey", coat=(150, 160, 186), light=(250, 250, 252), ears="up"),
    "C": dict(label="Lop", coat=(246, 220, 172), light=(255, 248, 232), ears="lop", ear=(168, 106, 66)),
}
NOSE = (240, 110, 150)
TAIL = (255, 255, 255)


def bunny(take="A"):
    t = TAKES[take]
    coat, light = t["coat"], t["light"]
    a = Animal("Bunny", "Common")
    # body: a bit smaller than the Pig's, the rider sits on top
    a.body(1.5, 1.4, 4.4, -2.2, 2.8, coat)
    d = a.dims
    # small front legs (swing forward from the top-back edge)
    for leg, sx in (("FL", -1), ("FR", 1)):
        xa, xb = sorted((sx * 0.5, sx * 1.2))
        z0, z1 = d["z0"] + 0.001, d["z0"] + 0.9
        name = "Leg" + leg
        a.box(name, (xa, 0.4, z0), (xb, d["y0"], z1), coat, name)
        a.box("Hoof" + leg, (xa, 0, z0), (xb, 0.4, z1), light, name)
        a.pivots[name] = ((xa + xb) / 2, d["y0"] - 0.025, z1 - 0.05)
    # big hind legs with long feet reaching forward (kick back from the top-front edge)
    for leg, sx in (("HL", -1), ("HR", 1)):
        xa, xb = sorted((sx * 0.3, sx * 1.5))
        z1 = d["z1"] - 0.001
        z0 = z1 - 2.0
        name = "Leg" + leg
        a.box(name, (xa, 0.4, z0), (xb, d["y0"], z1), coat, name)
        a.box("Hoof" + leg, (xa, 0, z0 - 1.0), (xb, 0.4, z1), light, name)
        a.pivots[name] = ((xa + xb) / 2, d["y0"] - 0.025, z0 + 0.05)
    # head on the body's front, raised above it
    a.box("Head", (-1.3, 3.0, -4.6), (1.3, 5.8, -2.199), coat, "neck")
    a.box("Muzzle", (-0.9, 3.0, -5.1), (0.9, 4.1, -4.6), light, "neck")
    a.box("Nose", (-0.35, 3.75, -5.3), (0.35, 4.25, -5.1), NOSE, "neck")
    a.box("Teeth", (-0.3, 2.5, -5.0), (0.3, 3.0, -4.7), EYE_WHITE, "neck")
    a.eyes(1.3, 4.3, 5.3, -4.2, -3.2)
    a.pivots["neck"] = (0, 4.4, -2.25)
    if t["ears"] == "up":
        # tall block ears, a pink inner block on the front; fold back from the front-bottom edge
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * 0.3, sx * 1.2))
            bone = "Ear" + side
            a.box(bone, (xa, 5.8, -3.4), (xb, 8.8, -2.9), coat, bone)
            ia, ib = sorted((sx * 0.5, sx * 1.0))
            a.box(bone + "In", (ia, 6.0, -3.55), (ib, 8.4, -3.4), PINK, bone)
            a.pivots[bone] = (sx * 0.75, 5.8, -3.55)
    else:
        # lop ears: hang down the head's sides from the top
        ear = t["ear"]
        for side, sx in (("L", -1), ("R", 1)):
            bone = "Ear" + side
            ta, tb = sorted((sx * 0.6, sx * 1.8))
            a.box(bone + "Top", (ta, 5.8, -3.3), (tb, 6.3, -2.4), ear, bone)
            xa, xb = sorted((sx * 1.3, sx * 1.8))
            a.box(bone, (xa, 2.6, -3.3), (xb, 5.8, -2.4), ear, bone)
            a.pivots[bone] = (sx * 1.2, 6.3, -3.3)
        # eyes move forward so the ears don't cover them
        a.parts = [p for p in a.parts if not p.name.startswith(("Eye", "Pupil"))]
        a.eyes(1.3, 4.3, 5.3, -4.55, -3.55)
    # cotton tail: a white cube on the rump
    a.box("Tail", (-0.6, 3.0, 2.8), (0.6, 4.2, 3.6), TAIL, "Tail")
    a.pivots["Tail"] = (0, 4.2, 2.8)
    a.meta = {"seat": (0, 5.2, 0.6), "neck_loop": {"center": (0, 4.4, -3.4), "radius": 1.8}}
    a.animations = lambda: bunny_animations(lop=t["ears"] == "lop")
    return a


def bunny_animations(lop=False):
    qm = json.load(open(QM_HORSE))
    anims = {"idle": read_tracks(qm, "idle"),
             "walk": leap(L=0.5, height=8, spread=35, pitch=6),
             "gallop": leap(L=0.7, height=25, spread=55)}
    if lop:  # hanging ears stay put: folding back swings them across the face
        for _, tracks in anims.values():
            tracks.pop("EarL", None)
            tracks.pop("EarR", None)
    return anims


def main(out="/mnt/project-files/animals/bunny"):
    os.makedirs(out, exist_ok=True)
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    pig = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Pig.bbmodel")))
    bunnies, names = [], []
    for k, t in TAKES.items():
        a = bunny(k)
        a.name = f"Bunny_{k}"
        m = A.build_animal(a, out)
        m["meta"]["format_version"] = "5.0"
        with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
            json.dump(m, f, separators=(",", ":"))
        with open(os.path.join(out, a.name + "_meta.json"), "w") as f:
            json.dump(dict(rarity=a.rarity, **a.meta), f, indent=1)
        bunnies.append(m)
        names.append(f"{k}: {t['label']}")
        print(a.name, len(a.parts), "parts")

    # the takes up close, front 3/4 and side
    close = dict(eye=(-15, 9, -17), target=(0, 3.8, -0.8), W=420, H=420, fov=34)
    side = dict(eye=(-24, 5, -1), target=(0, 4.2, -0.8), W=420, H=420, fov=34)
    rows = [A.label(A.strip(bunnies, cam=close), names, 24), A.label(A.strip(bunnies, cam=side), [""] * 3, 24)]
    im = Image.new("RGB", (rows[0].width, rows[0].height + rows[1].height), (255, 255, 255))
    im.paste(rows[0], (0, 0))
    im.paste(rows[1], (0, rows[0].height))
    im.save(os.path.join(out, "bunny_takes.png"))

    # next to the Meadow herd for size
    line = [horse, pig] + bunnies
    A.label(A.strip(line), ["Horse", "Pig"] + names).save(os.path.join(out, "bunny_lineup.png"))

    # hop and walk loops
    for name, n in (("gallop", 16), ("walk", 12)):
        frames = [A.label(A.strip(bunnies, name, i / n, side), names, 24).resize((840, 312)) for i in range(n)]
        A.gif(os.path.join(out, f"bunny_{name}.gif"), frames, fps=n / 0.7 if name == "gallop" else n / 0.5)
    print("written to", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
