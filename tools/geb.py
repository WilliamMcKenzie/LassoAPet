"""Geb (World 2, Ancient Tomb, Legendary): the green earth god and archer of the Tomb of the
Ancients, our own block take. A centaur: the god's green upper body rises from the front of a
great earthen bull (Geb is "the Bull of Nut"), and the rider sits on the bull's back behind him.

The god: green skin with glowing green life veins, a gold-and-green striped nemes headdress
with a gold goose on top (Geb's sacred bird), glowing gold eyes lined in black, a striped
false beard, a broad gold/lapis/turquoise collar, stone pauldrons with rock spikes and moss,
gold arm cuffs, and a big gold recurve bow drawn back with a glowing green string and a
burning fire arrow nocked.
The bull: green-brown earth with stone plates on the flanks split by glowing green cracks,
a moss back sprouting papyrus and pink lotus at the rump, rock spikes on the shoulders,
gold-banded legs with dark hooves capped in gold, a gold saddle with lapis/turquoise
striped drapes and a winged scarab on each side, red bombs with glowing fuses hanging
behind the saddle, a quiver of fire arrows on the right flank, and a papyrus-tufted tail.
Three fireballs and two green Nile ankh artifacts float around him.

    python3 tools/geb.py

writes designs/tomb/Geb.bbmodel (convert without --zyx), the preview
/mnt/project-files/world2/tomb/renders/Geb.png, a four-view sheet and an animation gif
(--still skips the gif). Every tilted part is built already turned (rests baked into the
parts, every bone at 0).
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz, render  # noqa: E402
from snow_designs import pyramid  # noqa: E402

NAME = "Geb"
SKIN = (92, 184, 84)
SKIN_DK = (60, 140, 66)
EARTH = (118, 150, 70)
EARTH_DK = (84, 112, 54)
SOIL = (122, 86, 52)
STONE = (168, 156, 132)
STONE_DK = (128, 118, 100)
MOSS = (136, 206, 68)
SAND = (220, 201, 152)  # #DCC998
SAND_DK = (208, 184, 134)  # #D0B886
GOLD = (255, 196, 52)
LAPIS = (42, 86, 210)
TURQ = (40, 204, 196)
RED = (222, 46, 40)
BOMB = (200, 36, 36)
HOOF = (58, 44, 36)
DARK = (28, 24, 26)
WHITE = (250, 248, 240)
PINK = (255, 132, 182)
ORANGE = (255, 150, 40)
LIFE = (110, 255, 90)
FIRE = (255, 110, 20)
FIRE_CORE = (255, 226, 90)
EYE = (255, 214, 60)


def frame(p0, p1):
    """A 4x4 transform at the midpoint of p0-p1 whose local y runs from p0 to p1."""
    p0, p1 = np.array(p0, float), np.array(p1, float)
    y = p1 - p0
    n = np.linalg.norm(y)
    y /= n
    ref = np.array([0, 0, 1.0]) if abs(y[2]) < 0.9 else np.array([1.0, 0, 0])
    x = np.cross(y, ref)
    x /= np.linalg.norm(x)
    z = np.cross(x, y)
    M = np.eye(4)
    M[:3, 0], M[:3, 1], M[:3, 2] = x, y, z
    M[:3, 3] = (p0 + p1) / 2
    return M, n


def geb():
    a = A.Animal(NAME, "Legendary")
    a.bone_order = [("root", None), ("neck", "root"), ("Head", "neck"), ("ArmL", "neck"), ("ArmR", "neck"),
                    ("Tail", "root")]
    a.bone_order += [("Leg" + leg, "root") for leg in A.LEGS]

    def rbox(name, size, M, color, bone):
        p = Part(name, size, M, color)
        p.bone = bone
        a.parts.append(p)
        return p

    def seg(name, p0, p1, w, d, color, bone, extra=0.0):
        """Block from p0 to p1 (w across, d deep), `extra` added to its length to close joints."""
        M, n = frame(p0, p1)
        return rbox(name, (w, n + extra, d), M, color, bone)

    def rpyr(name, M, w, d, h, color, bone):
        """Square pyramid, base w x d on local y = 0, tip at local (0, h, 0), placed by M."""
        base = [(-w / 2, 0, -d / 2), (w / 2, 0, -d / 2), (w / 2, 0, d / 2), (-w / 2, 0, d / 2)]
        pts = [(M @ np.array([*v, 1.0]))[:3] for v in base]
        tip = (M @ np.array([0, h, 0, 1.0]))[:3]
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
        p.polys = [np.array(pts)] + [np.array([pts[i], pts[(i + 1) % 4], tip]) for i in range(4)]
        p.bone = bone
        a.parts.append(p)
        return p

    def glow(name, lo, hi, color, bone):
        return a.box("Glow" + name, lo, hi, color, bone)

    # ================================================================ the bull (root)
    a.body(2.0, 3.6, 6.8, -4.2, 4.2, EARTH)
    a.box("Belly", (-1.8, 3.3, -3.4), (1.8, 3.6, 3.2), EARTH_DK, "root")
    a.box("Brisket", (-2.15, 3.4, -4.6), (2.15, 6.6, -3.4), EARTH_DK, "root")
    a.box("Rump", (-2.1, 4.0, 3.6), (2.1, 6.9, 4.5), EARTH_DK, "root")
    # gold breastplate on the brisket with a glowing green scarab, stone plates at its corners
    a.box("Breastplate", (-1.5, 4.3, -4.7), (1.5, 6.2, -4.6), GOLD, "root")
    for k, (y0, y1, c) in enumerate(((5.85, 6.05, LAPIS), (4.45, 4.65, LAPIS), (4.65, 4.8, TURQ))):
        a.box(f"BreastStripe{k + 1}", (-1.5, y0, -4.75), (1.5, y1, -4.7), c, "root")
    for k, x in enumerate((-1.1, -0.55, 0.55, 1.1)):
        pyramid(a, f"BreastTooth{k + 1}", (x - 0.2, 4.3, -4.7), (x + 0.2, 4.3, -4.6), "-y", 0.4, GOLD, "root")
    glow("BreastScarab", (-0.35, 4.95, -4.82), (0.35, 5.7, -4.7), LIFE, "root")
    glow("BreastScarabHead", (-0.2, 5.7, -4.8), (0.2, 5.85, -4.7), LIFE, "root")
    for side, sx in (("L", -1), ("R", 1)):
        wa, wb = sorted((sx * 0.35, sx * 1.25))
        a.box("BreastWing" + side, (wa, 5.2, -4.8), (wb, 5.55, -4.7), TURQ, "root")
        ta, tb = sorted((sx * 0.35, sx * 0.95))
        a.box("BreastWingTip" + side, (ta, 5.0, -4.8), (tb, 5.2, -4.7), LAPIS, "root")
        ca, cb = sorted((sx * 1.6, sx * 2.2))
        a.box("BrisketStone" + side, (ca, 3.4, -4.75), (cb, 4.6, -4.4), STONE, "root")
        pyramid(a, "BrisketSpike" + side, (ca + 0.05, 3.55, -4.75), (cb - 0.05, 4.45, -4.75), "-z", 0.6, STONE_DK, "root")
    # gold trim running along the bottom edge of the body, and a sand band above it
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 2.0, sx * 2.12))
        a.box("Trim" + side, (xs[0], 3.55, -3.4), (xs[1], 3.85, 3.6), GOLD, "root")
        a.box("Band" + side, (xs[0], 3.85, -3.4), (xs[1], 4.05, 3.6), SAND, "root")
        for k, z in enumerate((-2.6, -1.2, 0.2, 1.6, 3.0)):
            a.box(f"TrimStud{side}{k + 1}", (xs[0] - sx * 0.06 if sx < 0 else xs[0], 3.6, z - 0.2),
                  (xs[1] if sx < 0 else xs[1] + 0.06, 3.8, z + 0.2), LAPIS, "root")
    # stone plates on the flanks, split by glowing green life cracks
    for side, sx in (("L", -1), ("R", 1)):
        xo = sorted((sx * 2.0, sx * 2.2))
        xc = sorted((sx * 2.0, sx * 2.24))
        a.box("PlateFore" + side, (xo[0], 4.3, -3.2), (xo[1], 6.2, -1.6), STONE, "root")
        a.box("PlateMid" + side, (xo[0], 4.1, 2.0), (xo[1], 5.9, 3.5), STONE_DK, "root")
        a.box("PlateHind" + side, (xo[0], 5.2, 3.5), (xo[1], 6.6, 4.3), STONE, "root")
        glow("Crack" + side + "1", (xc[0], 4.5, -1.6), (xc[1], 4.7, -0.9), LIFE, "root")
        glow("Crack" + side + "2", (xc[0], 4.7, -1.1), (xc[1], 5.5, -0.9), LIFE, "root")
        glow("Crack" + side + "3", (xc[0], 5.5, -1.1), (xc[1], 5.7, -0.4), LIFE, "root")
        glow("Crack" + side + "4", (xc[0], 4.1, 1.7), (xc[1], 5.2, 1.95), LIFE, "root")
        glow("Crack" + side + "5", (xc[0], 5.9, 2.6), (xc[1], 6.1, 3.5), LIFE, "root")
        # rock spikes on the shoulders
        for k, (y0, z0, ln) in enumerate(((6.0, -3.9, 1.0), (6.3, -3.0, 1.3), (5.7, -2.1, 0.8))):
            x = sx * 2.15
            pyramid(a, f"ShoulderSpike{side}{k + 1}", (x, y0 - 0.45, z0 - 0.45), (x, y0 + 0.45, z0 + 0.45),
                    "+x" if sx > 0 else "-x", ln, STONE_DK, "root")

    # ---- legs: thick pillars, stone knees, gold bands, dark hooves capped in gold
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        z0 = -3.9 if front else 2.5
        z1 = z0 + 1.5
        xa, xb = sorted((sx * 0.45, sx * 1.95))
        bone = "Leg" + leg
        a.box(bone, (xa, 1.2, z0), (xb, 3.7, z1), EARTH, bone)
        a.box("Knee" + leg, (xa - 0.08, 2.3, z0 - 0.12), (xb + 0.08, 2.9, z0 + 0.6), STONE, bone)
        a.box("LegBand" + leg, (xa - 0.08, 1.45, z0 - 0.08), (xb + 0.08, 1.75, z1 + 0.08), GOLD, bone)
        a.box("LegBandLapis" + leg, (xa - 0.06, 1.75, z0 - 0.06), (xb + 0.06, 1.9, z1 + 0.06), LAPIS, bone)
        a.box("Hoof" + leg, (xa - 0.05, 0.3, z0 - 0.2), (xb + 0.05, 1.2, z1 + 0.05), HOOF, bone)
        a.box("HoofCap" + leg, (xa - 0.1, 0, z0 - 0.3), (xb + 0.1, 0.3, z1 + 0.1), GOLD, bone)
        xm = (xa + xb) / 2
        a.box("PlainHoofSplit" + leg, (xm - 0.06, 0.3, z0 - 0.24), (xm + 0.06, 1.15, z0 - 0.18), DARK, bone)
        a.pivots[bone] = (xm, 3.675, z1 - 0.05 if front else z0 + 0.05)

    # ---- moss back with papyrus and lotus at the rump
    a.box("MossBack", (-1.9, 6.8, -1.2), (1.9, 6.95, 4.3), MOSS, "root")
    a.box("MossRump", (-2.0, 6.9, 3.4), (2.0, 7.3, 4.4), MOSS, "root")
    for k, (x, z, h, tilt) in enumerate(((-1.4, 3.8, 2.0, -14), (-0.9, 4.15, 2.6, -4), (1.3, 3.9, 2.2, 12))):
        M = T(x, 7.3, z) @ Rz(-tilt) @ Rx(10)
        rbox(f"Papyrus{k + 1}", (0.16, h, 0.16), M @ T(0, h / 2, 0), SKIN_DK, "root")
        top = M @ T(0, h, 0)
        rpyr(f"PapyrusFan{k + 1}", top @ Rx(180) @ T(0, -0.9, 0), 0.9, 0.9, 0.9, MOSS, "root")
    for k, (x, z) in enumerate(((0.5, 3.8), (-1.7, 3.0))):
        a.box(f"LotusPad{k + 1}", (x - 0.45, 7.3, z - 0.45), (x + 0.45, 7.4, z + 0.45), SKIN_DK, "root")
        for j, (dx, dz) in enumerate(((-0.18, 0), (0.18, 0), (0, -0.18), (0, 0.18))):
            rpyr(f"Lotus{k + 1}{j + 1}", T(x + dx, 7.4, z + dz) @ Rx(dz * 120) @ Rz(-dx * 120), 0.3, 0.3, 0.6, PINK, "root")
        a.box(f"LotusHeart{k + 1}", (x - 0.1, 7.4, z - 0.1), (x + 0.1, 7.6, z + 0.1), GOLD, "root")

    # ---- gold saddle (the seat), lapis/turquoise drapes with a winged scarab on each side
    a.box("Saddle", (-1.7, 6.95, -0.6), (1.7, 7.2, 2.6), SAND, "root")
    a.box("SaddleTrimF", (-1.75, 6.9, -0.75), (1.75, 7.45, -0.55), GOLD, "root")
    a.box("SaddleCantle", (-1.6, 6.9, 2.55), (1.6, 7.75, 2.85), GOLD, "root")
    a.box("SaddleCantleGem", (-0.3, 7.25, 2.85), (0.3, 7.6, 2.92), TURQ, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 2.0, sx * 2.14))
        for k, (y0, y1, c) in enumerate(((6.5, 6.95, LAPIS), (6.05, 6.5, TURQ), (5.6, 6.05, LAPIS), (5.2, 5.6, TURQ))):
            a.box(f"Drape{side}{k + 1}", (xs[0], y0, -0.4), (xs[1], y1, 2.4), c, "root")
        xh = sorted((sx * 2.0, sx * 2.18))
        a.box("Hem" + side, (xh[0], 4.95, -0.45), (xh[1], 5.2, 2.45), GOLD, "root")
        for k, z in enumerate((-0.2, 0.5, 1.3, 2.1)):
            pyramid(a, f"HemTooth{side}{k + 1}", (xh[0], 4.95, z - 0.17), (xh[1], 4.95, z + 0.17), "-y", 0.35, GOLD, "root")
        # winged scarab emblem
        xe = sorted((sx * 2.14, sx * 2.26))
        a.box("Scarab" + side, (xe[0], 5.55, 0.65), (xe[1], 6.45, 1.35), GOLD, "root")
        a.box("ScarabHead" + side, (xe[0], 6.45, 0.8), (xe[1], 6.65, 1.2), GOLD, "root")
        glow("ScarabSun" + side, (xe[0] + (0.0 if sx > 0 else -0.04), 6.65, 0.85), (xe[1] + (0.04 if sx > 0 else 0.0), 6.85, 1.15), ORANGE, "root")
        for wk, (z0, z1, c) in enumerate(((-0.25, 0.65, TURQ), (1.35, 2.25, TURQ))):
            a.box(f"ScarabWing{side}{wk + 1}", (xe[0], 5.95, z0), (xe[1], 6.35, z1), c, "root")
            a.box(f"ScarabWingTip{side}{wk + 1}", (xe[0], 5.75, z0 + (0 if wk else 0.4)), (xe[1], 5.95, z1 - (0.4 if wk else 0)), LAPIS, "root")

    # ---- red bombs with glowing fuses hanging behind the saddle
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 2.1, sx * 2.25))
        a.box("BombStrap" + side, (xs[0], 5.3, 2.75), (xs[1], 6.9, 2.95), SOIL, "root")
        for k, (dz, dy) in enumerate(((-0.2, 0), (0.55, -0.35))):
            x0, x1 = sorted((sx * 2.25, sx * 3.05))
            z = 3.0 + dz
            y = 4.6 + dy
            a.box(f"Bomb{side}{k + 1}", (x0, y, z - 0.4), (x1, y + 0.8, z + 0.4), BOMB, "root")
            a.box(f"BombBand{side}{k + 1}", (x0 - 0.03, y + 0.3, z - 0.43), (x1 + 0.03, y + 0.5, z + 0.43), DARK, "root")
            xm = (x0 + x1) / 2
            a.box(f"BombCap{side}{k + 1}", (xm - 0.2, y + 0.8, z - 0.2), (xm + 0.2, y + 0.95, z + 0.2), GOLD, "root")
            glow(f"Fuse{side}{k + 1}", (xm - 0.07, y + 0.95, z - 0.07), (xm + 0.07, y + 1.3, z + 0.07), FIRE_CORE, "root")

    # ---- quiver of fire arrows slung on the right flank, angled back
    Q = T(2.35, 5.2, -0.9) @ Rx(-35)
    rbox("Quiver", (0.6, 2.2, 0.6), Q, SAND_DK, "root")
    rbox("QuiverBandTop", (0.66, 0.2, 0.66), Q @ T(0, 0.85, 0), GOLD, "root")
    rbox("QuiverBandBot", (0.66, 0.2, 0.66), Q @ T(0, -0.85, 0), GOLD, "root")
    rbox("QuiverGem", (0.08, 0.35, 0.35), Q @ T(0.33, 0, 0), LAPIS, "root")
    for k, (dx, dz) in enumerate(((-0.12, -0.12), (0.12, 0.05), (-0.05, 0.15))):
        rbox(f"QuiverArrow{k + 1}", (0.08, 0.6, 0.08), Q @ T(dx, 1.4, dz), SAND, "root")
        rpyr(f"GlowQuiverTip{k + 1}", Q @ T(dx, 1.7, dz), 0.22, 0.22, 0.4, FIRE, "root")

    # ---- tail with a papyrus tuft
    a.pivots["Tail"] = (0, 6.4, 4.5)
    seg("Tail", (0, 6.4, 4.45), (0, 4.2, 5.2), 0.32, 0.32, EARTH_DK, "Tail", 0.2)
    seg("TailBand", (0, 4.6, 5.05), (0, 4.35, 5.14), 0.42, 0.42, GOLD, "Tail")
    rpyr("TailTuft", T(0, 4.3, 5.18) @ Rx(180 - 18), 0.6, 0.6, 1.1, MOSS, "Tail")

    # ================================================================ the god (neck = waist)
    a.pivots["neck"] = (0, 6.8, -2.6)
    # kilt (shendyt) with gold belt and an apron flap
    a.box("Kilt", (-1.65, 6.2, -3.8), (1.65, 7.5, -1.4), WHITE, "neck")
    a.box("Belt", (-1.7, 7.3, -3.85), (1.7, 7.7, -1.35), GOLD, "neck")
    a.box("BeltGemL", (-1.0, 7.38, -3.92), (-0.6, 7.62, -3.85), TURQ, "neck")
    a.box("BeltGemR", (0.6, 7.38, -3.92), (1.0, 7.62, -3.85), TURQ, "neck")
    a.box("Buckle", (-0.35, 7.25, -3.95), (0.35, 7.75, -3.85), GOLD, "neck")
    glow("Buckle", (-0.18, 7.38, -3.99), (0.18, 7.62, -3.95), LIFE, "neck")
    a.box("Apron", (-0.6, 6.1, -3.9), (0.6, 7.3, -3.8), GOLD, "neck")
    for k, y in enumerate((6.35, 6.75)):
        a.box(f"ApronStripe{k + 1}", (-0.6, y, -3.95), (0.6, y + 0.15, -3.9), LAPIS, "neck")
    # torso
    a.box("Waist", (-1.3, 7.7, -3.5), (1.3, 8.6, -1.7), SKIN, "neck")
    a.box("Chest", (-1.6, 8.6, -3.7), (1.6, 10.3, -1.5), SKIN, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.08, sx * 1.4))
        a.box("Pec" + side, (xa, 8.9, -3.82), (xb, 9.6, -3.7), SKIN_DK, "neck")
    for k, y in enumerate((7.85, 8.25)):
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * 0.08, sx * 0.7))
            a.box(f"Abs{side}{k + 1}", (xa, y, -3.6), (xb, y + 0.3, -3.5), SKIN_DK, "neck")
    # glowing life veins up the sides of the chest
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 1.6, sx * 1.66))
        glow("Vein" + side + "1", (xs[0], 8.0, -2.8), (xs[1], 9.6, -2.6), LIFE, "neck")
        glow("Vein" + side + "2", (xs[0], 9.4, -2.6), (xs[1], 9.6, -2.0), LIFE, "neck")
    # broad collar (usekh): gold, lapis, turquoise, gold, front and back
    for k, (y0, y1, c) in enumerate(((10.0, 10.3, GOLD), (9.75, 10.0, LAPIS), (9.5, 9.75, TURQ), (9.3, 9.5, GOLD))):
        w = 1.2 - 0.12 * k
        a.box(f"Collar{k + 1}", (-w, y0, -3.82), (w, y1, -3.7), c, "neck")
        a.box(f"CollarBack{k + 1}", (-w, y0, -1.5), (w, y1, -1.38), c, "neck")
    a.box("CollarTop", (-1.62, 10.3, -3.82), (1.62, 10.42, -1.38), GOLD, "neck")
    for k, x in enumerate((-0.7, 0, 0.7)):
        a.box(f"CollarDrop{k + 1}", (x - 0.12, 9.05, -3.86), (x + 0.12, 9.3, -3.8), GOLD, "neck")
    # stone pauldrons with moss and rock spikes
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.3, sx * 2.55))
        a.box("Pauldron" + side, (xa, 9.6, -3.4), (xb, 10.5, -1.8), STONE, "neck")
        a.box("PauldronRim" + side, (xa - 0.05, 9.45, -3.45), (xb + 0.05, 9.65, -1.75), GOLD, "neck")
        a.box("PauldronMoss" + side, (xa + 0.1, 10.5, -3.3), (xb - 0.1, 10.65, -1.9), MOSS, "neck")
        for k, (z, ln) in enumerate(((-3.0, 0.9), (-2.2, 1.2))):
            xc = sx * 1.95
            pyramid(a, f"PauldronSpike{side}{k + 1}", (xc - 0.3, 10.65, z - 0.3), (xc + 0.3, 10.65, z + 0.3), "+y", ln, STONE_DK, "neck")

    # ---- head
    a.pivots["Head"] = (0, 10.4, -2.6)
    a.box("Neck", (-0.55, 10.3, -3.0), (0.55, 10.8, -2.1), SKIN, "Head")
    a.box("Face", (-0.9, 10.75, -3.55), (0.9, 12.45, -1.75), SKIN, "Head")
    a.box("Nose", (-0.17, 11.2, -3.75), (0.17, 11.7, -3.55), SKIN_DK, "Head")
    a.box("PlainMouth", (-0.35, 10.98, -3.58), (0.35, 11.06, -3.55), DARK, "Head")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.18, sx * 0.72))
        e = glow("Eye" + side, (xa, 11.75, -3.6), (xb, 12.0, -3.55), EYE, "Head")
        e.plain = True
        c = sx * 0.42
        a.box("PlainPupil" + side, (c - 0.08, 11.78, -3.63), (c + 0.08, 11.97, -3.6), DARK, "Head")
        # kohl liner flicking out past the eye (the Eye of Horus line)
        la, lb = sorted((sx * 0.15, sx * 0.86))
        a.box("PlainLiner" + side, (la, 12.0, -3.62), (lb, 12.08, -3.55), DARK, "Head")
        ta, tb = sorted((sx * 0.72, sx * 0.92))
        a.box("PlainLinerTail" + side, (ta, 11.82, -3.62), (tb, 11.92, -3.5), DARK, "Head")
        ba, bb = sorted((sx * 0.15, sx * 0.8))
        a.box("Brow" + side, (ba, 12.12, -3.66), (bb, 12.28, -3.55), SKIN_DK, "Head")
        # earth-god face paint: a glowing green line down each cheek
        ga, gb = sorted((sx * 0.38, sx * 0.48))
        glow("Cheek" + side, (ga, 11.15, -3.6), (gb, 11.65, -3.55), LIFE, "Head").plain = True
    # false beard: striped gold and lapis
    for k, (y0, y1, c) in enumerate(((10.65, 10.9, GOLD), (10.4, 10.65, LAPIS), (10.15, 10.4, GOLD), (9.95, 10.15, LAPIS))):
        a.box(f"Beard{k + 1}", (-0.25, y0, -3.75), (0.25, y1, -3.35), c, "Head")
    a.box("BeardTip", (-0.3, 9.85, -3.8), (0.3, 9.95, -3.3), GOLD, "Head")
    # nemes headdress, gold and green stripes
    a.box("Nemes", (-1.05, 12.3, -3.65), (1.05, 12.95, -1.6), GOLD, "Head")
    a.box("NemesBand", (-1.07, 12.25, -3.7), (1.07, 12.45, -1.58), LAPIS, "Head")
    for k, x in enumerate((-0.75, -0.25, 0.25, 0.75)):
        a.box(f"NemesStripe{k + 1}", (x - 0.12, 12.95, -3.65), (x + 0.12, 13.0, -1.6), SKIN_DK, "Head")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.9, sx * 1.12))
        a.box("NemesSide" + side, (xa, 10.9, -3.3), (xb, 12.3, -1.6), GOLD, "Head")
        # lappets falling in front of the shoulders, striped
        la, lb = sorted((sx * 0.92, sx * 1.4))
        for k in range(5):
            y1 = 11.2 - 0.32 * k
            a.box(f"Lappet{side}{k + 1}", (la, y1 - 0.32, -3.4), (lb, y1, -3.0), GOLD if k % 2 == 0 else SKIN_DK, "Head")
    for k in range(4):
        y1 = 12.3 - 0.4 * k
        a.box(f"NemesTail{k + 1}", (-0.75, y1 - 0.4, -1.6), (0.75, y1, -1.3), GOLD if k % 2 == 0 else SKIN_DK, "Head")
    # gold goose on top (Geb's sacred bird), with a glowing sun disc behind it
    a.box("GooseBody", (-0.4, 13.0, -2.9), (0.4, 13.6, -1.9), GOLD, "Head")
    a.wedge("GooseTail", (-0.35, 13.2, -1.9), (0.35, 13.75, -1.5), GOLD, "Head", "up_back")
    a.box("GooseNeck", (-0.15, 13.6, -3.0), (0.15, 14.5, -2.7), GOLD, "Head")
    a.box("GooseHead", (-0.2, 14.4, -3.15), (0.2, 14.75, -2.65), GOLD, "Head")
    a.box("GooseBeak", (-0.1, 14.45, -3.5), (0.1, 14.6, -3.15), ORANGE, "Head")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.2, sx * 0.23))
        a.box("PlainGooseEye" + side, (xa, 14.55, -3.05), (xb, 14.65, -2.95), DARK, "Head")
        wa, wb = sorted((sx * 0.4, sx * 0.48))
        a.box("GooseWing" + side, (wa, 13.1, -2.7), (wb, 13.5, -1.85), SAND, "Head")
    glow("SunDisc", (-0.55, 13.6, -1.75), (0.55, 14.7, -1.6), ORANGE, "Head")

    # ---- arms: the left holds the bow out front, the right draws the string to the cheek
    shL, shR = np.array([-1.95, 9.8, -2.6]), np.array([1.95, 9.8, -2.6])
    elL, haL = np.array([-1.9, 9.9, -4.3]), np.array([-1.15, 10.0, -5.6])
    elR, haR = np.array([2.75, 10.5, -1.4]), np.array([0.95, 10.55, -3.85])
    a.pivots["ArmL"], a.pivots["ArmR"] = tuple(shL), tuple(shR)
    for side, sh, el, ha in (("L", shL, elL, haL), ("R", shR, elR, haR)):
        bone = "Arm" + side
        seg("UpperArm" + side, sh, el, 0.8, 0.8, SKIN, bone, 0.6)
        seg("ArmBand" + side, sh + (el - sh) * 0.45, sh + (el - sh) * 0.62, 0.9, 0.9, GOLD, bone)
        seg("Forearm" + side, el, ha, 0.72, 0.72, SKIN, bone, 0.5)
        seg("Cuff" + side, el + (ha - el) * 0.55, el + (ha - el) * 0.85, 0.84, 0.84, GOLD, bone)
        seg("CuffGem" + side, el + (ha - el) * 0.64, el + (ha - el) * 0.76, 0.9, 0.5, LAPIS, bone)
        M, _ = frame(el, ha)
        M[:3, 3] = ha
        rbox("Hand" + side, (0.8, 0.7, 0.8), M, SKIN, bone)

    # gold recurve bow in the left hand, limbs bending back toward the god with flicked tips
    gx = haL[0]
    gz = haL[2]
    gy = haL[1]
    rbox("BowGrip", (0.3, 1.0, 0.36), T(gx, gy, gz - 0.15), LAPIS, "ArmL")
    tips = {}
    for half, s in (("Top", 1), ("Bot", -1)):
        pts = [(0.45, 0.0), (1.35, 0.25), (2.25, 0.65), (2.95, 1.05), (3.3, 0.85)]  # (height, pull back toward the god)
        pts = [np.array([gx, gy + s * h, gz - 0.15 + dz]) for h, dz in pts]
        for k in range(len(pts) - 1):
            seg(f"Bow{half}{k + 1}", pts[k], pts[k + 1], 0.24, 0.3, GOLD, "ArmL", 0.12)
        rpyr(f"BowTip{half}", T(*pts[-1]) @ (Rx(-25) if s > 0 else Rx(180 + 25)), 0.26, 0.3, 0.4, LAPIS, "ArmL")
        tips[half] = pts[-2]
    # glowing green bowstring pulled back to the right hand
    for half in ("Top", "Bot"):
        seg("GlowString" + half, tips[half], haR, 0.07, 0.07, LIFE, "ArmR", 0.05)
    # burning arrow nocked: shaft from the draw hand out past the grip
    d = np.array([gx, gy, gz - 0.15]) - haR
    d /= np.linalg.norm(d)
    tip = np.array([gx, gy, gz - 0.15]) + d * 1.1
    seg("ArrowShaft", haR - d * 0.3, tip, 0.12, 0.12, SAND, "ArmR")
    for k, rot in enumerate((0, 90)):
        Mf, _ = frame(haR - d * 0.25, haR + d * 0.35)
        rbox(f"Fletch{k + 1}", (0.38, 0.55, 0.04), Mf @ Ry(rot), RED, "ArmR")
    Mt, _ = frame(tip, tip + d)
    rpyr("GlowArrowHead", Mt @ T(0, -0.5, 0), 0.32, 0.32, 0.7, FIRE_CORE, "ArmR")
    rpyr("GlowArrowFlame", Mt @ T(0, -0.85, 0) @ Rx(180), 0.42, 0.42, 1.1, FIRE, "ArmR")

    # ================================================================ floating things
    for j, (x, y, z) in enumerate(((-3.6, 11.4, -3.6), (3.7, 12.2, -2.2), (-3.4, 8.2, 1.6))):
        bone = f"Fire{j + 1}"
        a.bone_order.append((bone, "root"))
        a.pivots[bone] = (x, y, z)
        rbox(bone.replace("Fire", "GlowFireball"), (0.8, 0.8, 0.8), T(x, y, z) @ Ry(45) @ Rx(35), FIRE_CORE, bone)
        rpyr(bone.replace("Fire", "GlowFireTail"), T(x, y + 0.25, z) @ Rx(-30), 0.75, 0.75, 1.3, FIRE, bone)
    # Nile artifacts: floating green ankhs ringed in gold
    for j, (x, y, z) in enumerate(((3.6, 8.4, 2.4), (-3.9, 13.3, -0.8))):
        bone = f"Ankh{j + 1}"
        a.bone_order.append((bone, "root"))
        a.pivots[bone] = (x, y, z)
        M = T(x, y, z) @ Ry(-35 if x > 0 else 35)
        rbox(f"GlowAnkhStem{j + 1}", (0.24, 1.1, 0.24), M @ T(0, -0.55, 0), LIFE, bone)
        rbox(f"GlowAnkhBar{j + 1}", (1.0, 0.22, 0.24), M @ T(0, 0.05, 0), LIFE, bone)
        for k, (dx, dy, w, h) in enumerate(((-0.25, 0.5, 0.18, 0.7), (0.25, 0.5, 0.18, 0.7), (0, 0.85, 0.5, 0.18))):
            rbox(f"GlowAnkhLoop{j + 1}{k + 1}", (w, h, 0.24), M @ T(dx, dy, 0), LIFE, bone)
        rbox(f"AnkhRing{j + 1}", (0.4, 0.14, 0.32), M @ T(0, -1.1, 0), GOLD, bone)

    a.meta = {"seat": (0, 7.2, 1.2), "neck_loop": {"center": (0, 8.4, -2.6), "radius": 2.1}}
    for p in a.parts:
        p.neon = p.name.startswith("Glow")
    a.animations = animations
    return a


def animations():
    """The Horse's idle, walk and leap gallop for the bull's body and legs, its neck swing
    damped on the god's waist (neck) so he stays upright, his head steadying against it.
    On top: he breathes and keeps the bow drawn, the bow arm swaying with the stride and
    the draw hand pulling back harder the faster he goes; the tail swishes; the fireballs
    and ankhs bob and spin."""
    out = {}
    for name, (L, tracks) in A.quad_animations().items():
        tracks = {b: t for b, t in tracks.items() if b not in ("EarL", "EarR")}
        strong = {"idle": 0.0, "walk": 0.5, "gallop": 1.0}[name]
        cycles = max(1, round(L / 1.2)) if name == "idle" else 1
        n = 16
        wave = lambda k, ph=0.0: float(np.sin(2 * np.pi * (cycles * k / n - ph)))
        ts = [round(L * k / n, 4) for k in range(n + 1)]
        lean = -4 * strong  # leans into the run
        neck = []
        for tr in tracks.get("neck", []):
            if tr["channel"] == "rotation":
                tr = dict(tr, keys=[(t, (lean + 0.35 * r[0], 0.35 * r[1], 0.35 * r[2])) for t, r in tr["keys"]])
            neck.append(tr)
        tracks["neck"] = neck
        tracks["Head"] = [{"channel": "rotation", "interp": "catmullrom",
                           "keys": [(t, (-1.5 * wave(k, 0.1), 3 * wave(k, 0.3) * (1 - strong), 0)) for k, t in enumerate(ts)]}]
        tracks["ArmL"] = [{"channel": "rotation", "interp": "catmullrom",
                           "keys": [(t, ((2 + 3 * strong) * wave(k, 0.2), (1.5 + 2 * strong) * wave(k, 0.45), 0)) for k, t in enumerate(ts)]}]
        tracks["ArmR"] = [{"channel": "rotation", "interp": "catmullrom",
                           "keys": [(t, (-(1 + 4 * strong) - (1 + 2 * strong) * wave(k, 0.2), -(3 * strong) - 1.5 * wave(k, 0.45), 0))
                                    for k, t in enumerate(ts)]}]
        swish = (10 + 10 * strong)
        tail = [tr for tr in tracks.get("Tail", []) if tr["channel"] != "rotation"]
        tail.append({"channel": "rotation", "interp": "catmullrom",
                     "keys": [(t, (-10 * strong + 6 * wave(k, 0.1), 0, swish * wave(k, 0.35))) for k, t in enumerate(ts)]})
        tracks["Tail"] = tail
        for j, bone in enumerate(["Fire1", "Fire2", "Fire3", "Ankh1", "Ankh2"]):
            sign = 1 if j % 2 else -1
            spin = [(round(L * k / 4, 4), (0, sign * 90 * k, 0)) for k in range(5)]
            bob = [(t, (0, (2.5 + strong) * float(np.sin(2 * np.pi * (k / n + 0.2 * j))), 0)) for k, t in enumerate(ts)]
            tracks[bone] = [{"channel": "rotation", "interp": "linear", "keys": spin},
                            {"channel": "position", "interp": "catmullrom", "keys": bob}]
        out[name] = (L, tracks)
    return out


SHOT = "/mnt/project-files/world2/tomb/renders"
BG = (240, 240, 236)


def shot(parts, **cam):
    im = render(parts, transparent=True, **cam)
    out = Image.new("RGB", im.size, BG)
    out.paste(im, (0, 0), im)
    return out


def main(out=os.path.join(A.ROOT, "designs", "tomb")):
    os.makedirs(out, exist_ok=True)
    os.makedirs(SHOT, exist_ok=True)
    a = geb()
    model = A.build_animal(a, out)
    print(f"{NAME}: {len(a.parts)} parts")
    shot(a.parts, eye=(-22, 15, -21), target=(0, 7.6, -0.4), W=900, H=900, fov=42).save(os.path.join(SHOT, NAME + ".png"))
    views = [dict(eye=(-21, 14, -23), target=(0, 7.4, 0)), dict(eye=(-30, 9, 0), target=(0, 7.4, 0)),
             dict(eye=(19, 15, 23), target=(0, 7.4, 0)), dict(eye=(0, 10, -28), target=(0, 7.4, 0))]
    sheet = Image.new("RGB", (1000, 1000))
    for i, cam in enumerate(views):
        sheet.paste(shot(a.parts, W=500, H=500, fov=42, **cam), ((i % 2) * 500, (i // 2) * 500))
    sheet.save(os.path.join(os.path.dirname(SHOT), "Geb_views.png"))
    if "--still" in sys.argv:
        return
    frames = []
    cams = [dict(eye=(-30, 9, -2), target=(0, 7.4, 0)), dict(eye=(-22, 15, -21), target=(0, 7.6, -0.4))]
    for name, nf in (("idle", 24), ("walk", 20), ("gallop", 16)):
        anim = A.anim_named(model, name)
        for k in range(nf):
            ps = pose(model, anim, k / nf * anim["length"])
            for p in ps:
                p.neon = p.name.startswith("Glow")
            im = Image.new("RGB", (800, 400))
            for c, cam in enumerate(cams):
                im.paste(shot(ps, W=400, H=400, fov=44, **cam), (400 * c, 0))
            frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    A.gif(os.path.join(os.path.dirname(SHOT), "Geb_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[x for x in sys.argv[1:] if not x.startswith("--")])
