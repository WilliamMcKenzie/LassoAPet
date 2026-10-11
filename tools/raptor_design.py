"""Velociraptor (QM Oct 11): the T-Rex's idea (tools/trex_v2.py) smaller and leaner for the
Jurassic: bright blue with navy tiger stripes (blue stands out on the Jurassic grass), a cream belly and jaw, lilac teeth down a
long snout, a yellow eye under a dark brow and an orange feather crest; longer arms with three
black claws and orange arm feathers, slim legs with a raised black sickle claw on each foot,
and a long stiff tail ending in an orange feather fan. Static draft.

Run: python3 tools/raptor_design.py [out_dir]
writes Raptor.bbmodel, Raptor.png (three views) and Raptor_vs_trex.png to out_dir.

Bones: root, LegL/LegR, ArmL/ArmR, neck (head) > Jaw, Tail > Tail2.
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
from trex_v2 import CLAW, CREAM, EYE, NOSTRIL, TOOTH, trex  # noqa: E402

OUT = "/mnt/project-files/animals/raptor"

BLUE = (76, 154, 226)
STRIPE = (36, 70, 140)
FEATHER = (255, 146, 46)
OVER = 0.025  # how far a stripe block stands out of the body (QM's T-Rex: 0.25 Blockbench units)


def raptor():
    a = Conv("Raptor", "Rare", 1.0)
    a.pivots["root"] = (0, 5.4, 0)

    def stripe(name, hw, ytop, depth, z0, z1, bone):
        """A dark stripe as QM draws them on the T-Rex: one block over the band of the body it
        crosses, OVER bigger than the body on each side and on top, so it shows round it."""
        a.b(name, (-hw - OVER, ytop - depth, z0), (hw + OVER, ytop + OVER, z1), STRIPE, bone)

    # ---- slim legs: a striped thigh, a thin shin raked back, a foot with two clawed toes
    # forward and the big sickle claw held up off the ground on the inside
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 1.1, 5.0, 0.6))
        x0, x1 = X(sx, 0.45, 1.65)
        a.b("Thigh" + side, (x0, 3.0, -0.5), (x1, 5.6, 1.5), BLUE, leg)
        x0, x1 = X(sx, 0.45 - OVER, 1.65 + OVER)
        for i, y0 in enumerate((4.6, 3.7)):
            a.b(f"ThighStripe{side}{i}", (x0, y0, -0.5 - OVER), (x1, y0 + 0.35, 1.5 + OVER), STRIPE, leg)
        x0, x1 = X(sx, 0.7, 1.4)
        a.b("Shin" + side, (x0, 0.7, 0.6), (x1, 3.2, 1.4), BLUE, leg)
        x0, x1 = X(sx, 0.6, 1.5)
        a.b("Foot" + side, (x0, 0.0, -0.5), (x1, 0.7, 1.5), BLUE, leg)
        for i, dx in enumerate((0.0, 0.3)):
            xc = sx * (1.05 + dx)
            a.b(f"Toe{side}{i}", (xc - 0.15, 0.0, -1.1), (xc + 0.15, 0.45, -0.5), BLUE, leg)
            a.pyr(f"Claw{side}{i}", (xc - 0.13, 0.03, -1.1), (xc + 0.13, 0.37, -1.1), "-z", 0.4, CLAW, leg)
        # the sickle claw: a raised toe on the inside, its big claw curling forward
        xc = sx * 0.72
        a.b("SickleToe" + side, (xc - 0.13, 0.7, -0.4), (xc + 0.13, 1.1, 0.1), BLUE, leg)
        a.b("SickleBase" + side, (xc - 0.12, 1.1, -0.55), (xc + 0.12, 1.35, -0.1), CLAW, leg)
        a.pyr("SickleClaw" + side, (xc - 0.11, 0.85, -0.55), (xc + 0.11, 1.3, -0.55), "-z", 0.55, CLAW, leg)

    # ---- body: lean, held level, cream belly and chest, stripes down the back
    a.b("Body", (-1.4, 3.8, -2.4), (1.4, 6.6, 2.4), BLUE, "root")
    a.b("Belly", (-1.15, 3.55, -2.1), (1.15, 3.8, 2.1), CREAM, "root")
    a.b("Chest", (-1.1, 3.8, -2.62), (1.1, 5.8, -2.4), CREAM, "root")
    for i, z in enumerate((-1.8, -0.6, 0.6, 1.8)):
        stripe(f"BackStripe{i}", 1.4, 6.6, 1.4 - 0.25 * (i % 2), z, z + 0.45, "root")

    # ---- arms: longer than the T-Rex's, three black claws, orange feathers trailing behind
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, "root", (sx * 1.3, 5.4, -2.0))
        x0, x1 = X(sx, 1.15, 1.75)
        a.b("UpperArm" + side, (x0, 4.2, -2.6), (x1, 5.6, -1.8), BLUE, arm)
        a.b("Forearm" + side, (x0, 3.8, -3.6), (x1, 4.45, -2.4), BLUE, arm)
        a.b("ArmFeather" + side, (x0, 3.45, -3.2), (x1, 3.8, -2.0), FEATHER, arm)
        for i, dx in enumerate((-0.18, 0.0, 0.18)):
            xc = sx * 1.45 + dx
            a.pyr(f"ArmClaw{side}{i}", (xc - 0.08, 3.85, -3.6), (xc + 0.08, 4.15, -3.6), "-z", 0.35, CLAW, arm)

    # ---- tail: long and stiff, stripes over, an orange feather fan at the tip
    tail = a.bone("Tail", "root", (0, 5.6, 2.4))
    a.b("Tail1", (-1.0, 4.4, 2.4), (1.0, 6.3, 6.0), BLUE, tail)
    a.b("TailBelly1", (-0.8, 4.2, 2.4), (0.8, 4.4, 5.8), CREAM, tail)
    for i, z in enumerate((3.2, 4.6)):
        stripe(f"TailStripe1{i}", 1.0, 6.3, 1.1, z, z + 0.4, tail)
    tail2 = a.bone("Tail2", "Tail", (0, 5.4, 6.0))
    a.b("Tail2", (-0.6, 4.8, 6.0), (0.6, 5.9, 9.8), BLUE, tail2)
    for i, z in enumerate((6.8, 8.2)):
        stripe(f"TailStripe2{i}", 0.6, 5.9, 0.7, z, z + 0.35, tail2)
    a.b("TailFeather", (-0.9, 4.95, 9.8), (0.9, 5.75, 10.7), FEATHER, tail2)
    for i, x in enumerate((-0.55, 0.0, 0.55)):
        a.pyr(f"TailFeatherTip{i}", (x - 0.25, 5.05, 10.7), (x + 0.25, 5.65, 10.7), "+z", 0.6, FEATHER, tail2)

    # ---- neck rising forward, a long low head: dark brow, yellow eye, nostril, orange crest
    head = a.bone("neck", "root", (0, 6.0, -2.2))
    a.b("Neck", (-0.85, 5.2, -3.6), (0.85, 8.0, -2.0), BLUE, head)
    a.b("Throat", (-0.7, 5.0, -3.5), (0.7, 5.2, -2.2), CREAM, head)
    stripe("NeckStripe", 0.85, 8.0, 0.9, -3.0, -2.6, head)
    a.b("Head", (-1.1, 7.2, -6.9), (1.1, 9.0, -3.3), BLUE, head)
    stripe("HeadStripe", 1.1, 9.0, 0.7, -4.1, -3.7, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.1, 7.9, 8.6, -4.9, -4.1, head, eye=EYE)
        x0, x1 = X(sx, 0.6, 1.2)
        a.b("Brow" + side, (x0, 8.6, -5.2), (x1, 8.95, -3.9), STRIPE, head)
        x0, x1 = X(sx, 1.1, 1.15)
        a.b("Nostril" + side, (x0, 8.4, -6.7), (x1, 8.65, -6.45), NOSTRIL, head)
    for i, (z, ln) in enumerate(((-3.9, 0.7), (-3.4, 0.9))):
        a.pyr(f"Crest{i}", (-0.25, 9.0, z - 0.25), (0.25, 9.0, z + 0.25), "+y", ln, FEATHER, head)
    a.pyr("CrestBack", (-0.3, 8.2, -3.3), (0.3, 8.8, -3.3), "+z", 0.8, FEATHER, head)
    jaw = a.bone("Jaw", "neck", (0, 7.2, -3.6))
    a.b("Jaw", (-1.0, 6.5, -6.7), (1.0, 7.2, -3.6), CREAM, jaw)
    for side, sx in SIDES:
        for i, z in enumerate(np.arange(-6.5, -4.0, 0.5)):
            x0, x1 = X(sx, 0.86, 1.08)
            a.pyr(f"Tooth{side}{i}", (x0, 7.2, z - 0.18), (x1, 7.2, z + 0.18), "-y", 0.4, TOOTH, head)
    for i, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
        a.pyr(f"ToothFront{i}", (x - 0.17, 7.2, -6.9), (x + 0.17, 7.2, -6.7), "-y", 0.4, TOOTH, head)
    a.meta = {"seat": (0, 6.74, 0.2), "neck_loop": {"center": (0, 6.6, -2.8), "radius": 1.2}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(raptor)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Raptor.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    plain = ("Eye", "Pupil", "Tooth", "Claw", "ArmClaw", "Nostril", "Sickle", "Crest", "TailFeatherTip")
    for p in parts:
        if p.name.startswith(plain):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    W = 480
    sheet = Image.new("RGB", (W * 3, W))
    for i, v in enumerate(((-19, 8, -21), (-30, 4, 0), (19, 12, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=W, H=W, fov=34), (i * W, 0))
    A.label(sheet, ["Velociraptor", "side", "back"], 22).save(os.path.join(out, "Raptor.png"))
    # beside the T-Rex draft, both at model size, the raptor set off to one side
    _, _, rex = C.build(trex)
    for p in parts:
        p.polys = [q + np.array([-12.0, 0, 0]) for q in p.polys]
    cam = dict(eye=(-40, 16, -40), target=(-5, 5, 1), W=W * 2, H=W, fov=34)
    A.label(render(rex + parts, **cam), ["Velociraptor and T-Rex"], 22).save(os.path.join(out, "Raptor_vs_trex.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
