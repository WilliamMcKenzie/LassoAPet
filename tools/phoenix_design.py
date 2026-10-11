"""Phoenix (QM Oct 11): the first flying animal, after QM's Minecraft-style reference (a
boxy bird with huge spread wings whose feathers break up into pixel flames, a streaming
flame tail, curly plumes on its head), in a fiery scheme: crimson body, wings going
crimson -> orange -> gold, yellow flame tips (Glow*, Neon in game). Static draft.

Run: python3 tools/phoenix_design.py [out_dir]
writes Phoenix.bbmodel, Phoenix.png (three views) and Phoenix_vs_horse.png to out_dir.

Built to fly: wings spread wide from the shoulders, legs tucked back under the body.
Bones root, WingL/WingR, LegL/LegR, neck (head, beak, plumes) and Tail, so a flap can
be added later.
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
OUT = "/mnt/project-files/animals/phoenix"

CRIMSON = (206, 34, 40)  # body, inner wing
RED = (240, 72, 32)  # head, neck, wing band
ORANGE = (255, 132, 24)  # feathers
GOLD = (255, 188, 36)  # beak, legs, feather ends
FLAME = (255, 232, 84)  # glowing flame tips
EYE = (255, 236, 120)


def phoenix():
    a = Conv("Phoenix", "Legendary", 1.0)
    a.pivots["root"] = (0, 6.0, 0)
    # body: a crimson box, an orange chest
    a.b("Body", (-1.6, 5.0, -2.4), (1.6, 8.0, 2.4), CRIMSON, "root")
    a.b("Chest", (-1.3, 5.3, -2.7), (1.3, 7.6, -2.4), ORANGE, "root")
    # legs tucked back under it in flight: gold shins angled back, three toes each
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 0.9, 5.2, 0.8))
        x0, x1 = X(sx, 0.5, 1.3)
        a.b("Thigh" + side, (x0, 4.2, 0.2), (x1, 5.2, 1.6), RED, leg)
        x0, x1 = X(sx, 0.65, 1.15)
        a.b("Shin" + side, (x0, 3.8, 1.4), (x1, 4.4, 3.4), GOLD, leg)
        for i, dx in enumerate((-0.3, 0.0, 0.3)):
            xc = sx * 0.9 + dx
            a.b(f"Toe{side}{i}", (xc - 0.13, 3.5, 3.2), (xc + 0.13, 3.9, 4.2), GOLD, leg)
    # wings spread wide: a crimson arm, an orange band, then a row of long feathers
    # trailing back that break into gold and glowing flame tips, stepping up as they go out
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 1.6, 7.6, -1.0))

        def y(x):  # wings rise toward the tips
            return 7.2 + 0.4 * (x - 1.6)

        for name, x0_, x1_, z0, z1, col in (("Arm", 1.6, 5.0, -1.8, 0.6, CRIMSON), ("Band", 5.0, 8.4, -1.4, 0.4, RED),
                                             ("Hand", 8.4, 10.6, -1.0, 0.2, ORANGE)):
            x0, x1 = X(sx, x0_, x1_)
            yc = y((x0_ + x1_) / 2)
            a.b(f"Wing{name}{side}", (x0, yc, z0), (x1, yc + 0.7, z1), col, wing)
        # trailing feathers: longer toward the tip, each orange -> gold -> flame, in short
        # pixel steps that drift outward as they go back, so the wing fans like the reference
        n = 10
        for i, xf in enumerate(np.linspace(2.0, 9.8, n)):
            length = 2.6 + 0.45 * i + (0.7 if i % 2 else 0)  # a ragged, flickering edge
            drift = 0.08 + 0.07 * i  # studs outward per step
            yc = y(xf + 0.4)
            z = 0.4 if xf < 8.4 else 0.2
            cols = (ORANGE, ORANGE, ORANGE, GOLD, GOLD, FLAME)
            step = length / len(cols)
            for j, col in enumerate(cols):
                xa = xf + drift * j
                x0, x1 = X(sx, xa, xa + 1.2)
                pre = "Glow" if col == FLAME else ""
                a.b(f"{pre}Feather{side}{i}_{j}", (x0, yc + 0.1 + 0.08 * j, z), (x1, yc + 0.55 + 0.08 * j, z + step), col, wing)
                z += step
        # the tip: three long flame feathers flicking out past the hand, fanning forward and back
        for i, (dz, length, fan) in enumerate(((-1.0, 2.6, -0.35), (-0.4, 3.6, 0.0), (0.2, 3.0, 0.35))):
            xs = 10.6
            cols = (ORANGE, ORANGE, GOLD, GOLD, FLAME)
            step = length / len(cols)
            for j, col in enumerate(cols):
                x0, x1 = X(sx, xs, xs + step)
                yc = y(xs) + 0.1 * i
                zc = dz + fan * j
                pre = "Glow" if col == FLAME else ""
                a.b(f"{pre}Tip{side}{i}_{j}", (x0, yc, zc - 0.28), (x1, yc + 0.5, zc + 0.28), col, wing)
                xs += step
    # tail: five long flame streamers trailing out the back, crimson -> orange -> gold ->
    # flame, in pixel steps that fan out sideways and droop a little
    tail = a.bone("Tail", "root", (0, 7.0, 2.4))
    for i, (x, length) in enumerate(((-1.2, 5.0), (-0.6, 6.6), (0.0, 8.0), (0.6, 6.6), (1.2, 5.0))):
        cols = (CRIMSON, CRIMSON, ORANGE, ORANGE, GOLD, GOLD, FLAME)
        step = length / len(cols)
        z, yb = 2.3, 6.6 + 0.15 * (i % 2)
        for j, col in enumerate(cols):
            xc = x * (1 + 0.35 * j)
            yy = yb - 0.12 * j
            pre = "Glow" if col == FLAME else ""
            a.b(f"{pre}Tail{i}_{j}", (xc - 0.32, yy, z), (xc + 0.32, yy + 0.55, z + step), col, tail)
            z += step
    # neck up into a boxy head with a short hooked gold beak
    head = a.bone("neck", "root", (0, 7.6, -2.0))
    a.b("Neck", (-0.9, 7.2, -3.6), (0.9, 9.8, -1.8), RED, head)
    a.b("Head", (-1.4, 9.2, -5.8), (1.4, 11.6, -2.8), RED, head)
    a.b("Beak", (-0.6, 9.8, -7.2), (0.6, 10.8, -5.8), GOLD, head)
    a.b("BeakHook", (-0.5, 9.3, -7.6), (0.5, 10.6, -7.2), GOLD, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.4, 10.1, 11.1, -5.4, -4.2, head, eye=EYE)
    # two curly flame plumes out of the top of the head, curling forward at the end
    for side, sx in SIDES:
        x = sx * 0.6
        steps = ((0.0, 11.6, -3.6, 0.8), (0.0, 12.4, -3.3, 0.8), (0.0, 13.2, -3.5, 0.7), (0.0, 13.9, -4.1, 0.5),
                 (0.0, 13.7, -4.7, 0.5))
        for j, (_, yb, zc, h) in enumerate(steps):
            col = (ORANGE, ORANGE, GOLD, FLAME, FLAME)[j]
            pre = "Glow" if col == FLAME else ""
            a.b(f"{pre}Plume{side}{j}", (x - 0.25, yb, zc - 0.3), (x + 0.25, yb + h, zc + 0.3), col, head)
    a.meta = {"seat": (0, 8.0, 0.6), "neck_loop": {"center": (0, 10.4, -4.2), "radius": 1.8}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(phoenix)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Phoenix.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 10, -21), (-30, 4, 0), (19, 16, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Phoenix", "side", "back"], 22).save(os.path.join(out, "Phoenix.png"))
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-40, 16, -40), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Horse", "Phoenix"], 22).save(os.path.join(out, "Phoenix_vs_horse.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
