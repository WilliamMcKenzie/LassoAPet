"""Chocobo (QM Oct 11): a big yellow riding bird in full tack, after QM's reference (Final
Fantasy's chocobo): a fluffy yellow body and chest, a long neck, a crest of feathers
swept back off the head, an orange beak in a bridle with reins and a hanging crystal,
small wings, a fan of long tail feathers, and long legs in leather boots with steel
plates over big grey clawed feet. On its back a saddle (high cantle, pommel, steel
skirt plates), a blue cloth hanging down in front, a girth strap and stirrups, a bedroll
behind the saddle and a pouch on the chest strap. Detailed like the Snack Yak.
Static draft, no animations.

Run: python3 tools/chocobo_design.py [out_dir]
writes Chocobo.bbmodel, Chocobo.png (three views) and Chocobo_vs_horse.png to out_dir.

Bones: root, LegL/LegR, WingL/WingR, neck (head, beak, bridle) and Tail.
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
OUT = "/mnt/project-files/animals/chocobo"

YELLOW = (255, 206, 72)
FLUFF = (255, 230, 140)  # chest, belly, thigh fluff
FEATHER = (240, 172, 56)  # wing and tail feathers
FEATHER_TIP = (186, 112, 44)
BEAK = (255, 150, 40)
BEAK_LOW = (232, 120, 30)
FOOT = (110, 108, 120)
CLAW = (44, 42, 52)
LEATHER = (132, 80, 44)
LEATHER_DARK = (84, 50, 30)
TAN = (206, 160, 104)
STEEL = (190, 196, 206)
GOLD = (240, 196, 72)
CLOTH = (72, 96, 200)
CLOTH_DARK = (52, 70, 160)
ROLL = (244, 240, 228)
ROLL_END = (200, 196, 186)
CRYSTAL = (170, 230, 255)


def chocobo():
    a = Conv("Chocobo", "Legendary", 1.0)
    a.pivots["root"] = (0, 7.0, 0)

    # ---- legs: fluffy yellow thighs, leather boots with a turned-down cuff, a steel shin
    # plate and buckled strap, grey ankles and big feet (three toes forward, one back)
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 1.2, 6.6, 0.4))
        x0, x1 = X(sx, 0.3, 2.15)
        a.b("Thigh" + side, (x0, 3.8, -0.8), (x1, 6.8, 1.5), YELLOW, leg)
        x0, x1 = X(sx, 0.5, 1.9)
        a.b("ThighFluff" + side, (x0, 3.3, -0.4), (x1, 3.8, 1.4), FLUFF, leg)
        a.pyr("ThighTuft" + side, (x0, 3.3, 0.4), (x1, 3.3, 1.4), "-y", 0.5, FLUFF, leg)
        x0, x1 = X(sx, 0.7, 1.7)
        a.b("Boot" + side, (x0, 1.0, -0.3), (x1, 3.4, 0.7), LEATHER, leg)
        x0, x1 = X(sx, 0.55, 1.85)
        a.b("Cuff" + side, (x0, 2.9, -0.45), (x1, 3.6, 0.85), TAN, leg)
        a.b("CuffBand" + side, (x0, 2.85, -0.47), (x1, 3.0, 0.87), LEATHER_DARK, leg)
        x0, x1 = X(sx, 0.9, 1.5)
        a.b("ShinPlate" + side, (x0, 1.3, -0.47), (x1, 2.8, -0.3), STEEL, leg)
        a.b("ShinRivet" + side, (sx * 1.2 - 0.1, 2.3, -0.55), (sx * 1.2 + 0.1, 2.5, -0.47), GOLD, leg)
        x0, x1 = X(sx, 0.65, 1.75)
        a.b("BootStrap" + side, (x0, 1.6, -0.35), (x1, 1.9, 0.75), LEATHER_DARK, leg)
        a.b("Buckle" + side, (sx * 1.2 - 0.15, 1.55, -0.57), (sx * 1.2 + 0.15, 1.95, -0.47), GOLD, leg)
        x0, x1 = X(sx, 0.65, 1.75)
        a.b("BootSole" + side, (x0, 0.8, -0.35), (x1, 1.05, 0.7), LEATHER_DARK, leg)
        x0, x1 = X(sx, 0.85, 1.55)
        a.b("Ankle" + side, (x0, 0.35, -0.2), (x1, 0.8, 0.55), FOOT, leg)
        for i, dx in enumerate((-0.55, 0.0, 0.55)):
            xc = sx * 1.2 + dx
            a.b(f"Toe{side}{i}", (xc - 0.22, 0.0, -1.7 + 0.2 * (i != 1)), (xc + 0.22, 0.45, 0.1), FOOT, leg)
            a.b(f"Knuckle{side}{i}", (xc - 0.24, 0.45, -1.1 + 0.2 * (i != 1)), (xc + 0.24, 0.6, -0.5 + 0.2 * (i != 1)), FOOT, leg)
            zt = -1.7 + 0.2 * (i != 1)
            a.pyr(f"Claw{side}{i}", (xc - 0.18, 0.05, zt), (xc + 0.18, 0.4, zt), "-z", 0.55, CLAW, leg)
        xc = sx * 1.2
        a.b("ToeBack" + side, (xc - 0.2, 0.0, 0.5), (xc + 0.2, 0.35, 1.2), FOOT, leg)
        a.pyr("ClawBack" + side, (xc - 0.16, 0.03, 1.2), (xc + 0.16, 0.31, 1.2), "+z", 0.4, CLAW, leg)

    # ---- body: a big yellow box with a puffed pale chest, belly fluff and a rounded rump
    a.b("Body", (-2.0, 6.2, -3.0), (2.0, 10.0, 3.0), YELLOW, "root")
    a.b("Chest", (-1.7, 6.5, -3.6), (1.7, 9.6, -3.0), FLUFF, "root")
    a.b("ChestLow", (-1.3, 6.0, -3.3), (1.3, 6.5, -2.4), FLUFF, "root")
    for i, x in enumerate((-1.0, 0.0, 1.0)):
        a.pyr(f"ChestTuft{i}", (x - 0.4, 6.0, -3.5), (x + 0.4, 6.0, -2.7), "-y", 0.6, FLUFF, "root")
    a.b("Belly", (-1.7, 5.8, -2.4), (1.7, 6.2, 2.4), FLUFF, "root")
    a.b("Rump", (-1.7, 6.6, 3.0), (1.7, 9.6, 3.5), YELLOW, "root")
    a.b("BackRidge", (-1.6, 10.0, 2.6), (1.6, 10.3, 3.4), YELLOW, "root")

    # ---- small wings folded on the sides behind the saddle, layered feathers with brown tips
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 2.0, 9.6, 0.6))
        x0, x1 = X(sx, 2.0, 2.45)
        a.b("Wing" + side, (x0, 7.6, 0.6), (x1, 9.8, 2.8), YELLOW, wing)
        x0, x1 = X(sx, 2.05, 2.4)
        a.b(f"WingFeather{side}0", (x0, 7.0, 1.2), (x1, 7.6, 3.4), FEATHER, wing)
        a.b(f"WingFeather{side}1", (x0, 7.6, 2.8), (x1, 9.2, 3.8), FEATHER, wing)
        a.b(f"WingTip{side}0", (x0, 6.6, 2.2), (x1, 7.0, 3.6), FEATHER_TIP, wing)
        a.b(f"WingTip{side}1", (x0, 7.0, 3.4), (x1, 8.6, 4.2), FEATHER_TIP, wing)
        x0, x1 = X(sx, 2.45, 2.6)
        a.b(f"WingCovert{side}", (x0, 8.6, 0.8), (x1, 9.6, 2.6), FLUFF, wing)

    # ---- tail: a fan of five long feathers rising out the back, brown at the tips
    tail = a.bone("Tail", "root", (0, 9.0, 3.4))
    for i, (x, rise) in enumerate(((-1.3, 0.0), (-0.65, 0.5), (0.0, 0.8), (0.65, 0.5), (1.3, 0.0))):
        w = 0.28
        a.b(f"TailA{i}", (x - w, 8.4 + rise * 0.3, 3.4), (x + w, 9.6 + rise * 0.3, 5.0), FEATHER, tail)
        a.b(f"TailB{i}", (x - w, 9.2 + rise * 0.6, 4.8), (x + w, 10.2 + rise * 0.6, 6.4), FEATHER, tail)
        a.b(f"TailC{i}", (x - w, 10.0 + rise, 6.2), (x + w, 10.8 + rise, 7.4), FEATHER_TIP, tail)
        a.pyr(f"TailTip{i}", (x - w, 10.1 + rise, 7.4), (x + w, 10.7 + rise, 7.4), "+z", 0.7, FEATHER_TIP, tail)

    # ---- tack on the back: blue cloth hanging down in front, a girth strap round the belly,
    # the saddle (seat, high cantle, pommel with a steel plate), steel-plated leather skirts,
    # stirrups, a bedroll strapped behind and a chest strap with a pouch
    for side, sx in SIDES:
        x0, x1 = X(sx, 2.0, 2.12)
        a.b("Cloth" + side, (x0, 5.4, -2.6), (x1, 10.05, -1.2), CLOTH, "root")
        a.b("ClothHem" + side, (x0, 5.2, -2.6), (x1, 5.4, -1.2), CLOTH_DARK, "root")
        x0, x1 = X(sx, 2.12, 2.24)
        a.b("Skirt" + side, (x0, 7.6, -1.3), (x1, 10.05, 0.9), LEATHER, "root")
        x0, x1 = X(sx, 2.24, 2.34)
        a.b("SkirtPlate" + side, (x0, 8.2, -1.0), (x1, 9.6, 0.6), STEEL, "root")
        x0, x1 = X(sx, 2.34, 2.42)
        a.b("SkirtBoss" + side, (x0, 8.7, -0.4), (x1, 9.1, 0.0), GOLD, "root")
        x0, x1 = X(sx, 2.0, 2.16)
        a.b("Girth" + side, (x0, 5.8, -0.6), (x1, 7.6, -0.2), LEATHER_DARK, "root")
        x0, x1 = X(sx, 2.34, 2.46)
        a.b("StirrupStrap" + side, (x0, 5.0, 0.3), (x1, 7.8, 0.6), LEATHER, "root")
        x0, x1 = X(sx, 2.3, 2.7)
        a.b("Stirrup" + side, (x0, 4.6, 0.0), (x1, 5.0, 0.9), STEEL, "root")
    a.b("GirthUnder", (-2.16, 5.7, -0.6), (2.16, 5.8, -0.2), LEATHER_DARK, "root")
    a.b("Seat", (-1.6, 10.0, -1.4), (1.6, 10.4, 1.2), LEATHER_DARK, "root")
    a.b("Cantle", (-1.5, 10.4, 0.9), (1.5, 11.4, 1.4), LEATHER, "root")
    a.b("CantleTrim", (-1.55, 11.4, 0.85), (1.55, 11.55, 1.45), TAN, "root")
    a.b("Pommel", (-0.8, 10.4, -1.7), (0.8, 11.1, -1.1), LEATHER, "root")
    a.b("PommelPlate", (-0.55, 10.5, -1.82), (0.55, 11.0, -1.7), STEEL, "root")
    a.b("PommelGem", (-0.15, 10.65, -1.9), (0.15, 10.85, -1.82), GOLD, "root")
    a.b("Bedroll", (-1.9, 10.0, 1.6), (1.9, 11.0, 2.6), ROLL, "root")
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.9, 2.0)
        a.b("BedrollEnd" + side, (x0, 10.1, 1.7), (x1, 10.9, 2.5), ROLL_END, "root")
        x0, x1 = X(sx, 2.0, 2.05)
        a.b("BedrollCurl" + side, (x0, 10.35, 1.95), (x1, 10.65, 2.25), ROLL, "root")
        x0, x1 = X(sx, 0.9, 1.15)
        a.b("BedrollStrap" + side, (x0, 9.95, 1.55), (x1, 11.05, 2.65), LEATHER_DARK, "root")
    a.b("ChestStrap", (-1.8, 8.6, -3.72), (1.8, 8.95, -3.6), LEATHER_DARK, "root")
    a.b("Pouch", (-1.4, 7.5, -3.95), (-0.1, 8.6, -3.6), TAN, "root")
    a.b("PouchFlap", (-1.45, 8.1, -4.02), (-0.05, 8.65, -3.9), LEATHER, "root")
    a.b("PouchClasp", (-0.85, 8.0, -4.08), (-0.6, 8.25, -3.95), GOLD, "root")

    # ---- neck rising forward, a leather collar at its base, a big head with a crest swept back
    head = a.bone("neck", "root", (0, 9.6, -2.6))
    a.b("Neck", (-1.15, 9.2, -3.7), (1.15, 12.6, -1.5), YELLOW, head)
    a.b("NeckFluff", (-0.95, 9.4, -3.9), (0.95, 12.2, -3.7), FLUFF, head)
    a.b("NeckUpper", (-1.0, 12.4, -4.3), (1.0, 15.4, -2.3), YELLOW, head)
    a.b("NeckUpperFluff", (-0.8, 12.4, -4.5), (0.8, 14.6, -4.3), FLUFF, head)
    a.b("Collar", (-1.25, 11.0, -3.8), (1.25, 11.4, -1.4), LEATHER_DARK, head)
    a.b("CollarTag", (-0.2, 10.5, -3.95), (0.2, 11.0, -3.8), STEEL, head)
    a.b("Head", (-1.4, 15.0, -5.4), (1.4, 17.6, -2.4), YELLOW, head)
    a.b("Cheek", (-1.2, 14.7, -4.6), (1.2, 15.0, -2.6), FLUFF, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.4, 16.0, 17.0, -4.7, -3.7, head)
        x0, x1 = X(sx, 0.9, 1.45)
        a.b("Brow" + side, (x0, 17.0, -4.9), (x1, 17.3, -3.5), FEATHER, head)
    # the crest: tufts swept up and back off the top and back of the head
    for i, (x, z, ln) in enumerate(((-0.6, -3.8, 1.1), (0.6, -3.8, 1.1), (0.0, -3.2, 1.5), (-0.7, -2.7, 1.2), (0.7, -2.7, 1.2))):
        a.pyr(f"Crest{i}", (x - 0.4, 17.6, z - 0.4), (x + 0.4, 17.6, z + 0.4), "+y", ln, YELLOW, head)
    for i, (x, y, ln) in enumerate(((-0.7, 16.9, 1.6), (0.7, 16.9, 1.6), (0.0, 17.0, 2.0), (-0.5, 15.9, 1.2), (0.5, 15.9, 1.2))):
        a.pyr(f"CrestBack{i}", (x - 0.35, y - 0.35, -2.4), (x + 0.35, y + 0.35, -2.4), "+z", ln, FEATHER if i == 2 else YELLOW, head)
    # the beak: a big orange top with a hooked tip, a darker lower beak, nostrils
    a.b("Beak", (-1.0, 15.6, -7.0), (1.0, 16.8, -5.4), BEAK, head)
    a.b("BeakHook", (-0.8, 15.2, -7.4), (0.8, 16.4, -7.0), BEAK, head)
    a.b("BeakLow", (-0.85, 15.0, -6.6), (0.85, 15.6, -5.4), BEAK_LOW, head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.3, 0.6)
        a.b("Nostril" + side, (x0, 16.8, -6.6), (x1, 16.88, -6.3), BEAK_LOW, head)
    # the bridle: a noseband round the beak, a band round the head behind the eyes, a
    # strap over the top, steel rings at the corners, reins stepping down to the pommel
    a.b("Noseband", (-1.08, 15.5, -6.1), (1.08, 16.9, -5.8), LEATHER, head)
    a.b("Headband", (-1.48, 14.95, -3.55), (1.48, 17.68, -3.3), LEATHER, head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.4, 1.5)
        a.b("CheekStrap" + side, (x0, 15.6, -5.8), (x1, 15.9, -3.55), LEATHER, head)
        x0, x1 = X(sx, 1.42, 1.58)
        a.b("Ring" + side, (x0, 15.45, -5.95), (x1, 16.05, -5.55), STEEL, head)
        # the rein: steps from the ring down and back to the saddle's pommel
        steps = 6
        for k in range(steps):
            t0, t1 = k / steps, (k + 1) / steps
            y0, y1 = 15.6 - 4.8 * t1, 15.6 - 4.8 * t0
            z0 = -5.6 + 3.9 * t0
            xr = sx * (1.5 - 0.7 * t0)
            a.b(f"Rein{side}{k}", (xr - 0.08, y0, z0), (xr + 0.08, y1, z0 + 0.7), LEATHER_DARK, head)
    a.b("Pendant", (-0.06, 14.0, -4.62), (0.06, 15.0, -4.5), LEATHER_DARK, head)
    a.b("Crystal", (-0.22, 13.2, -4.75), (0.22, 14.0, -4.4), CRYSTAL, head)
    a.pyr("CrystalTip", (-0.22, 13.2, -4.75), (0.22, 13.2, -4.4), "-y", 0.4, CRYSTAL, head)
    a.meta = {"seat": (0, 10.4, 0), "neck_loop": {"center": (0, 13.6, -3.3), "radius": 1.6}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(chocobo)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Chocobo.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Pupil", "Claw", "Crystal", "Nostril", "Buckle", "Ring", "Rein", "Pendant", "PommelGem",
                              "SkirtBoss", "PouchClasp", "ShinRivet", "BedrollCurl", "CollarTag", "Crest", "TailTip", "ChestTuft", "ThighTuft")):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 8, -21), (-30, 4, 0), (19, 12, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Chocobo", "side", "back"], 22).save(os.path.join(out, "Chocobo.png"))
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-34, 14, -34), target=(0, 8, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Horse", "Chocobo"], 22).save(os.path.join(out, "Chocobo_vs_horse.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
