"""Desert creatures (first drafts, static models for QM to vet).

Run: python3 tools/desert_designs.py [out_dir]

  Cactus    Uncommon   a running cactus guy: ribbed green body, bent arms, three spines
  Scorpion  Rare       low and wide, big pincers out front, tail curled up over the back
  Sandworm  Epic       plated segments, a dark face with four black mandibles and a red eye
  Snake     Legendary  rears up out of its coil, horned head, open jaws with fangs, spikes

Built with the same blocks as tools/animal_designs.py (flush, axis-aligned,
slopes only from wedges). Bones and animations come after QM vets the shapes.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import render, write_bbmodel  # noqa: E402
import animal_designs as A  # noqa: E402
from animal_designs import Animal, EYE_WHITE, PUPIL, PLATE  # noqa: E402


def face_plate(a, name, x0, x1, y0, y1, z, color, bone="root", depth=PLATE):
    """Thin plate on a front face at z (sticking out toward -z)."""
    return a.box(name, (x0, y0, z - depth), (x1, y1, z), color, bone)


# ---------------------------------------------------------------- cactus

def cactus():
    a = Animal("Cactus", "Uncommon")
    green, rib, spine, face = (118, 204, 64), (72, 150, 44), (214, 176, 96), (54, 34, 24)
    # two chunky legs, a tall body with a stepped round top
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 1.35))
        a.box("Leg" + side, (xa, 0, -0.55), (xb, 3.2, 0.55), green, "root")
    a.box("Body", (-1.6, 3.2, -1.3), (1.6, 11.0, 1.3), green, "root")
    a.box("Top", (-1.2, 11.0, -0.9), (1.2, 11.6, 0.9), green, "neck")
    # ribs: thin dark lines down the front, back and sides
    for i, x in enumerate((-1.0, 1.0)):
        face_plate(a, f"PlainRibF{i}", x - 0.07, x + 0.07, 3.4, 10.8, -1.3, rib)
        a.box(f"PlainRibB{i}", (x - 0.07, 3.4, 1.3), (x + 0.07, 10.8, 1.3 + PLATE), rib, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.6, sx * (1.6 + PLATE)))
        a.box("PlainRibS" + side, (xa, 3.4, -0.07), (xb, 10.8, 0.07), rib, "root")
    # face: two dark eyes and an O mouth
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 0.8))
        face_plate(a, "Eye" + side, xa, xb, 9.2, 9.9, -1.3, face, "neck")
    face_plate(a, "Mouth", -0.25, 0.25, 7.6, 8.8, -1.3, face, "neck")
    # arms: out to the side, the left bends up, the right bends down
    a.box("ArmL", (-3.4, 7.3, -0.45), (-1.6, 8.2, 0.45), green, "ArmL")
    a.box("ForearmL", (-3.4, 8.2, -0.45), (-2.5, 10.1, 0.45), green, "ArmL")
    a.box("ArmR", (1.6, 6.9, -0.45), (3.4, 7.8, 0.45), green, "ArmR")
    a.box("ForearmR", (2.5, 5.0, -0.45), (3.4, 6.9, 0.45), green, "ArmR")
    # three spines on top
    for i, (x, h) in enumerate(((-0.5, 1.0), (0, 1.35), (0.5, 1.0))):
        a.box(f"PlainSpine{i}", (x - 0.07, 11.6, -0.07), (x + 0.07, 11.6 + h, 0.07), spine, "neck")
    a.meta = {"seat": (0, 11.7, 0.2), "neck_loop": {"center": (0, 9.5, 0), "radius": 2.2}}
    return a


# ---------------------------------------------------------------- scorpion

def scorpion():
    a = Animal("Scorpion", "Rare")
    shell, dark, joint, sting = (230, 160, 74), (184, 110, 50), (160, 70, 60), (70, 44, 40)
    # body in plates: light, dark seam, light...
    bands = [(-2.4, -0.9, shell), (-0.9, -0.6, dark), (-0.6, 0.9, shell), (0.9, 1.2, dark), (1.2, 2.6, shell)]
    for i, (z0, z1, c) in enumerate(bands):
        a.box(f"Body{i + 1}", (-1.8, 1.6, z0), (1.8, 3.4, z1), c, "root")
    a.box("Head", (-1.4, 1.6, -3.6), (1.4, 3.0, -2.399), shell, "neck")
    a.eyes(1.4, 2.2, 2.9, -3.5, -2.8)
    a.bone_order = [("root", None), ("neck", "root"), ("Tail", "root"), ("ClawL", "root"), ("ClawR", "root")]
    a.pivots = {"root": (0, 2.5, 0.1), "neck": (0, 2.3, -2.4), "Tail": (0, 2.0, 2.6)}
    for side, sx in (("L", -1), ("R", 1)):
        a.pivots["Claw" + side] = (sx * 1.4, 2.3, -2.9)
        for k, z in enumerate((-1.6, 0.1, 1.8)):
            a.bone_order.append((f"Leg{side}{k}", "root"))
            a.pivots[f"Leg{side}{k}"] = (sx * 1.8, 2.45, z)
        def X(a0, a1):
            return sorted((sx * a0, sx * a1))
        # pincer arm: out from the head's side, then forward
        x0, x1 = X(1.4, 2.6)
        a.box("Shoulder" + side, (x0, 1.9, -3.3), (x1, 2.7, -2.5), joint, "Claw" + side)
        x0, x1 = X(2.0, 2.8)
        a.box("Arm" + side, (x0, 1.9, -4.5), (x1, 2.7, -3.3), joint, "Claw" + side)
        # the claw: a chunky hand, a long outer finger hooking in over a short inner
        # one, with a gap between them
        x0, x1 = X(1.6, 3.2)
        a.box("Hand" + side, (x0, 1.4, -5.8), (x1, 3.0, -4.5), shell, "Claw" + side)
        x0, x1 = X(2.6, 3.2)
        a.box("FingerOut" + side, (x0, 1.7, -7.8), (x1, 2.7, -5.8), dark, "Claw" + side)
        x0, x1 = X(2.0, 2.6)
        a.box("FingerOutTip" + side, (x0, 1.8, -7.8), (x1, 2.6, -7.3), sting, "Claw" + side)
        x0, x1 = X(1.6, 2.1)
        a.box("FingerIn" + side, (x0, 1.8, -6.7), (x1, 2.6, -5.8), dark, "Claw" + side)
        a.box("FingerInTip" + side, (x0, 1.85, -7.0), (x1, 2.55, -6.7), sting, "Claw" + side)
        # three legs a side: out, then down
        for k, z in enumerate((-1.6, 0.1, 1.8)):
            x0, x1 = X(1.8, 3.0)
            a.box(f"Thigh{side}{k}", (x0, 2.2, z - 0.3), (x1, 2.7, z + 0.3), joint, f"Leg{side}{k}")
            x0, x1 = X(2.6, 3.0)
            a.box(f"Shin{side}{k}", (x0, 0, z - 0.3), (x1, 2.2, z + 0.3), dark, f"Leg{side}{k}")
    # tail: plated segments up and over the back, stinger hanging forward
    segs = [((-0.8, 2.0, 2.6), (0.8, 3.4, 3.8)),
            ((-0.7, 3.4, 3.1), (0.7, 5.0, 4.3)),
            ((-0.7, 5.0, 3.1), (0.7, 6.6, 4.3)),
            ((-0.7, 6.6, 2.7), (0.7, 8.0, 3.9)),
            ((-0.65, 7.6, 1.5), (0.65, 8.8, 2.7))]
    for i, (lo, hi) in enumerate(segs):
        a.box(f"Tail{i + 1}" if i else "Tail", lo, hi, shell if i % 2 == 0 else dark, "Tail")
    a.box("Bulb", (-0.6, 7.4, 0.3), (0.6, 8.6, 1.5), joint, "Tail")
    a.wedge("Stinger", (-0.3, 6.4, 0.3), (0.3, 7.4, 1.0), sting, "Tail", "down_back")
    a.meta = {"seat": (0, 3.4, -0.4), "neck_loop": {"center": (0, 2.3, -3.0), "radius": 1.7}}
    a.meta_scale = 1.3
    return a


# ---------------------------------------------------------------- sandworm

def sandworm():
    a = Animal("Sandworm", "Epic")
    sand, ring, face, horn, eye = (226, 180, 112), (182, 128, 74), (70, 36, 34), (46, 38, 40), (236, 44, 44)
    # segments from head to tail, each with a darker plated ring at its front
    segs = [("Head", 2.2, 4.4, -6.0, -3.0, "neck"),
            ("Seg1", 2.0, 4.0, -3.0, 0.0, "root"),
            ("Seg2", 1.8, 3.6, 0.0, 3.0, "root"),
            ("Seg3", 1.5, 3.0, 3.0, 5.6, "Tail"),
            ("Seg4", 1.1, 2.2, 5.6, 7.8, "Tail")]
    for name, hw, h, z0, z1, bone in segs:
        a.box(name, (-hw, 0, z0), (hw, h, z1), sand, bone)
        if name != "Head":
            a.box(name + "Ring", (-hw - 0.15, 0, z0), (hw + 0.15, h + 0.15, z0 + 0.5), ring, bone)
    a.wedge("TailTip", (-0.7, 0, 7.8), (0.7, 1.4, 9.0), ring, "Tail", "down_back")
    # face: dark mouth plate, a red eye in the middle
    face_plate(a, "PlainFace", -1.6, 1.6, 0.8, 3.6, -6.0, face, "neck")
    face_plate(a, "EyeRed", -0.35, 0.35, 1.85, 2.55, -6.0 - PLATE, eye, "neck")
    # four mandibles off the face's corners: out forward, then hooking in
    for vx, x in (("L", -1), ("R", 1)):
        for vy, (y0, y1) in (("T", (3.0, 3.7)), ("B", (0.7, 1.4))):
            xa, xb = sorted((x * 1.2, x * 1.9))
            a.box(f"Mandible{vy}{vx}", (xa, y0, -7.8), (xb, y1, -6.0), horn, "neck")
            xa, xb = sorted((x * 0.6, x * 1.2))
            a.box(f"Hook{vy}{vx}", (xa, y0, -7.8), (xb, y1, -7.2), horn, "neck")
    a.meta = {"seat": (0, 4.2, -1.2), "neck_loop": {"center": (0, 2.2, -4.5), "radius": 3.0}}
    a.meta_scale = 1.2
    return a


# ---------------------------------------------------------------- snake

def snake():
    a = Animal("Snake", "Legendary")
    body, coil, belly, spike, mouth, horn = (226, 184, 104), (176, 60, 84), (248, 228, 180), (250, 240, 214), (206, 72, 112), (250, 236, 200)
    # the coil on the ground: a ring, and a smaller ring stacked on top
    a.box("CoilL", (-2.6, 0, -2.8), (-0.8, 1.8, 4.0), coil, "root")
    a.box("CoilB", (-2.6, 0, 4.0), (2.6, 1.8, 5.8), coil, "Tail")
    a.box("CoilR", (0.8, 0, -0.6), (2.6, 1.8, 4.0), coil, "Tail")
    a.wedge("TailTip", (0.8, 0, -2.0), (2.6, 1.0, -0.6), coil, "Tail", "up_back")
    a.box("CoilF", (-0.8, 0, -2.8), (0.9, 1.8, -1.0), body, "root")
    a.box("CoilMid", (-0.8, 0, -1.0), (0.8, 1.8, 4.0), coil, "root")
    a.box("Coil2", (-1.8, 1.8, -1.0), (1.8, 3.2, 4.2), coil, "root")
    # the neck rearing up out of the front, cream belly facing forward
    a.box("Neck", (-0.9, 1.8, -2.8), (0.9, 7.8, -1.0), body, "neck")
    face_plate(a, "Belly", -0.6, 0.6, 1.9, 7.6, -2.8, belly, "neck")
    # head: skull juts forward, lower jaw hangs open
    a.box("Skull", (-1.2, 7.8, -5.2), (1.2, 9.2, -0.8), body, "neck")
    a.box("MouthIn", (-0.9, 7.2, -4.4), (0.9, 7.8, -1.0), mouth, "neck")
    a.box("Jaw", (-1.0, 6.6, -4.8), (1.0, 7.2, -1.0), body, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.45, sx * 0.85))
        a.wedge("Fang" + side, (xa, 7.2, -5.1), (xb, 7.8, -4.7), spike, "neck", "down_back")
        xa, xb = sorted((sx * 0.3, sx * 0.6))
        a.wedge("FangLow" + side, (xa, 7.2, -4.8), (xb, 7.6, -4.5), spike, "neck")
        xa, xb = sorted((sx * 0.5, sx * 0.95))
        a.wedge("Horn" + side, (xa, 9.2, -1.6), (xb, 10.8, -0.8), horn, "neck", "up_back")
    a.eyes(1.2, 8.4, 9.1, -3.6, -2.6)
    # spikes down the back of the neck and along the coil
    for i, y in enumerate((2.6, 4.0, 5.4, 6.8)):
        a.wedge(f"Spike{i}", (-0.2, y, -1.0), (0.2, y + 0.7, -0.4), spike, "neck", "down_front")
    for i, (x, z) in enumerate(((-1.7, 0.0), (-1.7, 2.6), (1.7, 1.2), (-1.3, 4.9), (1.3, 4.9))):
        top = 3.2 if abs(x) < 1.8 and -1.0 <= z <= 4.2 else 1.8
        a.wedge(f"CoilSpike{i}", (x - 0.2, top, z - 0.3), (x + 0.2, top + 0.6, z + 0.3), spike, "root")
    a.meta = {"seat": (0, 3.4, 1.6), "neck_loop": {"center": (0, 5.5, -1.9), "radius": 1.5}}
    return a


CREATURES = [cactus, scorpion, sandworm, snake]


def scaled(a):
    k = getattr(a, "meta_scale", 1)
    if k != 1:
        a.scale(k)
    return a


def main(out):
    os.makedirs(out, exist_ok=True)
    horse = A.qm_horse("A")
    from horse_rig import pose
    lineup = [("Horse (for size)", pose(horse, None, 0))]
    for fn in CREATURES:
        a = scaled(fn())
        lineup.append((f"{a.name} · {a.rarity}", a.parts))
        print(a.name, len(a.parts), "parts")
    W, H = 360, 420
    cams = [dict(eye=(-24, 15, -27), target=(0, 4.5, -0.5)), dict(eye=(-38, 7, -1), target=(0, 4.5, -1)),
            dict(eye=(21, 13, 28), target=(0, 4.5, 0.5))]
    sheet = Image.new("RGB", (W * len(lineup), H * len(cams)))
    for c, (_, parts) in enumerate(lineup):
        for r, cam in enumerate(cams):
            sheet.paste(render(parts, W=W, H=H, fov=36, **cam), (c * W, r * H))
    A.label(sheet, [n for n, _ in lineup], 22).save(os.path.join(out, "desert_lineup.png"))
    print("wrote", out)


def one(name, out):
    """Close look at one creature: three angles plus the front."""
    fn = next(f for f in CREATURES if f.__name__ == name.lower())
    a = scaled(fn())
    W, H = 480, 480
    cams = [dict(eye=(-17, 11, -19), target=(0, 3.5, -2)), dict(eye=(-26, 5, -2), target=(0, 3.5, -2)),
            dict(eye=(15, 10, 20), target=(0, 3.5, 0)), dict(eye=(-4, 6, -24), target=(0, 3, -2)), dict(eye=(0, 30, -8), target=(0, 0, -2))]
    sheet = Image.new("RGB", (W * len(cams), H))
    for i, cam in enumerate(cams):
        sheet.paste(render(a.parts, W=W, H=H, fov=40, **cam), (i * W, 0))
    if a.pivots.keys() >= {n for n, _ in a.bone_order}:
        model, _ = write_bbmodel(a.parts, a.name, None, bones=a.bones())
        with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
            json.dump(model, f, separators=(",", ":"))
        print("wrote", a.name + ".bbmodel")
    path = os.path.join(out, f"{a.name}.png")
    sheet.save(path)
    print("wrote", path)


if __name__ == "__main__":
    args = sys.argv[1:]
    out = "/mnt/project-files/animals/desert"
    if args and args[0] == "one":
        one(args[1], out)
    else:
        main(*(args or [out]))
