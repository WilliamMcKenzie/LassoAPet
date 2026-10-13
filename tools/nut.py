"""Nut (World 2, Ancient Tomb, Legendary): the sky goddess, after the Tomb of the Ancients
healer boss. She flies flat out like a diving bird, so the rider sits on a gold-trimmed
saddle between her shoulder blades. A white pleated linen robe trailing behind in three
flowing sections, a gold and turquoise usekh collar, a lapis Egyptian wig banded in gold,
a gold diadem with a night-sky orb on top, kohl-lined googly eyes. Her arms reach forward,
each hand carrying a glowing star. Two huge Isis wings (gold arm bars, royal blue and
turquoise coverts, long night-blue flight feathers sprinkled with glowing stars, gold tips),
two lapis sashes streaming from her belt and four little stars orbiting her.

    python3 tools/nut.py

writes designs/tomb/Nut.bbmodel (model and bones only so far, no animations) and the
preview /mnt/project-files/world2/tomb/renders/Nut.png. Every rest is baked into the
parts; every bone sits at 0.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz, render, write_bbmodel  # noqa: E402
from snow_designs import pyramid  # noqa: E402

NAME = "Nut"
WHITE = (252, 250, 244)
PLEAT = (232, 224, 204)
SKIN = (92, 150, 255)       # sky-blue goddess skin
SKIN_DK = (64, 116, 226)
HAIR = (34, 44, 120)        # lapis wig
GOLD = (255, 196, 40)
GOLD_DK = (222, 150, 24)
TURQ = (34, 206, 196)
ROYAL = (44, 98, 236)
NIGHT = (36, 44, 128)
STAR = (255, 236, 120)
STAR_W = (236, 248, 255)
EYE_W = (255, 255, 255)
PUPIL = (20, 20, 30)
KOHL = (24, 22, 40)
LIP = (236, 84, 120)
BLUSH = (255, 140, 190)
ORB = (60, 70, 190)


def frame(p0, p1):
    """4x4 transform at the midpoint of p0-p1 with local z along p0 -> p1."""
    p0, p1 = np.array(p0, float), np.array(p1, float)
    d = p1 - p0
    d /= np.linalg.norm(d)
    up = np.array([0, 1.0, 0]) if abs(d[1]) < 0.95 else np.array([1.0, 0, 0])
    x = np.cross(up, d)
    x /= np.linalg.norm(x)
    y = np.cross(d, x)
    M = np.eye(4)
    M[:3, 0], M[:3, 1], M[:3, 2] = x, y, d
    M[:3, 3] = (p0 + p1) / 2
    return M


def nut():
    a = A.Animal(NAME, "Legendary")
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root"),
                    ("Robe1", "root"), ("Robe2", "Robe1"), ("Robe3", "Robe2"),
                    ("SashL", "root"), ("SashR", "root"),
                    ("WingL", "root"), ("WingL2", "WingL"), ("WingR", "root"), ("WingR2", "WingR")]

    def rbox(name, size, M, color, bone):
        p = Part(name, size, M, color)
        p.bone = bone
        a.parts.append(p)
        return p

    def beam(name, p0, p1, w, h, color, bone, pad=0.0):
        L = np.linalg.norm(np.array(p1, float) - np.array(p0, float)) + pad
        return rbox(name, (w, h, L), frame(p0, p1), color, bone)

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

    def star(name, M, r, color, bone, core=STAR_W):
        """Four-point star in the local xy plane: a turned core cube and four pyramid rays."""
        rbox(name + "Core", (r * 0.8, r * 0.8, r * 0.5), M @ Rz(45), core, bone)
        for k in range(4):
            rpyr(f"{name}Ray{k + 1}", M @ Rz(90 * k) @ T(0, r * 0.3, 0), r * 0.55, r * 0.4, r * 1.1, color, bone)

    # ---- torso (lying flat, facing -z), shoulders, usekh collar
    a.box("Torso", (-1.6, 4.8, -3.4), (1.6, 6.8, 0.4), WHITE, "root")
    a.box("Shoulders", (-2.0, 5.3, -3.5), (2.0, 6.95, -2.1), SKIN, "root")
    for i, (z0, col) in enumerate(((-3.62, GOLD), (-3.22, TURQ), (-2.82, ROYAL), (-2.42, GOLD))):
        g = 0.18 - 0.03 * i
        a.box(f"Collar{i + 1}", (-2.0 - g, 5.2 - g, z0), (2.0 + g, 6.95 + g, z0 + 0.4), col, "root")
    for i in range(7):  # gold drop beads along the collar's lower rim
        x = -1.8 + i * 0.6
        a.box(f"CollarBead{i + 1}", (x - 0.14, 4.82, -2.3), (x + 0.14, 5.05, -2.0), GOLD, "root")
        a.box(f"CollarBeadT{i + 1}", (x - 0.14, 7.12, -2.3), (x + 0.14, 7.3, -2.0), GOLD, "root")
    # pleats running down the robe's back
    for i, x in enumerate((-1.1, -0.55, 0.55, 1.1)):
        a.box(f"Pleat{i + 1}", (x - 0.06, 6.8, -2.0), (x + 0.06, 6.86, 0.4), PLEAT, "root")

    # ---- belt with turquoise/lapis checks and a scarab buckle on the back
    a.box("Belt", (-1.72, 4.68, 0.3), (1.72, 6.92, 0.95), GOLD, "root")
    for i in range(6):
        x = -1.45 + i * 0.58
        col = TURQ if i % 2 == 0 else ROYAL
        a.box(f"BeltCheck{i + 1}", (x - 0.2, 6.92, 0.45), (x + 0.2, 6.98, 0.8), col, "root")
        a.box(f"BeltCheckB{i + 1}", (x - 0.2, 4.62, 0.45), (x + 0.2, 4.68, 0.8), col, "root")
    a.box("Scarab", (-0.45, 6.95, 0.95), (0.45, 7.35, 1.85), TURQ, "root")
    a.box("ScarabHead", (-0.28, 6.95, 0.7), (0.28, 7.25, 0.98), GOLD_DK, "root")
    a.box("ScarabSplit", (-0.04, 7.35, 1.05), (0.04, 7.38, 1.8), GOLD, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 0.45, sx * 0.95))
        a.box("ScarabWing" + side, (xs[0], 6.95, 1.0), (xs[1], 7.2, 1.7), GOLD, "root")

    # ---- robe trailing behind in three flowing sections (white linen, gold hems, starry hem band)
    robe = [("Robe1", 0.95, 3.6, 1.55, 4.75, 6.75), ("Robe2", 3.6, 6.2, 1.35, 4.65, 6.4), ("Robe3", 6.2, 8.6, 1.15, 4.6, 6.0)]
    for bone, z0, z1, hw, y0, y1 in robe:
        a.pivots[bone] = (0, (y0 + y1) / 2, z0)
        a.box(bone, (-hw, y0, z0), (hw, y1, z1), WHITE, bone)
        for i, x in enumerate((-hw * 0.6, -hw * 0.2, hw * 0.2, hw * 0.6)):
            a.box(f"{bone}Pleat{i + 1}", (x - 0.06, y1, z0), (x + 0.06, y1 + 0.06, z1), PLEAT, bone)
        a.box(bone + "Hem", (-hw - 0.08, y0 - 0.08, z1 - 0.35), (hw + 0.08, y1 + 0.08, z1), GOLD, bone)
    # the last section: a night-sky hem band dotted with stars, then the feet
    a.box("RobeSky", (-1.2, 4.55, 7.3), (1.2, 6.05, 8.25), NIGHT, "Robe3")
    for i, (x, y) in enumerate(((-0.75, 6.05), (0.1, 6.05), (0.8, 6.05), (-1.2, 5.3), (1.2, 5.0))):
        if abs(x) == 1.2:
            xs = sorted((x, x + (0.06 if x > 0 else -0.06)))
            a.box(f"GlowRobeStar{i + 1}", (xs[0], y - 0.14, 7.6), (xs[1], y + 0.14, 7.9), STAR, "Robe3")
        else:
            a.box(f"GlowRobeStar{i + 1}", (x - 0.14, y, 7.6), (x + 0.14, y + 0.06, 7.9), STAR, "Robe3")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 0.15, sx * 0.85))
        a.box("Foot" + side, (xs[0], 4.75, 8.6), (xs[1], 5.35, 9.9), SKIN, "Robe3")
        a.box("Sandal" + side, (xs[0] - 0.05, 4.62, 8.6), (xs[1] + 0.05, 4.75, 9.95), GOLD, "Robe3")
        a.box("SandalStrap" + side, (xs[0] - 0.05, 4.75, 9.0), (xs[1] + 0.05, 5.42, 9.2), GOLD, "Robe3")
        a.box("Anklet" + side, (xs[0] - 0.08, 4.68, 8.55), (xs[1] + 0.08, 5.45, 8.75), TURQ, "Robe3")

    # ---- two lapis sashes streaming from the belt
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Sash" + side
        p0 = np.array([sx * 1.0, 6.9, 0.9])
        a.pivots[bone] = tuple(p0)
        pts = [p0, p0 + (sx * 0.7, -0.5, 2.6), p0 + (sx * 1.1, -1.3, 5.0), p0 + (sx * 1.3, -1.0, 7.4)]
        for k in range(3):
            beam(f"{bone}{k + 1}", pts[k], pts[k + 1], 0.55, 0.14, ROYAL if k % 2 == 0 else TURQ, bone, pad=0.2)
        rpyr(f"{bone}Tip", frame(pts[2], pts[3]) @ T(0, 0, 1.2) @ Rx(90), 0.55, 0.14, 0.7, GOLD, bone)

    # ---- saddle between the shoulder blades (the seat)
    a.box("Saddle", (-1.45, 6.95, -2.05), (1.45, 7.15, 0.25), ROYAL, "root")
    a.box("SaddleTrimF", (-1.5, 6.9, -2.2), (1.5, 7.25, -2.0), GOLD, "root")
    a.box("SaddleTrimB", (-1.5, 6.9, 0.2), (1.5, 7.45, 0.45), GOLD, "root")
    a.box("Pommel", (-0.3, 7.15, -2.25), (0.3, 7.7, -1.95), GOLD, "root")
    a.box("GlowPommelGem", (-0.16, 7.3, -2.32), (0.16, 7.56, -2.25), TURQ, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 1.6, sx * 1.75))
        a.box("Drape" + side, (xs[0], 5.4, -1.9), (xs[1], 7.0, 0.1), ROYAL, "root")
        xh = sorted((sx * 1.6, sx * 1.82))
        a.box("DrapeHem" + side, (xh[0], 5.2, -1.95), (xh[1], 5.45, 0.15), GOLD, "root")
        xa = sorted((sx * 1.75, sx * 1.86))
        a.box("Ankh" + side, (xa[0], 5.75, -1.0), (xa[1], 6.55, -0.82), GOLD, "root")
        a.box("AnkhBar" + side, (xa[0], 6.3, -1.2), (xa[1], 6.42, -0.62), GOLD, "root")
        a.box("AnkhLoop" + side, (xa[0], 6.55, -1.12), (xa[1], 6.95, -0.7), GOLD, "root")

    # ---- neck and head
    a.box("Neck", (-0.6, 6.2, -4.3), (0.6, 7.6, -3.4), SKIN, "neck")
    a.box("Head", (-1.15, 7.0, -5.6), (1.15, 9.3, -3.5), SKIN, "neck")
    a.box("Nose", (-0.18, 7.85, -5.78), (0.18, 8.3, -5.6), SKIN_DK, "neck")
    a.box("PlainMouth", (-0.35, 7.42, -5.64), (0.35, 7.56, -5.6), LIP, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        # googly plate eyes, kohl liner flicking out at the corner
        xa, xb = sorted((sx * 0.22, sx * 0.92))
        a.box("Eye" + side, (xa, 8.15, -5.66), (xb, 8.9, -5.6), EYE_W, "neck")
        c = sx * 0.5
        a.box("Pupil" + side, (c - 0.17, 8.2, -5.7), (c + 0.17, 8.6, -5.66), PUPIL, "neck")
        a.box("PlainLiner" + side, (xa - 0.04, 8.9, -5.68), (xb + 0.04, 9.0, -5.6), KOHL, "neck")
        ka, kb = sorted((sx * 0.92, sx * 1.16))
        a.box("PlainKohl" + side, (ka, 8.65, -5.68), (kb, 8.78, -5.58), KOHL, "neck")
        a.box("PlainShadow" + side, (xa, 9.0, -5.66), (xb, 9.1, -5.6), TURQ, "neck")
        ba, bb = sorted((sx * 0.55, sx * 0.95))
        a.box("PlainBlush" + side, (ba, 7.6, -5.64), (bb, 7.82, -5.6), BLUSH, "neck")
        # wig lappets hanging forward of the shoulders, banded in gold
        la, lb = sorted((sx * 0.95, sx * 1.45))
        a.box("Lappet" + side, (la, 6.0, -5.3), (lb, 8.8, -4.3), HAIR, "neck")
        for k, y in enumerate((6.35, 6.95, 7.55)):
            a.box(f"LappetBand{side}{k + 1}", (la - 0.05, y, -5.35), (lb + 0.05, y + 0.22, -4.25), GOLD, "neck")
        a.box("LappetTip" + side, (la - 0.05, 5.8, -5.35), (lb + 0.05, 6.02, -4.25), GOLD, "neck")
        ea, eb = sorted((sx * 1.45, sx * 1.6))
        a.box("Earring" + side, (ea, 7.4, -4.0), (eb, 7.95, -3.7), GOLD, "neck")
        a.box("GlowEarGem" + side, (ea, 7.05, -3.95), (eb, 7.4, -3.75), TURQ, "neck")
    # the wig: crown, back and fringe
    a.box("Wig", (-1.3, 7.3, -5.05), (1.3, 9.55, -3.2), HAIR, "neck")
    a.box("WigBack", (-1.2, 6.6, -3.4), (1.2, 8.6, -2.95), HAIR, "neck")
    a.box("Fringe", (-1.2, 9.05, -5.72), (1.2, 9.55, -5.05), HAIR, "neck")
    # gold diadem with a vulture-wing band and a glowing brow jewel
    a.box("Diadem", (-1.38, 9.1, -5.8), (1.38, 9.4, -3.1), GOLD, "neck")
    a.box("GlowBrowGem", (-0.24, 9.0, -5.88), (0.24, 9.48, -5.8), TURQ, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        for k in range(3):
            x0 = sx * (0.35 + 0.33 * k)
            xs = sorted((x0, x0 + sx * 0.28))
            a.box(f"DiademFeather{side}{k + 1}", (xs[0], 9.4, -5.82), (xs[1], 9.62 - 0.05 * k, -5.7),
                  ROYAL if k % 2 == 0 else TURQ, "neck")
    # the night-sky orb: a gold-rimmed octagon disc of stars standing on the crown
    orb_c = (0, 10.75, -4.25)
    a.box("OrbStem", (-0.3, 9.55, -4.45), (0.3, 9.85, -4.05), GOLD, "neck")
    for k, ang in enumerate((0, 45)):
        rbox(f"OrbRim{k + 1}", (1.95, 1.95, 0.32), T(*orb_c) @ Rz(ang), GOLD, "neck")
        rbox(f"Orb{k + 1}", (1.6, 1.6, 0.42), T(*orb_c) @ Rz(ang), ORB, "neck")
    for k, (x, y) in enumerate(((0, 0), (-0.45, 0.4), (0.5, 0.3), (-0.3, -0.45), (0.38, -0.4))):
        s = 0.22 if k == 0 else 0.13
        a.box(f"GlowOrbStar{k + 1}", (x - s, orb_c[1] + y - s, -4.5), (x + s, orb_c[1] + y + s, -4.0), STAR, "neck")
    rpyr("OrbFinial", T(0, orb_c[1] + 1.25, -4.25), 0.4, 0.4, 0.5, GOLD, "neck")

    # ---- arms reaching forward, a glowing star in each hand
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side
        S, E, H = (sx * 1.85, 6.1, -3.0), (sx * 2.7, 5.5, -5.3), (sx * 2.9, 5.45, -7.3)
        a.pivots[bone] = S
        beam("UpperArm" + side, S, E, 0.85, 0.85, SKIN, bone, pad=0.4)
        beam("Forearm" + side, E, H, 0.78, 0.78, SKIN, bone, pad=0.3)
        Sv, Ev, Hv = np.array(S), np.array(E), np.array(H)
        beam("Armlet" + side, Sv + 0.45 * (Ev - Sv), Sv + 0.62 * (Ev - Sv), 1.0, 1.0, GOLD, bone)
        beam("ArmletGem" + side, Sv + 0.5 * (Ev - Sv), Sv + 0.57 * (Ev - Sv), 1.06, 1.06, TURQ, bone)
        beam("Bracelet" + side, Ev + 0.62 * (Hv - Ev), Ev + 0.82 * (Hv - Ev), 0.95, 0.95, GOLD, bone)
        beam("BraceletBand" + side, Ev + 0.68 * (Hv - Ev), Ev + 0.76 * (Hv - Ev), 1.0, 1.0, TURQ, bone)
        d = (Hv - Ev) / np.linalg.norm(Hv - Ev)
        rbox("Hand" + side, (0.9, 0.5, 1.0), frame(Hv, Hv + d) @ T(0, 0, -0.1), SKIN, bone)
        rbox("Thumb" + side, (0.3, 0.3, 0.5), frame(Hv, Hv + d) @ T(-sx * 0.5, 0.15, -0.2), SKIN, bone)
        star("GlowHandStar" + side, T(*(Hv + d * 0.2 + (0, 0.95, 0))), 0.95, STAR, bone)

    # ---- the great Isis wings
    for side, sx in (("L", -1), ("R", 1)):
        inner, outer = "Wing" + side, "Wing" + side + "2"
        root = np.array([sx * 1.5, 6.6, -2.6])
        W = T(*root) @ Rz(sx * 22) @ Ry(-sx * 12)  # raised 22 deg, swept back 12 deg

        def wpt(u, v, w):
            return (W @ np.array([sx * u, v, w, 1.0]))[:3]

        a.pivots[inner] = tuple(root)
        a.pivots[outer] = tuple(wpt(4.6, 0, 0.3))

        def wbox(name, u0, u1, w0, w1, h, col, bone, v=0.0, fan=0.0):
            M = W @ T(sx * (u0 + u1) / 2, v, (w0 + w1) / 2) @ Ry(-sx * fan)
            return rbox(name, (u1 - u0, h, w1 - w0), M, col, bone)

        # gold arm bar along the leading edge, with turquoise inlay studs
        wbox(f"WingBar{side}", 0, 4.7, -0.1, 0.75, 0.6, GOLD, inner, v=0.05)
        wbox(f"WingBar{side}2", 4.5, 10.0, -0.05, 0.7, 0.55, GOLD, outer, v=0.05)
        for k in range(6):
            u = 0.9 + 1.55 * k
            wbox(f"WingInlay{side}{k + 1}", u, u + 0.6, 0.05, 0.6, 0.62, TURQ, inner if u < 4.6 else outer, v=0.06)
        # royal blue / turquoise scale coverts
        for k in range(11):
            u0 = 0.15 + 0.9 * k
            bone = inner if u0 < 4.5 else outer
            wbox(f"Covert{side}{k + 1}", u0, u0 + 0.85, 0.7, 1.75, 0.4, ROYAL if k % 2 == 0 else TURQ, bone)
            wbox(f"CovertTip{side}{k + 1}", u0 + 0.12, u0 + 0.73, 1.75, 2.1, 0.36, GOLD, bone)
        # turquoise secondaries
        for k in range(10):
            u0 = 0.15 + 0.95 * k
            bone = inner if u0 < 4.5 else outer
            wbox(f"Secondary{side}{k + 1}", u0, u0 + 0.88, 2.0, 3.5, 0.32, TURQ, bone)
        # long night-blue flight feathers, fanned, gold tipped, sprinkled with stars
        for k in range(11):
            u0 = 0.2 + 0.9 * k
            ln = 3.0 + 0.3 * k + (0.6 if k % 2 == 0 else 0.0)
            fan = 2.2 * k
            bone = inner if u0 < 4.5 else outer
            M = W @ T(sx * (u0 + 0.42), -0.05, 3.3) @ Ry(-sx * fan)
            rbox(f"Feather{side}{k + 1}", (0.68, 0.26, ln), M @ T(0, 0, ln / 2), NIGHT, bone)
            rpyr(f"FeatherTip{side}{k + 1}", M @ T(0, 0, ln) @ Rx(90), 0.68, 0.26, 0.8, GOLD, bone)
            if k % 2 == 0:
                rbox(f"GlowWingStar{side}{k + 1}", (0.26, 0.3, 0.26), M @ T(0, 0.02, ln * 0.55) @ Ry(45), STAR, bone)
            else:
                rbox(f"GlowWingStar{side}{k + 1}", (0.18, 0.3, 0.18), M @ T(0, 0.02, ln * 0.3) @ Ry(45), STAR_W, bone)

    # ---- four little stars orbiting her
    for j, (x, y, z) in enumerate(((-4.6, 8.8, -5.2), (4.6, 8.8, -5.2), (-3.2, 3.6, 4.0), (3.2, 3.6, 4.0))):
        bone = f"Star{j + 1}"
        a.bone_order.append((bone, "root"))
        a.pivots[bone] = (x, y, z)
        star(f"GlowOrbit{j + 1}", T(x, y, z) @ Ry(-35 if x < 0 else 35), 0.7, STAR, bone)

    a.pivots["root"] = (0, 5.8, 0)
    a.pivots["neck"] = (0, 6.9, -3.6)
    a.meta = {"seat": (0, 7.15, -0.9), "neck_loop": {"center": (0, 7.8, -4.0), "radius": 1.5}}
    for p in a.parts:
        p.neon = p.name.startswith("Glow")
    return a


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
    a = nut()
    model, _ = write_bbmodel(a.parts, NAME, None, bones=a.bones())
    model["animations"] = []
    with open(os.path.join(out, NAME + ".bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    lo = np.min([q for p in a.parts for q in (p.polys if p.shape == "Poly" else [p.cf[:3, 3]])
                 for q in (q if np.ndim(q) == 2 else [q])], axis=0)
    hi = np.max([q for p in a.parts for q in (p.polys if p.shape == "Poly" else [p.cf[:3, 3]])
                 for q in (q if np.ndim(q) == 2 else [q])], axis=0)
    print(f"{NAME}: {len(a.parts)} parts, extent {np.round(lo, 1)} .. {np.round(hi, 1)}")
    shot(a.parts, eye=(-15, 21, -18), target=(0, 6.0, 0.8), W=900, H=900, fov=46).save(os.path.join(SHOT, NAME + ".png"))
    views = [dict(eye=(-19, 13, -21), target=(0, 6, 0.5)), dict(eye=(-28, 8, 0), target=(0, 6, 0.5)),
             dict(eye=(16, 15, 21), target=(0, 6, 0.5)), dict(eye=(0, 9, -27), target=(0, 6.5, 0))]
    sheet = Image.new("RGB", (1000, 1000))
    for i, cam in enumerate(views):
        sheet.paste(shot(a.parts, W=500, H=500, fov=48, **cam), ((i % 2) * 500, (i // 2) * 500))
    sheet.save(os.path.join(os.path.dirname(SHOT), "Nut_views.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
