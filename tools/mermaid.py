"""Mermaid (World 3, Cnidaria, Legendary): the reef's sea princess, built on Nut's frame.
She swims flat out like a dolphin, so the rider sits on a scallop-shell saddle between her
shoulder blades. A long two-tone turquoise fish tail in three sections (dark teal stops
between the bands, a glowing dorsal stripe and glowing scale highlights) ends in a big forked
fluke. Coral-pink hair in chunky locks streams back past her shoulders, fin ears, a pink and
peach seashell top, a pearl necklace and a gold crown with pearls and coral branches. Her
right hand holds a gold trident forward like a lance (glowing tips), her left a glowing pearl
in an open clam. Two big fins flare from her hips and four bubbles drift round her.

    python3 tools/mermaid.py

writes designs/cnidaria/Mermaid.bbmodel (convert without --zyx, as Nut), the preview
/mnt/project-files/world3/cnidaria/renders/Mermaid.png, a four-view sheet beside a horse for
scale and an animation gif (--still skips the gif). Every rest is baked into the parts;
every bone sits at 0.

  idle    slow dolphin kick, hair and hip fins rippling, head looking about
  walk    quicker kick, nosing forward
  gallop  big fast kick, diving into the chase, hair streaming flat
"""

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz, render  # noqa: E402

NAME = "Mermaid"
SKIN = (250, 196, 156)      # warm skin
SKIN_DK = (226, 156, 120)
HAIR = (255, 74, 150)       # coral pink / magenta locks
HAIR_DK = (196, 30, 112)
HAIR_LT = (255, 140, 186)
TEAL = (0, 176, 168)        # tail scales, two tones
TURQ = (40, 228, 208)
DEEP = (0, 92, 108)         # dark stops between bands
BELLY = (170, 250, 232)
GLOW = (150, 255, 240)
FIN_A = (60, 214, 255)
FIN_B = (150, 104, 255)
FIN_DK = (64, 52, 168)
SHELL = (255, 120, 170)     # seashells
PEACH = (255, 178, 128)
SHELL_DK = (214, 70, 120)
CORAL = (255, 86, 72)
GOLD = (255, 196, 40)
GOLD_DK = (222, 150, 24)
PEARL = (250, 248, 255)
PEARL_GLOW = (236, 244, 255)
EYE_W = (255, 255, 255)
PUPIL = (20, 20, 30)
LASH = (40, 20, 50)
LIP = (236, 60, 110)
BLUSH = (255, 140, 170)
IRIS = (30, 170, 200)


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


