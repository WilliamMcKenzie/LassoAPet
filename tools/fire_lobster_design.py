"""Fire Lobster (QM Oct 11): a lava-red lobster on the Scorpion's base (QM's
designs/desert/Scorpion.bbmodel: same body, head, eyes, legs and lowered claws), with
bigger crusher claws, a rostrum and swept-back antennae, and the scorpion's stinger tail
swapped for a lobster's tail lying flat out the back. Claw tips, antenna tips and the
tail fan glow (Glow* = Neon in game). Static draft, no animations.

Run: python3 tools/fire_lobster_design.py [out_dir]
writes FireLobster.bbmodel, FireLobster.png (three views) and FireLobster_vs_horse.png.

Bones match the Scorpion's (root, neck, Tail, ClawL/R, LegL0-2, LegR0-2), so
tools/scorpion_rig.py's animations can drive it later.
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
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/firelobster"

RED = (226, 52, 36)  # the shell
RED_DARK = (170, 32, 30)  # seams, fingers, shins
ORANGE = (255, 124, 40)  # joints
LAVA = (255, 140, 30)  # the glowing bits


def XL(sx, a0, a1):
    return list(X(sx, a0, a1))


def fire_lobster():
    a = Conv("FireLobster", "Rare", 1.0)  # studs: QM's Scorpion coordinates / 10
    a.pivots["root"] = (0, 3.25, 0.13)
    # body: the Scorpion's plated bands
    for i, (z0, z1, c) in enumerate(((-3.12, -1.17, RED), (-1.17, -0.78, RED_DARK), (-0.78, 1.17, RED),
                                     (1.17, 1.56, RED_DARK), (1.56, 3.38, RED))):
        a.b(f"Body{i + 1}", (-2.34, 2.08, z0), (2.34, 4.42, z1), c, "root")
    # head with a pointed rostrum and two long antennae arching up and back
    head = a.bone("neck", "root", (0, 2.99, -3.12))
    a.b("Head", (-1.82, 2.08, -4.68), (1.82, 3.9, -3.12), RED, head)
    a.pyr("Rostrum", (-0.35, 3.3, -4.68), (0.35, 3.9, -4.68), "-z", 0.9, RED_DARK, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.82, 2.86, 3.77, -4.55, -3.64, head)
        x0, x1 = X(sx, 1.0, 1.4)
        a.b("Antenna" + side, (x0, 3.5, -5.6), (x1, 3.9, -4.68), RED_DARK, head)
        a.b(f"Antenna{side}2", (x0, 3.9, -5.6), (x1, 6.4, -5.2), RED_DARK, head)
        a.b(f"Antenna{side}3", (x0, 6.0, -5.2), (x1, 6.4, -2.6), RED_DARK, head)
        a.b(f"GlowAntenna{side}", (x0, 6.0, -2.6), (x1, 6.4, -2.0), LAVA, head)
    # crusher claws, bigger than the Scorpion's, at QM's lowered shoulder height
    for side, sx in SIDES:
        claw = a.bone("Claw" + side, "root", (sx * 1.82, 1.99, -3.77))
        a.b("Shoulder" + side, XL(sx, 1.82, 3.38)[:1] + [1.47, -4.29], XL(sx, 1.82, 3.38)[1:] + [2.51, -3.25], ORANGE, claw)
        a.b("Arm" + side, XL(sx, 2.6, 3.64)[:1] + [1.47, -5.85], XL(sx, 2.6, 3.64)[1:] + [2.51, -4.29], ORANGE, claw)
        a.b("Hand" + side, XL(sx, 1.9, 4.5)[:1] + [0.6, -8.2], XL(sx, 1.9, 4.5)[1:] + [3.1, -5.85], RED, claw)
        a.b("FingerOut" + side, XL(sx, 3.5, 4.5)[:1] + [1.0, -11.0], XL(sx, 3.5, 4.5)[1:] + [2.7, -8.2], RED_DARK, claw)
        a.b("GlowFingerOutTip" + side, XL(sx, 2.6, 3.5)[:1] + [1.15, -11.0], XL(sx, 2.6, 3.5)[1:] + [2.55, -10.2], LAVA, claw)
        a.b("FingerIn" + side, XL(sx, 1.9, 2.9)[:1] + [1.15, -9.8], XL(sx, 1.9, 2.9)[1:] + [2.55, -8.2], RED_DARK, claw)
        a.b("GlowFingerInTip" + side, XL(sx, 1.9, 2.9)[:1] + [1.3, -10.2], XL(sx, 1.9, 2.9)[1:] + [2.4, -9.8], LAVA, claw)
    # three legs a side, as the Scorpion's
    for side, sx in SIDES:
        for k, z in enumerate((-2.08, 0.13, 2.34)):
            leg = a.bone(f"Leg{side}{k}", "root", (sx * 2.34, 3.185, z))
            x0, x1 = X(sx, 2.34, 3.9)
            a.b(f"Thigh{side}{k}", (x0, 2.86, z - 0.39), (x1, 3.51, z + 0.39), ORANGE, leg)
            x0, x1 = X(sx, 3.38, 3.9)
            a.b(f"Shin{side}{k}", (x0, 0, z - 0.39), (x1, 2.86, z + 0.39), RED_DARK, leg)
    # the lobster's tail: plated segments narrowing out the back, a glowing fan at the end
    tail = a.bone("Tail", "root", (0, 2.6, 3.38))
    segs = ((2.0, 2.2, 4.1, 3.38, 4.5), (1.8, 2.2, 3.8, 4.5, 5.6), (1.6, 2.1, 3.5, 5.6, 6.7),
            (1.4, 2.0, 3.2, 6.7, 7.7), (1.2, 1.9, 2.9, 7.7, 8.6))
    for i, (hw, y0, y1, z0, z1) in enumerate(segs):
        a.b(f"Tail{i + 1}" if i else "Tail", (-hw, y0, z0), (hw, y1, z1), RED if i % 2 == 0 else RED_DARK, tail)
    a.b("GlowFan", (-0.6, 2.0, 8.6), (0.6, 2.5, 10.2), LAVA, tail)
    for side, sx in SIDES:
        a.b(f"GlowFan{side}1", XL(sx, 0.6, 1.5)[:1] + [2.0, 8.6], XL(sx, 0.6, 1.5)[1:] + [2.5, 9.9], LAVA, tail)
        a.b(f"GlowFan{side}2", XL(sx, 1.5, 2.3)[:1] + [2.0, 8.5], XL(sx, 1.5, 2.3)[1:] + [2.5, 9.4], LAVA, tail)
    a.meta = {"seat": (0, 4.42, -0.52), "neck_loop": {"center": (0, 2.99, -3.9), "radius": 2.2}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(fire_lobster)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "FireLobster.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith("Glow"):
            p.neon = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 12, -21), (-30, 4, 0), (19, 14, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Fire Lobster", "side", "back"], 22).save(os.path.join(out, "FireLobster.png"))
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-30, 12, -30), target=(0, 5, -1), W=T, H=T, fov=40)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Horse", "Fire Lobster"], 22).save(os.path.join(out, "FireLobster_vs_horse.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
