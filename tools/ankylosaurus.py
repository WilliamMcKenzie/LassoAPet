"""Ankylosaurus (QM Oct 11): the T-Rex's conventions (tools/trex_v2.py, tools/raptor_design.py)
on a low, wide, four-legged tank for the Jurassic: mustard yellow with dark brown armour bands
(each band one block, OVER bigger than the body on the sides and top, as QM draws the T-Rex's
stripes), a cream belly and beak, bone-white spikes down both flanks and two rows along the
back, horns at the back of a flat armoured head, and a long tail ending in a big brown club.
Static draft.

Run: python3 tools/ankylosaurus.py [out_dir]
writes Ankylosaurus.bbmodel, Ankylosaurus.png (three views) and Ankylosaurus_vs_trex.png.

Bones: root, LegFL/LegFR/LegHL/LegHR, neck (head) > Jaw, Tail > Tail2 (the club).
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
from trex_v2 import CREAM, EYE, NOSTRIL, trex  # noqa: E402

OUT = "/mnt/project-files/animals/ankylosaurus"

BODY = (236, 190, 62)  # mustard
BAND = (138, 84, 40)  # armour bands, brow, head plate, club
SPIKE = (250, 240, 214)  # bone
NAIL = (60, 50, 44)
OVER = 0.025  # a band stands this far out of the body (QM's T-Rex stripes: 0.25 Blockbench units)


def ankylosaurus():
    a = Conv("Ankylosaurus", "Rare", 1.0)
    a.pivots["root"] = (0, 3.3, 0)

    def band(name, hw, y0, ytop, z0, z1, bone):
        """One armour band: a single block over the body, OVER bigger on the sides and top."""
        a.b(name, (-hw - OVER, y0, z0), (hw + OVER, ytop + OVER, z1), BAND, bone)

    # ---- four short, thick legs with broad feet and three dark nails
    for leg, z, top in (("F", -2.4, 2.4), ("H", 2.3, 2.6)):
        for side, sx in SIDES:
            bone = a.bone(f"Leg{leg}{side}", "root", (sx * 1.9, top, z))
            x0, x1 = X(sx, 1.25, 2.55)
            a.b(f"Leg{leg}{side}", (x0, 0.5, z - 0.65), (x1, top + 0.4, z + 0.65), BODY, bone)
            x0, x1 = X(sx, 1.15, 2.65)
            a.b(f"Foot{leg}{side}", (x0, 0.0, z - 0.85), (x1, 0.5, z + 0.75), BODY, bone)
            for i, dx in enumerate((-0.45, 0.0, 0.45)):
                xc = sx * 1.9 + dx
                a.b(f"Nail{leg}{side}{i}", (xc - 0.17, 0.0, z - 1.0), (xc + 0.17, 0.3, z - 0.8), NAIL, bone)

    # ---- body: wide and low, cream belly, armour bands across the back
    a.b("Body", (-2.7, 1.9, -3.6), (2.7, 4.8, 3.6), BODY, "root")
    a.b("Belly", (-2.3, 1.7, -3.2), (2.3, 1.9, 3.2), CREAM, "root")
    for i, z in enumerate((-2.9, -1.3, 0.9, 2.5)):
        band(f"Band{i}", 2.7, 3.1, 4.8, z, z + 0.6, "root")
    # two rows of spikes along the back, leaving the saddle (z -1.2..1.2) clear
    for side, sx in SIDES:
        for i, z in enumerate((-2.3, 1.7, 3.1)):
            xc = sx * 1.6
            a.pyr(f"BackSpike{side}{i}", (xc - 0.3, 4.8, z - 0.3), (xc + 0.3, 4.8, z + 0.3), "+y", 0.7, SPIKE, "root")
        # flank spikes, biggest at the shoulder
        for i, (z, ln) in enumerate(((-3.0, 1.3), (-1.6, 1.0), (-0.2, 0.9), (1.2, 0.9), (2.6, 0.8))):
            a.pyr(f"FlankSpike{side}{i}", (sx * 2.7, 3.3, z - 0.32), (sx * 2.7, 3.95, z + 0.32), "-x" if sx < 0 else "+x", ln, SPIKE, "root")

    # ---- head: short neck, flat wide head under a brown plate, horns out the back corners,
    # a cream beak, yellow eye under a dark brow, and a jaw that opens with -X
    head = a.bone("neck", "root", (0, 3.4, -3.6))
    a.b("Neck", (-1.5, 2.3, -4.3), (1.5, 4.2, -3.6), BODY, head)
    a.b("Head", (-1.5, 2.4, -6.4), (1.5, 3.9, -4.1), BODY, head)
    a.b("HeadPlate", (-1.5 - OVER, 3.5, -6.0), (1.5 + OVER, 3.9 + OVER, -4.1), BAND, head)
    a.b("Beak", (-1.0, 2.4, -7.1), (1.0, 3.3, -6.4), CREAM, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.5, 2.8, 3.4, -5.6, -4.9, head, eye=EYE)
        x0, x1 = X(sx, 1.0, 1.55)
        a.b("Brow" + side, (x0, 3.4, -5.85), (x1, 3.75, -4.7), BAND, head)
        x0, x1 = X(sx, 0.35, 0.75)
        a.b("Nostril" + side, (x0, 2.9, -7.15), (x1, 3.15, -7.1), NOSTRIL, head)
        a.pyr("Horn" + side, (sx * 1.5, 3.3, -4.6), (sx * 1.5, 3.9, -4.1), "-x" if sx < 0 else "+x", 0.7, SPIKE, head)
        a.pyr("CheekHorn" + side, (sx * 1.5, 2.45, -4.7), (sx * 1.5, 2.95, -4.2), "-x" if sx < 0 else "+x", 0.5, SPIKE, head)
    jaw = a.bone("Jaw", "neck", (0, 2.4, -4.2))
    a.b("Jaw", (-1.3, 2.0, -6.3), (1.3, 2.4, -4.2), CREAM, jaw)
    a.b("JawBeak", (-0.9, 2.0, -6.9), (0.9, 2.4, -6.3), CREAM, jaw)

    # ---- tail: thick at the base, tapering, small spikes down the sides, a big club
    tail = a.bone("Tail", "root", (0, 3.6, 3.6))
    a.b("Tail1", (-1.6, 2.6, 3.6), (1.6, 4.4, 6.8), BODY, tail)
    band("TailBand", 1.6, 2.9, 4.4, 5.0, 5.6, tail)
    for side, sx in SIDES:
        a.pyr(f"TailSpike{side}", (sx * 1.6, 3.2, 5.8), (sx * 1.6, 3.7, 6.3), "-x" if sx < 0 else "+x", 0.7, SPIKE, tail)
    tail2 = a.bone("Tail2", "Tail", (0, 3.4, 6.8))
    a.b("Tail2", (-0.9, 2.9, 6.8), (0.9, 3.9, 10.0), BODY, tail2)
    band("Tail2Band", 0.9, 3.1, 3.9, 8.2, 8.7, tail2)
    a.b("Club", (-1.8, 2.5, 10.0), (1.8, 4.3, 12.0), BAND, tail2)
    a.b("ClubTip", (-1.2, 2.8, 12.0), (1.2, 4.0, 12.5), BAND, tail2)
    for side, sx in SIDES:
        a.pyr(f"ClubKnob{side}", (sx * 1.8, 2.9, 10.4), (sx * 1.8, 3.9, 11.6), "-x" if sx < 0 else "+x", 0.6, SPIKE, tail2)
    a.pyr("ClubKnobTop", (-0.5, 4.3, 10.5), (0.5, 4.3, 11.5), "+y", 0.5, SPIKE, tail2)
    a.meta = {"seat": (0, 4.95, 0.0), "neck_loop": {"center": (0, 3.3, -4.0), "radius": 1.8}}
    return a


PLAIN = ("Eye", "Pupil", "Nail", "Nostril", "BackSpike", "FlankSpike", "Horn", "CheekHorn", "TailSpike", "ClubKnob")


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(ankylosaurus)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Ankylosaurus.bbmodel")
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
    for i, v in enumerate(((-19, 9, -21), (-30, 4, 0), (19, 13, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=W, H=W, fov=34), (i * W, 0))
    A.label(sheet, ["Ankylosaurus", "side", "back"], 22).save(os.path.join(out, "Ankylosaurus.png"))
    _, _, rex = C.build(trex)
    for p in parts:
        p.polys = [q + np.array([-12.0, 0, 0]) for q in p.polys]
    cam = dict(eye=(-40, 16, -40), target=(-5, 5, 1), W=W * 2, H=W, fov=34)
    A.label(render(rex + parts, **cam), ["Ankylosaurus and T-Rex"], 22).save(os.path.join(out, "Ankylosaurus_vs_trex.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