def mermaid():
    a = A.Animal(NAME, "Legendary")
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root"),
                    ("Tail1", "root"), ("Tail2", "Tail1"), ("Tail3", "Tail2"), ("Fluke", "Tail3"),
                    ("FinL", "root"), ("FinR", "root")]
    for side in "LR":
        a.bone_order += [(f"Hair{side}{k}", "neck") for k in (1, 2, 3)]

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

    def pearl(name, c, r, bone, color=PEARL):
        """A round-ish pearl: a cube and a turned cube."""
        rbox(name, (r, r, r), T(*c), color, bone)
        rbox(name + "B", (r * 0.82, r * 1.12, r * 0.82), T(*c) @ Ry(45) @ Rx(45), color, bone)

    def fan(name, hinge, ang0, ang1, n, L, w, h, cols, bone, M=np.eye(4), tip=None, glow_every=0):
        """Ribs fanning in the local xz plane from hinge (angles from local -z, toward +x),
        placed by M. Returns the rib end points."""
        ends = []
        for k in range(n):
            t = k / (n - 1) if n > 1 else 0.5
            ang = math.radians(ang0 + (ang1 - ang0) * t)
            ln = L(t) if callable(L) else L
            h0 = np.array(hinge, float)
            e = h0 + ln * np.array([math.sin(ang), 0, -math.cos(ang)])
            P0 = (M @ np.array([*h0, 1.0]))[:3]
            P1 = (M @ np.array([*e, 1.0]))[:3]
            beam(f"{name}{k + 1}", P0, P1, w, h, cols[k % len(cols)], bone, pad=0.1)
            if tip:
                rpyr(f"{name}Tip{k + 1}", frame(P0, P1) @ T(0, 0, np.linalg.norm(P1 - P0) / 2) @ Rx(90),
                     w, h, tip[1], tip[0], bone)
            if glow_every and k % glow_every == 0:
                g = P0 + 0.62 * (P1 - P0)
                rbox(f"Glow{name}Dot{k + 1}", (w * 0.55, h + 0.08, w * 0.55), frame(P0, P1) @ T(0, 0, 0.12 * np.linalg.norm(P1 - P0)),
                     GLOW, bone)
            ends.append(P1)
        return ends

    # ---- torso (lying flat, facing -z), shoulders, the seashell top
    a.box("Torso", (-1.55, 4.85, -3.4), (1.55, 6.8, 0.45), SKIN, "root")
    a.box("Shoulders", (-2.0, 5.3, -3.5), (2.0, 6.95, -2.1), SKIN, "root")
    a.box("Back", (-1.3, 6.8, -2.1), (1.3, 6.95, 0.3), SKIN_DK, "root")
    # shell straps round the chest and over the shoulders
    a.box("ShellStrap", (-2.08, 5.22, -2.75), (2.08, 7.02, -2.48), SHELL_DK, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 0.75, sx * 1.05))
        a.box("ShellStrapUp" + side, (xs[0], 6.95, -3.55), (xs[1], 7.03, -2.48), SHELL_DK, "root")
        a.box("ShellKnot" + side, (xs[0] - 0.05, 6.95, -2.85), (xs[1] + 0.05, 7.18, -2.4), PEARL, "root")
        # two big scallop shells under the chest, ribs fanning forward and out the sides
        cx = sx * 0.95
        a.box("ShellHinge" + side, (cx - 0.35, 4.62, -1.95), (cx + 0.35, 5.0, -1.6), SHELL_DK, "root")
        fan("Shell" + side, (cx, 4.72, -1.75), -75, 75, 7,
            lambda t: 1.55 - 0.2 * abs(t - 0.5), 0.36, 0.3, (SHELL, PEACH), "root")
        # shell cups showing at the sides of the chest
        xc = sorted((sx * 1.95, sx * 2.18))
        a.box("ShellSide" + side, (xc[0], 4.85, -3.25), (xc[1], 5.75, -2.05), SHELL, "root")
        a.box("ShellSideRib" + side, (xc[0] - 0.04, 4.85, -2.8), (xc[1] + 0.04, 5.8, -2.55), PEACH, "root")
        a.box("ShellSideRim" + side, (xc[0] - 0.02, 4.72, -3.3), (xc[1] + 0.02, 4.9, -2.0), SHELL_DK, "root")

    # ---- waist: a pearl girdle and a scale band where the tail begins
    a.box("Waist", (-1.68, 4.75, 0.3), (1.68, 6.92, 0.95), TEAL, "root")
    a.box("WaistBand", (-1.74, 4.7, 0.25), (1.74, 6.98, 0.42), DEEP, "root")
    for i in range(7):
        x = -1.5 + i * 0.5
        a.box(f"GirdlePearl{i + 1}", (x - 0.15, 6.92, 0.18), (x + 0.15, 7.18, 0.48), PEARL, "root")
            # a scallop buckle on the small of her back, a glowing pearl in it
    fan("Buckle", (0, 7.0, 1.05), -70, 70, 5, 0.85, 0.3, 0.26, (SHELL, PEACH), "root")
    pearl("GlowBucklePearl", (0, 7.32, 0.85), 0.32, "root", PEARL_GLOW)
    # frilly fin skirt where skin meets scales
    for side, sx in (("L", -1), ("R", 1)):
        for k in range(3):
            y = 5.05 + 0.62 * k
            P0 = np.array([sx * 1.65, y, 0.55])
            beam(f"Frill{side}{k + 1}", P0, P0 + (sx * 0.75, -0.15, 0.9), 0.5, 0.18,
                 FIN_A if k % 2 == 0 else FIN_B, "root", pad=0.1)

    # ---- the fish tail in three sections: two-tone scale bands, dark stops, a glowing stripe
    tail = [("Tail1", 0.95, 3.8, 1.55, 4.85, 6.8), ("Tail2", 3.8, 6.55, 1.25, 5.0, 6.6),
            ("Tail3", 6.55, 9.0, 0.95, 5.2, 6.35)]
    for bone, z0, z1, hw, y0, y1 in tail:
        a.pivots[bone] = (0, (y0 + y1) / 2, z0)
        a.box(bone, (-hw, y0, z0), (hw, y1, z1), TEAL, bone)
        a.box(bone + "Belly", (-hw + 0.25, y0 - 0.12, z0 + 0.1), (hw - 0.25, y0 + 0.05, z1 - 0.1), BELLY, bone)
        a.box(bone + "Stop", (-hw - 0.07, y0 - 0.07, z0), (hw + 0.07, y1 + 0.07, z0 + 0.25), DEEP, bone)
        # bold two-tone scale bands and one glowing lateral line a side
        nb = int(round((z1 - z0 - 0.25) / 0.95))
        bl = (z1 - z0 - 0.25) / nb
        for r in range(nb):
            if r % 2 == 0:
                zb = z0 + 0.25 + r * bl
                a.box(f"{bone}Band{r + 1}", (-hw - 0.05, y0 + 0.2, zb), (hw + 0.05, y1 + 0.05, zb + bl), TURQ, bone)
        for side, sx in (("L", -1), ("R", 1)):
            xs = sorted((sx * hw, sx * (hw + 0.12)))
            a.box(f"Glow{bone}Line{side}", (xs[0], (y0 + y1) / 2 - 0.12, z0 + 0.4), (xs[1], (y0 + y1) / 2 + 0.12, z1 - 0.2), GLOW, bone)
        # glowing dorsal stripe with dark edging
        a.box(bone + "StripeEdge", (-0.3, y1, z0 + 0.25), (0.3, y1 + 0.08, z1), DEEP, bone)
        a.box("Glow" + bone + "Stripe", (-0.16, y1 + 0.05, z0 + 0.3), (0.16, y1 + 0.16, z1 - 0.05), GLOW, bone)
    # a small dorsal frill on the second section
    for k in range(4):
        z = 4.3 + 0.55 * k
        rpyr(f"DorsalSpine{k + 1}", T(0, 6.62, z) @ Rx(-25), 0.22, 0.5, 0.9 - 0.12 * k, FIN_B, "Tail2")
    # tail stalk
    a.box("Stalk", (-0.6, 5.35, 9.0), (0.6, 6.2, 10.0), TEAL, "Fluke")
    a.box("StalkStop", (-0.68, 5.28, 9.0), (0.68, 6.27, 9.25), DEEP, "Fluke")
    a.box("GlowStalkStripe", (-0.14, 6.2, 9.25), (0.14, 6.3, 10.0), GLOW, "Fluke")
    a.pivots["Fluke"] = (0, 5.8, 9.0)
    # ---- the big forked fluke: two lobes of rays fanning back and out, flat like a dolphin's
    a.box("FlukeCore", (-0.95, 5.4, 9.7), (0.95, 6.15, 10.9), FIN_B, "Fluke")
    a.box("FlukeCoreTop", (-0.7, 6.15, 9.8), (0.7, 6.28, 10.7), FIN_DK, "Fluke")
    for side, sx in (("L", -1), ("R", 1)):
        hinge = (sx * 0.5, 5.78, 10.3)
        M = T(*hinge) @ Ry(180)  # local -z points back (+z world)
        ang = (-25, -85) if sx < 0 else (25, 85)
        # Ry(180) mirrors x: angles toward +x local are toward -x world
        ang = (-ang[0], -ang[1])
        ends = fan("Fluke" + side, (0, 0, 0), ang[0], ang[1], 6,
                   lambda t: 3.9 - 1.0 * abs(t - 0.35) * 2, 0.62, 0.3,
                   (FIN_A, (80, 170, 255), FIN_B), "Fluke", M=M, tip=(FIN_DK, 0.7), glow_every=2)
        # webbing between the rays
        for k in range(len(ends) - 1):
            mid = (ends[k] + ends[k + 1]) / 2
            h = np.array(hinge)
            beam(f"FlukeWeb{side}{k + 1}", h + 0.25 * (mid - h), h + 0.85 * (mid - h), 0.6, 0.22,
                 (110, 190, 255), "Fluke")

    # ---- the hip fins: two big fins flaring from her hips like wings
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Fin" + side
        root = np.array([sx * 1.7, 5.6, 1.4])
        a.pivots[bone] = tuple(root)
        M = T(*root) @ Rz(sx * 12)
        a.box("FinBase" + side, *[tuple(v) for v in np.sort([root + (sx * -0.1, -0.35, -0.6), root + (sx * 0.5, 0.35, 0.8)], axis=0)],
              FIN_DK, bone)
        ends = fan("Fin" + side, (0, 0, 0), sx * 60, sx * 150, 6,
                   lambda t: 2.6 + 1.4 * math.sin(math.pi * t), 0.55, 0.24, (FIN_A, (100, 160, 255), FIN_B), bone,
                   M=M, tip=(FIN_DK, 0.6), glow_every=2)
        for k in range(len(ends) - 1):
            mid = (ends[k] + ends[k + 1]) / 2
            beam(f"FinWeb{side}{k + 1}", root + 0.2 * (mid - root), root + 0.85 * (mid - root), 0.6, 0.18,
                 (120, 200, 255), bone)

    # ---- scallop-shell saddle between the shoulder blades (the seat)
    a.box("Saddle", (-1.45, 6.95, -2.05), (1.45, 7.15, 0.25), (255, 240, 226), "root")
    fan("SaddleRib", (0, 7.12, -2.0), 120, 240, 7, 2.2, 0.32, 0.16, (SHELL, PEACH), "root",
        M=np.eye(4))
    a.box("SaddleTrimF", (-1.5, 6.9, -2.2), (1.5, 7.25, -2.0), GOLD, "root")
    a.box("SaddleTrimB", (-1.5, 6.9, 0.2), (1.5, 7.45, 0.45), GOLD, "root")
    a.box("Pommel", (-0.3, 7.15, -2.25), (0.3, 7.7, -1.95), CORAL, "root")
    pearl("GlowPommelPearl", (0, 7.85, -2.1), 0.36, "root", PEARL_GLOW)
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 1.6, sx * 1.75))
        a.box("Drape" + side, (xs[0], 5.4, -1.9), (xs[1], 7.0, 0.1), CORAL, "root")
        xh = sorted((sx * 1.6, sx * 1.82))
        a.box("DrapeHem" + side, (xh[0], 5.2, -1.95), (xh[1], 5.45, 0.15), GOLD, "root")
    # ---- neck, pearl necklace, head
    a.box("Neck", (-0.6, 6.2, -4.3), (0.6, 7.6, -3.4), SKIN, "neck")
    neck_c = np.array([0, 6.85, -3.75])
    for k in range(12):
        ang = TAU * k / 12
        r = (0.78, 0.82)
        c = neck_c + (r[0] * math.cos(ang), r[1] * math.sin(ang), 0)
        if math.sin(ang) < -0.3:
            c = c + (0, -0.15 * (1 - abs(math.cos(ang))), -0.1)
        a.box(f"Necklace{k + 1}", tuple(c - 0.15), tuple(c + 0.15), PEARL, "neck")
    pearl("GlowNecklacePendant", (0, 5.82, -4.0), 0.36, "neck", PEARL_GLOW)
    a.box("Head", (-1.15, 7.0, -5.6), (1.15, 9.3, -3.5), SKIN, "neck")
    a.box("Nose", (-0.17, 7.8, -5.76), (0.17, 8.2, -5.6), SKIN_DK, "neck")
    a.box("PlainMouth", (-0.36, 7.38, -5.64), (0.36, 7.52, -5.6), LIP, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        ma, mb = sorted((sx * 0.36, sx * 0.48))
        a.box("PlainSmile" + side, (ma, 7.48, -5.64), (mb, 7.62, -5.6), LIP, "neck")
        # googly plate eyes, teal irises behind dark pupils, lashes flicking out
        xa, xb = sorted((sx * 0.2, sx * 0.94))
        a.box("Eye" + side, (xa, 8.1, -5.66), (xb, 8.9, -5.6), EYE_W, "neck")
        c = sx * 0.52
        a.box("PupilIris" + side, (c - 0.24, 8.16, -5.69), (c + 0.24, 8.66, -5.66), IRIS, "neck")
        a.box("Pupil" + side, (c - 0.15, 8.22, -5.72), (c + 0.15, 8.58, -5.69), PUPIL, "neck")
        a.box("PupilShine" + side, (c - 0.1 + sx * 0.05, 8.44, -5.74), (c + sx * 0.05, 8.54, -5.72), EYE_W, "neck")
        a.box("PlainLash" + side, (xa - 0.04, 8.9, -5.68), (xb + 0.04, 9.0, -5.6), LASH, "neck")
        ka, kb = sorted((sx * 0.94, sx * 1.16))
        a.box("PlainLashFlick" + side, (ka, 8.82, -5.68), (kb, 9.0, -5.58), LASH, "neck")
        ba, bb = sorted((sx * 0.55, sx * 0.97))
        a.box("PlainBlush" + side, (ba, 7.6, -5.64), (bb, 7.82, -5.6), BLUSH, "neck")
        # front locks framing the face, banded with pearls
        la, lb = sorted((sx * 0.98, sx * 1.48))
        a.box("Lock" + side, (la, 6.05, -5.3), (lb, 9.0, -4.3), HAIR, "neck")
        a.box("LockShade" + side, (la - 0.03, 6.05, -4.7), (lb + 0.03, 8.6, -4.3), HAIR_DK, "neck")
        for k, y in enumerate((6.5, 7.3)):
            a.box(f"LockPearl{side}{k + 1}", (la - 0.06, y, -5.36), (lb + 0.06, y + 0.26, -4.24), PEARL, "neck")
        rpyr("LockTip" + side, T(sx * 1.23, 6.05, -4.8) @ Rx(180), 0.5, 1.0, 0.6, HAIR_DK, "neck")
        # fin ears: three thick rays fanning back and up from the side of the head
        ear = np.array([sx * 1.5, 8.1, -4.0])
        a.box("EarBase" + side, *[tuple(v) for v in np.sort([ear + (-0.12, -0.3, -0.3), ear + (0.12, 0.3, 0.3)], axis=0)],
              FIN_DK, "neck")
        for k in range(3):
            tip = ear + (sx * (0.9 - 0.15 * k), 0.3 + 0.55 * k, 0.9 + 0.2 * k)
            beam(f"EarRay{side}{k + 1}", ear, tip, 0.34, 0.18, (FIN_A, (100, 160, 255), FIN_B)[k], "neck", pad=0.1)
            rpyr(f"EarTip{side}{k + 1}", frame(ear, tip) @ T(0, 0, np.linalg.norm(tip - ear) / 2) @ Rx(90),
                 0.34, 0.18, 0.4, FIN_DK, "neck")
    # hair: crown, back and a fringe swept to one side
    a.box("Hair", (-1.3, 7.4, -5.05), (1.3, 9.6, -3.2), HAIR, "neck")
    a.box("HairBack", (-1.25, 6.9, -3.4), (1.25, 9.2, -2.85), HAIR_DK, "neck")
    a.box("Fringe", (-1.22, 9.0, -5.74), (1.22, 9.6, -5.05), HAIR, "neck")
    a.box("FringeSweep", (-1.22, 8.75, -5.78), (-0.25, 9.05, -5.2), HAIR_LT, "neck")
    a.box("FringeSweepR", (0.6, 8.85, -5.76), (1.22, 9.05, -5.2), HAIR_DK, "neck")
    # gold crown: band, five points with pearls, a big glowing pearl, coral branches
    a.box("CrownBand", (-1.4, 9.45, -5.4), (1.4, 9.85, -3.3), GOLD, "neck")
    a.box("CrownRim", (-1.44, 9.4, -5.44), (1.44, 9.52, -3.26), GOLD_DK, "neck")
    for k, x in enumerate((-1.05, -0.52, 0, 0.52, 1.05)):
        h = (0.6, 0.85, 1.2, 0.85, 0.6)[k]
        rpyr(f"CrownPoint{k + 1}", T(x, 9.85, -5.2), 0.42, 0.3, h, GOLD, "neck")
        a.box(f"CrownPearl{k + 1}", (x - 0.14, 9.85 + h - 0.12, -5.34), (x + 0.14, 9.85 + h + 0.16, -5.06), PEARL, "neck")
    for k, x in enumerate((-0.75, 0.75)):
        a.box(f"CrownGem{k + 1}", (x - 0.15, 9.52, -5.47), (x + 0.15, 9.78, -5.4), CORAL, "neck")
    pearl("GlowCrownPearl", (0, 9.66, -5.5), 0.36, "neck", PEARL_GLOW)
    for side, sx in (("L", -1), ("R", 1)):
        b0 = np.array([sx * 1.1, 9.8, -3.7])
        b1 = b0 + (sx * 0.5, 1.3, 0.3)
        beam("CoralBranch" + side, b0, b1, 0.28, 0.28, CORAL, "neck", pad=0.1)
        beam("CoralTwig" + side, b0 + 0.5 * (b1 - b0), b0 + 0.5 * (b1 - b0) + (sx * 0.6, 0.45, 0.0), 0.22, 0.22, CORAL, "neck", pad=0.1)
        beam("CoralTwigB" + side, b1, b1 + (-sx * 0.3, 0.5, 0.1), 0.22, 0.22, CORAL, "neck", pad=0.1)
        a.box("CoralTipA" + side, tuple(b1 + (-sx * 0.3, 0.5, 0.1) - 0.15), tuple(b1 + (-sx * 0.3, 0.5, 0.1) + 0.15), SHELL, "neck")
        tw = b0 + 0.5 * (b1 - b0) + (sx * 0.6, 0.45, 0.0)
        a.box("CoralTipB" + side, tuple(tw - 0.15), tuple(tw + 0.15), SHELL, "neck")
    # ---- long locks streaming back along her sides, each on its own bone
    for side, sx in (("L", -1), ("R", 1)):
        for k in (1, 2, 3):
            bone = f"Hair{side}{k}"
            p0 = np.array([sx * (1.0 + 0.2 * k), 8.7 - 0.6 * k, -3.0])
            a.pivots[bone] = tuple(p0)
            pts = [p0, p0 + (sx * (0.55 + 0.1 * k), -0.7, 1.6),
                   p0 + (sx * (0.8 + 0.12 * k), -1.15 + 0.2 * k, 3.3 - 0.2 * k),
                   p0 + (sx * (0.95 + 0.15 * k), -1.25 + 0.3 * k, 4.6 - 0.5 * k)]
            cols = (HAIR, HAIR_LT, HAIR) if k % 2 else (HAIR_DK, HAIR, HAIR_DK)
            w = 0.78 - 0.04 * k
            for s_ in range(3):
                beam(f"{bone}Seg{s_ + 1}", pts[s_], pts[s_ + 1], w - 0.1 * s_, 0.55 - 0.05 * s_, cols[s_], bone, pad=0.3)
            rpyr(f"{bone}Tip", frame(pts[2], pts[3]) @ T(0, 0, np.linalg.norm(pts[3] - pts[2]) / 2 + 0.1) @ Rx(90),
                 w - 0.2, 0.45, 0.7, HAIR_DK if k % 2 else HAIR, bone)
            if k == 2:
                c = pts[1] + 0.5 * (pts[2] - pts[1])
                a.box(f"HairPearl{side}", tuple(c + (-0.17, 0.2, -0.17)), tuple(c + (0.17, 0.5, 0.17)), PEARL, bone)

    # ---- arms reaching forward: a gold trident in the right hand, a glowing pearl in the left
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side
        S, E, H = (sx * 1.85, 6.1, -3.0), (sx * 2.7, 5.5, -5.3), (sx * 2.9, 5.45, -7.3)
        a.pivots[bone] = S
        beam("UpperArm" + side, S, E, 0.85, 0.85, SKIN, bone, pad=0.4)
        beam("Forearm" + side, E, H, 0.78, 0.78, SKIN, bone, pad=0.3)
        Sv, Ev, Hv = np.array(S), np.array(E), np.array(H)
        beam("Armlet" + side, Sv + 0.45 * (Ev - Sv), Sv + 0.62 * (Ev - Sv), 1.0, 1.0, GOLD, bone)
        beam("ArmletPearl" + side, Sv + 0.5 * (Ev - Sv), Sv + 0.57 * (Ev - Sv), 1.06, 1.06, PEARL, bone)
        beam("Bracelet" + side, Ev + 0.62 * (Hv - Ev), Ev + 0.82 * (Hv - Ev), 0.95, 0.95, GOLD, bone)
        beam("BraceletBand" + side, Ev + 0.68 * (Hv - Ev), Ev + 0.76 * (Hv - Ev), 1.0, 1.0, CORAL, bone)
        d = (Hv - Ev) / np.linalg.norm(Hv - Ev)
        rbox("Hand" + side, (0.9, 0.5, 1.0), frame(Hv, Hv + d) @ T(0, 0, -0.1), SKIN, bone)
        rbox("Thumb" + side, (0.3, 0.3, 0.5), frame(Hv, Hv + d) @ T(-sx * 0.5, 0.15, -0.2), SKIN, bone)
        if sx < 0:
            # an open clam on the palm, a glowing pearl in it
            c = Hv + d * 0.2 + np.array([0, 0.35, 0])
            fan("ClamLow", c - (0, 0.05, -0.45), -70, 70, 5, 1.0, 0.34, 0.2, (SHELL, PEACH), bone)
            M = T(*(c + (0, 0.1, 0.45))) @ Rx(-55)
            fan("ClamTop", (0, 0, 0), -70, 70, 5, 1.0, 0.34, 0.2, (PEACH, SHELL), bone, M=M)
            pearl("GlowHandPearl", c + (0, 0.5, -0.1), 0.62, bone, PEARL_GLOW)
        else:
            # the trident, held forward like a lance
            g = Hv + np.array([0, 0.1, 0])
            back, front = g + (0, 0.3, 3.6), g + (0, -0.25, -4.6)
            beam("TridentShaft", back, front, 0.32, 0.32, GOLD, bone)
            beam("TridentButt", back + (0, 0, 0.0), back + 0.06 * (front - back), 0.5, 0.5, GOLD_DK, bone)
            for k, f in enumerate((0.38, 0.47, 0.56)):
                beam(f"TridentWrap{k + 1}", back + f * (front - back), back + (f + 0.04) * (front - back), 0.42, 0.42, CORAL, bone)
            u = (front - back) / np.linalg.norm(front - back)
            beam("TridentCollar", front - 0.4 * u, front, 0.55, 0.55, GOLD_DK, bone)
            Fm = frame(front, front + u)
            rbox("TridentBar", (2.1, 0.36, 0.36), Fm @ T(0, 0, 0.15), GOLD, bone)
            pearl("GlowTridentPearl", front + 0.15 * u + (0, 0.25, 0), 0.28, bone, PEARL_GLOW)
            for k, x in enumerate((-0.88, 0, 0.88)):
                ln = 1.9 if x == 0 else 1.4
                rbox(f"TridentProng{k + 1}", (0.28, 0.28, ln), Fm @ T(x, 0, 0.15 + ln / 2), GOLD, bone)
                rpyr(f"GlowTridentTip{k + 1}", Fm @ T(x, 0, 0.15 + ln) @ Rx(90), 0.42, 0.42, 0.75, GLOW, bone)
                if x != 0:
                    rpyr(f"TridentBarb{k + 1}", Fm @ T(x + (0.15 if x > 0 else -0.15), 0, 0.15 + ln - 0.45) @ Rz(-90 if x > 0 else 90),
                         0.26, 0.26, 0.3, GOLD_DK, bone)

    # ---- four glowing bubbles drifting round her
    for j, (x, y, z) in enumerate(((-4.4, 8.6, -5.6), (4.6, 8.9, -3.8), (-3.6, 4.4, 4.6), (3.4, 4.0, 6.4))):
        bone = f"Bubble{j + 1}"
        a.bone_order.append((bone, "root"))
        a.pivots[bone] = (x, y, z)
        r = 0.55 if j < 2 else 0.42
        pearl(f"GlowBubble{j + 1}", (x, y, z), r * 1.4, bone, (150, 236, 255))
        a.box(f"BubbleShine{j + 1}", (x - r * 0.55, y + r * 0.2, z - r * 0.9), (x - r * 0.1, y + r * 0.6, z - r * 0.7), EYE_W, bone)
        pearl(f"GlowBubbleSmall{j + 1}", (x + r * 1.3, y + r * 1.4, z + r * 0.4), r * 0.6, bone, (150, 236, 255))

    a.pivots["root"] = (0, 5.8, 0)
    a.pivots["neck"] = (0, 6.9, -3.6)
    a.meta = {"seat": (0, 7.15, -0.9), "neck_loop": {"center": (0, 7.8, -4.0), "radius": 1.5}}
    for p in a.parts:
        p.neon = p.name.startswith("Glow")
    a.animations = animations
    return a


TAU = 2 * math.pi


def track(L, fn, n=16, channel="rotation"):
    """fn(u), u = 0..1 over the loop -> (x, y, z): degrees, or Blockbench units for position."""
    return {"channel": channel, "interp": "catmullrom",
            "keys": [(round(L * k / n, 4), tuple(round(float(v), 3) for v in fn(k / n))) for k in range(n + 1)]}


def animations():
    """A dolphin kick: the tail chain bends about X with growing amplitude and phase lag down to
    the fluke while the body counter-pitches; hair locks and hip fins ripple behind; the trident
    arm holds steady; the bubbles spin and bob."""
    def moves(L, kicks, amp, pitch, bob, ripple, n):
        w = lambda u, ph=0.0: math.sin(TAU * (kicks * u - ph))
        t = {"root": [track(L, lambda u: (pitch + 2.5 * w(u, 0.0), 0, 0), n),
                      track(L, lambda u: (0, -bob * w(u, 0.25), 0), n, "position")],
             "neck": [track(L, lambda u: (-pitch * 0.8 - 2.5 * w(u, 0.05), 6 * math.sin(TAU * u) if kicks < 2 else 0, 0), n)]}
        for i, bone in enumerate(("Tail1", "Tail2", "Tail3", "Fluke")):
            t[bone] = [track(L, lambda u, i=i: (amp * (0.45 + 0.25 * i) * w(u, 0.12 + 0.1 * i), 0, 0), n)]
        for side, sx in (("L", -1), ("R", 1)):
            t["Fin" + side] = [track(L, lambda u, sx=sx: (ripple * 0.5 * w(u, 0.3), 0, sx * ripple * w(u, 0.2)), n)]
            if sx < 0:
                t["Arm" + side] = [track(L, lambda u, sx=sx: (4 * w(u, 0.4) - pitch * 0.5, 0, sx * 3 * w(u, 0.6)), n)]
            else:
                t["Arm" + side] = [track(L, lambda u: (-pitch * 0.5 - 1.5 * w(u, 0.0), 0, 0), n)]
            for k in (1, 2, 3):
                t[f"Hair{side}{k}"] = [track(L, lambda u, sx=sx, k=k: (ripple * 0.8 * w(u, 0.2 + 0.1 * k),
                                                                       sx * ripple * 0.6 * w(u, 0.45 + 0.08 * k), 0), n)]
        for j in range(4):
            d = 1 if j % 2 else -1
            t[f"Bubble{j + 1}"] = [{"channel": "rotation", "interp": "linear",
                                    "keys": [(round(L * k / 4, 4), (0, d * 90 * k, 0)) for k in range(5)]},
                                   track(L, lambda u, j=j: (0, 4 * math.sin(TAU * (u + 0.25 * j)), 0), n, "position")]
        return t

    return {"idle": (2.0, moves(2.0, 1, 10, 0, 3, 6, 32)),
            "walk": (1.0, moves(1.0, 1, 14, -6, 4, 9, 24)),
            "gallop": (0.6, moves(0.6, 1, 18, -12, 5, 12, 24))}


SHOT = "/mnt/project-files/world3/cnidaria/renders"
BG = (232, 244, 250)


def shot(parts, crop=False, pad=50, **cam):
    im = render(parts, transparent=True, **cam)
    if crop and im.getbbox():
        x0, y0, x1, y1 = im.getbbox()
        im = im.crop((x0 - pad, y0 - pad, x1 + pad, y1 + pad))
    out = Image.new("RGB", im.size, BG)
    out.paste(im, (0, 0), im)
    return out


def main(out=os.path.join(A.ROOT, "designs", "cnidaria")):
    os.makedirs(out, exist_ok=True)
    os.makedirs(SHOT, exist_ok=True)
    a = mermaid()
    model = A.build_animal(a, out)
    rest = pose(model, None, 0)
    pts = np.vstack([q for p in rest for q in p.polys])
    lo, hi = pts.min(0), pts.max(0)
    nparts = sum(4 if e["type"] == "mesh" and len(e["vertices"]) == 5 else 1 for e in model["elements"])
    print(f"{NAME}: {len(model['elements'])} elements, {nparts} roblox parts, extent {np.round(lo, 2)} .. {np.round(hi, 2)},"
          f" size {np.round(hi - lo, 1)}")
    for p in rest:
        p.neon = p.name.startswith("Glow")
    shot(rest, crop=True, eye=(-21, 19, -24), target=(0.5, 6.0, -1.0), W=1200, H=1000, fov=50).save(os.path.join(SHOT, NAME + ".png"))
    horse = pose(A.qm_horse("A"), None, 0)
    for p in horse:
        p.polys = [q + np.array([hi[0] + 6, 0, 0]) for q in p.polys]
    views = [dict(eye=(-20, 16, -26), target=(4, 5.5, 0)), dict(eye=(-40, 8, -0.7), target=(0, 6, -0.7)),
             dict(eye=(22, 19, 27), target=(0, 6, 1.5)), dict(eye=(0, 9, -30), target=(0, 6.5, 0))]
    W, H = 640, 480
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(views):
        sheet.paste(shot(rest + (horse if i == 0 else []), W=W, H=H, fov=34 if i else 40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(SHOT, NAME + "_sheet.png"))
    if "--still" in sys.argv:
        return
    frames = []
    cams = [dict(eye=(-30, 9, 1), target=(0, 6, 1.0)), dict(eye=(-17, 19, -21), target=(0, 6, 0.0))]
    for name, nf in (("idle", 30), ("walk", 20), ("gallop", 14)):
        anim = A.anim_named(model, name)
        for k in range(nf):
            ps = pose(model, anim, k / nf * anim["length"])
            for p in ps:
                p.neon = p.name.startswith("Glow")
            im = Image.new("RGB", (800, 400))
            for c, cam in enumerate(cams):
                im.paste(shot(ps, W=400, H=400, fov=52, **cam), (400 * c, 0))
            frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    A.gif(os.path.join(SHOT, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[x for x in sys.argv[1:] if not x.startswith("--")])
