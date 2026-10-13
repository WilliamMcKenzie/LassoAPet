"""Bes: World 2 Ancient Tomb's first Legendary (QM: the three Tomb of the Ancients bosses are
the Tomb's Legendaries, "very complex/detailed" as the final biome). Our own blocky take on
the RotMG boss: a hulking sandstone war-god golem, the defender. Upright on two stocky legs,
hunched, with a lion-faced head under a striped nemes headdress and Bes's tall plume crown,
a gold-and-blue false beard, a layered usekh collar, a gold shendyt kilt and belt with a
glowing scarab, glowing turquoise eyes and cracks, a round Silver Shield on the left arm
(gold rim, ankh, glowing sun boss), a glowing Fire Boomerang in the right fist, a gold
throne-saddle on his back, and three floating Pyramid Artifacts.

    python3 tools/bes.py [out_dir]

writes designs/tomb/Bes.bbmodel (convert without --zyx), the render
/mnt/project-files/world2/tomb/renders/Bes.png and an animation gif in
/mnt/project-files/world2/tomb/bes/ (--still skips the gif). Every part is axis-aligned or
turned about one axis only, all bones at 0.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import Part, T, Rx, Rz, render  # noqa: E402
from horse_rig import pose  # noqa: E402
from snow_designs import pyramid  # noqa: E402

SAND = (220, 201, 152)  # Tomb sand #DCC998
SAND2 = (208, 184, 134)  # #D0B886
DARK = (168, 142, 96)
LIGHT = (238, 225, 188)
GLYPH = (128, 98, 60)
GOLD = (246, 196, 46)
GOLD2 = (214, 160, 30)
LAPIS = (40, 86, 206)
TURQ = (44, 196, 196)
SILVER = (206, 212, 220)
SILVER2 = (156, 164, 178)
RUBY = (226, 40, 52)
GLOW = (70, 255, 232)  # turquoise neon
FIRE = (255, 116, 24)
FIRE2 = (255, 214, 60)


def bes():
    a = A.Animal("Bes", "Legendary")
    a.bone_order = [("root", None), ("neck", "root"), ("LegFL", "root"), ("LegFR", "root"),
                    ("ArmL", "root"), ("ArmR", "root"), ("Artifacts", "root")]

    def xs(sx, a0, a1):
        return tuple(sorted((sx * a0, sx * a1)))

    def box(name, sx, x0, x1, y0, y1, z0, z1, color, bone):
        x = xs(sx, x0, x1)
        return a.box(name, (x[0], y0, z0), (x[1], y1, z1), color, bone)

    def glow(name, lo, hi, bone, color=GLOW):
        a.box("Glow" + name, lo, hi, color, bone).neon = True

    def turned(name, size, center, R, color, bone, neon=False):
        p = Part(("Glow" if neon else "") + name, np.array(size, float), T(*center) @ R, color)
        p.bone = bone
        p.neon = neon
        a.parts.append(p)
        return p

    # ================================================================ legs
    for leg, sx in (("FL", -1), ("FR", 1)):
        b = "Leg" + leg
        box("Thigh" + leg, sx, 0.9, 3.7, 4.4, 7.4, -1.9, 1.3, SAND, b)
        box("Knee" + leg, sx, 1.0, 3.6, 3.7, 4.4, -2.1, 1.1, DARK, b)
        glow("KneeCrack" + leg, (*xs(sx, 1.6, 3.0)[:1], 3.85, -2.2), (*xs(sx, 1.6, 3.0)[1:], 4.15, -2.1), b)
        box("Shin" + leg, sx, 1.1, 3.5, 1.1, 3.7, -1.6, 1.0, SAND2, b)
        box("Greave" + leg, sx, 1.4, 3.2, 1.4, 3.6, -1.85, -1.6, GOLD, b)
        box("GreaveGem" + leg, sx, 2.05, 2.55, 2.3, 2.9, -2.0, -1.85, LAPIS, b)
        box("Anklet" + leg, sx, 1.0, 3.6, 1.0, 1.5, -1.7, 1.1, GOLD, b)
        box("AnkletBand" + leg, sx, 0.98, 3.62, 1.15, 1.35, -1.72, 1.12, LAPIS, b)
        box("Foot" + leg, sx, 0.8, 3.8, 0, 1.0, -3.0, 1.4, SAND, b)
        for i in range(3):
            t = xs(sx, 0.9 + 1.0 * i, 1.7 + 1.0 * i)
            a.box(f"Toe{leg}{i + 1}", (t[0], 0, -3.6), (t[1], 0.8, -3.0), LIGHT, b)
            a.box(f"ToeCap{leg}{i + 1}", (t[0], 0.8, -3.6), (t[1], 1.0, -3.15), GOLD, b)
        # hieroglyphs carved on the outer thigh, a glowing crack on the front
        for i, (gy, gz) in enumerate(((6.4, -1.1), (6.4, 0.1), (5.3, -0.5))):
            box(f"Glyph{leg}{i + 1}", sx, 3.7, 3.78, gy, gy + 0.6, gz, gz + 0.6, GLYPH, b)
        cx = xs(sx, 2.0, 2.25)
        glow("ThighCrack" + leg, (cx[0], 5.0, -2.0), (cx[1], 6.8, -1.9), b)
        a.pivots[b] = (sx * 2.3, 7.2, -0.3)

    # ================================================================ hips, kilt, belt
    a.box("Hips", (-3.9, 6.4, -2.3), (3.9, 8.6, 1.9), SAND2, "root")
    a.box("Kilt", (-4.1, 5.4, -2.5), (4.1, 7.6, 2.1), GOLD, "root")
    for i in range(7):  # blue pleats on the front of the kilt
        x0 = -3.7 + i * 1.15
        a.box(f"Pleat{i + 1}", (x0, 5.4, -2.62), (x0 + 0.45, 7.4, -2.5), LAPIS, "root")
    a.box("Apron", (-1.3, 3.8, -2.85), (1.3, 7.2, -2.55), GOLD, "root")
    a.box("ApronStripe", (-0.35, 3.8, -2.95), (0.35, 7.0, -2.85), LAPIS, "root")
    for side, sx in (("L", -1), ("R", 1)):
        box("ApronEdge" + side, sx, 1.0, 1.3, 3.8, 7.0, -2.95, -2.85, TURQ, "root")
    a.box("ApronTip", (-1.3, 3.5, -2.85), (1.3, 3.8, -2.55), GOLD2, "root")
    a.box("Belt", (-4.25, 7.6, -2.65), (4.25, 8.4, 2.25), GOLD2, "root")
    a.box("BeltBand", (-4.3, 7.85, -2.7), (4.3, 8.15, 2.3), LAPIS, "root")
    # glowing scarab buckle: shell, head, wings out to the sides
    a.box("Buckle", (-0.9, 7.4, -2.95), (0.9, 8.6, -2.65), GOLD, "root")
    glow("Scarab", (-0.5, 7.55, -3.1), (0.5, 8.35, -2.95), "root")
    a.box("ScarabHead", (-0.3, 8.35, -3.05), (0.3, 8.6, -2.95), GOLD2, "root")
    for side, sx in (("L", -1), ("R", 1)):
        box("ScarabWing" + side, sx, 0.9, 1.8, 7.7, 8.3, -2.85, -2.7, TURQ, "root")

    # ================================================================ torso
    a.body(4.3, 8.4, 13.6, -2.7, 2.5, SAND)
    a.box("Belly", (-3.0, 8.6, -3.1), (3.0, 11.0, -2.7), SAND2, "root")
    for i in range(3):
        a.box(f"Ab{i + 1}", (-2.4, 8.9 + i * 0.75, -3.25), (2.4, 9.4 + i * 0.75, -3.1), LIGHT if i % 2 else SAND2, "root")
    for side, sx in (("L", -1), ("R", 1)):
        box("Pec" + side, sx, 0.25, 3.8, 11.0, 13.0, -3.25, -2.7, LIGHT, "root")
        box("Side" + side, sx, 4.3, 4.6, 9.0, 12.6, -2.0, 1.8, SAND2, "root")
    # glowing crack down the chest, branching
    glow("ChestCrack1", (-0.15, 9.2, -3.35), (0.15, 11.4, -3.25), "root")
    glow("ChestCrack2", (0.15, 9.2, -3.35), (1.3, 9.45, -3.25), "root")
    glow("ChestCrack3", (-1.6, 10.6, -3.35), (-0.15, 10.85, -3.25), "root")
    glow("ChestCrack4", (-1.85, 10.85, -3.35), (-1.6, 11.6, -3.25), "root")
    # back: carved slab with glyph rows and a glowing crack
    a.box("BackSlab", (-3.6, 8.8, 2.5), (3.6, 13.2, 2.85), SAND2, "root")
    for r in range(3):
        for c in range(4):
            a.box(f"BackGlyph{r}{c}", (-2.6 + c * 1.4, 9.4 + r * 1.2, 2.85), (-2.0 + c * 1.4, 9.9 + r * 1.2, 2.93),
                  GLYPH if (r + c) % 2 else GOLD2, "root")
    glow("BackCrack", (1.95, 9.0, 2.86), (2.15, 12.8, 2.95), "root")

    # ================================================================ usekh collar
    rings = ((13.6, 14.05, GOLD, 4.0), (13.15, 13.6, TURQ, 3.6), (12.7, 13.15, LAPIS, 3.2), (12.25, 12.7, GOLD, 2.8))
    for i, (y0, y1, c, w) in enumerate(rings):
        a.box(f"Collar{i + 1}", (-w, y0, -3.25 - 0.12 * (i + 1)), (w, y1, -2.7), c, "root")
    for i in range(7):  # gold teardrop beads hanging off the bottom ring
        x0 = -2.4 + i * 0.75
        a.box(f"Bead{i + 1}", (x0, 11.8, -3.8), (x0 + 0.35, 12.25, -3.6), GOLD2, "root")
    a.box("CollarTop", (-4.3, 13.6, -3.3), (4.3, 14.05, 1.2), GOLD, "root")
    a.box("CollarTopBand", (-3.8, 14.05, -3.0), (3.8, 14.2, 0.2), LAPIS, "root")

    # ================================================================ throne-saddle on the back
    a.box("Saddle", (-2.2, 14.05, -0.3), (2.2, 14.6, 2.5), GOLD, "root")
    a.box("SaddlePad", (-1.8, 14.6, 0.0), (1.8, 14.8, 2.2), RUBY, "root")
    a.box("Backrest", (-2.2, 14.6, 2.5), (2.2, 16.6, 2.95), GOLD2, "root")
    a.box("BackrestInlay", (-1.5, 15.0, 2.95), (1.5, 16.2, 3.05), LAPIS, "root")
    glow("BackrestSun", (-0.4, 15.4, 3.05), (0.4, 16.0, 3.12), "root")
    for side, sx in (("L", -1), ("R", 1)):
        box("Armrest" + side, sx, 2.2, 2.6, 14.05, 15.3, -0.3, 2.95, GOLD2, "root")
        x = xs(sx, 2.2, 2.6)
        pyramid(a, "Finial" + side, (x[0], 16.6, 2.5), (x[1], 16.6, 2.95), "+y", 0.8, GOLD, "root")
    pyramid(a, "BackrestPeak", (-0.6, 16.6, 2.5), (0.6, 16.6, 2.95), "+y", 1.0, GOLD, "root")

    # ================================================================ arms
    for arm, sx in (("L", -1), ("R", 1)):
        b = "Arm" + arm
        # boulder pauldron, stepped, gold-trimmed, a glyph row on the outside
        box("Pauldron" + arm, sx, 4.1, 6.9, 11.9, 14.6, -2.6, 2.0, SAND, b)
        box("PauldronTop" + arm, sx, 4.4, 6.6, 14.6, 15.2, -2.2, 1.6, LIGHT, b)
        box("PauldronFront" + arm, sx, 4.4, 6.6, 12.3, 14.2, -2.9, -2.6, SAND2, b)
        box("PauldronTrim" + arm, sx, 4.0, 7.0, 11.6, 12.0, -2.75, 2.15, GOLD, b)
        box("PauldronTrimGem" + arm, sx, 5.2, 5.8, 11.5, 12.1, -2.95, -2.75, LAPIS, b)
        for i in range(3):
            box(f"PauldronGlyph{arm}{i + 1}", sx, 6.9, 6.98, 12.8, 13.6, -1.8 + i * 1.1, -1.2 + i * 1.1, GLYPH, b)
        x = xs(sx, 5.1, 5.9)
        pyramid(a, "PauldronSpike" + arm, (x[0], 15.2, -0.7), (x[1], 15.2, 0.1), "+y", 1.3, GOLD, b)
        x = xs(sx, 5.0, 6.0)
        pyramid(a, "PauldronSpikeOut" + arm, (sx * 6.9, 12.9, -1.0), (sx * 6.9, 13.9, 0.0),
                "+x" if sx > 0 else "-x", 0.9, GOLD, b)
        # upper arm, glowing elbow, gold armband
        box("UpperArm" + arm, sx, 4.6, 6.4, 9.0, 11.9, -1.6, 0.6, SAND2, b)
        box("Armband" + arm, sx, 4.5, 6.5, 10.6, 11.2, -1.7, 0.7, GOLD, b)
        box("ArmbandBand" + arm, sx, 4.48, 6.52, 10.8, 11.0, -1.72, 0.72, TURQ, b)
        x = xs(sx, 4.65, 6.35)
        glow("Elbow" + arm, (x[0], 8.6, -1.55), (x[1], 9.0, 0.55), b)
        # forearm with a gold bracer, then a big fist
        box("Forearm" + arm, sx, 4.4, 6.6, 5.9, 8.6, -1.9, 0.9, SAND, b)
        box("Bracer" + arm, sx, 4.3, 6.7, 6.3, 8.0, -2.0, 1.0, GOLD, b)
        box("BracerBand" + arm, sx, 4.28, 6.72, 6.9, 7.4, -2.02, 1.02, LAPIS, b)
        box("Fist" + arm, sx, 4.3, 6.7, 3.9, 5.9, -2.1, 1.1, SAND2, b)
        for i in range(4):
            k = xs(sx, 4.4 + 0.58 * i, 4.92 + 0.58 * i)
            a.box(f"Knuckle{arm}{i + 1}", (k[0], 4.2, -2.6), (k[1], 5.7, -2.1), LIGHT if i % 2 else SAND, b)
        box("Thumb" + arm, sx, 4.0, 4.3, 4.6, 5.6, -2.0, -0.8, LIGHT, b)
        a.pivots[b] = (sx * 5.5, 12.8, -0.3)

    # ---- the Silver Shield on the left forearm, facing out: built round from a cross of plates
    S = "ArmL"
    sx0, sx1 = -7.25, -6.75  # shield thickness (x)
    cy, cz = 6.8, -0.5
    for i, (h, w) in enumerate(((5.2, 2.6), (4.4, 4.0), (2.6, 5.2))):
        a.box(f"Shield{i + 1}", (sx0, cy - h / 2, cz - w / 2), (sx1, cy + h / 2, cz + w / 2), SILVER, S)
    for i, (h, w) in enumerate(((5.6, 1.8), (4.8, 3.4), (3.4, 4.8), (1.8, 5.6))):  # gold rim behind
        a.box(f"ShieldRim{i + 1}", (sx1, cy - h / 2, cz - w / 2), (sx1 + 0.12, cy + h / 2, cz + w / 2), GOLD, S)
    for i, (y0, y1, z0, z1) in enumerate(((cy + 2.6, cy + 2.8, cz - 1.3, cz + 1.3), (cy - 2.8, cy - 2.6, cz - 1.3, cz + 1.3),
                                          (cy - 1.3, cy + 1.3, cz - 2.8, cz - 2.6), (cy - 1.3, cy + 1.3, cz + 2.6, cz + 2.8))):
        a.box(f"ShieldEdge{i + 1}", (sx0 - 0.05, y0, z0), (sx1, y1, z1), GOLD, S)
    a.box("ShieldRing", (sx0 - 0.1, cy - 1.7, cz - 1.7), (sx0, cy + 1.7, cz + 1.7), SILVER2, S)
    # gold ankh across it, a glowing sun at its heart
    a.box("AnkhBar", (sx0 - 0.2, cy + 0.2, cz - 1.6), (sx0 - 0.1, cy + 0.65, cz + 1.6), GOLD, S)
    a.box("AnkhStem", (sx0 - 0.2, cy - 2.3, cz - 0.25), (sx0 - 0.1, cy + 0.2, cz + 0.25), GOLD, S)
    a.box("AnkhLoopTop", (sx0 - 0.2, cy + 1.95, cz - 0.7), (sx0 - 0.1, cy + 2.3, cz + 0.7), GOLD, S)
    for side, dz in (("A", -1), ("B", 1)):
        z = sorted((cz + dz * 0.7, cz + dz * 1.05))
        a.box("AnkhLoop" + side, (sx0 - 0.2, cy + 0.65, z[0]), (sx0 - 0.1, cy + 2.3, z[1]), GOLD, S)
    glow("ShieldSun", (sx0 - 0.3, cy + 1.05, cz - 0.5), (sx0 - 0.2, cy + 1.75, cz + 0.5), S)
    for i, (dy, dz) in enumerate(((1.6, -1.6), (1.6, 1.6), (-1.6, -1.6), (-1.6, 1.6))):  # rivets
        a.box(f"ShieldRivet{i + 1}", (sx0 - 0.15, cy + dy - 0.2, cz + dz - 0.2), (sx0 - 0.05, cy + dy + 0.2, cz + dz + 0.2), SILVER2, S)
    k = 1.35  # grow the shield's face about its centre: it's his signature piece
    for p in a.parts:
        if p.bone == S and p.name.startswith(("Shield", "Ankh", "GlowShield")) and p.name != "ShieldGrip":
            p.size = p.size * np.array([1, k, k])
            p.cf[1, 3] = cy + (p.cf[1, 3] - cy) * k
            p.cf[2, 3] = cz + (p.cf[2, 3] - cz) * k
    a.box("ShieldGrip", (-6.75, 6.0, -1.0), (-6.6, 7.6, 0.0), GOLD2, S)

    # ---- the Fire Boomerang held up in the right fist: two glowing arms in a wide V, gold grip
    R = "ArmR"
    a.box("BoomGrip", (5.0, 3.6, -3.6), (6.0, 6.0, -2.6), GOLD2, R)
    a.box("BoomGripBand", (4.95, 4.5, -3.65), (6.05, 4.9, -2.55), LAPIS, R)
    e = np.array([5.5, 6.3, -3.4])  # the boomerang's bend, just above the fist, in front of it
    for nm, ang, ln in (("Up", -18, 4.6), ("Out", -100, 4.2)):
        r = Rz(ang)
        d = r[:3, :3] @ np.array([0, 1, 0])
        turned("BoomArm" + nm, (1.1, ln, 0.6), e + d * ln / 2, r, FIRE, R, neon=True)
        side = r[:3, :3] @ np.array([1, 0, 0])
        turned("BoomEdge" + nm, (0.35, ln - 0.5, 0.64), e + d * (ln / 2 + 0.25) + side * 0.4, r, FIRE2, R, neon=True)
        turned("BoomTip" + nm, (1.15, 0.4, 0.66), e + d * (ln - 0.2), r, GOLD, R)
    a.box("BoomElbow", (4.9, 5.7, -3.8), (6.1, 6.9, -3.0), GOLD, R)
    a.box("BoomGem", (5.25, 6.05, -3.9), (5.75, 6.55, -3.8), RUBY, R)

    # ================================================================ head
    N = "neck"
    F = -5.6  # face plane
    a.box("Head", (-2.2, 13.2, F + 0.4), (2.2, 16.9, -1.9), SAND, N)
    a.box("Cheeks", (-2.3, 13.3, F + 0.1), (2.3, 15.0, F + 0.9), SAND2, N)
    a.box("Muzzle", (-1.4, 13.4, F - 0.3), (1.4, 14.9, F + 0.1), LIGHT, N)  # lion's broad flat face
    a.box("Nose", (-0.6, 14.6, F - 0.75), (0.6, 15.8, F - 0.3), SAND2, N)
    a.box("NoseTip", (-0.5, 14.45, F - 0.85), (0.5, 14.8, F - 0.6), GLYPH, N)
    # snarling mouth: dark gap, a row of teeth, two fangs down from the top lip
    a.box("Mouth", (-1.1, 13.55, F - 0.4), (1.1, 14.2, F - 0.3), GLYPH, N)
    a.box("Teeth", (-0.9, 13.55, F - 0.45), (0.9, 13.75, F - 0.35), LIGHT, N)
    for side, sx in (("L", -1), ("R", 1)):
        x = xs(sx, 0.55, 0.95)
        pyramid(a, "Fang" + side, (x[0], 14.2, F - 0.5), (x[1], 14.2, F - 0.3), "-y", 0.55, (250, 248, 236), N)
        # deep sockets, big glowing eyes, a blue kohl line flicking out
        x = xs(sx, 0.35, 1.75)
        a.box("EyeSocket" + side, (x[0], 15.0, F - 0.05), (x[1], 15.85, F + 0.05), GLYPH, N)
        x = xs(sx, 0.5, 1.6)
        glow("Eye" + side, (x[0], 15.08, F - 0.12), (x[1], 15.7, F - 0.04), N)
        x = xs(sx, 0.45, 2.0)
        a.box("Kohl" + side, (x[0], 14.9, F - 0.12), (x[1], 15.02, F - 0.02), LAPIS, N)
        # angry brow, turned down toward the nose
        turned("Brow" + side, (1.9, 0.55, 0.8), (sx * 1.15, 16.05, F - 0.1), Rz(sx * 14), DARK, N)
        x = xs(sx, 2.2, 2.6)
        a.box("Ear" + side, (x[0], 14.8, -4.2), (x[1], 16.0, -3.2), SAND2, N)
    a.box("BrowRidge", (-0.35, 15.7, F - 0.35), (0.35, 16.5, F + 0.1), DARK, N)
    # nemes headdress: striped cap and lappets falling by the face onto the chest
    T0 = 16.9
    a.box("NemesCap", (-2.4, T0, F + 0.2), (2.4, T0 + 0.5, -1.7), GOLD, N)
    a.box("NemesBand", (-2.45, T0 - 0.5, F + 0.15), (2.45, T0, -1.65), LAPIS, N)
    a.box("NemesBack", (-2.4, 13.6, -1.95), (2.4, T0, -1.5), GOLD, N)
    for side, sx in (("L", -1), ("R", 1)):
        x = xs(sx, 2.3, 2.9)
        for i in range(6):  # alternating gold/blue stripes down each lappet
            y0 = 11.6 + i * 0.8
            a.box(f"Lappet{side}{i + 1}", (x[0], y0, -4.4), (x[1], y0 + 0.8, -2.6), GOLD if i % 2 else LAPIS, N)
    # uraeus: a gold cobra rearing on the brow with a ruby
    a.box("Uraeus", (-0.3, T0 - 0.5, F - 0.1), (0.3, T0 + 0.6, F + 0.2), GOLD, N)
    a.box("UraeusHood", (-0.55, T0 + 0.2, F - 0.2), (0.55, T0 + 0.9, F + 0.1), GOLD2, N)
    a.box("UraeusGem", (-0.22, T0 + 0.35, F - 0.3), (0.22, T0 + 0.7, F - 0.2), RUBY, N)
    # false beard: braided gold and blue, flared at the bottom
    for i in range(4):
        y0 = 11.4 + i * 0.5
        a.box(f"Beard{i + 1}", (-0.6, y0, F - 0.2), (0.6, y0 + 0.5, F + 0.7), GOLD if i % 2 else LAPIS, N)
    a.box("BeardTip", (-0.8, 11.1, F - 0.3), (0.8, 11.4, F + 0.8), GOLD2, N)
    # Bes's plume crown: five tall feathers fanned on top, gold and turquoise with glowing tips
    a.box("CrownBase", (-1.9, T0 + 0.5, -4.7), (1.9, T0 + 1.0, -2.5), GOLD2, N)
    a.box("CrownBand", (-1.95, T0 + 0.6, -4.75), (1.95, T0 + 0.9, -2.45), RUBY, N)
    for i, ang in enumerate((-28, -14, 0, 14, 28)):
        h = 3.6 - abs(ang) / 28 * 0.8
        x = (ang / 14) * 0.65
        c = GOLD if i % 2 == 0 else TURQ
        r = Rz(-ang)
        base = np.array([x, T0 + 0.9, -3.6])
        d = r[:3, :3] @ np.array([0, 1, 0])
        turned(f"Plume{i + 1}", (0.62, h, 0.45), base + d * h / 2, r, c, N)
        turned(f"PlumeTip{i + 1}", (0.64, 0.55, 0.5), base + d * (h + 0.27), r, GLOW, N, neon=True)
        turned(f"PlumeVein{i + 1}", (0.15, h * 0.8, 0.5), base + d * h * 0.45 + np.array([0, 0, -0.03]), r,
               GOLD2 if c == TURQ else LAPIS, N)
    a.pivots[N] = (0, 13.6, -2.4)

    # ================================================================ pyramid artifacts, floating
    P = "Artifacts"
    for i, (x, y, z, s) in enumerate(((-10.8, 13.6, -1.6, 1.3), (9.6, 11.4, -4.0, 1.2), (-4.6, 19.4, 3.8, 1.1))):
        a.box(f"ArtifactBase{i + 1}", (x - s, y - 0.25, z - s), (x + s, y, z + s), GOLD2, P)
        pyramid(a, f"ArtifactPyramid{i + 1}", (x - s, y, z - s), (x + s, y, z + s), "+y", s * 1.5, GOLD, P)
        pyramid(a, f"GlowArtifactTip{i + 1}", (x - s * 0.3, y + s * 1.05, z - s * 0.3), (x + s * 0.3, y + s * 1.05, z + s * 0.3),
                "+y", s * 0.45, GLOW, P).neon = True
        a.box(f"GlowArtifactEye{i + 1}", (x - s * 0.22, y + s * 0.35, z - s * 0.78), (x + s * 0.22, y + s * 0.6, z - s * 0.7), GLOW, P).neon = True
        pyramid(a, f"GlowArtifactUnder{i + 1}", (x - s * 0.5, y - 0.25, z - s * 0.5), (x + s * 0.5, y - 0.25, z + s * 0.5),
                "-y", s * 0.6, GLOW, P).neon = True
    a.pivots[P] = (0, 12.0, 0)

    a.meta = {"seat": (0, 14.8, 1.1), "neck_loop": {"center": (0, 14.8, -3.6), "radius": 2.4}}
    a.animations = animations
    return a


def animations():
    """Heavy and slow, a stone colossus: a breathing idle, a stomping walk (arms swing against
    the legs, a sway side to side) and a pounding run, leaning in. The Pyramid Artifacts bob
    and wobble on their own. Angles in degrees, heights in Blockbench units (10 = 1 stud).
    Legs and arms swing forward on +X; the body leans forward on -X."""
    rx, rz, py, at = A.rot_x, A.rot_z, A.pos_y, A.at
    cr = "catmullrom"

    L = 2.6
    idle = (L, {
        "root": [py(at(L, [(0, 0), (0.5, -1.5), (1, 0)]))],
        "neck": [rx(at(L, [(0, 0), (0.5, 3), (1, 0)]), cr)],
        "ArmL": [rx(at(L, [(0, 0), (0.5, 3), (1, 0)]), cr)],
        "ArmR": [rx(at(L, [(0, 0), (0.5, -3), (1, 0)]), cr)],
        "Artifacts": [py(at(L, [(0, 0), (0.5, 6), (1, 0)])), rz(at(L, [(0, -2), (0.5, 2), (1, -2)]), cr)],
    })

    L = 1.5
    walk = (L, {
        "root": [py(at(L, [(0, 0), (0.25, 4), (0.5, 0), (0.75, 4), (1, 0)])),
                 rz(at(L, [(0, 0), (0.25, 3), (0.5, 0), (0.75, -3), (1, 0)]), cr)],
        "neck": [rx(at(L, [(0, 0), (0.25, -3), (0.5, 0), (0.75, -3), (1, 0)]), cr)],
        "LegFL": [rx(at(L, [(0, 24), (0.5, -24), (1, 24)]), cr)],
        "LegFR": [rx(at(L, [(0, -24), (0.5, 24), (1, -24)]), cr)],
        "ArmL": [rx(at(L, [(0, -14), (0.5, 14), (1, -14)]), cr)],
        "ArmR": [rx(at(L, [(0, 14), (0.5, -14), (1, 14)]), cr)],
        "Artifacts": [py(at(L, [(0, 0), (0.5, 8), (1, 0)])), rz(at(L, [(0, -3), (0.5, 3), (1, -3)]), cr)],
    })

    L = 0.85
    gallop = (L, {
        "root": [py(at(L, [(0, 0), (0.25, 9), (0.5, 0), (0.75, 9), (1, 0)])),
                 rx(at(L, [(0, -7), (0.25, -4), (0.5, -7), (0.75, -4), (1, -7)]), cr),
                 rz(at(L, [(0, 0), (0.25, 4), (0.5, 0), (0.75, -4), (1, 0)]), cr)],
        "neck": [rx(at(L, [(0, 6), (0.25, 2), (0.5, 6), (0.75, 2), (1, 6)]), cr)],
        "LegFL": [rx(at(L, [(0, 40), (0.5, -36), (1, 40)]), cr)],
        "LegFR": [rx(at(L, [(0, -36), (0.5, 40), (1, -36)]), cr)],
        "ArmL": [rx(at(L, [(0, -32), (0.5, 30), (1, -32)]), cr)],
        "ArmR": [rx(at(L, [(0, 30), (0.5, -32), (1, 30)]), cr)],
        "Artifacts": [py(at(L, [(0, 0), (0.5, 10), (1, 0)])), rz(at(L, [(0, -4), (0.5, 4), (1, -4)]), cr)],
    })
    return {"idle": idle, "walk": walk, "gallop": gallop}


CAM = dict(eye=(-20, 16, -34), target=(0, 9.5, 0.0), W=720, H=720, fov=40)
BG = (238, 238, 232)
SIDE = dict(eye=(-36, 12, -14), target=(0, 9.5, -0.5), W=400, H=400, fov=40)
ANIMS = "/mnt/project-files/world2/tomb/bes"


def main(out=os.path.join(A.ROOT, "designs", "tomb"), shots="/mnt/project-files/world2/tomb/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = bes()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    from PIL import Image
    im = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    bg.convert("RGB").save(os.path.join(shots, "Bes.png"))
    im = render(pose(m, None, 0), transparent=True, **dict(CAM, eye=(22, 18, 30)))
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    bg.convert("RGB").save(os.path.join(os.environ.get("BES_SCRATCH", "/tmp"), "Bes_back.png"))
    if "--still" in sys.argv:
        return
    os.makedirs(ANIMS, exist_ok=True)
    frames = []
    for name, n in (("idle", 24), ("walk", 24), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for i in range(n):
            ps = pose(m, anim, i / n * anim["length"])
            for p in ps:
                p.neon = p.name.startswith("Glow")
            frames.append(A.label(render(ps, **SIDE), ["run" if name == "gallop" else name]))
    A.gif(os.path.join(ANIMS, "Bes_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[x for x in sys.argv[1:] if not x.startswith("--")])
